#ifndef HEADER_autoq_gp_World_hpp_ALREADY_INCLUDED
#define HEADER_autoq_gp_World_hpp_ALREADY_INCLUDED

#include <autoq/Types.hpp>
#include <autoq/gp/Node.hpp>
#include <autoq/Options.hpp>
#include <gubg/gp/World.hpp>
#include <gubg/gp/tree/Grow.hpp>
#include <gubg/signal/LinearChirp.hpp>
#include <gubg/wav/Writer.hpp>
#include <gubg/RMS.hpp>
#include <gubg/prob/Bernoulli.hpp>
#include <gubg/prob/Uniform.hpp>
#include <gubg/hr.hpp>
#include <gubg/block/each.hpp>
#include <gubg/stat/Boxplot.hpp>

namespace autoq { namespace gp { 

    class Operations
    {
    public:
        void set(const Options &options)
        {
            grow_.set_probs(options.grow.terminal_prob, options.grow.function_prob);
            grow_.set_max_depth(options.grow.max_depth);
            samplerate_ = options.samplerate;
            mutate_.set_prob(options.mate.mutate_prob);
            write_wav_from_generation_ = options.iteration_cnt-2;
        }

        //World CRTP API
        bool create(NodePtr &ptr)
        {
            MSS_BEGIN(bool);
            auto terminal_factory = [&](NodePtr &ptr)
            {
                MSS_BEGIN(bool);
                std::uniform_int_distribution<> uniform{0,1};
                /* switch (uniform(rng_)) */
                switch (0)
                {
                    case 0:
                        {
                            auto draw_frequency = [&]()
                            {
                                std::uniform_real_distribution<> uniform{20.0,20000.0};
                                return uniform(rng_);
                            };
                            auto draw_q = [&]()
                            {
                                std::uniform_real_distribution<> uniform{0.0,1.0};
                                return uniform(rng_);
                            };
                            auto draw_gain = [&]()
                            {
                                std::uniform_real_distribution<> uniform{-6.0,2.0};
                                return uniform(rng_);
                            };
                            auto draw_type = [&]()
                            {
                                std::uniform_int_distribution<> uniform{0, int(gubg::biquad::Type::Nr_)-1};
                                return static_cast<gubg::biquad::Type>(uniform(rng_));
                            };
                            Biquad biquad{draw_frequency(), draw_q(), draw_gain(), draw_type()};
                            ptr = gubg::gp::tree::create_terminal<Node>(biquad);
                        }
                        break;
                    case 1:
                        {
                            std::uniform_int_distribution<unsigned int> uniform{0, 100};
                            Delay delay{uniform(rng_)};
                            ptr = gubg::gp::tree::create_terminal<Node>(delay);
                        }
                        break;
                    default: MSS(false); break;
                }
                MSS_END();
            };
            auto function_factory = [&](NodePtr &ptr)
            {
                MSS_BEGIN(bool);
                std::uniform_int_distribution<> uniform{0,1};
                switch (uniform(rng_))
                {
                    case 0:
                        {
                            Serial serial;
                            ptr = gubg::gp::tree::create_function<Node>(serial);
                        }
                        break;
                    case 1:
                        {
                            Parallel parallel;
                            ptr = gubg::gp::tree::create_function<Node>(parallel);
                        }
                        break;
                    default: MSS(false); break;
                }
                MSS_END();
            };
            MSS(grow_(ptr, terminal_factory, function_factory));
            MSS_END();
        }

        template <typename Population>
        bool process(Population &population)
        {
            MSS_BEGIN(bool);
            std::cout << "Processing generation " << generation_ << std::endl;
            if (boxplot_.calculate())
            {
                std::cout << boxplot_;
                boxplot_.reset();
            }
            L(C(generation_));

            size_t total_bytesize = 0;
            for (const auto &ptr: population)
            {
                unsigned int bytesize = 0;
                auto update_bytesize = [&](auto &node, auto &path, bool is_enter)
                {
                    const auto bs = node->base().bytesize();
                    /* L(C(node->base().name())C(bs)); */
                    bytesize += bs;
                    return true;
                };
                gubg::gp::tree::Path path;
                MSS(gubg::gp::tree::dfs(ptr, update_bytesize, path));
                L(C(&ptr)C(ptr->size())C(bytesize));
                total_bytesize += bytesize;
            }
            L(C(total_bytesize));

            if (generation_ >= write_wav_from_generation_)
            {
                const auto &input = goc_chirp_();

                unsigned int cix = 0;
                for (const auto &ptr: population)
                {
                    tmp_output_ = input;
                    MSS(process_(tmp_output_, *ptr));

                    std::ostringstream fn; fn << "output." << generation_ << "." << cix << ".wav";
                    gubg::wav::Writer writer(fn.str(), 1, samplerate_);
                    for (auto v: tmp_output_)
                        MSS(writer.add_value(v));

                    ++cix;
                }
            }

            ++generation_;
            MSS_END();
        }

        template <typename Score>
        bool score(Score &score, const NodePtr &node)
        {
            MSS_BEGIN(bool);

            const auto model_complexity = std::log(node->size());

            double target_distance = 0;
            {
                const auto &input = goc_chirp_();
                tmp_output_ = input;
                MSS(process_(tmp_output_, *node));

                std::array<double, 48> rms_ary;
                {
                    const auto blocksize = tmp_output_.size()/rms_ary.size();
                    auto dst = rms_ary.begin();
                    auto compute_rms = [&](auto b, auto e)
                    {
                        gubg::RMS<double> rms;
                        rms.process(b, e);
                        *dst++ = rms.linear();
                        return true;
                    };
                    MSS(gubg::block::each(blocksize, tmp_output_, compute_rms));
                }

                for (auto ix = 0u; ix < rms_ary.size(); ++ix)
                {
                    const auto target = ((ix/10)%2==0 ? 0.2 : 0.8);
                    target_distance += std::abs(target-rms_ary[ix]);
                }
            }

            score = -target_distance - model_complexity;
            /* score = -target_distance; */
            if (generation_ >= write_wav_from_generation_)
            std::cout << C(score)C(target_distance)C(model_complexity) << std::endl;

            boxplot_ << score;

            MSS_END();
        }
        double kill_fraction()
        {
            return 0.5;
        }
        template <typename Creature>
        bool mate(Creature &dst, const Creature &a, const Creature &b)
        {
            MSS_BEGIN(bool);

            //Create dst as a copy of either a or b
            dst = gubg::prob::choose(a, b, 0.5)->clone(true);

            //Select random node in dst
            auto for_random_node = [&](auto &root, auto &&ftor)
            {
                const auto nrnodes = root->size();
                const auto wanted_nodeix = gubg::prob::Uniform(root->size())(rng_);
                auto nodeix = 0u;
                auto walker = [&](auto &root, auto &path, bool is_enter)
                {
                    if (is_enter)
                    {
                        if (nodeix == wanted_nodeix)
                            ftor(root);
                        ++nodeix;
                    }
                    return true;
                };
                gubg::gp::tree::dfs(root, walker);
            };
            NodePtr *dst_node_pp = nullptr;
            for_random_node(dst, [&](auto &node){dst_node_pp = &node;});
            MSS(!!*dst_node_pp);

            //Create new subtree
            NodePtr new_subtree;
            {
                if (mutate_())
                {
                    L("mutate");
                    MSS(create(new_subtree));
                }
                else
                {
                    L("crossover");
                    const auto &src = (&a == &dst ? b : a);
                    for_random_node(src, [&](const auto &node){new_subtree = node->clone(true);});
                }
            }

            *dst_node_pp = new_subtree;

            MSS_END();
        }

    private:
        Signal chirp_;
        const Signal &goc_chirp_()
        {
            if (chirp_.empty())
            {
                const double duration = 1;
                chirp_.resize(duration*samplerate_);
                gubg::signal::LinearChirp<double> chirp{0.1, 0.0, 20, 20000, duration};
                for (auto six = 0; six < chirp_.size(); ++six)
                {
                    const double t = double(six)/samplerate_;
                    chirp_[six] = chirp(t);
                }
            }
            return chirp_;
        }

        Signal tmp_output_;
        bool process_(Signal &io, Node &node)
        {
            auto process_block = [&](auto b, auto e)
            {
                return node.base().compute(node, b, e);
            };
            return gubg::block::each(1000, io, process_block);
        }

        unsigned int generation_ = 0;
        unsigned int write_wav_from_generation_ = 0;
        gubg::stat::Boxplot boxplot_;
        gubg::gp::tree::Grow<Node> grow_;
        double samplerate_ = 0;
        std::mt19937 &rng_ = gubg::prob::rng(true);
        gubg::prob::Bernoulli mutate_;
    };

    class World: public gubg::gp::World<NodePtr, Operations>
    {
    public:
        using Base = gubg::gp::World<NodePtr, Operations>;

        World(const Options &options)
        {
            Base::operations.set(options);
        }

    private:
    };

} } 

#endif

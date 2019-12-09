#ifndef HEADER_autoq_gp_World_hpp_ALREADY_INCLUDED
#define HEADER_autoq_gp_World_hpp_ALREADY_INCLUDED

#include <autoq/gp/Node.hpp>
#include <autoq/Options.hpp>
#include <gubg/gp/World.hpp>
#include <gubg/gp/tree/Grow.hpp>
#include <gubg/signal/LinearChirp.hpp>
#include <gubg/wav/Writer.hpp>
#include <gubg/RMS.hpp>

namespace autoq { namespace gp { 

    class Operations
    {
    public:
        void set(const Options &options)
        {
            grow_.set_probs(options.grow.terminal_prob, options.grow.function_prob);
            grow_.set_max_depth(options.grow.max_depth);
            samplerate_ = options.samplerate;
        }

        //World CRTP API
        bool create(NodePtr &ptr)
        {
            MSS_BEGIN(bool);
            auto terminal_factory = [&](NodePtr &ptr)
            {
                MSS_BEGIN(bool);
                std::uniform_int_distribution<> uniform{0,1};
                switch (uniform(rng_))
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
                            auto draw_type = [&]()
                            {
                                std::uniform_int_distribution<> uniform{0, int(gubg::biquad::Type::Nr_)-1};
                                return static_cast<gubg::biquad::Type>(uniform(rng_));
                            };
                            Biquad biquad{draw_frequency(), draw_q(), draw_type()};
                            ptr = gubg::gp::tree::create_terminal<Node>(biquad);
                        }
                        break;
                    case 1:
                        {
                            std::uniform_int_distribution<> uniform{0, 100};
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
            MSS_BEGIN(bool, "");
            L(C(generation_));

            for (const auto &ptr: population)
            {
                L(C(ptr->size()));
            }

            if (false)
            {
                const auto &input = goc_chirp_();

                unsigned int cix = 0;
                for (const auto &ptr: population)
                {
                    MSS(process_(tmp_output_, input, *ptr));

                    std::ostringstream fn; fn << "output." << generation_ << "." << cix << ".wav";
                    gubg::wav::Writer writer{fn.str(), 1, samplerate_};
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
            MSS_BEGIN(bool, "score");

            const auto &input = goc_chirp_();
            MSS(process_(tmp_output_, input, *node));

            const auto blocksize = 1000;
            int bix = 0;
            gubg::RMS<double> rms_rms;
            for (auto six = 0u; six < input.size()-blocksize+1; six += blocksize, ++bix)
            {
                gubg::RMS<double> rms;
                rms.process(&tmp_output_[six], &tmp_output_[six+blocksize]);
                const auto wanted_rms = std::pow(1.1, -bix);
                /* L(C(wanted_rms)C(rms.linear())); */
                rms_rms.process(wanted_rms-rms.linear());
            }

            score = -rms_rms.db();
            L(C(score));

            MSS_END();
        }
        double kill_fraction()
        {
            return 0.1;
        }
        template <typename Creature>
        bool mate(Creature &dst, const Creature &a, const Creature &b)
        {
            MSS_BEGIN(bool);
            MSS_END();
        }

    private:
        using Signal = std::vector<double>;
        Signal chirp_;
        const Signal &goc_chirp_()
        {
            if (chirp_.empty())
            {
                const double duration = 10;
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

        std::vector<double> tmp_output_;
        bool process_(std::vector<double> &output, const std::vector<double> &input, Node &node)
        {
            MSS_BEGIN(bool);
            output = input;
            for (auto &v: output)
            {
                MSS(node.compute(v));
            }
            MSS_END();
        }

        unsigned int generation_ = 0;
        gubg::gp::tree::Grow<Node> grow_;
        double samplerate_ = 0;
        std::mt19937 rng_;
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

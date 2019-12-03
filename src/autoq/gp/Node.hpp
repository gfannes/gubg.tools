#ifndef HEADER_autoq_gp_Node_hpp_ALREADY_INCLUDED
#define HEADER_autoq_gp_Node_hpp_ALREADY_INCLUDED

#include <gubg/gp/tree/Node.hpp>
#include <gubg/biquad/Tuner.hpp>
#include <gubg/biquad/Filter.hpp>
#include <gubg/History.hpp>

namespace autoq { namespace gp { 

    using T = double;

    class Base
    {
    public:
    private:
    };

    using Node = gubg::gp::tree::Node<T, Base>;
    using NodePtr = typename Node::Ptr;

    class Serial: public Base
    {
    public:
        std::size_t size() const {return 2;}

        template <typename Nodes>
        bool compute(T &v, Nodes &nodes)
        {
            MSS_BEGIN(bool);
            for (const auto &ptr: nodes)
            {
                MSS(ptr->compute(v));
            }
            MSS_END();
        }
    private:
    };

    class Parallel: public Base
    {
    public:
        std::size_t size() const {return 2;}

        template <typename Nodes>
        bool compute(T &v, Nodes &nodes)
        {
            MSS_BEGIN(bool);
            const auto orig_v = v;
            T sum = 0;
            for (const auto &ptr: nodes)
            {
                v = orig_v;
                MSS(ptr->compute(v));
                sum += v;
            }
            v = sum;
            MSS_END();
        }
    private:
    };

    class Biquad: public Base
    {
    public:
        Biquad(double frequency, double q, gubg::biquad::Type type)
        {
            Tuner tuner_{48000};
            tuner_.configure(frequency, q, type);
            filter_.set(*tuner_.compute());
        }

        bool compute(T &v)
        {
            MSS_BEGIN(bool);
            v = filter_(v);
            MSS_END();
        }

    private:
        using Filter = gubg::biquad::Filter<T>;
        using Tuner = gubg::biquad::Tuner<T>;

        Filter filter_;
    };

    class Delay: public Base
    {
    public:
        Delay(unsigned int samples)
        {
            history_.resize(samples);
        }

        bool compute(T &v)
        {
            MSS_BEGIN(bool);
            if (!history_.empty())
            {
                const auto orig = history_.back();
                history_.push_pop(v);
                v = orig;
            }
            MSS_END();
        }

    private:
        gubg::History<T> history_;
    };

} } 

#endif

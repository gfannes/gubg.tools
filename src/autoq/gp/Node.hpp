#ifndef HEADER_autoq_gp_Node_hpp_ALREADY_INCLUDED
#define HEADER_autoq_gp_Node_hpp_ALREADY_INCLUDED

#include <autoq/Types.hpp>
#include <gubg/gp/tree/Node.hpp>
#include <gubg/biquad/Tuner.hpp>
#include <gubg/biquad/Filter.hpp>
#include <gubg/History.hpp>

namespace autoq { namespace gp { 

    class Base;

    using Node = gubg::gp::tree::Node<Base>;
    using NodePtr = typename Node::Ptr;

    using T = double;

    class Base
    {
    public:
        virtual bool compute(Node &node, Signal &) = 0;
    };

    //Function that performs serial processing of its childs
    class Serial: public Base
    {
    public:
        std::size_t size() const {return 2;}

        bool compute(Node &node, Signal &io) override
        {
            MSS_BEGIN(bool);
            for (auto &ptr: node.childs())
            {
                MSS(ptr->base().compute(*ptr, io));
            }
            MSS_END();
        }
    private:
    };

    //Function that performs parallel processing of its childs
    class Parallel: public Base
    {
    public:
        std::size_t size() const {return 2;}

        bool compute(Node &node, Signal &io) override
        {
            MSS_BEGIN(bool);
            const auto size = io.size();
            orig_ = io;
            std::fill(RANGE(io), 0);
            for (auto &ptr: node.childs())
            {
                tmp_ = orig_;

                MSS(ptr->base().compute(*ptr, tmp_));
                for (auto ix = 0u; ix < size; ++ix)
                    io[ix] += tmp_[ix];
            }
            MSS_END();
        }

    private:
        Signal orig_, tmp_;
    };

    //Terminal that performs a biquad filter
    class Biquad: public Base
    {
    public:
        Biquad(double frequency, double q, gubg::biquad::Type type)
        {
            Tuner tuner_{48000};
            tuner_.configure(frequency, q, type);
            filter_.set(*tuner_.compute());
        }

        bool compute(Node &node, Signal &io) override
        {
            MSS_BEGIN(bool);
            for (auto &v: io)
                v = filter_(v);
            MSS_END();
        }

    private:
        using Filter = gubg::biquad::Filter<T>;
        using Tuner = gubg::biquad::Tuner<T>;

        Filter filter_;
    };

    //Terminal that performs a delay line
    class Delay: public Base
    {
    public:
        Delay(unsigned int samples)
        {
            history_.resize(samples);
        }

        bool compute(Node &node, Signal &io) override
        {
            MSS_BEGIN(bool);
            if (!history_.empty())
            {
                for (auto &v: io)
                {
                    const auto orig = history_.back();
                    history_.push_pop(v);
                    v = orig;
                }
            }
            MSS_END();
        }

    private:
        gubg::History<T> history_;
    };

} } 

#endif

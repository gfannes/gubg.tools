#ifndef HEADER_autoq_gp_Node_hpp_ALREADY_INCLUDED
#define HEADER_autoq_gp_Node_hpp_ALREADY_INCLUDED

#include <autoq/Types.hpp>
#include <gubg/gp/tree/Terminal.hpp>
#include <gubg/gp/tree/Function.hpp>
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
        virtual bool compute(Node &node, T *b, T *e) = 0;
        virtual size_t bytesize() const = 0;
        virtual std::string name() const = 0;
    };

    //Function that performs serial processing of its childs
    class Serial: public Base
    {
    public:
        std::size_t size() const {return 2;}

        bool compute(Node &node, T *b, T *e) override
        {
            MSS_BEGIN(bool);
            for (auto &ptr: node.childs())
            {
                MSS(ptr->base().compute(*ptr, b, e));
            }
            MSS_END();
        }
        size_t bytesize() const override {return sizeof(*this);}
        std::string name() const override {return "Serial";}

    private:
    };

    //Function that performs parallel processing of its childs
    class Parallel: public Base
    {
    public:
        std::size_t size() const {return 2;}

        bool compute(Node &node, T *b, T *e) override
        {
            MSS_BEGIN(bool);
            const auto size = e-b;
            orig_.assign(b, e);
            std::fill(b, e, 0);
            for (auto &ptr: node.childs())
            {
                tmp_ = orig_;
                auto tmp_ptr = tmp_.data();

                MSS(ptr->base().compute(*ptr, tmp_ptr, tmp_ptr+size));
                for (auto ix = 0u; ix < size; ++ix)
                    b[ix] += tmp_[ix];
            }
            MSS_END();
        }
        size_t bytesize() const override {return sizeof(*this)+orig_.size()*sizeof(orig_[0])+tmp_.size()*sizeof(tmp_[0]);}
        std::string name() const override {return "Parallel";}

    private:
        Signal orig_, tmp_;
    };

    //Terminal that performs a biquad filter
    class Biquad: public Base
    {
    public:
        Biquad(double frequency, double q, double gain_db, gubg::biquad::Type type)
        {
            Tuner tuner_{48000};
            tuner_.configure(frequency, q, type);
            tuner_.set_gain_db(gain_db);
            filter_.set(*tuner_.compute());
        }

        bool compute(Node &node, T *b, T *e) override
        {
            MSS_BEGIN(bool);
            for (auto it = b; it != e; ++it)
                *it = filter_(*it);
            MSS_END();
        }
        size_t bytesize() const override {return sizeof(*this);}
        std::string name() const override {return "Biquad";}

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

        bool compute(Node &node, T *b, T *e) override
        {
            MSS_BEGIN(bool);
            if (!history_.empty())
            {
                for (auto it = b; it != e; ++it)
                {
                    const auto orig = history_.back();
                    history_.push_pop(*it);
                    *it = orig;
                }
            }
            MSS_END();
        }
        size_t bytesize() const override {return sizeof(*this)+2*history_.size()*sizeof(T);}
        std::string name() const override {return "Delay";}

    private:
        gubg::History<T> history_;
    };

} } 

#endif

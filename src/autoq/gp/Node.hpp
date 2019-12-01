#ifndef HEADER_autoq_gp_Node_hpp_ALREADY_INCLUDED
#define HEADER_autoq_gp_Node_hpp_ALREADY_INCLUDED

#include <gubg/gp/tree/Node.hpp>

namespace autoq { namespace gp { 

    class Base
    {
    public:
    private:
    };

    class Serial: public Base
    {
    public:
    private:
    };

    class Parallel: public Base
    {
    public:
    private:
    };

    class Biquad: public Base
    {
    public:
    private:
    };

    class Delay: public Base
    {
    public:
    private:
    };

    using T = double;
    using Node = gubg::gp::tree::Node<T, Base>;
    using NodePtr = typename Node::Ptr;

} } 

#endif

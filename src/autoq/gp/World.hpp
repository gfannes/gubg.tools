#ifndef HEADER_autoq_gp_World_hpp_ALREADY_INCLUDED
#define HEADER_autoq_gp_World_hpp_ALREADY_INCLUDED

#include <autoq/gp/Node.hpp>
#include <gubg/gp/World.hpp>

namespace autoq { namespace gp { 

    class Operations
    {
    public:
        bool create(NodePtr &) const
        {
            MSS_BEGIN(bool);
            MSS_END();
        }
        template <typename Population>
        bool process(Population &population) const
        {
            MSS_BEGIN(bool);
            MSS_END();
        }
        template <typename Score>
        bool score(Score &score, const NodePtr &node) const
        {
            MSS_BEGIN(bool);
            MSS_END();
        }
        double kill_fraction() const
        {
            return 0.1;
        }
    private:
    };

    class World: public gubg::gp::World<NodePtr, Operations>
    {
    public:
        using Base = gubg::gp::World<NodePtr, Operations>;

        Operations operations;

        World(): Base(operations) {}

    private:
    };

} } 

#endif

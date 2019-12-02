#ifndef HEADER_autoq_App_hpp_ALREADY_INCLUDED
#define HEADER_autoq_App_hpp_ALREADY_INCLUDED

#include <autoq/Options.hpp>
#include <autoq/Response.hpp>
#include <autoq/gp/World.hpp>
#include <gubg/mss.hpp>
#include <iostream>
#include <optional>

namespace autoq { 
    class App
    {
    public:
        bool process(int argc, const char **argv)
        {
            MSS_BEGIN(bool);
            MSS(options_.parse(argc, argv));
            std::cout << options_ << std::endl;
            MSS_END();
        }
        bool operator()()
        {
            MSS_BEGIN(bool);

            if (options_.print_help)
                std::cout << options_.help() << std::endl;
            else
                MSS(do_learn_());

            MSS_END();
        }

    private:
        bool do_learn_()
        {
            MSS_BEGIN(bool);

            auto load_response = [](auto &dst, const auto &fn_opt)
            {
                MSS_BEGIN(bool);
                MSS(!!fn_opt);
                dst.emplace();
                MSS(dst->load(*fn_opt));
                std::cout << "Loaded \"" << *fn_opt << "\":" << std::endl;
                std::cout << *dst << std::endl;
                MSS_END();
            };
            MSS(load_response(system_, options_.system_response_filename));
            MSS(load_response(target_, options_.target_response_filename));

            MSS(!!system_);
            MSS(!!target_);
            MSS(system_->frequencies() == target_->frequencies(), std::cout << "Error: target frequencies are different from system frequencies.\n");

            gp::World world;
            world.resize(options_.population_size);

            for (auto i = 0u; i < options_.iteration_cnt; ++i)
            {
                MSS(world.process());
            }

            MSS_END();
        }

        Options options_;
        std::optional<Response> system_;
        std::optional<Response> target_;
    };
} 

#endif

#ifndef HEADER_app_App_hpp_ALREADY_INCLUDED
#define HEADER_app_App_hpp_ALREADY_INCLUDED

#include <app/Options.hpp>

namespace app { 
    class App
    {
    public:
        App(const Options &options): options_(options) {}

        bool run();

    private:
        Options options_;
    };
}

#endif

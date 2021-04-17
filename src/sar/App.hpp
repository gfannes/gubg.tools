#ifndef HEADER_sar_App_hpp_ALREADY_INCLUDED
#define HEADER_sar_App_hpp_ALREADY_INCLUDED

#include <sar/Options.hpp>

namespace sar { 

    class App
    {
    public:
        App(const Options &options): options_(options) {}

        bool operator()();

    private:
        const Options &options_;
    };

} 

#endif

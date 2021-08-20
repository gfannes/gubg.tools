#ifndef HEADER_app_Options_hpp_ALREADY_INCLUDED
#define HEADER_app_Options_hpp_ALREADY_INCLUDED

#include <string>

namespace app { 
    class Options
    {
    public:
        std::string exe_name;

        bool print_help = false;

        bool parse(unsigned int argc, const char **argv);

        std::string help() const;

    private:
    };
}

#endif

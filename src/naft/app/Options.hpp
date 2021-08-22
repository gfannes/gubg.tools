#ifndef HEADER_app_Options_hpp_ALREADY_INCLUDED
#define HEADER_app_Options_hpp_ALREADY_INCLUDED

#include <string>
#include <optional>

namespace app { 
    class Options
    {
    public:
        std::string exe_name;

        bool print_help = false;

        std::optional<std::string> input_fp;
        std::optional<std::string> output_fp;

        enum Operation {Pack, Unpack};
        std::optional<Operation> operation_;

        bool parse(unsigned int argc, const char **argv);

        std::string help() const;

    private:
    };
}

#endif

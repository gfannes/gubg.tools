#ifndef HEADER_sar_Options_hpp_ALREADY_INCLUDED
#define HEADER_sar_Options_hpp_ALREADY_INCLUDED

#include <string>
#include <optional>

namespace sar { 

    class Options
    {
    public:
        bool print_help = false;
        int verbose_level = 0;
        std::string filepath_pattern;
        std::optional<std::string> needle;
        std::optional<std::string> replacement;
        std::string root_folder = "./";
        bool simulate = false;
        bool case_insensitive = false;
        bool word_boundary = false;

        bool parse(int argc, const char **argv);

        std::string help() const;

    private:
        std::string exe_name_;
    };

} 

#endif

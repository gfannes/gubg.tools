#ifndef HEADER_sar_Options_hpp_ALREADY_INCLUDED
#define HEADER_sar_Options_hpp_ALREADY_INCLUDED

#include <string>
#include <optional>
#include <list>

namespace sar { 

    class Options
    {
    public:
        bool print_help = false;

        int verbose_level = 0;

        std::string root_folder = "./";

        std::string include_filepath_pattern;
        std::list<std::string> include_extensions;
        std::list<std::string> exclude_filepath_patterns;

        std::optional<std::string> search_pattern;

        std::optional<std::string> replacement;

        bool simulate = false;
        bool case_sensitive = true;
        bool word_boundary = false;

        bool output_filepaths = false;

        bool parse(int argc, const char **argv);

        std::string help() const;

    private:
        std::string exe_name_;
    };

} 

#endif

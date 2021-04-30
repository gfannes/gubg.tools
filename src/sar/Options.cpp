#include <sar/Options.hpp>
#include <sar/log.hpp>
#include <gubg/mss.hpp>
#include <sstream>

namespace sar { 
    bool Options::parse(int argc, const char **argv)
    {
        MSS_BEGIN(bool);

        unsigned int arg_ix = 0;
        auto pop_arg = [&](std::string &arg)
        {
            if (arg_ix >= argc)
                return false;
            arg = argv[arg_ix++];
            return true;
        };

        MSS(pop_arg(exe_name_));

        for (std::string arg; pop_arg(arg);)
        {
            std::string str;

            auto is = [&](const char *sh, const char *lh){return arg == sh || arg == lh;};
            if (false) {}
            else if (is("-h", "--help")) {print_help = true;}
            else if (is("-V", "--verbose"))
            {
                MSS(pop_arg(str), log::error() << "Expected verbose LEVEL" << std::endl);
                verbose_level = std::stoi(str);
            }
            else if (is("-C", "--root")) { MSS(pop_arg(root_folder), log::error() << "Expected root FOLDER" << std::endl); }
            else if (is("-e", "--extension")) { include_extensions.emplace_back(); MSS(pop_arg(include_extensions.back()), log::error() << "Expected extension STRING for filtering files" << std::endl); }
            else if (is("-f", "--include-filepath")) { MSS(pop_arg(include_filepath_pattern), log::error() << "Expected filepath PATTERN for including files" << std::endl); }
            else if (is("-x", "--exclude-filepath")) { exclude_filepath_patterns.emplace_back(); MSS(pop_arg(exclude_filepath_patterns.back()), log::error() << "Expected filepath PATTERN for excluding files" << std::endl); }
            else if (is("-p", "--search-pattern"))
            {
                search_pattern.emplace();
                MSS(pop_arg(*search_pattern), log::error() << "Expected search PATTERN" << std::endl);
            }
            else if (is("-r", "--replacement"))
            {
                replacement.emplace();
                MSS(pop_arg(*replacement), log::error() << "Expected replacement STRING" << std::endl);
            }
            else if (is("-n", "--simulate")) {simulate = true;}
            else if (is("-s", "--case-sensitive"))   {case_sensitive = true;}
            else if (is("-i", "--case-insensitive")) {case_sensitive = false;}
            else if (is("-w", "--word")) {word_boundary = true;}
            else if (is("-l", "--output-filepaths")) {output_filepaths = true;}
            else
                MSS(false, log::error() << "Unknown CLI option `" << arg << "`" << std::endl);
        }

        MSS_END();
    }

    std::string Options::help() const
    {
        std::ostringstream oss;
        oss << "Search and replace: " << exe_name_ << std::endl;
        oss << "    -h,--help                        Print this help" << std::endl;
        oss << "    -V,--verbose            LEVEL    Set the verbosity LEVEL [" << verbose_level << "]" << std::endl;
        oss << "    -C,--root               FOLDER   Use FOLDER as root [" << root_folder << "]" << std::endl;
        oss << "    -e,--extension          STRING   Filter selected files for given extensions" << std::endl;
        oss << "    -f,--include-filepath   PATTERN  Use PATTERN to select files [" << include_filepath_pattern << "]" << std::endl;
        oss << "    -x,--exclude-filepath   PATTERN  Add PATTERN to exclude files" << std::endl;
        oss << "    -p,--search-pattern     PATTERN  Use PATTERN as search pattern to find in the files" << std::endl;
        oss << "    -r,--replacement        STRING   Use STRING as replacement for the search pattern" << std::endl;
        oss << "    -n,--simulate                    Only simulate, do not overwrite files [" << simulate << "]" << std::endl;
        oss << "    -s,--case-sensitive              Use case sensitive search ["   << ( case_sensitive ? "enabled" : "disabled") << "]" << std::endl;
        oss << "    -i,--case-insensitive            Use case insensitive search [" << (!case_sensitive ? "enabled" : "disabled") << "]" << std::endl;
        oss << "    -w,--word                        Search for word boundary [" << word_boundary << "]" << std::endl;
        oss << "    -l,--output-filepaths            Output filepaths only [" << output_filepaths << "]" << std::endl;
        oss << "Written by Geert Fannes" << std::endl;
        return oss.str();
    }
} 

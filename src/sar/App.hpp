#ifndef HEADER_sar_App_hpp_ALREADY_INCLUDED
#define HEADER_sar_App_hpp_ALREADY_INCLUDED

#include <sar/Options.hpp>
#include <list>
#include <filesystem>
#include <optional>
#include <regex>
#include <string>

namespace sar { 

    class App
    {
    public:
        App(const Options &options): options_(options) {}

        bool operator()();

    private:
        using FilepathList = std::list<std::filesystem::path>;

        bool search_filepaths_(FilepathList &filepaths) const;
        std::optional<std::regex> get_search_pattern_re_() const;
        bool search_and_replace_in_files_(FilepathList &, const std::regex &needle_re, const std::string *replacement) const;

        std::regex create_regex_(const std::string &str) const;

        const Options &options_;
    };

} 

#endif

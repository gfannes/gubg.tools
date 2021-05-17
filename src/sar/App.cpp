#include <sar/App.hpp>
#include <sar/log.hpp>
#include <gubg/file/system.hpp>
#include <gubg/mss.hpp>
#include <vector>

namespace sar { 

    bool App::operator()()
    {
        MSS_BEGIN(bool);

        FilepathList filepaths;
        MSS(search_filepaths_(filepaths));

        if (auto search_pattern_re = get_search_pattern_re_())
        {
            MSS(search_and_replace_in_files_(filepaths, *search_pattern_re, options_.replacement ? &*options_.replacement : nullptr));
        }
        else
        {
            log::os(2) << "Found " << filepaths.size() << " matching files" << std::endl;
            if (options_.output_filepaths)
                for (const auto &fp: filepaths)
                    std::cout << fp.string() << std::endl;
        }

        MSS_END();
    }

    //Privates
    bool App::search_filepaths_(FilepathList &filepaths) const
    {
        MSS_BEGIN(bool);

        filepaths.clear();

        const std::string filepath_re_str = std::string(".*")+options_.include_filepath_pattern+".*";

        std::list<std::regex> exclude_res;
        for (const auto &exclude_pattern: options_.exclude_filepath_patterns)
            exclude_res.push_back(create_regex_(exclude_pattern));

        auto cb = [&](auto fp)
        {
            //Do not add non-regular files
            if (!std::filesystem::is_regular_file(fp))
                return true;

            const auto fp_str = fp.string();

            //Do not add files with a wrong extension
            if (!options_.include_extensions.empty())
            {
                bool found_match = false;
                for (const auto &extension: options_.include_extensions)
                {
                    //TODO: replace with std::string::ends_with() once supported
                    //if (!fp_str.ends_with(extension))
                    //    return true;
                    if (fp_str.size() < extension.size())
                        continue;
                    if (fp_str.substr(fp_str.size()-extension.size()) != extension)
                        continue;

                    found_match = true;
                    break;
                }
                //No extension matches: do not add this file
                if (!found_match)
                    return true;
            }

            //Do not add files that are explicitly excluded
            for (const auto &exclude_re: exclude_res)
                if (std::regex_search(fp_str, exclude_re))
                    return true;;

            //All checks passed: add file to be searched
            filepaths.push_back(fp);

            return true;
        };
        MSS(gubg::file::each_regex(create_regex_(filepath_re_str), cb, options_.root_folder, !options_.search_hidden_folders, !options_.search_hidden_files));

        MSS_END();
    }

    std::optional<std::regex> App::get_search_pattern_re_() const
    {
        std::optional<std::regex> re;

        if (options_.search_pattern)
        {
            std::string search_pattern_str = *options_.search_pattern;
            if (options_.word_boundary)
                search_pattern_str = std::string("\\b")+search_pattern_str+"\\b";

            re = create_regex_(search_pattern_str);
        }

        return re;
    }

    bool App::search_and_replace_in_files_(FilepathList &filepaths, const std::regex &search_pattern_re, const std::string *replacement) const
    {
        MSS_BEGIN(bool);

        FilepathList successful_filepaths;

        std::string content, new_content;
        std::vector<std::string> lines;
        for (const auto &fp: filepaths)
        {
            MSS(gubg::file::read(content, fp));

            //Parse content into lines
            //TODO: Can be optimized: there is no need to actually move all the data around
            {
                unsigned int line_ix = 0;

                auto grow_lines = [&](){
                    if (lines.size() <= line_ix)
                        lines.resize(line_ix+1);
                    lines[line_ix].resize(0);
                };

                grow_lines();

                for (char ch: content)
                {
                    if (ch == 10 || ch == 13)
                    {
                        ++line_ix;
                        grow_lines();
                        lines[line_ix].push_back(ch);
                        ++line_ix;
                        grow_lines();
                    }
                    else
                        lines[line_ix].push_back(ch);
                }
                lines.resize(line_ix+1);
            }

            {
                unsigned int match_count = 0;
                for (auto &line: lines)
                {
                    if (std::regex_search(line, search_pattern_re))
                    {
                        log::os(0) << line << std::endl;
                        ++match_count;

                        if (replacement)
                        {
                            line = std::regex_replace(line, search_pattern_re, *replacement);
                        }
                    }
                }

                if (match_count == 0)
                    log::os(3) << "No match in " << fp << std::endl;
                else
                {
                    log::os(2) << "Found " << match_count << " matches in " << fp << std::endl;
                    if (replacement)
                    {
                        //Combine lines into new_content
                        {
                            new_content.resize(0);
                            for (const auto &line: lines)
                                new_content.append(line);
                        }
                        if (options_.simulate)
                        {
                            log::os(0) << new_content;
                        }
                        else
                        {
                            const auto orig_permissions = std::filesystem::status(fp).permissions();
                            MSS(gubg::file::write(new_content, fp));
                            std::filesystem::permissions(fp, orig_permissions);
                        }
                    }
                }
            }
        }

        MSS_END();
    }

    std::regex App::create_regex_(const std::string &str) const
    {
        const auto flags = options_.case_sensitive ? std::regex_constants::ECMAScript : std::regex::icase;
        return std::regex{str, flags};
    }
} 

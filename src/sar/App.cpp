#include <sar/App.hpp>
#include <sar/log.hpp>
#include <gubg/file/system.hpp>
#include <gubg/mss.hpp>
#include <regex>
#include <vector>

namespace sar { 
    bool App::operator()()
    {
        MSS_BEGIN(bool);

        const std::string filepath_regex = std::string(".*")+options_.filepath_pattern+".*";

        std::optional<std::regex> needle_re;
        if (options_.needle)
        {
            std::string needle_str = *options_.needle;
            if (options_.word_boundary)
                needle_str = std::string("\\b")+needle_str+"\\b";
            if (options_.case_insensitive)
                needle_re.emplace(needle_str, std::regex_constants::icase);
            else
                needle_re.emplace(needle_str);
        }

        std::string content, new_content;
        std::vector<std::string> lines;
        auto cb = [&](auto fp)
        {
            MSS_BEGIN(bool);

            if (!std::filesystem::is_regular_file(fp))
                return true;

            if (needle_re)
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
                        if (std::regex_search(line, *needle_re))
                        {
                            log::os(0) << line << std::endl;
                            ++match_count;

                            if (options_.replacement)
                            {
                                line = std::regex_replace(line, *needle_re, *options_.replacement);
                            }
                        }
                    }

                    if (match_count == 0)
                        log::os(3) << "No match in " << fp << std::endl;
                    else
                    {
                        log::os(2) << "Found " << match_count << " matches in " << fp << std::endl;
                        if (options_.replacement)
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
            else
            {
                log::os(0) << fp << std::endl;
            }
            MSS_END();
        };
        MSS(gubg::file::each_regex(filepath_regex, cb, options_.root_folder));

        MSS_END();
    }
} 

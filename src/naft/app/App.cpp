#include <app/App.hpp>
#include <gubg/naft/Document.hpp>
#include <gubg/file/system.hpp>
#include <gubg/Strange.hpp>
#include <gubg/mss.hpp>
#include <fstream>

namespace app { 
    bool App::run()
    {
        MSS_BEGIN(bool);

        if (options_.operation_)
            switch (*options_.operation_)
            {
                case Options::Pack:
                    {
                        MSS(!!options_.input_fp);
                        const auto &input_fp = *options_.input_fp;
                        const auto folder = (input_fp == "." || input_fp == "./") ? std::filesystem::current_path() : std::filesystem::path{input_fp};

                        MSS(!!options_.output_fp);
                        output_fp_ = std::filesystem::absolute(*options_.output_fp);
                        std::ofstream fo{output_fp_};

                        gubg::naft::Document doc{fo};
                        pack_(folder, doc);
                    }
                    break;
                case Options::Unpack:
                    {
                        std::string content;
                        {
                            MSS(!!options_.input_fp);
                            const auto &input_fp = *options_.input_fp;
                            MSS(gubg::file::read(content, input_fp));
                        }

                        gubg::naft::Range r{content};

                        MSS(!!options_.output_fp);
                        std::filesystem::path output_fp = *options_.output_fp;

                        if (!std::filesystem::exists(output_fp))
                            std::filesystem::create_directories(output_fp);

                        MSS(unpack_(output_fp, r));
                    }
                    break;
                default: MSS(false); break;
            }

        MSS_END();
    }

    bool App::pack_(const std::filesystem::path &folder, gubg::naft::Node &parent)
    {
        MSS_BEGIN(bool);

        auto node = parent.node("folder");
        node.attr("name", folder.filename().string());

        for (const auto &dir_entry: std::filesystem::directory_iterator{folder})
        {
            if (false) {}
            else if (dir_entry.is_directory())
                MSS(pack_(dir_entry.path(), node));
            else if (dir_entry.is_regular_file())
            {
                const auto fp = std::filesystem::absolute(dir_entry.path());

                if (fp == output_fp_)
                {
                    //We do not include the output file we are currently writing into
                }
                else
                {
                    auto file = node.node("file");
                    file.attr("name", fp.filename().string());

                    std::string content;
                    MSS(gubg::file::read(content, fp));
                    file.attr("content", content);
                }
            }
        }

        MSS_END();
    }

    bool App::unpack_(const std::filesystem::path &folder, gubg::naft::Range &r)
    {
        MSS_BEGIN(bool, "");
        L(C(folder));

        MSS(std::filesystem::is_directory(folder), std::cout << "Error: I expected `" << folder << "` to be a folder" << std::endl);

        for (std::string tag; r.pop_tag(tag); )
        {
            std::string key, name, content;
            if (false) {}
            else if (tag == "folder")
            {
                MSS(r.pop_attr(key, name));
                MSS(key == "name");
                L("Found folder `" << name << "`");

                const auto new_folder = folder/std::filesystem::path{name};
                std::filesystem::create_directories(new_folder);

                if (gubg::naft::Range rr; r.pop_block(rr))
                    MSS(unpack_(new_folder, rr));
            }
            else if (tag == "file")
            {
                MSS(r.pop_attr(key, name));
                MSS(key == "name");
                L("Found file `" << name << "`");
                MSS(r.pop_attr(key, content));
                MSS(key == "content");
                const auto new_file = folder/std::filesystem::path{name};
                MSS(gubg::file::write(content, new_file));
            }
            else MSS(false, std::cout << "Error: Unexpected tag `" << tag << "`" << std::endl);
        }

        MSS_END();
    }
}

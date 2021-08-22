#include <app/Options.hpp>
#include <gubg/cli/Range.hpp>
#include <gubg/mss.hpp>

namespace app { 
    bool Options::parse(unsigned int argc, const char **argv)
    {
        MSS_BEGIN(bool);

        gubg::cli::Range argr{argc, argv};

        MSS(argr.pop(exe_name));

        for (std::string arg; argr.pop(arg);)
        {
            auto is = [&](const char *sh, const char *lh){return arg == sh || arg == lh;};

            if (false) {}
            else if (is("-h", "--help")){print_help = true;}
            else if (is("-p", "--pack"))
            {
                operation_ = Pack;
                MSS(argr.pop(input_fp), std::cout << "Error: Expected folder to pack" << std::endl);
                MSS(argr.pop(output_fp), std::cout << "Error: Expected output file" << std::endl);
            }
            else if (is("-u", "--unpack"))
            {
                operation_ = Unpack;
                MSS(argr.pop(input_fp), std::cout << "Error: Expected file to unpack" << std::endl);
                MSS(argr.pop(output_fp), std::cout << "Error: Expected output folder" << std::endl);
            }
            else MSS(false, std::cout << "Error: Unknown argument `" << arg << "`" << std::endl);
        }

        MSS_END();
    }

    std::string Options::help() const
    {
        return R"eod(naft <options>
    -h    --help                         Print this help
    -p    --pack     FOLDER   FILEPATH   Pack FOLDER into FILEPATH
    -u    --unpack   FILEPATH FOLDER     Unpack FILEPATH into FOLDER
Developed by Geert Fannes
)eod";
    }
}

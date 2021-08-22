#include <app/Options.hpp>
#include <gubg/mss.hpp>

namespace app { 
    bool Options::parse(unsigned int argc, const char **argv)
    {
        MSS_BEGIN(bool);

        unsigned int argix = 0;
        auto pop_arg = [&](std::string &arg){
            if (argix >= argc)
                return false;
            arg = argv[argix++];
            return true;
        };

        MSS(pop_arg(exe_name));

        for (std::string arg; pop_arg(arg);)
        {
            auto is = [&](const char *sh, const char *lh){return arg == sh || arg == lh;};

            if (false) {}
            else if (is("-h", "--help")){print_help = true;}
            else if (is("-p", "--pack"))
            {
                MSS(pop_opt(pack_fp), std::cout << "Error: ");
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

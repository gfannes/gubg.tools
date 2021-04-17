#include <sar/App.hpp>
#include <sar/log.hpp>
#include <gubg/mss.hpp>

int main(int argc, const char **argv)
{
    MSS_BEGIN(int);

    sar::Options options;
    MSS(options.parse(argc, argv));
    sar::log::set_level(options.verbose_level);

    if (options.print_help)
    {
        std::cout << options.help();
    }
    else
    {
        sar::App app{options};
        MSS(app());
    }

    MSS_END();
}

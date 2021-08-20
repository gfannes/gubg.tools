#include <app/Options.hpp>
#include <app/App.hpp>
#include <gubg/mss.hpp>
#include <iostream>

int main(int argc, const char **argv)
{
    MSS_BEGIN(int);

    app::Options options;
    MSS(options.parse(argc, argv));

    if (options.print_help)
    {
        std::cout << options.help();
    }
    else
    {
        app::App app{options};
        MSS(app.run(), std::cout << "Something failed" << std::endl);
        std::cout << "Everything went OK" << std::endl;
    }

    MSS_END();
}

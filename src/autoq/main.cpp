#include <autoq/App.hpp>
#include <iostream>

int main(int argc, const char **argv)
{
    autoq::App app;
    if (!app.process(argc, argv))
    {
        std::cout << "Error: could not process the CLI arguments" << std::endl;
        return -1;
    }
    if (!app())
    {
        std::cout << "Error: could not execute the app" << std::endl;
        return -1;
    }

    return 0;
}

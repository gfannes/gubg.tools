#ifndef HEADER_app_App_hpp_ALREADY_INCLUDED
#define HEADER_app_App_hpp_ALREADY_INCLUDED

#include <app/Options.hpp>
#include <gubg/naft/Node.hpp>
#include <gubg/naft/Range.hpp>
#include <filesystem>

namespace app { 
    class App
    {
    public:
        App(const Options &options): options_(options) {}

        bool run();

    private:
        bool pack_(const std::filesystem::path &folder, gubg::naft::Node &node);
        bool unpack_(const std::filesystem::path &folder, gubg::naft::Range &r);

        Options options_;
        std::filesystem::path output_fp_;
    };
}

#endif

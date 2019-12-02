#ifndef HEADER_autoq_Options_hpp_ALREADY_INCLUDED
#define HEADER_autoq_Options_hpp_ALREADY_INCLUDED

#include <gubg/mss.hpp>
#include <string>
#include <ostream>
#include <sstream>
#include <optional>

namespace autoq { 
    class Options
    {
    public:
        std::string cli_filename;

        bool print_help = false;

        std::optional<std::string> system_response_filename;
        std::optional<std::string> target_response_filename;
        double samplerate = 48000;

        unsigned int population_size = 100;
        unsigned int iteration_cnt = 10;

        bool parse(int argc, const char **argv)
        {
            MSS_BEGIN(bool);
            unsigned int ix = 0;
            auto pop = [&]()
            {
                if (ix >= argc)
                    return "";
                return argv[ix++];
            };
            cli_filename = pop();

            for (std::string arg; !(arg = pop()).empty();)
            {
                if (false) {}
                else if (arg == "-h"){print_help = true;}
                else if (arg == "system"){system_response_filename = pop();}
                else if (arg == "target"){target_response_filename = pop();}
                else if (arg == "samplerate"){samplerate = std::stod(pop());}
                else if (arg == "population"){population_size = std::stol(pop());}
                else if (arg == "iteration"){iteration_cnt = std::stol(pop());}
                else
                    MSS(false, std::cout << "Error: unknown argument \"" << arg << "\".\n");
            }

            MSS_END();
        }

        void stream(std::ostream &os) const
        {
            os << "[autoq::Options](cli_filename:" << cli_filename << ")(samplerate:" << samplerate << "){" << std::endl;
            if (system_response_filename)
                os << "  [System](filename:" << *system_response_filename << ")" << std::endl;
            if (target_response_filename)
                os << "  [Target](filename:" << *target_response_filename << ")" << std::endl;
            os << "}" << std::endl;
        }

        std::string help() const
        {
            std::ostringstream oss;
            oss << cli_filename << std::endl;
            oss << "    -h                      Print this help\n";
            oss << "    system     <filename>   System response file\n";
            oss << "    target     <filename>   Target response file\n";
            oss << "    samplerate <number>     Sample rate (default " << samplerate << ")\n";
            oss << "    population <number>     Population size (default " << population_size << ")\n";
            oss << "    iteration <number>      Iteration count (default " << iteration_cnt << ")\n";
            return oss.str();
        }
    };
    inline std::ostream &operator<<(std::ostream &os, const Options &options)
    {
        options.stream(os);
        return os;
    }
} 

#endif

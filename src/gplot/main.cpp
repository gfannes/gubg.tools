#include "gubg/OptionParser.hpp"
#include "gubg/parse/tree/Parser.hpp"
#include "gubg/string_algo/algo.hpp"
#include "gubg/mss.hpp"
#include <iostream>
#include <fstream>
using namespace std;

namespace app { 
    struct Options
    {
        std::string help;
        std::string input_fn;
        std::string output_fn;
        std::string x;
        std::string y;
    };

    bool parse(Options &options, gubg::OptionParser::Args &args)
    {
        MSS_BEGIN(bool);
        gubg::OptionParser parser("gplot: extracts info from tree output for plotting with gnuplot");
        parser.add_switch('h', "help", "Print this help", [&](){options.help = parser.help();});
        parser.add_mandatory('i', "input", "Input filename", [&](std::string str){options.input_fn = str;});
        parser.add_mandatory('o', "output", "Output filename", [&](std::string str){options.output_fn = str;});
        parser.add_mandatory('x', "x", "X path", [&](std::string str){options.x = str;});
        parser.add_mandatory('y', "y", "Y path", [&](std::string str){options.y = str;});

        MSS(parser.parse(args));
        MSS_END();
    }

    using Path = vector<string>;

    class Parser: public gubg::parse::tree::Parser_crtp<Parser>
    {
    public:
        Parser(std::ofstream &fo, Path ypath): fo_(fo), ypath_(ypath)
        {
            fo_ << "$dataset << EOD" << endl;
        }
        ~Parser()
        {
            fo_ << "EOD" << endl;
            fo_ << "plot $dataset using 1:2 with lines" << endl;
            fo_ << "pause mouse" << endl;
        }

        bool tree_node_open(std::string str)
        {
            MSS_BEGIN(bool, "");
            if (!match_ || depth_ > ypath_.size()-2 || str != ypath_[depth_])
                match_ = false;
            L(C(str)C(depth_)C(match_));
            ++depth_;
            MSS_END();
        }
        bool tree_attr(std::string key, std::string value)
        {
            MSS_BEGIN(bool, "");
            L(C(key)C(value)C(depth_)C(match_));
            if (match_ && depth_ == ypath_.size()-1 && key == ypath_.back())
            {
                L("MATCH");
                fo_ << ix_ << ' ' << value << endl;
                ++ix_;
            }
            MSS_END();
        }
        bool tree_attr_done() { return true; }
        bool tree_node_close()
        {
            MSS_BEGIN(bool);
            --depth_;
            if (depth_ == 0)
                match_ = (ypath_.size() >= 2);
            MSS_END();
        }
        bool tree_text(std::string str) { return true; }

    private:
        std::ofstream &fo_;
        unsigned int ix_ = 0;
        unsigned int depth_ = 0;
        Path ypath_;
        bool match_ = (ypath_.size() >= 2);
        Path::iterator y_ = ypath_.begin();
    };

    bool main(gubg::OptionParser::Args &args)
    {
        MSS_BEGIN(bool);

        Options options;
        MSS(parse(options, args));

        if (!options.help.empty())
        {
            std::cout << options.help;
            MSS_RETURN_OK();
        }

        std::ifstream fi(options.input_fn);
        MSS(fi.good(), cout << "Error: Invalid input file \"" << options.input_fn << "\"" << endl);
        std::ofstream fo(options.output_fn);
        MSS(fo.good(), cout << "Error: Invalid output file \"" << options.output_fn << "\"" << endl);

        MSS(!options.y.empty(), cout << "Error: No Y path given" << endl);
        Path ypath = gubg::string_algo::split<vector>(options.y, '.');

        Parser parser(fo, ypath);

        while (fi.good())
        {
            char ch; fi >> ch;
            MSS(parser.process(ch));
        }
        MSS(parser.stop());

        MSS_END();
    }
} 

int main(int argc, const char **argv)
{
    MSS_BEGIN(int);
    auto args = gubg::OptionParser::create_args(argc, argv);
    MSS(app::main(args), std::cout << "Error" << std::endl);
    std::cout << "Eveything went OK" << std::endl;
    MSS_END();
}

#include "gubg/OptionParser.hpp"
#include "gubg/parse/naft/Parser.hpp"
#include "gubg/string_algo/algo.hpp"
#include "gubg/wav/Writer.hpp"
#include "gubg/Range.hpp"
#include "gubg/mss.hpp"
#include <iostream>
#include <fstream>
#include <vector>
using namespace std;

namespace app { 
    using Strings = vector<string>;
    using Floats = vector<double>;
    using WavWriter = gubg::wav::Writer;
    using WavWriter_ptr = std::shared_ptr<WavWriter>;

    struct Options
    {
        std::string help;
        std::string input_fn;
        std::string output_fn;
        std::string path;
        std::string x;
        Strings ys;
    };

    bool parse(Options &options, gubg::OptionParser::Args &args)
    {
        MSS_BEGIN(bool);
        gubg::OptionParser parser("gplot: extracts info from naft output for plotting with gnuplot");
        parser.add_switch('h', "help", "Print this help", [&](){options.help = parser.help();});
        parser.add_mandatory('i', "input", "Input filename (default std::cin)", [&](std::string str){options.input_fn = str;});
        parser.add_mandatory('o', "output", "Output filename (.wav, any, default std::cout)", [&](std::string str){options.output_fn = str;});
        parser.add_mandatory('p', "path", "Object path, delimited by '.'", [&](std::string str){options.path = str;});
        parser.add_mandatory('x', "x", "X attribute (default ix)", [&](std::string str){options.x = str;});
        parser.add_mandatory('y', "y", "Y attribute(s)", [&](std::string str){options.ys.push_back(str);});

        MSS(parser.parse(args));
        MSS_END();
    }

    class Parser: public gubg::parse::naft::Parser_crtp<Parser>
    {
    public:
        Parser(std::ostream *os, WavWriter_ptr ww, Strings path, std::string x_attr, Strings y_attrs): os_(os), ww_(ww), wanted_path_(path), x_attr_(x_attr), y_attrs_(y_attrs), y_values_(y_attrs.size(), 0)
        {
            if (os_)
            {
                auto &os = *os_;
                os << "$dataset << EOD" << endl;
            }
        }
        ~Parser()
        {
            if (os_)
            {
                auto &os = *os_;
                os << "EOD" << endl;
                for (size_t ix = 0; ix < y_attrs_.size(); ++ix)
                {
                    os << (ix == 0 ? "plot" : ",") << " $dataset";
                    os << " using 1:" << ix+2;
                    os << " with lines";
                    if (x_attr_.empty())
                        os << " title \"" << y_attrs_[ix] << "\"";
                    else
                        os << " title \"" << x_attr_ << " x " << y_attrs_[ix] << "\"";
                }
                os << endl;
                os << "pause mouse" << endl;
            }
        }

        bool naft_node_open(std::string str)
        {
            MSS_BEGIN(bool);
            path_.push_back(str);
            MSS_END();
        }
        bool naft_attr(std::string key, std::string value)
        {
            MSS_BEGIN(bool);
            if (path_ == wanted_path_)
            {
                if (key == x_attr_)
                    x_value_ = value;

                {
                    auto dst = y_values_.begin();
                    for (auto k: y_attrs_)
                    {
                        if (key == k)
                            *dst = std::stod(value);
                        ++dst;
                    }
                }
            }
            MSS_END();
        }
        bool naft_attr_done()
        {
            MSS_BEGIN(bool);
            if (path_ == wanted_path_)
            {
                if (x_attr_.empty())
                {
                    if (os_)
                        *os_ << ix_;
                    ++ix_;
                }
                else
                {
                    if (os_)
                        *os_ << x_value_;
                    x_value_.clear();
                }

                if (os_)
                {
                    for (auto &v: y_values_)
                        *os_ << ' ' << v;
                    *os_ << endl;
                }
                if (ww_)
                    MSS(ww_->add_sample(y_values_));
                std::fill(RANGE(y_values_), 0);
            }
            MSS_END();
        }
        bool naft_node_close()
        {
            MSS_BEGIN(bool);
            path_.pop_back();
            MSS_END();
        }
        bool naft_text(std::string str) { return true; }

    private:
        std::ostream *os_ = nullptr;
        WavWriter_ptr ww_;
        unsigned int ix_ = 0;
        const Strings wanted_path_;
        Strings path_;
        const std::string x_attr_;
        std::string x_value_;
        const Strings y_attrs_;
        Floats y_values_;
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

        std::istream *is = &std::cin;
        std::ifstream fi;
        if (!options.input_fn.empty())
        {
            fi.open(options.input_fn);
            MSS(fi.good(), cout << "Error: Invalid input file \"" << options.input_fn << "\"" << endl);
            is = &fi;
        }

        std::ostream *os = nullptr;
        std::ofstream fo;
        WavWriter_ptr wav_writer;

        auto has_extension = [](const std::string &fn, const std::string &ext)
        {
            return (fn.size() < ext.size()) ? false : (fn.substr(fn.size()-ext.size(), ext.size()) == ext);
        };

        if (false) {}
        else if (has_extension(options.output_fn, ".wav"))
        {
            wav_writer.reset(new gubg::wav::Writer(options.output_fn, options.ys.size(), 48000));
        }
        else if (!options.output_fn.empty())
        {
            fo.open(options.output_fn);
            MSS(fo.good(), cout << "Error: Invalid output file \"" << options.output_fn << "\"" << endl);
            os = &fo;
        }
        else
        {
            os = &std::cout;
        }

        MSS(!options.path.empty(), cout << "Error: No object path given" << endl);
        Strings path = gubg::string_algo::split<vector>(options.path, '.');

        MSS(!options.ys.empty(), cout << "Error: No Y attribute(s) given" << endl);

        Parser parser(os, wav_writer, path, options.x, options.ys);

        while (is->good())
        {
            char ch; *is >> ch;
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
    MSS_END();
}

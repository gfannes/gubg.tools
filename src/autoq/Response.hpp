#ifndef HEADER_autoq_Response_hpp_ALREADY_INCLUDED
#define HEADER_autoq_Response_hpp_ALREADY_INCLUDED

#include <gubg/Strange.hpp>
#include <gubg/file/system.hpp>
#include <gubg/mss.hpp>
#include <vector>
#include <ostream>
#include <fstream>
#include <algorithm>

namespace autoq { 

    struct FrequencyAmplitude
    {
        double frequency = 0;
        double amplitude = 0;
    };
    inline std::ostream &operator<<(std::ostream &os, const FrequencyAmplitude &fa)
    {
        os << "[FrequencyAmplitude](frequency:" << fa.frequency << ")(amplitude:" << fa.amplitude << ")";
        return os;
    }

    class Response
    {
    public:
        bool load(const std::string &filename)
        {
            MSS_BEGIN(bool);

            fas_.clear();

            std::string content;
            MSS(gubg::file::read(content, filename));

            gubg::Strange strange(content);

            const std::string whitespace = " \t";
            for (gubg::Strange line; strange.pop_line(line);)
            {
                line.strip(whitespace);
                if (line.empty())
                    continue;
                FrequencyAmplitude fa;
                MSS(line.pop_float(fa.frequency));
                MSS(line.pop_if(' '));
                MSS(line.pop_float(fa.amplitude));
                fas_.push_back(fa);
            }

            MSS_END();
        }
        bool save(const std::string &filename) const
        {
            MSS_BEGIN(bool);
            std::ofstream fo{filename};
            MSS(fo.good());
            for (const auto &fa: fas_)
                fo << fa.frequency << ' ' << fa.amplitude << std::endl;
            MSS_END();
        }
        void stream(std::ostream &os) const
        {
            for (const auto &fa: fas_)
                os << fa << std::endl;
        }

        std::vector<double> frequencies() const
        {
            std::vector<double> ary(fas_.size());
            std::transform(RANGE(fas_), ary.begin(), [](const auto &fa){return fa.frequency;});
            return ary;
        }

    private:
        std::vector<FrequencyAmplitude> fas_;
    };
    inline std::ostream &operator<<(std::ostream &os, const Response &response)
    {
        response.stream(os);
        return os;
    }

} 

#endif

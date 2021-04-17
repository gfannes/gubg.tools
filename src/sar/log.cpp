#include <sar/log.hpp>
#include <iostream>
#include <fstream>

namespace sar { namespace log { 

    namespace  { 
        int s_level = 0;
        std::ofstream s_devnull;
    } 
    std::ostream &error()
    {
        return std::cout;
    }

    void set_level(int level)
    {
        s_level = level;
    }
    std::ostream &os(int level)
    {
        if (s_level >= level)
            return std::cout;
        return s_devnull;
    }

} } 

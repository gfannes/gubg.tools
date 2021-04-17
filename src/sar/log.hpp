#ifndef HEADER_sar_log_hpp_ALREADY_INCLUDED
#define HEADER_sar_log_hpp_ALREADY_INCLUDED

#include <ostream>

namespace sar { namespace log { 

    std::ostream &error();

    void set_level(int level);
    std::ostream &os(int level);

} } 

#endif

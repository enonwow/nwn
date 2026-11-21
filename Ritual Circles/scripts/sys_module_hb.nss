// sys_module_hb.nss - module OnHeartbeat (fires every ~6 seconds)
// Hook: Module Properties -> Events -> OnHeartbeat
//
// Advances channeling timers and clears expired cooldowns.
// Runs one SQL read per call (two queries); cost is negligible.

#include "lib_rit"

void main()
{
    RitProcessHeartbeat();
}

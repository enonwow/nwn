#include "lib_trap"

// ================================================================
// trap_hb.nss  —  EVENT_SCRIPT_PLACEABLE_ON_HEARTBEAT for placed traps
// ================================================================

void main()
{
    TrapHeartbeat(OBJECT_SELF);
}

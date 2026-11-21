#include "lib_trap"

// ================================================================
// trap_def.nss  —  EVENT_SCRIPT_PLACEABLE_ON_USED for placed traps
//
// A player who uses (right-clicks) a placed trap attempts to disarm it.
// ================================================================

void main()
{
    TrapTryDefuse(OBJECT_SELF);
}

#include "lib_phy"

// Called from the module's OnPlayerDeath event script.
// Place: ExecuteScript("sys_on_death", OBJECT_SELF); — inside your main death handler
// or set this as the OnPlayerDeath script directly if no other death logic exists.

void main()
{
    object oPC = GetLastPlayerDied();
    PhyHandleDeath(oPC);
}

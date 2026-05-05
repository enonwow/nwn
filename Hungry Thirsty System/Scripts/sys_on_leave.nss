// =============================================================================
// sys_on_leave.nss
// =============================================================================
// Module OnClientExit event. Tears down the HUD.
// State persists in the SQL row (timestamp-based decay) so no save needed.
// =============================================================================

#include "lib_rations"

void main()
{
    object oPC = GetExitingObject();
    if(!GetIsPC(oPC)) return;

    DestroyRationsHud(oPC);
}

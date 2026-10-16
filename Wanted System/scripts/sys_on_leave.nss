// =============================================================================
// sys_on_leave.nss
// =============================================================================
// Module OnClientExit event. Tears down NUI windows.
// Heat state persists in the campaign DB via timestamps — no extra writes needed.
// =============================================================================

#include "lib_wnt"

void main()
{
    object oPC = GetExitingObject();
    if(!GetIsPC(oPC)) return;

    WantedDestroyPanel(oPC);
    WantedDestroyHud(oPC);
}

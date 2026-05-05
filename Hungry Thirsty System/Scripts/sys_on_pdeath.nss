// =============================================================================
// sys_on_pdeath.nss
// =============================================================================
// Module OnPlayerDeath event. Resets both hunger and thirst to RAT_DEATH_RESET
// (50%) so the player is not punished too harshly on respawn.
// =============================================================================

#include "lib_rations"

void main()
{
    object oPC = GetLastPlayerDied();
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    RationsOnPlayerDeath(oPC);
}

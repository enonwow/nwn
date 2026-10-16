// =============================================================================
// sys_on_enter.nss
// =============================================================================
// Module OnClientEnter event.
// Ensures the player has a Wanted row in the campaign DB, re-applies the
// correct debuffs for their current heat, and spawns the HUD after a 1-second
// delay (NUI created immediately on enter can race the client settling).
// =============================================================================

#include "lib_wnt"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    WantedEnsureRow(oPC);

    // Align cached last_level with the true current heat on login
    // (heat may have decayed while the player was offline).
    string sUuid = GetObjectUUID(oPC);
    struct WantedState s = WantedGetState(sUuid);
    int nHeat = WantedCalcHeat(s);
    int nLvl  = WantedGetLevel(nHeat);

    WantedApplyEffects(oPC, nLvl);
    WantedWriteLastLevel(sUuid, nLvl);

    // 1-second delay: NUI requires the player's area to be fully loaded.
    DelayCommand(1.0, WantedCreateHud(oPC));
}

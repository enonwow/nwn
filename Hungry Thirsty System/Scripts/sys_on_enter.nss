// =============================================================================
// sys_on_enter.nss
// =============================================================================
// Module OnClientEnter event. Ensures the player has a Rations row, then
// spawns the HUD after a 1-second delay (the player area must be valid first;
// creating NUI on enter immediately can race the engine settling state).
// =============================================================================

#include "lib_rations"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    RationsEnsureRow(oPC);

    // On first apply after login: align cached threshold with current state.
    string sUuid = GetObjectUUID(oPC);
    int nLvlH = RationsGetThresholdLevel(RationsGetCurrentHunger(oPC));
    int nLvlT = RationsGetThresholdLevel(RationsGetCurrentThirst(oPC));
    RationsApplyDebuffH(oPC, nLvlH);
    RationsApplyDebuffT(oPC, nLvlT);
    RationsSetLastThH(sUuid, nLvlH);
    RationsSetLastThT(sUuid, nLvlT);

    DelayCommand(1.0, CreateRationsHud(oPC));
}

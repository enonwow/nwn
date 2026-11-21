#include "lib_trap"

// ================================================================
// sys_on_target.nss  —  OnModulePlayerTarget
//
// Fires when a PC finishes targeting after TrapEnterDeployMode().
// Plug this into the module's OnPlayerTarget event.
// ================================================================

void main()
{
    object oPC = GetLastPlayerToDoCommand();
    if(!GetIsPC(oPC)) return;

    if(!GetLocalInt(oPC, TRAP_LVAR_DEPLOYING)) return;

    // Player targeted a tile / floor position
    vector vPos    = GetTargetingModeSelectedPosition();
    object oArea   = GetArea(oPC);
    location lTarget = Location(oArea, vPos, GetFacing(oPC));

    // Reject if too far from player (must place within reach)
    float fDist = GetDistanceBetweenLocations(GetLocation(oPC), lTarget);
    if(fDist > 5.0)
    {
        SendMessageToPC(oPC, "[Pułapki] Zbyt daleko. Musisz umieścić pułapkę w zasięgu 5 metrów.");
        DeleteLocalInt   (oPC, TRAP_LVAR_DEPLOYING);
        DeleteLocalString(oPC, TRAP_LVAR_DEPLOY_TYPE);
        DeleteLocalInt   (oPC, TRAP_LVAR_DEPLOY_DARM);
        DeleteLocalInt   (oPC, TRAP_LVAR_DETECT_DC);
        return;
    }

    TrapPlaceAtLocation(oPC, lTarget);
}

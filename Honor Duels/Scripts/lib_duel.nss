// Honor Duels — public facade.
// Includes both UI and flow modules so callers only need #include "lib_duel".
#include "lib_duel_ui"
#include "lib_duel_hud"
#include "lib_duel_flow"

void DuelStartChallengeTargeting(object oPC)
{
    if(DuelHasAnyActive(GetObjectUUID(oPC)))
    {
        SendMessageToPC(oPC, "[Duel] Finish your current duel first.");
        return;
    }
    SendMessageToPC(oPC,
        "[Duel] Choose your foe within sight. Liars spit on the code.");
    EnterTargetingMode(oPC, OBJECT_TYPE_CREATURE);
}

void DuelOnPlayerTarget(object oPC)
{
    object oTarget = GetTargetingModeSelectedObject();
    if(!GetIsObjectValid(oTarget))
    {
        SendMessageToPC(oPC, "[Duel] Selection canceled.");
        return;
    }
    if(!GetIsPC(oTarget))
    {
        SendMessageToPC(oPC, "[Duel] Only living players may answer the code of honor.");
        return;
    }
    if(oTarget == oPC)
    {
        SendMessageToPC(oPC, "[Duel] You cannot challenge yourself.");
        return;
    }
    DuelShowChallengeConfig(oPC, GetObjectUUID(oTarget), GetName(oTarget));
}

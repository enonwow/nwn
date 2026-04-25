// Honor Duels — public facade.
// Includes both UI and flow modules so callers only need #include "lib_duel".
#include "lib_duel_ui"
#include "lib_duel_hud"
#include "lib_duel_flow"

void DuelStartChallengeTargeting(object oPC)
{
    if(DuelHasAnyActive(GetObjectUUID(oPC)))
    {
        SendMessageToPC(oPC, "[Pojedynek] Konczysz najpierw obecny pojedynek.");
        return;
    }
    SendMessageToPC(oPC,
        "[Pojedynek] Wybierz wroga w zasiegu wzroku. Klamcy spluwaja na kodeks.");
    EnterTargetingMode(oPC, OBJECT_TYPE_CREATURE);
}

void DuelOnPlayerTarget(object oPC)
{
    object oTarget = GetTargetingModeSelectedObject();
    if(!GetIsObjectValid(oTarget))
    {
        SendMessageToPC(oPC, "[Pojedynek] Wybor anulowany.");
        return;
    }
    if(!GetIsPC(oTarget))
    {
        SendMessageToPC(oPC, "[Pojedynek] Tylko grajacy moga stanac do honorowej walki.");
        return;
    }
    if(oTarget == oPC)
    {
        SendMessageToPC(oPC, "[Pojedynek] Nie wyzywaj samego siebie.");
        return;
    }
    DuelShowChallengeConfig(oPC, GetObjectUUID(oTarget), GetName(oTarget));
}

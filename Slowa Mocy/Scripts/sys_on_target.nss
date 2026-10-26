#include "lib_slm"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetIsObjectValid(oPC)) return;

    if(!GetLocalInt(oPC, SLM_LVAR_TARGETING)) return;
    DeleteLocalInt(oPC, SLM_LVAR_TARGETING);

    int nElem   = GetLocalInt(oPC, SLM_LVAR_INVOKE_ELEM);
    int nTarget = GetLocalInt(oPC, SLM_LVAR_INVOKE_TGT);
    int nPower  = GetLocalInt(oPC, SLM_LVAR_INVOKE_POW);

    DeleteLocalInt(oPC, SLM_LVAR_INVOKE_ELEM);
    DeleteLocalInt(oPC, SLM_LVAR_INVOKE_TGT);
    DeleteLocalInt(oPC, SLM_LVAR_INVOKE_POW);

    object oSelected = GetTargetingModeSelectedObject();

    if(!GetIsObjectValid(oSelected))
    {
        SendMessageToPC(oPC, "[Słowa Mocy] Inkantacja rozwiała się w powietrzu.");
        return;
    }

    SlmApplyEffect(oPC, nElem, nTarget, nPower, oSelected);
}

// sys_on_enter.nss  –  Corruption: OnClientEnter hook
// Restores cached corruption value and reapplies permanent effects.

#include "lib_cor"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    int nCorruption = CorDbGetCorruption(oPC);
    SetLocalInt(oPC, COR_LVAR_CORRUPTION, nCorruption);

    CorApplyEffects(oPC);

    int nStage = CorGetStage(nCorruption);
    if(nStage >= COR_STAGE_TAINTED)
        SendMessageToPC(oPC,
            "[Korupcja] Twoja dusza nosi piętno " + CorStageName(nStage) +
            " (" + IntToString(nCorruption) + "/100).");
}

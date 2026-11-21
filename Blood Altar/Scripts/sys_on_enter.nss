// sys_on_enter.nss — Blood Altar: odswiezanie VFX korupcji przy logowaniu (OnClientEnter)
#include "lib_balt"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    BaltDecayOnEnter(oPC);
    int nCorruption = BaltGetCorruption(oPC);
    BaltApplyCorruptionVFX(oPC, nCorruption);

    if(nCorruption >= BALT_CORRUPT_HIGH)
        SendMessageToPC(oPC, "[Oltarz] Skalanie twojej duszy jest wysokie ("
                      + IntToString(nCorruption) + "%). Unikaj ciemnych oltarzy.");
}

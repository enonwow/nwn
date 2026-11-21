#include "lib_sgl"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    SglRegisterPlayer(oPC);

    int nCount = SglGetPlayerSigilCount(oPC);
    if(nCount > 0)
    {
        string sMsg = "[Znak Ochronny] Masz " + IntToString(nCount)
            + " aktywnych znaków ochronnych.";
        DelayCommand(3.0, SendMessageToPC(oPC, sMsg));
    }
}

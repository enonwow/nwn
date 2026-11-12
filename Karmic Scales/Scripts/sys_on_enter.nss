#include "lib_ks"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    int nKarma = KsGetKarma(oPC);
    KsApplyPassiveEffects(oPC, nKarma);

    if(nKarma <= -50)
    {
        SendMessageToPC(oPC, "[Szale Przeznaczenia] Mrok wciąż spoczywa w twoim sercu. ("
            + IntToString(nKarma) + ")");
    }
    else if(nKarma >= 50)
    {
        SendMessageToPC(oPC, "[Szale Przeznaczenia] Blask wiary towarzyszy ci nadal. (+"
            + IntToString(nKarma) + ")");
    }
}

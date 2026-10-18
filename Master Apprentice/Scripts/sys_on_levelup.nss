#include "lib_ma"

void main()
{
    object oPC = GetPCLevellingUp();
    if(!GetIsPC(oPC)) return;

    int nNewLevel = GetHitDice(oPC);
    MaOnApprenticeLevelUp(oPC, nNewLevel);
}

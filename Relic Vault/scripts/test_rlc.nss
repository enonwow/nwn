#include "lib_rlc"

// Place this script in the OnUsed event of a placeable (e.g. a stone altar or chest).
// Using it opens the Relic Vault window and grants 2000 gp if the PC is broke.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    if(GetGold(oPC) < 2000)
        GiveGoldToCreature(oPC, 2000);

    RlcShowWindow(oPC);
}

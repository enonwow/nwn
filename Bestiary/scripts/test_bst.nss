// test_bst.nss — OnUsed for the Bestiarist's Tome placeable
// Set this as the OnUsed script on any placeable (e.g. an ancient tome or lectern)
// to open the Codex Bestiarum for the interacting PC.
#include "lib_bst"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    BstOpenCodex(oPC);
}

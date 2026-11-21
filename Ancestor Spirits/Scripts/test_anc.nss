// test_anc.nss — Ancestor Spirits: OnUsed script for altar placeable
// Assign this as the OnUsed event of any placeable that serves as an Ancestral Altar.
#include "lib_anc"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    AncOpen(oPC);
}

#include "lib_rf"

// OnUsed script for a "Kuźnia Runiczna" placeable.
// Place this script in the OnUsed event of any placeable acting as the forge.

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    RFOpenForge(oPC);
}

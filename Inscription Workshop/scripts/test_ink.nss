#include "lib_ink"

// OnUsed script for the Inscription Workshop placeable.
// Set this as the OnUsed event on a desk/lectern placeable.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    InkCreateWindow(oPC);
}

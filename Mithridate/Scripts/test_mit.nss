#include "lib_mit"

// OnUsed on the Apothecary Table placeable.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    MitShowWindow(oPC);
}

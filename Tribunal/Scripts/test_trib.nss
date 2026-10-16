#include "lib_trib"

// OnUsed script for a "Tablica Trybunału" placeable.
// Place a placeable in your test area, assign this script to its OnUsed event.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    TribOpenWindow(oPC);
}

#include "lib_sgl"

// OnUsed script for the Sigil Wards demo placeable.
// Place a "Tablica Znaków Ochronnych" placeable in the toolset,
// set its OnUsed script to "test_sgl", then activate it in-game.

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    CreateSglWindow(oPC);
}

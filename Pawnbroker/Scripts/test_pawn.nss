#include "lib_pawn"

// OnUsed script for a Zastawnik placeable / NPC.
// Drop onto any placeable's OnUsed event to test the module.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    CreatePawnWindow(oPC);
}

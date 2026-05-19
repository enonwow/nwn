#include "lib_bur"

// OnUsed script for the "Plyta Nagrobna" (Grave Slab / Undertaker's Board) placeable.
// Set this as the OnUsed script on any placeable in the Toolset.
// The placeable acts as the portal to the burial system for nearby players.

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    BurCreateWindow(oPC);
}

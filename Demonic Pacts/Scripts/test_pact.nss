#include "lib_pact"

// Attach to a placeable's OnUsed event.
// The placeable acts as the physical Altar of Covenants in the world.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    CreatePactWindow(oPC);
}

#include "lib_sth"

// Attach to a placeable's OnUsed event.
// The placeable represents the keep's management board; using it opens the
// Stronghold UI for the triggering PC.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    StrongholdOpen(oPC);
}

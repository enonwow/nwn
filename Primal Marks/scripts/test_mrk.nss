#include "lib_mrk"

// Place a placeable (Campfire, Altar, or any workbench) in the module
// and set its OnUsed script to "test_mrk".
// Using it opens the Primal Marks window for the PC.
//
// For testing essence gain without killing creatures:
//   SetLocalInt(oPC, "MRK_DEBUG_ESS", 1) in a debug console,
//   then call MrkOnCreatureDeath passing a dummy creature object.

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    MrkOpenWindow(oPC);
}

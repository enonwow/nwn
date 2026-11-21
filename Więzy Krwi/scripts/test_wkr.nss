#include "lib_wkr"

// OnUsed script for the demo placeable (e.g. a blood-stained stone altar).
// Place an object with this script as its OnUsed event to test the module.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    WkrOpen(oPC);
}

// OnUsed script for a test placeable.
// Place a placeable with this script to open the Effigy Curse UI.
// For demo purposes only — remove from production or restrict by DM/faction.

#include "lib_eff"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    CreateEffigyWindow(oPC);
}

#include "lib_ins"

// Place this script in the OnUsed event of a placeable with tag "ins_tablet".
// The placeable's tag is used as the inscription namespace, so tablets in
// different locations should have distinct tags (e.g. "ins_tablet_tavern",
// "ins_tablet_graveyard").

void main()
{
    object oPC     = GetLastUsedBy();
    object oTablet = OBJECT_SELF;

    if(!GetIsPC(oPC)) return;

    InsOpenWindow(oPC, oTablet);
}

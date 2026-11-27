#include "lib_bb"

// Place this as OnUsed script on a placeable (e.g. a cage or totem).
// Using it opens the Beast Binder window for the activating PC.

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    BbOpenWindow(oPC);
}

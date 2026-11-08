// Demo / test script for the Forge Trial module.
// Place this as the OnUsed event of a Forge placeable in the toolset.
// When a PC activates the forge, the Forge Trial NUI window opens.

#include "lib_frg"

void main()
{
    object oPC = GetLastUsedBy();

    if(!GetIsPC(oPC))
        return;

    // Basic sanity check: PC must have at least one forgeable item equipped
    int bHasItem = FALSE;
    int i;
    for(i = 0; i < FRG_SLOT_COUNT; i++)
    {
        if(GetIsObjectValid(FrgGetSlotItem(oPC, i)))
        {
            bHasItem = TRUE;
            break;
        }
    }

    if(!bHasItem)
    {
        FloatingTextStringOnCreature(
            "Kuźnia nie zna próżni. Załóż broń lub zbroję, by przystąpić do próby.",
            oPC, FALSE);
        return;
    }

    FrgOpenWindow(oPC);
}

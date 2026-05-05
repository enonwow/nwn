// =============================================================================
// sys_on_activate.nss
// =============================================================================
// Module OnActivateItem event. Routes activated items through the Rations
// consumption check.
//
// For an item to fire this event it must have the "Cast Spell: Unique Power"
// (or any "Cast Spell" with itself as the target) item property.
// =============================================================================

#include "lib_rations"

void main()
{
    object oPC   = GetItemActivator();
    object oItem = GetItemActivated();

    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;
    if(!GetIsObjectValid(oItem))      return;

    RationsTryEatItem(oPC, oItem);
}

#include "lib_bs_def"

void main()
{
    object oPC = GetExitingObject();
    if(!GetIsPC(oPC)) return;

    // Remove spirit bonuses from all potentially equipped haunted weapons.
    // Iterating both hands is sufficient — spirits only activate in right hand,
    // but we clean both to handle edge cases from item swaps.
    object oRH = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
    object oLH = GetItemInSlot(INVENTORY_SLOT_LEFTHAND,  oPC);

    if(GetIsObjectValid(oRH)) BsRemoveBonuses(oPC, GetObjectUUID(oRH));
    if(GetIsObjectValid(oLH)) BsRemoveBonuses(oPC, GetObjectUUID(oLH));
}

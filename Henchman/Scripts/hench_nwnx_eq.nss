// hench_nwnx_eq.nss
// Handler for NWNX_ON_ITEM_EQUIP/UNEQUIP_AFTER.
// OBJECT_SELF = creature that equipped/unequipped the item.
// If it's a player's henchman - persist its state.
#include "lib_hench_def"

void main()
{
    object oMaster = GetMaster(OBJECT_SELF);
    if(!GetIsObjectValid(oMaster) || !GetIsPC(oMaster)) return;
    HenchSave(oMaster);
}

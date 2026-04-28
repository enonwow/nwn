// hench_nwnx_inv.nss
// Handler for NWNX_ON_INVENTORY_ADD/REMOVE_ITEM_AFTER.
// OBJECT_SELF = the container whose inventory changed (creature or placeable).
// If it's a player's henchman - persist its state.
#include "lib_hench_def"

void main()
{
    object oMaster = GetMaster(OBJECT_SELF);
    if(!GetIsObjectValid(oMaster) || !GetIsPC(oMaster)) return;
    HenchSave(oMaster);
}

// hench_nwnx_sub.nss
// Subscribes NWNX events for persisting henchman state.
// Called once from sys_on_load at module start.
#include "nwnx_events"

void main()
{
    NWNX_Events_SubscribeEvent("NWNX_ON_ITEM_EQUIP_AFTER",            "hench_nwnx_eq");
    NWNX_Events_SubscribeEvent("NWNX_ON_ITEM_UNEQUIP_AFTER",          "hench_nwnx_eq");
    NWNX_Events_SubscribeEvent("NWNX_ON_INVENTORY_ADD_ITEM_AFTER",    "hench_nwnx_inv");
    NWNX_Events_SubscribeEvent("NWNX_ON_INVENTORY_REMOVE_ITEM_AFTER", "hench_nwnx_inv");
    NWNX_Events_SubscribeEvent("NWNX_ON_REMOVE_ASSOCIATE_AFTER",      "hench_nwnx_rm");
}

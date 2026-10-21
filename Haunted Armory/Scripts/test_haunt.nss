// test_haunt.nss
// OnUsed script for a test Placeable in the demo area.
//
// Behaviour:
//   1. If the PC is wielding a weapon, open the Haunted Armory panel for it.
//   2. If no weapon is in hand but a test item with tag "haunt_test_sword"
//      exists in inventory, equip it and open the panel.
//   3. If neither is true, give the PC a test sword and a Holy Water flask.
//
// Place this script on any Placeable's OnUsed event.

#include "lib_haunt"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Check right then left hand.
    object oWeap = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
    if(!GetIsObjectValid(oWeap))
        oWeap = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oPC);

    // Also accept any weapon the PC happens to have in inventory.
    if(!GetIsObjectValid(oWeap))
    {
        object oItem = GetFirstItemInInventory(oPC);
        while(GetIsObjectValid(oItem))
        {
            int nBase = GetBaseItemType(oItem);
            // Accept most melee base item types.
            if(nBase == BASE_ITEM_LONGSWORD || nBase == BASE_ITEM_SHORTSWORD
            || nBase == BASE_ITEM_BASTARDSWORD || nBase == BASE_ITEM_GREATSWORD
            || nBase == BASE_ITEM_DAGGER || nBase == BASE_ITEM_HANDAXE
            || nBase == BASE_ITEM_BATTLEAXE || nBase == BASE_ITEM_GREATAXE
            || nBase == BASE_ITEM_MORNINGSTAR || nBase == BASE_ITEM_MACE
            || nBase == BASE_ITEM_HALBERD || nBase == BASE_ITEM_SPEAR)
            {
                oWeap = oItem;
                break;
            }
            oItem = GetNextItemInInventory(oPC);
        }
    }

    if(!GetIsObjectValid(oWeap))
    {
        // Give the PC a basic longsword (resref: nw_wswls001) for testing
        // and one Holy Water flask tagged haunt_holy_water.
        oWeap = CreateItemOnObject("nw_wswls001", oPC);
        object oWater = CreateItemOnObject("nw_it_mpotion001", oPC);
        if(GetIsObjectValid(oWater))
        {
            SetTag(oWater, HAUNT_CLEANSE_TAG);
            SetName(oWater, "Święcona Woda");
        }
        SendMessageToPC(oPC,
            "[Oręże] Otrzymałeś miecz testowy i Święconą Wodę. "
            "Zabij kilka stworzeń, a wróć tu ponownie.");
        return;
    }

    // Force a dummy kill registration to allow testing without a real
    // creature — comment out or remove in production.
    if(GetIsObjectValid(oWeap))
    {
        string sUUID  = GetObjectUUID(oWeap);
        int    nKills = 0;
        json   jData  = HauntGetWeaponData(sUUID);
        if(JsonGetType(jData) != JSON_TYPE_NULL)
            nKills = JsonGetInt(JsonObjectGet(jData, "kill_count"));

        // Simulate 12 kills so the weapon reaches Level 1 for demo purposes.
        if(nKills < 12)
        {
            int i;
            for(i = nKills; i < 12; i++)
                HauntRecordKillSQL(sUUID, "Testowy Goblin", RACIAL_TYPE_HUMANOID_GOBLINOID);
        }
    }

    HauntOpenWindow(oPC, oWeap);
}

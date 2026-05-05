// =============================================================================
// test_rations.nss
// =============================================================================
// Hook this on a placeable's OnUsed event. Spawns 6 sample consumable items
// in the activator's inventory (3 food + 3 drink), each with the proper
// LocalInt restore values pre-set, and (re)creates the HUD if missing.
//
// Sample items use blueprint resref "nw_it_picnic001" as a generic stand-in;
// edit if you ship your own food blueprints.
// =============================================================================

#include "lib_rations"

// Helper: spawn an item, assign tag/name/restore values, place in inventory.
void TestRationsSpawn(object oPC, string sName, int nHunger, int nThirst)
{
    // Use a generic edible blueprint. Replace with your own resref(s) as
    // needed. Any item works as long as it has the "Cast Spell: Unique Power"
    // item property so the OnActivateItem event fires.
    object oItem = CreateItemOnObject("nw_it_picnic001", oPC, 1);
    if(!GetIsObjectValid(oItem)) return;

    SetName(oItem, sName);
    if(nHunger > 0) SetLocalInt(oItem, RAT_LVAR_IT_HUNGER, nHunger);
    if(nThirst > 0) SetLocalInt(oItem, RAT_LVAR_IT_THIRST, nThirst);
}

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // 3 foods
    TestRationsSpawn(oPC, "Bread",        20, 0);
    TestRationsSpawn(oPC, "Cooked Meat",  35, 0);
    TestRationsSpawn(oPC, "Hearty Feast", 60, 10);

    // 3 drinks
    TestRationsSpawn(oPC, "Waterskin",     0, 25);
    TestRationsSpawn(oPC, "Tankard of Ale", 5, 40);
    TestRationsSpawn(oPC, "Bottle of Wine", 0, 60);

    SendMessageToPC(oPC, "Rations test items added to your inventory. "
        + "Activate each (radial menu) to consume.");

    // Make sure the HUD is up.
    if(NuiFindWindow(oPC, RAT_HUD_WIN) == 0) CreateRationsHud(oPC);
}

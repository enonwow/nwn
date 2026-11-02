// test_wf.nss — OnUsed script for the campfire test placeable.
// Place a campfire placeable in the toolset and assign this as its OnUsed script.
// Optionally set the local int "WF_DANGER" on the placeable to 0-5 to test
// different danger levels.

#include "lib_wf"

// Creates a stack of test ingredient items in the PC's inventory
void CreateTestIngredients(object oPC)
{
    // Herb bundle (wf_herb_fire, wf_herb_heal, wf_herb_mind, wf_herb_power)
    // Simple misc items; resref "nw_it_mabltherb" is a base game herb item —
    // set its tag in the toolset or create with CreateItemOnObject.

    // We create blank containers with the right tags using CreateObject.
    // The recommended approach for a real module is to add these items to the HAK.

    string aTags[5];
    aTags[0] = "wf_herb_fire";
    aTags[1] = "wf_herb_heal";
    aTags[2] = "wf_herb_mind";
    aTags[3] = "wf_herb_power";
    aTags[4] = "wf_ration";

    // CreateItemOnObject requires a resref; use a generic herb resref from base game.
    // "nw_it_mabltherb" (Magical Beast Herb) is a common misc item.
    string sResRef = "nw_it_mabltherb";

    int i;
    for(i = 0; i < 5; i++)
    {
        object oItem = CreateItemOnObject(sResRef, oPC, 1);
        if(GetIsObjectValid(oItem))
            SetTag(oItem, aTags[i]);
    }

    // Also add meat and dark water
    object oMeat = CreateItemOnObject(sResRef, oPC, 1);
    if(GetIsObjectValid(oMeat))
        SetTag(oMeat, "wf_meat");

    object oWater = CreateItemOnObject(sResRef, oPC, 1);
    if(GetIsObjectValid(oWater))
        SetTag(oWater, "wf_dark_water");
}

void main()
{
    object oPC  = GetLastUsedBy();
    object oCf  = OBJECT_SELF;

    if(!GetIsPC(oPC)) return;

    // Set danger 2 for testing if not already set
    if(!GetLocalInt(oCf, WF_OVAR_DANGER))
        SetLocalInt(oCf, WF_OVAR_DANGER, 2);

    // Give test ingredients only if PC has none
    if(!GetIsObjectValid(GetItemPossessedBy(oPC, "wf_herb_fire")))
        CreateTestIngredients(oPC);

    WfOpenWindow(oPC, oCf);
}

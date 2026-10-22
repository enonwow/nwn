// OnUsed script for a test placeable with tag "bcn_test_fire".
// Place a placeable in the toolset, set its OnUsed to this script.
// The script sets up demo BCN variables, gives the PC test items, and opens the UI.
#include "lib_bcn"

void GiveDemoItem(object oPC, string sResRef, string sTag, string sName, int nStack)
{
    if(BcnCountItemsByTag(oPC, sTag) >= nStack) return;
    object oItem = CreateItemOnObject(sResRef, oPC, nStack, FALSE, sTag);
    if(GetIsObjectValid(oItem))
        SetName(oItem, sName);
}

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    object oBeacon = OBJECT_SELF;

    // Set up beacon metadata if not configured in the toolset
    if(GetLocalString(oBeacon, BCN_VAR_TYPE) == "")
        SetLocalString(oBeacon, BCN_VAR_TYPE, BCN_TYPE_FIRE);
    if(GetLocalString(oBeacon, BCN_VAR_NAME) == "")
        SetLocalString(oBeacon, BCN_VAR_NAME, "Latarnia Wiecznego Ognia");

    string sType = GetLocalString(oBeacon, BCN_VAR_TYPE);

    // Give the PC demo fuel matching the beacon's current type
    if(sType == BCN_TYPE_FIRE)
        GiveDemoItem(oPC, "nw_it_torch001", BCN_ITEM_TINDER,     "Hubka [demo]", 5);
    else if(sType == BCN_TYPE_SHADOW)
        GiveDemoItem(oPC, "nw_it_msmlmisc08", BCN_ITEM_SHADOW_ASH, "Popiol Cienia [demo]", 5);
    else if(sType == BCN_TYPE_SPIRIT)
        GiveDemoItem(oPC, "nw_it_msmlmisc07", BCN_ITEM_INCENSE,   "Kadzidlo [demo]", 5);
    else if(sType == BCN_TYPE_BLOOD)
        GiveDemoItem(oPC, "nw_it_mpotion012", BCN_ITEM_BLOOD_VIAL, "Fiolka Krwi [demo]", 5);
    else if(sType == BCN_TYPE_STONE)
        GiveDemoItem(oPC, "nw_it_msmlmisc09", BCN_ITEM_QUARTZ,    "Kwarc [demo]", 5);

    // Give purification reagent regardless
    GiveDemoItem(oPC, "nw_it_mpotion018", BCN_ITEM_HOLY_WATER, "Swiecona Woda [demo]", 2);

    BcnOpenWindow(oPC, oBeacon);
}

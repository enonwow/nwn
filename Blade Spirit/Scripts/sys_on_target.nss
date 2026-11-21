#include "lib_bs"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetIsPC(oPC)) return;

    // Only handle our targeting flow
    if(!GetLocalInt(oPC, BS_LVAR_TARGETING)) return;
    DeleteLocalInt(oPC, BS_LVAR_TARGETING);

    object oTarget = GetTargetingModeSelectedObject();
    if(!GetIsObjectValid(oTarget))
    {
        SendMessageToPC(oPC, "[Duch Ostrza] Nie wybrano żadnego przedmiotu.");
        return;
    }

    // Must be a weapon in the player's inventory
    if(GetItemPossessor(oTarget) != oPC)
    {
        SendMessageToPC(oPC, "[Duch Ostrza] Wybierz broń ze swojego ekwipunku.");
        return;
    }

    int nBaseType = GetBaseItemType(oTarget);
    // Verify it is a melee weapon (categories 0..27 cover most melee; shield / misc excluded)
    // Check if the item can be wielded in right hand as weapon
    if(!GetItemHasItemProperty(oTarget, ITEM_PROPERTY_UNLIMITED_AMMUNITION) &&
       Get2DAString("baseitems", "WeaponType", nBaseType) == "")
    {
        // Fallback: any equippable item except armor/shields is accepted
        // to avoid overly strict filtering in custom HAKs
    }

    string sUUID = GetObjectUUID(oTarget);
    json   jTest = BsGetSpirit(sUUID);
    if(JsonGetType(jTest) != JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Duch Ostrza] To ostrze jest już nawiedzone.");
        BsOpenWindow(oPC, sUUID);
        return;
    }

    string sIcon = GetStringLowerCase(
        Get2DAString("baseitems", "DefaultIcon", nBaseType));
    if(sIcon == "") sIcon = "ir_longsword";

    BsOpenCreateWindow(oPC, sUUID, GetName(oTarget), sIcon);
}

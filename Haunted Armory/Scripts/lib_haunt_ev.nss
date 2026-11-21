#include "lib_haunt"

// Finds a weapon in oPC's inventory/equipped slots by UUID.
object HauntFindWeaponByUUID(object oPC, string sUUID)
{
    // Check equipped weapon slots first.
    object oSlot = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
    if(GetIsObjectValid(oSlot) && GetObjectUUID(oSlot) == sUUID) return oSlot;

    oSlot = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oPC);
    if(GetIsObjectValid(oSlot) && GetObjectUUID(oSlot) == sUUID) return oSlot;

    // Walk inventory.
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem))
    {
        if(GetObjectUUID(oItem) == sUUID) return oItem;
        oItem = GetNextItemInInventory(oPC);
    }
    return OBJECT_INVALID;
}

// ----------------------------------------------------------------
// Main NUI event handler
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(nToken != NuiFindWindow(oPC, HAUNT_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalString(oPC, HAUNT_LVAR_OPEN_UUID);
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK) return;

    if(sElem == HAUNT_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    string sUUID = GetLocalString(oPC, HAUNT_LVAR_OPEN_UUID);
    if(sUUID == "") return;

    object oWeap = HauntFindWeaponByUUID(oPC, sUUID);
    if(!GetIsObjectValid(oWeap))
    {
        SendMessageToPC(oPC, "[Oręże] Nie można odnaleźć broni w ekwipunku.");
        NuiDestroy(oPC, nToken);
        return;
    }

    if(sElem == HAUNT_BTN_EMBRACE)
    {
        json jData = HauntGetWeaponData(sUUID);
        if(JsonGetType(jData) == JSON_TYPE_NULL
        || JsonGetInt(JsonObjectGet(jData, "haunt_level")) < 1)
        {
            SendMessageToPC(oPC, "[Oręże] Broń nie jest wystarczająco nawiedziona.");
            return;
        }
        if(JsonGetInt(JsonObjectGet(jData, "is_embraced")))
        {
            SendMessageToPC(oPC, "[Oręże] Klątwa już objęta.");
            return;
        }

        HauntSetEmbraced(sUUID, 1);
        HauntApplyEffects(oPC, oWeap);

        FloatingTextStringOnCreature("Klątwa przyjęta!", oPC, FALSE);
        SendMessageToPC(oPC, "[Oręże] Objąłeś klątwę. Broń pulsuje głębią czerwieni...");

        HauntFeedPanel(oPC, nToken, oWeap);
        return;
    }

    if(sElem == HAUNT_BTN_CLEANSE)
    {
        // Search inventory for holy water.
        int bFound = FALSE;
        object oItem = GetFirstItemInInventory(oPC);
        while(GetIsObjectValid(oItem))
        {
            if(GetTag(oItem) == HAUNT_CLEANSE_TAG)
            {
                bFound = TRUE;
                DestroyObject(oItem);
                break;
            }
            oItem = GetNextItemInInventory(oPC);
        }

        if(!bFound)
        {
            SendMessageToPC(oPC, "[Oręże] Oczyszczenie wymaga Święconej Wody w ekwipunku.");
            return;
        }

        HauntRemoveEffects(oPC, sUUID);
        HauntCleanse(sUUID);

        FloatingTextStringOnCreature("Oręże oczyszczone.", oPC, FALSE);
        SendMessageToPC(oPC, "[Oręże] Cień odpływa z ostrza. Broń znów milczy.");

        HauntFeedPanel(oPC, nToken, oWeap);
        return;
    }
}

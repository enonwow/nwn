#include "lib_bs"

// Place on the OnUsed event of a placeable named "Ołtarz Poległych".
// Using the placeable enters item-selection mode; the player then
// clicks a weapon in their inventory to open the binding dialog.
// If the player uses the placeable while already holding a haunted
// weapon, the spirit viewer opens directly instead.

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // If right-hand weapon is already haunted, open its spirit viewer
    object oRH = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
    if(GetIsObjectValid(oRH))
    {
        string sUUID = GetObjectUUID(oRH);
        if(JsonGetType(BsGetSpirit(sUUID)) != JSON_TYPE_NULL)
        {
            BsOpenWindow(oPC, sUUID);
            return;
        }
    }

    // Otherwise enter weapon-selection targeting mode
    if(GetLocalInt(oPC, BS_LVAR_TARGETING))
    {
        SendMessageToPC(oPC, "[Duch Ostrza] Już wybierasz broń — kliknij przedmiot w ekwipunku.");
        return;
    }

    SetLocalInt(oPC, BS_LVAR_TARGETING, 1);
    EnterTargetingMode(oPC, OBJECT_TYPE_ITEM);
    SendMessageToPC(oPC, "[Duch Ostrza] Wybierz broń z ekwipunku, którą chcesz nawiedzić.");
    FloatingTextStringOnCreature(
        "Ołtarz Poległych pulsuje zimnym blaskiem...\nWybierz ostrze.", oPC, FALSE);
}

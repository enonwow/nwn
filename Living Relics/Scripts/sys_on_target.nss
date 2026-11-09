#include "lib_mrel"

// Module OnPlayerTarget — fires when a PC selects an item after MrelCreateWindow
// put the PC into targeting mode via EnterTargetingMode(oPC, OBJECT_TYPE_ITEM).
// The targeting slot is stored in MREL_LVAR_ATTUNING on the PC.
void main()
{
    // Find the PC currently in targeting mode for relic attunement
    object oPC = OBJECT_INVALID;
    object oSearch = GetFirstPC();
    while(GetIsObjectValid(oSearch))
    {
        if(GetLocalInt(oSearch, MREL_LVAR_ATTUNING) != 0) { oPC = oSearch; break; }
        oSearch = GetNextPC();
    }
    if(!GetIsObjectValid(oPC)) return;

    int    nSlot = GetLocalInt(oPC, MREL_LVAR_ATTUNING);
    object oItem = GetTargetingModeSelectedObject();

    DeleteLocalInt(oPC, MREL_LVAR_ATTUNING);

    if(!GetIsObjectValid(oItem) || GetObjectType(oItem) != OBJECT_TYPE_ITEM)
    {
        SendMessageToPC(oPC, "[Relikwia] Anulowano — to nie jest przedmiot.");
        return;
    }
    if(GetItemPossessor(oItem) != oPC)
    {
        SendMessageToPC(oPC, "[Relikwia] Możesz poświęcić tylko przedmiot ze swojego ekwipunku.");
        return;
    }
    if(GetLocalString(oItem, MREL_ITEM_LVAR) != "")
    {
        SendMessageToPC(oPC, "[Relikwia] Ten przedmiot jest już przywiązany. Najpierw usuń poprzedni atunement.");
        return;
    }

    MrelAttuneItem(oPC, nSlot, oItem);
}

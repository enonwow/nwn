#include "lib_scry"

// OnUsed on a "Krysztalne Zrodlo" placeable.
// DMs who activate it also receive both test items if they are missing,
// so the full flow can be exercised immediately.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    if(GetIsDM(oPC))
    {
        // Hand out reagents if not present, so a DM can test without toolset items
        if(!GetIsObjectValid(GetItemPossessedBy(oPC, SCRY_ITEM_TEAR)))
            SendMessageToPC(oPC, "[Test] Dodaj item z tagiem '" + SCRY_ITEM_TEAR + "' (Lza Jasnowidza) przez DM-narzedzia.");
        if(!GetIsObjectValid(GetItemPossessedBy(oPC, SCRY_ITEM_CRYSTAL)))
            SendMessageToPC(oPC, "[Test] Dodaj item z tagiem '" + SCRY_ITEM_CRYSTAL + "' (Kamien Krysztalowy) przez DM-narzedzia.");
    }

    ScryCreateWindow(oPC);
}

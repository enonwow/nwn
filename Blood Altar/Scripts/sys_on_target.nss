// sys_on_target.nss — Blood Altar: obsluga celowania przy ofierze z przedmiotu (OnPlayerTarget)
#include "lib_balt"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetIsObjectValid(oPC)) return;

    // Ignoruj, jesli okno oltarza nie jest otwarte lub nie ma indeksu ofiary
    int nToken = NuiFindWindow(oPC, BALT_WINDOW);
    if(nToken == 0) return;

    string sAltarTag = GetLocalString(oPC, BALT_LVAR_ALTAR_TAG);
    if(sAltarTag == "") return;

    int nSacIdx = GetLocalInt(oPC, BALT_LVAR_ITEM_IDX);
    // Wartosc 0 to tez poprawny indeks; rozrozniamy przez BALT_LVAR_ITEM_IDX = -1 gdy nieaktywny
    if(nSacIdx < 0) return;
    SetLocalInt(oPC, BALT_LVAR_ITEM_IDX, -1);  // kasuj, zeby nie przetworzyc dwukrotnie

    object oItem = GetTargetingModeSelectedObject();
    if(!GetIsObjectValid(oItem) || GetItemPossessor(oItem) != oPC)
    {
        SendMessageToPC(oPC, "[Oltarz] Mozesz poswiecic tylko przedmiot ze swojego ekwipunku.");
        return;
    }

    json jSacs = BaltGetSacrifices(sAltarTag);
    if(nSacIdx >= JsonGetLength(jSacs)) return;
    json jSac = JsonArrayGet(jSacs, nSacIdx);

    string sItemName = GetName(oItem);
    DestroyObject(oItem);

    BaltApplyBoon(oPC, jSac);

    int nCorrupt = JsonGetInt(JsonObjectGet(jSac, "corrupt"));
    int nNewCorr = BaltAddCorruption(oPC, nCorrupt);
    BaltLogSacrifice(oPC, sAltarTag, nSacIdx);
    BaltApplyCorruptionVFX(oPC, nNewCorr);
    BaltFeedWindow(oPC, nToken, sAltarTag);

    SendMessageToPC(oPC, "[Oltarz] Poswiecono: " + sItemName + ". "
                  + JsonGetString(JsonObjectGet(jSac, "eff_desc")));

    if(nCorrupt > 0 && nNewCorr >= BALT_CORRUPT_HIGH)
        FloatingTextStringOnCreature(
            "Pieczen krwi pulsuje mroczna moca...", oPC, FALSE);
}

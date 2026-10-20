#include "lib_sets"

// OnUsed script for a test Placeable.
// Creates a selection of set items in the PC's inventory and opens the Sets panel.
// Remove this from production – for toolset/QA use only.

void GiveSetItem(object oPC, string sResRef, string sSetTag, string sDisplayName)
{
    object oItem = CreateItemOnObject(sResRef, oPC, 1);
    if(!GetIsObjectValid(oItem))
    {
        SendMessageToPC(oPC, "[test_sets] Nie udało się stworzyć przedmiotu: " + sResRef);
        return;
    }
    SetTag(oItem, sSetTag);
    SetName(oItem, sDisplayName);
}

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Use generic item resrefs available in the default NWN hak; override tags.
    // Zbroja Mrocznego Rycerza – helm + chest (unlocks 2-piece bonus)
    GiveSetItem(oPC, "nw_arhe001",  "set_dk_helm",  "Hełm Mroku");
    GiveSetItem(oPC, "nw_aarcl010", "set_dk_chest", "Napierśnik Cienia");

    // Rząd Korsarza – wszystkie 4 elementy (odblokowuje 4-piece bonus)
    GiveSetItem(oPC, "nw_cloth013",  "set_co_coat",   "Płaszcz Krwi");
    GiveSetItem(oPC, "nw_cloth011",  "set_co_gloves", "Rękawice Czarnej Dłoni");
    GiveSetItem(oPC, "nw_it_mboots001", "set_co_boots", "Buty Przemytnika");
    GiveSetItem(oPC, "nw_wswsc001",  "set_co_blade",  "Szabla Korsarza");

    // Pierścienie Przeklętych – oba pierścienie
    GiveSetItem(oPC, "nw_it_mring001", "set_pr_ring1", "Pierścień Pożogi");
    GiveSetItem(oPC, "nw_it_mring001", "set_pr_ring2", "Pierścień Mrozu");

    SendMessageToPC(oPC,
        "[Zestawy] Przedmioty testowe dodane do ekwipunku. " +
        "Załóż je, a następnie otwórz panel zestawów.");

    // Open the window immediately so the player can inspect the empty state first
    SetsOpenWindow(oPC);
}

// test_syn.nss — Szynkarz demo: placeable OnUsed script
// Place a "Brewing Kit" placeable in the toolset and set this as its OnUsed script.
// Activating it opens the Warzelnia window.
// Also seeds the PC's inventory with one of each ingredient for easy testing.

#include "lib_syn"

void SeedTestIngredients(object oPC)
{
    // Creates one stack of each ingredient so the brewer can test all recipes.
    // In a real module these items must exist in a palette/hak with matching tags.
    string sIngs = SYN_ING_HOP + "," + SYN_ING_BARLEY + "," + SYN_ING_MIDNIGHT + ","
                 + SYN_ING_HONEY + "," + SYN_ING_WORMWOOD + "," + SYN_ING_BONE_DUST + ","
                 + SYN_ING_GRAPES + "," + SYN_ING_BLOOD + "," + SYN_ING_GHOST_ESS + ","
                 + SYN_ING_MOONWATER + "," + SYN_ING_IRON_FIL + "," + SYN_ING_CINDER + ","
                 + SYN_ING_SPIDER_VEN + "," + SYN_ING_ARCANE_CRY;

    SendMessageToPC(oPC, "[Warzelnia/Test] Składniki do testów: próba tworzenia przedmiotów o tagach:");
    SendMessageToPC(oPC, sIngs);
    SendMessageToPC(oPC, "[Warzelnia/Test] Dodaj przedmioty z odpowiednimi tagami do haka i ekwipunku ręcznie.");
}

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    // Shift+Use seeds test ingredients (only if debug mode is on)
    if(GetLocalInt(GetModule(), "SYN_DEBUG"))
        SeedTestIngredients(oPC);

    SynOpenWindow(oPC);
}

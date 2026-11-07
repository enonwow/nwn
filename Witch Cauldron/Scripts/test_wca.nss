// test_wca.nss — Witch Cauldron: OnUsed demo script for the cauldron placeable.
// Place a placeable (e.g., a large pot/forge) in the test area and assign this
// script to its OnUsed event. Using it opens the Witch Cauldron window.
#include "lib_wca"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Give test ingredients so the player can immediately try all recipes.
    // In production these would be found in the world.
    int bGiveItems = !GetLocalInt(oPC, "WCA_TEST_ITEMS_GIVEN");
    if(bGiveItems)
    {
        SetLocalInt(oPC, "WCA_TEST_ITEMS_GIVEN", 1);

        // Ingredients are custom items; this uses tag-based creation.
        // If the blueprints are not in the module palette, the creation
        // silently fails — the placeholder message below catches that case.
        int bAny = FALSE;
        object oI;

        oI = CreateItemOnObject(WCA_ING_MANDRAKE,    oPC, 2); if(GetIsObjectValid(oI)) bAny = TRUE;
        oI = CreateItemOnObject(WCA_ING_NIGHTSHADE,  oPC, 2); if(GetIsObjectValid(oI)) bAny = TRUE;
        oI = CreateItemOnObject(WCA_ING_BLOODMOSS,   oPC, 2); if(GetIsObjectValid(oI)) bAny = TRUE;
        oI = CreateItemOnObject(WCA_ING_GRAVESOIL,   oPC, 2); if(GetIsObjectValid(oI)) bAny = TRUE;
        oI = CreateItemOnObject(WCA_ING_BONETHORN,   oPC, 2); if(GetIsObjectValid(oI)) bAny = TRUE;
        oI = CreateItemOnObject(WCA_ING_SHADOWFERN,  oPC, 2); if(GetIsObjectValid(oI)) bAny = TRUE;
        oI = CreateItemOnObject(WCA_ING_HELLBANE,    oPC, 2); if(GetIsObjectValid(oI)) bAny = TRUE;
        oI = CreateItemOnObject(WCA_ING_SPECTER_ASH, oPC, 2); if(GetIsObjectValid(oI)) bAny = TRUE;
        oI = CreateItemOnObject(WCA_ING_BAT_WING,    oPC, 2); if(GetIsObjectValid(oI)) bAny = TRUE;
        oI = CreateItemOnObject(WCA_ING_WOLFBANE,    oPC, 2); if(GetIsObjectValid(oI)) bAny = TRUE;

        if(!bAny)
            SendMessageToPC(oPC,
                "[Kocioł TEST] Uwaga: pliki .uti składników nie istnieją w module. "
                "Dodaj je do palety przedmiotów z tagami wca_mandrake ... wca_wolfbane, "
                "aby testowanie mikstur było możliwe. Receptury NUI działają niezależnie.");

        // Teach all recipes for testing
        int r;
        for(r = 0; r < WCA_RECIPE_COUNT; r++)
            WcaLearnRecipe(oPC, r);
    }

    WcaOpenWindow(oPC, OBJECT_SELF);
}

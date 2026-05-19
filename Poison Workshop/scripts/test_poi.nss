// OnUsed script for the Poison Workshop placeable.
// Place a placeable (e.g. table, cauldron) in your area and set this
// as its OnUsed script. Running it opens the workshop UI and, on first
// use, seeds a small starting batch of every ingredient type so the
// player can immediately experiment with all recipes.
#include "lib_poi"

const int POI_TEST_SEED_COUNT = 3;  // ingredients given on first use

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Seed ingredients once per character (if they have none of anything)
    int bNeedsSeed = TRUE;
    int i;
    for(i = 0; i < POI_ING_COUNT; i++)
    {
        if(PoiGetStock(oPC, i) > 0)
        {
            bNeedsSeed = FALSE;
            break;
        }
    }

    if(bNeedsSeed)
    {
        for(i = 0; i < POI_ING_COUNT; i++)
            PoiSetStock(oPC, i, POI_TEST_SEED_COUNT);

        SendMessageToPC(oPC,
            "[Trucizny] Znalazłeś porzucone zapasy alchemika. Stół skrywa składniki "
            "do wszystkich podstawowych receptur.");
        FloatingTextStringOnCreature(
            "*odkrywa stary stół alchemiczny*", oPC, FALSE);
    }

    CreatePoisonWindow(oPC);
}

// OnUsed script for an alchemist's bench placeable.
// For demo/testing: if the player has no known recipes, they start with the
// two simplest ones (HEAL_MINOR, ANTIDOTE) so the UI is immediately usable.
// In a real module these would be learned through in-world discovery.

#include "lib_alch"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Seed starter recipes for new alchemists
    if(!AlchIsRecipeKnown(oPC, ALCH_RCP_HEAL_MINOR))
        AlchLearnRecipe(oPC, ALCH_RCP_HEAL_MINOR);
    if(!AlchIsRecipeKnown(oPC, ALCH_RCP_ANTIDOTE))
        AlchLearnRecipe(oPC, ALCH_RCP_ANTIDOTE);

    // Give test ingredients when used with shift (DM) or always in demo
    // Spawns one of each ingredient needed for the two starter recipes
    string aTestIngr[4];
    aTestIngr[0] = "alch_herb_glasswort";
    aTestIngr[1] = "alch_herb_elfwood";
    aTestIngr[2] = "alch_herb_archangel";
    aTestIngr[3] = "alch_mineral_bezoar";

    int i;
    for(i = 0; i < 4; i++)
    {
        if(!GetIsObjectValid(GetItemPossessedBy(oPC, aTestIngr[i])))
            CreateItemOnObject(aTestIngr[i], oPC);
    }

    AlchOpenWindow(oPC);
}

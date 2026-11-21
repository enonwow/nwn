// sys_on_acquire.nss
// Module OnAcquireItem — detects recipe scrolls and unlocks the matching recipe.
// Recipe scroll tags follow the pattern ALCH_REC_N where N is the recipe ID (0–8).
#include "lib_alch_def"

void main()
{
    object oItem = GetModuleItemAcquired();
    object oPC   = GetModuleItemAcquiredBy();

    if(!GetIsPC(oPC) || !GetIsObjectValid(oItem)) return;

    string sTag = GetTag(oItem);

    // Fast-reject: must start with ALCH_REC_
    if(GetStringLeft(sTag, GetStringLength(ALCH_REC_TAG_PREFIX)) != ALCH_REC_TAG_PREFIX)
        return;

    string sSuffix = GetStringRight(sTag,
        GetStringLength(sTag) - GetStringLength(ALCH_REC_TAG_PREFIX));
    int nId = StringToInt(sSuffix);

    if(nId < 0 || nId >= ALCH_RECIPE_COUNT) return;

    if(AlchHasRecipe(oPC, nId))
    {
        SendMessageToPC(oPC, "[Alchemia] Znasz już ten przepis. Zwój rozsypuje się w pył.");
        DestroyObject(oItem);
        return;
    }

    AlchUnlockRecipe(oPC, nId);
    SendMessageToPC(oPC,
        "[Alchemia] Nauczyłeś się nowego przepisu: " + AlchGetRecipeName(nId) + "!");

    // Refresh open window if PC has it open
    int nToken = NuiFindWindow(oPC, ALCH_WINDOW);
    if(nToken != 0)
        FeedRecipeList(oPC, nToken);

    // Consume scroll with a short delay so engine finishes the acquire event
    DestroyObject(oItem, 0.1);
}

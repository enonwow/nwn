// sys_on_enter.nss — Witch Cauldron: module OnClientEnter hook
#include "lib_wca_def"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    // Grant the first (tier 1) recipe to any character who doesn't know it yet.
    // Lore-flavour: every practitioner inherits the most basic knowledge.
    if(!WcaHasRecipe(oPC, 0))
    {
        WcaLearnRecipeDB(oPC, 0);
        DelayCommand(5.0, SendMessageToPC(oPC,
            "[Kocioł] Stary pergamin drżący w kieszeni... Receptura Worka Klątwy — zdaje się, że ją znasz."));
    }

    int nCount = WcaGetKnownRecipeCount(oPC);
    if(nCount > 1)
    {
        string sMsg = "[Kocioł] Znasz " + IntToString(nCount) + " receptury. Znajdź kocioł, by warzyć.";
        DelayCommand(6.0, SendMessageToPC(oPC, sMsg));
    }
}

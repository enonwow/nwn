// sys_on_activate.nss  –  Corruption: OnActivateItem hook
// Handles holy water and dark artifact items.

#include "lib_cor"

void main()
{
    object oPC   = GetItemActivator();
    object oItem = GetItemActivated();

    if(!GetIsPC(oPC) || !GetIsObjectValid(oItem)) return;

    string sTag = GetTag(oItem);

    // Holy water: reduce corruption
    if(sTag == COR_TAG_HOLY_WATER)
    {
        CorUseHolyWater(oPC, oItem);
        return;
    }

    // Dark artifact: gain corruption when activated/first picked up
    int nDarkPower = GetLocalInt(oItem, COR_IVAR_DARK_ARTIFACT);
    if(nDarkPower > 0)
    {
        SendMessageToPC(oPC,
            "[Korupcja] Mroczna moc artefaktu przesącza się przez twoje palce...");
        CorGainCorruption(oPC, nDarkPower,
            "Dotknąłeś " + GetName(oItem) + " — pieczęć mroku się wzmacnia.");
        // Remove the variable so the item can only corrupt once per activation
        DeleteLocalInt(oItem, COR_IVAR_DARK_ARTIFACT);
    }
}

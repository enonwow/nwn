#include "lib_vamp"

// OnUsed script for a test Placeable.
//
// First use:  infects the PC (or shows status if already vampire).
// Second use (while vampire): creates a holy-blood cure item in inventory.
// The placeable can be placed anywhere in the test area for demonstration.

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    if(!VampIsVampire(oPC))
    {
        SendMessageToPC(oPC,
            "[Test] Dotykasz starożytnego kamienia pokrytego krwią."
            " Czujesz, jak coś zimnego przenika twoją duszę...");
        VampInfectPC(oPC);
        return;
    }

    // Already a vampire — give a cure item for testing the remedy flow
    object oCure = CreateItemOnObject(VAMP_CURE_ITEM_TAG, oPC);
    if(GetIsObjectValid(oCure))
    {
        SendMessageToPC(oPC,
            "[Test] Znajdziesz w swoim ekwipunku Krew Świętą."
            " Otwórz okno klątwy i kliknij 'Oczyść Klątwę'.");
    }
    else
    {
        // Resref not in hak — fall back to a dummy item (potion of healing) for quick demo
        SendMessageToPC(oPC,
            "[Test] Nie znaleziono itemu '" + VAMP_CURE_ITEM_TAG + "' w hak."
            " Dodaj go lub stwórz ręcznie z tagiem 'vamp_holy_blood'.");
    }

    // Re-open the status window in case it was closed
    CreateVampWindow(oPC);
}

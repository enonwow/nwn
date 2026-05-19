// test_bur.nss — OnUsed on a placeable; opens the Burial Rites window for the user.
// Place this on a "Stol Grabarza" (Altar/Workbench) placeable in the toolset.
// Optionally set tag = "BUR_WORKBENCH" for easy lookup.

#include "lib_bur"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Give the tester one of each optional item so all rites can be tested.
    // Remove this block in production (items should be acquired normally).
    if(GetLocalInt(OBJECT_SELF, "BUR_TEST_GIVEN") == 0)
    {
        SetLocalInt(OBJECT_SELF, "BUR_TEST_GIVEN", 1);
        object oCandle = CreateItemOnObject(BUR_TAG_CANDLE, oPC, 3);
        object oOil    = CreateItemOnObject(BUR_TAG_OIL,    oPC, 3);
        object oScroll = CreateItemOnObject(BUR_TAG_SCROLL, oPC, 3);
        if(GetIsObjectValid(oCandle) || GetIsObjectValid(oOil) || GetIsObjectValid(oScroll))
            SendMessageToPC(oPC,
                "[Pogrzebnik TEST] Otrzymujesz materia\305\202y testowe (resrefy musz\304\205 istnie\304\207 w haku).");
        else
            SendMessageToPC(oPC,
                "[Pogrzebnik TEST] Brak plik\303\263w item\303\263w w haku \342\200\224 dodaj bur_candle/bur_oil/bur_scroll.");
    }

    BurShowWindow(oPC);
}

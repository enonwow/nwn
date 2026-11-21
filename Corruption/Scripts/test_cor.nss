// test_cor.nss  –  Corruption: OnUsed script for a demonstration placeable
//
// Placeable tag: "test_corruption"
//
// First use:  opens the Corruption Soul panel for the activating PC.
// Second use (within same session): adds 15 corruption points for testing.
// Third use:  subtracts 15 corruption points.
// Cycles through gain / reduce so testers can walk through all stages.
//
// Place a campfire or shrine placeable in your test area, assign this
// script to its OnUsed event, and give the placeable the tag "test_corruption".

#include "lib_cor"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    int nMode = GetLocalInt(OBJECT_SELF, "TEST_COR_MODE");

    switch(nMode % 3)
    {
        case 0:
            // Open the soul panel
            CorOpenWindow(oPC);
            SendMessageToPC(oPC,
                "[Test Korupcja] Panel otwarty. Użyj ponownie by dodać 15 pkt korupcji.");
            break;

        case 1:
            // Gain corruption
            CorGainCorruption(oPC, 15,
                "Mroczna energia z obiektu testowego przenika przez twoje ciało.");
            SendMessageToPC(oPC,
                "[Test Korupcja] +15 korupcji. Użyj ponownie by odjąć 15 pkt.");
            break;

        case 2:
            // Reduce corruption
            CorReduceCorruption(oPC, 15);
            SendMessageToPC(oPC,
                "[Test Korupcja] -15 korupcji. Użyj ponownie by otworzyć panel.");
            break;
    }

    SetLocalInt(OBJECT_SELF, "TEST_COR_MODE", (nMode + 1) % 3);
}

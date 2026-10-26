// test_slm.nss — OnUsed script for a Placeable object.
// Learns all words for the activating PC and opens the Words of Power window.
// Place a placeable in the module with OnUsed set to this script to demo the system.

#include "lib_slm"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Grant all words so any character can demo the full system
    SlmLearnAllWords(oPC);

    SendMessageToPC(oPC, "[Słowa Mocy] Starożytne słowa wnikają w umysł jak zimna woda.");
    SendMessageToPC(oPC, "[Słowa Mocy] Poznałeś wszystkie Żywioły, Cele i Moce. Zacznij od stworzenia inkantacji.");

    OpenSlmWindow(oPC);
}

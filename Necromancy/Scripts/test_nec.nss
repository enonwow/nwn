// test_nec.nss — Necromancy: demo placeable OnUsed script
// Place a "Księga Nekromancji" or similar placeable in your test area
// and set its OnUsed script to test_nec. Using it opens the NUI panel
// and grants 200 starting Essence for testing purposes.

#include "lib_nec"

void main()
{
    object oPC = GetLastUsedBy();
    if (!GetIsPC(oPC)) return;

    NecRegisterPC(oPC);

    // Grant essence for testing only — remove from production.
    NecAddEssenceToPool(oPC, 200);
    SendMessageToPC(oPC, "[Nekromancja] Otrzymujesz 200 pkt Esencji Dusz na potrzeby testów.");

    NecOpenWindow(oPC);
}

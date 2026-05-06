// test_plg.nss - debug placeable for testing diseases (Phase A smoke test)
// Hook: placeable OnUsed
//
// Action: infects player with a random disease.
// Phase B+ adds UI window for selecting a specific disease.

#include "lib_plg"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    // Random disease (0-3)
    int nDiseaseId = Random(PLG_DIS_COUNT);

    // DEBUG: show name (Phase A skips hidden identity for test convenience)
    SendMessageToPC(oPC, "[DEBUG] Infected: " + PlgDiseaseName(nDiseaseId)
        + " (id=" + IntToString(nDiseaseId) + ")");

    PlgContractAndNotify(oPC, nDiseaseId);
}

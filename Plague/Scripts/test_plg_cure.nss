// test_plg_cure.nss - debug placeable: cure all diseases
// Hook: placeable OnUsed
//
// Action: removes all diseases from the player + clears all effects.

#include "lib_plg"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    int nDiseaseId;
    int nCured = 0;
    for(nDiseaseId = 0; nDiseaseId < PLG_DIS_COUNT; nDiseaseId++)
    {
        if(GetLocalInt(oPC, PLG_LVAR_HAS + IntToString(nDiseaseId)))
        {
            PlgCureAndNotify(oPC, nDiseaseId);
            nCured++;
        }
    }

    if(nCured == 0)
    {
        SendMessageToPC(oPC, "[DEBUG] You have no diseases.");
    }
    else
    {
        SendMessageToPC(oPC, "[DEBUG] Cured " + IntToString(nCured) + " disease(s).");
    }
}

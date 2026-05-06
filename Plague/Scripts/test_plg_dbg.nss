// test_plg_dbg.nss - debug placeable dispatcher
// Hook: placeable OnUsed
//
// Action depends on the placeable's TAG:
//   plg_test_plague   - infect with Black Plague
//   plg_test_blood    - infect with Blood Rot
//   plg_test_swamp    - infect with Swamp Fever
//   plg_test_necro    - infect with Necrotic Wound
//   plg_test_debug    - toggle debug mode (30s/phase instead of normal hours)
//   plg_test_advance  - force phase advance for the player's first disease
//   plg_test_status   - print player's current health status

#include "lib_plg"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    string sTag = GetTag(OBJECT_SELF);

    if(sTag == "plg_test_plague")
    {
        SendMessageToPC(oPC, "[DEBUG] Trying to infect: Black Plague");
        PlgContractAndNotify(oPC, PLG_DIS_BLACK_PLAGUE);
    }
    else if(sTag == "plg_test_blood")
    {
        SendMessageToPC(oPC, "[DEBUG] Trying to infect: Blood Rot");
        PlgContractAndNotify(oPC, PLG_DIS_BLOOD_ROT);
    }
    else if(sTag == "plg_test_swamp")
    {
        SendMessageToPC(oPC, "[DEBUG] Trying to infect: Swamp Fever");
        PlgContractAndNotify(oPC, PLG_DIS_SWAMP_FEVER);
    }
    else if(sTag == "plg_test_necro")
    {
        SendMessageToPC(oPC, "[DEBUG] Trying to infect: Necrotic Wound");
        PlgContractAndNotify(oPC, PLG_DIS_NECROTIC);
    }
    else if(sTag == "plg_test_debug")
    {
        // Toggle debug mode
        int bDebug = !PlgIsDebugMode();
        PlgSetDebugMode(bDebug);
        if(bDebug)
        {
            SendMessageToPC(oPC, "[DEBUG] DEBUG MODE ON - "
                + IntToString(PLG_DEBUG_PHASE_SEC) + "s per phase.");
            FloatingTextStringOnCreature("DEBUG ON", oPC, FALSE, FALSE);
        }
        else
        {
            SendMessageToPC(oPC, "[DEBUG] DEBUG MODE OFF - normal timings.");
            FloatingTextStringOnCreature("DEBUG OFF", oPC, FALSE, FALSE);
        }
    }
    else if(sTag == "plg_test_advance")
    {
        // Force phase advance for the player's first disease.
        // Sets phase_end to now-1 so the next heartbeat triggers an advance.
        int nDiseaseId;
        int nFound = -1;
        for(nDiseaseId = 0; nDiseaseId < PLG_DIS_COUNT; nDiseaseId++)
        {
            if(GetLocalInt(oPC, PLG_LVAR_HAS + IntToString(nDiseaseId)))
            {
                nFound = nDiseaseId;
                break;
            }
        }
        if(nFound < 0)
        {
            SendMessageToPC(oPC, "[DEBUG] You have no diseases.");
            return;
        }
        json jState = PlgGetState(oPC, nFound);
        int nPhase = JsonGetInt(JsonObjectGet(jState, "phase"));
        int nPhaseStart = JsonGetInt(JsonObjectGet(jState, "phase_start"));
        int nNow = PlgUnixNow();
        PlgSetPhase(oPC, nFound, nPhase, nPhaseStart, nNow - 1);
        SendMessageToPC(oPC, "[DEBUG] Force advance: " + PlgDiseaseName(nFound)
            + " - will advance to next phase on next heartbeat.");
    }
    else if(sTag == "plg_test_status")
    {
        // Print current status
        json jStates = PlgGetStates(oPC);
        int nLen = JsonGetLength(jStates);
        if(nLen == 0)
        {
            SendMessageToPC(oPC, "[DEBUG] You are healthy.");
            return;
        }
        SendMessageToPC(oPC, "[DEBUG] Your diseases (" + IntToString(nLen) + "):");
        int i;
        for(i = 0; i < nLen; i++)
        {
            json jState = JsonArrayGet(jStates, i);
            int nDid       = JsonGetInt(JsonObjectGet(jState, "disease_id"));
            int nPhase     = JsonGetInt(JsonObjectGet(jState, "phase"));
            int nPhaseEnd  = JsonGetInt(JsonObjectGet(jState, "phase_end"));
            int nDiagnosed = JsonGetInt(JsonObjectGet(jState, "diagnosed"));
            int nNow = PlgUnixNow();
            int nRemain = (nPhaseEnd > 0) ? nPhaseEnd - nNow : 0;
            string sDiag = nDiagnosed ? PlgDiseaseName(nDid) : "[Unknown]";
            SendMessageToPC(oPC, "  " + sDiag
                + " - phase: " + PlgPhaseName(nPhase)
                + " (next in: " + IntToString(nRemain) + "s)");
        }
    }
    else
    {
        SendMessageToPC(oPC, "[DEBUG] Unknown placeable tag: '" + sTag + "'");
        SendMessageToPC(oPC, "Available: plg_test_plague, plg_test_blood, "
            + "plg_test_swamp, plg_test_necro, plg_test_debug, "
            + "plg_test_advance, plg_test_status");
    }
}

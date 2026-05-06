// lib_plg_dm_ev.nss - event handler dla DM panel NUI

#include "lib_plg_dm"

void main()
{
    object oDm    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(!GetIsDM(oDm)) return;
    if(nToken != NuiFindWindow(oDm, PLG_DM_WINDOW)) return;

    // ===== List row select =====
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == PLG_DM_BTN_INFECTED_ROW)
    {
        json jList = GetLocalJson(oDm, PLG_DM_LVAR_INFECTED_LIST_JSON);
        if(nIdx < 0 || nIdx >= JsonGetLength(jList)) return;
        json jRec = JsonArrayGet(jList, nIdx);
        SetLocalString(oDm, PLG_DM_LVAR_SEL_INFECTED_UUID,
            JsonGetString(JsonObjectGet(jRec, "uuid")));
        SetLocalInt(oDm, PLG_DM_LVAR_SEL_INFECTED_DID,
            JsonGetInt(JsonObjectGet(jRec, "disease_id")));
        FeedPlgDmWindow(oDm, nToken);
        return;
    }
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == PLG_DM_BTN_ONLINE_ROW)
    {
        json jList = GetLocalJson(oDm, PLG_DM_LVAR_ONLINE_LIST_JSON);
        if(nIdx < 0 || nIdx >= JsonGetLength(jList)) return;
        json jRec = JsonArrayGet(jList, nIdx);
        SetLocalString(oDm, PLG_DM_LVAR_SEL_ONLINE_UUID,
            JsonGetString(JsonObjectGet(jRec, "uuid")));
        FeedPlgDmWindow(oDm, nToken);
        return;
    }

    // ===== Click events =====
    if(sEvent != EVENT_TYPE_CLICK) return;

    // Close
    if(sElem == PLG_DM_BTN_CLOSE)
    {
        NuiDestroy(oDm, nToken);
        return;
    }

    // Tab switch
    if(sElem == PLG_DM_TAB_INFECTED)
    {
        PlgDmSwapToInfected(oDm, nToken);
        FeedPlgDmWindow(oDm, nToken);
        return;
    }
    if(sElem == PLG_DM_TAB_ONLINE)
    {
        PlgDmSwapToOnline(oDm, nToken);
        FeedPlgDmWindow(oDm, nToken);
        return;
    }
    if(sElem == PLG_DM_TAB_STATS)
    {
        PlgDmSwapToStats(oDm, nToken);
        FeedPlgDmWindow(oDm, nToken);
        return;
    }

    // Refresh
    if(sElem == PLG_DM_BTN_REFRESH)
    {
        FeedPlgDmWindow(oDm, nToken);
        return;
    }

    // Debug toggle
    if(sElem == PLG_DM_BTN_DEBUG)
    {
        PlgSetDebugMode(!PlgIsDebugMode());
        FeedPlgDmWindow(oDm, nToken);
        return;
    }

    // ===== Actions on selected INFECTED row =====
    string sSelInfUuid = GetLocalString(oDm, PLG_DM_LVAR_SEL_INFECTED_UUID);
    int    nSelInfDid  = GetLocalInt(oDm, PLG_DM_LVAR_SEL_INFECTED_DID);

    if(sElem == PLG_DM_BTN_CURE || sElem == PLG_DM_BTN_REVEAL
       || sElem == PLG_DM_BTN_PHASE_UP || sElem == PLG_DM_BTN_PHASE_DOWN)
    {
        if(sSelInfUuid == "")
        {
            SendMessageToPC(oDm, "[DM] Select an infected player from the list first.");
            return;
        }
        // Znajdz online PC po UUID
        object oTarget = OBJECT_INVALID;
        object oPC = GetFirstPC();
        while(GetIsObjectValid(oPC))
        {
            if(GetObjectUUID(oPC) == sSelInfUuid)
            {
                oTarget = oPC;
                break;
            }
            oPC = GetNextPC();
        }
        if(!GetIsObjectValid(oTarget))
        {
            SendMessageToPC(oDm, "[DM] Player offline - actions require online presence.");
            return;
        }

        if(sElem == PLG_DM_BTN_CURE)
        {
            PlgLogDmAction(oDm, oTarget, nSelInfDid, "cure");
            PlgCureAndNotify(oTarget, nSelInfDid);
            SendMessageToPC(oDm, "[DM] Cured " + GetName(oTarget)
                + " - " + PlgDiseaseName(nSelInfDid));
            // Reset selection
            DeleteLocalString(oDm, PLG_DM_LVAR_SEL_INFECTED_UUID);
            DeleteLocalInt(oDm, PLG_DM_LVAR_SEL_INFECTED_DID);
        }
        else if(sElem == PLG_DM_BTN_REVEAL)
        {
            SetLocalInt(oTarget, PLG_LVAR_DIAGNOSED + IntToString(nSelInfDid), TRUE);
            PlgSetDiagnosed(oTarget, nSelInfDid, TRUE);
            PlgLogDmAction(oDm, oTarget, nSelInfDid, "reveal");
            SendMessageToPC(oDm, "[DM] Revealed " + PlgDiseaseName(nSelInfDid)
                + " for " + GetName(oTarget));
            SendMessageToPC(oTarget,
                "[Plague] You now know what afflicts you: " + PlgDiseaseName(nSelInfDid));
        }
        else if(sElem == PLG_DM_BTN_PHASE_UP || sElem == PLG_DM_BTN_PHASE_DOWN)
        {
            json jState = PlgGetState(oTarget, nSelInfDid);
            if(JsonGetType(jState) == JSON_TYPE_NULL) return;
            int nPhase = JsonGetInt(JsonObjectGet(jState, "phase"));
            int nNew = (sElem == PLG_DM_BTN_PHASE_UP) ? nPhase + 1 : nPhase - 1;
            if(nNew < PLG_PHASE_INCUBATION || nNew > PLG_PHASE_CRITICAL)
            {
                SendMessageToPC(oDm, "[DM] Phase out of range.");
                return;
            }
            int nNow = PlgUnixNow();
            int nInterval = (nNew < PLG_PHASE_CRITICAL)
                ? PlgPhaseInterval(nSelInfDid, nNew) : 0;
            int nEnd = (nInterval > 0) ? nNow + nInterval : 0;
            PlgSetPhase(oTarget, nSelInfDid, nNew, nNow, nEnd);
            PlgApplyEffectsForDisease(oTarget, nSelInfDid, nNew);
            PlgLogDmAction(oDm, oTarget, nSelInfDid,
                (sElem == PLG_DM_BTN_PHASE_UP) ? "phase_up" : "phase_down");
            SendMessageToPC(oDm, "[DM] Phase: " + PlgPhaseName(nNew)
                + " for " + GetName(oTarget));
        }
        FeedPlgDmWindow(oDm, nToken);
        return;
    }

    // ===== Infect actions on selected ONLINE row =====
    int nInfectDid = -1;
    if(sElem == PLG_DM_BTN_INF_PLAGA) nInfectDid = PLG_DIS_BLACK_PLAGUE;
    else if(sElem == PLG_DM_BTN_INF_KREW)  nInfectDid = PLG_DIS_BLOOD_ROT;
    else if(sElem == PLG_DM_BTN_INF_BAGNA) nInfectDid = PLG_DIS_SWAMP_FEVER;
    else if(sElem == PLG_DM_BTN_INF_NKR)   nInfectDid = PLG_DIS_NECROTIC;

    if(nInfectDid >= 0)
    {
        string sSelOnlUuid = GetLocalString(oDm, PLG_DM_LVAR_SEL_ONLINE_UUID);
        if(sSelOnlUuid == "")
        {
            SendMessageToPC(oDm, "[DM] Select an online player from the second tab first.");
            return;
        }
        object oTarget = OBJECT_INVALID;
        object oPC = GetFirstPC();
        while(GetIsObjectValid(oPC))
        {
            if(GetObjectUUID(oPC) == sSelOnlUuid)
            {
                oTarget = oPC;
                break;
            }
            oPC = GetNextPC();
        }
        if(!GetIsObjectValid(oTarget))
        {
            SendMessageToPC(oDm, "[DM] Player offline.");
            return;
        }

        if(PlgHasDisease(oTarget, nInfectDid))
        {
            SendMessageToPC(oDm, "[DM] " + GetName(oTarget)
                + " already has " + PlgDiseaseName(nInfectDid));
            return;
        }

        PlgLogDmAction(oDm, oTarget, nInfectDid, "infect");
        PlgContractAndNotify(oTarget, nInfectDid);
        SendMessageToPC(oDm, "[DM] Infected " + GetName(oTarget)
            + " - " + PlgDiseaseName(nInfectDid));
        FeedPlgDmWindow(oDm, nToken);
        return;
    }
}

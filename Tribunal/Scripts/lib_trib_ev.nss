#include "lib_trib"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    // ---- Search popup (select defendant) ----
    if(nToken == NuiFindWindow(oPC, TRIB_WIN_SEARCH))
    {
        if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == TRIB_BTN_SRCH_ROW)
        {
            json jRes = GetLocalJson(oPC, TRIB_LVAR_SEARCH_RES);
            if(nIdx < 0 || nIdx >= JsonGetLength(jRes)) return;

            json   jEntry = JsonArrayGet(jRes, nIdx);
            string sUuid  = JsonGetString(JsonObjectGet(jEntry, "uuid"));
            string sName  = JsonGetString(JsonObjectGet(jEntry, "char_name"));

            SetLocalString(oPC, TRIB_LVAR_TARGET_UUID, sUuid);
            SetLocalString(oPC, TRIB_LVAR_TARGET_NAME, sName);
            NuiDestroy(oPC, nToken);

            int nMain = NuiFindWindow(oPC, TRIB_WINDOW);
            if(nMain)
            {
                NuiSetBind(oPC, nMain, TRIB_BIND_TARGET_LBL,
                           JsonString("Oskarżony: " + sName));
                string sCharge = JsonGetString(NuiGetBind(oPC, nMain, TRIB_BIND_CHARGE_TXT));
                NuiSetBind(oPC, nMain, TRIB_BIND_SUBMIT_ENA,
                           JsonBool(sCharge != "" && sUuid != ""));
            }
        }
        return;
    }

    if(nToken != NuiFindWindow(oPC, TRIB_WINDOW)) return;

    // ---- Window closed ----
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalString(oPC, TRIB_LVAR_TARGET_UUID);
        DeleteLocalString(oPC, TRIB_LVAR_TARGET_NAME);
        DeleteLocalInt   (oPC, TRIB_LVAR_CASE_ID);
        DeleteLocalJson  (oPC, TRIB_LVAR_SEARCH_RES);
        return;
    }

    // ---- Watch: charge field enables submit button ----
    if(sEvent == EVENT_TYPE_WATCH && sElem == TRIB_BIND_CHARGE_TXT)
    {
        string sCharge = JsonGetString(NuiGetBind(oPC, nToken, TRIB_BIND_CHARGE_TXT));
        string sTarget = GetLocalString(oPC, TRIB_LVAR_TARGET_UUID);
        NuiSetBind(oPC, nToken, TRIB_BIND_SUBMIT_ENA,
                   JsonBool(sCharge != "" && sTarget != ""));
        return;
    }

    // ---- Click / mousedown dispatch ----
    if(sEvent != EVENT_TYPE_CLICK && sEvent != EVENT_TYPE_MOUSEDOWN) return;

    if(sElem == TRIB_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    if(sElem == TRIB_BTN_ACCUSE)
    {
        SwapToAccuseView(oPC, nToken);
        return;
    }

    if(sElem == TRIB_BTN_BACK)
    {
        SwapToCaseListView(oPC, nToken);
        return;
    }

    // Row click in case list
    if(sElem == TRIB_BTN_ROW && sEvent == EVENT_TYPE_MOUSEDOWN)
    {
        json jCases = TribGetAllCases();
        if(nIdx < 0 || nIdx >= JsonGetLength(jCases)) return;
        int nCaseId = JsonGetInt(JsonObjectGet(JsonArrayGet(jCases, nIdx), "id"));
        SwapToCaseDetailView(oPC, nToken, nCaseId);
        return;
    }

    // Search for defendant in accuse view
    if(sElem == TRIB_BTN_SEARCH)
    {
        string sQuery = JsonGetString(NuiGetBind(oPC, nToken, TRIB_BIND_SEARCH_TXT));
        if(sQuery == "")
        {
            SendMessageToPC(oPC, "[Trybunał] Wpisz imię, aby szukać.");
            return;
        }
        json jRes = TribSearchPlayers(sQuery, oPC);
        if(JsonGetLength(jRes) == 0)
        {
            SendMessageToPC(oPC, "[Trybunał] Nie znaleziono gracza. Musi się zalogować co najmniej raz.");
            return;
        }
        SetLocalJson(oPC, TRIB_LVAR_SEARCH_RES, jRes);
        TribShowSearchPopup(oPC, jRes);
        return;
    }

    // Submit accusation
    if(sElem == TRIB_BTN_SUBMIT_ACC)
    {
        string sTargetUUID = GetLocalString(oPC, TRIB_LVAR_TARGET_UUID);
        string sTargetName = GetLocalString(oPC, TRIB_LVAR_TARGET_NAME);
        if(sTargetUUID == "")
        {
            SendMessageToPC(oPC, "[Trybunał] Nie wybrano oskarżonego.");
            return;
        }
        string sCharge = JsonGetString(NuiGetBind(oPC, nToken, TRIB_BIND_CHARGE_TXT));
        if(sCharge == "")
        {
            SendMessageToPC(oPC, "[Trybunał] Zarzut nie może być pusty.");
            return;
        }
        if(TribGetOpenCaseCountFor(sTargetUUID) >= TRIB_MAX_OPEN_PER_DEF)
        {
            SendMessageToPC(oPC, "[Trybunał] Oskarżony ma już "
                + IntToString(TRIB_MAX_OPEN_PER_DEF) + " otwartych spraw. Trybunał odmawia przyjęcia kolejnej.");
            return;
        }
        string sEvid = JsonGetString(NuiGetBind(oPC, nToken, TRIB_BIND_EVID2_TXT));
        int nId = TribCreateCase(sTargetUUID, sTargetName,
                                 GetObjectUUID(oPC), GetName(oPC),
                                 sCharge, sEvid);
        SendMessageToPC(oPC, "[Trybunał] Oskarżenie złożone. Sprawa #" + IntToString(nId) + ".");

        // Warn defendant if online
        object oNotify = GetFirstPC();
        while(GetIsObjectValid(oNotify))
        {
            if(GetObjectUUID(oNotify) == sTargetUUID)
            {
                SendMessageToPC(oNotify,
                    "[Trybunał] Złożono przeciwko tobie oskarżenie: \"" + sCharge + "\".");
                FloatingTextStringOnCreature(
                    "Inkwizycja skierowała ku tobie swój wzrok...", oNotify, FALSE);
                break;
            }
            oNotify = GetNextPC();
        }

        DeleteLocalString(oPC, TRIB_LVAR_TARGET_UUID);
        DeleteLocalString(oPC, TRIB_LVAR_TARGET_NAME);
        SwapToCaseListView(oPC, nToken);
        return;
    }

    // Submit defense testimony
    if(sElem == TRIB_BTN_SUBMIT_DEF)
    {
        int nCaseId = GetLocalInt(oPC, TRIB_LVAR_CASE_ID);
        if(nCaseId <= 0) return;
        string sDefense = JsonGetString(NuiGetBind(oPC, nToken, TRIB_BIND_DEFENSE_TXT));
        TribUpdateDefense(nCaseId, sDefense);
        SendMessageToPC(oPC, "[Trybunał] Zeznanie zostało złożone.");
        return;
    }

    // Update evidence (judge only)
    if(sElem == TRIB_BTN_SUBMIT_EVID)
    {
        if(!GetIsDM(oPC))
        {
            SendMessageToPC(oPC, "[Trybunał] Tylko Inkwizycja może uzupełniać dowody.");
            return;
        }
        int nCaseId = GetLocalInt(oPC, TRIB_LVAR_CASE_ID);
        if(nCaseId <= 0) return;
        string sEvid = JsonGetString(NuiGetBind(oPC, nToken, TRIB_BIND_EVIDENCE_TXT));
        TribUpdateEvidence(nCaseId, sEvid);
        SendMessageToPC(oPC, "[Trybunał] Dowody zaktualizowane.");
        return;
    }

    // Verdicts — all require DM
    if(!GetIsDM(oPC)) return;

    int nCaseId  = GetLocalInt(oPC, TRIB_LVAR_CASE_ID);
    if(nCaseId <= 0) return;
    string sSent = JsonGetString(NuiGetBind(oPC, nToken, TRIB_BIND_SENTENCE_TXT));

    if(sElem == TRIB_BTN_GUILTY_JAIL)
    {
        TribApplyVerdict(oPC, nCaseId, TRIB_VERDICT_JAIL, sSent);
        SwapToCaseDetailView(oPC, nToken, nCaseId);
        return;
    }
    if(sElem == TRIB_BTN_GUILTY_EXILE)
    {
        TribApplyVerdict(oPC, nCaseId, TRIB_VERDICT_EXILE, sSent);
        SwapToCaseDetailView(oPC, nToken, nCaseId);
        return;
    }
    if(sElem == TRIB_BTN_GUILTY_DEATH)
    {
        TribApplyVerdict(oPC, nCaseId, TRIB_VERDICT_DEATH, sSent);
        SwapToCaseDetailView(oPC, nToken, nCaseId);
        return;
    }
    if(sElem == TRIB_BTN_INNOCENT)
    {
        TribApplyVerdict(oPC, nCaseId, TRIB_VERDICT_INNOCENT, sSent);
        SwapToCaseDetailView(oPC, nToken, nCaseId);
        return;
    }
}

#include "lib_sdebt"

// ----------------------------------------------------------------
// Helpers for event handler
// ----------------------------------------------------------------

void SDebtHandleProposeConfirm(object oPC)
{
    int nPopToken = NuiFindWindow(oPC, SDEBT_WIN_PROPOSE);
    if(nPopToken == 0) return;

    string sTargetUuid = GetLocalString(oPC, SDEBT_LVAR_PROP_UUID);
    string sTargetName = GetLocalString(oPC, SDEBT_LVAR_PROP_NAME);
    if(sTargetUuid == "")
    {
        SendMessageToPC(oPC, "[Dług Duszy] Wybierz najpierw cel z listy.");
        return;
    }

    string sDesc = JsonGetString(NuiGetBind(oPC, nPopToken, SDEBT_BIND_PROP_DESC));

    int nId = SDebtCreate(GetObjectUUID(oPC), GetName(oPC), sTargetUuid, sTargetName, sDesc);
    NuiDestroy(oPC, nPopToken);

    int nMainToken = NuiFindWindow(oPC, SDEBT_WINDOW);
    if(nMainToken != 0) SDebtFeedAll(oPC, nMainToken);

    SendMessageToPC(oPC, "[Dług Duszy] Propozycja wysłana do " + sTargetName + ".");

    // Notify target if online
    object oTarget = GetFirstPC();
    while(GetIsObjectValid(oTarget))
    {
        if(GetObjectUUID(oTarget) == sTargetUuid)
        {
            SendMessageToPC(oTarget, "[Dług Duszy] " + GetName(oPC)
                + " twierdzi, że ocali ci życie i żąda uznania długu.");
            DelayCommand(2.0, SDebtShowNotifyPopup(oTarget, nId, FALSE));
            break;
        }
        oTarget = GetNextPC();
    }
}

void SDebtHandleInvoke(object oPC, int nId)
{
    json jRow = SDebtGetById(nId);
    if(JsonGetType(jRow) == JSON_TYPE_NULL) return;

    string sSt = JsonGetString(JsonObjectGet(jRow, "status"));
    if(sSt != "active") return;

    SDebtInvoke(nId);

    string sDebtName = JsonGetString(JsonObjectGet(jRow, "debtor_name"));
    string sDebtUuid = JsonGetString(JsonObjectGet(jRow, "debtor_uuid"));
    SendMessageToPC(oPC, "[Dług Duszy] Wywołałeś dług " + sDebtName + ". Dłużnik będzie tracił HP.");

    // Notify and start pressure on debtor if online
    object oDebtor = GetFirstPC();
    while(GetIsObjectValid(oDebtor))
    {
        if(GetObjectUUID(oDebtor) == sDebtUuid)
        {
            SendMessageToPC(oDebtor, "[Dług Duszy] " + GetName(oPC)
                + " wywołał twój dług! Tracisz HP co 5 minut.");
            SDebtShowNotifyPopup(oDebtor, nId, TRUE);
            DelayCommand(SDEBT_INVOKE_TICK, SDebtApplyInvokePressure(oDebtor));
            break;
        }
        oDebtor = GetNextPC();
    }

    int nToken = NuiFindWindow(oPC, SDEBT_WINDOW);
    if(nToken != 0)
    {
        SetLocalInt(oPC, SDEBT_LVAR_SEL_ID, 0);
        SDebtFeedCredView(oPC, nToken);
        SDebtFeedAll(oPC, nToken);
    }
}

void SDebtHandleForgive(object oPC, int nId)
{
    json jRow = SDebtGetById(nId);
    if(JsonGetType(jRow) == JSON_TYPE_NULL) return;

    string sDebtName = JsonGetString(JsonObjectGet(jRow, "debtor_name"));
    SDebtSetStatus(nId, "forgiven");

    SendMessageToPC(oPC, "[Dług Duszy] Odpuściłeś dług " + sDebtName + ".");

    int nToken = NuiFindWindow(oPC, SDEBT_WINDOW);
    if(nToken != 0)
    {
        SetLocalInt(oPC, SDEBT_LVAR_SEL_ID, 0);
        SDebtFeedAll(oPC, nToken);
    }
}

void SDebtHandleAccept(object oPC, int nId)
{
    json jRow = SDebtGetById(nId);
    if(JsonGetType(jRow) == JSON_TYPE_NULL) return;

    string sSt = JsonGetString(JsonObjectGet(jRow, "status"));
    if(sSt != "pending") return;

    SDebtAccept(nId);

    string sCredName = JsonGetString(JsonObjectGet(jRow, "creditor_name"));
    string sCredUuid = JsonGetString(JsonObjectGet(jRow, "creditor_uuid"));
    SendMessageToPC(oPC, "[Dług Duszy] Przyjąłeś dług wobec " + sCredName + ". Pieczęć krwi pulsuje słabo…");
    FloatingTextStringOnCreature("Pieczęć krwi pulsuje słabo…", oPC, FALSE);

    // Notify creditor
    object oCreditor = GetFirstPC();
    while(GetIsObjectValid(oCreditor))
    {
        if(GetObjectUUID(oCreditor) == sCredUuid)
        {
            SendMessageToPC(oCreditor, "[Dług Duszy] " + GetName(oPC) + " przyjął twoje roszczenie.");
            int nCrToken = NuiFindWindow(oCreditor, SDEBT_WINDOW);
            if(nCrToken != 0) SDebtFeedAll(oCreditor, nCrToken);
            break;
        }
        oCreditor = GetNextPC();
    }

    int nToken = NuiFindWindow(oPC, SDEBT_WINDOW);
    if(nToken != 0)
    {
        SetLocalInt(oPC, SDEBT_LVAR_SEL_ID, 0);
        SDebtFeedAll(oPC, nToken);
    }
}

void SDebtHandleRepay(object oPC, int nId)
{
    json jRow = SDebtGetById(nId);
    if(JsonGetType(jRow) == JSON_TYPE_NULL) return;

    string sSt = JsonGetString(JsonObjectGet(jRow, "status"));
    if(sSt != "active" && sSt != "invoked") return;

    if(GetGold(oPC) < SDEBT_REPAY_GOLD)
    {
        SendMessageToPC(oPC, "[Dług Duszy] Nie masz wystarczająco złota (" + IntToString(SDEBT_REPAY_GOLD) + " sz.).");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(SDEBT_REPAY_GOLD, oPC, TRUE));
    SDebtSetStatus(nId, "repaid");

    string sCredName = JsonGetString(JsonObjectGet(jRow, "creditor_name"));
    string sCredUuid = JsonGetString(JsonObjectGet(jRow, "creditor_uuid"));
    SendMessageToPC(oPC, "[Dług Duszy] Spłaciłeś dług wobec " + sCredName + ". Pieczęć krwi gaśnie.");
    FloatingTextStringOnCreature("Pieczęć krwi gaśnie. Dług spłacony.", oPC, FALSE);

    // Notify creditor
    object oCreditor = GetFirstPC();
    while(GetIsObjectValid(oCreditor))
    {
        if(GetObjectUUID(oCreditor) == sCredUuid)
        {
            SendMessageToPC(oCreditor, "[Dług Duszy] " + GetName(oPC)
                + " spłacił twój dług (" + IntToString(SDEBT_REPAY_GOLD) + " sz.).");
            int nCrToken = NuiFindWindow(oCreditor, SDEBT_WINDOW);
            if(nCrToken != 0) SDebtFeedAll(oCreditor, nCrToken);
            break;
        }
        oCreditor = GetNextPC();
    }

    int nToken = NuiFindWindow(oPC, SDEBT_WINDOW);
    if(nToken != 0)
    {
        SetLocalInt(oPC, SDEBT_LVAR_SEL_ID, 0);
        SDebtFeedAll(oPC, nToken);
    }
}

void SDebtHandleRenounce(object oPC, int nId)
{
    json jRow = SDebtGetById(nId);
    if(JsonGetType(jRow) == JSON_TYPE_NULL) return;

    string sSt = JsonGetString(JsonObjectGet(jRow, "status"));
    if(sSt == "repaid" || sSt == "renounced" || sSt == "forgiven") return;

    SDebtSetStatus(nId, "renounced");
    SDebtApplyRenounceCurse(oPC);

    string sCredName = JsonGetString(JsonObjectGet(jRow, "creditor_name"));
    string sCredUuid = JsonGetString(JsonObjectGet(jRow, "creditor_uuid"));

    // Notify creditor
    object oCreditor = GetFirstPC();
    while(GetIsObjectValid(oCreditor))
    {
        if(GetObjectUUID(oCreditor) == sCredUuid)
        {
            SendMessageToPC(oCreditor, "[Dług Duszy] " + GetName(oPC)
                + " odrzucił twój dług. Przekleństwo spadnie na wyrzekającego się.");
            int nCrToken = NuiFindWindow(oCreditor, SDEBT_WINDOW);
            if(nCrToken != 0) SDebtFeedAll(oCreditor, nCrToken);
            break;
        }
        oCreditor = GetNextPC();
    }

    int nToken = NuiFindWindow(oPC, SDEBT_WINDOW);
    if(nToken != 0)
    {
        SetLocalInt(oPC, SDEBT_LVAR_SEL_ID, 0);
        SDebtFeedAll(oPC, nToken);
    }
}

// ----------------------------------------------------------------
// Main NUI event handler
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    // ---- Propose popup ----
    if(nToken == NuiFindWindow(oPC, SDEBT_WIN_PROPOSE))
    {
        if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == SDEBT_BTN_PROP_ROW)
        {
            json jList = GetLocalJson(oPC, SDEBT_LVAR_PROP_LIST);
            if(nIdx < 0 || nIdx >= JsonGetLength(jList)) return;
            json jEntry = JsonArrayGet(jList, nIdx);
            SetLocalString(oPC, SDEBT_LVAR_PROP_UUID, JsonGetString(JsonObjectGet(jEntry, "uuid")));
            SetLocalString(oPC, SDEBT_LVAR_PROP_NAME, JsonGetString(JsonObjectGet(jEntry, "name")));

            // Highlight selected row
            json jEncs = JsonArray();
            int i;
            for(i = 0; i < JsonGetLength(jList); i++)
                jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
            NuiSetBind(oPC, nToken, SDEBT_BIND_PROP_ENC, jEncs);
        }
        else if(sEvent == EVENT_TYPE_CLICK && sElem == SDEBT_BTN_PROP_CONFIRM)
        {
            SDebtHandleProposeConfirm(oPC);
        }
        else if(sEvent == EVENT_TYPE_CLICK && sElem == SDEBT_BTN_PROP_CANCEL)
        {
            NuiDestroy(oPC, nToken);
        }
        return;
    }

    // ---- Notify popup ----
    if(nToken == NuiFindWindow(oPC, SDEBT_WIN_NOTIFY))
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            int nDebtId = GetLocalInt(oPC, SDEBT_LVAR_NOTIF_ID);
            if(sElem == SDEBT_BTN_NOTIF_ACC && nDebtId > 0)
            {
                SDebtHandleAccept(oPC, nDebtId);
                NuiDestroy(oPC, nToken);
            }
            else if(sElem == SDEBT_BTN_NOTIF_REJ && nDebtId > 0)
            {
                SDebtHandleRenounce(oPC, nDebtId);
                NuiDestroy(oPC, nToken);
            }
            else if(sElem == SDEBT_BTN_NOTIF_OK)
            {
                NuiDestroy(oPC, nToken);
            }
        }
        return;
    }

    // ---- Main window ----
    if(nToken != NuiFindWindow(oPC, SDEBT_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, SDEBT_LVAR_SEL_ID);
        return;
    }

    int nSelId = GetLocalInt(oPC, SDEBT_LVAR_SEL_ID);

    // Tab buttons
    if(sEvent == EVENT_TYPE_CLICK && sElem == SDEBT_BTN_TAB_CRED)
    {
        SDebtSwitchTab(oPC, nToken, 0);
        return;
    }
    if(sEvent == EVENT_TYPE_CLICK && sElem == SDEBT_BTN_TAB_DEBT)
    {
        SDebtSwitchTab(oPC, nToken, 1);
        return;
    }
    if(sEvent == EVENT_TYPE_CLICK && sElem == SDEBT_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    // Creditor tab – row select
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == SDEBT_BTN_ROW_CRED)
    {
        json jRows = SDebtGetAsCreditor(GetObjectUUID(oPC));
        if(nIdx < 0 || nIdx >= JsonGetLength(jRows)) return;
        int nId = JsonGetInt(JsonObjectGet(JsonArrayGet(jRows, nIdx), "id"));
        SetLocalInt(oPC, SDEBT_LVAR_SEL_ID, nId);
        SDebtFeedCredView(oPC, nToken);
        return;
    }

    // Creditor tab – actions
    if(sEvent == EVENT_TYPE_CLICK && sElem == SDEBT_BTN_INVOKE)
    {
        if(nSelId > 0) SDebtHandleInvoke(oPC, nSelId);
        return;
    }
    if(sEvent == EVENT_TYPE_CLICK && sElem == SDEBT_BTN_FORGIVE)
    {
        if(nSelId > 0) SDebtHandleForgive(oPC, nSelId);
        return;
    }
    if(sEvent == EVENT_TYPE_CLICK && sElem == SDEBT_BTN_PROPOSE)
    {
        SDebtShowProposePopup(oPC);
        return;
    }

    // Debtor tab – row select
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == SDEBT_BTN_ROW_DEBT)
    {
        json jRows = SDebtGetAsDebtor(GetObjectUUID(oPC));
        if(nIdx < 0 || nIdx >= JsonGetLength(jRows)) return;
        int nId = JsonGetInt(JsonObjectGet(JsonArrayGet(jRows, nIdx), "id"));
        SetLocalInt(oPC, SDEBT_LVAR_SEL_ID, nId);
        SDebtFeedDebtView(oPC, nToken);
        return;
    }

    // Debtor tab – actions
    if(sEvent == EVENT_TYPE_CLICK && sElem == SDEBT_BTN_ACCEPT)
    {
        if(nSelId > 0) SDebtHandleAccept(oPC, nSelId);
        return;
    }
    if(sEvent == EVENT_TYPE_CLICK && sElem == SDEBT_BTN_REPAY)
    {
        if(nSelId > 0) SDebtHandleRepay(oPC, nSelId);
        return;
    }
    if(sEvent == EVENT_TYPE_CLICK && sElem == SDEBT_BTN_RENOUNCE)
    {
        if(nSelId > 0) SDebtHandleRenounce(oPC, nSelId);
        return;
    }
}

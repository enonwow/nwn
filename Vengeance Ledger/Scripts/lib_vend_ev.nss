#include "lib_vend"

// ================================================================
// Forswear confirmation handler
// ================================================================

void HandleForswearConfirm(object oPC)
{
    int nId = GetLocalInt(oPC, VEND_LVAR_PENDING_ID);
    if (nId <= 0) return;

    VendForswearGrudge(nId);

    int nNewXP = GetXP(oPC) - VEND_FORSW_XP_PENALTY;
    if (nNewXP < 0) nNewXP = 0;
    SetXP(oPC, nNewXP);

    SendMessageToPC(oPC,
        "[Księga Krzywd] Wyrzekasz się zemsty. "
        "Niech ciężar tej zniewagi spoczywa na twej duszy.");

    DeleteLocalInt(oPC, VEND_LVAR_PENDING_ID);
    SetLocalInt(oPC, VEND_LVAR_SEL_ID, 0);

    ApplyVendEffects(oPC);

    NuiDestroy(oPC, NuiFindWindow(oPC, VEND_WIN_CONFIRM));

    int nMain = NuiFindWindow(oPC, VEND_WINDOW);
    if (nMain) FeedVendWindow(oPC, nMain);
}

// ================================================================
// Active list row selection
// ================================================================

void HandleRowSelect(object oPC, int nToken, int nIdx)
{
    json jActive = VendGetActiveGrudges(oPC);
    if (nIdx < 0 || nIdx >= JsonGetLength(jActive)) return;

    json jRow = JsonArrayGet(jActive, nIdx);
    int  nId  = JsonGetInt(JsonObjectGet(jRow, "id"));

    SetLocalInt(oPC, VEND_LVAR_SEL_ID, nId);

    int  nCount = JsonGetLength(jActive);
    json jEncs  = JsonArray();
    int  i;
    for (i = 0; i < nCount; i++)
        jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));

    NuiSetBind(oPC, nToken, VEND_BIND_ACT_ENC,   jEncs);
    NuiSetBind(oPC, nToken, VEND_BIND_FORSW_ENA, JsonBool(TRUE));
}

// ================================================================
// Forswear button — opens confirmation popup
// ================================================================

void HandleForswearRequest(object oPC)
{
    int nSelId = GetLocalInt(oPC, VEND_LVAR_SEL_ID);
    if (nSelId <= 0) return;

    json   jActive = VendGetActiveGrudges(oPC);
    string sName   = "";
    int    i;
    for (i = 0; i < JsonGetLength(jActive); i++)
    {
        json jRow = JsonArrayGet(jActive, i);
        if (JsonGetInt(JsonObjectGet(jRow, "id")) == nSelId)
        {
            sName = JsonGetString(JsonObjectGet(jRow, "wrongdoer_name"));
            break;
        }
    }

    CreateVendConfirmPopup(oPC, nSelId, sName);
}

// ================================================================
// Main event handler
// ================================================================

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    // --- Forswear confirmation popup ---
    if (nToken == NuiFindWindow(oPC, VEND_WIN_CONFIRM))
    {
        if (sEvent == EVENT_TYPE_CLICK)
        {
            if (sElem == VEND_BTN_FORSW_OK)
                HandleForswearConfirm(oPC);
            else if (sElem == VEND_BTN_FORSW_CANCEL)
                NuiDestroy(oPC, nToken);
        }
        return;
    }

    if (nToken != NuiFindWindow(oPC, VEND_WINDOW)) return;

    if (sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, VEND_LVAR_SEL_ID);
        return;
    }

    if (sEvent == EVENT_TYPE_CLICK)
    {
        if (sElem == VEND_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if (sElem == VEND_BTN_FORSWEAR)
        {
            HandleForswearRequest(oPC);
            return;
        }
    }

    if (sEvent == EVENT_TYPE_MOUSEDOWN && sElem == VEND_BTN_ROW_ACT)
    {
        HandleRowSelect(oPC, nToken, nIdx);
        return;
    }
}

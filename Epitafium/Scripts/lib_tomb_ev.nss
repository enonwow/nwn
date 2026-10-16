// lib_tomb_ev.nss — NUI event handler for Epitafium

#include "lib_tomb"

// ----------------------------------------------------------------
// Write-window helpers
// ----------------------------------------------------------------

void HandleWriteWatch(object oPC, int nToken, string sElem)
{
    if(sElem != TOMB_BIND_W_EPITAPH) return;

    string sText = JsonGetString(NuiGetBind(oPC, nToken, TOMB_BIND_W_EPITAPH));
    int    nLen  = GetStringLength(sText);
    int    nLeft = TOMB_EPITAPH_MAX - nLen;

    string sHint = IntToString(nLen) + " / " + IntToString(TOMB_EPITAPH_MAX);
    if(nLeft < 30)
        sHint = sHint + "  (zostało " + IntToString(nLeft) + ")";

    NuiSetBind(oPC, nToken, TOMB_BIND_W_HINT, JsonString(sHint));
}

void HandleWriteClick(object oPC, int nToken, string sElem)
{
    if(sElem == TOMB_BTN_ENGRAVE)
    {
        TombFinalizeMemorial(oPC, nToken);
        return;
    }
    if(sElem == TOMB_BTN_SKIP)
    {
        NuiDestroy(oPC, nToken);
        TombClearDeathLvars(oPC);
        SendMessageToPC(oPC, "[Epitafium] Nie zostawiasz po sobie słów...");
        return;
    }
}

void HandleWriteClose(object oPC)
{
    // Closing without confirming = same as skip
    TombClearDeathLvars(oPC);
}

// ----------------------------------------------------------------
// Read-window helpers
// ----------------------------------------------------------------

void HandleReadClick(object oPC, int nToken, string sElem)
{
    if(sElem == TOMB_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        DeleteLocalInt(oPC, TOMB_LVAR_MEM_ID);
        return;
    }
    if(sElem == TOMB_BTN_TRIBUTE)
    {
        int nId = GetLocalInt(oPC, TOMB_LVAR_MEM_ID);
        if(nId > 0)
            TombPayTribute(oPC, nToken, nId);
        return;
    }
}

// ----------------------------------------------------------------
// Main dispatch
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    // ---- Write window ----
    if(nToken == NuiFindWindow(oPC, TOMB_WIN_WRITE))
    {
        if(sEvent == EVENT_TYPE_WATCH)
        {
            HandleWriteWatch(oPC, nToken, sElem);
            return;
        }
        if(sEvent == EVENT_TYPE_CLICK)
        {
            HandleWriteClick(oPC, nToken, sElem);
            return;
        }
        if(sEvent == EVENT_TYPE_CLOSE)
        {
            HandleWriteClose(oPC);
            return;
        }
        return;
    }

    // ---- Read window ----
    if(nToken == NuiFindWindow(oPC, TOMB_WIN_READ))
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            HandleReadClick(oPC, nToken, sElem);
            return;
        }
        if(sEvent == EVENT_TYPE_CLOSE)
        {
            DeleteLocalInt(oPC, TOMB_LVAR_MEM_ID);
            return;
        }
        return;
    }
}

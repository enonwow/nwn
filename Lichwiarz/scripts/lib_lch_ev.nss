// lib_lch_ev.nss — NUI event handler for Lichwiarz (Usurer system)

#include "lib_lch"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    // ---- Borrow popup ----
    if(nToken == NuiFindWindow(oPC, LCH_WIN_BORROW))
    {
        if(sEvent == EVENT_TYPE_WATCH && sElem == LCH_BIND_BORROW_AMT)
        {
            string sVal       = JsonGetString(NuiGetBind(oPC, nToken, LCH_BIND_BORROW_AMT));
            int    nVal       = StringToInt(sVal);
            json   jLoan      = LchGetLoan(oPC);
            int    nCurrDebt  = (JsonGetType(jLoan) != JSON_TYPE_NULL)
                                ? JsonGetInt(JsonObjectGet(jLoan, "current_debt")) : 0;
            int bValid = (sVal != "" && nVal >= LCH_MIN_LOAN && nVal <= LCH_MAX_LOAN
                          && (nCurrDebt + nVal) <= LCH_MAX_LOAN);
            NuiSetBind(oPC, nToken, LCH_BIND_CONFIRM_ENA, JsonBool(bValid));
            return;
        }
        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == LCH_BTN_BORROW_OK) { LchHandleBorrow(oPC);        return; }
            if(sElem == LCH_BTN_BORROW_X)  { NuiDestroy(oPC, nToken);     return; }
        }
        return;
    }

    // ---- Repay popup ----
    if(nToken == NuiFindWindow(oPC, LCH_WIN_REPAY))
    {
        if(sEvent == EVENT_TYPE_WATCH && sElem == LCH_BIND_REPAY_AMT)
        {
            string sVal  = JsonGetString(NuiGetBind(oPC, nToken, LCH_BIND_REPAY_AMT));
            int    nVal  = StringToInt(sVal);
            int    nGold = GetGold(oPC);
            json   jLoan = LchGetLoan(oPC);
            int    nDebt = (JsonGetType(jLoan) != JSON_TYPE_NULL)
                           ? JsonGetInt(JsonObjectGet(jLoan, "current_debt")) : 0;
            int bValid = (sVal != "" && nVal > 0 && nVal <= nGold && nVal <= nDebt);
            NuiSetBind(oPC, nToken, LCH_BIND_DO_REPAY_ENA, JsonBool(bValid));
            return;
        }
        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == LCH_BTN_REPAY_DO)   { LchHandleRepay(oPC, FALSE); return; }
            if(sElem == LCH_BTN_REPAY_FULL) { LchHandleRepay(oPC, TRUE);  return; }
            if(sElem == LCH_BTN_REPAY_X)    { NuiDestroy(oPC, nToken);    return; }
        }
        return;
    }

    // ---- Main window ----
    if(nToken != NuiFindWindow(oPC, LCH_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        int nBorrow = NuiFindWindow(oPC, LCH_WIN_BORROW);
        int nRepay  = NuiFindWindow(oPC, LCH_WIN_REPAY);
        if(nBorrow != 0) NuiDestroy(oPC, nBorrow);
        if(nRepay  != 0) NuiDestroy(oPC, nRepay);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == LCH_BTN_BORROW) { LchCreateBorrowPopup(oPC); return; }
        if(sElem == LCH_BTN_REPAY)  { LchCreateRepayPopup(oPC);  return; }
    }
}

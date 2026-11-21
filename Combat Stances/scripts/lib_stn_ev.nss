#include "lib_stn"

// ----------------------------------------------------------------
// Main NUI event handler for Combat Stances windows.
// Registered as: lib_stn_ev
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    // ---- Widget ----
    if(nToken == NuiFindWindow(oPC, STN_WIN_WIDGET))
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == STN_BTN_WGT_OPEN)
            {
                CreateStanceWindow(oPC);
                return;
            }
            if(sElem == STN_BTN_WGT_CLOSE)
            {
                NuiDestroy(oPC, nToken);
                return;
            }
        }
        return;
    }

    // ---- Book window ----
    if(nToken != NuiFindWindow(oPC, STN_WIN_BOOK)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, STN_LVAR_SEL);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == STN_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == STN_BTN_ADOPT)
        {
            int nSel = GetLocalInt(oPC, STN_LVAR_SEL);
            StnAdoptStance(oPC, nSel);
            return;
        }

        if(sElem == STN_BTN_UNLOCK)
        {
            int nSel = GetLocalInt(oPC, STN_LVAR_SEL);
            StnUnlockAtTrainer(oPC, nSel);
            return;
        }
    }

    // Row click: select stance for preview
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == STN_BTN_ROW)
    {
        if(nIdx < 0 || nIdx >= STN_COUNT) return;
        SetLocalInt(oPC, STN_LVAR_SEL, nIdx);
        FeedStanceWindow(oPC, nToken);
        return;
    }
}

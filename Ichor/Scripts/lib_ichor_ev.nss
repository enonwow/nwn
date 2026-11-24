#include "lib_ichor"

// ----------------------------------------------------------------
// Main NUI event handler — set as the event script for ICHOR_WINDOW.
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, ICHOR_WINDOW)) return;

    // ---- Window closed ----
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        SetLocalInt(oPC, ICHOR_LVAR_SEL_IDX, -1);
        DeleteLocalJson(oPC, ICHOR_LVAR_ESS_JSON);
        return;
    }

    // ---- Close button ----
    if(sEvent == EVENT_TYPE_CLICK && sElem == ICHOR_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    // ---- Essence list row click ----
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == ICHOR_BTN_ROW)
    {
        int nPrev = GetLocalInt(oPC, ICHOR_LVAR_SEL_IDX);
        if(nIdx == nPrev)
        {
            // Deselect on second click
            SetLocalInt(oPC, ICHOR_LVAR_SEL_IDX, -1);
        }
        else
        {
            SetLocalInt(oPC, ICHOR_LVAR_SEL_IDX, nIdx);
        }
        IchorFeedEssences(oPC, nToken);
        IchorFeedDesc    (oPC, nToken);
        IchorFeedWeapon  (oPC, nToken);
        return;
    }

    // ---- Apply button ----
    if(sEvent == EVENT_TYPE_CLICK && sElem == ICHOR_BTN_APPLY)
    {
        IchorApply(oPC, nToken);
        return;
    }

    // ---- Remove slot 1 ----
    if(sEvent == EVENT_TYPE_CLICK && sElem == ICHOR_BTN_REM1)
    {
        IchorRemoveSlotDB(oPC, nToken, 1);
        return;
    }

    // ---- Remove slot 2 ----
    if(sEvent == EVENT_TYPE_CLICK && sElem == ICHOR_BTN_REM2)
    {
        IchorRemoveSlotDB(oPC, nToken, 2);
        return;
    }
}

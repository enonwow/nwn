#include "lib_ink"

// ----------------------------------------------------------------
// NUI event handler for the Inkantator window
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, INK_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, INK_LVAR_SEL_FORM);
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK && sEvent != EVENT_TYPE_MOUSEDOWN) return;

    // ---- Top bar ----
    if(sElem == INK_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    // ---- Tab switches ----
    if(sElem == INK_BTN_TAB_GRIMOIRE)
    {
        InkSwapToGrimoire(oPC, nToken);
        return;
    }

    if(sElem == INK_BTN_TAB_WORKSHOP)
    {
        int nSelForm = GetLocalInt(oPC, INK_LVAR_SEL_FORM);
        if(nSelForm > 0 && InkIsFormulaKnown(oPC, nSelForm))
            InkSwapToWorkshop(oPC, nToken, nSelForm);
        else
            SendMessageToPC(oPC, "[Inkantator] Najpierw wybierz formułę z Grimuaru.");
        return;
    }

    if(sElem == INK_BTN_TAB_HISTORY)
    {
        InkSwapToHistory(oPC, nToken);
        return;
    }

    // ---- Grimoire: row click ----
    // Row index maps directly to formula_id - 1 (all 8 formulas shown)
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == INK_BTN_FORM_ROW)
    {
        int nFormulaId = nIdx + 1;
        if(nFormulaId < 1 || nFormulaId > INK_FORMULA_COUNT) return;

        if(!InkIsFormulaKnown(oPC, nFormulaId))
        {
            if(InkIsFormulaAdvanced(nFormulaId))
                SendMessageToPC(oPC, "[Inkantator] Ta formuła jest zapieczętowana. "
                    "Znajdź zwój wiedzy, by ją odczytać.");
            else
                InkLearnFormula(oPC, nFormulaId); // fallback: grant basic formula
            return;
        }

        InkSwapToWorkshop(oPC, nToken, nFormulaId);
        return;
    }

    // ---- Workshop: back button ----
    if(sElem == INK_BTN_WS_BACK)
    {
        InkSwapToGrimoire(oPC, nToken);
        return;
    }

    // ---- Workshop: inscribe button ----
    if(sElem == INK_BTN_INSCRIBE)
    {
        int nFormId = GetLocalInt(oPC, INK_LVAR_SEL_FORM);
        if(nFormId < 1 || nFormId > INK_FORMULA_COUNT)
        {
            SendMessageToPC(oPC, "[Inkantator] Żadna formuła nie jest wybrana.");
            return;
        }
        if(!InkIsFormulaKnown(oPC, nFormId))
        {
            SendMessageToPC(oPC, "[Inkantator] Tej formuły nie znasz.");
            return;
        }
        InkDoInscribe(oPC, nToken, nFormId);
        return;
    }
}

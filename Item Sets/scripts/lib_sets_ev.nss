#include "lib_sets"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, SETS_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, SETS_LVAR_SEL);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == SETS_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        // Set roster row clicked – update selection and refresh detail
        if(sElem == SETS_BTN_ROW)
        {
            if(nIdx < 0 || nIdx >= SETS_TOTAL) return;

            int nCurSel = GetLocalInt(oPC, SETS_LVAR_SEL);
            // Clicking the already-selected row deselects it
            if(nCurSel == nIdx)
                SetLocalInt(oPC, SETS_LVAR_SEL, -1);
            else
                SetLocalInt(oPC, SETS_LVAR_SEL, nIdx);

            FeedSetsPanel(oPC, nToken);
            return;
        }
    }
}

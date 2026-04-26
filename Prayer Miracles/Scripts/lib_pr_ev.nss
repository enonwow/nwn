#include "lib_pr"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    int nMain  = NuiFindWindow(oPC, PR_WINDOW);
    int nDeity = NuiFindWindow(oPC, PR_WIN_DEITY);

    // ---- Deity selector ----
    if(nToken == nDeity && nDeity != 0)
    {
        if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == PR_BTN_DEITY_ROW)
        {
            if(nIdx >= 0 && nIdx < PR_DEITY_COUNT)
                PrSelectDeity(oPC, nIdx);
        }
        return;
    }

    // ---- Main window ----
    if(nToken != nMain || nMain == 0) return;

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == PR_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }
        if(sElem == PR_BTN_PRAY)
        {
            PrPray(oPC);
            return;
        }
        if(sElem == PR_BTN_CHANGE_DEITY)
        {
            PrShowDeitySelector(oPC);
            return;
        }
        if(sElem == PR_BTN_MIRACLE)
        {
            // Click came from a per-row button — index identifies the miracle.
            if(nIdx < 0 || nIdx >= PR_MIRACLE_COUNT) return;
            if(PrMiracleNeedsTarget(nIdx))
                PrStartMiracleTargeting(oPC, nIdx);
            else
                PrTryCastMiracle(oPC, nIdx, OBJECT_INVALID);
            return;
        }
    }
}

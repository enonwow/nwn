// lib_cor_ev.nss  –  Corruption: NUI event handler (OnNUIWindowRoutine)

#include "lib_cor"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(nToken != NuiFindWindow(oPC, COR_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
        return; // no cleanup needed — effects are persistent

    if(sEvent == EVENT_TYPE_OPEN)
    {
        CorRefreshWindow(oPC);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == COR_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == COR_BTN_RITUAL)
        {
            CorPerformRitual(oPC);
            return;
        }
    }
}

// lib_san_ev.nss — NUI event handler for the Sanity module.
//   Assign this script to the module's OnNUIEvent hook.

#include "lib_san"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    // Only process events for our window.
    if(nToken != NuiFindWindow(oPC, SAN_WINDOW)) return;

    if(sEvent == EVENT_TYPE_OPEN)
    {
        SanFeedWindow(oPC, nToken);
        return;
    }

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        // Nothing to clean up — all state is in SQL.
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == SAN_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == SAN_BTN_MEDITATE)
        {
            SanHandleMeditate(oPC, nToken);
            return;
        }
    }
}

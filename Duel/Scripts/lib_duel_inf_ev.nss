// lib_duel_inf_ev.nss
// Event handler for the Honor Duels info / rules window.
// Currently only handles Close.
#include "lib_duel_inf"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(NuiFindWindow(oPC, DUEL_INF_WINDOW) != nToken) return;

    if(sEvent == EVENT_TYPE_CLICK && sElem == DUEL_INF_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
    }
}

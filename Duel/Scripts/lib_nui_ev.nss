// lib_nui_ev.nss
// Event handler for lib_nui info windows (CreateWindowInfo).
// Closes the window when the Close button is clicked.
#include "lib_nui"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(sEvent == EVENT_TYPE_CLICK && sElem == CLOSE)
    {
        NuiDestroy(oPC, nToken);
    }
}

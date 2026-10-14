#include "lib_nit"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(nToken != NuiFindWindow(oPC, NIT_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
        return;

    if(sEvent != EVENT_TYPE_CLICK) return;

    if(sElem == NIT_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    if(sElem == NIT_BTN_CLEANSE)
    {
        NitTryCleanse(oPC, nToken);
        return;
    }
}

#include "lib_sin"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if (nToken != NuiFindWindow(oPC, SIN_WINDOW)) return;

    if (sEvent == EVENT_TYPE_CLOSE) return;

    if (sEvent != EVENT_TYPE_CLICK) return;

    if (sElem == SIN_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    if (sElem == SIN_BTN_ABS)
    {
        SinAbsolve(oPC);
        return;
    }

    if (sElem == SIN_BTN_EMBRACE)
    {
        SinEmbrace(oPC);
        return;
    }
}

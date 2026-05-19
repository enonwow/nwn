// lib_bur_ev.nss — NUI event handler for Burial Rites

#include "lib_bur"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(nToken != NuiFindWindow(oPC, BUR_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
        return;

    if(sEvent != EVENT_TYPE_CLICK) return;

    if(sElem == BUR_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    if(sElem == BUR_BTN_PAUPER)
    {
        BurApplyRite(oPC, BUR_RITE_PAUPER);
        return;
    }

    if(sElem == BUR_BTN_PROPER)
    {
        BurApplyRite(oPC, BUR_RITE_PROPER);
        return;
    }

    if(sElem == BUR_BTN_SACRED)
    {
        BurApplyRite(oPC, BUR_RITE_SACRED);
        return;
    }
}

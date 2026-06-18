// lib_vic_ev.nss — NUI event handler for the Vices (Nałogi) window.
// Registered as the event script in NuiCreate.
#include "lib_vic"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(nToken != NuiFindWindow(oPC, VIC_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE) return;

    if(sEvent != EVENT_TYPE_CLICK) return;

    // Consume button: VIC_BTN_CONSUME + substanceId
    int nConsumeLen = GetStringLength(VIC_BTN_CONSUME);
    if(GetStringLeft(sElem, nConsumeLen) == VIC_BTN_CONSUME)
    {
        int nSub = StringToInt(GetStringRight(sElem, GetStringLength(sElem) - nConsumeLen));
        VicConsumeDose(oPC, nSub);
        return;
    }

    // Detox button: VIC_BTN_BREAK + substanceId
    int nBreakLen = GetStringLength(VIC_BTN_BREAK);
    if(GetStringLeft(sElem, nBreakLen) == VIC_BTN_BREAK)
    {
        int nSub = StringToInt(GetStringRight(sElem, GetStringLength(sElem) - nBreakLen));
        VicAttemptDetox(oPC, nSub);
        return;
    }
}

#include "lib_lycan"

// NUI event handler — registered as LYCAN_EV_SCRIPT on the status window.

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(nToken != NuiFindWindow(oPC, LYCAN_WIN_STATUS)) return;

    if(sEvent == EVENT_TYPE_CLOSE) return;

    if(sEvent != EVENT_TYPE_CLICK) return;

    if(sElem == LYCAN_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    if(sElem == LYCAN_BTN_CURE)
    {
        if(LycanGetInfectionStage(oPC) == LYCAN_STAGE_NONE)
        {
            SendMessageToPC(oPC, "[Wilkołactwo] Nie jesteś zarażony.");
            return;
        }
        LycanTryCure(oPC);
        LycanFeedWindow(oPC, nToken);
        return;
    }

    if(sElem == LYCAN_BTN_TRANSFORM)
    {
        int nStage = LycanGetInfectionStage(oPC);
        if(nStage < LYCAN_STAGE_FULL)
        {
            SendMessageToPC(oPC,
                "[Wilkołactwo] Klątwa jeszcze nie dojrzała do pełnej przemiany.");
            return;
        }

        if(GetLocalInt(oPC, LYCAN_LVAR_TRANSFORMED))
            LycanRevert(oPC);
        else
            LycanTransform(oPC);

        LycanFeedWindow(oPC, nToken);
        return;
    }
}

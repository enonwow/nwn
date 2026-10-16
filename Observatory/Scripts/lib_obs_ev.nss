#include "lib_obs"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(nToken != NuiFindWindow(oPC, OBS_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalString(oPC, OBS_LVAR_RESULT);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == OBS_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == OBS_BTN_READ)
        {
            ObsDoReading(oPC, nToken);
            return;
        }
    }
}

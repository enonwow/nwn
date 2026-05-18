#include "lib_prison"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(nToken != NuiFindWindow(oPC, PRISON_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        // Window closed — heartbeat keeps running; no state to clean.
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == PRISON_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == PRISON_BTN_TAB_STATUS)
        {
            PrisonOpenStatus(oPC, nToken);
            return;
        }

        if(sElem == PRISON_BTN_TAB_HISTORY)
        {
            PrisonOpenHistory(oPC, nToken);
            return;
        }

        if(sElem == PRISON_BTN_SERVE)
        {
            // Serve time: close window and let the heartbeat do its work.
            SendMessageToPC(oPC, "[Więzienie] Siadasz na pryczy. Czas przecieka przez palce niczym piasek.");
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == PRISON_BTN_BRIBE)
        {
            PrisonTryBribe(oPC, nToken);
            return;
        }

        if(sElem == PRISON_BTN_PICK)
        {
            PrisonTryPickLock(oPC, nToken);
            return;
        }

        if(sElem == PRISON_BTN_OVERPOWER)
        {
            PrisonTryOverpower(oPC, nToken);
            return;
        }
    }
}

#include "lib_bcn"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(nToken != NuiFindWindow(oPC, BCN_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalObject(oPC, BCN_LVAR_BEACON_OBJ);
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK) return;

    if(sElem == BCN_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    object oBeacon = GetLocalObject(oPC, BCN_LVAR_BEACON_OBJ);
    if(!GetIsObjectValid(oBeacon))
    {
        SendMessageToPC(oPC, "[Latarnia] Nie mozna znalezc latarni — zamykanie okna.");
        NuiDestroy(oPC, nToken);
        return;
    }

    if(sElem == BCN_BTN_KINDLE)
    {
        BcnTryKindle(oPC, oBeacon, nToken);
        return;
    }
    if(sElem == BCN_BTN_REST)
    {
        BcnTryRest(oPC, oBeacon, nToken);
        return;
    }
    if(sElem == BCN_BTN_PURIFY)
    {
        BcnTryPurify(oPC, oBeacon, nToken);
        return;
    }
}

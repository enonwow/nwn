// lib_chaos_ev.nss — NUI event handler for the Chaos Surge window.
// Assigned as EventScript when the window is created.

#include "lib_chaos"

void main()
{
    object oPC     = NuiGetEventPlayer();
    int    nToken  = NuiGetEventWindow();
    string sEvent  = NuiGetEventType();
    string sElem   = NuiGetEventElement();

    if(nToken != NuiFindWindow(oPC, CHAOS_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
        return; // state is saved by ChaosSaveState on any surge; nothing extra needed

    if(sEvent != EVENT_TYPE_CLICK) return;

    if(sElem == CHAOS_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    if(sElem == CHAOS_BTN_SURGE)
    {
        int nCP = ChaosGetCP(oPC);
        if(nCP < CHAOS_SURGE_COST)
        {
            SendMessageToPC(oPC,
                "[Chaos] Za mało punktów chaosu. Potrzebujesz co najmniej "
                + IntToString(CHAOS_SURGE_COST) + " CP.");
            return;
        }
        // Manual surge — guaranteed trigger at any CP level
        ChaosRollSurge(oPC);
        return;
    }
}

// lib_rit_ev.nss - Ritual Circles: NUI event handler
// Assigned to the window via RIT_EV_SCRIPT constant.

#include "lib_rit"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, RIT_WINDOW)) return;

    string sTag = GetLocalString(oPC, RIT_LVAR_CIRCLE);

    // Window closed via native X button — clean up if not in an active ritual
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        if(sTag != "" && !RitIsParticipant(oPC, sTag))
            DeleteLocalString(oPC, RIT_LVAR_CIRCLE);
        return;
    }

    if(sTag == "") return; // guard: window open but no circle tracked

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == RIT_BTN_JOIN)
        {
            RitJoin(oPC, sTag);
            return;
        }
        if(sElem == RIT_BTN_LEAVE)
        {
            RitLeave(oPC, sTag);
            return;
        }
        if(sElem == RIT_BTN_BEGIN)
        {
            RitBegin(oPC, sTag);
            return;
        }
        if(sElem == RIT_BTN_CANCEL)
        {
            RitCancel(oPC, sTag);
            return;
        }
    }

    // Ritual type row selection (mousedown fires before click, gives better UX feel)
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == RIT_BTN_TYPE_ROW)
    {
        // nIdx is 0-based; ritual types are 1-indexed
        int nType = nIdx + 1;
        RitSetType(oPC, sTag, nType);
        return;
    }
}

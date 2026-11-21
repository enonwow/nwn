#include "lib_astr"

// NUI event handler — registered as ASTR_EV_SCRIPT ("lib_astr_ev").
// All astral projection windows route here.
void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(nToken != NuiFindWindow(oPC, ASTR_WINDOW)) return;

    switch(TRUE)
    {
        // ---- Window closed via native X button (voluntary return) ----
        case (sEvent == EVENT_TYPE_CLOSE):
        {
            // Only exit if still active; prevents double-call when AstrExitProjection destroys the window
            if(GetLocalInt(oPC, ASTR_LVAR_ACTIVE))
                AstrExitProjection(oPC, FALSE);
            break;
        }

        case (sEvent == EVENT_TYPE_CLICK && sElem == ASTR_BTN_RETURN):
        {
            AstrExitProjection(oPC, FALSE);
            break;
        }

        case (sEvent == EVENT_TYPE_CLICK && sElem == ASTR_BTN_PERCEIVE):
        {
            AstrPerceiveHidden(oPC);
            break;
        }
    }
}

// =============================================================================
// lib_rations_ev.nss
// =============================================================================
// NUI event router for the Rations HUD window.
//
// Wires:
//   - WATCH on geometry bind   -> debounced position save (0.5s after last drag)
//   - CLOSE                    -> cleanup
// =============================================================================

#include "lib_rations"

void main()
{
    object oPC      = NuiGetEventPlayer();
    int    nToken   = NuiGetEventWindow();
    string sEvent   = NuiGetEventType();
    string sElement = NuiGetEventElement();

    if(GetLocalInt(oPC, RAT_LVAR_HUD_TOKEN) != nToken) return;

    if(sEvent == "close")
    {
        DeleteLocalInt(oPC, RAT_LVAR_HUD_TOKEN);
        DeleteLocalInt(oPC, RAT_LVAR_GEOM_DELAY);
        DeleteLocalInt(oPC, RAT_LVAR_TICK_GUARD);
        return;
    }

    if(sEvent == "watch" && sElement == RAT_BIND_GEOM)
    {
        // Debounce: wait 0.5s after the last drag before reading the bind,
        // because NuiGetBind can lag a few ticks after the user releases.
        if(GetLocalInt(oPC, RAT_LVAR_GEOM_DELAY)) return;
        SetLocalInt(oPC, RAT_LVAR_GEOM_DELAY, 1);
        DelayCommand(0.5, RationsSaveHudPos(oPC));
        return;
    }
}

// =============================================================================
// lib_wnt_ev.nss
// =============================================================================
// NUI event router for the Wanted system.
// Wires both the HUD and the Records Panel:
//
//   HUD:
//     WATCH  geometry bind → debounced position save (0.5 s after last drag)
//     CLOSE                → cleanup locals
//     CLICK  WNT_BTN_OPEN  → toggle Records Panel
//
//   Panel:
//     CLOSE              → cleanup local
//     CLICK WNT_BTN_BRIBE     → WantedBribe()
//     CLICK WNT_BTN_SURRENDER → WantedSurrender()
//     CLICK WNT_BTN_CLOSE     → WantedDestroyPanel()
// =============================================================================

#include "lib_wnt"

void main()
{
    object oPC      = NuiGetEventPlayer();
    int    nToken   = NuiGetEventWindow();
    string sEvent   = NuiGetEventType();
    string sElement = NuiGetEventElement();

    int nHudToken   = GetLocalInt(oPC, WNT_LVAR_HUD_TOKEN);
    int nPanelToken = GetLocalInt(oPC, WNT_LVAR_PANEL_TOKEN);

    // -------------------------------------------------------------------------
    // HUD events
    // -------------------------------------------------------------------------
    if(nToken == nHudToken)
    {
        if(sEvent == "close")
        {
            DeleteLocalInt(oPC, WNT_LVAR_HUD_TOKEN);
            DeleteLocalInt(oPC, WNT_LVAR_GEOM_DELAY);
            DeleteLocalInt(oPC, WNT_LVAR_TICK_GUARD);
            return;
        }

        if(sEvent == "watch" && sElement == WNT_BIND_GEOM)
        {
            // Debounce: 0.5 s after the last drag frame before reading position.
            if(GetLocalInt(oPC, WNT_LVAR_GEOM_DELAY)) return;
            SetLocalInt(oPC, WNT_LVAR_GEOM_DELAY, 1);
            DelayCommand(0.5, WantedSaveHudPos(oPC));
            return;
        }

        if(sEvent == "click" && sElement == WNT_BTN_OPEN)
        {
            if(NuiFindWindow(oPC, WNT_PANEL_WIN) != 0)
                WantedDestroyPanel(oPC);
            else
                WantedOpenPanel(oPC);
            return;
        }

        return;
    }

    // -------------------------------------------------------------------------
    // Records Panel events
    // -------------------------------------------------------------------------
    if(nToken == nPanelToken)
    {
        if(sEvent == "close")
        {
            DeleteLocalInt(oPC, WNT_LVAR_PANEL_TOKEN);
            return;
        }

        if(sEvent == "click")
        {
            if(sElement == WNT_BTN_CLOSE)
            {
                WantedDestroyPanel(oPC);
                return;
            }
            if(sElement == WNT_BTN_BRIBE)
            {
                WantedBribe(oPC);
                return;
            }
            if(sElement == WNT_BTN_SURRENDER)
            {
                WantedSurrender(oPC);
                return;
            }
        }

        return;
    }
}

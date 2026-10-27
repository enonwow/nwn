// lib_wyrd_ev.nss — Wyrd System NUI event handler.
// Set as the module's OnNUIEvent script, or dispatch to this from an existing
// OnNUIEvent handler:
//   #include "lib_wyrd_ev"
//   void main() { WyrdHandleNuiEvent(); /* ... other modules ... */ }
#include "lib_wyrd"

void WyrdHandleNuiEvent()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    // Only handle events for the Wyrd window
    if(nToken != NuiFindWindow(oPC, WYRD_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
        return;  // cleanup handled by GC; no lvars to clear for the window

    if(sEvent != EVENT_TYPE_CLICK) return;

    // Close button
    if(sElem == WYRD_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    // Tab: Laski
    if(sElem == WYRD_BTN_TAB_BOONS)
    {
        WyrdSwapView(oPC, nToken, 0);
        return;
    }

    // Tab: Kronika
    if(sElem == WYRD_BTN_TAB_LEDGER)
    {
        WyrdSwapView(oPC, nToken, 1);
        return;
    }

    // Buy boon buttons: WYRD_BTN_BUY + "1".."6"
    string sBuyPrefix = WYRD_BTN_BUY;
    int    nPrefixLen = GetStringLength(sBuyPrefix);
    if(GetStringLeft(sElem, nPrefixLen) == sBuyPrefix)
    {
        int nId = StringToInt(GetStringRight(sElem,
                              GetStringLength(sElem) - nPrefixLen));
        if(nId >= 1 && nId <= WYRD_BOON_COUNT)
            WyrdBuyBoon(oPC, nId);
        return;
    }
}

void main()
{
    WyrdHandleNuiEvent();
}

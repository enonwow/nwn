#include "lib_div"

// Main NUI event handler — set as nUI event script in DivShowWindow.
void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(nToken != NuiFindWindow(oPC, DIV_WINDOW)) return;

    // ---- Window closed by chrome X ----
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        // If reading was in progress and not accepted, refund is not given
        // but we clean up session state.
        DeleteLocalJson(oPC, DIV_LVAR_CARDS);
        DeleteLocalInt(oPC, DIV_LVAR_REVEALED);
        DeleteLocalInt(oPC, DIV_LVAR_CARDCNT);
        DeleteLocalInt(oPC, DIV_LVAR_LASTCARD);
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK) return;

    // ---- Close button ----
    if(sElem == DIV_BTN_CLOSE)
    {
        DeleteLocalJson(oPC, DIV_LVAR_CARDS);
        DeleteLocalInt(oPC, DIV_LVAR_REVEALED);
        DeleteLocalInt(oPC, DIV_LVAR_CARDCNT);
        DeleteLocalInt(oPC, DIV_LVAR_LASTCARD);
        NuiDestroy(oPC, nToken);
        return;
    }

    // ---- Main view: small reading ----
    if(sElem == DIV_BTN_SMALL)
    {
        DivStartReading(oPC, nToken, DIV_SMALL_CARDS);
        return;
    }

    // ---- Main view: grand reading ----
    if(sElem == DIV_BTN_GRAND)
    {
        DivStartReading(oPC, nToken, DIV_GRAND_CARDS);
        return;
    }

    // ---- Reading view: card slot clicked ----
    int bCardPrefix = (GetStringLeft(sElem, GetStringLength(DIV_BTN_CARD))
                       == DIV_BTN_CARD);
    if(bCardPrefix)
    {
        int nSlot = StringToInt(GetStringRight(sElem,
            GetStringLength(sElem) - GetStringLength(DIV_BTN_CARD)));
        DivRevealCard(oPC, nToken, nSlot);
        return;
    }

    // ---- Reading view: accept fate ----
    if(sElem == DIV_BTN_ACCEPT)
    {
        DivAcceptFate(oPC, nToken);
        return;
    }

    // ---- Reading view: cancel / back ----
    if(sElem == DIV_BTN_BACK)
    {
        DivCancelReading(oPC, nToken);
        return;
    }
}

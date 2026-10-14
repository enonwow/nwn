// lib_anc_ev.nss — Ancestor Spirits: NUI event handler

#include "lib_anc"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, ANC_WINDOW)) return;

    // ---- Window closed via OS chrome (alt+F4, etc.) ----
    if(sEvent == EVENT_TYPE_CLOSE)
        return;

    if(sEvent != EVENT_TYPE_CLICK && sEvent != EVENT_TYPE_MOUSEDOWN) return;

    // ---- Close button ----
    if(sElem == ANC_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    // ---- Lineage selection row click ----
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == ANC_BTN_LIN_ROW)
    {
        AncHandleSelectLineage(oPC, nToken, nIdx);
        return;
    }

    // ---- Offer button ----
    if(sElem == ANC_BTN_OFFER)
    {
        AncHandleOffer(oPC, nToken);
        return;
    }

    // ---- Invoke buttons (slot 0 / 1 / 2) ----
    int nSlot;
    for(nSlot = 0; nSlot < 3; nSlot++)
    {
        if(sElem == ANC_BTN_INVOKE + IntToString(nSlot))
        {
            AncHandleInvoke(oPC, nToken, nSlot);
            return;
        }
    }
}

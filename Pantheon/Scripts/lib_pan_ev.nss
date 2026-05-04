#include "lib_pan"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    int nMain  = NuiFindWindow(oPC, PAN_WINDOW);
    int nDeity = NuiFindWindow(oPC, PAN_WIN_DEITY);
    int nOffer = NuiFindWindow(oPC, PAN_WIN_OFFER);

    // ---- Deity selector ----
    if(nToken == nDeity && nDeity != 0)
    {
        if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == PAN_BTN_DEITY_ROW)
        {
            if(nIdx >= 0 && nIdx < PAN_DEITY_COUNT)
            {
                PanSelectDeity(oPC, nIdx);
            }
        }
        return;
    }

    // ---- Offer popup ----
    if(nToken == nOffer && nOffer != 0)
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == PAN_BTN_OFFER_OK)
            {
                json jVal = NuiGetBind(oPC, nToken, PAN_BIND_OFFER_AMT);
                int nGold = StringToInt(JsonGetString(jVal));
                PanProcessOffer(oPC, nGold);
                return;
            }
            if(sElem == PAN_BTN_OFFER_NO)
            {
                NuiDestroy(oPC, nToken);
                return;
            }
        }
        return;
    }

    // ---- Main window ----
    if(nToken != nMain || nMain == 0) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, PAN_LVAR_PENDING_TARGET);
        PanClearState(oPC);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == PAN_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }
        if(sElem == PAN_BTN_PRAY)
        {
            PanPray(oPC);
            return;
        }
        if(sElem == PAN_BTN_OFFER)
        {
            PanShowOfferWindow(oPC);
            return;
        }
        if(sElem == PAN_BTN_MIRACLE)
        {
            if(nIdx < 0 || nIdx >= PAN_MIRACLE_COUNT) return;
            if(PanMiracleNeedsTarget(nIdx))
            {
                PanStartMiracleTargeting(oPC, nIdx);
            }
            else
            {
                PanTryCastMiracle(oPC, nIdx, OBJECT_INVALID);
            }
            return;
        }
    }
}

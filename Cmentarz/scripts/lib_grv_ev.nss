#include "lib_grv"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    // ----------------------------------------------------------------
    // Grave interaction window
    // ----------------------------------------------------------------

    if(nToken == NuiFindWindow(oPC, GRV_WIN_GRAVE))
    {
        if(sEvent == EVENT_TYPE_CLOSE)
        {
            DeleteLocalInt(oPC, GRV_LVAR_GRAVE_ID);
            return;
        }

        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == GRV_BTN_GRAVE_CLOSE)
            {
                NuiDestroy(oPC, nToken);
                return;
            }
            if(sElem == GRV_BTN_PRAY)
            {
                int nId = GetLocalInt(oPC, GRV_LVAR_GRAVE_ID);
                GrvHandlePray(oPC, nToken, nId);
                return;
            }
            if(sElem == GRV_BTN_DESECRATE)
            {
                int nId = GetLocalInt(oPC, GRV_LVAR_GRAVE_ID);
                GrvHandleDesecrate(oPC, nToken, nId);
                return;
            }
        }
        return;
    }

    // ----------------------------------------------------------------
    // Shop window
    // ----------------------------------------------------------------

    if(nToken == NuiFindWindow(oPC, GRV_WIN_SHOP))
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == GRV_BTN_SHOP_CLOSE)
            {
                NuiDestroy(oPC, nToken);
                return;
            }
            if(sElem == GRV_BTN_BUY && nIdx >= 0 && nIdx < GRV_SHOP_COUNT)
            {
                GrvHandleBuy(oPC, nToken, nIdx);
                return;
            }
        }
        return;
    }

    // ----------------------------------------------------------------
    // Burial window
    // ----------------------------------------------------------------

    if(nToken != NuiFindWindow(oPC, GRV_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, GRV_LVAR_TYPE);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == GRV_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }
        if(sElem == GRV_BTN_TYPE0)
        {
            GrvHandleTypeSelect(oPC, nToken, GRV_TYPE_MOUND);
            return;
        }
        if(sElem == GRV_BTN_TYPE1)
        {
            GrvHandleTypeSelect(oPC, nToken, GRV_TYPE_STONE);
            return;
        }
        if(sElem == GRV_BTN_TYPE2)
        {
            GrvHandleTypeSelect(oPC, nToken, GRV_TYPE_CRYPT);
            return;
        }
        if(sElem == GRV_BTN_BURY)
        {
            GrvHandleBury(oPC, nToken);
            return;
        }
        if(sElem == GRV_BTN_OPEN_SHOP)
        {
            GrvCreateShopWindow(oPC);
            return;
        }
    }

    if(sEvent == EVENT_TYPE_WATCH && sElem == GRV_BIND_GOLD_TXT)
    {
        string sVal = JsonGetString(NuiGetBind(oPC, nToken, GRV_BIND_GOLD_TXT));
        int nVal    = StringToInt(sVal);
        if(sVal != "" && sVal != "0" && nVal <= 0)
            NuiSetBind(oPC, nToken, GRV_BIND_STATUS_LBL,
                JsonString("Ofiara musi być liczbą całkowitą dodatnią."));
        else
            NuiSetBind(oPC, nToken, GRV_BIND_STATUS_LBL, JsonString(""));
        return;
    }
}

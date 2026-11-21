#include "lib_bmt"

// ----------------------------------------------------------------
// Main NUI event handler — set as EventScript on BMT_WINDOW
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, BMT_WINDOW)) return;

    // ---- Window closed by OS chrome ----
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        BmtCleanupPC(oPC);
        return;
    }

    // ---- Row click (mousedown so row highlight fires immediately) ----
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == BMT_BTN_ROW)
    {
        if(GetLocalInt(oPC, BMT_LVAR_MODE) != 0) return;

        json jStock = BmtGetStock();
        if(nIdx < 0 || nIdx >= JsonGetLength(jStock)) return;

        json jRow  = JsonArrayGet(jStock, nIdx);
        int  nId   = JsonGetInt   (JsonObjectGet(jRow, "id"));
        string sNm = JsonGetString(JsonObjectGet(jRow, "item_name"));
        int  nGold = JsonGetInt   (JsonObjectGet(jRow, "base_gold"));

        SetLocalInt   (oPC, BMT_LVAR_SEL_STOCK, nId);
        SetLocalString(oPC, BMT_LVAR_SEL_NAME,  sNm);
        SetLocalInt   (oPC, BMT_LVAR_SEL_PRICE, nGold);

        BmtFeedBuyTab(oPC, nToken);
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK) return;

    // ---- Close button ----
    if(sElem == BMT_BTN_CLOSE)
    {
        BmtCleanupPC(oPC);
        NuiDestroy(oPC, nToken);
        return;
    }

    // ---- Tab: switch to Buy ----
    if(sElem == BMT_BTN_TAB_BUY)
    {
        if(GetLocalInt(oPC, BMT_LVAR_MODE) == 0) return;
        SetLocalInt(oPC, BMT_LVAR_MODE, 0);
        NuiSetGroupLayout(oPC, nToken, BMT_GRP_SWAP, BmtBuildBuyView(oPC));
        BmtFeedBuyTab(oPC, nToken);
        return;
    }

    // ---- Tab: switch to Sell ----
    if(sElem == BMT_BTN_TAB_SELL)
    {
        if(GetLocalInt(oPC, BMT_LVAR_MODE) == 1) return;
        SetLocalInt(oPC, BMT_LVAR_MODE, 1);
        NuiSetGroupLayout(oPC, nToken, BMT_GRP_SWAP, BmtBuildSellView(oPC));
        BmtFeedSellTab(oPC, nToken);
        return;
    }

    // ---- Buy: execute purchase of selected item ----
    if(sElem == BMT_BTN_BUY)
    {
        BmtHandleBuy(oPC, nToken);
        return;
    }

    // ---- Sell: pick item from inventory (enters targeting mode) ----
    if(sElem == BMT_BTN_PICK_ITEM)
    {
        // Clear any previously serialized item so the old offer stays visible
        // but is invalidated — user must pick again if they changed their mind.
        string sOldSerial = GetLocalString(oPC, BMT_LVAR_SELL_SERIAL);
        if(sOldSerial != "")
        {
            // Restore the previously taken item before picking a new one
            JsonToObject(JsonParse(sOldSerial), GetLocation(oPC), oPC, TRUE);
            DeleteLocalString(oPC, BMT_LVAR_SELL_SERIAL);
            DeleteLocalString(oPC, BMT_LVAR_SELL_NAME);
            DeleteLocalInt   (oPC, BMT_LVAR_SELL_PRICE);
        }
        EnterTargetingMode(oPC, OBJECT_TYPE_ITEM);
        SendMessageToPC(oPC,
            "[Targowisko] Kliknij przedmiot w ekwipunku, który chcesz sprzedać.");
        return;
    }

    // ---- Sell: confirm and exchange ----
    if(sElem == BMT_BTN_SELL_CONFIRM)
    {
        BmtHandleSell(oPC, nToken);
        return;
    }
}

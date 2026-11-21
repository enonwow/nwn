#include "lib_bmt_def"

// ----------------------------------------------------------------
// Heat display helpers
// ----------------------------------------------------------------

json BmtHeatColor(int nHeat)
{
    if(nHeat < 30)           return NuiColor( 80, 200,  80);
    if(nHeat < 60)           return NuiColor(220, 200,  60);
    if(nHeat < BMT_HEAT_WARN) return NuiColor(230, 140,  40);
    return                          NuiColor(220,  60,  60);
}

string BmtHeatLabel(int nHeat)
{
    if(nHeat == 0)            return "Poszukiwany: Nikt cie nie szuka";
    if(nHeat < 30)            return "Poszukiwany: Wzbudzasz ciekawosc (" + IntToString(nHeat) + ")";
    if(nHeat < 60)            return "Poszukiwany: Kilka par oczu sledzi (" + IntToString(nHeat) + ")";
    if(nHeat < BMT_HEAT_WARN) return "Poszukiwany: Listy goncze kraza (" + IntToString(nHeat) + ")";
    return                           "!! WYJATKOWO GORACY !! (" + IntToString(nHeat) + ")";
}

string BmtRefreshLabel()
{
    int nSecs = BmtGetSecondsToRefresh();
    if(nSecs <= 0) return "Towar wlasnie sie odnawia...";
    int nH = nSecs / 3600;
    int nM = (nSecs % 3600) / 60;
    return "Oferta zmienia sie za: " + IntToString(nH) + "h " + IntToString(nM) + "m";
}

// ----------------------------------------------------------------
// Guard consequence
// ----------------------------------------------------------------

// Called with a delay after area entry when heat is high.
// Sets a WANTED flag and applies a visual paranoia cue.
// Dependent systems (guard AI, NPC dialogue) can read BMT_WANTED.
void BmtCheckGuards(object oPC)
{
    string sUuid = GetObjectUUID(oPC);
    int nHeat    = BmtGetHeat(sUuid);
    if(nHeat < BMT_HEAT_WARN) return;

    // Probability scales linearly: 0% at threshold, 25% at max.
    int nChance = (nHeat - BMT_HEAT_WARN) * 25 / (BMT_HEAT_MAX - BMT_HEAT_WARN);
    if(d100() > nChance) return;

    SetLocalInt(oPC, "BMT_WANTED", 1);
    SendMessageToPC(oPC, "[Targowisko] Czujesz na sobie ciezki wzrok straznikow...");
    FloatingTextStringOnCreature("Poszukiwany!", oPC, FALSE);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_DOOM), oPC);
}

// ----------------------------------------------------------------
// NUI Layout — Buy tab
// ----------------------------------------------------------------

json BmtBuildBuyView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fFlvH  = GetNuiScaleDimension(oPC, 75.0);
    float fListH = GetNuiScaleDimension(oPC, 210.0);

    // Tab bar
    json jTabBuy = NuiButton(JsonString("[ Kup ]"));
    jTabBuy = NuiId(jTabBuy, BMT_BTN_TAB_BUY);
    jTabBuy = NuiWidth(jTabBuy, GetNuiScaleDimension(oPC, 110.0));
    jTabBuy = NuiHeight(jTabBuy, fBtnH);
    jTabBuy = NuiEncouraged(jTabBuy, JsonBool(TRUE));

    json jTabSell = NuiButton(JsonString("Sprzedaj"));
    jTabSell = NuiId(jTabSell, BMT_BTN_TAB_SELL);
    jTabSell = NuiWidth(jTabSell, GetNuiScaleDimension(oPC, 110.0));
    jTabSell = NuiHeight(jTabSell, fBtnH);

    json jHeatLbl = NuiLabel(NuiBind(BMT_BIND_HEAT_LBL),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jHeatLbl = NuiStyleForegroundColor(jHeatLbl, NuiBind(BMT_BIND_HEAT_COLOR));

    json jTabRow = JsonArray();
    jTabRow = JsonArrayInsert(jTabRow, jTabBuy);
    jTabRow = JsonArrayInsert(jTabRow, jTabSell);
    jTabRow = JsonArrayInsert(jTabRow, NuiSpacer());
    jTabRow = JsonArrayInsert(jTabRow, jHeatLbl);

    // Refresh info
    json jRefreshLbl = NuiLabel(NuiBind(BMT_BIND_REFRESH_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRefreshLbl = NuiHeight(jRefreshLbl, GetNuiScaleDimension(oPC, 20.0));

    // Item list — columns: name (elastic) | price (80) | qty (50)
    float fPriceW = GetNuiScaleDimension(oPC, 80.0);
    float fQtyW   = GetNuiScaleDimension(oPC, 50.0);

    json jNameLbl  = NuiLabel(NuiBind(BMT_BIND_ROW_NAME),
        JsonInt(NUI_HALIGN_LEFT),   JsonInt(NUI_VALIGN_MIDDLE));
    json jPriceLbl = NuiLabel(NuiBind(BMT_BIND_ROW_PRICE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jPriceLbl = NuiWidth(jPriceLbl, fPriceW);
    json jQtyLbl   = NuiLabel(NuiBind(BMT_BIND_ROW_QTY),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jQtyLbl = NuiWidth(jQtyLbl, fQtyW);

    json jCellCols = JsonArray();
    jCellCols = JsonArrayInsert(jCellCols, jNameLbl);
    jCellCols = JsonArrayInsert(jCellCols, jPriceLbl);
    jCellCols = JsonArrayInsert(jCellCols, jQtyLbl);

    json jCell = NuiGroup(NuiRow(jCellCols), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, BMT_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(BMT_BIND_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(BMT_BIND_ROWCNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // Flavor text
    json jFlavor = NuiGroup(NuiText(NuiBind(BMT_BIND_FLAVOR), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jFlavor = NuiHeight(jFlavor, fFlvH);

    // Buy button
    json jBuyBtn = NuiButton(NuiBind(BMT_BIND_BUY_LBL));
    jBuyBtn = NuiId(jBuyBtn, BMT_BTN_BUY);
    jBuyBtn = NuiEnabled(jBuyBtn, NuiBind(BMT_BIND_BUY_ENA));
    jBuyBtn = NuiWidth(jBuyBtn, GetNuiScaleDimension(oPC, 240.0));
    jBuyBtn = NuiHeight(jBuyBtn, fBtnH);

    json jBuyRow = JsonArray();
    jBuyRow = JsonArrayInsert(jBuyRow, NuiSpacer());
    jBuyRow = JsonArrayInsert(jBuyRow, jBuyBtn);
    jBuyRow = JsonArrayInsert(jBuyRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTabRow));
    jCol = JsonArrayInsert(jCol, jRefreshLbl);
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, jFlavor);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBuyRow));

    return NuiCol(jCol);
}

// ----------------------------------------------------------------
// NUI Layout — Sell tab
// ----------------------------------------------------------------

json BmtBuildSellView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fInstrH= GetNuiScaleDimension(oPC, 90.0);
    float fOfferH= GetNuiScaleDimension(oPC, 120.0);

    // Tab bar
    json jTabBuy = NuiButton(JsonString("Kup"));
    jTabBuy = NuiId(jTabBuy, BMT_BTN_TAB_BUY);
    jTabBuy = NuiWidth(jTabBuy, GetNuiScaleDimension(oPC, 110.0));
    jTabBuy = NuiHeight(jTabBuy, fBtnH);

    json jTabSell = NuiButton(JsonString("[ Sprzedaj ]"));
    jTabSell = NuiId(jTabSell, BMT_BTN_TAB_SELL);
    jTabSell = NuiWidth(jTabSell, GetNuiScaleDimension(oPC, 110.0));
    jTabSell = NuiHeight(jTabSell, fBtnH);
    jTabSell = NuiEncouraged(jTabSell, JsonBool(TRUE));

    json jHeatLbl = NuiLabel(NuiBind(BMT_BIND_HEAT_LBL),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jHeatLbl = NuiStyleForegroundColor(jHeatLbl, NuiBind(BMT_BIND_HEAT_COLOR));

    json jTabRow = JsonArray();
    jTabRow = JsonArrayInsert(jTabRow, jTabBuy);
    jTabRow = JsonArrayInsert(jTabRow, jTabSell);
    jTabRow = JsonArrayInsert(jTabRow, NuiSpacer());
    jTabRow = JsonArrayInsert(jTabRow, jHeatLbl);

    // Instructions
    string sInstr =
        "Passur skupuje towar bez zbednych pytan.\n"
        "Zaplaci " + IntToString(BMT_FENCE_RATE) + "% wartosci — reszte pochlopnie 'prowizja'.\n\n"
        "Wybierz przedmiot z ekwipunku klikajac przycisk ponizej.";
    json jInstrTxt = NuiGroup(NuiText(JsonString(sInstr), FALSE),
        FALSE, NUI_SCROLLBARS_NONE);
    jInstrTxt = NuiHeight(jInstrTxt, fInstrH);

    // Pick button
    json jPickBtn = NuiButton(JsonString("Wybierz przedmiot z ekwipunku"));
    jPickBtn = NuiId(jPickBtn, BMT_BTN_PICK_ITEM);
    jPickBtn = NuiHeight(jPickBtn, fBtnH);

    // Offer display
    json jOfferTxt = NuiGroup(NuiText(NuiBind(BMT_BIND_OFFER_LBL), FALSE),
        FALSE, NUI_SCROLLBARS_NONE);
    jOfferTxt = NuiHeight(jOfferTxt, fOfferH);

    // Sell confirm button
    json jSellBtn = NuiButton(JsonString("Sprzedaj Passurowi"));
    jSellBtn = NuiId(jSellBtn, BMT_BTN_SELL_CONFIRM);
    jSellBtn = NuiEnabled(jSellBtn, NuiBind(BMT_BIND_SELL_ENA));
    jSellBtn = NuiWidth(jSellBtn, GetNuiScaleDimension(oPC, 220.0));
    jSellBtn = NuiHeight(jSellBtn, fBtnH);

    json jSellRow = JsonArray();
    jSellRow = JsonArrayInsert(jSellRow, NuiSpacer());
    jSellRow = JsonArrayInsert(jSellRow, jSellBtn);
    jSellRow = JsonArrayInsert(jSellRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTabRow));
    jCol = JsonArrayInsert(jCol, jInstrTxt);
    jCol = JsonArrayInsert(jCol, jPickBtn);
    jCol = JsonArrayInsert(jCol, jOfferTxt);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jSellRow));

    return NuiCol(jCol);
}

// ----------------------------------------------------------------
// Window create / reopen
// ----------------------------------------------------------------

void BmtShowWindow(object oPC)
{
    BmtRefreshStock();

    int nExisting = NuiFindWindow(oPC, BMT_WINDOW);
    if(nExisting != 0)
    {
        NuiSetGroupLayout(oPC, nExisting, BMT_GRP_SWAP, BmtBuildBuyView(oPC));
        SetLocalInt(oPC, BMT_LVAR_MODE, 0);
        BmtFeedBuyTab(oPC, nExisting);
        return;
    }

    float fW  = GetNuiScaleDimension(oPC, BMT_W);
    float fH  = GetNuiScaleDimension(oPC, BMT_H);
    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;
    json jGeom = NuiRect(fCX, fCY, fW, fH);

    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, BMT_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);
    json jTopBarRow = JsonArray();
    jTopBarRow = JsonArrayInsert(jTopBarRow, NuiSpacer());
    jTopBarRow = JsonArrayInsert(jTopBarRow, jCloseBtn);

    json jSwapGrp = NuiGroup(BmtBuildBuyView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, BMT_GRP_SWAP);

    json jRootChildren = JsonArray();
    jRootChildren = JsonArrayInsert(jRootChildren, NuiRow(jTopBarRow));
    jRootChildren = JsonArrayInsert(jRootChildren, jSwapGrp);
    json jRoot = NuiCol(jRootChildren);

    json jWin = NuiWindow(jRoot,
        JsonString("Czarne Targowisko"),
        NuiBind(BMT_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, BMT_WINDOW, BMT_EV_SCRIPT);
    NuiSetBind(oPC, nToken, BMT_WIN_GEOM, jGeom);

    SetLocalInt(oPC, BMT_LVAR_MODE, 0);
    BmtFeedBuyTab(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed — Buy tab
// ----------------------------------------------------------------

void BmtFeedBuyTab(object oPC, int nToken)
{
    json jStock = BmtGetStock();
    int  nCount = JsonGetLength(jStock);
    int  nSelId = GetLocalInt(oPC, BMT_LVAR_SEL_STOCK);

    json jNames  = JsonArray();
    json jPrices = JsonArray();
    json jQtys   = JsonArray();
    json jEncs   = JsonArray();
    string sFlavor = "";

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow  = JsonArrayGet(jStock, i);
        int  nId   = JsonGetInt   (JsonObjectGet(jRow, "id"));
        string sNm = JsonGetString(JsonObjectGet(jRow, "item_name"));
        int  nGold = JsonGetInt   (JsonObjectGet(jRow, "base_gold"));
        int  nQty  = JsonGetInt   (JsonObjectGet(jRow, "qty"));

        jNames  = JsonArrayInsert(jNames,  JsonString(sNm));
        jPrices = JsonArrayInsert(jPrices, JsonString(IntToString(nGold) + " sz."));
        jQtys   = JsonArrayInsert(jQtys,   JsonString("x" + IntToString(nQty)));
        jEncs   = JsonArrayInsert(jEncs,   JsonBool(nSelId > 0 && nId == nSelId));

        if(nSelId > 0 && nId == nSelId)
            sFlavor = JsonGetString(JsonObjectGet(jRow, "flavor"));
    }

    NuiSetBind(oPC, nToken, BMT_BIND_ROW_NAME,    jNames);
    NuiSetBind(oPC, nToken, BMT_BIND_ROW_PRICE,   jPrices);
    NuiSetBind(oPC, nToken, BMT_BIND_ROW_QTY,     jQtys);
    NuiSetBind(oPC, nToken, BMT_BIND_ROW_ENC,     jEncs);
    NuiSetBind(oPC, nToken, BMT_BIND_ROWCNT,      JsonInt(nCount));
    NuiSetBind(oPC, nToken, BMT_BIND_REFRESH_LBL, JsonString(BmtRefreshLabel()));
    NuiSetBind(oPC, nToken, BMT_BIND_FLAVOR,       JsonString(sFlavor));

    string sBuyLbl = nSelId > 0
        ? "Kup — " + GetLocalString(oPC, BMT_LVAR_SEL_NAME)
            + " (" + IntToString(GetLocalInt(oPC, BMT_LVAR_SEL_PRICE)) + " sz.)"
        : "Wybierz towar";
    NuiSetBind(oPC, nToken, BMT_BIND_BUY_LBL, JsonString(sBuyLbl));
    NuiSetBind(oPC, nToken, BMT_BIND_BUY_ENA, JsonBool(nSelId > 0));

    int nHeat = BmtGetHeat(GetObjectUUID(oPC));
    NuiSetBind(oPC, nToken, BMT_BIND_HEAT_LBL,   JsonString(BmtHeatLabel(nHeat)));
    NuiSetBind(oPC, nToken, BMT_BIND_HEAT_COLOR,  BmtHeatColor(nHeat));
}

// ----------------------------------------------------------------
// Feed — Sell tab
// ----------------------------------------------------------------

void BmtFeedSellTab(object oPC, int nToken)
{
    string sSellName = GetLocalString(oPC, BMT_LVAR_SELL_NAME);
    int    nOffer    = GetLocalInt   (oPC, BMT_LVAR_SELL_PRICE);
    int    bHasOffer = (sSellName != "");

    string sOfferTxt;
    if(bHasOffer)
        sOfferTxt =
            "Passur zważył w dłoni " + sSellName + " i wydał wyrok:\n\n"
            "„" + IntToString(nOffer) + " monet. Nie targujemy sie."\n\n"
            "Polowa trafi w zapomniane kieszenie — to koszt milczenia.";
    else
        sOfferTxt =
            "Zadnego towaru jeszcze nie wyceniono.\n\n"
            "Wcisnij przycisk powyzej i wsknaz przedmiot z ekwipunku.";

    NuiSetBind(oPC, nToken, BMT_BIND_OFFER_LBL, JsonString(sOfferTxt));
    NuiSetBind(oPC, nToken, BMT_BIND_SELL_ENA,  JsonBool(bHasOffer));

    int nHeat = BmtGetHeat(GetObjectUUID(oPC));
    NuiSetBind(oPC, nToken, BMT_BIND_HEAT_LBL,   JsonString(BmtHeatLabel(nHeat)));
    NuiSetBind(oPC, nToken, BMT_BIND_HEAT_COLOR,  BmtHeatColor(nHeat));
}

// ----------------------------------------------------------------
// Action: Buy
// ----------------------------------------------------------------

void BmtHandleBuy(object oPC, int nToken)
{
    int nStockId = GetLocalInt(oPC, BMT_LVAR_SEL_STOCK);
    if(nStockId <= 0) return;

    json jItem = BmtGetStockItem(nStockId);
    if(JsonGetType(jItem) == JSON_TYPE_NULL || JsonGetInt(JsonObjectGet(jItem, "qty")) <= 0)
    {
        SendMessageToPC(oPC, "[Targowisko] Towar właśnie się wyczerpał.");
        DeleteLocalInt(oPC, BMT_LVAR_SEL_STOCK);
        DeleteLocalString(oPC, BMT_LVAR_SEL_NAME);
        DeleteLocalInt(oPC, BMT_LVAR_SEL_PRICE);
        BmtFeedBuyTab(oPC, nToken);
        return;
    }

    int    nCost = JsonGetInt   (JsonObjectGet(jItem, "base_gold"));
    string sRes  = JsonGetString(JsonObjectGet(jItem, "resref"));
    string sNm   = JsonGetString(JsonObjectGet(jItem, "item_name"));

    if(GetGold(oPC) < nCost)
    {
        SendMessageToPC(oPC, "[Targowisko] „Nie masz dość monet, przyjacielu."");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(nCost, oPC, TRUE));

    object oItem = CreateItemOnObject(sRes, oPC);
    if(!GetIsObjectValid(oItem))
    {
        // Resref missing — refund; this is a builder configuration error
        GiveGoldToCreature(oPC, nCost);
        SendMessageToPC(oPC,
            "[Targowisko] Predmiot niedostepny — skontaktuj sie z zarzadca modulu.");
        return;
    }

    BmtDeductStock(nStockId);
    BmtAddHeat(GetObjectUUID(oPC), BMT_HEAT_PER_BUY);

    SendMessageToPC(oPC,
        "[Targowisko] Kupiles " + sNm + " za " + IntToString(nCost) + " sz.");
    FloatingTextStringOnCreature("Transakcja zawarta.", oPC, FALSE);

    DeleteLocalInt(oPC, BMT_LVAR_SEL_STOCK);
    DeleteLocalString(oPC, BMT_LVAR_SEL_NAME);
    DeleteLocalInt(oPC, BMT_LVAR_SEL_PRICE);
    BmtFeedBuyTab(oPC, nToken);
}

// ----------------------------------------------------------------
// Action: Sell (confirm after item was already taken and serialized)
// ----------------------------------------------------------------

void BmtHandleSell(object oPC, int nToken)
{
    string sSellName = GetLocalString(oPC, BMT_LVAR_SELL_NAME);
    int    nOffer    = GetLocalInt   (oPC, BMT_LVAR_SELL_PRICE);
    if(sSellName == "" || nOffer <= 0) return;

    GiveGoldToCreature(oPC, nOffer);
    BmtAddHeat(GetObjectUUID(oPC), BMT_HEAT_PER_SELL);

    SendMessageToPC(oPC,
        "[Targowisko] Passur przyjal " + sSellName
        + " i odliczyl " + IntToString(nOffer) + " sz.");
    FloatingTextStringOnCreature("Gotowka. Bez pokwitowania.", oPC, FALSE);

    DeleteLocalString(oPC, BMT_LVAR_SELL_NAME);
    DeleteLocalInt   (oPC, BMT_LVAR_SELL_PRICE);
    DeleteLocalString(oPC, BMT_LVAR_SELL_SERIAL);

    BmtFeedSellTab(oPC, nToken);
}

// ----------------------------------------------------------------
// Action: Handle player targeting (called from sys_on_target)
// ----------------------------------------------------------------

void BmtHandleTarget(object oPC)
{
    int nToken = NuiFindWindow(oPC, BMT_WINDOW);
    if(nToken == 0) return;
    if(GetLocalInt(oPC, BMT_LVAR_MODE) != 1) return;

    object oItem = GetTargetingModeSelectedObject();
    if(!GetIsObjectValid(oItem) || GetItemPossessor(oItem) != oPC)
    {
        SendMessageToPC(oPC,
            "[Targowisko] Możesz sprzedać tylko przedmiot ze swojego ekwipunku.");
        return;
    }

    int nBaseValue = GetGoldPieceValue(oItem);
    int nOffer     = (nBaseValue * BMT_FENCE_RATE) / 100;
    if(nOffer <= 0) nOffer = 1;

    string sName  = GetName(oItem);
    json   jSerial = ObjectToJson(oItem, TRUE);

    SetLocalString(oPC, BMT_LVAR_SELL_NAME,   sName);
    SetLocalInt   (oPC, BMT_LVAR_SELL_PRICE,  nOffer);
    SetLocalString(oPC, BMT_LVAR_SELL_SERIAL, JsonDump(jSerial));

    DestroyObject(oItem);

    BmtFeedSellTab(oPC, nToken);
}

// ----------------------------------------------------------------
// Cleanup: restore pending sell item, clear all LVARs
// ----------------------------------------------------------------

void BmtCleanupPC(object oPC)
{
    string sSerial = GetLocalString(oPC, BMT_LVAR_SELL_SERIAL);
    if(sSerial != "")
        JsonToObject(JsonParse(sSerial), GetLocation(oPC), oPC, TRUE);

    DeleteLocalString(oPC, BMT_LVAR_SELL_NAME);
    DeleteLocalInt   (oPC, BMT_LVAR_SELL_PRICE);
    DeleteLocalString(oPC, BMT_LVAR_SELL_SERIAL);
    DeleteLocalInt   (oPC, BMT_LVAR_SEL_STOCK);
    DeleteLocalString(oPC, BMT_LVAR_SEL_NAME);
    DeleteLocalInt   (oPC, BMT_LVAR_SEL_PRICE);
    DeleteLocalInt   (oPC, BMT_LVAR_MODE);
}

#include "lib_grv_def"

// ----------------------------------------------------------------
// Burial window layout
// ----------------------------------------------------------------

json GrvBuildBurialContent(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fTypeBtnW = GetNuiScaleDimension(oPC, 140.0);
    float fLblH  = GetNuiScaleDimension(oPC, 22.0);

    // Deceased name input
    json jDecLabel = NuiLabel(JsonString("Imię zmarłego:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDecLabel = NuiWidth(jDecLabel, GetNuiScaleDimension(oPC, 110.0));
    jDecLabel = NuiHeight(jDecLabel, fBtnH);

    json jDecField = NuiTextEdit(JsonString("Nieznany..."), NuiBind(GRV_BIND_DECEASED), 60, FALSE);
    jDecField = NuiHeight(jDecField, fBtnH);

    json jDecRow = JsonArray();
    jDecRow = JsonArrayInsert(jDecRow, jDecLabel);
    jDecRow = JsonArrayInsert(jDecRow, jDecField);

    // Type selection buttons (encouraged = selected)
    json jType0 = NuiButton(JsonString("Usypana Mogiła"));
    jType0 = NuiId(jType0, GRV_BTN_TYPE0);
    jType0 = NuiEncouraged(jType0, NuiBind(GRV_BIND_TYPE0_ENC));
    jType0 = NuiWidth(jType0, fTypeBtnW);
    jType0 = NuiHeight(jType0, fBtnH);

    json jType1 = NuiButton(JsonString("Kamienny Nagrobek"));
    jType1 = NuiId(jType1, GRV_BTN_TYPE1);
    jType1 = NuiEncouraged(jType1, NuiBind(GRV_BIND_TYPE1_ENC));
    jType1 = NuiWidth(jType1, fTypeBtnW);
    jType1 = NuiHeight(jType1, fBtnH);

    json jType2 = NuiButton(JsonString("Krypta Szlachecka"));
    jType2 = NuiId(jType2, GRV_BTN_TYPE2);
    jType2 = NuiEncouraged(jType2, NuiBind(GRV_BIND_TYPE2_ENC));
    jType2 = NuiWidth(jType2, fTypeBtnW);
    jType2 = NuiHeight(jType2, fBtnH);

    json jTypeRow = JsonArray();
    jTypeRow = JsonArrayInsert(jTypeRow, jType0);
    jTypeRow = JsonArrayInsert(jTypeRow, NuiSpacer());
    jTypeRow = JsonArrayInsert(jTypeRow, jType1);
    jTypeRow = JsonArrayInsert(jTypeRow, NuiSpacer());
    jTypeRow = JsonArrayInsert(jTypeRow, jType2);

    // Materials & grace reward
    json jMatLbl = NuiLabel(NuiBind(GRV_BIND_MAT_DESC),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jMatLbl = NuiHeight(jMatLbl, fLblH);

    json jGraceLbl = NuiLabel(NuiBind(GRV_BIND_GRACE_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jGraceLbl = NuiHeight(jGraceLbl, fLblH);
    jGraceLbl = NuiStyleForegroundColor(jGraceLbl, NuiColor(180, 230, 180));

    // Offering gold
    json jGoldLabel = NuiLabel(JsonString("Złoto ofiarne:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jGoldLabel = NuiWidth(jGoldLabel, GetNuiScaleDimension(oPC, 110.0));
    jGoldLabel = NuiHeight(jGoldLabel, fBtnH);

    json jGoldField = NuiTextEdit(JsonString("0"), NuiBind(GRV_BIND_GOLD_TXT), 7, FALSE);
    jGoldField = NuiWidth(jGoldField, GetNuiScaleDimension(oPC, 100.0));
    jGoldField = NuiHeight(jGoldField, fBtnH);

    json jGoldHint = NuiLabel(JsonString("(szansa na ducha pogrzebanego)"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jGoldRow = JsonArray();
    jGoldRow = JsonArrayInsert(jGoldRow, jGoldLabel);
    jGoldRow = JsonArrayInsert(jGoldRow, jGoldField);
    jGoldRow = JsonArrayInsert(jGoldRow, jGoldHint);

    // Piętno / marks status
    json jMarksLbl = NuiLabel(NuiBind(GRV_BIND_MARKS_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jMarksLbl = NuiHeight(jMarksLbl, fLblH);
    jMarksLbl = NuiStyleForegroundColor(jMarksLbl, NuiColor(220, 100, 80));

    // Status feedback
    json jStatusLbl = NuiLabel(NuiBind(GRV_BIND_STATUS_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiHeight(jStatusLbl, fLblH);
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiColor(200, 200, 120));

    // Bottom bar: Shop + Bury
    json jShopBtn = NuiButton(JsonString("Sklep Grabarza"));
    jShopBtn = NuiId(jShopBtn, GRV_BTN_OPEN_SHOP);
    jShopBtn = NuiWidth(jShopBtn, GetNuiScaleDimension(oPC, 130.0));
    jShopBtn = NuiHeight(jShopBtn, fBtnH);

    json jBuryBtn = NuiButton(JsonString("Pochowaj"));
    jBuryBtn = NuiId(jBuryBtn, GRV_BTN_BURY);
    jBuryBtn = NuiEnabled(jBuryBtn, NuiBind(GRV_BIND_BURY_ENA));
    jBuryBtn = NuiWidth(jBuryBtn, GetNuiScaleDimension(oPC, 110.0));
    jBuryBtn = NuiHeight(jBuryBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jShopBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jBuryBtn);

    // Assemble column
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jDecRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jTypeRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, jMatLbl);
    jCol = JsonArrayInsert(jCol, jGraceLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jGoldRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, jMarksLbl);
    jCol = JsonArrayInsert(jCol, jStatusLbl);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    float fContentW = GetNuiScaleDimension(oPC, GRV_WIN_W - 40.0);
    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Shop window layout
// ----------------------------------------------------------------

json GrvBuildShopContent(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fRowH  = GetNuiScaleDimension(oPC, 50.0);
    float fLblH  = GetNuiScaleDimension(oPC, 18.0);

    // Grace balance header
    json jGraceHdr = NuiLabel(NuiBind(GRV_BIND_SHOP_GRACE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jGraceHdr = NuiHeight(jGraceHdr, fBtnH);
    jGraceHdr = NuiStyleForegroundColor(jGraceHdr, NuiColor(180, 230, 180));

    // Item list: name, cost, description, buy button as a NuiList
    json jNameLbl = NuiLabel(NuiBind(GRV_BIND_SHOP_ROWNAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jDescLbl = NuiLabel(NuiBind(GRV_BIND_SHOP_ROWDESC),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDescLbl = NuiStyleForegroundColor(jDescLbl, NuiColor(170, 170, 170));

    json jTextCol = JsonArray();
    jTextCol = JsonArrayInsert(jTextCol, jNameLbl);
    jTextCol = JsonArrayInsert(jTextCol, jDescLbl);

    json jCostLbl = NuiLabel(NuiBind(GRV_BIND_SHOP_ROWCOST),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jCostLbl = NuiWidth(jCostLbl, GetNuiScaleDimension(oPC, 50.0));
    jCostLbl = NuiStyleForegroundColor(jCostLbl, NuiColor(180, 230, 180));

    json jBuyBtn = NuiButton(JsonString("Kup"));
    jBuyBtn = NuiId(jBuyBtn, GRV_BTN_BUY);
    jBuyBtn = NuiEnabled(jBuyBtn, NuiBind(GRV_BIND_SHOP_ROWENA));
    jBuyBtn = NuiEncouraged(jBuyBtn, NuiBind(GRV_BIND_SHOP_ROWENC));
    jBuyBtn = NuiWidth(jBuyBtn, GetNuiScaleDimension(oPC, 60.0));
    jBuyBtn = NuiHeight(jBuyBtn, fBtnH);

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, NuiCol(jTextCol));
    jCellRow = JsonArrayInsert(jCellRow, jCostLbl);
    jCellRow = JsonArrayInsert(jCellRow, jBuyBtn);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(GRV_BIND_SHOP_COUNT), fRowH);
    jList = NuiHeight(jList, GetNuiScaleDimension(oPC, GRV_SHOP_H - 120.0));

    json jCloseBtn = NuiButton(JsonString("Zamknij"));
    jCloseBtn = NuiId(jCloseBtn, GRV_BTN_SHOP_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 90.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jCloseBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jGraceHdr);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    float fContentW = GetNuiScaleDimension(oPC, GRV_SHOP_W - 40.0);
    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Grave interaction window layout
// ----------------------------------------------------------------

json GrvBuildGraveContent(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fLblH = GetNuiScaleDimension(oPC, 22.0);

    json jTitle = NuiLabel(NuiBind(GRV_BIND_GRAVE_TITLE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);
    jTitle = NuiStyleForegroundColor(jTitle, NuiColor(220, 200, 150));

    json jInfo = NuiGroup(
        NuiText(NuiBind(GRV_BIND_GRAVE_INFO), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jInfo = NuiHeight(jInfo, GetNuiScaleDimension(oPC, 120.0));

    json jPrayBtn = NuiButton(NuiBind(GRV_BIND_PRAY_LBL));
    jPrayBtn = NuiId(jPrayBtn, GRV_BTN_PRAY);
    jPrayBtn = NuiEnabled(jPrayBtn, NuiBind(GRV_BIND_PRAY_ENA));
    jPrayBtn = NuiWidth(jPrayBtn, GetNuiScaleDimension(oPC, 160.0));
    jPrayBtn = NuiHeight(jPrayBtn, fBtnH);

    json jDesecBtn = NuiButton(JsonString("Zbezcześć"));
    jDesecBtn = NuiId(jDesecBtn, GRV_BTN_DESECRATE);
    jDesecBtn = NuiEnabled(jDesecBtn, NuiBind(GRV_BIND_GRAVE_DESEC));
    jDesecBtn = NuiWidth(jDesecBtn, GetNuiScaleDimension(oPC, 120.0));
    jDesecBtn = NuiHeight(jDesecBtn, fBtnH);

    json jCloseBtn = NuiButton(JsonString("Zamknij"));
    jCloseBtn = NuiId(jCloseBtn, GRV_BTN_GRAVE_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 90.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jActRow = JsonArray();
    jActRow = JsonArrayInsert(jActRow, jPrayBtn);
    jActRow = JsonArrayInsert(jActRow, NuiSpacer());
    jActRow = JsonArrayInsert(jActRow, jDesecBtn);
    jActRow = JsonArrayInsert(jActRow, NuiSpacer());
    jActRow = JsonArrayInsert(jActRow, jCloseBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jTitle);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, jInfo);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jActRow));

    float fContentW = GetNuiScaleDimension(oPC, GRV_GRAVE_W - 40.0);
    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Window create / open
// ----------------------------------------------------------------

void GrvCreateBurialWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, GRV_WINDOW);
    if(nToken != 0)
    {
        GrvFeedBurialWindow(oPC, nToken);
        return;
    }

    float fW = GetNuiScaleDimension(oPC, GRV_WIN_W);
    float fH = GetNuiScaleDimension(oPC, GRV_WIN_H);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, GRV_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jCloseBtn);

    json jSwapGrp = NuiGroup(GrvBuildBurialContent(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, GRV_GRP_SWAP);

    json jRoot = NuiCol(JsonArrayInsert(
        JsonArrayInsert(JsonArray(), NuiRow(jTopRow)),
        jSwapGrp));

    json jWin = NuiWindow(jRoot,
        JsonString("Cmentarz — Obrzęd Pochówku"),
        NuiBind(GRV_BIND_WIN_GEOM),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE), JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, GRV_WINDOW, GRV_EV_SCRIPT);
    NuiSetBind(oPC, nToken, GRV_BIND_WIN_GEOM, NuiRect(fX, fY, fW, fH));
    NuiSetBind(oPC, nToken, GRV_BIND_GOLD_TXT, JsonString("0"));
    NuiSetBindWatch(oPC, nToken, GRV_BIND_GOLD_TXT, TRUE);

    SetLocalInt(oPC, GRV_LVAR_TYPE, GRV_TYPE_MOUND);
    GrvFeedBurialWindow(oPC, nToken);
}

void GrvCreateShopWindow(object oPC)
{
    if(NuiFindWindow(oPC, GRV_WIN_SHOP) != 0)
    {
        GrvFeedShopWindow(oPC, NuiFindWindow(oPC, GRV_WIN_SHOP));
        return;
    }

    float fW = GetNuiScaleDimension(oPC, GRV_SHOP_W);
    float fH = GetNuiScaleDimension(oPC, GRV_SHOP_H);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    json jWin = NuiWindow(GrvBuildShopContent(oPC),
        JsonString("Sklep Grabarza — Błogosławieństwa"),
        NuiBind(GRV_BIND_SHOP_GEOM),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, GRV_WIN_SHOP, GRV_EV_SCRIPT);
    NuiSetBind(oPC, nToken, GRV_BIND_SHOP_GEOM, NuiRect(fX, fY, fW, fH));
    GrvFeedShopWindow(oPC, nToken);
}

void GrvCreateGraveWindow(object oPC, int nGraveId)
{
    if(NuiFindWindow(oPC, GRV_WIN_GRAVE) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, GRV_WIN_GRAVE));

    float fW = GetNuiScaleDimension(oPC, GRV_GRAVE_W);
    float fH = GetNuiScaleDimension(oPC, GRV_GRAVE_H);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    json jWin = NuiWindow(GrvBuildGraveContent(oPC),
        JsonString("Grób"),
        NuiBind(GRV_BIND_GRAVE_GEOM),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    SetLocalInt(oPC, GRV_LVAR_GRAVE_ID, nGraveId);
    int nToken = NuiCreate(oPC, jWin, GRV_WIN_GRAVE, GRV_EV_SCRIPT);
    NuiSetBind(oPC, nToken, GRV_BIND_GRAVE_GEOM, NuiRect(fX, fY, fW, fH));
    GrvFeedGraveWindow(oPC, nToken, nGraveId);
}

// ----------------------------------------------------------------
// Feed functions
// ----------------------------------------------------------------

void GrvFeedBurialWindow(object oPC, int nToken)
{
    int nType  = GetLocalInt(oPC, GRV_LVAR_TYPE);
    int nMarks = GrvGetDesecMarks(oPC);
    int nGrace = GrvGetBoneGrace(oPC);

    NuiSetBind(oPC, nToken, GRV_BIND_TYPE0_ENC, JsonBool(nType == GRV_TYPE_MOUND));
    NuiSetBind(oPC, nToken, GRV_BIND_TYPE1_ENC, JsonBool(nType == GRV_TYPE_STONE));
    NuiSetBind(oPC, nToken, GRV_BIND_TYPE2_ENC, JsonBool(nType == GRV_TYPE_CRYPT));

    NuiSetBind(oPC, nToken, GRV_BIND_MAT_DESC,  JsonString(GrvGetGraveTypeMaterials(nType)));
    NuiSetBind(oPC, nToken, GRV_BIND_GRACE_LBL, JsonString(
        "Nagroda: +" + IntToString(GrvGetGraveTypeGrace(nType)) + " Łaska Kości   (posiadasz: " + IntToString(nGrace) + ")"));

    string sMarksLbl = "";
    if(nMarks > 0)
    {
        sMarksLbl = "Piętno Zbezczeszczenia: " + IntToString(nMarks);
        if(nMarks >= GRV_DESEC_HEAVY_THRESHOLD)
            sMarksLbl = sMarksLbl + " — CIĘŻKA KLĄTWA";
        else if(nMarks >= GRV_DESEC_CURSE_THRESHOLD)
            sMarksLbl = sMarksLbl + " — przeklęty";
    }
    NuiSetBind(oPC, nToken, GRV_BIND_MARKS_LBL, JsonString(sMarksLbl));
    NuiSetBind(oPC, nToken, GRV_BIND_STATUS_LBL, JsonString(""));

    NuiSetBind(oPC, nToken, GRV_BIND_BURY_ENA, JsonBool(TRUE));
}

void GrvFeedShopWindow(object oPC, int nToken)
{
    int nGrace = GrvGetBoneGrace(oPC);
    NuiSetBind(oPC, nToken, GRV_BIND_SHOP_GRACE,
        JsonString("Twoja Łaska Kości: " + IntToString(nGrace)));

    json jNames = JsonArray();
    json jCosts = JsonArray();
    json jEnas  = JsonArray();
    json jEncs  = JsonArray();
    json jDescs = JsonArray();

    int i;
    for(i = 0; i < GRV_SHOP_COUNT; i++)
    {
        int nCost = GrvGetShopItemCost(i);
        int bCan  = (nGrace >= nCost);

        // Forgiveness: extra cooldown via pray_log with grave_id = 0
        if(i == 4)
        {
            if(GrvHasPrayed(oPC, 0)) bCan = FALSE;
            if(GrvGetDesecMarks(oPC) <= 0) bCan = FALSE;
        }

        jNames = JsonArrayInsert(jNames, JsonString(GrvGetShopItemName(i)));
        jCosts = JsonArrayInsert(jCosts, JsonString(IntToString(nCost) + " ŁK"));
        jEnas  = JsonArrayInsert(jEnas,  JsonBool(bCan));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(FALSE));
        jDescs = JsonArrayInsert(jDescs, JsonString(GrvGetShopItemDesc(i)));
    }

    NuiSetBind(oPC, nToken, GRV_BIND_SHOP_ROWNAME,  jNames);
    NuiSetBind(oPC, nToken, GRV_BIND_SHOP_ROWCOST,  jCosts);
    NuiSetBind(oPC, nToken, GRV_BIND_SHOP_ROWENA,   jEnas);
    NuiSetBind(oPC, nToken, GRV_BIND_SHOP_ROWENC,   jEncs);
    NuiSetBind(oPC, nToken, GRV_BIND_SHOP_ROWDESC,  jDescs);
    NuiSetBind(oPC, nToken, GRV_BIND_SHOP_COUNT,    JsonInt(GRV_SHOP_COUNT));
}

void GrvFeedGraveWindow(object oPC, int nToken, int nGraveId)
{
    json jGrave = GrvGetGrave(nGraveId);
    if(JsonGetType(jGrave) == JSON_TYPE_NULL)
    {
        NuiSetBind(oPC, nToken, GRV_BIND_GRAVE_TITLE, JsonString("Grób nie istnieje."));
        NuiSetBind(oPC, nToken, GRV_BIND_GRAVE_INFO,  JsonString(""));
        NuiSetBind(oPC, nToken, GRV_BIND_GRAVE_DESEC, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, GRV_BIND_PRAY_ENA,    JsonBool(FALSE));
        NuiSetBind(oPC, nToken, GRV_BIND_PRAY_LBL,    JsonString("Módl się"));
        return;
    }

    string sDeceased = JsonGetString(JsonObjectGet(jGrave, "deceased_name"));
    string sOwner    = JsonGetString(JsonObjectGet(jGrave, "owner_name"));
    int    nType     = JsonGetInt   (JsonObjectGet(jGrave, "grave_type"));
    int    nGold     = JsonGetInt   (JsonObjectGet(jGrave, "gold_buried"));
    int    nAt       = JsonGetInt   (JsonObjectGet(jGrave, "created_at"));
    int    bDesec    = JsonGetInt   (JsonObjectGet(jGrave, "is_desecrated"));

    string sTitle = GrvGetGraveTypeName(nType) + ": " + sDeceased;

    string sInfo = "Typ: " + GrvGetGraveTypeName(nType) + "\n";
    sInfo = sInfo + "Pogrzebany przez: " + sOwner + "\n";
    sInfo = sInfo + "Data: " + GrvFormatDate(nAt) + "\n";
    if(nGold > 0)
        sInfo = sInfo + "Złoto złożone: " + IntToString(nGold) + " monet\n";
    if(bDesec)
        sInfo = sInfo + "\n[Grób zbezczeszczony — kości nie dają spokoju...]";

    int bHasPrayed = GrvHasPrayed(oPC, nGraveId);
    string sPrayLbl = bHasPrayed ? "Módliłeś się tu (odczekaj dobę)" : "Módl się (+2 do rzutów obronnych, 8h)";

    NuiSetBind(oPC, nToken, GRV_BIND_GRAVE_TITLE, JsonString(sTitle));
    NuiSetBind(oPC, nToken, GRV_BIND_GRAVE_INFO,  JsonString(sInfo));
    NuiSetBind(oPC, nToken, GRV_BIND_GRAVE_DESEC, JsonBool(!bDesec));
    NuiSetBind(oPC, nToken, GRV_BIND_PRAY_ENA,    JsonBool(!bHasPrayed));
    NuiSetBind(oPC, nToken, GRV_BIND_PRAY_LBL,    JsonString(sPrayLbl));
}

// ----------------------------------------------------------------
// Action handlers
// ----------------------------------------------------------------

void GrvHandleBury(object oPC, int nToken)
{
    int    nType    = GetLocalInt(oPC, GRV_LVAR_TYPE);
    int    nGoldCost = GrvGetGraveTypeGoldCost(nType);
    string sGoldStr = JsonGetString(NuiGetBind(oPC, nToken, GRV_BIND_GOLD_TXT));
    int    nOffering = StringToInt(sGoldStr);
    int    nTotal    = nGoldCost + (nOffering > 0 ? nOffering : 0);

    if(nOffering < 0)
    {
        NuiSetBind(oPC, nToken, GRV_BIND_STATUS_LBL, JsonString("Ofiara nie może być ujemna."));
        return;
    }

    if(GetGold(oPC) < nTotal)
    {
        NuiSetBind(oPC, nToken, GRV_BIND_STATUS_LBL,
            JsonString("Nie masz wystarczająco złota (" + IntToString(nTotal) + " wymagane)."));
        return;
    }

    string sDeceased = JsonGetString(NuiGetBind(oPC, nToken, GRV_BIND_DECEASED));
    if(sDeceased == "" || sDeceased == "Nieznany...")
        sDeceased = "Nieznany";

    if(nTotal > 0)
        AssignCommand(oPC, TakeGoldFromCreature(nTotal, oPC, TRUE));

    string sArea = GetResRef(GetArea(oPC));
    int nGraveId = GrvInsertGrave(oPC, sDeceased, nType, nOffering, sArea);

    int nGrace = GrvGetGraveTypeGrace(nType);
    GrvAddBoneGrace(oPC, nGrace);

    string sMsg = "Pochowałeś " + sDeceased + " jako " + GrvGetGraveTypeName(nType) + ".";
    sMsg = sMsg + " Łaska Kości: +" + IntToString(nGrace) + ".";
    SendMessageToPC(oPC, "[Cmentarz] " + sMsg);
    NuiSetBind(oPC, nToken, GRV_BIND_STATUS_LBL, JsonString(sMsg));

    PlaySound("as_pl_coinsdrop1");
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_HEAD_HOLY), oPC);

    GrvTrySpawnGhost(oPC, sDeceased, nOffering);
    GrvFeedBurialWindow(oPC, nToken);
}

void GrvHandleTypeSelect(object oPC, int nToken, int nType)
{
    SetLocalInt(oPC, GRV_LVAR_TYPE, nType);
    GrvFeedBurialWindow(oPC, nToken);
}

void GrvHandleBuy(object oPC, int nShopToken, int nIdx)
{
    int nCost = GrvGetShopItemCost(nIdx);
    if(!GrvSpendBoneGrace(oPC, nCost))
    {
        SendMessageToPC(oPC, "[Cmentarz] Zbyt mało Łaski Kości.");
        return;
    }

    GrvApplyShopEffect(oPC, nIdx);
    GrvFeedShopWindow(oPC, nShopToken);

    int nBurToken = NuiFindWindow(oPC, GRV_WINDOW);
    if(nBurToken != 0)
        GrvFeedBurialWindow(oPC, nBurToken);
}

void GrvHandlePray(object oPC, int nToken, int nGraveId)
{
    if(GrvHasPrayed(oPC, nGraveId))
    {
        SendMessageToPC(oPC, "[Cmentarz] Już modliłeś się przy tym grobie. Wróć jutro.");
        return;
    }

    GrvLogPrayer(oPC, nGraveId);
    GrvApplyPrayerBuff(oPC);

    SendMessageToPC(oPC, "[Cmentarz] Modlitwa zostaje wysłuchana. +2 do wszystkich rzutów obronnych przez 8 godzin.");
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_HEAD_HOLY), oPC);
    GrvFeedGraveWindow(oPC, nToken, nGraveId);
}

void GrvHandleDesecrate(object oPC, int nToken, int nGraveId)
{
    json jGrave = GrvGetGrave(nGraveId);
    if(JsonGetType(jGrave) == JSON_TYPE_NULL) return;
    if(JsonGetInt(JsonObjectGet(jGrave, "is_desecrated"))) return;

    int nType     = JsonGetInt(JsonObjectGet(jGrave, "grave_type"));
    int nBuried   = JsonGetInt(JsonObjectGet(jGrave, "gold_buried"));

    int nLoot = 0;
    switch(nType)
    {
        case GRV_TYPE_MOUND: nLoot = Random(31);                         break;
        case GRV_TYPE_STONE: nLoot = 30 + Random(71);                   break;
        case GRV_TYPE_CRYPT: nLoot = 100 + Random(301) + (nBuried / 2); break;
    }

    GrvMarkDesecrated(nGraveId);
    GrvAddDesecMark(oPC);

    if(nLoot > 0)
        GiveGoldToCreature(oPC, nLoot);

    int nMarks = GrvGetDesecMarks(oPC);

    string sMsg = "Zbezcześciłeś grób i znalazłeś " + IntToString(nLoot) + " sztuk złota.";
    sMsg = sMsg + " Piętno Zbezczeszczenia: " + IntToString(nMarks) + ".";
    SendMessageToPC(oPC, "[Cmentarz] " + sMsg);

    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_HEAD_EVIL), oPC);
    GrvApplyCursePenalties(oPC, nMarks);
    GrvFeedGraveWindow(oPC, nToken, nGraveId);
}

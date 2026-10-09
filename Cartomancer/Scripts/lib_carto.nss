#include "lib_carto_def"

// ----------------------------------------------------------------
// NUI — list view layout
// ----------------------------------------------------------------

json BuildCartoListView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fRowH  = GetNuiScaleDimension(oPC, 28.0);
    float fListH = GetNuiScaleDimension(oPC, 340.0);
    float fHdrH  = GetNuiScaleDimension(oPC, 22.0);

    float fNameW   = GetNuiScaleDimension(oPC, 260.0);
    float fDangerW = GetNuiScaleDimension(oPC, 90.0);
    float fResW    = GetNuiScaleDimension(oPC, 70.0);
    float fGoldW   = GetNuiScaleDimension(oPC, 70.0);

    // -- Top action row --
    json jTitleLbl = NuiLabel(JsonString("Dziennik Kartografa"),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jNewBtn = NuiButton(JsonString("Nowa mapa"));
    jNewBtn = NuiId(jNewBtn, CARTO_BTN_NEWMAP);
    jNewBtn = NuiWidth(jNewBtn, GetNuiScaleDimension(oPC, 95.0));
    jNewBtn = NuiHeight(jNewBtn, fBtnH);
    jNewBtn = NuiTooltip(jNewBtn,
                JsonString("Szkicuje mape aktualnego obszaru."));

    json jSellAllBtn = NuiButton(JsonString("Sprzedaj wszystkie"));
    jSellAllBtn = NuiId(jSellAllBtn, CARTO_BTN_SELLALL);
    jSellAllBtn = NuiWidth(jSellAllBtn, GetNuiScaleDimension(oPC, 140.0));
    jSellAllBtn = NuiHeight(jSellAllBtn, fBtnH);
    jSellAllBtn = NuiTooltip(jSellAllBtn,
                    JsonString("Sprzedaje wszystkie niesprzedane mapy Faktorowi."));

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitleLbl);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jNewBtn);
    jTopRow = JsonArrayInsert(jTopRow, jSellAllBtn);

    // -- Column headers --
    json jHdrName = NuiLabel(JsonString("Obszar"),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrName   = NuiWidth(jHdrName, fNameW);
    jHdrName   = NuiHeight(jHdrName, fHdrH);
    jHdrName   = NuiStyleForegroundColor(jHdrName, NuiColor(185, 150, 100, 220));

    json jHdrDanger = NuiLabel(JsonString("Zagrozenie"),
                               JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrDanger = NuiWidth(jHdrDanger, fDangerW);
    jHdrDanger = NuiHeight(jHdrDanger, fHdrH);
    jHdrDanger = NuiStyleForegroundColor(jHdrDanger, NuiColor(185, 150, 100, 220));

    json jHdrRes = NuiLabel(JsonString("Zasoby"),
                            JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrRes    = NuiWidth(jHdrRes, fResW);
    jHdrRes    = NuiHeight(jHdrRes, fHdrH);
    jHdrRes    = NuiStyleForegroundColor(jHdrRes, NuiColor(185, 150, 100, 220));

    json jHdrGold = NuiLabel(JsonString("Wartosc"),
                             JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrGold   = NuiWidth(jHdrGold, fGoldW);
    jHdrGold   = NuiHeight(jHdrGold, fHdrH);
    jHdrGold   = NuiStyleForegroundColor(jHdrGold, NuiColor(185, 150, 100, 220));

    json jHdrRow = JsonArray();
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrName);
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrDanger);
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrRes);
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrGold);

    // -- List template row --
    json jNameLbl = NuiLabel(NuiBind(CARTO_BIND_ROW_NAME),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(CARTO_BIND_ROW_COLOR));

    json jDangerLbl = NuiLabel(NuiBind(CARTO_BIND_ROW_DANGER),
                               JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDangerLbl = NuiWidth(jDangerLbl, fDangerW);
    jDangerLbl = NuiStyleForegroundColor(jDangerLbl, NuiBind(CARTO_BIND_ROW_COLOR));

    json jResLbl = NuiLabel(NuiBind(CARTO_BIND_ROW_RES),
                            JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jResLbl = NuiWidth(jResLbl, fResW);
    jResLbl = NuiStyleForegroundColor(jResLbl, NuiBind(CARTO_BIND_ROW_COLOR));

    json jGoldLbl2 = NuiLabel(JsonString(""),
                              JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jGoldLbl2 = NuiWidth(jGoldLbl2, fGoldW);

    // Row cell acting as a clickable button via NuiGroup + NuiId
    json jCellChildren = JsonArray();
    jCellChildren = JsonArrayInsert(jCellChildren, jNameLbl);
    jCellChildren = JsonArrayInsert(jCellChildren, jDangerLbl);
    jCellChildren = JsonArrayInsert(jCellChildren, jResLbl);

    json jCell = NuiGroup(NuiRow(jCellChildren), FALSE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, CARTO_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(CARTO_BIND_ROW_ENC));

    json jTmpl = JsonArray();
    jTmpl = JsonArrayInsert(jTmpl, NuiListTemplateCell(jCell, 0.0, TRUE));

    json jList = NuiList(jTmpl, NuiBind(CARTO_BIND_ROW_CNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // -- Status bar --
    json jStatusLbl = NuiLabel(NuiBind(CARTO_BIND_STATUS),
                               JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiHeight(jStatusLbl, GetNuiScaleDimension(oPC, 20.0));
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiColor(160, 200, 160, 220));

    // -- Assemble --
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTopRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jHdrRow));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, jStatusLbl);

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 640.0);
    json jMain = JsonArray();
    jMain = JsonArrayInsert(jMain, jSide);
    jMain = JsonArrayInsert(jMain, NuiWidth(NuiCol(jCol), fContentW));
    jMain = JsonArrayInsert(jMain, jSide);
    return NuiRow(jMain);
}

// ----------------------------------------------------------------
// NUI — edit view layout
// ----------------------------------------------------------------

json BuildCartoEditView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fNotesH= GetNuiScaleDimension(oPC, 140.0);
    float fLblW  = GetNuiScaleDimension(oPC, 90.0);
    float fChkW  = GetNuiScaleDimension(oPC, 90.0);
    float fDBtn  = GetNuiScaleDimension(oPC, 52.0);

    // -- Top row: back + area name --
    json jBackBtn = NuiButton(JsonString("< Wróc"));
    jBackBtn = NuiId(jBackBtn, CARTO_BTN_BACK);
    jBackBtn = NuiWidth(jBackBtn, GetNuiScaleDimension(oPC, 70.0));
    jBackBtn = NuiHeight(jBackBtn, fBtnH);

    json jAreaLbl = NuiLabel(NuiBind(CARTO_BIND_AREA_LBL),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jAreaLbl = NuiStyleForegroundColor(jAreaLbl, NuiColor(220, 190, 130, 255));

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jBackBtn);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jAreaLbl);

    // -- Danger row --
    json jDangerHdrLbl = NuiLabel(JsonString("Zagrozenie:"),
                                  JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDangerHdrLbl = NuiWidth(jDangerHdrLbl, fLblW);

    json jD1 = NuiButton(JsonString("I"));
    jD1 = NuiId(jD1, CARTO_BTN_D1);
    jD1 = NuiEncouraged(jD1, NuiBind(CARTO_BIND_D1_ENC));
    jD1 = NuiWidth(jD1, fDBtn); jD1 = NuiHeight(jD1, fBtnH);
    jD1 = NuiTooltip(jD1, JsonString("Banalne. Slabe potwory lub ich brak."));

    json jD2 = NuiButton(JsonString("II"));
    jD2 = NuiId(jD2, CARTO_BTN_D2);
    jD2 = NuiEncouraged(jD2, NuiBind(CARTO_BIND_D2_ENC));
    jD2 = NuiWidth(jD2, fDBtn); jD2 = NuiHeight(jD2, fBtnH);
    jD2 = NuiTooltip(jD2, JsonString("Umiarkowane. Warto byc ostroznym."));

    json jD3 = NuiButton(JsonString("III"));
    jD3 = NuiId(jD3, CARTO_BTN_D3);
    jD3 = NuiEncouraged(jD3, NuiBind(CARTO_BIND_D3_ENC));
    jD3 = NuiWidth(jD3, fDBtn); jD3 = NuiHeight(jD3, fBtnH);
    jD3 = NuiTooltip(jD3, JsonString("Powazne. Niebezpieczne stwory lub pulapki."));

    json jD4 = NuiButton(JsonString("IV"));
    jD4 = NuiId(jD4, CARTO_BTN_D4);
    jD4 = NuiEncouraged(jD4, NuiBind(CARTO_BIND_D4_ENC));
    jD4 = NuiWidth(jD4, fDBtn); jD4 = NuiHeight(jD4, fBtnH);
    jD4 = NuiTooltip(jD4, JsonString("Smiertlne. Elity lub wladcy lochów."));

    json jD5 = NuiButton(JsonString("V"));
    jD5 = NuiId(jD5, CARTO_BTN_D5);
    jD5 = NuiEncouraged(jD5, NuiBind(CARTO_BIND_D5_ENC));
    jD5 = NuiWidth(jD5, fDBtn); jD5 = NuiHeight(jD5, fBtnH);
    jD5 = NuiTooltip(jD5, JsonString("Legendarne. Powrot nie jest pewny."));

    json jDRow = JsonArray();
    jDRow = JsonArrayInsert(jDRow, jDangerHdrLbl);
    jDRow = JsonArrayInsert(jDRow, jD1);
    jDRow = JsonArrayInsert(jDRow, jD2);
    jDRow = JsonArrayInsert(jDRow, jD3);
    jDRow = JsonArrayInsert(jDRow, jD4);
    jDRow = JsonArrayInsert(jDRow, jD5);
    jDRow = JsonArrayInsert(jDRow, NuiSpacer());

    // -- Resources row --
    json jResHdrLbl = NuiLabel(JsonString("Zasoby:"),
                               JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jResHdrLbl = NuiWidth(jResHdrLbl, fLblW);

    json jChkHerbs  = NuiCheckbox(JsonString("Ziola"),   NuiBind(CARTO_BIND_CHK_HERBS));
    jChkHerbs  = NuiWidth(jChkHerbs,  fChkW);
    json jChkOre    = NuiCheckbox(JsonString("Ruda"),     NuiBind(CARTO_BIND_CHK_ORE));
    jChkOre    = NuiWidth(jChkOre,    fChkW);
    json jChkWater  = NuiCheckbox(JsonString("Woda"),     NuiBind(CARTO_BIND_CHK_WATER));
    jChkWater  = NuiWidth(jChkWater,  fChkW);
    json jChkRuins  = NuiCheckbox(JsonString("Ruiny"),    NuiBind(CARTO_BIND_CHK_RUINS));
    jChkRuins  = NuiWidth(jChkRuins,  fChkW);
    json jChkShrine = NuiCheckbox(JsonString("Kapliczka"),NuiBind(CARTO_BIND_CHK_SHRINE));
    jChkShrine = NuiWidth(jChkShrine, fChkW);

    json jResRow = JsonArray();
    jResRow = JsonArrayInsert(jResRow, jResHdrLbl);
    jResRow = JsonArrayInsert(jResRow, jChkHerbs);
    jResRow = JsonArrayInsert(jResRow, jChkOre);
    jResRow = JsonArrayInsert(jResRow, jChkWater);
    jResRow = JsonArrayInsert(jResRow, jChkRuins);
    jResRow = JsonArrayInsert(jResRow, jChkShrine);

    // -- Notes text area --
    json jNotesEdit = NuiTextEdit(
        JsonString("Odnotatuj napotkane zagrozenia, ukryte przejscia, skarby..."),
        NuiBind(CARTO_BIND_NOTES),
        CARTO_NOTES_MAX,
        TRUE);
    jNotesEdit = NuiHeight(jNotesEdit, fNotesH);

    // -- Gold preview row --
    json jGoldHdrLbl = NuiLabel(JsonString("Skupuje Faktor:"),
                                JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jGoldHdrLbl = NuiWidth(jGoldHdrLbl, GetNuiScaleDimension(oPC, 120.0));

    json jGoldValLbl = NuiLabel(NuiBind(CARTO_BIND_GOLD_LBL),
                                JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jGoldValLbl = NuiStyleForegroundColor(jGoldValLbl, NuiColor(200, 185, 80, 255));

    json jGoldRow = JsonArray();
    jGoldRow = JsonArrayInsert(jGoldRow, jGoldHdrLbl);
    jGoldRow = JsonArrayInsert(jGoldRow, jGoldValLbl);
    jGoldRow = JsonArrayInsert(jGoldRow, NuiSpacer());

    // -- Action buttons row --
    json jSaveBtn = NuiButton(JsonString("Zachowaj"));
    jSaveBtn = NuiId(jSaveBtn, CARTO_BTN_SAVE);
    jSaveBtn = NuiWidth(jSaveBtn, GetNuiScaleDimension(oPC, 90.0));
    jSaveBtn = NuiHeight(jSaveBtn, fBtnH);

    json jDelBtn = NuiButton(JsonString("Usun"));
    jDelBtn = NuiId(jDelBtn, CARTO_BTN_DEL);
    jDelBtn = NuiEnabled(jDelBtn, NuiBind(CARTO_BIND_DEL_ENA));
    jDelBtn = NuiWidth(jDelBtn, GetNuiScaleDimension(oPC, 70.0));
    jDelBtn = NuiHeight(jDelBtn, fBtnH);
    jDelBtn = NuiTooltip(jDelBtn, JsonString("Nieodwracalnie usuwa mape z dziennika."));

    json jSellBtn = NuiButton(JsonString("Sprzedaj"));
    jSellBtn = NuiId(jSellBtn, CARTO_BTN_SELL);
    jSellBtn = NuiEnabled(jSellBtn, NuiBind(CARTO_BIND_SELL_ENA));
    jSellBtn = NuiWidth(jSellBtn, GetNuiScaleDimension(oPC, 80.0));
    jSellBtn = NuiHeight(jSellBtn, fBtnH);
    jSellBtn = NuiTooltip(jSellBtn, JsonString("Sprzedaje mape Faktorowi Kartografów. Mapa zostaje oznaczona jako sprzedana."));

    json jXferBtn = NuiButton(JsonString("Przekaz"));
    jXferBtn = NuiId(jXferBtn, CARTO_BTN_XFER);
    jXferBtn = NuiEnabled(jXferBtn, NuiBind(CARTO_BIND_XFER_ENA));
    jXferBtn = NuiWidth(jXferBtn, GetNuiScaleDimension(oPC, 80.0));
    jXferBtn = NuiHeight(jXferBtn, fBtnH);
    jXferBtn = NuiTooltip(jXferBtn, JsonString("Kliknij gracza w poblizu, by przekazac mu kopie mapy."));

    json jActRow = JsonArray();
    jActRow = JsonArrayInsert(jActRow, jSaveBtn);
    jActRow = JsonArrayInsert(jActRow, jDelBtn);
    jActRow = JsonArrayInsert(jActRow, jSellBtn);
    jActRow = JsonArrayInsert(jActRow, NuiSpacer());
    jActRow = JsonArrayInsert(jActRow, jXferBtn);

    // -- Status bar --
    json jStatusLbl = NuiLabel(NuiBind(CARTO_BIND_STATUS),
                               JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiHeight(jStatusLbl, GetNuiScaleDimension(oPC, 20.0));
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiColor(160, 200, 160, 220));

    // -- Assemble --
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTopRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jDRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jResRow));
    jCol = JsonArrayInsert(jCol, jNotesEdit);
    jCol = JsonArrayInsert(jCol, NuiRow(jGoldRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jActRow));
    jCol = JsonArrayInsert(jCol, jStatusLbl);

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 640.0);
    json jMain = JsonArray();
    jMain = JsonArrayInsert(jMain, jSide);
    jMain = JsonArrayInsert(jMain, NuiWidth(NuiCol(jCol), fContentW));
    jMain = JsonArrayInsert(jMain, jSide);
    return NuiRow(jMain);
}

// ----------------------------------------------------------------
// Window open / close
// ----------------------------------------------------------------

void CartoOpen(object oPC)
{
    if(NuiFindWindow(oPC, CARTO_WIN) != 0)
    {
        NuiSetGroupLayout(oPC, NuiFindWindow(oPC, CARTO_WIN),
                          CARTO_GRP_SWAP, BuildCartoListView(oPC));
        CartoSwapToList(oPC, NuiFindWindow(oPC, CARTO_WIN));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, CARTO_WIN_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, CARTO_WIN_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
                         GetNuiScaleDimension(oPC, CARTO_WIN_W),
                         GetNuiScaleDimension(oPC, CARTO_WIN_H));

    float fBtnH = GetNuiScaleDimension(oPC, 30.0);

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, CARTO_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jHeaderRow = JsonArray();
    jHeaderRow = JsonArrayInsert(jHeaderRow, NuiSpacer());
    jHeaderRow = JsonArrayInsert(jHeaderRow, jCloseBtn);

    json jSwapGrp = NuiGroup(BuildCartoListView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, CARTO_GRP_SWAP);

    json jRootChildren = JsonArray();
    jRootChildren = JsonArrayInsert(jRootChildren, NuiRow(jHeaderRow));
    jRootChildren = JsonArrayInsert(jRootChildren, jSwapGrp);
    json jRoot = NuiCol(jRootChildren);

    json jWin = NuiWindow(jRoot,
        JsonBool(FALSE),
        NuiBind(CARTO_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, CARTO_WIN, CARTO_EV_SCRIPT);
    NuiSetBind(oPC, nToken, CARTO_WIN_GEOM, jGeom);

    CartoSwapToList(oPC, nToken);
}

// ----------------------------------------------------------------
// View switch helpers
// ----------------------------------------------------------------

void CartoSwapToList(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, CARTO_GRP_SWAP, BuildCartoListView(oPC));
    CartoFeedList(oPC, nToken);
}

void CartoSwapToEdit(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, CARTO_GRP_SWAP, BuildCartoEditView(oPC));
    CartoFeedEdit(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed list view
// ----------------------------------------------------------------

void CartoFeedList(object oPC, int nToken)
{
    json jMaps = CartoGetAllMaps(oPC);
    SetLocalJson(oPC, CARTO_LVAR_MAPS_CACHE, jMaps);

    int nCount = JsonGetLength(jMaps);

    json jNames   = JsonArray();
    json jDangers = JsonArray();
    json jRes     = JsonArray();
    json jColors  = JsonArray();
    json jEncs    = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow    = JsonArrayGet(jMaps, i);
        string sName = JsonGetString(JsonObjectGet(jRow, "area_name"));
        int nDanger  = JsonGetInt   (JsonObjectGet(jRow, "danger"));
        int nSold    = JsonGetInt   (JsonObjectGet(jRow, "is_sold"));
        int nHerbs   = JsonGetInt   (JsonObjectGet(jRow, "has_herbs"));
        int nOre     = JsonGetInt   (JsonObjectGet(jRow, "has_ore"));
        int nWater   = JsonGetInt   (JsonObjectGet(jRow, "has_water"));
        int nRuins   = JsonGetInt   (JsonObjectGet(jRow, "has_ruins"));
        int nShrine  = JsonGetInt   (JsonObjectGet(jRow, "has_shrine"));

        string sDangerStr = IntToString(nDanger) + " czaszk"
            + (nDanger == 1 ? "a" : (nDanger < 5 ? "i" : "ek"));
        string sRes = CartoResourceSummary(nHerbs, nOre, nWater, nRuins, nShrine);

        // Sold maps shown in muted grey
        json jColor = nSold
            ? NuiColor(110, 110, 110, 180)
            : NuiColor(220, 210, 180, 255);

        if(nSold) sName = "[sprzedana] " + sName;

        jNames   = JsonArrayInsert(jNames,   JsonString(sName));
        jDangers = JsonArrayInsert(jDangers, JsonString(sDangerStr));
        jRes     = JsonArrayInsert(jRes,     JsonString(sRes));
        jColors  = JsonArrayInsert(jColors,  jColor);
        jEncs    = JsonArrayInsert(jEncs,    JsonBool(FALSE));
    }

    NuiSetBind(oPC, nToken, CARTO_BIND_ROW_NAME,   jNames);
    NuiSetBind(oPC, nToken, CARTO_BIND_ROW_DANGER,  jDangers);
    NuiSetBind(oPC, nToken, CARTO_BIND_ROW_RES,     jRes);
    NuiSetBind(oPC, nToken, CARTO_BIND_ROW_COLOR,   jColors);
    NuiSetBind(oPC, nToken, CARTO_BIND_ROW_ENC,     jEncs);
    NuiSetBind(oPC, nToken, CARTO_BIND_ROW_CNT,     JsonInt(nCount));

    int nSellGold = CartoGetSellAllGold(oPC);
    string sStatus = nCount > 0
        ? (IntToString(nCount) + " map w dzienniku. "
           + (nSellGold > 0 ? "Mozliwy skup: " + IntToString(nSellGold) + " sz." : ""))
        : "Dziennik jest pusty. Kliknij 'Nowa mapa' bedac w ciekawym obszarze.";
    NuiSetBind(oPC, nToken, CARTO_BIND_STATUS, JsonString(sStatus));
}

// ----------------------------------------------------------------
// Feed edit view
// ----------------------------------------------------------------

void CartoFeedEdit(object oPC, int nToken)
{
    string sTag  = GetLocalString(oPC, CARTO_LVAR_EDIT_TAG);
    int    nDang = GetLocalInt   (oPC, CARTO_LVAR_DANGER);
    if(nDang < 1 || nDang > 5) nDang = 1;

    // Area label
    object oArea  = GetArea(oPC);
    string sAreaName = (sTag != "" && sTag == GetTag(oArea))
        ? GetName(oArea)
        : sTag;

    json jExisting = CartoGetMap(oPC, sTag);
    int bIsNew = (JsonGetType(jExisting) == JSON_TYPE_NULL);

    if(!bIsNew)
    {
        // Load saved values as initial state
        nDang = JsonGetInt(JsonObjectGet(jExisting, "danger"));
        SetLocalInt(oPC, CARTO_LVAR_DANGER, nDang);
        sAreaName = JsonGetString(JsonObjectGet(jExisting, "area_name"));

        NuiSetBind(oPC, nToken, CARTO_BIND_NOTES,
            JsonString(JsonGetString(JsonObjectGet(jExisting, "notes"))));
        NuiSetBind(oPC, nToken, CARTO_BIND_CHK_HERBS,
            JsonBool(JsonGetInt(JsonObjectGet(jExisting, "has_herbs"))));
        NuiSetBind(oPC, nToken, CARTO_BIND_CHK_ORE,
            JsonBool(JsonGetInt(JsonObjectGet(jExisting, "has_ore"))));
        NuiSetBind(oPC, nToken, CARTO_BIND_CHK_WATER,
            JsonBool(JsonGetInt(JsonObjectGet(jExisting, "has_water"))));
        NuiSetBind(oPC, nToken, CARTO_BIND_CHK_RUINS,
            JsonBool(JsonGetInt(JsonObjectGet(jExisting, "has_ruins"))));
        NuiSetBind(oPC, nToken, CARTO_BIND_CHK_SHRINE,
            JsonBool(JsonGetInt(JsonObjectGet(jExisting, "has_shrine"))));
    }
    else
    {
        NuiSetBind(oPC, nToken, CARTO_BIND_NOTES,      JsonString(""));
        NuiSetBind(oPC, nToken, CARTO_BIND_CHK_HERBS,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, CARTO_BIND_CHK_ORE,    JsonBool(FALSE));
        NuiSetBind(oPC, nToken, CARTO_BIND_CHK_WATER,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, CARTO_BIND_CHK_RUINS,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, CARTO_BIND_CHK_SHRINE, JsonBool(FALSE));
    }

    NuiSetBind(oPC, nToken, CARTO_BIND_AREA_LBL,
        JsonString(sAreaName));

    // Danger level encouragement
    NuiSetBind(oPC, nToken, CARTO_BIND_D1_ENC, JsonBool(nDang == 1));
    NuiSetBind(oPC, nToken, CARTO_BIND_D2_ENC, JsonBool(nDang == 2));
    NuiSetBind(oPC, nToken, CARTO_BIND_D3_ENC, JsonBool(nDang == 3));
    NuiSetBind(oPC, nToken, CARTO_BIND_D4_ENC, JsonBool(nDang == 4));
    NuiSetBind(oPC, nToken, CARTO_BIND_D5_ENC, JsonBool(nDang == 5));

    // Gold preview
    int nGold = CartoGoldForDanger(nDang);
    int nSold = bIsNew ? 0 : JsonGetInt(JsonObjectGet(jExisting, "is_sold"));
    string sGoldStr = nSold
        ? "(juz sprzedana)"
        : IntToString(nGold) + " sztuk zlota";
    NuiSetBind(oPC, nToken, CARTO_BIND_GOLD_LBL, JsonString(sGoldStr));

    // Button states
    NuiSetBind(oPC, nToken, CARTO_BIND_DEL_ENA,  JsonBool(!bIsNew));
    NuiSetBind(oPC, nToken, CARTO_BIND_SELL_ENA, JsonBool(!bIsNew && !nSold));
    NuiSetBind(oPC, nToken, CARTO_BIND_XFER_ENA, JsonBool(!bIsNew));

    NuiSetBind(oPC, nToken, CARTO_BIND_STATUS,
        JsonString(bIsNew
            ? "Nowa mapa — wypelnij i kliknij Zachowaj."
            : "Edytujesz zapisana mape. Zmiany obowiazuja po kliknieciu Zachowaj."));
}

// ----------------------------------------------------------------
// Update danger level encouragement on change
// ----------------------------------------------------------------

void CartoUpdateDangerDisplay(object oPC, int nToken, int nDang)
{
    SetLocalInt(oPC, CARTO_LVAR_DANGER, nDang);
    NuiSetBind(oPC, nToken, CARTO_BIND_D1_ENC, JsonBool(nDang == 1));
    NuiSetBind(oPC, nToken, CARTO_BIND_D2_ENC, JsonBool(nDang == 2));
    NuiSetBind(oPC, nToken, CARTO_BIND_D3_ENC, JsonBool(nDang == 3));
    NuiSetBind(oPC, nToken, CARTO_BIND_D4_ENC, JsonBool(nDang == 4));
    NuiSetBind(oPC, nToken, CARTO_BIND_D5_ENC, JsonBool(nDang == 5));

    string sTag  = GetLocalString(oPC, CARTO_LVAR_EDIT_TAG);
    json jExisting = CartoGetMap(oPC, sTag);
    int nSold = (JsonGetType(jExisting) != JSON_TYPE_NULL)
        ? JsonGetInt(JsonObjectGet(jExisting, "is_sold")) : 0;
    int nGold = CartoGoldForDanger(nDang);
    NuiSetBind(oPC, nToken, CARTO_BIND_GOLD_LBL,
        JsonString(nSold ? "(juz sprzedana)" : IntToString(nGold) + " sztuk zlota"));
}

// ----------------------------------------------------------------
// Handle: save current edit view to DB
// ----------------------------------------------------------------

void CartoHandleSave(object oPC, int nToken)
{
    string sTag = GetLocalString(oPC, CARTO_LVAR_EDIT_TAG);
    if(sTag == "") return;

    int nDang  = GetLocalInt(oPC, CARTO_LVAR_DANGER);
    if(nDang < 1 || nDang > 5) nDang = 1;

    string sNotes  = JsonGetString(NuiGetBind(oPC, nToken, CARTO_BIND_NOTES));
    int nHerbs     = JsonGetInt(NuiGetBind(oPC, nToken, CARTO_BIND_CHK_HERBS));
    int nOre       = JsonGetInt(NuiGetBind(oPC, nToken, CARTO_BIND_CHK_ORE));
    int nWater     = JsonGetInt(NuiGetBind(oPC, nToken, CARTO_BIND_CHK_WATER));
    int nRuins     = JsonGetInt(NuiGetBind(oPC, nToken, CARTO_BIND_CHK_RUINS));
    int nShrine    = JsonGetInt(NuiGetBind(oPC, nToken, CARTO_BIND_CHK_SHRINE));

    string sAreaName = JsonGetString(NuiGetBind(oPC, nToken, CARTO_BIND_AREA_LBL));
    if(sAreaName == "") sAreaName = sTag;

    CartoSaveMap(oPC, sTag, sAreaName, nDang, sNotes,
                 nHerbs, nOre, nWater, nRuins, nShrine);

    NuiSetBind(oPC, nToken, CARTO_BIND_STATUS,
        JsonString("Mapa '" + sAreaName + "' zostala zachowana w dzienniku."));
    NuiSetBind(oPC, nToken, CARTO_BIND_DEL_ENA,  JsonBool(TRUE));
    NuiSetBind(oPC, nToken, CARTO_BIND_SELL_ENA, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, CARTO_BIND_XFER_ENA, JsonBool(TRUE));

    // Refresh area bonus since the map now exists
    CartoApplyAreaBonus(oPC);
}

// ----------------------------------------------------------------
// Handle: sell single map
// ----------------------------------------------------------------

void CartoHandleSell(object oPC, int nToken)
{
    string sTag = GetLocalString(oPC, CARTO_LVAR_EDIT_TAG);
    if(sTag == "") return;

    json jMap = CartoGetMap(oPC, sTag);
    if(JsonGetType(jMap) == JSON_TYPE_NULL) return;
    if(JsonGetInt(JsonObjectGet(jMap, "is_sold"))) return;

    int nDang = JsonGetInt(JsonObjectGet(jMap, "danger"));
    int nGold = CartoGoldForDanger(nDang);

    CartoMarkSold(oPC, sTag);
    GiveGoldToCreature(oPC, nGold);

    NuiSetBind(oPC, nToken, CARTO_BIND_SELL_ENA, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, CARTO_BIND_GOLD_LBL, JsonString("(juz sprzedana)"));
    NuiSetBind(oPC, nToken, CARTO_BIND_STATUS,
        JsonString("Faktor zaplacil " + IntToString(nGold) + " sz. Pieciec na mapie wyscha — "
                   + "wiedza pozostaje w dzienniku."));

    FloatingTextStringOnCreature(
        "Faktor Kartografów: „Pergamin przyjety. " + IntToString(nGold) + " srebrznikow, jak ustalono."",
        oPC, FALSE);
}

// ----------------------------------------------------------------
// Handle: sell all unsold maps
// ----------------------------------------------------------------

void CartoHandleSellAll(object oPC, int nToken)
{
    int nGold = CartoGetSellAllGold(oPC);
    if(nGold <= 0)
    {
        NuiSetBind(oPC, nToken, CARTO_BIND_STATUS,
            JsonString("Nie ma niesprzedanych map do skupu."));
        return;
    }
    CartoSellAll(oPC);
    GiveGoldToCreature(oPC, nGold);
    CartoFeedList(oPC, nToken);
    FloatingTextStringOnCreature(
        "Faktor Kartografów: „Dokonano skupu wszystkich map. Razem: "
        + IntToString(nGold) + " sz."",
        oPC, FALSE);
}

// ----------------------------------------------------------------
// Handle: delete map
// ----------------------------------------------------------------

void CartoHandleDelete(object oPC, int nToken)
{
    string sTag = GetLocalString(oPC, CARTO_LVAR_EDIT_TAG);
    if(sTag == "") return;

    CartoDeleteMap(oPC, sTag);
    DeleteLocalString(oPC, CARTO_LVAR_EDIT_TAG);
    DeleteLocalInt   (oPC, CARTO_LVAR_DANGER);
    CartoRemoveAreaBonus(oPC);
    CartoApplyAreaBonus(oPC);   // re-check if we still have a map here
    CartoSwapToList(oPC, nToken);
    SendMessageToPC(oPC, "[Kartomancer] Mapa usunięta z dziennika.");
}

// ----------------------------------------------------------------
// Handle: transfer map to another player
// ----------------------------------------------------------------

void CartoHandleTransfer(object oPC, int nToken)
{
    string sTag = GetLocalString(oPC, CARTO_LVAR_EDIT_TAG);
    if(sTag == "") return;

    json jMap = CartoGetMap(oPC, sTag);
    if(JsonGetType(jMap) == JSON_TYPE_NULL) return;

    SetLocalInt   (oPC, CARTO_LVAR_TARGETING, 1);
    SetLocalString(oPC, CARTO_LVAR_XFER_TAG,  sTag);
    EnterTargetingMode(oPC, OBJECT_TYPE_CREATURE);
    NuiSetBind(oPC, nToken, CARTO_BIND_STATUS,
        JsonString("Kliknij postac gracza w poblizu, aby przekazac kopie mapy."));
}

void CartoOnPlayerTarget(object oPC)
{
    if(!GetLocalInt(oPC, CARTO_LVAR_TARGETING)) return;
    DeleteLocalInt(oPC, CARTO_LVAR_TARGETING);

    string sTag = GetLocalString(oPC, CARTO_LVAR_XFER_TAG);
    DeleteLocalString(oPC, CARTO_LVAR_XFER_TAG);

    object oTarget = GetTargetingModeSelectedObject();
    if(!GetIsObjectValid(oTarget) || !GetIsPC(oTarget) || oTarget == oPC)
    {
        SendMessageToPC(oPC, "[Kartomancer] Bledny cel — wybierz innego gracza.");
        return;
    }

    json jMap = CartoGetMap(oPC, sTag);
    if(JsonGetType(jMap) == JSON_TYPE_NULL) return;

    CartoCopyMapTo(oPC, oTarget, sTag);
    string sAreaName = JsonGetString(JsonObjectGet(jMap, "area_name"));

    SendMessageToPC(oPC,
        "[Kartomancer] Przekazano kopie mapy '" + sAreaName + "' graczowi " + GetName(oTarget) + ".");
    SendMessageToPC(oTarget,
        "[Kartomancer] " + GetName(oPC) + " przekazal Ci kopie mapy: '" + sAreaName + "'.");

    CartoApplyAreaBonus(oTarget);
}

// ----------------------------------------------------------------
// Area knowledge bonus
// ----------------------------------------------------------------

void CartoRemoveAreaBonus(object oPC)
{
    effect eCheck = GetFirstEffect(oPC);
    while(GetIsEffectValid(eCheck))
    {
        if(GetEffectTag(eCheck) == CARTO_EFFECT_TAG)
            RemoveEffect(oPC, eCheck);
        eCheck = GetNextEffect(oPC);
    }
}

void CartoApplyAreaBonus(object oPC)
{
    string sAreaTag = GetTag(GetArea(oPC));
    if(!CartoHasMap(oPC, sAreaTag)) return;

    // Avoid double-applying
    effect eCheck = GetFirstEffect(oPC);
    while(GetIsEffectValid(eCheck))
    {
        if(GetEffectTag(eCheck) == CARTO_EFFECT_TAG) return;
        eCheck = GetNextEffect(oPC);
    }

    effect eLore   = EffectSkillIncrease(SKILL_LORE,   CARTO_BONUS_AMOUNT);
    effect eSearch = EffectSkillIncrease(SKILL_SEARCH,  CARTO_BONUS_AMOUNT);
    effect eLink   = EffectLinkEffects(eLore, eSearch);
    eLink = TagEffect(eLink, CARTO_EFFECT_TAG);
    eLink = ExtraordinaryEffect(eLink);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eLink, oPC);

    FloatingTextStringOnCreature(
        "Posiadasz mape tego obszaru. (+2 Lore, +2 Search)",
        oPC, FALSE);
}

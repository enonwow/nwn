#include "lib_phy_def"

// ----------------------------------------------------------------
// Flavor text pool — chosen by charges remaining
// ----------------------------------------------------------------

string PhyGetFlavorText(int nCharges)
{
    if(nCharges <= 0)
        return "\"Naczynie jest puste. Dusza nie ma już schronienia.\"\n— Grobowe inskrypcje, Nekropolia Czarnego Księżyca";
    if(nCharges == 1)
        return "\"Ostatni oddech przed wielką ciemnością...\"\n— Modlitwy umierającego, Księga Wiecznego Zmierzchu";
    if(nCharges <= 3)
        return "\"Kamień pulsuje słabym blaskiem. Dusza jest bezpieczna — na razie.\"\n— Wykaz zaklęć filakterii, Wieża Czarnego Maga";
    return "\"Żar duszy rozświetla ciemność od środka. Śmierć będzie musiała zaczekać.\"\n— Sekret rzemieślników dusz, Zaginiona Biblioteka";
}

// ----------------------------------------------------------------
// Build — Status View
// ----------------------------------------------------------------

json BuildPhyStatusView(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fRowH = GetNuiScaleDimension(oPC, 26.0);
    float fLblW = GetNuiScaleDimension(oPC, 130.0);
    float fValW = GetNuiScaleDimension(oPC, 300.0);

    // -- Status row --
    json jStatusKey = NuiLabel(JsonString("Stan filakterii:"),
                               JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusKey = NuiWidth(jStatusKey, fLblW);
    json jStatusVal = NuiLabel(NuiBind(PHY_BIND_STATUS_LBL),
                               JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusVal = NuiStyleForegroundColor(jStatusVal, NuiBind(PHY_BIND_STATUS_COLOR));
    json jStatusRow = JsonArray();
    jStatusRow = JsonArrayInsert(jStatusRow, jStatusKey);
    jStatusRow = JsonArrayInsert(jStatusRow, jStatusVal);

    // -- Charges row --
    json jChargesKey = NuiLabel(JsonString("Ładunki duszy:"),
                                JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jChargesKey = NuiWidth(jChargesKey, fLblW);
    json jChargesVal = NuiLabel(NuiBind(PHY_BIND_CHARGES_LBL),
                                JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jChargesVal = NuiStyleForegroundColor(jChargesVal, NuiBind(PHY_BIND_CHARGES_COLOR));
    json jChargesRow = JsonArray();
    jChargesRow = JsonArrayInsert(jChargesRow, jChargesKey);
    jChargesRow = JsonArrayInsert(jChargesRow, jChargesVal);

    // -- Anchor location row --
    json jAnchorKey = NuiLabel(JsonString("Zakotwiczenie:"),
                               JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jAnchorKey = NuiWidth(jAnchorKey, fLblW);
    json jAnchorVal = NuiLabel(NuiBind(PHY_BIND_ANCHOR_LBL),
                               JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jAnchorRow = JsonArray();
    jAnchorRow = JsonArrayInsert(jAnchorRow, jAnchorKey);
    jAnchorRow = JsonArrayInsert(jAnchorRow, jAnchorVal);

    // -- Anchor date row --
    json jDateKey = NuiLabel(JsonString("Data zakotwiczenia:"),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDateKey = NuiWidth(jDateKey, fLblW);
    json jDateVal = NuiLabel(NuiBind(PHY_BIND_ANCHOR_DATE),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jDateRow = JsonArray();
    jDateRow = JsonArrayInsert(jDateRow, jDateKey);
    jDateRow = JsonArrayInsert(jDateRow, jDateVal);

    // -- Gold available row --
    json jGoldKey = NuiLabel(JsonString("Złoto:"),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jGoldKey = NuiWidth(jGoldKey, fLblW);
    json jGoldVal = NuiLabel(NuiBind(PHY_BIND_GOLD_LBL),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jGoldRow = JsonArray();
    jGoldRow = JsonArrayInsert(jGoldRow, jGoldKey);
    jGoldRow = JsonArrayInsert(jGoldRow, jGoldVal);

    // -- Flavor text area --
    float fFlavorH = GetNuiScaleDimension(oPC, 90.0);
    json jFlavor = NuiGroup(NuiText(NuiBind(PHY_BIND_FLAVOR_TXT), FALSE),
                            TRUE, NUI_SCROLLBARS_NONE);
    jFlavor = NuiHeight(jFlavor, fFlavorH);

    // -- Action buttons --
    float fFullBtnW = GetNuiScaleDimension(oPC, 200.0);
    float fHalfBtnW = GetNuiScaleDimension(oPC, 150.0);

    json jCreateBtn = NuiButton(NuiBind(PHY_BIND_CREATE_LBL));
    jCreateBtn = NuiId(jCreateBtn, PHY_BTN_CREATE);
    jCreateBtn = NuiEnabled(jCreateBtn, NuiBind(PHY_BIND_CREATE_ENA));
    jCreateBtn = NuiWidth(jCreateBtn, fFullBtnW);
    jCreateBtn = NuiHeight(jCreateBtn, fBtnH);

    json jAnchorBtn = NuiButton(JsonString("Zakotwicz Tutaj"));
    jAnchorBtn = NuiId(jAnchorBtn, PHY_BTN_ANCHOR);
    jAnchorBtn = NuiEnabled(jAnchorBtn, NuiBind(PHY_BIND_ANCHOR_ENA));
    jAnchorBtn = NuiWidth(jAnchorBtn, fFullBtnW);
    jAnchorBtn = NuiHeight(jAnchorBtn, fBtnH);

    string sEmpLabel = "Wzmocnij (+" + IntToString(PHY_EMPOWER_GOLD_COST) + " sz)";
    json jEmpowerBtn = NuiButton(JsonString(sEmpLabel));
    jEmpowerBtn = NuiId(jEmpowerBtn, PHY_BTN_EMPOWER);
    jEmpowerBtn = NuiEnabled(jEmpowerBtn, NuiBind(PHY_BIND_EMPOWER_ENA));
    jEmpowerBtn = NuiWidth(jEmpowerBtn, fHalfBtnW);
    jEmpowerBtn = NuiHeight(jEmpowerBtn, fBtnH);

    json jShatterBtn = NuiButton(JsonString("Rozbij Naczynie"));
    jShatterBtn = NuiId(jShatterBtn, PHY_BTN_SHATTER);
    jShatterBtn = NuiEnabled(jShatterBtn, NuiBind(PHY_BIND_SHATTER_ENA));
    jShatterBtn = NuiWidth(jShatterBtn, fHalfBtnW);
    jShatterBtn = NuiHeight(jShatterBtn, fBtnH);

    json jTopBtnRow = JsonArray();
    jTopBtnRow = JsonArrayInsert(jTopBtnRow, jCreateBtn);
    jTopBtnRow = JsonArrayInsert(jTopBtnRow, NuiSpacer());
    jTopBtnRow = JsonArrayInsert(jTopBtnRow, jAnchorBtn);

    json jBotBtnRow = JsonArray();
    jBotBtnRow = JsonArrayInsert(jBotBtnRow, jEmpowerBtn);
    jBotBtnRow = JsonArrayInsert(jBotBtnRow, NuiSpacer());
    jBotBtnRow = JsonArrayInsert(jBotBtnRow, jShatterBtn);

    // -- Assemble column --
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jStatusRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jChargesRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jAnchorRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jDateRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jGoldRow));
    jCol = JsonArrayInsert(jCol, jFlavor);
    jCol = JsonArrayInsert(jCol, NuiRow(jTopBtnRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jBotBtnRow));

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 460.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Build — History View
// ----------------------------------------------------------------

json BuildPhyHistoryView(object oPC)
{
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fListH = GetNuiScaleDimension(oPC, 340.0);
    float fDateW = GetNuiScaleDimension(oPC, 90.0);
    float fAreaW = GetNuiScaleDimension(oPC, 140.0);

    json jDateLbl = NuiLabel(NuiBind(PHY_BIND_HIST_DATE),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDateLbl = NuiWidth(jDateLbl, fDateW);
    jDateLbl = NuiStyleForegroundColor(jDateLbl, NuiBind(PHY_BIND_HIST_COLOR));

    json jKillerLbl = NuiLabel(NuiBind(PHY_BIND_HIST_KILLER),
                               JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jKillerLbl = NuiStyleForegroundColor(jKillerLbl, NuiBind(PHY_BIND_HIST_COLOR));

    json jAreaLbl = NuiLabel(NuiBind(PHY_BIND_HIST_AREA),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jAreaLbl = NuiWidth(jAreaLbl, fAreaW);
    jAreaLbl = NuiStyleForegroundColor(jAreaLbl, NuiBind(PHY_BIND_HIST_COLOR));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jDateLbl)),   fDateW));
    jCellRow = JsonArrayInsert(jCellRow, jKillerLbl);
    jCellRow = JsonArrayInsert(jCellRow, NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jAreaLbl)), fAreaW));

    json jCell = NuiGroup(NuiRow(jCellRow), FALSE, NUI_SCROLLBARS_NONE);
    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(PHY_BIND_HIST_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    json jHdrDate  = NuiLabel(JsonString("Data"),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrDate  = NuiWidth(jHdrDate, fDateW);
    json jHdrKill  = NuiLabel(JsonString("Zabójca / Przyczyna"),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jHdrArea  = NuiLabel(JsonString("Lokacja"),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrArea  = NuiWidth(jHdrArea, fAreaW);
    json jHdrRow   = JsonArray();
    jHdrRow = JsonArrayInsert(jHdrRow, NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jHdrDate)), fDateW));
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrKill);
    jHdrRow = JsonArrayInsert(jHdrRow, NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jHdrArea)), fAreaW));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jHdrRow));
    jCol = JsonArrayInsert(jCol, jList);

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 460.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Window create
// ----------------------------------------------------------------

void CreatePhyWindow(object oPC)
{
    if(NuiFindWindow(oPC, PHY_WINDOW) != 0)
    {
        PhySwapToStatus(oPC, NuiFindWindow(oPC, PHY_WINDOW));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, PHY_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, PHY_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
                         GetNuiScaleDimension(oPC, PHY_W),
                         GetNuiScaleDimension(oPC, PHY_H));

    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fTabW  = GetNuiScaleDimension(oPC, 120.0);

    // Tab row + close button
    json jTabStatus = NuiButton(JsonString("Status"));
    jTabStatus = NuiId(jTabStatus, PHY_BTN_TAB_STATUS);
    jTabStatus = NuiWidth(jTabStatus, fTabW);
    jTabStatus = NuiHeight(jTabStatus, fBtnH);

    json jTabHistory = NuiButton(JsonString("Historia Śmierci"));
    jTabHistory = NuiId(jTabHistory, PHY_BTN_TAB_HISTORY);
    jTabHistory = NuiWidth(jTabHistory, fTabW);
    jTabHistory = NuiHeight(jTabHistory, fBtnH);

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, PHY_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTabRow = JsonArray();
    jTabRow = JsonArrayInsert(jTabRow, jTabStatus);
    jTabRow = JsonArrayInsert(jTabRow, jTabHistory);
    jTabRow = JsonArrayInsert(jTabRow, NuiSpacer());
    jTabRow = JsonArrayInsert(jTabRow, jCloseBtn);

    json jSwapGrp = NuiGroup(BuildPhyStatusView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, PHY_GRP_SWAP);

    json jRootChildren = JsonArray();
    jRootChildren = JsonArrayInsert(jRootChildren, NuiRow(jTabRow));
    jRootChildren = JsonArrayInsert(jRootChildren, jSwapGrp);
    json jRoot = NuiCol(jRootChildren);

    json jWin = NuiWindow(jRoot,
        JsonString("Filakteria"),
        NuiBind(PHY_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, PHY_WINDOW, PHY_EV_SCRIPT);
    NuiSetBind(oPC, nToken, PHY_WIN_GEOM, jGeom);

    SetLocalString(oPC, PHY_LVAR_VIEW, "status");
    PhyFeedStatus(oPC, nToken);
}

// ----------------------------------------------------------------
// Tab swap
// ----------------------------------------------------------------

void PhySwapToStatus(object oPC, int nToken)
{
    SetLocalString(oPC, PHY_LVAR_VIEW, "status");
    NuiSetGroupLayout(oPC, nToken, PHY_GRP_SWAP, BuildPhyStatusView(oPC));
    PhyFeedStatus(oPC, nToken);
}

void PhySwapToHistory(object oPC, int nToken)
{
    SetLocalString(oPC, PHY_LVAR_VIEW, "history");
    NuiSetGroupLayout(oPC, nToken, PHY_GRP_SWAP, BuildPhyHistoryView(oPC));
    PhyFeedHistory(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed — Status
// ----------------------------------------------------------------

void PhyFeedStatus(object oPC, int nToken)
{
    json jRec = PhyGetRecord(oPC);
    int bExists  = (JsonGetType(jRec) != JSON_TYPE_NULL);
    int bActive  = bExists && JsonGetInt(JsonObjectGet(jRec, "is_active"));
    int nCharges = bExists ? JsonGetInt(JsonObjectGet(jRec, "charges")) : 0;
    int nMax     = bExists ? JsonGetInt(JsonObjectGet(jRec, "max_charges")) : PHY_MAX_CHARGES;
    string sAnchorArea = bExists ? JsonGetString(JsonObjectGet(jRec, "anchor_area_name")) : "";
    int nAnchorAt = bExists ? JsonGetInt(JsonObjectGet(jRec, "anchor_at")) : 0;
    int bHasAnchor = (sAnchorArea != "");

    // Status label + color
    string sStatus;
    json jStatusColor;
    if(!bExists)
    {
        sStatus      = "Brak filakterii";
        jStatusColor = NuiColor(160, 160, 160);
    }
    else if(!bActive)
    {
        sStatus      = "ROZBITA — dusza uwolniona";
        jStatusColor = NuiColor(200, 80, 80);
    }
    else if(!bHasAnchor)
    {
        sStatus      = "Aktywna — niezakotwiczona";
        jStatusColor = NuiColor(220, 200, 80);
    }
    else
    {
        sStatus      = "Aktywna — zakotwiczona";
        jStatusColor = NuiColor(80, 200, 120);
    }

    // Charges label + color
    string sCharges = bExists ? (IntToString(nCharges) + " / " + IntToString(nMax)) : "-";
    json jChargesColor;
    if(nCharges == 0)       jChargesColor = NuiColor(200, 80, 80);
    else if(nCharges <= 2)  jChargesColor = NuiColor(220, 160, 50);
    else                    jChargesColor = NuiColor(200, 255, 200);

    // Button states
    int bCanCreate  = !bExists || !bActive;
    int bCanAnchor  = bExists && bActive;
    int bCanEmpower = bExists && bActive && (nCharges < nMax) && (GetGold(oPC) >= PHY_EMPOWER_GOLD_COST);
    int bCanShatter = bExists;

    string sCreateLbl = bExists ? "Odtwórz Filakterię (" + IntToString(PHY_CREATE_GOLD_COST) + " sz)"
                                : "Stwórz Filakterię (" + IntToString(PHY_CREATE_GOLD_COST) + " sz)";

    NuiSetBind(oPC, nToken, PHY_BIND_STATUS_LBL,    JsonString(sStatus));
    NuiSetBind(oPC, nToken, PHY_BIND_STATUS_COLOR,  jStatusColor);
    NuiSetBind(oPC, nToken, PHY_BIND_CHARGES_LBL,   JsonString(sCharges));
    NuiSetBind(oPC, nToken, PHY_BIND_CHARGES_COLOR, jChargesColor);
    NuiSetBind(oPC, nToken, PHY_BIND_ANCHOR_LBL,    JsonString(bHasAnchor ? sAnchorArea : "(brak)"));
    NuiSetBind(oPC, nToken, PHY_BIND_ANCHOR_DATE,   JsonString(bHasAnchor ? PhyFormatDate(nAnchorAt) : "-"));
    NuiSetBind(oPC, nToken, PHY_BIND_GOLD_LBL,      JsonString(IntToString(GetGold(oPC)) + " sz"));
    NuiSetBind(oPC, nToken, PHY_BIND_FLAVOR_TXT,    JsonString(PhyGetFlavorText(nCharges)));
    NuiSetBind(oPC, nToken, PHY_BIND_CREATE_LBL,    JsonString(sCreateLbl));
    NuiSetBind(oPC, nToken, PHY_BIND_CREATE_ENA,    JsonBool(bCanCreate && GetGold(oPC) >= PHY_CREATE_GOLD_COST));
    NuiSetBind(oPC, nToken, PHY_BIND_ANCHOR_ENA,    JsonBool(bCanAnchor));
    NuiSetBind(oPC, nToken, PHY_BIND_EMPOWER_ENA,   JsonBool(bCanEmpower));
    NuiSetBind(oPC, nToken, PHY_BIND_SHATTER_ENA,   JsonBool(bCanShatter));
}

// ----------------------------------------------------------------
// Feed — History
// ----------------------------------------------------------------

void PhyFeedHistory(object oPC, int nToken)
{
    json jHistory = PhyGetResurrectionHistory(oPC);
    int nCount    = JsonGetLength(jHistory);

    json jDates   = JsonArray();
    json jKillers = JsonArray();
    json jAreas   = JsonArray();
    json jColors  = JsonArray();
    json jGray    = NuiColor(180, 180, 180);

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow      = JsonArrayGet(jHistory, i);
        int  nTs       = JsonGetInt   (JsonObjectGet(jRow, "resurrect_at"));
        string sKiller = JsonGetString(JsonObjectGet(jRow, "killed_by"));
        string sArea   = JsonGetString(JsonObjectGet(jRow, "area_name"));

        jDates   = JsonArrayInsert(jDates,   JsonString(PhyFormatDate(nTs)));
        jKillers = JsonArrayInsert(jKillers, JsonString(sKiller != "" ? sKiller : "nieznane"));
        jAreas   = JsonArrayInsert(jAreas,   JsonString(sArea   != "" ? sArea   : "-"));
        jColors  = JsonArrayInsert(jColors,  jGray);
    }

    if(nCount == 0)
    {
        jDates   = JsonArrayInsert(jDates,   JsonString("-"));
        jKillers = JsonArrayInsert(jKillers, JsonString("Brak zapisanych zmartwychwstań."));
        jAreas   = JsonArrayInsert(jAreas,   JsonString("-"));
        jColors  = JsonArrayInsert(jColors,  jGray);
        nCount   = 1;
    }

    NuiSetBind(oPC, nToken, PHY_BIND_HIST_DATE,   jDates);
    NuiSetBind(oPC, nToken, PHY_BIND_HIST_KILLER, jKillers);
    NuiSetBind(oPC, nToken, PHY_BIND_HIST_AREA,   jAreas);
    NuiSetBind(oPC, nToken, PHY_BIND_HIST_COLOR,  jColors);
    NuiSetBind(oPC, nToken, PHY_BIND_HIST_COUNT,  JsonInt(nCount));
}

// ----------------------------------------------------------------
// Shatter confirmation popup
// ----------------------------------------------------------------

void CreatePhyShatterConfirm(object oPC)
{
    if(NuiFindWindow(oPC, PHY_WIN_CONFIRM) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, PHY_WIN_CONFIRM));

    float fW = GetNuiScaleDimension(oPC, 400.0);
    float fH = GetNuiScaleDimension(oPC, 180.0);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    json jMsg = NuiLabel(
        JsonString("Rozbicie naczynia uwalnia uwięzioną duszę.\n"
                   + "Zyskasz chwilowe wzmocnienie, lecz filakteria zostanie\n"
                   + "zniszczona bezpowrotnie. Czy jesteś pewien?"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));

    json jYes = NuiButton(JsonString("Rozbij"));
    jYes = NuiId(jYes, PHY_BTN_CONF_YES);
    jYes = NuiWidth(jYes, GetNuiScaleDimension(oPC, 110.0));

    json jNo = NuiButton(JsonString("Cofnij"));
    jNo = NuiId(jNo, PHY_BTN_CONF_NO);
    jNo = NuiWidth(jNo, GetNuiScaleDimension(oPC, 110.0));

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jYes);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jNo);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jMsg);
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jWin = NuiWindow(NuiCol(jCol),
        JsonString("Rozbicie Filakterii"),
        NuiRect(fX, fY, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    NuiCreate(oPC, jWin, PHY_WIN_CONFIRM, PHY_EV_SCRIPT);
}

// ----------------------------------------------------------------
// Shatter effect — applies temporary combat bonuses
// ----------------------------------------------------------------

void PhyApplyShatterBuff(object oPC)
{
    effect eSaves  = EffectSavingThrowIncrease(SAVING_THROW_ALL, PHY_SHATTER_SAVES);
    effect eAB     = EffectAttackIncrease(2, ATTACK_BONUS_MISC);
    effect eLink   = EffectLinkEffects(eSaves, eAB);
    eLink = SupernaturalEffect(eLink);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eLink, oPC,
                        IntToFloat(PHY_SHATTER_DURATION));

    FloatingTextStringOnCreature(
        "Uwolniona energia duszy przenika twoje ciało!", oPC, FALSE);
    SendMessageToPC(oPC,
        "[Filakteria] Rozbicie naczynia: +2 do rzutów obronnych i trafień na 1 godzinę.");
}

// ----------------------------------------------------------------
// Death handling
// ----------------------------------------------------------------

void PhyRespawnAndTeleport(object oPC)
{
    json jRec = PhyGetRecord(oPC);
    if(JsonGetType(jRec) == JSON_TYPE_NULL) return;

    string sAreaTag = JsonGetString(JsonObjectGet(jRec, "anchor_area"));
    float  fX       = JsonGetFloat (JsonObjectGet(jRec, "anchor_x"));
    float  fY       = JsonGetFloat (JsonObjectGet(jRec, "anchor_y"));
    float  fZ       = JsonGetFloat (JsonObjectGet(jRec, "anchor_z"));
    float  fFacing  = JsonGetFloat (JsonObjectGet(jRec, "anchor_facing"));

    object oArea = GetObjectByTag(sAreaTag);
    if(!GetIsObjectValid(oArea))
    {
        SendMessageToPC(oPC, "[Filakteria] Zakotwiczona lokacja jest niedostępna.");
        return;
    }

    RespawnPC(oPC);

    location lDest = Location(oArea, Vector(fX, fY, fZ), fFacing);
    DelayCommand(0.5, AssignCommand(oPC, JumpToLocation(lDest)));

    // HP penalty: set to 25% of max
    int nMaxHP = GetMaxHitPoints(oPC);
    int nTarget = nMaxHP * PHY_RESURRECT_HP_PCT / 100;
    if(nTarget < 1) nTarget = 1;
    int nCurrent = GetCurrentHitPoints(oPC);
    if(nCurrent > nTarget)
    {
        effect eDmg = EffectDamage(nCurrent - nTarget, DAMAGE_TYPE_MAGICAL, DAMAGE_POWER_NORMAL);
        DelayCommand(0.8, ApplyEffectToObject(DURATION_TYPE_INSTANT, eDmg, oPC));
    }

    // Exhaustion: -2 STR/CON for 5 minutes
    effect eExhaust = EffectLinkEffects(
        EffectAbilityDecrease(ABILITY_STRENGTH,     2),
        EffectAbilityDecrease(ABILITY_CONSTITUTION, 2));
    eExhaust = SupernaturalEffect(eExhaust);
    DelayCommand(0.9, ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eExhaust, oPC, 300.0));
}

void PhyHandleDeath(object oPC)
{
    if(!GetIsPC(oPC)) return;
    if(!PhyHasPhylactery(oPC)) return;

    // Identify killer for log
    object oKiller = GetLastKiller();
    string sKilledBy = GetIsObjectValid(oKiller) ? GetName(oKiller) : "nieznane";
    string sAreaName = GetName(GetArea(oPC));

    if(!PhyConsumeCharge(oPC)) return;

    PhyLogResurrection(oPC, sKilledBy, sAreaName);

    json jRec      = PhyGetRecord(oPC);
    int  nLeft     = (JsonGetType(jRec) != JSON_TYPE_NULL)
                     ? JsonGetInt(JsonObjectGet(jRec, "charges")) : 0;
    int  bLastCharge = (nLeft == 0);

    FloatingTextStringOnCreature(
        "Filakteria pochłania twoją duszę... i zwraca ją!", oPC, FALSE);
    SendMessageToPC(oPC,
        "[Filakteria] Zmartwychwstajesz w zakotwiczonej lokacji. "
        + "Pozostało ładunków: " + IntToString(nLeft) + ".");

    if(bLastCharge)
    {
        SendMessageToPC(oPC,
            "[Filakteria] To był ostatni ładunek. Naczynie duszy zostało rozbite.");
        DelayCommand(1.5, PhyApplyShatterBuff(oPC));
    }

    DelayCommand(1.0, PhyRespawnAndTeleport(oPC));
}

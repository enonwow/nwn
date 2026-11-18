#include "lib_pawn_def"

// ----------------------------------------------------------------
// Internal helpers
// ----------------------------------------------------------------

// Returns the icon resref for an item, falling back to a generic one.
string PawnItemIcon(object oItem)
{
    string sIcon = Get2DAString("baseitems", "DefaultIcon", GetBaseItemType(oItem));
    if(sIcon == "") sIcon = "ir_barter";
    return sIcon;
}

// Gold loan offered for an item (25% of GPV, minimum 1).
int PawnCalcLoan(object oItem)
{
    int nVal = GetGoldPieceValue(oItem);
    int nLoan = FloatToInt(IntToFloat(nVal) * PAWN_VALUE_RATIO);
    return (nLoan < 1) ? 1 : nLoan;
}

// Human-readable status badge text.
string PawnStatusBadge(int nIsExpired, int nDaysLeft)
{
    if(nIsExpired) return "WYGASŁO";
    if(nDaysLeft <= 1) return "jutro";
    return IntToString(nDaysLeft) + "d";
}

// Total offer for all filled slots.
int PawnTotalOffer(object oPC)
{
    json jSlots = GetLocalJson(oPC, PAWN_LVAR_SLOTS);
    int nCount  = JsonGetLength(jSlots);
    int nTotal  = 0;
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jSlot = JsonArrayGet(jSlots, i);
        nTotal += JsonGetInt(JsonObjectGet(jSlot, "loan"));
    }
    return nTotal;
}

// ----------------------------------------------------------------
// Browse view layout
// ----------------------------------------------------------------

json BuildPawnBrowseView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fListH = GetNuiScaleDimension(oPC, 200.0);
    float fDetH  = GetNuiScaleDimension(oPC, 80.0);

    // ---- Header row: title + "Zastaw" button ----
    json jTitle = NuiLabel(JsonString("Lombard — Zastaw i Wykup"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);

    json jPawnBtn = NuiButton(JsonString("Zastaw przedmiot"));
    jPawnBtn = NuiId(jPawnBtn, PAWN_BTN_TO_PAWN);
    jPawnBtn = NuiWidth(jPawnBtn, GetNuiScaleDimension(oPC, 150.0));
    jPawnBtn = NuiHeight(jPawnBtn, fBtnH);

    json jHeaderRow = JsonArray();
    jHeaderRow = JsonArrayInsert(jHeaderRow, jTitle);
    jHeaderRow = JsonArrayInsert(jHeaderRow, NuiSpacer());
    jHeaderRow = JsonArrayInsert(jHeaderRow, jPawnBtn);

    // ---- List columns: name | status | days | cost ----
    float fNameW   = GetNuiScaleDimension(oPC, 240.0);
    float fBadgeW  = GetNuiScaleDimension(oPC, 70.0);
    float fDaysW   = GetNuiScaleDimension(oPC, 55.0);
    float fCostW   = GetNuiScaleDimension(oPC, 90.0);

    json jNameLbl = NuiLabel(NuiBind(PAWN_BIND_ROW_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(PAWN_BIND_ROW_COLOR));

    json jStatusLbl = NuiLabel(NuiBind(PAWN_BIND_ROW_STATUS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiWidth(jStatusLbl, fBadgeW);
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiBind(PAWN_BIND_ROW_COST_CLR));

    json jDaysLbl = NuiLabel(NuiBind(PAWN_BIND_ROW_DAYS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDaysLbl = NuiWidth(jDaysLbl, fDaysW);
    jDaysLbl = NuiStyleForegroundColor(jDaysLbl, NuiBind(PAWN_BIND_ROW_COLOR));

    json jCostLbl = NuiLabel(NuiBind(PAWN_BIND_ROW_COST), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jCostLbl = NuiWidth(jCostLbl, fCostW);
    jCostLbl = NuiStyleForegroundColor(jCostLbl, NuiBind(PAWN_BIND_ROW_COST_CLR));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jNameLbl)), fNameW));
    jCellRow = JsonArrayInsert(jCellRow, jStatusLbl);
    jCellRow = JsonArrayInsert(jCellRow, jDaysLbl);
    jCellRow = JsonArrayInsert(jCellRow, jCostLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, PAWN_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(PAWN_BIND_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind("pawn_rowcount"), fRowH);
    jList = NuiHeight(jList, fListH);

    // ---- Detail panel ----
    json jDetName = NuiLabel(NuiBind(PAWN_BIND_DET_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDetName = NuiHeight(jDetName, GetNuiScaleDimension(oPC, 22.0));

    json jDetInfo = NuiGroup(NuiText(NuiBind(PAWN_BIND_DET_INFO), FALSE), TRUE, NUI_SCROLLBARS_NONE);
    jDetInfo = NuiHeight(jDetInfo, fDetH);

    // ---- Bottom: Redeem button + flavor ----
    json jFlavorLbl = NuiLabel(NuiBind(PAWN_BIND_FLAVOR), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jRedeemBtn = NuiButton(NuiBind(PAWN_BIND_REDEEM_LBL));
    jRedeemBtn = NuiId(jRedeemBtn, PAWN_BTN_REDEEM);
    jRedeemBtn = NuiEnabled(jRedeemBtn, NuiBind(PAWN_BIND_REDEEM_ENA));
    jRedeemBtn = NuiWidth(jRedeemBtn, GetNuiScaleDimension(oPC, 200.0));
    jRedeemBtn = NuiHeight(jRedeemBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jFlavorLbl);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jRedeemBtn);

    // ---- Assemble ----
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jHeaderRow));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, jDetName);
    jCol = JsonArrayInsert(jCol, jDetInfo);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    json jSide    = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContW  = GetNuiScaleDimension(oPC, 640.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Pawn view layout
// ----------------------------------------------------------------

json BuildPawnPawnView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fSlotSz = GetNuiScaleDimension(oPC, 64.0);

    // ---- Top: back + heading ----
    json jBackBtn = NuiButton(JsonString("← Wróć"));
    jBackBtn = NuiId(jBackBtn, PAWN_BTN_BACK);
    jBackBtn = NuiWidth(jBackBtn, GetNuiScaleDimension(oPC, 90.0));
    jBackBtn = NuiHeight(jBackBtn, fBtnH);

    json jHeading = NuiLabel(JsonString("Zastawianie przedmiotów"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHeading = NuiHeight(jHeading, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jBackBtn);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jHeading);

    // ---- Flavor text ----
    json jFlavorLbl = NuiLabel(NuiBind(PAWN_BIND_PAWN_FLAVOR), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jFlavorLbl = NuiHeight(jFlavorLbl, GetNuiScaleDimension(oPC, 42.0));

    // ---- Instruction ----
    json jInstr = NuiLabel(JsonString("Kliknij gniazdo, by wybrać przedmiot z ekwipunku. Ponowne kliknięcie zwraca przedmiot."),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jInstr = NuiHeight(jInstr, GetNuiScaleDimension(oPC, 26.0));

    // ---- Item slots ----
    json jSlotRow = JsonArray();
    int i;
    for(i = 0; i < PAWN_SLOT_COUNT; i++)
    {
        string sImgBind = PAWN_BIND_SLOT_IMG + IntToString(i);
        string sTipBind = PAWN_BIND_SLOT_TIP + IntToString(i);
        string sBtnId   = PAWN_BTN_SLOT + IntToString(i);

        json jSlotBtn = NuiButtonImage(NuiBind(sImgBind));
        jSlotBtn = NuiId(jSlotBtn, sBtnId);
        jSlotBtn = NuiWidth(jSlotBtn, fSlotSz);
        jSlotBtn = NuiHeight(jSlotBtn, fSlotSz);
        jSlotBtn = NuiTooltip(jSlotBtn, NuiBind(sTipBind));

        jSlotRow = JsonArrayInsert(jSlotRow, jSlotBtn);
        // small spacer between slots
        jSlotRow = JsonArrayInsert(jSlotRow, CreateEmptyRow(oPC, 8.0));
    }

    json jSlotWrap = NuiRow(jSlotRow);

    // ---- Offer summary ----
    json jOfferLbl = NuiLabel(NuiBind(PAWN_BIND_OFFER_LBL), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jOfferLbl = NuiHeight(jOfferLbl, GetNuiScaleDimension(oPC, 28.0));
    jOfferLbl = NuiStyleForegroundColor(jOfferLbl, GetNuiColorNwnGold());

    // ---- Confirm button ----
    json jConfirmBtn = NuiButton(JsonString("Zastawiam"));
    jConfirmBtn = NuiId(jConfirmBtn, PAWN_BTN_CONFIRM);
    jConfirmBtn = NuiEnabled(jConfirmBtn, NuiBind(PAWN_BIND_CONFIRM_ENA));
    jConfirmBtn = NuiWidth(jConfirmBtn, GetNuiScaleDimension(oPC, 150.0));
    jConfirmBtn = NuiHeight(jConfirmBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jOfferLbl);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jConfirmBtn);

    // ---- Assemble ----
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTopRow));
    jCol = JsonArrayInsert(jCol, jFlavorLbl);
    jCol = JsonArrayInsert(jCol, jInstr);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 10.0));
    jCol = JsonArrayInsert(jCol, jSlotWrap);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 10.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    json jSide    = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContW  = GetNuiScaleDimension(oPC, 640.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Window lifecycle
// ----------------------------------------------------------------

void CreatePawnWindow(object oPC)
{
    if(NuiFindWindow(oPC, PAWN_WINDOW) != 0)
    {
        SwapToBrowseView(oPC, NuiFindWindow(oPC, PAWN_WINDOW));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - GetNuiScaleDimension(oPC, PAWN_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - GetNuiScaleDimension(oPC, PAWN_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, PAWN_W), GetNuiScaleDimension(oPC, PAWN_H));

    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, PAWN_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTitleRow = JsonArray();
    jTitleRow = JsonArrayInsert(jTitleRow, NuiSpacer());
    jTitleRow = JsonArrayInsert(jTitleRow, jCloseBtn);

    json jSwapGrp = NuiGroup(BuildPawnBrowseView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, PAWN_GRP_SWAP);

    json jRootChildren = JsonArray();
    jRootChildren = JsonArrayInsert(jRootChildren, NuiRow(jTitleRow));
    jRootChildren = JsonArrayInsert(jRootChildren, jSwapGrp);
    json jRoot = NuiCol(jRootChildren);

    json jWin = NuiWindow(jRoot,
        JsonBool(FALSE),
        NuiBind(PAWN_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, PAWN_WINDOW, PAWN_EV_SCRIPT);
    NuiSetBind(oPC, nToken, PAWN_WIN_GEOM, jGeom);
    SwapToBrowseView(oPC, nToken);
}

// ----------------------------------------------------------------
// View transitions
// ----------------------------------------------------------------

void SwapToBrowseView(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, PAWN_GRP_SWAP, BuildPawnBrowseView(oPC));
    SetLocalInt(oPC, PAWN_LVAR_SEL_ID, 0);
    FeedBrowseList(oPC, nToken);
}

void SwapToPawnView(object oPC, int nToken)
{
    SetLocalJson(oPC, PAWN_LVAR_SLOTS, JsonArray());
    NuiSetGroupLayout(oPC, nToken, PAWN_GRP_SWAP, BuildPawnPawnView(oPC));
    NuiSetBind(oPC, nToken, PAWN_BIND_PAWN_FLAVOR, JsonString(PAWN_FLAVOR_PAWN));
    FeedPawnSlots(oPC, nToken);
    FeedPawnOffer(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed: browse list
// ----------------------------------------------------------------

void FeedBrowseList(object oPC, int nToken)
{
    json jRows = PawnGetActive(GetObjectUUID(oPC));
    int  nCount = JsonGetLength(jRows);

    json jNames    = JsonArray();
    json jStatuses = JsonArray();
    json jDays     = JsonArray();
    json jCosts    = JsonArray();
    json jColors   = JsonArray();
    json jCostClrs = JsonArray();
    json jEncs     = JsonArray();

    json jWhite    = NuiColor(255, 255, 255);
    json jGold     = GetNuiColorNwnGold();
    json jRed      = NuiColor(220, 60, 60);
    json jOrange   = NuiColor(255, 160, 50);

    int nSelId = GetLocalInt(oPC, PAWN_LVAR_SEL_ID);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow      = JsonArrayGet(jRows, i);
        int  nId       = JsonGetInt(JsonObjectGet(jRow, "id"));
        int  nExpired  = JsonGetInt(JsonObjectGet(jRow, "is_expired"));
        int  nDaysLeft = JsonGetInt(JsonObjectGet(jRow, "days_left"));
        int  nCost     = JsonGetInt(JsonObjectGet(jRow, "redeem_cost"));

        string sBadge  = PawnStatusBadge(nExpired, nDaysLeft);
        string sCost   = IntToString(nCost) + " sz";
        string sDays   = IntToString(nExpired ? 0 : nDaysLeft) + "d";

        json jRowClr   = jWhite;
        json jCostClr  = nExpired ? jRed : ((nDaysLeft <= 2) ? jOrange : jGold);

        jNames    = JsonArrayInsert(jNames,    JsonString(JsonGetString(JsonObjectGet(jRow, "name"))));
        jStatuses = JsonArrayInsert(jStatuses, JsonString(sBadge));
        jDays     = JsonArrayInsert(jDays,     JsonString(sDays));
        jCosts    = JsonArrayInsert(jCosts,    JsonString(sCost));
        jColors   = JsonArrayInsert(jColors,   jRowClr);
        jCostClrs = JsonArrayInsert(jCostClrs, jCostClr);
        jEncs     = JsonArrayInsert(jEncs,     JsonBool(nSelId > 0 && nId == nSelId));
    }

    NuiSetBind(oPC, nToken, PAWN_BIND_ROW_NAME,     jNames);
    NuiSetBind(oPC, nToken, PAWN_BIND_ROW_STATUS,   jStatuses);
    NuiSetBind(oPC, nToken, PAWN_BIND_ROW_DAYS,     jDays);
    NuiSetBind(oPC, nToken, PAWN_BIND_ROW_COST,     jCosts);
    NuiSetBind(oPC, nToken, PAWN_BIND_ROW_COLOR,    jColors);
    NuiSetBind(oPC, nToken, PAWN_BIND_ROW_COST_CLR, jCostClrs);
    NuiSetBind(oPC, nToken, PAWN_BIND_ROW_ENC,      jEncs);
    NuiSetBind(oPC, nToken, "pawn_rowcount",         JsonInt(nCount));

    // Reset detail panel
    NuiSetBind(oPC, nToken, PAWN_BIND_DET_NAME,   JsonString(""));
    NuiSetBind(oPC, nToken, PAWN_BIND_DET_INFO,   JsonString(""));
    NuiSetBind(oPC, nToken, PAWN_BIND_REDEEM_ENA, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, PAWN_BIND_REDEEM_LBL, JsonString("Wykup"));

    string sFlavor = (nCount == 0) ? PAWN_FLAVOR_EMPTY : PAWN_FLAVOR_GREET;
    NuiSetBind(oPC, nToken, PAWN_BIND_FLAVOR, JsonString(sFlavor));
}

void FeedBrowseDetail(object oPC, int nToken, int nId)
{
    json jItem = PawnGetItem(nId);
    if(JsonGetType(jItem) == JSON_TYPE_NULL) return;

    SetLocalInt(oPC, PAWN_LVAR_SEL_ID, nId);

    string sName    = JsonGetString(JsonObjectGet(jItem, "item_name"));
    int    nCost    = JsonGetInt   (JsonObjectGet(jItem, "redeem_cost"));
    int    nBaseLoan= JsonGetInt   (JsonObjectGet(jItem, "base_loan"));
    int    nDays    = JsonGetInt   (JsonObjectGet(jItem, "days_elapsed"));
    int    nExpired = JsonGetInt   (JsonObjectGet(jItem, "is_expired"));
    int    nDaysLeft= PAWN_EXPIRY_DAYS - nDays;

    string sInfo;
    if(nExpired)
    {
        sInfo = "Termin wykupu minął " + IntToString(nDays - PAWN_EXPIRY_DAYS + 1) + " dni temu.\n"
              + "Pożyczka: " + IntToString(nBaseLoan) + " sz\n"
              + "Narosłe odsetki: " + IntToString(nCost - nBaseLoan) + " sz\n"
              + "Łączna kwota wykupu: " + IntToString(nCost) + " sz\n\n"
              + PAWN_FLAVOR_EXPIRED;
    }
    else
    {
        sInfo = "Pozostało dni: " + IntToString(nDaysLeft) + "\n"
              + "Pożyczka: " + IntToString(nBaseLoan) + " sz\n"
              + "Narosłe odsetki: " + IntToString(nCost - nBaseLoan) + " sz\n"
              + "Kwota wykupu teraz: " + IntToString(nCost) + " sz";
    }

    string sRedeemLbl = "Wykup (" + IntToString(nCost) + " sz)";
    int bCanRedeem = (GetGold(oPC) >= nCost);

    FeedBrowseList(oPC, nToken);
    NuiSetBind(oPC, nToken, PAWN_BIND_DET_NAME,   JsonString(sName));
    NuiSetBind(oPC, nToken, PAWN_BIND_DET_INFO,   JsonString(sInfo));
    NuiSetBind(oPC, nToken, PAWN_BIND_REDEEM_ENA, JsonBool(bCanRedeem));
    NuiSetBind(oPC, nToken, PAWN_BIND_REDEEM_LBL, JsonString(sRedeemLbl));
}

// ----------------------------------------------------------------
// Feed: pawn slots
// ----------------------------------------------------------------

void FeedPawnSlots(object oPC, int nToken)
{
    json jSlots = GetLocalJson(oPC, PAWN_LVAR_SLOTS);
    int  nFilled = JsonGetLength(jSlots);

    int i;
    for(i = 0; i < PAWN_SLOT_COUNT; i++)
    {
        string sImg = PAWN_BIND_SLOT_IMG + IntToString(i);
        string sTip = PAWN_BIND_SLOT_TIP + IntToString(i);
        if(i < nFilled)
        {
            json jSlot   = JsonArrayGet(jSlots, i);
            string sIcon = JsonGetString(JsonObjectGet(jSlot, "icon"));
            string sName = JsonGetString(JsonObjectGet(jSlot, "name"));
            int    nLoan = JsonGetInt   (JsonObjectGet(jSlot, "loan"));
            NuiSetBind(oPC, nToken, sImg, JsonString(sIcon));
            NuiSetBind(oPC, nToken, sTip, JsonString(sName + " (" + IntToString(nLoan) + " sz)"));
        }
        else
        {
            NuiSetBind(oPC, nToken, sImg, JsonString("ir_barter"));
            NuiSetBind(oPC, nToken, sTip, JsonString("Puste gniazdo — kliknij, by wybrać przedmiot"));
        }
    }
}

void FeedPawnOffer(object oPC, int nToken)
{
    int nTotal = PawnTotalOffer(oPC);
    int nFilled = JsonGetLength(GetLocalJson(oPC, PAWN_LVAR_SLOTS));

    string sOffer = (nFilled == 0) ? "Łączna oferta: — sz"
                                   : "Łączna oferta: " + IntToString(nTotal) + " sz";
    NuiSetBind(oPC, nToken, PAWN_BIND_OFFER_LBL,   JsonString(sOffer));
    NuiSetBind(oPC, nToken, PAWN_BIND_CONFIRM_ENA, JsonBool(nFilled > 0));
}

// ----------------------------------------------------------------
// Execute pawn: drain slots → DB, give gold, return to browse
// ----------------------------------------------------------------

void PawnExecute(object oPC, int nToken)
{
    json jSlots = GetLocalJson(oPC, PAWN_LVAR_SLOTS);
    int  nCount = JsonGetLength(jSlots);
    if(nCount == 0) return;

    int nTotalGold = 0;
    int i;
    for(i = 0; i < nCount; i++)
    {
        json   jSlot   = JsonArrayGet(jSlots, i);
        json   jItemJson = JsonObjectGet(jSlot, "item_json");
        string sName   = JsonGetString(JsonObjectGet(jSlot, "name"));
        int    nLoan   = JsonGetInt   (JsonObjectGet(jSlot, "loan"));

        PawnInsert(GetObjectUUID(oPC), jItemJson, sName, nLoan);
        nTotalGold += nLoan;
    }

    GiveGoldToCreature(oPC, nTotalGold);
    SetLocalJson(oPC, PAWN_LVAR_SLOTS, JsonArray());

    SendMessageToPC(oPC, "[Lombard] Zastawiono " + IntToString(nCount) + " przedmiot(ów). Otrzymano: " + IntToString(nTotalGold) + " sz.");
    FloatingTextStringOnCreature(PAWN_FLAVOR_CONFIRM, oPC, FALSE);

    SwapToBrowseView(oPC, nToken);
}

// ----------------------------------------------------------------
// Redeem an item from browse view
// ----------------------------------------------------------------

void PawnHandleRedeem(object oPC, int nToken, int nId)
{
    if(nId <= 0) return;

    json jItem = PawnGetItem(nId);
    if(JsonGetType(jItem) == JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Lombard] Nie znaleziono zastawu.");
        return;
    }

    int nCost = JsonGetInt(JsonObjectGet(jItem, "redeem_cost"));
    if(GetGold(oPC) < nCost)
    {
        SendMessageToPC(oPC, "[Lombard] Za mało złota. Potrzeba: " + IntToString(nCost) + " sz.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(nCost, oPC, TRUE));

    json jItemJson = JsonObjectGet(jItem, "item_json");
    JsonToObject(jItemJson, GetLocation(oPC), oPC, TRUE);

    PawnMarkRedeemed(nId);

    string sName = JsonGetString(JsonObjectGet(jItem, "item_name"));
    SendMessageToPC(oPC, "[Lombard] Wykupiono: " + sName + ". Zapłacono: " + IntToString(nCost) + " sz.");
    FloatingTextStringOnCreature(PAWN_FLAVOR_REDEEMED, oPC, FALSE);

    SetLocalInt(oPC, PAWN_LVAR_SEL_ID, 0);
    FeedBrowseList(oPC, nToken);
}

// ----------------------------------------------------------------
// Slot click in pawn view
// ----------------------------------------------------------------

void PawnHandleSlotClick(object oPC, int nToken, int nSlotIdx)
{
    if(nSlotIdx < 0 || nSlotIdx >= PAWN_SLOT_COUNT) return;

    json jSlots = GetLocalJson(oPC, PAWN_LVAR_SLOTS);
    int  nFilled = JsonGetLength(jSlots);

    if(nSlotIdx < nFilled)
    {
        // Filled slot: return item to inventory
        json jSlot     = JsonArrayGet(jSlots, nSlotIdx);
        json jItemJson = JsonObjectGet(jSlot, "item_json");
        JsonToObject(jItemJson, GetLocation(oPC), oPC, TRUE);

        // Remove from array
        json jNew = JsonArray();
        int i;
        for(i = 0; i < nFilled; i++)
        {
            if(i != nSlotIdx)
                jNew = JsonArrayInsert(jNew, JsonArrayGet(jSlots, i));
        }
        SetLocalJson(oPC, PAWN_LVAR_SLOTS, jNew);
        FeedPawnSlots(oPC, nToken);
        FeedPawnOffer(oPC, nToken);
    }
    else if(nFilled < PAWN_SLOT_COUNT)
    {
        // Check active pawn limit
        int nActive = PawnCountActive(GetObjectUUID(oPC)) + nFilled;
        if(nActive >= PAWN_MAX_ACTIVE)
        {
            SendMessageToPC(oPC, "[Lombard] Masz zbyt wiele aktywnych zastawów (" + IntToString(PAWN_MAX_ACTIVE) + " maks.).");
            return;
        }
        // Enter targeting mode so player can click an item
        SetLocalInt(oPC, PAWN_LVAR_TARGET_IDX, nFilled);
        NuiSetBind(oPC, nToken, PAWN_BIND_CONFIRM_ENA, JsonBool(FALSE));
        EnterTargetingMode(oPC, OBJECT_TYPE_ITEM);
        SendMessageToPC(oPC, "[Lombard] Kliknij przedmiot z ekwipunku, by go zastawić.");
    }
}

// ----------------------------------------------------------------
// Called from sys_on_target.nss when targeting mode resolves
// ----------------------------------------------------------------

void PawnOnPlayerTarget(object oPC)
{
    int nToken = NuiFindWindow(oPC, PAWN_WINDOW);
    if(nToken == 0) return;

    object oItem = GetTargetingModeSelectedObject();

    // Re-enable confirm regardless of outcome
    int nFilled = JsonGetLength(GetLocalJson(oPC, PAWN_LVAR_SLOTS));
    NuiSetBind(oPC, nToken, PAWN_BIND_CONFIRM_ENA, JsonBool(nFilled > 0));

    if(!GetIsObjectValid(oItem) || GetItemPossessor(oItem) != oPC)
    {
        SendMessageToPC(oPC, "[Lombard] Możesz zastawiać tylko przedmioty ze swojego ekwipunku.");
        return;
    }

    if(GetItemCursedFlag(oItem))
    {
        SendMessageToPC(oPC, "[Lombard] Zastawnik spluwia. „Przeklętych rzeczy nie przyjmuję."");
        return;
    }

    if(GetBaseItemType(oItem) == BASE_ITEM_GOLD)
    {
        SendMessageToPC(oPC, "[Lombard] Złota nie zastawia się u zastawnika.");
        return;
    }

    int nLoan = PawnCalcLoan(oItem);
    if(nLoan <= 0)
    {
        SendMessageToPC(oPC, "[Lombard] Ten przedmiot nie ma żadnej wartości.");
        return;
    }

    // Serialize and store in slot
    json jSerial = ObjectToJson(oItem, TRUE);
    string sName = GetName(oItem);
    string sIcon = PawnItemIcon(oItem);

    json jSlot = JsonObject();
    jSlot = JsonObjectSet(jSlot, "item_json", jSerial);
    jSlot = JsonObjectSet(jSlot, "name",      JsonString(sName));
    jSlot = JsonObjectSet(jSlot, "icon",      JsonString(sIcon));
    jSlot = JsonObjectSet(jSlot, "loan",      JsonInt   (nLoan));

    json jSlots = GetLocalJson(oPC, PAWN_LVAR_SLOTS);
    jSlots = JsonArrayInsert(jSlots, jSlot);
    SetLocalJson(oPC, PAWN_LVAR_SLOTS, jSlots);

    // Remove from inventory (item now lives only in the JSON)
    DestroyObject(oItem);

    FeedPawnSlots(oPC, nToken);
    FeedPawnOffer(oPC, nToken);
}

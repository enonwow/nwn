// lib_bnt.nss — Bounty Contracts: UI builders, feed functions, game-logic handlers.
#include "lib_bnt_def"

// ============================================================
// Internal forward declarations
// ============================================================
json BntBuildBoardView(object oPC);
json BntBuildActiveView(object oPC);
json BntBuildMineView(object oPC);
json BntBuildPostView(object oPC);

// ============================================================
// Shared helpers
// ============================================================

// Top tab bar shared across all views
json BntBuildTabBar(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 28.0);
    float fBtnW = GetNuiScaleDimension(oPC, 140.0);

    json jBoard = NuiButton(JsonString("Tablica"));
    jBoard = NuiId(jBoard, BNT_BTN_TAB_BOARD);
    jBoard = NuiWidth(jBoard, fBtnW);
    jBoard = NuiHeight(jBoard, fBtnH);

    json jActive = NuiButton(JsonString("Kontrakt"));
    jActive = NuiId(jActive, BNT_BTN_TAB_ACTIVE);
    jActive = NuiWidth(jActive, fBtnW);
    jActive = NuiHeight(jActive, fBtnH);

    json jMine = NuiButton(JsonString("Moje zlecenia"));
    jMine = NuiId(jMine, BNT_BTN_TAB_MINE);
    jMine = NuiWidth(jMine, fBtnW);
    jMine = NuiHeight(jMine, fBtnH);

    json jPost = NuiButton(JsonString("Nowy kontrakt"));
    jPost = NuiId(jPost, BNT_BTN_TAB_POST);
    jPost = NuiWidth(jPost, fBtnW);
    jPost = NuiHeight(jPost, fBtnH);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jBoard);
    jRow = JsonArrayInsert(jRow, jActive);
    jRow = JsonArrayInsert(jRow, jMine);
    jRow = JsonArrayInsert(jRow, jPost);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

// ============================================================
// Board view
// ============================================================

json BntBuildBoardView(object oPC)
{
    float fRowH     = GetNuiScaleDimension(oPC, 26.0);
    float fListH    = GetNuiScaleDimension(oPC, 220.0);
    float fDetailH  = GetNuiScaleDimension(oPC, 110.0);
    float fBtnH     = GetNuiScaleDimension(oPC, 28.0);
    float fRewardW  = GetNuiScaleDimension(oPC, 90.0);
    float fPosterW  = GetNuiScaleDimension(oPC, 120.0);
    float fExpW     = GetNuiScaleDimension(oPC, 50.0);

    // -- List row template --
    json jTargetLbl = NuiLabel(NuiBind(BNT_BIND_BD_TARGET),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTargetLbl = NuiStyleForegroundColor(jTargetLbl, NuiBind(BNT_BIND_BD_COLOR));

    json jRewardLbl = NuiLabel(NuiBind(BNT_BIND_BD_REWARD),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jRewardLbl = NuiWidth(jRewardLbl, fRewardW);
    jRewardLbl = NuiStyleForegroundColor(jRewardLbl, NuiBind(BNT_BIND_BD_COLOR));

    json jPosterLbl = NuiLabel(NuiBind(BNT_BIND_BD_POSTER),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jPosterLbl = NuiWidth(jPosterLbl, fPosterW);
    jPosterLbl = NuiStyleForegroundColor(jPosterLbl, NuiBind(BNT_BIND_BD_COLOR));

    json jExpLbl = NuiLabel(NuiBind(BNT_BIND_BD_EXP),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jExpLbl = NuiWidth(jExpLbl, fExpW);
    jExpLbl = NuiStyleForegroundColor(jExpLbl, NuiBind(BNT_BIND_BD_COLOR));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, jTargetLbl);
    jCellRow = JsonArrayInsert(jCellRow, jRewardLbl);
    jCellRow = JsonArrayInsert(jCellRow, jPosterLbl);
    jCellRow = JsonArrayInsert(jCellRow, jExpLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, BNT_BTN_BD_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(BNT_BIND_BD_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(BNT_BIND_BD_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // -- Detail panel --
    json jDetail = NuiGroup(NuiText(NuiBind(BNT_BIND_BD_DETAIL), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jDetail = NuiHeight(jDetail, fDetailH);

    // -- Bottom row --
    json jAcceptBtn = NuiButton(JsonString("Przyjmij kontrakt"));
    jAcceptBtn = NuiId(jAcceptBtn, BNT_BTN_ACCEPT);
    jAcceptBtn = NuiEnabled(jAcceptBtn, NuiBind(BNT_BIND_ACCEPT_ENA));
    jAcceptBtn = NuiWidth(jAcceptBtn, GetNuiScaleDimension(oPC, 180.0));
    jAcceptBtn = NuiHeight(jAcceptBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jAcceptBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, BntBuildTabBar(oPC));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, jDetail);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    return NuiCol(jCol);
}

// ============================================================
// Active-contract view
// ============================================================

json BntBuildActiveView(object oPC)
{
    float fBtnH    = GetNuiScaleDimension(oPC, 28.0);
    float fDescH   = GetNuiScaleDimension(oPC, 200.0);
    float fLabelH  = GetNuiScaleDimension(oPC, 24.0);

    json jHeader = NuiLabel(NuiBind(BNT_BIND_ACT_HEADER),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHeader = NuiHeight(jHeader, GetNuiScaleDimension(oPC, 32.0));

    // Info rows
    json jTargetRow = JsonArray();
    json jTargetKey = NuiLabel(JsonString("Cel:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTargetKey = NuiWidth(jTargetKey, GetNuiScaleDimension(oPC, 100.0));
    jTargetKey = NuiHeight(jTargetKey, fLabelH);
    json jTargetVal = NuiLabel(NuiBind(BNT_BIND_ACT_TARGET),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTargetVal = NuiHeight(jTargetVal, fLabelH);
    jTargetRow = JsonArrayInsert(jTargetRow, jTargetKey);
    jTargetRow = JsonArrayInsert(jTargetRow, jTargetVal);

    json jRewardRow = JsonArray();
    json jRewardKey = NuiLabel(JsonString("Nagroda:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRewardKey = NuiWidth(jRewardKey, GetNuiScaleDimension(oPC, 100.0));
    jRewardKey = NuiHeight(jRewardKey, fLabelH);
    json jRewardVal = NuiLabel(NuiBind(BNT_BIND_ACT_REWARD),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRewardVal = NuiHeight(jRewardVal, fLabelH);
    jRewardVal = NuiStyleForegroundColor(jRewardVal, NuiColor(220, 180, 60));
    jRewardRow = JsonArrayInsert(jRewardRow, jRewardKey);
    jRewardRow = JsonArrayInsert(jRewardRow, jRewardVal);

    json jPosterRow = JsonArray();
    json jPosterKey = NuiLabel(JsonString("Zleceniodawca:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jPosterKey = NuiWidth(jPosterKey, GetNuiScaleDimension(oPC, 100.0));
    jPosterKey = NuiHeight(jPosterKey, fLabelH);
    json jPosterVal = NuiLabel(NuiBind(BNT_BIND_ACT_POSTER),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jPosterVal = NuiHeight(jPosterVal, fLabelH);
    jPosterRow = JsonArrayInsert(jPosterRow, jPosterKey);
    jPosterRow = JsonArrayInsert(jPosterRow, jPosterVal);

    json jExpRow = JsonArray();
    json jExpKey = NuiLabel(JsonString("Wygasa:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jExpKey = NuiWidth(jExpKey, GetNuiScaleDimension(oPC, 100.0));
    jExpKey = NuiHeight(jExpKey, fLabelH);
    json jExpVal = NuiLabel(NuiBind(BNT_BIND_ACT_EXP),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jExpVal = NuiHeight(jExpVal, fLabelH);
    jExpRow = JsonArrayInsert(jExpRow, jExpKey);
    jExpRow = JsonArrayInsert(jExpRow, jExpVal);

    // Description
    json jDescGrp = NuiGroup(NuiText(NuiBind(BNT_BIND_ACT_DESC), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jDescGrp = NuiHeight(jDescGrp, fDescH);

    // Buttons
    json jClaimBtn = NuiButton(JsonString("Odbierz nagrode"));
    jClaimBtn = NuiId(jClaimBtn, BNT_BTN_CLAIM);
    jClaimBtn = NuiEnabled(jClaimBtn, NuiBind(BNT_BIND_CLAIM_ENA));
    jClaimBtn = NuiWidth(jClaimBtn, GetNuiScaleDimension(oPC, 180.0));
    jClaimBtn = NuiHeight(jClaimBtn, fBtnH);
    jClaimBtn = NuiTooltip(jClaimBtn,
        JsonString("Odbierz nagrode po wykonaniu kontraktu. Tylko dla celow NPC."));

    json jAbandonBtn = NuiButton(JsonString("Zrezygnuj"));
    jAbandonBtn = NuiId(jAbandonBtn, BNT_BTN_ABANDON);
    jAbandonBtn = NuiWidth(jAbandonBtn, GetNuiScaleDimension(oPC, 110.0));
    jAbandonBtn = NuiHeight(jAbandonBtn, fBtnH);
    jAbandonBtn = NuiTooltip(jAbandonBtn,
        JsonString("Zwolnij kontrakt — wróci na tablice. Nagroda nie zostaje zwrocona."));

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jAbandonBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jClaimBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, BntBuildTabBar(oPC));
    jCol = JsonArrayInsert(jCol, jHeader);
    jCol = JsonArrayInsert(jCol, NuiRow(jTargetRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jRewardRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jPosterRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jExpRow));
    jCol = JsonArrayInsert(jCol, jDescGrp);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    return NuiCol(jCol);
}

// ============================================================
// My-contracts view
// ============================================================

json BntBuildMineView(object oPC)
{
    float fRowH    = GetNuiScaleDimension(oPC, 26.0);
    float fListH   = GetNuiScaleDimension(oPC, 320.0);
    float fBtnH    = GetNuiScaleDimension(oPC, 28.0);
    float fRewardW = GetNuiScaleDimension(oPC, 90.0);
    float fStateW  = GetNuiScaleDimension(oPC, 80.0);
    float fHunterW = GetNuiScaleDimension(oPC, 130.0);

    json jTargetLbl = NuiLabel(NuiBind(BNT_BIND_MINE_TARGET),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTargetLbl = NuiStyleForegroundColor(jTargetLbl, NuiBind(BNT_BIND_MINE_COLOR));

    json jRewardLbl = NuiLabel(NuiBind(BNT_BIND_MINE_REWARD),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jRewardLbl = NuiWidth(jRewardLbl, fRewardW);
    jRewardLbl = NuiStyleForegroundColor(jRewardLbl, NuiBind(BNT_BIND_MINE_COLOR));

    json jStateLbl = NuiLabel(NuiBind(BNT_BIND_MINE_STATE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStateLbl = NuiWidth(jStateLbl, fStateW);
    jStateLbl = NuiStyleForegroundColor(jStateLbl, NuiBind(BNT_BIND_MINE_COLOR));

    json jHunterLbl = NuiLabel(NuiBind(BNT_BIND_MINE_HUNTER),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHunterLbl = NuiWidth(jHunterLbl, fHunterW);
    jHunterLbl = NuiStyleForegroundColor(jHunterLbl, NuiBind(BNT_BIND_MINE_COLOR));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, jTargetLbl);
    jCellRow = JsonArrayInsert(jCellRow, jRewardLbl);
    jCellRow = JsonArrayInsert(jCellRow, jStateLbl);
    jCellRow = JsonArrayInsert(jCellRow, jHunterLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, BNT_BTN_MINE_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(BNT_BIND_MINE_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(BNT_BIND_MINE_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    json jCancelBtn = NuiButton(JsonString("Anuluj wybrany"));
    jCancelBtn = NuiId(jCancelBtn, BNT_BTN_CANCEL_OWN);
    jCancelBtn = NuiEnabled(jCancelBtn, NuiBind(BNT_BIND_CANCEL_ENA));
    jCancelBtn = NuiWidth(jCancelBtn, GetNuiScaleDimension(oPC, 160.0));
    jCancelBtn = NuiHeight(jCancelBtn, fBtnH);
    jCancelBtn = NuiTooltip(jCancelBtn,
        JsonString("Anuluje kontrakt. Zwrot nagrody tylko jesli nikt go jeszcze nie przyjal."));

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jCancelBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, BntBuildTabBar(oPC));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    return NuiCol(jCol);
}

// ============================================================
// Post-new-contract view
// ============================================================

json BntBuildPostView(object oPC)
{
    float fBtnH   = GetNuiScaleDimension(oPC, 28.0);
    float fFieldH = GetNuiScaleDimension(oPC, 28.0);
    float fDescH  = GetNuiScaleDimension(oPC, 140.0);
    float fLblW   = GetNuiScaleDimension(oPC, 130.0);

    // Target name row
    json jTargetLbl = NuiLabel(JsonString("Cel (imie):"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTargetLbl = NuiWidth(jTargetLbl, fLblW);
    jTargetLbl = NuiHeight(jTargetLbl, fFieldH);

    json jTargetField = NuiTextEdit(JsonString(""), NuiBind(BNT_BIND_POST_TARGET),
        BNT_MAX_TARGET_NAME, FALSE);
    jTargetField = NuiHeight(jTargetField, fFieldH);

    json jTargetRow = JsonArray();
    jTargetRow = JsonArrayInsert(jTargetRow, jTargetLbl);
    jTargetRow = JsonArrayInsert(jTargetRow, jTargetField);

    // PC checkbox row
    json jIsPcChk = NuiCheck(JsonString("Cel jest graczem (PC)"), NuiBind(BNT_BIND_POST_IS_PC));
    jIsPcChk = NuiHeight(jIsPcChk, fFieldH);
    jIsPcChk = NuiTooltip(jIsPcChk,
        JsonString("Zaznacz jesli cel to gracz. System automatycznie wyplaci nagrode po smierci."));

    json jPcRow = JsonArray();
    json jPcSpacer = NuiSpacer();
    jPcSpacer = NuiWidth(jPcSpacer, fLblW);
    jPcRow = JsonArrayInsert(jPcRow, jPcSpacer);
    jPcRow = JsonArrayInsert(jPcRow, jIsPcChk);

    // Reward row
    json jRewardLbl = NuiLabel(JsonString("Nagroda (zloto):"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRewardLbl = NuiWidth(jRewardLbl, fLblW);
    jRewardLbl = NuiHeight(jRewardLbl, fFieldH);

    json jRewardField = NuiTextEdit(JsonString(""), NuiBind(BNT_BIND_POST_REWARD), 8, FALSE);
    jRewardField = NuiWidth(jRewardField, GetNuiScaleDimension(oPC, 140.0));
    jRewardField = NuiHeight(jRewardField, fFieldH);

    json jRewardRow = JsonArray();
    jRewardRow = JsonArrayInsert(jRewardRow, jRewardLbl);
    jRewardRow = JsonArrayInsert(jRewardRow, jRewardField);

    // Description label + multiline field
    json jDescLbl = NuiLabel(JsonString("Opis / poszlaki:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDescLbl = NuiHeight(jDescLbl, GetNuiScaleDimension(oPC, 22.0));

    json jDescField = NuiTextEdit(JsonString(""), NuiBind(BNT_BIND_POST_DESC),
        BNT_MAX_DESC, TRUE);
    jDescField = NuiHeight(jDescField, fDescH);

    // Status line (validation feedback, Polish)
    json jStatusLbl = NuiLabel(NuiBind(BNT_BIND_POST_STATUS),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiHeight(jStatusLbl, GetNuiScaleDimension(oPC, 22.0));
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiColor(220, 80, 80));

    // Submit button
    json jSubmitBtn = NuiButton(JsonString("Zloz kontrakt"));
    jSubmitBtn = NuiId(jSubmitBtn, BNT_BTN_SUBMIT);
    jSubmitBtn = NuiEnabled(jSubmitBtn, NuiBind(BNT_BIND_POST_SUB_ENA));
    jSubmitBtn = NuiWidth(jSubmitBtn, GetNuiScaleDimension(oPC, 160.0));
    jSubmitBtn = NuiHeight(jSubmitBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jStatusLbl);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jSubmitBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, BntBuildTabBar(oPC));
    jCol = JsonArrayInsert(jCol, NuiRow(jTargetRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jPcRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jRewardRow));
    jCol = JsonArrayInsert(jCol, jDescLbl);
    jCol = JsonArrayInsert(jCol, jDescField);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    return NuiCol(jCol);
}

// ============================================================
// Window creation
// ============================================================

void BntOpenWindow(object oPC)
{
    BntExpireContracts();

    if(NuiFindWindow(oPC, BNT_WINDOW) != 0)
    {
        BntSwapToBoard(oPC, NuiFindWindow(oPC, BNT_WINDOW));
        return;
    }

    float fW  = GetNuiScaleDimension(oPC, BNT_W);
    float fH  = GetNuiScaleDimension(oPC, BNT_H);
    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    json jGeom = NuiRect(fCX, fCY, fW, fH);

    // Close button top-right
    float fBtnH = GetNuiScaleDimension(oPC, 28.0);
    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, BNT_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 28.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTitleRow = JsonArray();
    jTitleRow = JsonArrayInsert(jTitleRow, NuiSpacer());
    jTitleRow = JsonArrayInsert(jTitleRow, jCloseBtn);

    json jSwapGrp = NuiGroup(BntBuildBoardView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, BNT_GRP_SWAP);

    json jRootCol = JsonArray();
    jRootCol = JsonArrayInsert(jRootCol, NuiRow(jTitleRow));
    jRootCol = JsonArrayInsert(jRootCol, jSwapGrp);

    json jWin = NuiWindow(NuiCol(jRootCol),
        JsonString("Tablica Kontraktów"),
        NuiBind(BNT_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, BNT_WINDOW, BNT_EV_SCRIPT);
    NuiSetBind(oPC, nToken, BNT_WIN_GEOM, jGeom);

    BntSwapToBoard(oPC, nToken);
}

// ============================================================
// View swaps
// ============================================================

void BntSwapToBoard(object oPC, int nToken)
{
    DeleteLocalInt(oPC, BNT_LVAR_SEL_ID);
    NuiSetGroupLayout(oPC, nToken, BNT_GRP_SWAP, BntBuildBoardView(oPC));
    BntFeedBoard(oPC, nToken);
}

void BntSwapToActive(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, BNT_GRP_SWAP, BntBuildActiveView(oPC));
    BntFeedActive(oPC, nToken);
}

void BntSwapToMine(object oPC, int nToken)
{
    DeleteLocalInt(oPC, BNT_LVAR_MINE_SEL);
    NuiSetGroupLayout(oPC, nToken, BNT_GRP_SWAP, BntBuildMineView(oPC));
    BntFeedMine(oPC, nToken);
}

void BntSwapToPost(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, BNT_GRP_SWAP, BntBuildPostView(oPC));
    BntFeedPost(oPC, nToken);
}

// ============================================================
// Feed — Board
// ============================================================

void BntFeedBoard(object oPC, int nToken)
{
    json jContracts = BntGetOpenContracts();
    int nCount = JsonGetLength(jContracts);

    json jTargets  = JsonArray();
    json jRewards  = JsonArray();
    json jPosters  = JsonArray();
    json jExps     = JsonArray();
    json jColors   = JsonArray();
    json jEncs     = JsonArray();

    json jGold   = NuiColor(220, 180, 60);
    json jWhite  = NuiColor(220, 200, 170);
    int nSelId   = GetLocalInt(oPC, BNT_LVAR_SEL_ID);

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow   = JsonArrayGet(jContracts, i);
        int  nId    = JsonGetInt   (JsonObjectGet(jRow, "id"));
        int  nRew   = JsonGetInt   (JsonObjectGet(jRow, "reward"));
        int  nExp   = JsonGetInt   (JsonObjectGet(jRow, "expires_at"));
        string sTgt = JsonGetString(JsonObjectGet(jRow, "target_name"));
        string sPost= JsonGetString(JsonObjectGet(jRow, "poster_name"));

        jTargets = JsonArrayInsert(jTargets, JsonString(sTgt));
        jRewards = JsonArrayInsert(jRewards, JsonString(IntToString(nRew) + " zl"));
        jPosters = JsonArrayInsert(jPosters, JsonString(sPost));
        jExps    = JsonArrayInsert(jExps,    JsonString(BntDaysLeft(nExp)));
        jColors  = JsonArrayInsert(jColors,  (nId == nSelId) ? jGold : jWhite);
        jEncs    = JsonArrayInsert(jEncs,    JsonBool(nId == nSelId));
    }

    NuiSetBind(oPC, nToken, BNT_BIND_BD_TARGET, jTargets);
    NuiSetBind(oPC, nToken, BNT_BIND_BD_REWARD, jRewards);
    NuiSetBind(oPC, nToken, BNT_BIND_BD_POSTER, jPosters);
    NuiSetBind(oPC, nToken, BNT_BIND_BD_EXP,    jExps);
    NuiSetBind(oPC, nToken, BNT_BIND_BD_COLOR,  jColors);
    NuiSetBind(oPC, nToken, BNT_BIND_BD_ENC,    jEncs);
    NuiSetBind(oPC, nToken, BNT_BIND_BD_COUNT,  JsonInt(nCount));

    // detail + accept button state
    if(nSelId > 0 && nCount > 0)
    {
        // Find the selected row's description
        for(i = 0; i < nCount; i++)
        {
            json jRow = JsonArrayGet(jContracts, i);
            if(JsonGetInt(JsonObjectGet(jRow, "id")) == nSelId)
            {
                string sDesc = JsonGetString(JsonObjectGet(jRow, "description"));
                string sTgt  = JsonGetString(JsonObjectGet(jRow, "target_name"));
                string sPost = JsonGetString(JsonObjectGet(jRow, "poster_name"));
                int    nRew  = JsonGetInt   (JsonObjectGet(jRow, "reward"));
                int    nExp  = JsonGetInt   (JsonObjectGet(jRow, "expires_at"));

                string sDetail = "Cel: " + sTgt + "\n"
                    + "Nagroda: " + IntToString(nRew) + " zlota\n"
                    + "Zleceniodawca: " + sPost + "\n"
                    + "Wygasa: " + BntFormatDate(nExp) + "\n\n"
                    + (sDesc != "" ? sDesc : "(Brak opisu.)");
                NuiSetBind(oPC, nToken, BNT_BIND_BD_DETAIL, JsonString(sDetail));
                break;
            }
        }
        // Allow accept only if hunter has no active contract
        json jActive = BntGetActiveContract(oPC);
        int bCanAccept = (JsonGetType(jActive) == JSON_TYPE_NULL);
        NuiSetBind(oPC, nToken, BNT_BIND_ACCEPT_ENA, JsonBool(bCanAccept));
    }
    else
    {
        NuiSetBind(oPC, nToken, BNT_BIND_BD_DETAIL,
            JsonString("Wybierz zlecenie z listy aby zobaczyc szczegoly.\n\n"
                "Krwawa moneta nie zna litosci — tylko skutecznosc."));
        NuiSetBind(oPC, nToken, BNT_BIND_ACCEPT_ENA, JsonBool(FALSE));
    }
}

// ============================================================
// Feed — Active contract
// ============================================================

void BntFeedActive(object oPC, int nToken)
{
    json jActive = BntGetActiveContract(oPC);

    if(JsonGetType(jActive) == JSON_TYPE_NULL)
    {
        NuiSetBind(oPC, nToken, BNT_BIND_ACT_HEADER,
            JsonString("Brak aktywnego kontraktu"));
        NuiSetBind(oPC, nToken, BNT_BIND_ACT_TARGET, JsonString("—"));
        NuiSetBind(oPC, nToken, BNT_BIND_ACT_REWARD, JsonString("—"));
        NuiSetBind(oPC, nToken, BNT_BIND_ACT_POSTER, JsonString("—"));
        NuiSetBind(oPC, nToken, BNT_BIND_ACT_EXP,    JsonString("—"));
        NuiSetBind(oPC, nToken, BNT_BIND_ACT_DESC,
            JsonString("Przejdz na Tablice i przyjmij kontrakt.\n\n"
                "Sztylet w mroku nie zna koloru zlota — tylko smak krwi."));
        NuiSetBind(oPC, nToken, BNT_BIND_CLAIM_ENA, JsonBool(FALSE));
        return;
    }

    string sTgt  = JsonGetString(JsonObjectGet(jActive, "target_name"));
    string sTuid = JsonGetString(JsonObjectGet(jActive, "target_uuid"));
    int    nRew  = JsonGetInt   (JsonObjectGet(jActive, "reward"));
    string sPost = JsonGetString(JsonObjectGet(jActive, "poster_name"));
    int    nExp  = JsonGetInt   (JsonObjectGet(jActive, "expires_at"));
    string sDesc = JsonGetString(JsonObjectGet(jActive, "description"));
    int    nId   = JsonGetInt   (JsonObjectGet(jActive, "id"));

    NuiSetBind(oPC, nToken, BNT_BIND_ACT_HEADER,
        JsonString("Kontrakt aktywny: " + sTgt));
    NuiSetBind(oPC, nToken, BNT_BIND_ACT_TARGET, JsonString(sTgt));
    NuiSetBind(oPC, nToken, BNT_BIND_ACT_REWARD,
        JsonString(IntToString(nRew) + " zlota"));
    NuiSetBind(oPC, nToken, BNT_BIND_ACT_POSTER, JsonString(sPost));
    NuiSetBind(oPC, nToken, BNT_BIND_ACT_EXP,
        JsonString(BntFormatDate(nExp) + " (" + BntDaysLeft(nExp) + " pozostalo)"));

    // PC-target contracts are paid out automatically on death — no manual claim
    int bIsPC = (sTuid != "");
    string sDescFull = (sDesc != "" ? sDesc : "(Brak opisu.)");
    if(bIsPC)
        sDescFull = sDescFull + "\n\n[Cel-PC: nagroda wyplaci sie automatycznie po smierci celu.]";

    NuiSetBind(oPC, nToken, BNT_BIND_ACT_DESC, JsonString(sDescFull));

    // Manual claim only for NPC contracts
    NuiSetBind(oPC, nToken, BNT_BIND_CLAIM_ENA, JsonBool(!bIsPC));

    SetLocalInt(oPC, BNT_LVAR_SEL_ID, nId);
}

// ============================================================
// Feed — My contracts
// ============================================================

void BntFeedMine(object oPC, int nToken)
{
    json jMine  = BntGetMyPostedContracts(oPC);
    int  nCount = JsonGetLength(jMine);

    json jTargets  = JsonArray();
    json jRewards  = JsonArray();
    json jStates   = JsonArray();
    json jHunters  = JsonArray();
    json jColors   = JsonArray();
    json jEncs     = JsonArray();

    json jGold  = NuiColor(220, 180, 60);
    json jWhite = NuiColor(220, 200, 170);
    json jRed   = NuiColor(220, 100, 80);
    int nSelId  = GetLocalInt(oPC, BNT_LVAR_MINE_SEL);

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow = JsonArrayGet(jMine, i);
        int  nId  = JsonGetInt   (JsonObjectGet(jRow, "id"));
        int  nSt  = JsonGetInt   (JsonObjectGet(jRow, "state"));

        jTargets = JsonArrayInsert(jTargets, JsonString(JsonGetString(JsonObjectGet(jRow, "target_name"))));
        jRewards = JsonArrayInsert(jRewards, JsonString(IntToString(JsonGetInt(JsonObjectGet(jRow, "reward"))) + " zl"));
        jStates  = JsonArrayInsert(jStates,  JsonString(BntStateName(nSt)));
        jHunters = JsonArrayInsert(jHunters, JsonString(
            nSt == BNT_STATE_ACCEPTED
                ? JsonGetString(JsonObjectGet(jRow, "hunter_name"))
                : "—"));
        jColors  = JsonArrayInsert(jColors, (nId == nSelId) ? jGold : jWhite);
        jEncs    = JsonArrayInsert(jEncs,   JsonBool(nId == nSelId));
    }

    NuiSetBind(oPC, nToken, BNT_BIND_MINE_TARGET, jTargets);
    NuiSetBind(oPC, nToken, BNT_BIND_MINE_REWARD, jRewards);
    NuiSetBind(oPC, nToken, BNT_BIND_MINE_STATE,  jStates);
    NuiSetBind(oPC, nToken, BNT_BIND_MINE_HUNTER, jHunters);
    NuiSetBind(oPC, nToken, BNT_BIND_MINE_COLOR,  jColors);
    NuiSetBind(oPC, nToken, BNT_BIND_MINE_ENC,    jEncs);
    NuiSetBind(oPC, nToken, BNT_BIND_MINE_COUNT,  JsonInt(nCount));
    NuiSetBind(oPC, nToken, BNT_BIND_CANCEL_ENA,  JsonBool(nSelId > 0));
}

// ============================================================
// Feed — Post view
// ============================================================

void BntFeedPost(object oPC, int nToken)
{
    NuiSetBind(oPC, nToken, BNT_BIND_POST_TARGET,  JsonString(""));
    NuiSetBind(oPC, nToken, BNT_BIND_POST_DESC,    JsonString(""));
    NuiSetBind(oPC, nToken, BNT_BIND_POST_REWARD,  JsonString(""));
    NuiSetBind(oPC, nToken, BNT_BIND_POST_IS_PC,   JsonBool(FALSE));
    NuiSetBind(oPC, nToken, BNT_BIND_POST_STATUS,  JsonString(""));
    NuiSetBind(oPC, nToken, BNT_BIND_POST_SUB_ENA, JsonBool(FALSE));

    NuiSetBindWatch(oPC, nToken, BNT_BIND_POST_TARGET,  TRUE);
    NuiSetBindWatch(oPC, nToken, BNT_BIND_POST_REWARD,  TRUE);
}

// ============================================================
// Action handlers
// ============================================================

void BntHandleAccept(object oPC, int nToken)
{
    int nId = GetLocalInt(oPC, BNT_LVAR_SEL_ID);
    if(nId <= 0)
    {
        SendMessageToPC(oPC, "[Kontrakty] Najpierw wybierz zlecenie z listy.");
        return;
    }

    json jActive = BntGetActiveContract(oPC);
    if(JsonGetType(jActive) != JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Kontrakty] Masz juz aktywny kontrakt. Zrezygnuj z niego przed przyjęciem nowego.");
        return;
    }

    if(!BntAcceptContract(oPC, nId))
    {
        SendMessageToPC(oPC, "[Kontrakty] Kontrakt zostal juz przyjety przez kogo innego lub wygasl.");
        BntSwapToBoard(oPC, nToken);
        return;
    }

    SendMessageToPC(oPC, "[Kontrakty] Kontrakt przyjety. Ostrze pragnie krwi.");
    BntSwapToActive(oPC, nToken);
}

void BntHandleClaim(object oPC, int nToken)
{
    json jActive = BntGetActiveContract(oPC);
    if(JsonGetType(jActive) == JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Kontrakty] Brak aktywnego kontraktu.");
        return;
    }

    // Claim only for NPC contracts — PC contracts autopay on death
    string sTuid = JsonGetString(JsonObjectGet(jActive, "target_uuid"));
    if(sTuid != "")
    {
        SendMessageToPC(oPC, "[Kontrakty] Ten kontrakt wyplaci sie automatycznie po smierci gracza-celu.");
        return;
    }

    int nId     = JsonGetInt(JsonObjectGet(jActive, "id"));
    int nReward = BntClaimContract(oPC, nId);
    if(nReward <= 0)
    {
        SendMessageToPC(oPC, "[Kontrakty] Nie mozna odebrac nagrody — kontrakt niedostepny.");
        return;
    }

    GiveGoldToCreature(oPC, nReward);
    SendMessageToPC(oPC,
        "[Kontrakty] Nagroda " + IntToString(nReward) + " zlota odebrana. Krew splynela na zloto.");

    FloatingTextStringOnCreature(
        "Kontrakt ukończony. +" + IntToString(nReward) + " zl", oPC, FALSE);

    BntSwapToBoard(oPC, nToken);
}

void BntHandleAbandon(object oPC, int nToken)
{
    json jActive = BntGetActiveContract(oPC);
    if(JsonGetType(jActive) == JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Kontrakty] Brak aktywnego kontraktu.");
        return;
    }

    BntAbandonContract(oPC);
    SendMessageToPC(oPC, "[Kontrakty] Zrezygnowales z kontraktu. Wrócil na tablice.");
    BntSwapToBoard(oPC, nToken);
}

void BntHandleCancelOwn(object oPC, int nToken)
{
    int nId = GetLocalInt(oPC, BNT_LVAR_MINE_SEL);
    if(nId <= 0)
    {
        SendMessageToPC(oPC, "[Kontrakty] Wybierz kontrakt do anulowania.");
        return;
    }

    int nRefund = BntCancelOwnContract(oPC, nId);

    if(nRefund > 0)
    {
        GiveGoldToCreature(oPC, nRefund);
        SendMessageToPC(oPC,
            "[Kontrakty] Kontrakt anulowany. Zwrócono " + IntToString(nRefund) + " zlota.");
    }
    else
    {
        SendMessageToPC(oPC,
            "[Kontrakty] Kontrakt anulowany. Brak zwrotu — łowca byl juz w terenie.");
    }

    DeleteLocalInt(oPC, BNT_LVAR_MINE_SEL);
    BntFeedMine(oPC, nToken);
}

void BntHandlePost(object oPC, int nToken)
{
    string sTarget  = JsonGetString(NuiGetBind(oPC, nToken, BNT_BIND_POST_TARGET));
    string sDesc    = JsonGetString(NuiGetBind(oPC, nToken, BNT_BIND_POST_DESC));
    string sReward  = JsonGetString(NuiGetBind(oPC, nToken, BNT_BIND_POST_REWARD));
    int    bIsPC    = JsonGetInt   (NuiGetBind(oPC, nToken, BNT_BIND_POST_IS_PC));
    int    nReward  = StringToInt(sReward);

    if(sTarget == "")
    {
        NuiSetBind(oPC, nToken, BNT_BIND_POST_STATUS, JsonString("Podaj imię celu."));
        return;
    }
    if(nReward < BNT_MIN_REWARD)
    {
        NuiSetBind(oPC, nToken, BNT_BIND_POST_STATUS,
            JsonString("Minimalna nagroda: " + IntToString(BNT_MIN_REWARD) + " zlota."));
        return;
    }
    if(GetGold(oPC) < nReward)
    {
        NuiSetBind(oPC, nToken, BNT_BIND_POST_STATUS,
            JsonString("Nie masz wystarczajaco zlota."));
        return;
    }

    string sTargetUuid = "";
    if(bIsPC)
    {
        sTargetUuid = BntFindPlayerUUID(sTarget);
        if(sTargetUuid == "")
        {
            NuiSetBind(oPC, nToken, BNT_BIND_POST_STATUS,
                JsonString("Nie znaleziono gracza o tym imieniu."));
            return;
        }
        if(sTargetUuid == GetObjectUUID(oPC))
        {
            NuiSetBind(oPC, nToken, BNT_BIND_POST_STATUS,
                JsonString("Nie mozesz wystawic nagrody na wlasna glowe."));
            return;
        }
    }

    AssignCommand(oPC, TakeGoldFromCreature(nReward, oPC, TRUE));

    int nId = BntPostContract(oPC, sTarget, sTargetUuid, sDesc, nReward);
    if(nId <= 0)
    {
        GiveGoldToCreature(oPC, nReward);  // rollback
        SendMessageToPC(oPC, "[Kontrakty] Blad zapisu kontraktu.");
        return;
    }

    SendMessageToPC(oPC,
        "[Kontrakty] Kontrakt wystawiony. Nagroda " + IntToString(nReward)
        + " zlota zablokowana az do realizacji lub anulowania.");

    if(bIsPC)
    {
        object oTarget = BntGetPCByUUID(sTargetUuid);
        if(GetIsObjectValid(oTarget))
        {
            SendMessageToPC(oTarget,
                "[Kontrakty] Ktos wystawil kontrakt na twoja glowe. Strzez sie.");
            FloatingTextStringOnCreature("Kontrakt na twoja glowe!", oTarget, FALSE);
        }
    }

    BntSwapToMine(oPC, nToken);
}

// ============================================================
// Validate post form for real-time submit-button enable
// ============================================================

void BntValidatePostForm(object oPC, int nToken)
{
    string sTarget = JsonGetString(NuiGetBind(oPC, nToken, BNT_BIND_POST_TARGET));
    string sReward = JsonGetString(NuiGetBind(oPC, nToken, BNT_BIND_POST_REWARD));
    int    nReward = StringToInt(sReward);
    int    bOk     = (sTarget != "" && nReward >= BNT_MIN_REWARD && GetGold(oPC) >= nReward);
    NuiSetBind(oPC, nToken, BNT_BIND_POST_SUB_ENA, JsonBool(bOk));
}

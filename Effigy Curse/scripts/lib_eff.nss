#include "sql_eff"

void CreateEffigyWindow(object oPC);
void EffFeedTargetList(object oPC, int nToken);
void EffFeedMyEffigies(object oPC, int nToken);
void EffFeedAffectedList(object oPC, int nToken);
void EffRefreshCursePanel(object oPC, int nToken);
void EffSwitchTab(object oPC, int nToken, int nTab);

// ----------------------------------------------------------------
// Window construction
// ----------------------------------------------------------------

json BuildEffTabBar(object oPC)
{
    float fBtnW = GetNuiScaleDimension(oPC, 160.0);
    float fBtnH = GetNuiScaleDimension(oPC, 32.0);

    json jT0 = NuiButton(JsonString("Utwórz Figurkę"));
    jT0 = NuiId(jT0, EFF_BTN_TAB0);
    jT0 = NuiWidth(jT0, fBtnW);
    jT0 = NuiHeight(jT0, fBtnH);

    json jT1 = NuiButton(JsonString("Moje Figurki"));
    jT1 = NuiId(jT1, EFF_BTN_TAB1);
    jT1 = NuiWidth(jT1, fBtnW);
    jT1 = NuiHeight(jT1, fBtnH);

    json jT2 = NuiButton(JsonString("Działające na Mnie"));
    jT2 = NuiId(jT2, EFF_BTN_TAB2);
    jT2 = NuiWidth(jT2, fBtnW);
    jT2 = NuiHeight(jT2, fBtnH);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jT0);
    jRow = JsonArrayInsert(jRow, jT1);
    jRow = JsonArrayInsert(jRow, jT2);
    return NuiRow(jRow);
}

json BuildEffCreateTab(object oPC)
{
    float fRowH   = GetNuiScaleDimension(oPC, 26.0);
    float fListH  = GetNuiScaleDimension(oPC, 260.0);
    float fBtnH   = GetNuiScaleDimension(oPC, 34.0);
    float fSepW   = GetNuiScaleDimension(oPC, 12.0);
    float fHalfW  = GetNuiScaleDimension(oPC, 280.0);
    float fCBtnW  = GetNuiScaleDimension(oPC, 120.0);
    float fCBtnH  = GetNuiScaleDimension(oPC, 60.0);

    // Left: target list
    json jHdrLbl = NuiLabel(JsonString("Wybierz cel:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrLbl = NuiHeight(jHdrLbl, GetNuiScaleDimension(oPC, 22.0));

    json jTgtName = NuiLabel(NuiBind(EFF_BIND_TGT_NAMES),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jTgtBtn  = NuiButton(jTgtName);
    jTgtBtn = NuiId(jTgtBtn, EFF_BTN_TGT_ROW);
    jTgtBtn = NuiHeight(jTgtBtn, fRowH);

    json jTgtRow = JsonArray();
    jTgtRow = JsonArrayInsert(jTgtRow, jTgtBtn);
    json jTgtList = NuiList(NuiRow(jTgtRow), NuiBind(EFF_BIND_TGT_ENC), fRowH);
    jTgtList = NuiHeight(jTgtList, fListH);
    jTgtList = NuiWidth(jTgtList, fHalfW);

    json jSelLbl = NuiLabel(NuiBind(EFF_BIND_TGT_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSelLbl = NuiHeight(jSelLbl, GetNuiScaleDimension(oPC, 22.0));

    json jLeft = JsonArray();
    jLeft = JsonArrayInsert(jLeft, jHdrLbl);
    jLeft = JsonArrayInsert(jLeft, jTgtList);
    jLeft = JsonArrayInsert(jLeft, jSelLbl);
    json jLeftCol = NuiCol(jLeft);

    // Spacer
    json jSpacer = NuiSpacer();
    jSpacer = NuiWidth(jSpacer, fSepW);

    // Right: curse selection + info
    json jCurseHdr = NuiLabel(JsonString("Rodzaj klątwy:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCurseHdr = NuiHeight(jCurseHdr, GetNuiScaleDimension(oPC, 22.0));

    // 4 curse type buttons
    json jC1 = NuiButton(JsonString("Meczarnia"));
    jC1 = NuiId(jC1, EFF_BTN_C1);
    jC1 = NuiWidth(jC1, fCBtnW);
    jC1 = NuiHeight(jC1, fCBtnH);
    jC1 = NuiEnabled(jC1, NuiBind(EFF_BIND_C1_ACTIVE));

    json jC2 = NuiButton(JsonString("Więdnięcie"));
    jC2 = NuiId(jC2, EFF_BTN_C2);
    jC2 = NuiWidth(jC2, fCBtnW);
    jC2 = NuiHeight(jC2, fCBtnH);
    jC2 = NuiEnabled(jC2, NuiBind(EFF_BIND_C2_ACTIVE));

    json jC3 = NuiButton(JsonString("Zaćmienie"));
    jC3 = NuiId(jC3, EFF_BTN_C3);
    jC3 = NuiWidth(jC3, fCBtnW);
    jC3 = NuiHeight(jC3, fCBtnH);
    jC3 = NuiEnabled(jC3, NuiBind(EFF_BIND_C3_ACTIVE));

    json jC4 = NuiButton(JsonString("Otępienie"));
    jC4 = NuiId(jC4, EFF_BTN_C4);
    jC4 = NuiWidth(jC4, fCBtnW);
    jC4 = NuiHeight(jC4, fCBtnH);
    jC4 = NuiEnabled(jC4, NuiBind(EFF_BIND_C4_ACTIVE));

    json jCurseRow1 = JsonArray();
    jCurseRow1 = JsonArrayInsert(jCurseRow1, jC1);
    jCurseRow1 = JsonArrayInsert(jCurseRow1, jC2);
    json jCurseRow2 = JsonArray();
    jCurseRow2 = JsonArrayInsert(jCurseRow2, jC3);
    jCurseRow2 = JsonArrayInsert(jCurseRow2, jC4);

    json jFlavorLbl = NuiLabel(NuiBind(EFF_BIND_FLAVOR_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jFlavorLbl = NuiHeight(jFlavorLbl, GetNuiScaleDimension(oPC, 60.0));

    json jCostLbl = NuiLabel(NuiBind(EFF_BIND_COST_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCostLbl = NuiHeight(jCostLbl, GetNuiScaleDimension(oPC, 24.0));

    json jCreateBtn = NuiButton(JsonString("Utwórz Figurkę"));
    jCreateBtn = NuiId(jCreateBtn, EFF_BTN_CREATE);
    jCreateBtn = NuiHeight(jCreateBtn, fBtnH);
    jCreateBtn = NuiEnabled(jCreateBtn, NuiBind(EFF_BIND_CREATE_ENA));

    json jRight = JsonArray();
    jRight = JsonArrayInsert(jRight, jCurseHdr);
    jRight = JsonArrayInsert(jRight, NuiRow(jCurseRow1));
    jRight = JsonArrayInsert(jRight, NuiRow(jCurseRow2));
    jRight = JsonArrayInsert(jRight, jFlavorLbl);
    jRight = JsonArrayInsert(jRight, jCostLbl);
    jRight = JsonArrayInsert(jRight, jCreateBtn);
    json jRightCol = NuiCol(jRight);
    jRightCol = NuiWidth(jRightCol, fHalfW);

    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jLeftCol);
    jMainRow = JsonArrayInsert(jMainRow, jSpacer);
    jMainRow = JsonArrayInsert(jMainRow, jRightCol);

    json jGroup = NuiGroup(NuiRow(jMainRow), JsonBool(FALSE), JsonInt(NUI_SCROLLBARS_NONE));
    jGroup = NuiVisible(jGroup, NuiBind(EFF_BIND_TAB0_VIS));
    return jGroup;
}

json BuildEffMineTab(object oPC)
{
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fListH = GetNuiScaleDimension(oPC, 300.0);
    float fBtnH  = GetNuiScaleDimension(oPC, 34.0);
    float fTgtW  = GetNuiScaleDimension(oPC, 160.0);
    float fTypeW = GetNuiScaleDimension(oPC, 110.0);
    float fAgeW  = GetNuiScaleDimension(oPC, 70.0);

    json jTgtCol  = NuiLabel(NuiBind(EFF_BIND_MINE_TGTS),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTgtCol = NuiWidth(jTgtCol, fTgtW);
    jTgtCol = NuiStyleForegroundColor(jTgtCol, NuiBind(EFF_BIND_MINE_COLORS));

    json jTypeCol = NuiLabel(NuiBind(EFF_BIND_MINE_TYPES),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTypeCol = NuiWidth(jTypeCol, fTypeW);
    jTypeCol = NuiStyleForegroundColor(jTypeCol, NuiBind(EFF_BIND_MINE_COLORS));

    json jAgeCol  = NuiLabel(NuiBind(EFF_BIND_MINE_AGES),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jAgeCol = NuiWidth(jAgeCol, fAgeW);
    jAgeCol = NuiStyleForegroundColor(jAgeCol, NuiBind(EFF_BIND_MINE_COLORS));

    json jRowBtn = NuiButton(NuiLabel(JsonString(""), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jRowBtn = NuiId(jRowBtn, EFF_BTN_MINE_ROW);

    json jColumns = JsonArray();
    jColumns = JsonArrayInsert(jColumns, jTgtCol);
    jColumns = JsonArrayInsert(jColumns, jTypeCol);
    jColumns = JsonArrayInsert(jColumns, jAgeCol);

    json jList = NuiList(NuiRow(jColumns), NuiBind(EFF_BIND_MINE_ENC), fRowH);
    jList = NuiHeight(jList, fListH);

    json jInfoLbl = NuiLabel(NuiBind(EFF_BIND_MINE_INFO),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jInfoLbl = NuiHeight(jInfoLbl, GetNuiScaleDimension(oPC, 28.0));

    json jSmashBtn = NuiButton(JsonString("Roztrzaskaj Figurkę"));
    jSmashBtn = NuiId(jSmashBtn, EFF_BTN_SMASH);
    jSmashBtn = NuiHeight(jSmashBtn, fBtnH);
    jSmashBtn = NuiEnabled(jSmashBtn, NuiBind(EFF_BIND_SMASH_ENA));
    jSmashBtn = NuiTooltip(jSmashBtn,
        JsonString("Zadaje 8-18 obrażeń ofierze i niszczy figurkę."));

    json jItems = JsonArray();
    jItems = JsonArrayInsert(jItems,
        NuiLabel(JsonString("Aktywne figurki klątwy:"),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jItems = JsonArrayInsert(jItems, jList);
    jItems = JsonArrayInsert(jItems, jInfoLbl);
    jItems = JsonArrayInsert(jItems, jSmashBtn);

    json jGroup = NuiGroup(NuiCol(jItems), JsonBool(FALSE), JsonInt(NUI_SCROLLBARS_NONE));
    jGroup = NuiVisible(jGroup, NuiBind(EFF_BIND_TAB1_VIS));
    return jGroup;
}

json BuildEffAffectedTab(object oPC)
{
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fListH = GetNuiScaleDimension(oPC, 260.0);
    float fBtnH  = GetNuiScaleDimension(oPC, 34.0);
    float fSrcW  = GetNuiScaleDimension(oPC, 180.0);
    float fTypeW = GetNuiScaleDimension(oPC, 130.0);

    json jSrcCol  = NuiLabel(NuiBind(EFF_BIND_AFF_SRCS),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSrcCol = NuiWidth(jSrcCol, fSrcW);

    json jTypeCol = NuiLabel(NuiBind(EFF_BIND_AFF_TYPES),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTypeCol = NuiWidth(jTypeCol, fTypeW);

    json jColumns = JsonArray();
    jColumns = JsonArrayInsert(jColumns, jSrcCol);
    jColumns = JsonArrayInsert(jColumns, jTypeCol);

    json jList = NuiList(NuiRow(jColumns), NuiBind(EFF_BIND_AFF_ENC), fRowH);
    jList = NuiHeight(jList, fListH);

    json jDetectLbl = NuiLabel(NuiBind(EFF_BIND_DETECT_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDetectLbl = NuiHeight(jDetectLbl, GetNuiScaleDimension(oPC, 28.0));

    json jDetectBtn = NuiButton(JsonString("Szukaj Klątw"));
    jDetectBtn = NuiId(jDetectBtn, EFF_BTN_DETECT);
    jDetectBtn = NuiHeight(jDetectBtn, fBtnH);
    jDetectBtn = NuiTooltip(jDetectBtn,
        JsonString("Rzut na Mądrość i Spellcraft (DC 18) w poszukiwaniu aktywnych klątw."));

    json jCleanse = NuiButton(JsonString("Zapłać za Oczyszczenie (800 zł)"));
    jCleanse = NuiId(jCleanse, EFF_BTN_CLEANSE);
    jCleanse = NuiHeight(jCleanse, fBtnH);
    jCleanse = NuiEnabled(jCleanse, NuiBind(EFF_BIND_CLEANSE_ENA));
    jCleanse = NuiTooltip(jCleanse,
        JsonString("Kosztuje 800 złota. Usuwa wybraną klątwę i powiadamia twórcę."));

    json jInfoLbl = NuiLabel(NuiBind(EFF_BIND_AFF_INFO),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jInfoLbl = NuiHeight(jInfoLbl, GetNuiScaleDimension(oPC, 28.0));

    json jItems = JsonArray();
    jItems = JsonArrayInsert(jItems,
        NuiLabel(JsonString("Wykryte klątwy działające na ciebie:"),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jItems = JsonArrayInsert(jItems, jList);
    jItems = JsonArrayInsert(jItems, jDetectLbl);
    jItems = JsonArrayInsert(jItems, jDetectBtn);
    jItems = JsonArrayInsert(jItems, jCleanse);
    jItems = JsonArrayInsert(jItems, jInfoLbl);

    json jGroup = NuiGroup(NuiCol(jItems), JsonBool(FALSE), JsonInt(NUI_SCROLLBARS_NONE));
    jGroup = NuiVisible(jGroup, NuiBind(EFF_BIND_TAB2_VIS));
    return jGroup;
}

void CreateEffigyWindow(object oPC)
{
    int nExisting = NuiFindWindow(oPC, EFF_WINDOW);
    if(nExisting != 0)
    {
        NuiSetBind(oPC, nExisting, WINDOW_GEOMETRY,
            NuiRect(-1.0, -1.0, EFF_W, EFF_H));
        EffSwitchTab(oPC, nExisting, EFF_TAB_CREATE);
        return;
    }

    float fW = GetNuiScaleDimension(oPC, EFF_W);
    float fH = GetNuiScaleDimension(oPC, EFF_H);

    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, EFF_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 30.0));
    jClose = NuiHeight(jClose, GetNuiScaleDimension(oPC, 28.0));

    json jTitle = NuiLabel(JsonString("Figurka Klątwy"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jHeader = JsonArray();
    jHeader = JsonArrayInsert(jHeader, jTitle);
    jHeader = JsonArrayInsert(jHeader, jClose);

    json jAll = JsonArray();
    jAll = JsonArrayInsert(jAll, NuiRow(jHeader));
    jAll = JsonArrayInsert(jAll, BuildEffTabBar(oPC));
    jAll = JsonArrayInsert(jAll, BuildEffCreateTab(oPC));
    jAll = JsonArrayInsert(jAll, BuildEffMineTab(oPC));
    jAll = JsonArrayInsert(jAll, BuildEffAffectedTab(oPC));

    json jLayout = NuiCol(jAll);

    json jWindow = NuiWindow(
        jLayout,
        JsonString("Figurka Klątwy"),
        NuiBind(WINDOW_GEOMETRY),
        JsonBool(FALSE),  // resizable
        JsonBool(FALSE),  // collapsed
        JsonBool(FALSE),  // closable
        JsonBool(FALSE),  // transparent
        JsonBool(TRUE)    // border
    );

    int nToken = NuiCreate(oPC, jWindow, EFF_WINDOW);
    NuiSetGroupScript(oPC, nToken, EFF_EV_SCRIPT);

    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY, NuiRect(-1.0, -1.0, fW, fH));

    EffSwitchTab(oPC, nToken, EFF_TAB_CREATE);
    EffFeedTargetList(oPC, nToken);
    EffRefreshCursePanel(oPC, nToken);
}

// ----------------------------------------------------------------
// Data feeding
// ----------------------------------------------------------------

void EffSwitchTab(object oPC, int nToken, int nTab)
{
    NuiSetBind(oPC, nToken, EFF_BIND_TAB0_VIS, JsonBool(nTab == EFF_TAB_CREATE));
    NuiSetBind(oPC, nToken, EFF_BIND_TAB1_VIS, JsonBool(nTab == EFF_TAB_MINE));
    NuiSetBind(oPC, nToken, EFF_BIND_TAB2_VIS, JsonBool(nTab == EFF_TAB_AFFECTED));

    if(nTab == EFF_TAB_MINE)     EffFeedMyEffigies(oPC, nToken);
    if(nTab == EFF_TAB_AFFECTED) EffFeedAffectedList(oPC, nToken);
}

void EffFeedTargetList(object oPC, int nToken)
{
    json jPlayers = EffGetKnownPlayers(oPC);
    int  nCount   = JsonGetLength(jPlayers);

    json jNames = JsonArray();
    json jEnc   = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jP    = JsonArrayGet(jPlayers, i);
        string sN  = JsonGetString(JsonObjectGet(jP, "char_name"));
        jNames = JsonArrayInsert(jNames, JsonString(sN));
        jEnc   = JsonArrayInsert(jEnc,   JsonBool(TRUE));
    }

    NuiSetBind(oPC, nToken, EFF_BIND_TGT_NAMES, jNames);
    NuiSetBind(oPC, nToken, EFF_BIND_TGT_ENC,   jEnc);

    string sSel = GetLocalString(oPC, EFF_LVAR_SEL_TGT_NAME);
    if(sSel == "")
        NuiSetBind(oPC, nToken, EFF_BIND_TGT_LBL, JsonString("Wybierz cel z listy."));
    else
        NuiSetBind(oPC, nToken, EFF_BIND_TGT_LBL, JsonString("Cel: " + sSel));
}

void EffRefreshCursePanel(object oPC, int nToken)
{
    int nSel = GetLocalInt(oPC, EFF_LVAR_SEL_CURSE);

    NuiSetBind(oPC, nToken, EFF_BIND_C1_ACTIVE, JsonBool(nSel != EFF_CURSE_ANGUISH));
    NuiSetBind(oPC, nToken, EFF_BIND_C2_ACTIVE, JsonBool(nSel != EFF_CURSE_WITHER));
    NuiSetBind(oPC, nToken, EFF_BIND_C3_ACTIVE, JsonBool(nSel != EFF_CURSE_BLINDNESS));
    NuiSetBind(oPC, nToken, EFF_BIND_C4_ACTIVE, JsonBool(nSel != EFF_CURSE_TORPOR));

    if(nSel > 0)
    {
        NuiSetBind(oPC, nToken, EFF_BIND_FLAVOR_LBL,
            JsonString(EffCurseFlavor(nSel)));
        NuiSetBind(oPC, nToken, EFF_BIND_COST_LBL,
            JsonString("Koszt: " + IntToString(EffCurseCost(nSel)) + " złota"));
    }
    else
    {
        NuiSetBind(oPC, nToken, EFF_BIND_FLAVOR_LBL,
            JsonString("Wybierz rodzaj klątwy z listy powyżej."));
        NuiSetBind(oPC, nToken, EFF_BIND_COST_LBL, JsonString(""));
    }

    string sTgt = GetLocalString(oPC, EFF_LVAR_SEL_TGT_UUID);
    int bReady  = (sTgt != "" && nSel > 0);
    NuiSetBind(oPC, nToken, EFF_BIND_CREATE_ENA, JsonBool(bReady));
}

void EffFeedMyEffigies(object oPC, int nToken)
{
    json jMine   = EffGetMyEffigies(GetObjectUUID(oPC));
    int  nCount  = JsonGetLength(jMine);

    json jTargets = JsonArray();
    json jTypes   = JsonArray();
    json jAges    = JsonArray();
    json jEnc     = JsonArray();
    json jColors  = JsonArray();

    json jWhite   = NuiColor(220, 220, 210, 255);

    int i;
    for(i = 0; i < nCount; i++)
    {
        json   jRow  = JsonArrayGet(jMine, i);
        string sTgt  = JsonGetString(JsonObjectGet(jRow, "target_name"));
        int    nType = JsonGetInt(JsonObjectGet(jRow,    "curse_type"));
        int    nDays = JsonGetInt(JsonObjectGet(jRow,    "days"));

        if(sTgt == "") sTgt = "?Nieznany?";
        jTargets = JsonArrayInsert(jTargets, JsonString(sTgt));
        jTypes   = JsonArrayInsert(jTypes,   JsonString(EffCurseName(nType)));
        jAges    = JsonArrayInsert(jAges,    JsonString(IntToString(nDays) + "d"));
        jEnc     = JsonArrayInsert(jEnc,     JsonBool(TRUE));
        jColors  = JsonArrayInsert(jColors,  jWhite);
    }

    NuiSetBind(oPC, nToken, EFF_BIND_MINE_TGTS,  jTargets);
    NuiSetBind(oPC, nToken, EFF_BIND_MINE_TYPES, jTypes);
    NuiSetBind(oPC, nToken, EFF_BIND_MINE_AGES,  jAges);
    NuiSetBind(oPC, nToken, EFF_BIND_MINE_ENC,   jEnc);
    NuiSetBind(oPC, nToken, EFF_BIND_MINE_COLORS,jColors);

    NuiSetBind(oPC, nToken, EFF_BIND_SMASH_ENA,
        JsonBool(GetLocalInt(oPC, EFF_LVAR_SEL_MINE_ID) > 0));

    if(nCount == 0)
        NuiSetBind(oPC, nToken, EFF_BIND_MINE_INFO, JsonString("Nie masz aktywnych figurek."));
    else
        NuiSetBind(oPC, nToken, EFF_BIND_MINE_INFO,
            JsonString(IntToString(nCount) + " / " + IntToString(EFF_MAX_EFFIGIES_PER_PC)
                + " aktywnych figurek."));
}

void EffFeedAffectedList(object oPC, int nToken)
{
    string sUuid = GetObjectUUID(oPC);
    json jDet    = EffGetDetectedAffecting(sUuid);
    int  nCount  = JsonGetLength(jDet);

    json jSrcs  = JsonArray();
    json jTypes = JsonArray();
    json jEnc   = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json   jRow  = JsonArrayGet(jDet, i);
        string sName = JsonGetString(JsonObjectGet(jRow, "creator_name"));
        int    nType = JsonGetInt(JsonObjectGet(jRow, "curse_type"));
        if(sName == "") sName = "Nieznajomy";
        jSrcs  = JsonArrayInsert(jSrcs,  JsonString(sName));
        jTypes = JsonArrayInsert(jTypes, JsonString(EffCurseName(nType)));
        jEnc   = JsonArrayInsert(jEnc,   JsonBool(TRUE));
    }

    NuiSetBind(oPC, nToken, EFF_BIND_AFF_SRCS,  jSrcs);
    NuiSetBind(oPC, nToken, EFF_BIND_AFF_TYPES, jTypes);
    NuiSetBind(oPC, nToken, EFF_BIND_AFF_ENC,   jEnc);

    int nUndet = EffCountUndetectedAffecting(sUuid);
    if(nUndet > 0)
        NuiSetBind(oPC, nToken, EFF_BIND_DETECT_LBL,
            JsonString("Czujesz, że coś działa na ciebie... ("
                + IntToString(nUndet) + " niewykrytych klątw)"));
    else if(nCount == 0)
        NuiSetBind(oPC, nToken, EFF_BIND_DETECT_LBL,
            JsonString("Nie wykryto aktywnych klątw. Użyj przycisku, by szukać."));
    else
        NuiSetBind(oPC, nToken, EFF_BIND_DETECT_LBL,
            JsonString(IntToString(nCount) + " wykrytych klątw."));

    int bCanCleanse = GetLocalInt(oPC, EFF_LVAR_SEL_AFF_ID) > 0;
    NuiSetBind(oPC, nToken, EFF_BIND_CLEANSE_ENA, JsonBool(bCanCleanse));
    NuiSetBind(oPC, nToken, EFF_BIND_AFF_INFO, JsonString(""));
}

// lib_wf.nss — Watchfire: UI construction, rest logic, cooking

#include "lib_wf_def"

// ----------------------------------------------------------------
// Camp tab layout
// ----------------------------------------------------------------

json BuildWfCampTab(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fLblH  = GetNuiScaleDimension(oPC, 24.0);
    float fSep   = GetNuiScaleDimension(oPC, 10.0);

    // Status label (shows current camp state)
    json jStatus = NuiLabel(NuiBind(WF_BIND_STATUS_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatus = NuiHeight(jStatus, GetNuiScaleDimension(oPC, 32.0));

    // Danger level row
    json jDangerTxt = NuiLabel(JsonString("Zagrożenie obszaru:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDangerTxt = NuiWidth(jDangerTxt, GetNuiScaleDimension(oPC, 160.0));
    jDangerTxt = NuiHeight(jDangerTxt, fLblH);

    json jDangerVal = NuiLabel(NuiBind(WF_BIND_DANGER_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDangerVal = NuiHeight(jDangerVal, fLblH);

    json jDangerRow = JsonArray();
    jDangerRow = JsonArrayInsert(jDangerRow, jDangerTxt);
    jDangerRow = JsonArrayInsert(jDangerRow, jDangerVal);

    // Watch toggle button
    json jWatchBtn = NuiButton(NuiBind(WF_BIND_WATCH_LBL));
    jWatchBtn = NuiId(jWatchBtn, WF_BTN_WATCH);
    jWatchBtn = NuiEnabled(jWatchBtn, NuiBind(WF_BIND_WATCH_ENA));
    jWatchBtn = NuiWidth(jWatchBtn, GetNuiScaleDimension(oPC, 280.0));
    jWatchBtn = NuiHeight(jWatchBtn, fBtnH);
    jWatchBtn = NuiTooltip(jWatchBtn, JsonString(
        "Warta: bezpieczniejszy odpoczynek, ale mniej PŻ odzyskanych."));

    json jWatchRow = JsonArray();
    jWatchRow = JsonArrayInsert(jWatchRow, NuiSpacer());
    jWatchRow = JsonArrayInsert(jWatchRow, jWatchBtn);
    jWatchRow = JsonArrayInsert(jWatchRow, NuiSpacer());

    // Rest/Wake action buttons
    json jShortBtn = NuiButton(JsonString("Krótki odpoczynek (2h)"));
    jShortBtn = NuiId(jShortBtn, WF_BTN_REST_SHORT);
    jShortBtn = NuiEnabled(jShortBtn, NuiBind(WF_BIND_REST_S_ENA));
    jShortBtn = NuiWidth(jShortBtn, GetNuiScaleDimension(oPC, 200.0));
    jShortBtn = NuiHeight(jShortBtn, fBtnH);
    jShortBtn = NuiTooltip(jShortBtn, JsonString("Odpoczywa 2 godziny. Odzyskuje 25% PŻ."));

    json jLongBtn = NuiButton(JsonString("Długi odpoczynek (8h)"));
    jLongBtn = NuiId(jLongBtn, WF_BTN_REST_LONG);
    jLongBtn = NuiEnabled(jLongBtn, NuiBind(WF_BIND_REST_L_ENA));
    jLongBtn = NuiWidth(jLongBtn, GetNuiScaleDimension(oPC, 200.0));
    jLongBtn = NuiHeight(jLongBtn, fBtnH);
    jLongBtn = NuiTooltip(jLongBtn, JsonString("Odpoczywaj 8 godzin. Pełne PŻ (50% przy warcie)."));

    json jWakeBtn = NuiButton(JsonString("Obudź się"));
    jWakeBtn = NuiId(jWakeBtn, WF_BTN_WAKE);
    jWakeBtn = NuiEnabled(jWakeBtn, NuiBind(WF_BIND_WAKE_ENA));
    jWakeBtn = NuiWidth(jWakeBtn, GetNuiScaleDimension(oPC, 160.0));
    jWakeBtn = NuiHeight(jWakeBtn, fBtnH);

    json jActionRow = JsonArray();
    jActionRow = JsonArrayInsert(jActionRow, NuiSpacer());
    jActionRow = JsonArrayInsert(jActionRow, jShortBtn);
    jActionRow = JsonArrayInsert(jActionRow, NuiSpacer());
    jActionRow = JsonArrayInsert(jActionRow, jLongBtn);
    jActionRow = JsonArrayInsert(jActionRow, NuiSpacer());
    jActionRow = JsonArrayInsert(jActionRow, jWakeBtn);
    jActionRow = JsonArrayInsert(jActionRow, NuiSpacer());

    // Result text (outcome of last rest)
    json jResultLbl = NuiGroup(
        NuiText(NuiBind(WF_BIND_RESULT_LBL), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jResultLbl = NuiHeight(jResultLbl, GetNuiScaleDimension(oPC, 120.0));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, jStatus);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jDangerRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jWatchRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jRestInfo);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jActionRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 10.0));
    jCol = JsonArrayInsert(jCol, jResultLbl);

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 620.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Cook tab layout
// ----------------------------------------------------------------

json BuildWfCookTab(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fRowH  = GetNuiScaleDimension(oPC, 28.0);
    float fListH = GetNuiScaleDimension(oPC, 210.0);
    float fLblH  = GetNuiScaleDimension(oPC, 24.0);

    // Recipe list
    json jRecName = NuiLabel(NuiBind(WF_BIND_REC_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jRecCell = NuiGroup(NuiRow(JsonArrayInsert(JsonArray(), jRecName)),
        TRUE, NUI_SCROLLBARS_NONE);
    jRecCell = NuiId(jRecCell, WF_BTN_REC_ROW);
    jRecCell = NuiEncouraged(jRecCell, NuiBind(WF_BIND_REC_ENC));

    json jRecTmpl = JsonArrayInsert(JsonArray(),
        NuiListTemplateCell(jRecCell, 0.0, TRUE));

    json jRecList = NuiList(jRecTmpl, NuiBind(WF_BIND_REC_COUNT), fRowH);
    jRecList = NuiHeight(jRecList, fListH);

    // Selected recipe detail
    json jEffLbl = NuiLabel(NuiBind(WF_BIND_REC_EFF),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEffLbl = NuiHeight(jEffLbl, fLblH);

    json jCanCookLbl = NuiLabel(NuiBind(WF_BIND_CAN_COOK),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCanCookLbl = NuiHeight(jCanCookLbl, fLblH);

    // Cook button
    json jCookBtn = NuiButton(JsonString("Gotuj"));
    jCookBtn = NuiId(jCookBtn, WF_BTN_COOK);
    jCookBtn = NuiEnabled(jCookBtn, NuiBind(WF_BIND_COOK_ENA));
    jCookBtn = NuiWidth(jCookBtn, GetNuiScaleDimension(oPC, 160.0));
    jCookBtn = NuiHeight(jCookBtn, fBtnH);

    json jCookMsgLbl = NuiLabel(NuiBind(WF_BIND_COOK_MSG),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCookMsgLbl = NuiHeight(jCookMsgLbl, fLblH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jCookBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jRecList);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jEffLbl);
    jCol = JsonArrayInsert(jCol, jCanCookLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jCookMsgLbl);

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 620.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Journal tab layout
// ----------------------------------------------------------------

json BuildWfJournalTab(object oPC)
{
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fListH = GetNuiScaleDimension(oPC, 340.0);

    float fDayW  = GetNuiScaleDimension(oPC, 50.0);
    float fTypeW = GetNuiScaleDimension(oPC, 60.0);
    float fEncW  = GetNuiScaleDimension(oPC, 70.0);

    json jDay = NuiLabel(NuiBind(WF_BIND_LOG_DAY),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDay = NuiWidth(jDay, fDayW);

    json jArea = NuiLabel(NuiBind(WF_BIND_LOG_AREA),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jType = NuiLabel(NuiBind(WF_BIND_LOG_TYPE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jType = NuiWidth(jType, fTypeW);

    json jEnc = NuiLabel(NuiBind(WF_BIND_LOG_ENC),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jEnc = NuiWidth(jEnc, fEncW);

    json jMeal = NuiLabel(NuiBind(WF_BIND_LOG_MEAL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jDay)),  fDayW));
    jCellRow = JsonArrayInsert(jCellRow, jArea);
    jCellRow = JsonArrayInsert(jCellRow, NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jType)), fTypeW));
    jCellRow = JsonArrayInsert(jCellRow, NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jEnc)),  fEncW));
    jCellRow = JsonArrayInsert(jCellRow, jMeal);

    json jCell = NuiGroup(NuiRow(jCellRow), FALSE, NUI_SCROLLBARS_NONE);
    json jTmpl = JsonArrayInsert(JsonArray(),
        NuiListTemplateCell(jCell, 0.0, TRUE));

    json jList = NuiList(jTmpl, NuiBind(WF_BIND_LOG_ROW_CNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // Header row
    json jHdrDay  = NuiLabel(JsonString("Data"),    JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrDay  = NuiWidth(jHdrDay,  fDayW);
    json jHdrArea = NuiLabel(JsonString("Obszar"),  JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jHdrType = NuiLabel(JsonString("Rodzaj"),  JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrType = NuiWidth(jHdrType, fTypeW);
    json jHdrEnc  = NuiLabel(JsonString("Napotkano"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrEnc  = NuiWidth(jHdrEnc,  fEncW);
    json jHdrMeal = NuiLabel(JsonString("Posiłek"),  JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jHdrRow = JsonArray();
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrDay);
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrArea);
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrType);
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrEnc);
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrMeal);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jHdrRow));
    jCol = JsonArrayInsert(jCol, jList);

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 620.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Window create / tab switch
// ----------------------------------------------------------------

void WfOpenWindow(object oPC, object oCampfire)
{
    SetLocalObject(oPC, WF_LVAR_CAMPFIRE, oCampfire);

    if(NuiFindWindow(oPC, WF_WINDOW) != 0)
    {
        WfFeedCampTab(oPC, NuiFindWindow(oPC, WF_WINDOW));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, WF_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, WF_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
        GetNuiScaleDimension(oPC, WF_W),
        GetNuiScaleDimension(oPC, WF_H));

    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fTabW  = GetNuiScaleDimension(oPC, 140.0);

    json jTabCamp = NuiButton(JsonString("Ognisko"));
    jTabCamp = NuiId(jTabCamp, WF_BTN_TAB_CAMP);
    jTabCamp = NuiWidth(jTabCamp, fTabW);
    jTabCamp = NuiHeight(jTabCamp, fBtnH);

    json jTabCook = NuiButton(JsonString("Kuchnia"));
    jTabCook = NuiId(jTabCook, WF_BTN_TAB_COOK);
    jTabCook = NuiWidth(jTabCook, fTabW);
    jTabCook = NuiHeight(jTabCook, fBtnH);

    json jTabLog = NuiButton(JsonString("Dziennik"));
    jTabLog = NuiId(jTabLog, WF_BTN_TAB_LOG);
    jTabLog = NuiWidth(jTabLog, fTabW);
    jTabLog = NuiHeight(jTabLog, fBtnH);

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, WF_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTopBar = JsonArray();
    jTopBar = JsonArrayInsert(jTopBar, jTabCamp);
    jTopBar = JsonArrayInsert(jTopBar, jTabCook);
    jTopBar = JsonArrayInsert(jTopBar, jTabLog);
    jTopBar = JsonArrayInsert(jTopBar, NuiSpacer());
    jTopBar = JsonArrayInsert(jTopBar, jCloseBtn);

    json jSwapGrp = NuiGroup(BuildWfCampTab(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, WF_GRP_TABS);

    json jRootChildren = JsonArray();
    jRootChildren = JsonArrayInsert(jRootChildren, NuiRow(jTopBar));
    jRootChildren = JsonArrayInsert(jRootChildren, jSwapGrp);

    json jWin = NuiWindow(NuiCol(jRootChildren),
        JsonString("Watchfire — Obóz"),
        NuiBind(WF_WIN_GEOM),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, WF_WINDOW, WF_EV_SCRIPT);
    NuiSetBind(oPC, nToken, WF_WIN_GEOM, jGeom);
    SetLocalInt(oPC, WF_LVAR_TAB, WF_TAB_CAMP);
    WfFeedCampTab(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed functions
// ----------------------------------------------------------------

void WfFeedCampTab(object oPC, int nToken)
{
    int nState     = GetLocalInt(oPC, WF_LVAR_STATE);
    int nWatchOn   = GetLocalInt(oPC, WF_LVAR_WATCH_ON);
    object oCf     = GetLocalObject(oPC, WF_LVAR_CAMPFIRE);
    int nDanger    = WfGetDangerLevel(oCf);
    string sResult = GetLocalString(oPC, WF_LVAR_RESULT);

    string sStatus;
    if(nState == WF_STATE_RESTING)
        sStatus = "Odpoczywasz przy ognisku...";
    else
        sStatus = "Ognisko płonie spokojnie. Możesz odpocząć.";

    string sWatchLbl;
    if(nWatchOn)
        sWatchLbl = "[Warta: AKTYWNA] — Naciśnij, by wyłączyć";
    else
        sWatchLbl = "[Warta: WYŁĄCZONA] — Naciśnij, by włączyć";

    NuiSetBind(oPC, nToken, WF_BIND_STATUS_LBL,  JsonString(sStatus));
    NuiSetBind(oPC, nToken, WF_BIND_DANGER_LBL,  JsonString(WfDangerLabel(nDanger)));
    NuiSetBind(oPC, nToken, WF_BIND_WATCH_LBL,   JsonString(sWatchLbl));
    NuiSetBind(oPC, nToken, WF_BIND_WATCH_ENA,   JsonBool(nState == WF_STATE_IDLE));
    NuiSetBind(oPC, nToken, WF_BIND_REST_S_ENA,  JsonBool(nState == WF_STATE_IDLE));
    NuiSetBind(oPC, nToken, WF_BIND_REST_L_ENA,  JsonBool(nState == WF_STATE_IDLE));
    NuiSetBind(oPC, nToken, WF_BIND_WAKE_ENA,    JsonBool(nState == WF_STATE_RESTING));
    NuiSetBind(oPC, nToken, WF_BIND_RESULT_LBL,  JsonString(sResult));
}

void WfFeedCookTab(object oPC, int nToken)
{
    int nSel = GetLocalInt(oPC, WF_LVAR_SEL_REC);

    json jNames = JsonArray();
    json jEncs  = JsonArray();
    int i;
    for(i = 0; i < WF_RECIPE_COUNT; i++)
    {
        jNames = JsonArrayInsert(jNames, JsonString(WfRecipeName(i)));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(i == nSel));
    }

    NuiSetBind(oPC, nToken, WF_BIND_REC_NAME,  jNames);
    NuiSetBind(oPC, nToken, WF_BIND_REC_ENC,   jEncs);
    NuiSetBind(oPC, nToken, WF_BIND_REC_COUNT, JsonInt(WF_RECIPE_COUNT));

    string sEff     = WfRecipeEffect(nSel);
    string sIngLbl  = "Składniki: " + WfRecipeIngLabel(nSel);
    int bHas        = WfHasIngredients(oPC, nSel);
    int bResting    = (GetLocalInt(oPC, WF_LVAR_STATE) == WF_STATE_RESTING);
    string sCanCook = bHas ? "Masz składniki." : "Brak składników.";

    NuiSetBind(oPC, nToken, WF_BIND_REC_EFF,     JsonString(sEff + "\n" + sIngLbl));
    NuiSetBind(oPC, nToken, WF_BIND_CAN_COOK,    JsonString(sCanCook));
    NuiSetBind(oPC, nToken, WF_BIND_COOK_ENA,    JsonBool(bHas && bResting));
    NuiSetBind(oPC, nToken, WF_BIND_COOK_MSG,    JsonString(""));
}

void WfFeedJournalTab(object oPC, int nToken)
{
    json jSessions = WfGetRecentSessions(oPC);
    int nCount     = JsonGetLength(jSessions);

    json jDays  = JsonArray();
    json jAreas = JsonArray();
    json jTypes = JsonArray();
    json jEncs  = JsonArray();
    json jMeals = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow = JsonArrayGet(jSessions, i);
        string sType = JsonGetString(JsonObjectGet(jRow, "rest_type"));
        int nEnc     = JsonGetInt   (JsonObjectGet(jRow, "encounter"));

        jDays  = JsonArrayInsert(jDays,  JsonString(JsonGetString(JsonObjectGet(jRow, "day"))));
        jAreas = JsonArrayInsert(jAreas, JsonString(JsonGetString(JsonObjectGet(jRow, "area_name"))));
        jTypes = JsonArrayInsert(jTypes, JsonString(sType == "long" ? "Długi" : "Krótki"));
        jEncs  = JsonArrayInsert(jEncs,  JsonString(nEnc ? "Tak" : "Nie"));
        jMeals = JsonArrayInsert(jMeals, JsonString(JsonGetString(JsonObjectGet(jRow, "meal_name"))));
    }

    NuiSetBind(oPC, nToken, WF_BIND_LOG_DAY,     jDays);
    NuiSetBind(oPC, nToken, WF_BIND_LOG_AREA,    jAreas);
    NuiSetBind(oPC, nToken, WF_BIND_LOG_TYPE,    jTypes);
    NuiSetBind(oPC, nToken, WF_BIND_LOG_ENC,     jEncs);
    NuiSetBind(oPC, nToken, WF_BIND_LOG_MEAL,    jMeals);
    NuiSetBind(oPC, nToken, WF_BIND_LOG_ROW_CNT, JsonInt(nCount));
}

// ----------------------------------------------------------------
// Rest logic
// ----------------------------------------------------------------

// nType: 0=short (2h, 25% HP), 1=long (8h, full HP)
void WfDoRest(object oPC, int nToken, int nType)
{
    if(GetLocalInt(oPC, WF_LVAR_STATE) != WF_STATE_IDLE) return;

    SetLocalInt(oPC, WF_LVAR_STATE,      WF_STATE_RESTING);
    SetLocalInt(oPC, WF_LVAR_REST_TYPE,  nType);
    SetLocalInt(oPC, WF_LVAR_ENCOUNTER,  0);
    DeleteLocalString(oPC, WF_LVAR_RESULT);
    DeleteLocalString(oPC, WF_LVAR_MEAL_NAME);

    string sMsg = nType == 1
        ? "[Watchfire] Zasypiasz przy ognisku..."
        : "[Watchfire] Odpoczywasz chwilę przy ognisku...";
    SendMessageToPC(oPC, sMsg);

    WfFeedCampTab(oPC, nToken);
    WfFeedCookTab(oPC, nToken);
}

void WfDoWake(object oPC, int nToken)
{
    if(GetLocalInt(oPC, WF_LVAR_STATE) != WF_STATE_RESTING) return;

    int nRestType = GetLocalInt(oPC, WF_LVAR_REST_TYPE);
    int nWatchOn  = GetLocalInt(oPC, WF_LVAR_WATCH_ON);

    object oCf    = GetLocalObject(oPC, WF_LVAR_CAMPFIRE);
    int nDanger   = WfGetDangerLevel(oCf);
    string sArea  = GetName(GetArea(oPC));

    // Encounter check: d20 vs DC = (8 + nDanger * 2 - nWatchOn * 3)
    int nRoll = d20();
    int nDC   = 8 + nDanger * 2 - (nWatchOn ? 3 : 0);
    int bEnc  = (nRoll < nDC);

    string sResult;

    if(nRestType == 1)
    {
        // Long rest: full HP, restore spells (NWN does this via time advance)
        AdvanceTimeByHours(8);
        int nMaxHP = GetMaxHitPoints(oPC);
        int nCurHP = GetCurrentHitPoints(oPC);
        // Watch duty reduces recovery
        int nHeal;
        if(nWatchOn)
            nHeal = nMaxHP / 2 - nCurHP;
        else
            nHeal = nMaxHP - nCurHP;
        if(nHeal > 0)
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(nHeal), oPC);
        sResult = "Długi odpoczynek zakończony. Zdrowie przywrócone";
        if(nWatchOn) sResult = sResult + " (50% — warta osłabiła sen).";
        else         sResult = sResult + ".";
    }
    else
    {
        // Short rest: 25% HP
        AdvanceTimeByHours(2);
        int nMaxHP = GetMaxHitPoints(oPC);
        int nCurHP = GetCurrentHitPoints(oPC);
        int nHeal  = nMaxHP / 4 - (nCurHP - GetMaxHitPoints(oPC));
        if(nHeal < 0) nHeal = 0;
        int nActualHeal = (nMaxHP / 4);
        if(nActualHeal > 0)
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(nActualHeal), oPC);
        sResult = "Krótki odpoczynek zakończony. Odzyskano 25% PŻ.";
    }

    if(bEnc)
    {
        sResult = sResult + "\n\nW nocy coś krążyło wokół obozu... Poczuj się ostrzeżony.";
        SendMessageToPC(oPC, "[Watchfire] Słyszysz odgłosy w ciemnościach.");
        FloatingTextStringOnCreature("Niespokojny obóz...", oPC, FALSE);
    }
    else
    {
        sResult = sResult + "\n\nNoc minęła spokojnie.";
    }

    string sMealName = GetLocalString(oPC, WF_LVAR_MEAL_NAME);
    if(sMealName != "")
        sResult = sResult + "\nPosiłek: " + sMealName + " — efekt aktywny.";

    SetLocalInt(oPC, WF_LVAR_STATE,     WF_STATE_IDLE);
    SetLocalInt(oPC, WF_LVAR_ENCOUNTER, bEnc ? 1 : 0);
    SetLocalString(oPC, WF_LVAR_RESULT, sResult);

    WfLogSession(oPC,
        nRestType == 1 ? "long" : "short",
        sArea,
        bEnc ? 1 : 0,
        sMealName);

    SendMessageToPC(oPC, "[Watchfire] " + sResult);
    WfFeedCampTab(oPC, nToken);
    WfFeedCookTab(oPC, nToken);
}

// ----------------------------------------------------------------
// Cooking
// ----------------------------------------------------------------

void WfDoCook(object oPC, int nToken)
{
    if(GetLocalInt(oPC, WF_LVAR_STATE) != WF_STATE_RESTING)
    {
        NuiSetBind(oPC, nToken, WF_BIND_COOK_MSG,
            JsonString("Gotowanie tylko przy aktywnym odpoczynku!"));
        return;
    }

    int nSel = GetLocalInt(oPC, WF_LVAR_SEL_REC);
    if(!WfHasIngredients(oPC, nSel))
    {
        NuiSetBind(oPC, nToken, WF_BIND_COOK_MSG,
            JsonString("Brak składników!"));
        return;
    }

    WfConsumeIngredients(oPC, nSel);
    WfApplyMealBuff(oPC, nSel);

    string sMealName = WfRecipeName(nSel);
    SetLocalString(oPC, WF_LVAR_MEAL_NAME, sMealName);

    string sMsg = "Ugotowano: " + sMealName + ". Efekt: " + WfRecipeEffect(nSel);
    NuiSetBind(oPC, nToken, WF_BIND_COOK_MSG, JsonString(sMsg));
    SendMessageToPC(oPC, "[Watchfire] " + sMsg);

    WfFeedCookTab(oPC, nToken);
}

// lib_hench.nss
// NUI layout for henchman system: 3 layouts (Hire / Fire / FireDead) via NuiSetGroupLayout
#include "nw_inc_nui"
#include "lib_hench_def"

// ============================================================
// NUI utilities (inline - no external dependencies)
// ============================================================

const string EVENT_TYPE_WATCH     = "watch";
const string EVENT_TYPE_OPEN      = "open";
const string EVENT_TYPE_CLOSE     = "close";
const string EVENT_TYPE_CLICK     = "click";
const string EVENT_TYPE_MOUSEDOWN = "mousedown";
const string WINDOW_GEOMETRY      = "geometry";

float GetNuiScaleDimension(object oPC, float fDim, float fScaleMax = 1.5)
{
    int nScale = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_SCALE);
    float fScale = nScale / 100.0;
    fScale = fScale > fScaleMax ? fScaleMax : fScale;
    return fDim / fScale;
}

json CreateEmptyRow(object oPC, float fHeight)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, fHeight)));
    return NuiRow(jRow);
}

void NuiOffEncouragedData(object oPC, int nToken, string sBind)
{
    int nRow = GetLocalInt(oPC, HENCH_LVAR_SEL_IDX);
    json jEncs = NuiGetBind(oPC, nToken, sBind);
    if(JsonGetType(jEncs) != JSON_TYPE_ARRAY) return;
    if(nRow < 0 || nRow >= JsonGetLength(jEncs)) return;
    jEncs = JsonArraySet(jEncs, nRow, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, sBind, jEncs);
}

void NuiOnEncouragedData(object oPC, int nToken, string sBind, int nRow)
{
    json jEncs = NuiGetBind(oPC, nToken, sBind);
    if(JsonGetType(jEncs) != JSON_TYPE_ARRAY) return;
    if(nRow < 0 || nRow >= JsonGetLength(jEncs)) return;
    jEncs = JsonArraySet(jEncs, nRow, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, sBind, jEncs);
    SetLocalInt(oPC, HENCH_LVAR_SEL_IDX, nRow);
}

// Forward declarations
void FeedRosterList(object oPC, int nToken);
void FeedDetailPanel(object oPC, int nToken, int nIdx);
void FeedFireLayout(object oPC, int nToken);
void FeedFireDeadLayout(object oPC, int nToken);
json HenchBuildFireDeadLayout(object oPC);

// ============================================================
// Helpers
// ============================================================

string HenchStatLabel(int nStrRef)
{
    return GetStringByStrRef(nStrRef) + ":";
}

json HenchMakeStatRow(string sLabel, string sValBind, float fLblW, float fValW, float fH)
{
    json jLbl = NuiLabel(JsonString(sLabel),
                         JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLbl = NuiWidth(jLbl, fLblW);
    jLbl = NuiHeight(jLbl, fH);

    json jVal = NuiLabel(NuiBind(sValBind),
                         JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jVal = NuiWidth(jVal, fValW);
    jVal = NuiHeight(jVal, fH);

    json jRowC = JsonArray();
    jRowC = JsonArrayInsert(jRowC, NuiSpacer());
    jRowC = JsonArrayInsert(jRowC, jLbl);
    jRowC = JsonArrayInsert(jRowC, jVal);
    jRowC = JsonArrayInsert(jRowC, NuiSpacer());
    return NuiRow(jRowC);
}

// ============================================================
// Roster cell (for NuiList in the Hire layout)
// ============================================================

json HenchBuildRosterCell(object oPC)
{
    float fPortH = GetNuiScaleDimension(oPC, 44.0);
    float fPortW = GetNuiScaleDimension(oPC, 36.0);
    float fNameH = GetNuiScaleDimension(oPC, 20.0);
    float fClsH  = GetNuiScaleDimension(oPC, 16.0);

    json jPort = NuiImage(NuiBind(HENCH_BIND_PORT),
                          JsonInt(NUI_ASPECT_FILL),
                          JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_TOP));
    jPort = NuiWidth(jPort,  fPortW);
    jPort = NuiHeight(jPort, fPortH);

    json jName = NuiLabel(NuiBind(HENCH_BIND_NAME),
                          JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiHeight(jName, fNameH);

    json jCls = NuiLabel(NuiBind(HENCH_BIND_CLASS),
                         JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCls = NuiHeight(jCls, fClsH);

    json jTextCol = JsonArray();
    jTextCol = JsonArrayInsert(jTextCol, jName);
    jTextCol = JsonArrayInsert(jTextCol, jCls);

    json jRowItems = JsonArray();
    jRowItems = JsonArrayInsert(jRowItems, jPort);
    jRowItems = JsonArrayInsert(jRowItems, NuiCol(jTextCol));

    json jCell = NuiGroup(NuiRow(jRowItems), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, HENCH_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(HENCH_BIND_ENC));

    json jTmpl = JsonArray();
    jTmpl = JsonArrayInsert(jTmpl, NuiListTemplateCell(jCell, 0.0, TRUE));
    return jTmpl;
}

// ============================================================
// Detail panel - shared between Hire and Fire layouts
// ============================================================

json HenchBuildDetailPanel(object oPC)
{
    float fPortW = GetNuiScaleDimension(oPC, 128.0);
    float fPortH = GetNuiScaleDimension(oPC, 200.0);
    float fLblH  = GetNuiScaleDimension(oPC, 20.0);
    float fLblH2 = GetNuiScaleDimension(oPC, 16.0);
    float fStatH  = GetNuiScaleDimension(oPC, 18.0);
    float fLblW   = GetNuiScaleDimension(oPC, 90.0);
    float fValW   = GetNuiScaleDimension(oPC, 32.0);
    float fDescH  = GetNuiScaleDimension(oPC, 120.0);

    json jPort = NuiImage(NuiBind(HENCH_BIND_DET_PORT),
                          JsonInt(NUI_ASPECT_FILL),
                          JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_TOP));
    jPort = NuiWidth(jPort,  fPortW);
    jPort = NuiHeight(jPort, fPortH);

    json jName = NuiLabel(NuiBind(HENCH_BIND_DET_NAME),
                          JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiHeight(jName, fLblH);

    json jCls = NuiLabel(NuiBind(HENCH_BIND_DET_CLS),
                         JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jCls = NuiHeight(jCls, fLblH2);

    json jDesc = NuiText(NuiBind(HENCH_BIND_DET_DESC), FALSE);
    jDesc = NuiHeight(jDesc, fDescH);

    json jPortRow = JsonArray();
    jPortRow = JsonArrayInsert(jPortRow, NuiSpacer());
    jPortRow = JsonArrayInsert(jPortRow, jPort);
    jPortRow = JsonArrayInsert(jPortRow, NuiSpacer());

    json jInfoCol = JsonArray();
    jInfoCol = JsonArrayInsert(jInfoCol, NuiRow(jPortRow));
    jInfoCol = JsonArrayInsert(jInfoCol, jName);
    jInfoCol = JsonArrayInsert(jInfoCol, jCls);
    jInfoCol = JsonArrayInsert(jInfoCol, CreateEmptyRow(oPC, 6.0));

    jInfoCol = JsonArrayInsert(jInfoCol, HenchMakeStatRow(HenchStatLabel(135), HENCH_BIND_DET_STR, fLblW, fValW, fStatH));
    jInfoCol = JsonArrayInsert(jInfoCol, HenchMakeStatRow(HenchStatLabel(133), HENCH_BIND_DET_DEX, fLblW, fValW, fStatH));
    jInfoCol = JsonArrayInsert(jInfoCol, HenchMakeStatRow(HenchStatLabel(132), HENCH_BIND_DET_CON, fLblW, fValW, fStatH));
    jInfoCol = JsonArrayInsert(jInfoCol, HenchMakeStatRow(HenchStatLabel(134), HENCH_BIND_DET_INT, fLblW, fValW, fStatH));
    jInfoCol = JsonArrayInsert(jInfoCol, HenchMakeStatRow(HenchStatLabel(136), HENCH_BIND_DET_WIS, fLblW, fValW, fStatH));
    jInfoCol = JsonArrayInsert(jInfoCol, HenchMakeStatRow(HenchStatLabel(131), HENCH_BIND_DET_CHA, fLblW, fValW, fStatH));
    jInfoCol = JsonArrayInsert(jInfoCol, HenchMakeStatRow(HenchStatLabel(320), HENCH_BIND_DET_HP,  fLblW, fValW, fStatH));
    jInfoCol = JsonArrayInsert(jInfoCol, HenchMakeStatRow(HenchStatLabel(321), HENCH_BIND_DET_AC,  fLblW, fValW, fStatH));
    jInfoCol = JsonArrayInsert(jInfoCol, CreateEmptyRow(oPC, 6.0));
    jInfoCol = JsonArrayInsert(jInfoCol, jDesc);

    return NuiGroup(NuiCol(jInfoCol), TRUE, NUI_SCROLLBARS_AUTO);
}

// ============================================================
// Hire layout: detail panel (280px) + roster list + Hire button
// ============================================================

json HenchBuildHireLayout(object oPC)
{
    float fRowH   = GetNuiScaleDimension(oPC, 60.0);
    float fBtnH   = GetNuiScaleDimension(oPC, 30.0);
    float fBtnW   = GetNuiScaleDimension(oPC, 120.0);
    float fDetW   = GetNuiScaleDimension(oPC, 280.0);
    float fPad    = GetNuiScaleDimension(oPC, 20.0);
    float fColW   = GetNuiScaleDimension(oPC, HENCH_WIN_W - 40.0);
    float fListH  = GetNuiScaleDimension(oPC, HENCH_SWAP_H - 60.0);

    json jDetailPanel = HenchBuildDetailPanel(oPC);
    jDetailPanel = NuiVisible(jDetailPanel, NuiBind(HENCH_BIND_DET_VIS));
    jDetailPanel = NuiWidth(jDetailPanel, fDetW);
    jDetailPanel = NuiHeight(jDetailPanel, fListH);

    json jList = NuiList(HenchBuildRosterCell(oPC), NuiBind("h_row_count"), fRowH);
    jList = NuiHeight(jList, fListH);
    json jListCol = JsonArray();
    jListCol = JsonArrayInsert(jListCol, jList);

    json jHireBtn = NuiId(NuiButton(JsonString("Hire")), HENCH_BTN_HIRE);
    jHireBtn = NuiEnabled(jHireBtn, NuiBind(HENCH_BIND_HIRE_EN));
    jHireBtn = NuiWidth(jHireBtn,  fBtnW);
    jHireBtn = NuiHeight(jHireBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jHireBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    json jContentRow = JsonArray();
    jContentRow = JsonArrayInsert(jContentRow, jDetailPanel);
    jContentRow = JsonArrayInsert(jContentRow, NuiCol(jListCol));

    json jInner = JsonArray();
    jInner = JsonArrayInsert(jInner, NuiRow(jContentRow));
    jInner = JsonArrayInsert(jInner, NuiRow(jBtnRow));

    json jInnerCol = NuiCol(jInner);
    jInnerCol = NuiWidth(jInnerCol, fColW);

    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiSpacer(), fPad));
    jMainRow = JsonArrayInsert(jMainRow, jInnerCol);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiSpacer(), fPad));

    return NuiRow(jMainRow);
}

// ============================================================
// Fire layout: same detail panel (full width) + Dismiss button
// ============================================================

json HenchBuildFireLayout(object oPC)
{
    float fBtnH   = GetNuiScaleDimension(oPC, 30.0);
    float fBtnW   = GetNuiScaleDimension(oPC, 120.0);
    float fPad    = GetNuiScaleDimension(oPC, 20.0);
    float fDetW   = GetNuiScaleDimension(oPC, HENCH_WIN_W - 40.0);
    float fListH  = GetNuiScaleDimension(oPC, HENCH_SWAP_H - 60.0);

    json jDetailPanel = HenchBuildDetailPanel(oPC);
    jDetailPanel = NuiWidth(jDetailPanel, fDetW);
    jDetailPanel = NuiHeight(jDetailPanel, fListH);

    json jFireBtn = NuiId(NuiButton(JsonString("Dismiss")), HENCH_BTN_FIRE);
    jFireBtn = NuiWidth(jFireBtn,  fBtnW);
    jFireBtn = NuiHeight(jFireBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jFireBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    json jInner = JsonArray();
    jInner = JsonArrayInsert(jInner, jDetailPanel);
    jInner = JsonArrayInsert(jInner, NuiRow(jBtnRow));

    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiSpacer(), fPad));
    jMainRow = JsonArrayInsert(jMainRow, NuiCol(jInner));
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiSpacer(), fPad));

    return NuiRow(jMainRow);
}

// ============================================================
// FireDead layout: portrait + name + "Deceased" (red) + Resurrect/Dismiss
// ============================================================

json HenchBuildFireDeadLayout(object oPC)
{
    float fPad     = GetNuiScaleDimension(oPC, 20.0);
    float fPadTop  = GetNuiScaleDimension(oPC, 60.0);
    float fPortW   = GetNuiScaleDimension(oPC, 128.0);
    float fPortH   = GetNuiScaleDimension(oPC, 200.0);
    float fNameH   = GetNuiScaleDimension(oPC, 24.0);
    float fDeadH   = GetNuiScaleDimension(oPC, 40.0);
    float fBtnH    = GetNuiScaleDimension(oPC, 30.0);
    float fResW    = GetNuiScaleDimension(oPC, 180.0);
    float fFireW   = GetNuiScaleDimension(oPC, 120.0);
    float fGap     = GetNuiScaleDimension(oPC, 20.0);

    // --- Portrait (centered in row)
    json jPort = NuiImage(NuiBind(HENCH_BIND_DEAD_PORT),
        JsonInt(NUI_ASPECT_FILL),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_TOP));
    jPort = NuiWidth(jPort,  fPortW);
    jPort = NuiHeight(jPort, fPortH);

    json jPortRow = JsonArray();
    jPortRow = JsonArrayInsert(jPortRow, NuiSpacer());
    jPortRow = JsonArrayInsert(jPortRow, jPort);
    jPortRow = JsonArrayInsert(jPortRow, NuiSpacer());

    // --- Imie henchmana (centrowane)
    json jName = NuiLabel(NuiBind(HENCH_BIND_DEAD_NAME),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiHeight(jName, fNameH);

    // --- "Deceased" (red, prominent)
    json jDead = NuiLabel(JsonString("Deceased"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDead = NuiStyleForegroundColor(jDead, NuiColor(220, 60, 60));
    jDead = NuiHeight(jDead, fDeadH);

    // --- Buttons (Resurrect + Dismiss)
    json jResBtn = NuiId(NuiButton(NuiBind(HENCH_BIND_RES_LABEL)), HENCH_BTN_RESURRECT);
    jResBtn = NuiEnabled(jResBtn, NuiBind(HENCH_BIND_RES_EN));
    jResBtn = NuiWidth(jResBtn,  fResW);
    jResBtn = NuiHeight(jResBtn, fBtnH);

    json jFireBtn = NuiId(NuiButton(JsonString("Dismiss")), HENCH_BTN_FIRE);
    jFireBtn = NuiWidth(jFireBtn,  fFireW);
    jFireBtn = NuiHeight(jFireBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jResBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiWidth(NuiSpacer(), fGap));
    jBtnRow = JsonArrayInsert(jBtnRow, jFireBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    // --- Inner col (wszystko ukladane pionowo)
    json jInner = JsonArray();
    jInner = JsonArrayInsert(jInner, NuiHeight(NuiSpacer(), fPadTop));
    jInner = JsonArrayInsert(jInner, NuiRow(jPortRow));
    jInner = JsonArrayInsert(jInner, jName);
    jInner = JsonArrayInsert(jInner, jDead);
    jInner = JsonArrayInsert(jInner, NuiSpacer());           // elastic ? pushes buttons down
    jInner = JsonArrayInsert(jInner, NuiRow(jBtnRow));
    jInner = JsonArrayInsert(jInner, NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, 20.0)));

    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiSpacer(), fPad));
    jMainRow = JsonArrayInsert(jMainRow, NuiCol(jInner));
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiSpacer(), fPad));

    return NuiRow(jMainRow);
}

// ============================================================
// CreateHenchWindow
// ============================================================

void CreateHenchWindow(object oPC)
{
    if(NuiFindWindow(oPC, HENCH_WINDOW) != 0)
        return;

    float fW    = HENCH_WIN_W;
    float fH    = HENCH_WIN_H;
    float fPadT = GetNuiScaleDimension(oPC, 30.0);
    float fPadB = GetNuiScaleDimension(oPC, 16.0);

    // --- Close button
    json jCloseBtn = NuiId(NuiButton(JsonString("X")), HENCH_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn,  GetNuiScaleDimension(oPC, 28.0));
    jCloseBtn = NuiHeight(jCloseBtn, GetNuiScaleDimension(oPC, 24.0));
    json jCloseRow = JsonArray();
    jCloseRow = JsonArrayInsert(jCloseRow, NuiSpacer());
    jCloseRow = JsonArrayInsert(jCloseRow, jCloseBtn);
    jCloseRow = JsonArrayInsert(jCloseRow,
        NuiWidth(NuiSpacer(), GetNuiScaleDimension(oPC, 8.0)));

    // --- Pick initial layout (Hire / FireAlive / FireDead)
    int bHasHench = GetIsObjectValid(GetHenchman(oPC));
    int bIsDead   = FALSE;
    if(!bHasHench)
    {
        json jRec = HenchLoadRecord(GetObjectUUID(oPC));
        if(JsonGetType(jRec) != JSON_TYPE_NULL)
            bIsDead = (JsonGetInt(JsonObjectGet(jRec, "is_dead")) == 1);
    }

    json jInitLayout;
    if(bHasHench)        jInitLayout = HenchBuildFireLayout(oPC);
    else if(bIsDead)     jInitLayout = HenchBuildFireDeadLayout(oPC);
    else                 jInitLayout = HenchBuildHireLayout(oPC);

    // --- Swap group
    json jSwapGroup = NuiGroup(jInitLayout, FALSE, NUI_SCROLLBARS_NONE);
    jSwapGroup = NuiId(jSwapGroup, HENCH_GROUP_MAIN);
    jSwapGroup = NuiHeight(jSwapGroup, GetNuiScaleDimension(oPC, HENCH_SWAP_H));

    // --- Root kolumna
    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiHeight(NuiSpacer(), fPadT));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jCloseRow));
    jRoot = JsonArrayInsert(jRoot, jSwapGroup);
    jRoot = JsonArrayInsert(jRoot, NuiSpacer());

    // --- Tlo DrawList ORDER_BEFORE
    json jBgImg = NuiDrawListImage(
        JsonBool(TRUE), JsonString("hench_bg"),
        NuiRect(0.0, 0.0, fW, fH),
        JsonInt(NUI_ASPECT_STRETCH), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE),
        NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);
    json jBgList = JsonArrayInsert(JsonArray(), jBgImg);

    json jRootCol = NuiDrawList(NuiCol(jRoot), JsonBool(FALSE), jBgList);

    // --- Geometria (wycentrowane)
    int nW = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH);
    int nH = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT);
    float fX = (IntToFloat(nW) - fW) / 2.0;
    float fY = (IntToFloat(nH) - fH) / 2.0;

    int nToken = NuiCreate(oPC, NuiWindow(
        jRootCol,
        JsonString(""),
        NuiBind(WINDOW_GEOMETRY),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE)
    ), HENCH_WINDOW, HENCH_EVT_SCRIPT);

    SetLocalInt(oPC, HENCH_LVAR_TOKEN,   nToken);
    SetLocalInt(oPC, HENCH_LVAR_SEL_IDX, -1);

    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY, NuiRect(fX, fY, fW, fH));

    if(bHasHench)
        FeedFireLayout(oPC, nToken);
    else if(bIsDead)
        FeedFireDeadLayout(oPC, nToken);
    else
    {
        NuiSetBind(oPC, nToken, HENCH_BIND_HIRE_EN, JsonBool(FALSE));
        FeedRosterList(oPC, nToken);
        FeedDetailPanel(oPC, nToken, -1);
    }
}

// ============================================================
// Feed funkcje
// ============================================================

void FeedRosterList(object oPC, int nToken)
{
    json jRoster = GetLocalJson(GetModule(), HENCH_MOD_ROSTER);
    if(JsonGetType(jRoster) != JSON_TYPE_ARRAY)
    {
        NuiSetBind(oPC, nToken, "h_row_count", JsonInt(0));
        return;
    }

    int nCount = JsonGetLength(jRoster);
    int nSel   = GetLocalInt(oPC, HENCH_LVAR_SEL_IDX);

    json jPorts = JsonArray();
    json jNames = JsonArray();
    json jCls   = JsonArray();
    json jEncs  = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jE = JsonArrayGet(jRoster, i);
        jPorts = JsonArrayInsert(jPorts, JsonObjectGet(jE, "portrait"));
        jNames = JsonArrayInsert(jNames, JsonObjectGet(jE, "name"));
        jCls   = JsonArrayInsert(jCls,   JsonObjectGet(jE, "class_str"));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(FALSE));
    }

    NuiSetBind(oPC, nToken, HENCH_BIND_PORT,  jPorts);
    NuiSetBind(oPC, nToken, HENCH_BIND_NAME,  jNames);
    NuiSetBind(oPC, nToken, HENCH_BIND_CLASS, jCls);

    NuiSetBind(oPC, nToken, HENCH_BIND_ENC, jEncs);
    if(nSel >= 0 && nSel < nCount)
    {
        NuiOffEncouragedData(oPC, nToken, HENCH_BIND_ENC);
        NuiOnEncouragedData(oPC, nToken, HENCH_BIND_ENC, nSel);
    }

    NuiSetBind(oPC, nToken, "h_row_count", JsonInt(nCount));
}

void FeedDetailPanel(object oPC, int nToken, int nIdx)
{
    int bHasHench = GetIsObjectValid(GetHenchman(oPC));

    if(nIdx < 0)
    {
        NuiSetBind(oPC, nToken, HENCH_BIND_DET_PORT, JsonString(""));
        NuiSetBind(oPC, nToken, HENCH_BIND_DET_NAME, JsonString(""));
        NuiSetBind(oPC, nToken, HENCH_BIND_DET_CLS,  JsonString(""));
        NuiSetBind(oPC, nToken, HENCH_BIND_DET_STR,  JsonString(""));
        NuiSetBind(oPC, nToken, HENCH_BIND_DET_DEX,  JsonString(""));
        NuiSetBind(oPC, nToken, HENCH_BIND_DET_CON,  JsonString(""));
        NuiSetBind(oPC, nToken, HENCH_BIND_DET_INT,  JsonString(""));
        NuiSetBind(oPC, nToken, HENCH_BIND_DET_WIS,  JsonString(""));
        NuiSetBind(oPC, nToken, HENCH_BIND_DET_CHA,  JsonString(""));
        NuiSetBind(oPC, nToken, HENCH_BIND_DET_HP,   JsonString(""));
        NuiSetBind(oPC, nToken, HENCH_BIND_DET_AC,   JsonString(""));
        NuiSetBind(oPC, nToken, HENCH_BIND_DET_DESC, JsonString(""));
        NuiSetBind(oPC, nToken, HENCH_BIND_DET_VIS,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, HENCH_BIND_HIRE_EN,  JsonBool(FALSE));
        return;
    }

    json jRoster = GetLocalJson(GetModule(), HENCH_MOD_ROSTER);
    if(JsonGetType(jRoster) != JSON_TYPE_ARRAY) return;
    if(nIdx >= JsonGetLength(jRoster)) return;

    json jE = JsonArrayGet(jRoster, nIdx);

    NuiSetBind(oPC, nToken, HENCH_BIND_DET_PORT, JsonObjectGet(jE, "portrait"));
    NuiSetBind(oPC, nToken, HENCH_BIND_DET_NAME, JsonObjectGet(jE, "name"));
    NuiSetBind(oPC, nToken, HENCH_BIND_DET_CLS,  JsonObjectGet(jE, "class_str"));

    NuiSetBind(oPC, nToken, HENCH_BIND_DET_STR,
        JsonString(IntToString(JsonGetInt(JsonObjectGet(jE, "str")))));
    NuiSetBind(oPC, nToken, HENCH_BIND_DET_DEX,
        JsonString(IntToString(JsonGetInt(JsonObjectGet(jE, "dex")))));
    NuiSetBind(oPC, nToken, HENCH_BIND_DET_CON,
        JsonString(IntToString(JsonGetInt(JsonObjectGet(jE, "con")))));
    NuiSetBind(oPC, nToken, HENCH_BIND_DET_INT,
        JsonString(IntToString(JsonGetInt(JsonObjectGet(jE, "int")))));
    NuiSetBind(oPC, nToken, HENCH_BIND_DET_WIS,
        JsonString(IntToString(JsonGetInt(JsonObjectGet(jE, "wis")))));
    NuiSetBind(oPC, nToken, HENCH_BIND_DET_CHA,
        JsonString(IntToString(JsonGetInt(JsonObjectGet(jE, "cha")))));

    NuiSetBind(oPC, nToken, HENCH_BIND_DET_HP,
        JsonString(IntToString(JsonGetInt(JsonObjectGet(jE, "hp")))));
    NuiSetBind(oPC, nToken, HENCH_BIND_DET_AC,
        JsonString(IntToString(JsonGetInt(JsonObjectGet(jE, "ac")))));

    NuiSetBind(oPC, nToken, HENCH_BIND_DET_DESC, JsonObjectGet(jE, "desc"));

    NuiSetBind(oPC, nToken, HENCH_BIND_DET_VIS,  JsonBool(TRUE));
    NuiSetBind(oPC, nToken, HENCH_BIND_HIRE_EN,  JsonBool(!bHasHench));
}

void FeedFireLayout(object oPC, int nToken)
{
    object oHench = GetHenchman(oPC);
    if(!GetIsObjectValid(oHench)) return;

    NuiSetBind(oPC, nToken, HENCH_BIND_DET_PORT,
        JsonString(GetPortraitResRef(oHench) + "L"));
    NuiSetBind(oPC, nToken, HENCH_BIND_DET_NAME,
        JsonString(GetName(oHench)));
    NuiSetBind(oPC, nToken, HENCH_BIND_DET_CLS,
        JsonString(HenchClassString(oHench)));
    NuiSetBind(oPC, nToken, HENCH_BIND_DET_STR,
        JsonString(IntToString(GetAbilityScore(oHench, ABILITY_STRENGTH, TRUE))));
    NuiSetBind(oPC, nToken, HENCH_BIND_DET_DEX,
        JsonString(IntToString(GetAbilityScore(oHench, ABILITY_DEXTERITY, TRUE))));
    NuiSetBind(oPC, nToken, HENCH_BIND_DET_CON,
        JsonString(IntToString(GetAbilityScore(oHench, ABILITY_CONSTITUTION, TRUE))));
    NuiSetBind(oPC, nToken, HENCH_BIND_DET_INT,
        JsonString(IntToString(GetAbilityScore(oHench, ABILITY_INTELLIGENCE, TRUE))));
    NuiSetBind(oPC, nToken, HENCH_BIND_DET_WIS,
        JsonString(IntToString(GetAbilityScore(oHench, ABILITY_WISDOM, TRUE))));
    NuiSetBind(oPC, nToken, HENCH_BIND_DET_CHA,
        JsonString(IntToString(GetAbilityScore(oHench, ABILITY_CHARISMA, TRUE))));
    NuiSetBind(oPC, nToken, HENCH_BIND_DET_HP,
        JsonString(IntToString(GetCurrentHitPoints(oHench)) + "/" + IntToString(GetMaxHitPoints(oHench))));
    NuiSetBind(oPC, nToken, HENCH_BIND_DET_AC,
        JsonString(IntToString(GetAC(oHench))));
    NuiSetBind(oPC, nToken, HENCH_BIND_DET_DESC,
        JsonString(GetDescription(oHench)));
}

// ============================================================
// FeedFireDeadLayout - simplified state after henchman death
// ============================================================

void FeedFireDeadLayout(object oPC, int nToken)
{
    json jRec = HenchLoadRecord(GetObjectUUID(oPC));
    if(JsonGetType(jRec) == JSON_TYPE_NULL) return;

    string sResRef = JsonGetString(JsonObjectGet(jRec, "resref"));
    json jE = HenchGetRosterEntry(sResRef);
    if(JsonGetType(jE) == JSON_TYPE_NULL) return;

    string sName = JsonGetString(JsonObjectGet(jE, "name"));
    string sPort = JsonGetString(JsonObjectGet(jE, "portrait"));
    int    nCost = HenchGetResurrectCost(sResRef);
    int    bCanPay = (GetGold(oPC) >= nCost);

    NuiSetBind(oPC, nToken, HENCH_BIND_DEAD_PORT, JsonString(sPort));
    NuiSetBind(oPC, nToken, HENCH_BIND_DEAD_NAME, JsonString(sName));
    NuiSetBind(oPC, nToken, HENCH_BIND_RES_LABEL,
        JsonString("Resurrect (" + IntToString(nCost) + " gp)"));
    NuiSetBind(oPC, nToken, HENCH_BIND_RES_EN, JsonBool(bCanPay));
}

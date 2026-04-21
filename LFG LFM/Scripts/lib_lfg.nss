// lib_lfg.nss
// LFG/LFM system - NUI layouts, swap, feed, tick

#include "lib_lfg_def"
#include "lib_nui"

// Forward declarations
void LfgSwapToStart(object oPC, int nToken);
void LfgSwapToCategories(object oPC, int nToken);
void LfgSwapToLfmForm(object oPC, int nToken);
void LfgSwapToLfmActive(object oPC, int nToken);
void LfgSwapToLfgList(object oPC, int nToken, string sPrev = "start");
void LfgFeedLfmForm(object oPC, int nToken);
void LfgFeedLfmActive(object oPC, int nToken);
void LfgFeedLfgList(object oPC, int nToken);
void LfgTick(object oPC, int nToken);

// ============================================================
// Bind name constants
// ============================================================
const string LFG_BIND_GEOM         = "LFG_GEOM";

// LFM form
const string LFG_BIND_FORM_NAME    = "LFG_FN";
const string LFG_BIND_FORM_DESC    = "LFG_FD";
const string LFG_BIND_FORM_CAT_SEL = "LFG_FCS";
const string LFG_BIND_FORM_CAT_EN  = "LFG_FCE";
const string LFG_BIND_FORM_LIMIT   = "LFG_FL";
const string LFG_BIND_FORM_LVLMIN  = "LFG_FMN";
const string LFG_BIND_FORM_LVLMAX  = "LFG_FMX";
const string LFG_BIND_FORM_CL_SEL  = "LFG_FKS";
const string LFG_BIND_FORM_CL_ENT  = "LFG_FKE";
const string LFG_BIND_FORM_RST_N   = "LFG_FRN";
const string LFG_BIND_FORM_RST_I   = "LFG_FRI";
const string LFG_BIND_FORM_RST_LEN = "LFG_FRL";
const string LFG_BIND_CRE_EN       = "LFG_CREN";
const string LFG_BIND_FORM_CAT_ENT = "LFG_FCENT";

// LFM active (pending list)
const string LFG_BIND_PEND_NAMES   = "LFG_PN";
const string LFG_BIND_PEND_CLS     = "LFG_PC";
const string LFG_BIND_PEND_INV_EN  = "LFG_PIE";
const string LFG_BIND_PEND_LEN     = "LFG_PL";

// LFG list
const string LFG_BIND_LIST_CICO    = "LFG_LCI";
const string LFG_BIND_LIST_NAME    = "LFG_LNM";
const string LFG_BIND_LIST_INFO    = "LFG_LIN";
const string LFG_BIND_LIST_CLS     = "LFG_LCL";
const string LFG_BIND_LIST_DESC    = "LFG_LDS";
const string LFG_BIND_LIST_DTIP    = "LFG_LDT";
const string LFG_BIND_LIST_BLBL    = "LFG_LBL";
const string LFG_BIND_LIST_BEN     = "LFG_LBE";
const string LFG_BIND_LIST_LEN     = "LFG_LLN";

// ============================================================
// Button ID constants
// ============================================================
const string LFG_BTN_LFM          = "LFG_BLFM";
const string LFG_BTN_LFG          = "LFG_BLFG";
const string LFG_BTN_LIST         = "LFG_BLIS";
const string LFG_BTN_BACK         = "LFG_BBCK";
const string LFG_BTN_CAT_EXP      = "LFG_BCEX";
const string LFG_BTN_CAT_DUN      = "LFG_BCDU";
const string LFG_BTN_CAT_RP       = "LFG_BCRP";
const string LFG_BTN_CAT_PVP      = "LFG_BCPV";
const string LFG_BTN_CAT_ALL      = "LFG_BCAL";
const string LFG_BTN_FORM_ADD     = "LFG_BFAD";
const string LFG_BTN_FORM_REM     = "LFG_BFRM";
const string LFG_BTN_FORM_CRE     = "LFG_BFCR";
const string LFG_BTN_FORM_BAK     = "LFG_BFBK";
const string LFG_BTN_ACT_INV      = "LFG_BAIN";
const string LFG_BTN_ACT_CAN      = "LFG_BACAN";
const string LFG_BTN_LIST_ACT     = "LFG_BLAC";
const string LFG_BTN_LIST_ROW     = "LFG_BLRW";
const string LFG_BTN_CLOSE        = "LFG_BCLS";

// Visibility binds
const string LFG_BIND_BACK_VIS    = "LFG_BKVIS";

// ============================================================
// LVAR on PC (event handler data)
// ============================================================
const string LFG_LVAR_LIST_UUIDS  = "LFG_LUUIDS";
const string LFG_LVAR_PEND_UUIDS  = "LFG_PUUIDS";
const string LFG_LVAR_FORM_CL_IDS = "LFG_FCIDS";
const string LFG_LVAR_FORM_CL_AV  = "LFG_FCAV";

// ============================================================
// Sizes (design pixels)
// ============================================================
const float LFG_ICO_LG  = 180.0;
const float LFG_ICO_MD  = 110.0;
const float LFG_ICO_SM  = 70.0;
const float LFG_ROW_H   = 60.0;
const float LFG_LIST_H  = 700.0;

// ============================================================
// Helper - icon button (NuiButton + DrawList ORDER_AFTER)
// ============================================================
json LfgIconBtn(object oPC, string sBtnId, string sResref, float fSize, string sTooltip = "")
{
    float fS = GetNuiScaleDimension(oPC, fSize);

    json jBtn = NuiId(NuiButton(JsonString("")), sBtnId);
    jBtn = NuiWidth(jBtn, fS);
    jBtn = NuiHeight(jBtn, fS);
    if(sTooltip != "")
        jBtn = NuiTooltip(jBtn, JsonString(sTooltip));

    json jChildren = JsonArrayInsert(JsonArray(), jBtn);
    json jContainer = NuiGroup(NuiCol(jChildren), FALSE, NUI_SCROLLBARS_NONE);
    jContainer = NuiWidth(jContainer, fS);
    jContainer = NuiHeight(jContainer, fS);

    float fOffset = GetNuiScaleDimension(oPC, 15.0);
    json jImg = NuiDrawListImage(
        JsonBool(TRUE),
        JsonString(sResref),
        NuiRect(-fOffset, -fOffset, fS + fOffset * 2.0, fS + fOffset * 2.0),
        JsonInt(NUI_ASPECT_STRETCH),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);
    json jDl = JsonArrayInsert(JsonArray(), jImg);
    jContainer = NuiDrawList(jContainer, JsonBool(FALSE), jDl);

    return jContainer;
}

// ============================================================
// BuildViewStart - start screen (LFG / LFM / LIST)
// ============================================================
json LfgBuildViewStart(object oPC, int nToken)
{
    string sUuid  = GetObjectUUID(oPC);
    int bHasApps  = LfgApplicantGetCount(sUuid) > 0;

    json jCenter = JsonArray();
    jCenter = JsonArrayInsert(jCenter, NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, 275.0)));
    jCenter = JsonArrayInsert(jCenter, LfgIconBtn(oPC, LFG_BTN_LFM, LFG_RES_LFM, LFG_ICO_LG, LFG_TIP_LFM));
    jCenter = JsonArrayInsert(jCenter, NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, 100.0)));
    jCenter = JsonArrayInsert(jCenter, LfgIconBtn(oPC, LFG_BTN_LFG, LFG_RES_LFG, LFG_ICO_LG, LFG_TIP_LFG));

    if(bHasApps)
    {
        jCenter = JsonArrayInsert(jCenter, NuiSpacer());
        jCenter = JsonArrayInsert(jCenter, LfgIconBtn(oPC, LFG_BTN_LIST, LFG_RES_LIST, LFG_ICO_MD, LFG_TIP_LIST));
    }

    jCenter = JsonArrayInsert(jCenter, NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, 300.0)));

    json jSideCol = JsonArrayInsert(JsonArray(), NuiSpacer());
    json jCol1 = NuiWidth(NuiCol(jSideCol), GetNuiScaleDimension(oPC, 650.0));

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jCol1);
    jRow = JsonArrayInsert(jRow, NuiCol(jCenter));
    jRow = JsonArrayInsert(jRow, NuiCol(jSideCol));

    return NuiRow(jRow);
}

// ============================================================
// BuildViewCategories - EXP / Dungeon / RP / PvP / ALL + back
// ============================================================
json LfgBuildViewCategories(object oPC, int nToken, string sTitle)
{
    json jSpacer = NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, 50.0));

    json jLabel = NuiLabel(JsonString(sTitle), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLabel = NuiWidth(jLabel, GetNuiScaleDimension(oPC, 300.0));
    jLabel = NuiStyleForegroundColor(jLabel, NuiColor(255, 255, 255));

    json jLabelRow = JsonArray();
    jLabelRow = JsonArrayInsert(jLabelRow, NuiWidth(NuiSpacer(), GetNuiScaleDimension(oPC, 40.0)));
    jLabelRow = JsonArrayInsert(jLabelRow, jLabel);
    jLabelRow = JsonArrayInsert(jLabelRow, NuiSpacer());

    json jCenter = JsonArray();
    jCenter = JsonArrayInsert(jCenter, NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, 50.0)));
    jCenter = JsonArrayInsert(jCenter, NuiRow(jLabelRow));
    jCenter = JsonArrayInsert(jCenter, NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, 50.0)));
    jCenter = JsonArrayInsert(jCenter, LfgIconBtn(oPC, LFG_BTN_CAT_EXP, LFG_RES_EXP,     LFG_ICO_MD, LFG_TIP_EXP));
    jCenter = JsonArrayInsert(jCenter, jSpacer);
    jCenter = JsonArrayInsert(jCenter, LfgIconBtn(oPC, LFG_BTN_CAT_DUN, LFG_RES_DUNGEON, LFG_ICO_MD, LFG_TIP_DUNGEON));
    jCenter = JsonArrayInsert(jCenter, jSpacer);
    jCenter = JsonArrayInsert(jCenter, LfgIconBtn(oPC, LFG_BTN_CAT_RP,  LFG_RES_RP,      LFG_ICO_MD, LFG_TIP_RP));
    jCenter = JsonArrayInsert(jCenter, jSpacer);
    jCenter = JsonArrayInsert(jCenter, LfgIconBtn(oPC, LFG_BTN_CAT_PVP, LFG_RES_PVP,     LFG_ICO_MD, LFG_TIP_PVP));
    jCenter = JsonArrayInsert(jCenter, jSpacer);
    jCenter = JsonArrayInsert(jCenter, LfgIconBtn(oPC, LFG_BTN_CAT_ALL, LFG_RES_ALL,     LFG_ICO_MD, LFG_TIP_ALL));
    jCenter = JsonArrayInsert(jCenter, NuiSpacer());

    json jSideCol = JsonArrayInsert(JsonArray(), NuiSpacer());
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiCol(jSideCol), GetNuiScaleDimension(oPC, 700.0)));
    jRow = JsonArrayInsert(jRow, NuiCol(jCenter));
    jRow = JsonArrayInsert(jRow, NuiCol(jSideCol));

    return NuiRow(jRow);
}

// ============================================================
// BuildViewLfmForm - LFM creation form
// ============================================================
json LfgBuildViewLfmForm(object oPC, int nToken)
{
    json jCol = JsonArray();

    // Name
    json jRowName = JsonArray();
    jRowName = JsonArrayInsert(jRowName, NuiWidth(NuiLabel(JsonString("Name:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), GetNuiScaleDimension(oPC, 80.0)));
    json jName = NuiTextEdit(JsonString("Group name"), NuiBind(LFG_BIND_FORM_NAME), 64, FALSE);
    jRowName = JsonArrayInsert(jRowName, jName);
    jCol = JsonArrayInsert(jCol, NuiRow(jRowName));

    // Description
    json jRowDesc = JsonArray();
    jRowDesc = JsonArrayInsert(jRowDesc, NuiWidth(NuiLabel(JsonString("Desc:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), GetNuiScaleDimension(oPC, 80.0)));
    json jDesc = NuiTextEdit(JsonString("Short description"), NuiBind(LFG_BIND_FORM_DESC), 200, FALSE);
    jRowDesc = JsonArrayInsert(jRowDesc, jDesc);
    jCol = JsonArrayInsert(jCol, NuiRow(jRowDesc));

    // Category dropdown
    json jRowCat = JsonArray();
    jRowCat = JsonArrayInsert(jRowCat, NuiWidth(NuiLabel(JsonString("Type:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), GetNuiScaleDimension(oPC, 80.0)));
    json jCat = NuiCombo(NuiBind(LFG_BIND_FORM_CAT_ENT), NuiBind(LFG_BIND_FORM_CAT_SEL));
    jCat = NuiEnabled(jCat, NuiBind(LFG_BIND_FORM_CAT_EN));
    jRowCat = JsonArrayInsert(jRowCat, jCat);
    jCol = JsonArrayInsert(jCol, NuiRow(jRowCat));

    // Level range
    json jRowLvl = JsonArray();
    jRowLvl = JsonArrayInsert(jRowLvl, NuiWidth(NuiLabel(JsonString("Level:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), GetNuiScaleDimension(oPC, 80.0)));
    json jMin = NuiTextEdit(JsonString("Min"), NuiBind(LFG_BIND_FORM_LVLMIN), 3, FALSE);
    jMin = NuiWidth(jMin, GetNuiScaleDimension(oPC, 60.0));
    json jMax = NuiTextEdit(JsonString("Max"), NuiBind(LFG_BIND_FORM_LVLMAX), 3, FALSE);
    jMax = NuiWidth(jMax, GetNuiScaleDimension(oPC, 60.0));
    jRowLvl = JsonArrayInsert(jRowLvl, jMin);
    jRowLvl = JsonArrayInsert(jRowLvl, NuiWidth(NuiLabel(JsonString("-"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)), GetNuiScaleDimension(oPC, 20.0)));
    jRowLvl = JsonArrayInsert(jRowLvl, jMax);
    jCol = JsonArrayInsert(jCol, NuiRow(jRowLvl));

    // Limit
    json jRowLim = JsonArray();
    jRowLim = JsonArrayInsert(jRowLim, NuiWidth(NuiLabel(JsonString("Slots:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), GetNuiScaleDimension(oPC, 80.0)));
    json jLim = NuiTextEdit(JsonString("0"), NuiBind(LFG_BIND_FORM_LIMIT), 2, FALSE);
    jLim = NuiWidth(jLim, GetNuiScaleDimension(oPC, 50.0));
    jRowLim = JsonArrayInsert(jRowLim, jLim);
    jRowLim = JsonArrayInsert(jRowLim, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jRowLim));

    // Class restriction - combo + Add button
    json jRowCls = JsonArray();
    jRowCls = JsonArrayInsert(jRowCls, NuiWidth(NuiLabel(JsonString("Class:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), GetNuiScaleDimension(oPC, 80.0)));
    json jClsCmb = NuiCombo(NuiBind(LFG_BIND_FORM_CL_ENT), NuiBind(LFG_BIND_FORM_CL_SEL));
    jClsCmb = NuiHeight(jClsCmb, GetNuiScaleDimension(oPC, 30.0));
    jRowCls = JsonArrayInsert(jRowCls, jClsCmb);
    json jBtnAdd = NuiId(NuiButton(JsonString("Add")), LFG_BTN_FORM_ADD);
    jBtnAdd = NuiWidth(jBtnAdd, GetNuiScaleDimension(oPC, 60.0));
    jBtnAdd = NuiHeight(jBtnAdd, GetNuiScaleDimension(oPC, 30.0));
    jRowCls = JsonArrayInsert(jRowCls, jBtnAdd);
    jCol = JsonArrayInsert(jCol, NuiRow(jRowCls));

    // Class restriction list
    json jRstRow = JsonArray();
    json jRstIcon = NuiImage(NuiBind(LFG_BIND_FORM_RST_I), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jRstIcon = NuiWidth(jRstIcon, GetNuiScaleDimension(oPC, 44.0));
    jRstIcon = NuiHeight(jRstIcon, GetNuiScaleDimension(oPC, 44.0));
    json jRstName = NuiLabel(NuiBind(LFG_BIND_FORM_RST_N), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jRstRem  = NuiId(NuiButton(JsonString("X")), LFG_BTN_FORM_REM);
    jRstRem = NuiWidth(jRstRem, GetNuiScaleDimension(oPC, 30.0));

    jRstRow = JsonArrayInsert(jRstRow, jRstIcon);
    jRstRow = JsonArrayInsert(jRstRow, jRstName);
    jRstRow = JsonArrayInsert(jRstRow, jRstRem);

    json jRstCell = NuiGroup(NuiRow(jRstRow), TRUE, NUI_SCROLLBARS_NONE);
    json jRstTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jRstCell, 0.0, TRUE));
    json jRstList = NuiList(jRstTmpl, NuiBind(LFG_BIND_FORM_RST_LEN), GetNuiScaleDimension(oPC, 60.0), TRUE, NUI_SCROLLBARS_AUTO);
    jRstList = NuiHeight(jRstList, GetNuiScaleDimension(oPC, 400.0));
    jCol = JsonArrayInsert(jCol, jRstList);

    // Buttons row
    json jRowBtns = JsonArray();
    json jBtnCre = NuiId(NuiButton(JsonString("Create")), LFG_BTN_FORM_CRE);
    jBtnCre = NuiEnabled(jBtnCre, NuiBind(LFG_BIND_CRE_EN));
    jBtnCre = NuiWidth(jBtnCre, GetNuiScaleDimension(oPC, 100.0));
    jRowBtns = JsonArrayInsert(jRowBtns, NuiSpacer());
    jRowBtns = JsonArrayInsert(jRowBtns, jBtnCre);
    jRowBtns = JsonArrayInsert(jRowBtns, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jRowBtns));

    json jFormCol = NuiWidth(NuiCol(jCol), GetNuiScaleDimension(oPC, 560.0));

    json jOuter = JsonArray();
    jOuter = JsonArrayInsert(jOuter, NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, 80.0)));
    jOuter = JsonArrayInsert(jOuter, jFormCol);
    jOuter = JsonArrayInsert(jOuter, NuiSpacer());

    json jSideCol = JsonArrayInsert(JsonArray(), NuiSpacer());
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiCol(jSideCol), GetNuiScaleDimension(oPC, 488.0)));
    jRow = JsonArrayInsert(jRow, NuiCol(jOuter));
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiCol(jSideCol), GetNuiScaleDimension(oPC, 488.0)));

    return NuiRow(jRow);
}

// ============================================================
// BuildViewLfmActive - active LFM (pending applications list)
// ============================================================
json LfgBuildViewLfmActive(object oPC, int nToken)
{
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, 40.0)));

    // Pending list header
    json jHdr = NuiLabel(JsonString("Pending Applications"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdr = NuiHeight(jHdr, GetNuiScaleDimension(oPC, 28.0));
    json jHdrRow = JsonArray();
    jHdrRow = JsonArrayInsert(jHdrRow, NuiSpacer());
    jHdrRow = JsonArrayInsert(jHdrRow, jHdr);
    jHdrRow = JsonArrayInsert(jHdrRow, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jHdrRow));

    // Pending NuiList
    // Row: [Name 350px] [Classes - flex] [Invite 100px]
    json jPRow = JsonArray();
    json jPName = NuiLabel(NuiBind(LFG_BIND_PEND_NAMES), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jPName = NuiWidth(jPName, GetNuiScaleDimension(oPC, 350.0));
    json jPCls  = NuiLabel(NuiBind(LFG_BIND_PEND_CLS),   JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jPInv  = NuiId(NuiButton(JsonString("Invite")), LFG_BTN_ACT_INV);
    jPInv = NuiEnabled(jPInv, NuiBind(LFG_BIND_PEND_INV_EN));
    jPInv = NuiWidth(jPInv, GetNuiScaleDimension(oPC, 100.0));

    jPRow = JsonArrayInsert(jPRow, jPName);
    jPRow = JsonArrayInsert(jPRow, jPCls);
    jPRow = JsonArrayInsert(jPRow, jPInv);

    json jPCell = NuiGroup(NuiRow(jPRow), TRUE, NUI_SCROLLBARS_NONE);
    json jPTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jPCell, 0.0, TRUE));
    json jPList = NuiList(jPTmpl, NuiBind(LFG_BIND_PEND_LEN), GetNuiScaleDimension(oPC, 60.0), TRUE, NUI_SCROLLBARS_AUTO);
    jPList = NuiHeight(jPList, GetNuiScaleDimension(oPC, LFG_LIST_H));
    jPList = NuiWidth(jPList, GetNuiScaleDimension(oPC, 570.0));
    jCol = JsonArrayInsert(jCol, jPList);

    // Cancel button (bottom)
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    json jRowCan = JsonArray();
    jRowCan = JsonArrayInsert(jRowCan, NuiSpacer());
    json jBtnCan = NuiId(NuiButton(JsonString("Cancel LFM")), LFG_BTN_ACT_CAN);
    jBtnCan = NuiWidth(jBtnCan, GetNuiScaleDimension(oPC, 150.0));
    jRowCan = JsonArrayInsert(jRowCan, jBtnCan);
    jRowCan = JsonArrayInsert(jRowCan, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jRowCan));

    json jSideCol = JsonArrayInsert(JsonArray(), NuiSpacer());
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiCol(jSideCol), GetNuiScaleDimension(oPC, 470.0)));
    jRow = JsonArrayInsert(jRow, NuiCol(jCol));
    jRow = JsonArrayInsert(jRow, NuiCol(jSideCol));
    return NuiRow(jRow);
}

// ============================================================
// BuildViewLfgList - LFG group list (filtered or all)
// ============================================================
json LfgBuildViewLfgList(object oPC, int nToken)
{
    // Category title
    string sCat = GetLocalString(oPC, LFG_LVAR_CATEGORY);
    string sCatName = "All";
    if(sCat == LFG_CAT_EXP)         sCatName = "Experience";
    else if(sCat == LFG_CAT_DUNGEON) sCatName = "Dungeon";
    else if(sCat == LFG_CAT_RP)      sCatName = "RP";
    else if(sCat == LFG_CAT_PVP)     sCatName = "PvP";

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, 60.0)));

    json jTitle = NuiLabel(JsonString("LFG - " + sCatName), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, GetNuiScaleDimension(oPC, 28.0));
    jTitle = NuiStyleForegroundColor(jTitle, NuiColor(255, 255, 255));
    json jTitleRow = JsonArray();
    jTitleRow = JsonArrayInsert(jTitleRow, NuiSpacer());
    jTitleRow = JsonArrayInsert(jTitleRow, jTitle);
    jTitleRow = JsonArrayInsert(jTitleRow, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jTitleRow));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, 10.0)));

    // List template
    // NuiRow: [Col#1: cat icon 88px] [Col#2: Row1(name, info) + Row2(desc+tooltip) + Row3(classes, Join/Cancel)]
    json jCatIco = NuiImage(NuiBind(LFG_BIND_LIST_CICO), JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jCatIco = NuiWidth(jCatIco, GetNuiScaleDimension(oPC, 88.0));
    jCatIco = NuiHeight(jCatIco, GetNuiScaleDimension(oPC, 88.0));
    json jIcoCol = JsonArray();
    jIcoCol = JsonArrayInsert(jIcoCol, NuiSpacer());
    jIcoCol = JsonArrayInsert(jIcoCol, jCatIco);
    jIcoCol = JsonArrayInsert(jIcoCol, NuiSpacer());

    json jGName  = NuiLabel(NuiBind(LFG_BIND_LIST_NAME), JsonInt(NUI_HALIGN_LEFT),  JsonInt(NUI_VALIGN_MIDDLE));
    jGName = NuiWidth(jGName, GetNuiScaleDimension(oPC, 100.0));
    json jGInfo  = NuiLabel(NuiBind(LFG_BIND_LIST_INFO), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jGName);
    jTopRow = JsonArrayInsert(jTopRow, jGInfo);

    // Row 2: description (short) with full desc tooltip
    json jGDesc  = NuiLabel(NuiBind(LFG_BIND_LIST_DESC), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jGDesc = NuiTooltip(jGDesc, NuiBind(LFG_BIND_LIST_DTIP));
    json jMidRow = JsonArray();
    jMidRow = JsonArrayInsert(jMidRow, jGDesc);

    // Row 3: classes + Join/Cancel button
    json jGCls   = NuiLabel(NuiBind(LFG_BIND_LIST_CLS), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jGAct   = NuiId(NuiButton(NuiBind(LFG_BIND_LIST_BLBL)), LFG_BTN_LIST_ACT);
    jGAct = NuiEnabled(jGAct, NuiBind(LFG_BIND_LIST_BEN));
    jGAct = NuiWidth(jGAct, GetNuiScaleDimension(oPC, 90.0));
    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jGCls);
    jBotRow = JsonArrayInsert(jBotRow, jGAct);

    json jTextCol = JsonArray();
    jTextCol = JsonArrayInsert(jTextCol, NuiRow(jTopRow));
    jTextCol = JsonArrayInsert(jTextCol, NuiRow(jMidRow));
    jTextCol = JsonArrayInsert(jTextCol, NuiRow(jBotRow));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, NuiWidth(NuiCol(jIcoCol), GetNuiScaleDimension(oPC, 98.0)));
    jCellRow = JsonArrayInsert(jCellRow, NuiCol(jTextCol));

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, LFG_BTN_LIST_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(NUI_DATA_ENCOURAGED));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(LFG_BIND_LIST_LEN), GetNuiScaleDimension(oPC, LFG_ROW_H + 60.0), TRUE, NUI_SCROLLBARS_AUTO);
    jList = NuiHeight(jList, GetNuiScaleDimension(oPC, LFG_LIST_H + 100.0));
    jList = NuiWidth(jList, GetNuiScaleDimension(oPC, 570.0));
    jCol = JsonArrayInsert(jCol, jList);

    json jSideCol = JsonArrayInsert(JsonArray(), NuiSpacer());
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiCol(jSideCol), GetNuiScaleDimension(oPC, 470.0)));
    jRow = JsonArrayInsert(jRow, NuiCol(jCol));
    jRow = JsonArrayInsert(jRow, NuiCol(jSideCol));
    return NuiRow(jRow);
}

// ============================================================
// BuildBottomBar - permanent bar: [back] [spacer] [close]
// ============================================================
json LfgBuildBottomBar(object oPC)
{
    json jCol = JsonArray();

    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, 10.0)));

    json jRow2 = JsonArray();
    json jBack = LfgIconBtn(oPC, LFG_BTN_BACK, LFG_RES_BACK, LFG_ICO_SM, LFG_TIP_BACK);
    jBack = NuiVisible(jBack, NuiBind(LFG_BIND_BACK_VIS));

    jRow2 = JsonArrayInsert(jRow2, NuiWidth(NuiSpacer(), GetNuiScaleDimension(oPC, 30.0)));
    jRow2 = JsonArrayInsert(jRow2, jBack);
    jRow2 = JsonArrayInsert(jRow2, NuiSpacer());
    jRow2 = JsonArrayInsert(jRow2, LfgIconBtn(oPC, LFG_BTN_CLOSE, LFG_RES_CLOSE, LFG_ICO_SM, LFG_TIP_CLOSE));
    jRow2 = JsonArrayInsert(jRow2, NuiWidth(NuiSpacer(), GetNuiScaleDimension(oPC, 30.0)));
    jCol = JsonArrayInsert(jCol, NuiRow(jRow2));

    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, 10.0)));

    json jBar = NuiGroup(NuiCol(jCol), FALSE, NUI_SCROLLBARS_NONE);
    jBar = NuiHeight(jBar, GetNuiScaleDimension(oPC, 100.0));
    return jBar;
}

// ============================================================
// CreateLfgWindow
// ============================================================
void CreateLfgWindow(object oPC)
{
    if(GetFactionLeader(oPC) != oPC)
    {
        SendMessageToPC(oPC, "You are not the party leader.");
        return;
    }
    if(NuiFindWindow(oPC, LFG_WINDOW) != 0) return;

    float fW = GetNuiScaleDimension(oPC, LFG_WINDOW_W);
    float fH = GetNuiScaleDimension(oPC, LFG_WINDOW_H);

    json jSwap = NuiGroup(NuiCol(JsonArray()), FALSE, NUI_SCROLLBARS_NONE);
    jSwap = NuiId(jSwap, LFG_SWAP_GROUP);
    json jChildren = JsonArrayInsert(JsonArray(), jSwap);
    jChildren = JsonArrayInsert(jChildren, LfgBuildBottomBar(oPC));
    json jRoot = NuiCol(jChildren);

    json jBgImg = NuiDrawListImage(
        JsonBool(TRUE),
        JsonString(LFG_RES_BG),
        NuiRect(0.0, 0.0, fW, fH),
        JsonInt(NUI_ASPECT_STRETCH),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE),
        NUI_DRAW_LIST_ITEM_ORDER_BEFORE,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);
    json jDl = JsonArrayInsert(JsonArray(), jBgImg);
    jRoot = NuiDrawList(jRoot, JsonBool(FALSE), jDl);

    json jWindow = NuiWindow(
        jRoot,
        JsonBool(FALSE),
        NuiBind(LFG_BIND_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWindow, LFG_WINDOW, LFG_EV_SCRIPT);
    SetLocalInt(oPC, LFG_LVAR_TOKEN, nToken);

    int nW = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH);
    int nH = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT);
    float fX = (IntToFloat(nW) - fW) / 2.0;
    float fY = (IntToFloat(nH) - fH) / 2.0;
    NuiSetBind(oPC, nToken, LFG_BIND_GEOM, NuiRect(fX, fY, fW, fH));

    LfgSwapToStart(oPC, nToken);
}

// ============================================================
// Swap functions
// ============================================================
void LfgSwapToStart(object oPC, int nToken)
{
    DeleteLocalString(oPC, LFG_LVAR_PREV_VIEW);
    NuiSetBind(oPC, nToken, LFG_BIND_BACK_VIS, JsonBool(FALSE));
    NuiSetGroupLayout(oPC, nToken, LFG_SWAP_GROUP, LfgBuildViewStart(oPC, nToken));
}

void LfgSwapToCategories(object oPC, int nToken)
{
    string sMode  = GetLocalString(oPC, LFG_LVAR_MODE);
    string sTitle = (sMode == LFG_MODE_LFM) ? "LFM" : "LFG";
    SetLocalString(oPC, LFG_LVAR_PREV_VIEW, "start");
    NuiSetBind(oPC, nToken, LFG_BIND_BACK_VIS, JsonBool(TRUE));
    NuiSetGroupLayout(oPC, nToken, LFG_SWAP_GROUP, LfgBuildViewCategories(oPC, nToken, sTitle));
}

void LfgSwapToLfmForm(object oPC, int nToken)
{
    SetLocalString(oPC, LFG_LVAR_PREV_VIEW, "categories");
    NuiSetBind(oPC, nToken, LFG_BIND_BACK_VIS, JsonBool(TRUE));
    NuiSetGroupLayout(oPC, nToken, LFG_SWAP_GROUP, LfgBuildViewLfmForm(oPC, nToken));
    LfgFeedLfmForm(oPC, nToken);

    NuiSetBindWatch(oPC, nToken, LFG_BIND_FORM_NAME,  TRUE);
    NuiSetBindWatch(oPC, nToken, LFG_BIND_FORM_LIMIT, TRUE);
}

void LfgSwapToLfmActive(object oPC, int nToken)
{
    SetLocalString(oPC, LFG_LVAR_PREV_VIEW, "start");
    NuiSetBind(oPC, nToken, LFG_BIND_BACK_VIS, JsonBool(TRUE));
    NuiSetGroupLayout(oPC, nToken, LFG_SWAP_GROUP, LfgBuildViewLfmActive(oPC, nToken));
    LfgFeedLfmActive(oPC, nToken);
    LfgTick(oPC, nToken);
}

void LfgSwapToLfgList(object oPC, int nToken, string sPrev = "start")
{
    SetLocalString(oPC, LFG_LVAR_PREV_VIEW, sPrev);
    NuiSetBind(oPC, nToken, LFG_BIND_BACK_VIS, JsonBool(TRUE));
    NuiSetGroupLayout(oPC, nToken, LFG_SWAP_GROUP, LfgBuildViewLfgList(oPC, nToken));
    LfgFeedLfgList(oPC, nToken);
    LfgTick(oPC, nToken);
}

// ============================================================
// Feed - LFM form
// ============================================================
void LfgFeedLfmForm(object oPC, int nToken)
{
    NuiSetBind(oPC, nToken, LFG_BIND_FORM_NAME,   JsonString(""));
    NuiSetBind(oPC, nToken, LFG_BIND_FORM_DESC,   JsonString(""));
    NuiSetBind(oPC, nToken, LFG_BIND_FORM_LIMIT,  JsonString("4"));
    NuiSetBind(oPC, nToken, LFG_BIND_FORM_LVLMIN, JsonString("1"));
    NuiSetBind(oPC, nToken, LFG_BIND_FORM_LVLMAX, JsonString("40"));

    json jCatEnts = JsonArray();
    json jE;
    jE = JsonArrayInsert(JsonArray(), JsonString("Experience"));
    jE = JsonArrayInsert(jE, JsonInt(0));
    jCatEnts = JsonArrayInsert(jCatEnts, jE);

    jE = JsonArrayInsert(JsonArray(), JsonString("Dungeon"));
    jE = JsonArrayInsert(jE, JsonInt(1));
    jCatEnts = JsonArrayInsert(jCatEnts, jE);

    jE = JsonArrayInsert(JsonArray(), JsonString("RP"));
    jE = JsonArrayInsert(jE, JsonInt(2));
    jCatEnts = JsonArrayInsert(jCatEnts, jE);

    jE = JsonArrayInsert(JsonArray(), JsonString("PvP"));
    jE = JsonArrayInsert(jE, JsonInt(3));
    jCatEnts = JsonArrayInsert(jCatEnts, jE);

    NuiSetBind(oPC, nToken, LFG_BIND_FORM_CAT_ENT, jCatEnts);

    string sCat = GetLocalString(oPC, LFG_LVAR_CATEGORY);
    int nCatIdx = 0;
    int bCatEn  = FALSE;
    if(sCat == LFG_CAT_EXP)         { nCatIdx = 0; bCatEn = FALSE; }
    else if(sCat == LFG_CAT_DUNGEON) { nCatIdx = 1; bCatEn = FALSE; }
    else if(sCat == LFG_CAT_RP)      { nCatIdx = 2; bCatEn = FALSE; }
    else if(sCat == LFG_CAT_PVP)     { nCatIdx = 3; bCatEn = FALSE; }
    else                             { nCatIdx = 0; bCatEn = TRUE; }

    NuiSetBind(oPC, nToken, LFG_BIND_FORM_CAT_SEL, JsonInt(nCatIdx));
    NuiSetBind(oPC, nToken, LFG_BIND_FORM_CAT_EN,  JsonBool(bCatEn));

    json jClassIds = LfgGetPlayerClassIds();
    SetLocalJson(oPC, LFG_LVAR_FORM_CL_AV, jClassIds);

    json jClsEnts = JsonArray();
    int i, nLen = JsonGetLength(jClassIds);
    for(i = 0; i < nLen; i++)
    {
        int nId = JsonGetInt(JsonArrayGet(jClassIds, i));
        jE = JsonArrayInsert(JsonArray(), JsonString(LfgGetClassName(nId)));
        jE = JsonArrayInsert(jE, JsonInt(i));
        jClsEnts = JsonArrayInsert(jClsEnts, jE);
    }
    NuiSetBind(oPC, nToken, LFG_BIND_FORM_CL_ENT, jClsEnts);
    NuiSetBind(oPC, nToken, LFG_BIND_FORM_CL_SEL, JsonInt(0));

    SetLocalJson(oPC, LFG_LVAR_FORM_CL_IDS, JsonArray());
    NuiSetBind(oPC, nToken, LFG_BIND_FORM_RST_N,   JsonArray());
    NuiSetBind(oPC, nToken, LFG_BIND_FORM_RST_I,   JsonArray());
    NuiSetBind(oPC, nToken, LFG_BIND_FORM_RST_LEN, JsonInt(0));

    NuiSetBind(oPC, nToken, LFG_BIND_CRE_EN, JsonBool(FALSE));
}

// Rebuild restriction list binds from LVAR
void LfgRefreshRestrictions(object oPC, int nToken)
{
    json jIds = GetLocalJson(oPC, LFG_LVAR_FORM_CL_IDS);
    json jNames = JsonArray();
    json jIcons = JsonArray();
    int i, nLen = JsonGetLength(jIds);
    for(i = 0; i < nLen; i++)
    {
        int nId = JsonGetInt(JsonArrayGet(jIds, i));
        jNames = JsonArrayInsert(jNames, JsonString(LfgGetClassName(nId)));
        jIcons = JsonArrayInsert(jIcons, JsonString(LfgGetClassIcon(nId)));
    }
    NuiSetBind(oPC, nToken, LFG_BIND_FORM_RST_N,   jNames);
    NuiSetBind(oPC, nToken, LFG_BIND_FORM_RST_I,   jIcons);
    NuiSetBind(oPC, nToken, LFG_BIND_FORM_RST_LEN, JsonInt(nLen));
}

// ============================================================
// Feed - LFM active (pending list)
// ============================================================
void LfgFeedLfmActive(object oPC, int nToken)
{
    string sUuid  = GetObjectUUID(oPC);
    json jGroup   = LfgGroupGet(sUuid);

    json jNames   = JsonArray();
    json jCls     = JsonArray();
    json jInvEn   = JsonArray();
    json jUuids   = JsonArray();

    if(JsonGetType(jGroup) != JSON_TYPE_NULL)
    {
        json jPending = JsonObjectGet(jGroup, LFG_FIELD_PENDING);
        int i, nLen = JsonGetLength(jPending);
        for(i = 0; i < nLen; i++)
        {
            string sAppUuid = JsonGetString(JsonArrayGet(jPending, i));
            object oApp = GetObjectByUUID(sAppUuid);

            string sName = GetIsObjectValid(oApp) ? GetName(oApp) : "(offline)";

            string sClsSummary = "";
            if(GetIsObjectValid(oApp))
            {
                object oMember = GetFirstFactionMember(oApp, TRUE);
                while(GetIsObjectValid(oMember))
                {
                    if(sClsSummary != "") sClsSummary += " / ";
                    int nClassId = GetClassByPosition(1, oMember);
                    sClsSummary += LfgGetClassName(nClassId);
                    oMember = GetNextFactionMember(oApp, TRUE);
                }
            }

            jNames  = JsonArrayInsert(jNames,  JsonString(sName));
            jCls    = JsonArrayInsert(jCls,    JsonString(sClsSummary));
            jInvEn  = JsonArrayInsert(jInvEn,  JsonBool(GetIsObjectValid(oApp)));
            jUuids  = JsonArrayInsert(jUuids,  JsonString(sAppUuid));
        }
    }

    SetLocalJson(oPC, LFG_LVAR_PEND_UUIDS, jUuids);
    NuiSetBind(oPC, nToken, LFG_BIND_PEND_NAMES,  jNames);
    NuiSetBind(oPC, nToken, LFG_BIND_PEND_CLS,    jCls);
    NuiSetBind(oPC, nToken, LFG_BIND_PEND_INV_EN, jInvEn);
    NuiSetBind(oPC, nToken, LFG_BIND_PEND_LEN,    JsonInt(JsonGetLength(jNames)));
}

// ============================================================
// Feed - LFG list
// ============================================================
void LfgFeedLfgList(object oPC, int nToken)
{
    string sUuid   = GetObjectUUID(oPC);
    string sFilter = GetLocalString(oPC, LFG_LVAR_CATEGORY);
    json jGroupList = LfgGetGroupList(sFilter);

    json jCicos  = JsonArray();
    json jNames  = JsonArray();
    json jInfos  = JsonArray();
    json jDescs  = JsonArray();
    json jDTips  = JsonArray();
    json jClss   = JsonArray();
    json jBLbls  = JsonArray();
    json jBEns   = JsonArray();
    json jEnc    = JsonArray();
    json jUuids  = JsonArray();

    int i, nLen = JsonGetLength(jGroupList);
    for(i = 0; i < nLen; i++)
    {
        json jG        = JsonArrayGet(jGroupList, i);
        string sLdrUuid = JsonGetString(JsonObjectGet(jG, LFG_FIELD_UUID));
        string sCat    = JsonGetString(JsonObjectGet(jG, LFG_FIELD_CATEGORY));
        string sName   = JsonGetString(JsonObjectGet(jG, LFG_FIELD_NAME));
        string sLdrNm  = JsonGetString(JsonObjectGet(jG, LFG_FIELD_LEADER_NAME));
        int nLimit     = JsonGetInt(JsonObjectGet(jG, LFG_FIELD_LIMIT));
        int nMin       = JsonGetInt(JsonObjectGet(jG, LFG_FIELD_LEVEL_MIN));
        int nMax       = JsonGetInt(JsonObjectGet(jG, LFG_FIELD_LEVEL_MAX));
        json jClasses  = JsonObjectGet(jG, LFG_FIELD_CLASSES);

        string sInfo = "Leader: " + sLdrNm + " | " +
                       IntToString(nLimit) + " slots | Lvl " +
                       IntToString(nMin) + "-" + IntToString(nMax);

        string sDesc      = JsonGetString(JsonObjectGet(jG, LFG_FIELD_DESC));
        string sDescShort = GetStringLength(sDesc) > 70 ? GetStringLeft(sDesc, 70) + "..." : sDesc;

        string sClsLine = "";
        int j, nCls = JsonGetLength(jClasses);
        for(j = 0; j < nCls; j++)
        {
            if(j > 0) sClsLine += " / ";
            sClsLine += LfgGetClassName(JsonGetInt(JsonArrayGet(jClasses, j)));
        }

        int bApplied = LfgApplicantHasApplied(sUuid, sLdrUuid);
        int bCanApply = LfgCanApply(oPC) && !bApplied;

        if(sLdrUuid == sUuid) continue;

        // Skip groups the player is already a member of
        object oLeader = GetObjectByUUID(sLdrUuid);
        if(GetIsObjectValid(oLeader) && GetFactionLeader(oPC) == GetFactionLeader(oLeader)) continue;

        // Skip groups that don't match class restrictions
        if(!LfgClassesMatch(oPC, jClasses)) continue;

        // Skip groups outside the player's party level range
        if(!LfgLevelMatch(oPC, nMin, nMax)) continue;

        jCicos = JsonArrayInsert(jCicos, JsonString(LfgCatResref(sCat)));
        jNames = JsonArrayInsert(jNames, JsonString(sName));
        jInfos = JsonArrayInsert(jInfos, JsonString(sInfo));
        jDescs = JsonArrayInsert(jDescs, JsonString(sDescShort));
        jDTips = JsonArrayInsert(jDTips, JsonString(sDesc));
        jClss  = JsonArrayInsert(jClss,  JsonString(sClsLine));
        jBLbls = JsonArrayInsert(jBLbls, JsonString(bApplied ? "Cancel" : "Join"));
        jBEns  = JsonArrayInsert(jBEns,  JsonBool(bApplied || bCanApply));
        jEnc   = JsonArrayInsert(jEnc,   JsonBool(bApplied));
        jUuids = JsonArrayInsert(jUuids, JsonString(sLdrUuid));
    }

    int nCount = JsonGetLength(jNames);
    SetLocalJson(oPC, LFG_LVAR_LIST_UUIDS, jUuids);
    NuiSetBind(oPC, nToken, LFG_BIND_LIST_CICO, jCicos);
    NuiSetBind(oPC, nToken, LFG_BIND_LIST_NAME, jNames);
    NuiSetBind(oPC, nToken, LFG_BIND_LIST_INFO, jInfos);
    NuiSetBind(oPC, nToken, LFG_BIND_LIST_DESC,  jDescs);
    NuiSetBind(oPC, nToken, LFG_BIND_LIST_DTIP,  jDTips);
    NuiSetBind(oPC, nToken, LFG_BIND_LIST_CLS,   jClss);
    NuiSetBind(oPC, nToken, LFG_BIND_LIST_BLBL,  jBLbls);
    NuiSetBind(oPC, nToken, LFG_BIND_LIST_BEN,  jBEns);
    NuiSetBind(oPC, nToken, NUI_DATA_ENCOURAGED, jEnc);
    NuiSetBind(oPC, nToken, LFG_BIND_LIST_LEN,  JsonInt(nCount));

    // Restore row highlight after refresh
    string sSel = GetLocalString(oPC, LFG_LVAR_SEL_UUID);
    int nSelIdx = -1;
    for(i = 0; i < nCount; i++)
    {
        if(JsonGetString(JsonArrayGet(jUuids, i)) == sSel)
        { nSelIdx = i; break; }
    }
    NuiOffEncouragedData(oPC, nToken);
    if(nSelIdx >= 0) NuiOnEncouragedData(oPC, nToken, nSelIdx);
}

// ============================================================
// Refresh helpers
// ============================================================
void LfgRefreshList(object oPC, int nToken)
{
    LfgFeedLfgList(oPC, nToken);
}

void LfgRefreshPending(object oPC, int nToken)
{
    LfgFeedLfmActive(oPC, nToken);
}

// ============================================================
// Tick - periodic refresh
// ============================================================
void LfgTick(object oPC, int nToken)
{
    if(NuiFindWindow(oPC, LFG_WINDOW) == 0) return;
    if(GetLocalInt(oPC, LFG_LVAR_TOKEN) != nToken) return;

    string sMode = GetLocalString(oPC, LFG_LVAR_MODE);
    if(sMode == LFG_MODE_LFG)
        LfgRefreshList(oPC, nToken);
    else if(sMode == LFG_MODE_LFM)
        LfgRefreshPending(oPC, nToken);

    DelayCommand(IntToFloat(LFG_TICK_SECONDS), LfgTick(oPC, nToken));
}

// ============================================================
// Validate and update Create button state
// ============================================================
void LfgValidateForm(object oPC, int nToken)
{
    string sName  = JsonGetString(NuiGetBind(oPC, nToken, LFG_BIND_FORM_NAME));
    string sLimit = JsonGetString(NuiGetBind(oPC, nToken, LFG_BIND_FORM_LIMIT));

    int bValid = GetStringLength(sName) > 0 && StringToInt(sLimit) > 0;

    NuiSetBind(oPC, nToken, LFG_BIND_CRE_EN, JsonBool(bValid));
}

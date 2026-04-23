#include "lib_sm_ico"

// Forward declarations
void FeedSmMenu(object oPC, int nToken);
void FeedSmCreate(object oPC, int nToken);
void FeedSmSelected(object oPC, int nToken);
void SwapToMenuView(object oPC, int nToken);
void SwapToCreateView(object oPC, int nToken, int nEditIdx);
void SmRebuildLevels(object oPC, int nToken);

// --- Delete confirm popup -----------------------------------------------------
void CreateSmDeletePopup(object oPC, string sName)
{
    float fW = SmScale(oPC, 380.0);
    float fH = SmScale(oPC, 160.0);

    json jCol = JsonArray();

    json jRow = JsonArray();
    {
        string sText = "Delete macro \"" + sName + "\"?";
        json jLbl = NuiLabel(JsonString(sText),
            JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
        jRow = JsonArrayInsert(jRow, jLbl);
        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    jCol = JsonArrayInsert(jCol, SmEmptyRow(oPC, 10.0));

    jRow = JsonArray();
    {
        json jYes = NuiId(NuiButton(JsonString("Yes, delete")), SM_BTN_DEL_CONFIRM);
        jYes = NuiWidth(jYes, SmScale(oPC, 120.0));

        json jNo = NuiId(NuiButton(JsonString("Cancel")), SM_BTN_DEL_CANCEL);
        jNo = NuiWidth(jNo, SmScale(oPC, 100.0));

        jRow = JsonArrayInsert(jRow, NuiSpacer());
        jRow = JsonArrayInsert(jRow, jYes);
        jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), SmScale(oPC, 10.0)));
        jRow = JsonArrayInsert(jRow, jNo);
        jRow = JsonArrayInsert(jRow, NuiSpacer());
        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    json jRoot = NuiCol(jCol);
    json jWin = NuiWindow(jRoot, JsonString("Delete Macro"),
        NuiRect(-1.0, -1.0, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    NuiCreate(oPC, jWin, SM_WIN_DELETE, "lib_sm_ev");
}

// --- Build menu view ----------------------------------------------------------
json BuildSmMenuView(object oPC)
{
    float fBtnW = SmScale(oPC, 90.0);
    float fRowH = SmScale(oPC, 54.0);

    json jCol = JsonArray();

    // "Nowe makro" button
    {
        json jRow = JsonArray();
        json jBtn = NuiId(NuiButton(JsonString("New Macro")), SM_BTN_NEW);
        jBtn = NuiWidth(jBtn, SmScale(oPC, 150.0));
        jRow = JsonArrayInsert(jRow, NuiSpacer());
        jRow = JsonArrayInsert(jRow, jBtn);
        jRow = JsonArrayInsert(jRow, NuiSpacer());
        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    // Sequence list
    {
        json jImg = NuiImage(NuiBind(SM_BIND_M_ICONS),
            JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
        jImg = NuiWidth(jImg,  SmScale(oPC, 40.0));
        jImg = NuiHeight(jImg, SmScale(oPC, 40.0));

        json jLabel = NuiLabel(NuiBind(SM_BIND_M_NAMES),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

        json jCellRow = JsonArray();
        jCellRow = JsonArrayInsert(jCellRow, jImg);
        jCellRow = JsonArrayInsert(jCellRow, NuiWidth(NuiSpacer(), SmScale(oPC, 4.0)));
        jCellRow = JsonArrayInsert(jCellRow, jLabel);

        json jGroup = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
        jGroup = NuiId(jGroup, SM_BTN_M_ROW);
        jGroup = NuiEncouraged(jGroup, NuiBind(SM_BIND_M_ENC));

        json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jGroup, 0.0, TRUE));

        json jList = NuiList(jTmpl, NuiBind(SM_BIND_M_COUNT), fRowH, TRUE, NUI_SCROLLBARS_Y);
        jList = NuiHeight(jList, SmScale(oPC, 556.0));
        jCol = JsonArrayInsert(jCol, jList);
    }

    // Cast / Edit / Delete buttons
    {
        json jRow = JsonArray();

        json jCast = NuiId(NuiButton(JsonString("Cast")), SM_BTN_CAST);
        jCast = NuiWidth(jCast, fBtnW);
        jCast = NuiEnabled(jCast, NuiBind(SM_BIND_M_CAST_EN));

        json jEdit = NuiId(NuiButton(JsonString("Edit")), SM_BTN_EDIT);
        jEdit = NuiWidth(jEdit, fBtnW);
        jEdit = NuiEnabled(jEdit, NuiBind(SM_BIND_M_EDIT_EN));

        json jDel = NuiId(NuiButton(JsonString("Delete")), SM_BTN_DELETE);
        jDel = NuiWidth(jDel, fBtnW);
        jDel = NuiEnabled(jDel, NuiBind(SM_BIND_M_DEL_EN));

        jRow = JsonArrayInsert(jRow, NuiSpacer());
        jRow = JsonArrayInsert(jRow, jCast);
        jRow = JsonArrayInsert(jRow, NuiSpacer());
        jRow = JsonArrayInsert(jRow, jEdit);
        jRow = JsonArrayInsert(jRow, NuiSpacer());
        jRow = JsonArrayInsert(jRow, jDel);
        jRow = JsonArrayInsert(jRow, NuiSpacer());
        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    json jWrap = JsonArray();
    jWrap = JsonArrayInsert(jWrap, NuiWidth(NuiCol(jCol), SmScale(oPC, 558.0)));
    return NuiRow(jWrap);
}

// --- Build create view --------------------------------------------------------
json BuildSmCreateView(object oPC)
{
    float fComboH = SmScale(oPC, 26.0);

    json jCol = JsonArray();

    // Class / Level / Metamagic combos
    {
        json jRow = JsonArray();

        json jClsLbl = NuiLabel(JsonString("Class:"),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
        jClsLbl = NuiWidth(jClsLbl, SmScale(oPC, 42.0));
        json jClsCombo = NuiCombo(NuiBind(SM_BIND_C_CLS_ENT), NuiBind(SM_BIND_C_CLS_IDX));
        jClsCombo = NuiWidth(jClsCombo, SmScale(oPC, 120.0));
        jClsCombo = NuiHeight(jClsCombo, fComboH);
        jClsCombo = NuiId(jClsCombo, SM_BIND_C_CLS_IDX);

        json jLvlLbl = NuiLabel(JsonString("Level:"),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
        jLvlLbl = NuiWidth(jLvlLbl, SmScale(oPC, 38.0));
        json jLvlCombo = NuiCombo(NuiBind(SM_BIND_C_LVL_ENT), NuiBind(SM_BIND_C_LVL_IDX));
        jLvlCombo = NuiWidth(jLvlCombo, SmScale(oPC, 56.0));
        jLvlCombo = NuiHeight(jLvlCombo, fComboH);
        jLvlCombo = NuiId(jLvlCombo, SM_BIND_C_LVL_IDX);

        json jMetaLbl = NuiLabel(JsonString("Meta:"),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
        jMetaLbl = NuiWidth(jMetaLbl, SmScale(oPC, 38.0));
        json jMetaCombo = NuiCombo(NuiBind(SM_BIND_C_META_ENT), NuiBind(SM_BIND_C_META_IDX));
        jMetaCombo = NuiWidth(jMetaCombo, SmScale(oPC, 110.0));
        jMetaCombo = NuiHeight(jMetaCombo, fComboH);
        jMetaCombo = NuiId(jMetaCombo, SM_BIND_C_META_IDX);

        jRow = JsonArrayInsert(jRow, jClsLbl);
        jRow = JsonArrayInsert(jRow, jClsCombo);
        jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), SmScale(oPC, 6.0)));
        jRow = JsonArrayInsert(jRow, jLvlLbl);
        jRow = JsonArrayInsert(jRow, jLvlCombo);
        jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), SmScale(oPC, 6.0)));
        jRow = JsonArrayInsert(jRow, jMetaLbl);
        jRow = JsonArrayInsert(jRow, jMetaCombo);
        jRow = JsonArrayInsert(jRow, NuiSpacer());
        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    jCol = JsonArrayInsert(jCol, SmEmptyRow(oPC, 4.0));

    // Spell name search
    {
        json jSearch = NuiTextEdit(JsonString("Search spell..."),
            NuiBind(SM_BIND_C_SPELL_SEARCH), 64, FALSE);
        jSearch = NuiId(jSearch, SM_BIND_C_SPELL_SEARCH);
        jSearch = NuiHeight(jSearch, SmScale(oPC, 26.0));
        json jRow = JsonArray();
        jRow = JsonArrayInsert(jRow, jSearch);
        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    jCol = JsonArrayInsert(jCol, SmEmptyRow(oPC, 4.0));

    // Target mode radio buttons
    {
        json jLabels = JsonArray();
        jLabels = JsonArrayInsert(jLabels, JsonString("Self"));
        jLabels = JsonArrayInsert(jLabels, JsonString("Ally"));
        jLabels = JsonArrayInsert(jLabels, JsonString("Enemy"));
        jLabels = JsonArrayInsert(jLabels, JsonString("Area"));

        json jOpts = NuiOptions(NUI_DIRECTION_HORIZONTAL, jLabels, NuiBind(SM_BIND_C_TARGET_MODE));
        jOpts = NuiId(jOpts, SM_BIND_C_TARGET_MODE);

        json jRow = JsonArray();
        jRow = JsonArrayInsert(jRow, jOpts);
        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    jCol = JsonArrayInsert(jCol, SmEmptyRow(oPC, 4.0));

    // Spell list
    {
        json jIcon = NuiImage(NuiBind(SM_BIND_C_SPELL_ICONS),
            JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
        jIcon = NuiWidth(jIcon, SmScale(oPC, 32.0));
        jIcon = NuiHeight(jIcon, SmScale(oPC, 32.0));
        {
            float fMI = SmScale(oPC, 14.0);
            float fMY = SmScale(oPC, 32.0) - fMI;
            json jDl = JsonArray();
            jDl = JsonArrayInsert(jDl, NuiDrawListImage(
                NuiBind(SM_BIND_C_SPELL_META_VIS),
                NuiBind(SM_BIND_C_SPELL_META_ICON),
                NuiRect(0.0, fMY, fMI, fMI),
                JsonInt(NUI_ASPECT_FIT),
                JsonInt(NUI_HALIGN_CENTER),
                JsonInt(NUI_VALIGN_MIDDLE)));
            float fDI = SmScale(oPC, 14.0);
            float fDX = SmScale(oPC, 32.0) - fDI;
            jDl = JsonArrayInsert(jDl, NuiDrawListImage(
                NuiBind(SM_BIND_C_SPELL_DOM_VIS),
                NuiBind(SM_BIND_C_SPELL_DOM_ICON),
                NuiRect(fDX, fMY, fDI, fDI),
                JsonInt(NUI_ASPECT_FIT),
                JsonInt(NUI_HALIGN_CENTER),
                JsonInt(NUI_VALIGN_MIDDLE)));
            jIcon = NuiDrawList(jIcon, JsonBool(FALSE), jDl);
        }

        json jName = NuiLabel(NuiBind(SM_BIND_C_SPELL_NAMES),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

        json jCellRow = JsonArray();
        jCellRow = JsonArrayInsert(jCellRow, jIcon);
        jCellRow = JsonArrayInsert(jCellRow, jName);

        json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
        jCell = NuiId(jCell, SM_BTN_C_SP_ROW);
        jCell = NuiEncouraged(jCell, NuiBind(SM_BIND_C_SPELL_ENC));

        json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));

        json jList = NuiList(jTmpl, NuiBind(SM_BIND_C_SPELL_COUNT),
            SmScale(oPC, 44.0), TRUE, NUI_SCROLLBARS_Y);
        jList = NuiHeight(jList, SmScale(oPC, 200.0));
        jCol = JsonArrayInsert(jCol, jList);
    }

    // "Dodaj do sekwencji" button
    {
        json jRow = JsonArray();
        json jAdd = NuiId(NuiButton(JsonString("Add to sequence")), SM_BTN_C_ADD);
        jAdd = NuiEnabled(jAdd, NuiBind(SM_BIND_C_ADD_EN));
        jAdd = NuiWidth(jAdd, SmScale(oPC, 180.0));
        jRow = JsonArrayInsert(jRow, NuiSpacer());
        jRow = JsonArrayInsert(jRow, jAdd);
        jRow = JsonArrayInsert(jRow, NuiSpacer());
        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    jCol = JsonArrayInsert(jCol, SmEmptyRow(oPC, 4.0));

    // Selected spells label + count
    {
        json jRow = JsonArray();
        json jLbl = NuiLabel(JsonString("Selected spells:"),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
        json jCount = NuiLabel(NuiBind(SM_BIND_C_SEL_COUNT),
            JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
        jCount = NuiWidth(jCount, SmScale(oPC, 50.0));
        jRow = JsonArrayInsert(jRow, jLbl);
        jRow = JsonArrayInsert(jRow, jCount);
        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    // Selected spells: horizontal row of 48x48 icon buttons, rebuilt via NuiSetGroupLayout
    {
        json jSelGroup = NuiGroup(NuiRow(JsonArray()), TRUE, NUI_SCROLLBARS_X);
        jSelGroup = NuiId(jSelGroup, SM_GRP_SEL_ICONS);
        jSelGroup = NuiHeight(jSelGroup, SmScale(oPC, 76.0));
        jCol = JsonArrayInsert(jCol, jSelGroup);
    }

    jCol = JsonArrayInsert(jCol, SmEmptyRow(oPC, 6.0));

    // Sequence name
    {
        json jRow = JsonArray();
        json jLbl = NuiLabel(JsonString("Name:"),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
        jLbl = NuiWidth(jLbl, SmScale(oPC, 46.0));

        json jEdit = NuiTextEdit(JsonString("macro name..."),
            NuiBind(SM_BIND_C_SEQ_NAME), 32, FALSE);
        jEdit = NuiWidth(jEdit, SmScale(oPC, 200.0));
        jEdit = NuiId(jEdit, SM_BIND_C_SEQ_NAME);

        jRow = JsonArrayInsert(jRow, jLbl);
        jRow = JsonArrayInsert(jRow, jEdit);
        jRow = JsonArrayInsert(jRow, NuiSpacer());
        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    jCol = JsonArrayInsert(jCol, SmEmptyRow(oPC, 4.0));

    // Icon selector row + Save button
    {
        json jRow = JsonArray();
        json jLbl = NuiLabel(JsonString("Icon:"),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
        jLbl = NuiWidth(jLbl, SmScale(oPC, 46.0));

        json jImg = NuiImage(NuiBind(SM_BIND_C_ICON),
            JsonInt(NUI_ASPECT_FIT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
        jImg = NuiWidth(jImg,  SmScale(oPC, 40.0));
        jImg = NuiHeight(jImg, SmScale(oPC, 40.0));

        json jPick = NuiId(NuiButton(JsonString("Pick")), SM_BTN_C_ICON_PICK);
        jPick = NuiWidth(jPick,  SmScale(oPC, 80.0));
        jPick = NuiHeight(jPick, SmScale(oPC, 40.0));

        json jSave = NuiId(NuiButton(JsonString("Save")), SM_BTN_SAVE);
        jSave = NuiWidth(jSave,  SmScale(oPC, 80.0));
        jSave = NuiHeight(jSave, SmScale(oPC, 40.0));
        jSave = NuiEnabled(jSave, NuiBind(SM_BIND_C_SAVE_EN));

        jRow = JsonArrayInsert(jRow, jLbl);
        jRow = JsonArrayInsert(jRow, jImg);
        jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), SmScale(oPC, 6.0)));
        jRow = JsonArrayInsert(jRow, jPick);
        jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), SmScale(oPC, 10.0)));
        jRow = JsonArrayInsert(jRow, jSave);
        jRow = JsonArrayInsert(jRow, NuiSpacer());
        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    jCol = JsonArrayInsert(jCol, SmEmptyRow(oPC, 6.0));

    // Back button (create view only)
    {
        json jRow = JsonArray();
        json jBack = NuiId(NuiButton(JsonString("Back")), SM_BTN_BACK);
        jBack = NuiWidth(jBack, SmScale(oPC, 100.0));
        jRow = JsonArrayInsert(jRow, NuiSpacer());
        jRow = JsonArrayInsert(jRow, jBack);
        jRow = JsonArrayInsert(jRow, NuiSpacer());
        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    json jWrap = JsonArray();
    jWrap = JsonArrayInsert(jWrap, NuiWidth(NuiCol(jCol), SmScale(oPC, 558.0)));
    return NuiRow(jWrap);
}

// --- Main window -------------------------------------------------------------
void CreateSmWindow(object oPC)
{
    float fW = SmScale(oPC, 580.0);
    float fH = SmScale(oPC, 728.0);

    // Swap group ? starts with menu view
    json jSwapGroup = NuiGroup(BuildSmMenuView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGroup = NuiId(jSwapGroup, SM_GRP_SWAP);
    jSwapGroup = NuiWidth(jSwapGroup, SmScale(oPC, 562.0));

    json jWin = NuiWindow(jSwapGroup, JsonString("Spell Macro"),
        NuiRect(-1.0, -1.0, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, SM_WIN_MENU, "lib_sm_ev");

    SetLocalInt(oPC, SM_LVAR_SEL_IDX, -1);
    SmCreateTable(oPC);
    FeedSmMenu(oPC, nToken);
}

// --- Swap functions -----------------------------------------------------------
void SwapToMenuView(object oPC, int nToken)
{
    int nPicker = NuiFindWindow(oPC, SM_WIN_ICON_PICKER);
    if(nPicker > 0) NuiDestroy(oPC, nPicker);

    DeleteLocalJson(oPC, SM_LVAR_SPELLS);
    DeleteLocalJson(oPC, "SM_SPELL_LIST");
    DeleteLocalJson(oPC, "SM_CLS_IDS");
    DeleteLocalInt(oPC, "SM_SUPPRESS_TM");
    SetLocalInt(oPC, SM_LVAR_SEL_IDX, -1);

    NuiSetGroupLayout(oPC, nToken, SM_GRP_SWAP, BuildSmMenuView(oPC));
    FeedSmMenu(oPC, nToken);
}

void SwapToCreateView(object oPC, int nToken, int nEditIdx)
{
    SetLocalInt(oPC, SM_LVAR_EDIT_IDX, nEditIdx);

    json jInitSpells = JsonArray();
    string sInitName = "";
    string sInitIcon = SM_ICO_DEFAULT;
    int nInitMode    = SM_TARGET_SELF;
    if(nEditIdx >= 0)
    {
        json jData = SmLoadByIdx(oPC, nEditIdx);
        if(JsonGetType(jData) != JSON_TYPE_NULL)
        {
            jInitSpells = JsonObjectGet(jData, "spells");
            sInitName   = JsonGetString(JsonObjectGet(jData, "name"));
            sInitIcon   = JsonGetString(JsonObjectGet(jData, "icon"));
            if(sInitIcon == "") sInitIcon = SM_ICO_DEFAULT;
            nInitMode   = JsonGetInt(JsonObjectGet(jData, "target_mode"));
        }
    }
    SetLocalJson(oPC, SM_LVAR_SPELLS, jInitSpells);
    SetLocalInt(oPC, "SM_SUPPRESS_TM", 1);

    NuiSetGroupLayout(oPC, nToken, SM_GRP_SWAP, BuildSmCreateView(oPC));

    NuiSetBind(oPC, nToken, SM_BIND_C_SEQ_NAME, JsonString(sInitName));
    NuiSetBindWatch(oPC, nToken, SM_BIND_C_SEQ_NAME, TRUE);

    NuiSetBind(oPC, nToken, SM_BIND_C_TARGET_MODE, JsonInt(nInitMode));
    NuiSetBindWatch(oPC, nToken, SM_BIND_C_TARGET_MODE, TRUE);
    NuiSetBindWatch(oPC, nToken, SM_BIND_C_CLS_IDX,    TRUE);
    NuiSetBindWatch(oPC, nToken, SM_BIND_C_LVL_IDX,    TRUE);
    NuiSetBindWatch(oPC, nToken, SM_BIND_C_META_IDX,   TRUE);

    NuiSetBind(oPC, nToken, SM_BIND_C_ADD_EN,  JsonBool(FALSE));
    NuiSetBind(oPC, nToken, SM_BIND_C_ICON,    JsonString(sInitIcon));
    NuiSetBind(oPC, nToken, SM_BIND_C_SPELL_SEARCH, JsonString(""));
    NuiSetBindWatch(oPC, nToken, SM_BIND_C_SPELL_SEARCH, TRUE);

    json jCls       = SmGetPlayerClasses(oPC);
    json jCls_ids   = JsonObjectGet(jCls, "ids");
    json jCls_names = JsonObjectGet(jCls, "names");
    SetLocalJson(oPC, "SM_CLS_IDS", jCls_ids);

    json jClsEntries = JsonArray();
    int i;
    for(i = 0; i < JsonGetLength(jCls_names); i++)
        jClsEntries = JsonArrayInsert(jClsEntries,
            JsonArrayInsert(JsonArrayInsert(JsonArray(),
                JsonArrayGet(jCls_names, i)), JsonInt(i)));
    NuiSetBind(oPC, nToken, SM_BIND_C_CLS_ENT, jClsEntries);
    NuiSetBind(oPC, nToken, SM_BIND_C_CLS_IDX, JsonInt(0));

    int nClassId0   = JsonGetInt(JsonArrayGet(jCls_ids, 0));
    json jLvlEnt0 = SmGetPlayerLevels(oPC, nClassId0);
    NuiSetBind(oPC, nToken, SM_BIND_C_LVL_ENT, jLvlEnt0);
    int nFirstLvl = JsonGetLength(jLvlEnt0) > 0 ? JsonGetInt(JsonArrayGet(JsonArrayGet(jLvlEnt0, 0), 1)) : 0;
    NuiSetBind(oPC, nToken, SM_BIND_C_LVL_IDX, JsonInt(nFirstLvl));
    NuiSetBind(oPC, nToken, SM_BIND_C_META_ENT, SmGetPlayerMetas(oPC));
    NuiSetBind(oPC, nToken, SM_BIND_C_META_IDX, JsonInt(0));

    FeedSmCreate(oPC, nToken);
}

void SmRebuildLevels(object oPC, int nToken)
{
    json jCls_ids = GetLocalJson(oPC, "SM_CLS_IDS");
    int  nClsIdx  = JsonGetInt(NuiGetBind(oPC, nToken, SM_BIND_C_CLS_IDX));
    int  nClassId = JsonGetInt(JsonArrayGet(jCls_ids, nClsIdx));
    json jLvlEnt = SmGetPlayerLevels(oPC, nClassId);
    NuiSetBind(oPC, nToken, SM_BIND_C_LVL_ENT, jLvlEnt);
    int nFirstLvl = JsonGetLength(jLvlEnt) > 0 ? JsonGetInt(JsonArrayGet(JsonArrayGet(jLvlEnt, 0), 1)) : 0;
    NuiSetBind(oPC, nToken, SM_BIND_C_LVL_IDX, JsonInt(nFirstLvl));

}

// --- Feed functions -----------------------------------------------------------
void FeedSmMenu(object oPC, int nToken)
{
    json jAll = SmLoadAll(oPC);
    int nCount = JsonGetLength(jAll);

    json jNames  = JsonArray();
    json jIcons  = JsonArray();
    json jEnc    = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jEntry = JsonArrayGet(jAll, i);
        string sIco = JsonGetString(JsonObjectGet(jEntry, "icon"));
        if(sIco == "") sIco = SM_ICO_DEFAULT;
        jNames  = JsonArrayInsert(jNames,  JsonObjectGet(jEntry, "name"));
        jIcons  = JsonArrayInsert(jIcons,  JsonString(sIco));
        jEnc    = JsonArrayInsert(jEnc,    JsonBool(FALSE));
    }

    NuiSetBind(oPC, nToken, SM_BIND_M_NAMES,  jNames);
    NuiSetBind(oPC, nToken, SM_BIND_M_ICONS,  jIcons);
    NuiSetBind(oPC, nToken, SM_BIND_M_COUNT,  JsonInt(JsonGetLength(jNames)));
    NuiSetBind(oPC, nToken, SM_BIND_M_ENC,   jEnc);
    NuiSetBind(oPC, nToken, SM_BIND_M_ROW,   JsonNull());
    NuiSetBind(oPC, nToken, SM_BIND_M_CAST_EN, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, SM_BIND_M_EDIT_EN, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, SM_BIND_M_DEL_EN,  JsonBool(FALSE));
}

void FeedSmCreate(object oPC, int nToken)
{
    json jCls_ids = GetLocalJson(oPC, "SM_CLS_IDS");
    int  nClsComboIdx = JsonGetInt(NuiGetBind(oPC, nToken, SM_BIND_C_CLS_IDX));
    int  nClassId = JsonGetInt(JsonArrayGet(jCls_ids, nClsComboIdx));

    // NuiCombo stores the selected VALUE (not array index) ? read directly.
    int nLevel = JsonGetInt(NuiGetBind(oPC, nToken, SM_BIND_C_LVL_IDX));
    int nMeta  = JsonGetInt(NuiGetBind(oPC, nToken, SM_BIND_C_META_IDX));

    int nTargetMode = JsonGetInt(NuiGetBind(oPC, nToken, SM_BIND_C_TARGET_MODE));
    string sSearch  = GetStringLowerCase(JsonGetString(NuiGetBind(oPC, nToken, SM_BIND_C_SPELL_SEARCH)));
    json jSpells = SmGatherSpells(oPC, nClassId, nLevel, nTargetMode, nMeta);

    // Apply name filter
    if(sSearch != "")
    {
        json jFiltered = JsonArray();
        int fi;
        for(fi = 0; fi < JsonGetLength(jSpells); fi++)
        {
            json jS = JsonArrayGet(jSpells, fi);
            string sName = GetStringLowerCase(JsonGetString(JsonObjectGet(jS, SM_F_NAME)));
            if(FindSubString(sName, sSearch) != -1)
                jFiltered = JsonArrayInsert(jFiltered, jS);
        }
        jSpells = jFiltered;
    }

    int nSpellCount = JsonGetLength(jSpells);

    json jNames    = JsonArray();
    json jIcons    = JsonArray();
    json jEnc      = JsonArray();
    json jMetaVis  = JsonArray();
    json jMetaIcon = JsonArray();
    json jDomVis   = JsonArray();
    json jDomIcon  = JsonArray();
    int i;
    for(i = 0; i < nSpellCount; i++)
    {
        json jS       = JsonArrayGet(jSpells, i);
        int  nEntMeta = JsonGetInt(JsonObjectGet(jS, SM_F_META));
        string sMIcon = SmGetMetaIcon(nEntMeta);
        jNames    = JsonArrayInsert(jNames,    JsonObjectGet(jS, SM_F_NAME));
        jIcons    = JsonArrayInsert(jIcons,    JsonObjectGet(jS, SM_F_ICON));
        jEnc      = JsonArrayInsert(jEnc,      JsonBool(FALSE));
        jMetaVis  = JsonArrayInsert(jMetaVis,  JsonBool(sMIcon != ""));
        jMetaIcon = JsonArrayInsert(jMetaIcon, JsonString(sMIcon));
        string sDIcon = JsonGetString(JsonObjectGet(jS, SM_F_DOMAIN_ICON));
        jDomVis  = JsonArrayInsert(jDomVis,  JsonBool(sDIcon != ""));
        jDomIcon = JsonArrayInsert(jDomIcon, JsonString(sDIcon));
    }

    NuiSetBind(oPC, nToken, SM_BIND_C_SPELL_NAMES,  jNames);
    NuiSetBind(oPC, nToken, SM_BIND_C_SPELL_COUNT,  JsonInt(nSpellCount));
    NuiSetBind(oPC, nToken, SM_BIND_C_SPELL_ICONS,  jIcons);
    NuiSetBind(oPC, nToken, SM_BIND_C_SPELL_ENC,       jEnc);
    NuiSetBind(oPC, nToken, SM_BIND_C_SPELL_META_VIS,  jMetaVis);
    NuiSetBind(oPC, nToken, SM_BIND_C_SPELL_META_ICON, jMetaIcon);
    NuiSetBind(oPC, nToken, SM_BIND_C_SPELL_DOM_VIS,   jDomVis);
    NuiSetBind(oPC, nToken, SM_BIND_C_SPELL_DOM_ICON,  jDomIcon);
    NuiSetBind(oPC, nToken, SM_BIND_C_SPELL_ROW,       JsonNull());
    NuiSetBind(oPC, nToken, SM_BIND_C_ADD_EN,          JsonBool(FALSE));

    SetLocalJson(oPC, "SM_SPELL_LIST", jSpells);

    FeedSmSelected(oPC, nToken);
}

void FeedSmSelected(object oPC, int nToken)
{
    json jSeq = GetLocalJson(oPC, SM_LVAR_SPELLS);
    int n = JsonGetLength(jSeq);

    json jIconRow = JsonArray();
    int i;
    for(i = 0; i < n; i++)
    {
        json jS = JsonArrayGet(jSeq, i);
        json jIcon = NuiButtonImage(JsonObjectGet(jS, SM_F_ICON));
        jIcon = NuiId(jIcon, SM_BTN_C_DEL_SEL + IntToString(i));
        jIcon = NuiWidth(jIcon,  SmScale(oPC, 48.0));
        jIcon = NuiHeight(jIcon, SmScale(oPC, 48.0));
        jIcon = NuiTooltip(jIcon, JsonObjectGet(jS, SM_F_NAME));

        json jDl = JsonArray();
        jDl = JsonArrayInsert(jDl, NuiDrawListText(
            JsonBool(TRUE),
            NuiColor(80, 140, 220),
            NuiRect(7.0, 2.0, 44.0, 16.0),
            JsonString(IntToString(i + 1))
        ));
        float fMI = SmScale(oPC, 14.0);
        float fMY = SmScale(oPC, 48.0) - fMI - SmScale(oPC, 2.0);
        string sMIcon = SmGetMetaIcon(JsonGetInt(JsonObjectGet(jS, SM_F_META)));
        if(sMIcon != "")
        {
            jDl = JsonArrayInsert(jDl, NuiDrawListImage(
                JsonBool(TRUE), JsonString(sMIcon),
                NuiRect(7.0, fMY, fMI, fMI),
                JsonInt(NUI_ASPECT_FIT),
                JsonInt(NUI_HALIGN_CENTER),
                JsonInt(NUI_VALIGN_MIDDLE)));
        }
        string sDIcon = JsonGetString(JsonObjectGet(jS, SM_F_DOMAIN_ICON));
        if(sDIcon != "")
        {
            float fDX = SmScale(oPC, 48.0) - fMI - SmScale(oPC, 2.0);
            jDl = JsonArrayInsert(jDl, NuiDrawListImage(
                JsonBool(TRUE), JsonString(sDIcon),
                NuiRect(fDX, fMY, fMI, fMI),
                JsonInt(NUI_ASPECT_FIT),
                JsonInt(NUI_HALIGN_CENTER),
                JsonInt(NUI_VALIGN_MIDDLE)));
        }
        jIcon = NuiDrawList(jIcon, JsonBool(FALSE), jDl);

        jIconRow = JsonArrayInsert(jIconRow, jIcon);
    }
    NuiSetGroupLayout(oPC, nToken, SM_GRP_SEL_ICONS, NuiRow(jIconRow));

    NuiSetBind(oPC, nToken, SM_BIND_C_SEL_COUNT,
        JsonString(IntToString(n) + "/" + IntToString(SM_MAX_SPELLS)));

    string sName = JsonGetString(NuiGetBind(oPC, nToken, SM_BIND_C_SEQ_NAME));
    NuiSetBind(oPC, nToken, SM_BIND_C_SAVE_EN, JsonBool(n > 0 && sName != ""));
}

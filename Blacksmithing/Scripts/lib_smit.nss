#include "lib_smit_def"

json  SmithBuildRecipeView (object oPC);
json  SmithBuildForgeView  (object oPC);
json  SmithBuildHistoryView(object oPC);
void  SmithDoForge         (object oPC, int nToken);

// ----------------------------------------------------------------
// Quality helpers
// ----------------------------------------------------------------

string SmithQualName(int nQ)
{
    if(nQ == 1) return SMIT_QUAL_1;
    if(nQ == 2) return SMIT_QUAL_2;
    if(nQ == 3) return SMIT_QUAL_3;
    if(nQ == 4) return SMIT_QUAL_4;
    return SMIT_QUAL_5;
}

json SmithQualColor(int nQ)
{
    if(nQ == 1) return NuiColor(200,  70,  70);  // czerwony — Kruche
    if(nQ == 2) return NuiColor(190, 190, 190);  // szary   — Pospolite
    if(nQ == 3) return NuiColor( 80, 200,  80);  // zielony — Dobre
    if(nQ == 4) return NuiColor( 80, 160, 255);  // niebieski — Wyborne
    return NuiColor(220, 170,  40);              // zloty   — Mistrzowskie
}

// ----------------------------------------------------------------
// Material helpers
// ----------------------------------------------------------------

int SmithCountMat(object oPC, string sTag)
{
    int nCount  = 0;
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem))
    {
        if(GetTag(oItem) == sTag)
            nCount += GetItemStackSize(oItem);
        oItem = GetNextItemInInventory(oPC);
    }
    return nCount;
}

void SmithConsumeMat(object oPC, string sTag, int nAmount)
{
    while(nAmount > 0)
    {
        object oItem = GetFirstItemInInventory(oPC);
        int bFound = FALSE;
        while(GetIsObjectValid(oItem))
        {
            if(GetTag(oItem) == sTag)
            {
                int nStack = GetItemStackSize(oItem);
                if(nStack <= nAmount)
                {
                    nAmount -= nStack;
                    DestroyObject(oItem);
                    bFound = TRUE;
                    break;
                }
                else
                {
                    SetItemStackSize(oItem, nStack - nAmount);
                    nAmount = 0;
                    bFound = TRUE;
                    break;
                }
            }
            oItem = GetNextItemInInventory(oPC);
        }
        if(!bFound) break;
    }
}

int SmithHasAllMats(object oPC, json jMats)
{
    int nCount = JsonGetLength(jMats);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jMat  = JsonArrayGet(jMats, i);
        string sTag = JsonGetString(JsonObjectGet(jMat, "tag"));
        int nNeed   = JsonGetInt   (JsonObjectGet(jMat, "count"));
        if(SmithCountMat(oPC, sTag) < nNeed) return FALSE;
    }
    return TRUE;
}

// ----------------------------------------------------------------
// Forging
// ----------------------------------------------------------------

int SmithRollQuality(object oPC, int nDC)
{
    int nRoll = d20() + GetAbilityModifier(ABILITY_STRENGTH, oPC)
                      + GetSkillRank(SKILL_CRAFT_TRAP, oPC);
    int nDiff = nRoll - nDC;
    if(nDiff >= 10) return 5;
    if(nDiff >= 5)  return 4;
    if(nDiff >= 0)  return 3;
    if(nDiff >= -5) return 2;
    return 1;
}

void SmithApplyQuality(object oItem, int nQuality, string sCategory)
{
    if(nQuality != 2)
        SetName(oItem, SmithQualName(nQuality) + " " + GetName(oItem));

    int nBonus = nQuality - 2;
    if(nBonus <= 0) return;

    if(sCategory == SMIT_CAT_WEAPON)
        AddItemProperty(DURATION_TYPE_PERMANENT, ItemPropertyEnhancementBonus(nBonus), oItem);
    else
        AddItemProperty(DURATION_TYPE_PERMANENT, ItemPropertyACBonus(nBonus), oItem);
}

// Attempts to forge the currently selected recipe; feeds result back via binds.
void SmithDoForge(object oPC, int nToken)
{
    int nRecId = GetLocalInt(oPC, SMIT_LVAR_SEL);
    json jRec  = SmithGetRecipeById(nRecId);
    if(JsonGetType(jRec) == JSON_TYPE_NULL) return;

    string sName  = JsonGetString(JsonObjectGet(jRec, "name"));
    string sCat   = JsonGetString(JsonObjectGet(jRec, "category"));
    string sResRef= JsonGetString(JsonObjectGet(jRec, "resref"));
    int    nDC    = JsonGetInt   (JsonObjectGet(jRec, "dc"));
    json   jMats  = JsonObjectGet(jRec, "materials");

    if(!SmithHasAllMats(oPC, jMats))
    {
        NuiSetBind(oPC, nToken, SMIT_BIND_FG_LBL, JsonString("Brak materialow!"));
        NuiSetBind(oPC, nToken, SMIT_BIND_FG_ENA, JsonBool(FALSE));
        return;
    }

    // Consume materials
    int nMatCount = JsonGetLength(jMats);
    int i;
    for(i = 0; i < nMatCount; i++)
    {
        json jMat   = JsonArrayGet(jMats, i);
        string sTag = JsonGetString(JsonObjectGet(jMat, "tag"));
        int nNeed   = JsonGetInt   (JsonObjectGet(jMat, "count"));
        SmithConsumeMat(oPC, sTag, nNeed);
    }

    int nQuality = SmithRollQuality(oPC, nDC);
    string sQName = SmithQualName(nQuality);

    object oItem = CreateItemOnObject(sResRef, oPC);
    if(!GetIsObjectValid(oItem))
    {
        SendMessageToPC(oPC, "[Kuznia] Blad: nie mozna stworzyc przedmiotu '" + sResRef + "'.");
        return;
    }

    SmithApplyQuality(oItem, nQuality, sCat);
    SmithAddHistory(oPC, nRecId, sName, nQuality);

    // Flavour response based on quality
    string sMsg;
    if(nQuality == 5)
        sMsg = "[Kuznia] Piec buczy triumfalnie. Wykules '" + sQName + " " + sName + "' — dzielo godne mistrza!";
    else if(nQuality >= 3)
        sMsg = "[Kuznia] Zelazna rozarka plonie rowno. Wykules '" + sQName + " " + sName + "'.";
    else if(nQuality == 2)
        sMsg = "[Kuznia] Wykules '" + sName + "'. Solidne, niezle — nic wiecej.";
    else
        sMsg = "[Kuznia] Lupa w kuzni. Wykules '" + sQName + " " + sName + "' — slabiutkie dzielo.";

    SendMessageToPC(oPC, sMsg);

    // Refresh forge panel (material counts change, button state may change)
    SmithFeedForgePanel(oPC, nToken);
}

// ----------------------------------------------------------------
// Build: Recipe List View
// ----------------------------------------------------------------

json SmithBuildRecipeView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fListH = GetNuiScaleDimension(oPC, 410.0);
    float fCatW  = GetNuiScaleDimension(oPC, 70.0);
    float fDCW   = GetNuiScaleDimension(oPC, 50.0);
    float fBtnW  = GetNuiScaleDimension(oPC, 80.0);
    float fBtnWS = GetNuiScaleDimension(oPC, 70.0);
    float fCloseW= GetNuiScaleDimension(oPC, 32.0);

    // ---- Filter + action bar ----
    json jFAll = NuiButton(JsonString("Wszystko"));
    jFAll = NuiId(jFAll, SMIT_BTN_F_ALL);
    jFAll = NuiWidth(jFAll, fBtnW);
    jFAll = NuiHeight(jFAll, fBtnH);

    json jFWpn = NuiButton(JsonString("Bron"));
    jFWpn = NuiId(jFWpn, SMIT_BTN_F_WPN);
    jFWpn = NuiWidth(jFWpn, GetNuiScaleDimension(oPC, 60.0));
    jFWpn = NuiHeight(jFWpn, fBtnH);

    json jFArm = NuiButton(JsonString("Zbroja"));
    jFArm = NuiId(jFArm, SMIT_BTN_F_ARM);
    jFArm = NuiWidth(jFArm, fBtnWS);
    jFArm = NuiHeight(jFArm, fBtnH);

    json jFShl = NuiButton(JsonString("Tarcza"));
    jFShl = NuiId(jFShl, SMIT_BTN_F_SHL);
    jFShl = NuiWidth(jFShl, fBtnWS);
    jFShl = NuiHeight(jFShl, fBtnH);

    json jHistBtn = NuiButton(JsonString("Historia"));
    jHistBtn = NuiId(jHistBtn, SMIT_BTN_HISTORY);
    jHistBtn = NuiWidth(jHistBtn, fBtnW);
    jHistBtn = NuiHeight(jHistBtn, fBtnH);

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, SMIT_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, fCloseW);
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jFAll);
    jTopRow = JsonArrayInsert(jTopRow, jFWpn);
    jTopRow = JsonArrayInsert(jTopRow, jFArm);
    jTopRow = JsonArrayInsert(jTopRow, jFShl);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jHistBtn);
    jTopRow = JsonArrayInsert(jTopRow, jCloseBtn);

    // ---- Recipe list ----
    json jNameLbl = NuiLabel(NuiBind(SMIT_BIND_REC_NAME),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jCatLbl = NuiLabel(NuiBind(SMIT_BIND_REC_CAT),
                            JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jCatLbl = NuiWidth(jCatLbl, fCatW);

    json jDCLbl = NuiLabel(NuiBind(SMIT_BIND_REC_DC),
                           JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDCLbl = NuiWidth(jDCLbl, fDCW);

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, jNameLbl);
    jCellRow = JsonArrayInsert(jCellRow, jCatLbl);
    jCellRow = JsonArrayInsert(jCellRow, jDCLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, SMIT_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(SMIT_BIND_REC_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(SMIT_BIND_REC_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    json jHintLbl = NuiLabel(
        JsonString("Wybierz recepture, aby zobaczyc wymagane materialy."),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHintLbl = NuiHeight(jHintLbl, fBtnH);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTopRow));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jHintLbl)));

    json jSide    = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContW  = GetNuiScaleDimension(oPC, 700.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Build: Forge Panel View
// ----------------------------------------------------------------

json SmithBuildForgeView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fDescH = GetNuiScaleDimension(oPC, 80.0);
    float fMatH  = GetNuiScaleDimension(oPC, 130.0);
    float fHaveW = GetNuiScaleDimension(oPC, 100.0);

    // ---- Title row ----
    json jTitleLbl = NuiLabel(NuiBind(SMIT_BIND_FG_TITLE),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, fBtnH);

    json jCatLbl = NuiLabel(NuiBind(SMIT_BIND_FG_CAT),
                            JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jCatLbl = NuiWidth(jCatLbl, GetNuiScaleDimension(oPC, 80.0));
    jCatLbl = NuiHeight(jCatLbl, fBtnH);

    json jTitleRow = JsonArray();
    jTitleRow = JsonArrayInsert(jTitleRow, jTitleLbl);
    jTitleRow = JsonArrayInsert(jTitleRow, jCatLbl);

    // ---- Description ----
    json jDescTxt = NuiGroup(NuiText(NuiBind(SMIT_BIND_FG_DESC), FALSE),
                             TRUE, NUI_SCROLLBARS_NONE);
    jDescTxt = NuiHeight(jDescTxt, fDescH);

    // ---- DC info ----
    json jDCLbl = NuiLabel(NuiBind(SMIT_BIND_FG_DC),
                           JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDCLbl = NuiHeight(jDCLbl, fBtnH);

    // ---- Material list ----
    json jMatNameLbl = NuiLabel(NuiBind(SMIT_BIND_MAT_NAME),
                                JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jMatHaveLbl = NuiLabel(NuiBind(SMIT_BIND_MAT_HAVE),
                                JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jMatHaveLbl = NuiWidth(jMatHaveLbl, fHaveW);
    jMatHaveLbl = NuiStyleForegroundColor(jMatHaveLbl, NuiBind(SMIT_BIND_MAT_COL));

    json jMatCellRow = JsonArray();
    jMatCellRow = JsonArrayInsert(jMatCellRow, jMatNameLbl);
    jMatCellRow = JsonArrayInsert(jMatCellRow, jMatHaveLbl);

    json jMatCell = NuiGroup(NuiRow(jMatCellRow), FALSE, NUI_SCROLLBARS_NONE);
    json jMatTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jMatCell, 0.0, TRUE));
    json jMatList = NuiList(jMatTmpl, NuiBind(SMIT_BIND_MAT_CNT), fRowH);
    jMatList = NuiHeight(jMatList, fMatH);

    // ---- Forge button row ----
    json jForgeBtn = NuiButton(NuiBind(SMIT_BIND_FG_LBL));
    jForgeBtn = NuiId(jForgeBtn, SMIT_BTN_FORGE);
    jForgeBtn = NuiEnabled(jForgeBtn, NuiBind(SMIT_BIND_FG_ENA));
    jForgeBtn = NuiWidth(jForgeBtn, GetNuiScaleDimension(oPC, 160.0));
    jForgeBtn = NuiHeight(jForgeBtn, fBtnH);

    json jBackBtn = NuiButton(JsonString("<- Powrot"));
    jBackBtn = NuiId(jBackBtn, SMIT_BTN_BACK);
    jBackBtn = NuiWidth(jBackBtn, GetNuiScaleDimension(oPC, 100.0));
    jBackBtn = NuiHeight(jBackBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jBackBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jForgeBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTitleRow));
    jCol = JsonArrayInsert(jCol, jDescTxt);
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jDCLbl)));
    jCol = JsonArrayInsert(jCol, jMatList);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    json jSide    = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContW  = GetNuiScaleDimension(oPC, 700.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Build: History View
// ----------------------------------------------------------------

json SmithBuildHistoryView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fListH = GetNuiScaleDimension(oPC, 420.0);
    float fQualW = GetNuiScaleDimension(oPC, 120.0);
    float fDateW = GetNuiScaleDimension(oPC, 50.0);

    // ---- Header row ----
    json jTitleLbl = NuiLabel(JsonString("Historia Wykucia"),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, fBtnH);

    json jBackBtn = NuiButton(JsonString("<- Powrot"));
    jBackBtn = NuiId(jBackBtn, SMIT_BTN_BACK);
    jBackBtn = NuiWidth(jBackBtn, GetNuiScaleDimension(oPC, 100.0));
    jBackBtn = NuiHeight(jBackBtn, fBtnH);

    json jHeaderRow = JsonArray();
    jHeaderRow = JsonArrayInsert(jHeaderRow, jTitleLbl);
    jHeaderRow = JsonArrayInsert(jHeaderRow, NuiSpacer());
    jHeaderRow = JsonArrayInsert(jHeaderRow, jBackBtn);

    // ---- History list ----
    json jHNameLbl = NuiLabel(NuiBind(SMIT_BIND_HI_NAME),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHNameLbl = NuiStyleForegroundColor(jHNameLbl, NuiBind(SMIT_BIND_HI_COL));

    json jHQualLbl = NuiLabel(NuiBind(SMIT_BIND_HI_QUAL),
                              JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHQualLbl = NuiWidth(jHQualLbl, fQualW);
    jHQualLbl = NuiStyleForegroundColor(jHQualLbl, NuiBind(SMIT_BIND_HI_COL));

    json jHDateLbl = NuiLabel(NuiBind(SMIT_BIND_HI_DATE),
                              JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHDateLbl = NuiWidth(jHDateLbl, fDateW);

    json jHistCellRow = JsonArray();
    jHistCellRow = JsonArrayInsert(jHistCellRow, jHNameLbl);
    jHistCellRow = JsonArrayInsert(jHistCellRow, jHQualLbl);
    jHistCellRow = JsonArrayInsert(jHistCellRow, jHDateLbl);

    json jHistCell = NuiGroup(NuiRow(jHistCellRow), FALSE, NUI_SCROLLBARS_NONE);
    json jHistTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jHistCell, 0.0, TRUE));
    json jHistList = NuiList(jHistTmpl, NuiBind(SMIT_BIND_HI_COUNT), fRowH);
    jHistList = NuiHeight(jHistList, fListH);

    json jEmptyLbl = NuiLabel(
        JsonString("Nie wykules jeszcze zadnego przedmiotu przy tym kowadle."),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEmptyLbl = NuiHeight(jEmptyLbl, fBtnH);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jHeaderRow));
    jCol = JsonArrayInsert(jCol, jHistList);
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jEmptyLbl)));

    json jSide    = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContW  = GetNuiScaleDimension(oPC, 700.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Window create / open
// ----------------------------------------------------------------

void SmithOpenWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, SMIT_WINDOW);
    if(nToken != 0)
    {
        NuiSetGroupLayout(oPC, nToken, SMIT_GRP_CONTENT, SmithBuildRecipeView(oPC));
        SmithFeedRecipeList(oPC, nToken);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, SMIT_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, SMIT_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
                         GetNuiScaleDimension(oPC, SMIT_W),
                         GetNuiScaleDimension(oPC, SMIT_H));

    json jSwapGrp = NuiGroup(SmithBuildRecipeView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, SMIT_GRP_CONTENT);

    json jRoot = NuiCol(JsonArrayInsert(JsonArray(), jSwapGrp));

    json jWin = NuiWindow(jRoot,
        JsonString("Kuznia"),
        NuiBind(SMIT_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, SMIT_WINDOW, SMIT_EV_SCRIPT);
    NuiSetBind(oPC, nToken, SMIT_WIN_GEOM, jGeom);

    DeleteLocalString(oPC, SMIT_LVAR_FILTER);
    SmithFeedRecipeList(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed: Recipe List
// ----------------------------------------------------------------

void SmithFeedRecipeList(object oPC, int nToken)
{
    string sFilter = GetLocalString(oPC, SMIT_LVAR_FILTER);
    json   jRecs   = SmithGetAllRecipes(sFilter);
    int    nCount  = JsonGetLength(jRecs);

    SetLocalJson(oPC, SMIT_LVAR_RECIPES, jRecs);

    int nSel = GetLocalInt(oPC, SMIT_LVAR_SEL);

    json jNames = JsonArray();
    json jCats  = JsonArray();
    json jDCs   = JsonArray();
    json jEncs  = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json   jRec  = JsonArrayGet(jRecs, i);
        int    nId   = JsonGetInt   (JsonObjectGet(jRec, "id"));
        string sCat  = JsonGetString(JsonObjectGet(jRec, "category"));
        string sName = JsonGetString(JsonObjectGet(jRec, "name"));
        int    nDC   = JsonGetInt   (JsonObjectGet(jRec, "dc"));

        jNames = JsonArrayInsert(jNames, JsonString(sName));
        jCats  = JsonArrayInsert(jCats,  JsonString("[" + sCat + "]"));
        jDCs   = JsonArrayInsert(jDCs,   JsonString("DC " + IntToString(nDC)));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(nId == nSel));
    }

    NuiSetBind(oPC, nToken, SMIT_BIND_REC_NAME,  jNames);
    NuiSetBind(oPC, nToken, SMIT_BIND_REC_CAT,   jCats);
    NuiSetBind(oPC, nToken, SMIT_BIND_REC_DC,    jDCs);
    NuiSetBind(oPC, nToken, SMIT_BIND_REC_ENC,   jEncs);
    NuiSetBind(oPC, nToken, SMIT_BIND_REC_COUNT, JsonInt(nCount));
}

// ----------------------------------------------------------------
// Feed: Forge Panel
// ----------------------------------------------------------------

void SmithFeedForgePanel(object oPC, int nToken)
{
    int  nRecId = GetLocalInt(oPC, SMIT_LVAR_SEL);
    json jRec   = SmithGetRecipeById(nRecId);
    if(JsonGetType(jRec) == JSON_TYPE_NULL) return;

    string sName  = JsonGetString(JsonObjectGet(jRec, "name"));
    string sCat   = JsonGetString(JsonObjectGet(jRec, "category"));
    string sDescr = JsonGetString(JsonObjectGet(jRec, "descr"));
    int    nDC    = JsonGetInt   (JsonObjectGet(jRec, "dc"));
    json   jMats  = JsonObjectGet(jRec, "materials");

    int nMatCount = JsonGetLength(jMats);
    json jMatNames = JsonArray();
    json jMatHaves = JsonArray();
    json jMatCols  = JsonArray();

    int bAllAvail = TRUE;
    int i;
    for(i = 0; i < nMatCount; i++)
    {
        json   jMat   = JsonArrayGet(jMats, i);
        string sTag   = JsonGetString(JsonObjectGet(jMat, "tag"));
        string sMName = JsonGetString(JsonObjectGet(jMat, "name"));
        int    nNeed  = JsonGetInt   (JsonObjectGet(jMat, "count"));
        int    nHave  = SmithCountMat(oPC, sTag);
        int    bOk    = (nHave >= nNeed);

        if(!bOk) bAllAvail = FALSE;

        jMatNames = JsonArrayInsert(jMatNames,
            JsonString(sMName + " x" + IntToString(nNeed)));
        jMatHaves = JsonArrayInsert(jMatHaves,
            JsonString("Masz: " + IntToString(nHave)));
        jMatCols  = JsonArrayInsert(jMatCols,
            bOk ? NuiColor(80, 200, 80) : NuiColor(220, 60, 60));
    }

    int nSTRMod = GetAbilityModifier(ABILITY_STRENGTH, oPC);
    int nCraft  = GetSkillRank(SKILL_CRAFT_TRAP, oPC);
    int nMin    = 1 + nSTRMod + nCraft;   // d20 rolls 1 at minimum
    int nMax    = 20 + nSTRMod + nCraft;

    string sDCInfo = "DC: " + IntToString(nDC)
        + "  |  Proba: " + IntToString(nMin) + "-" + IntToString(nMax)
        + "  (STR " + (nSTRMod >= 0 ? "+" : "") + IntToString(nSTRMod)
        + " + Rzemioslo " + IntToString(nCraft) + ")";

    NuiSetBind(oPC, nToken, SMIT_BIND_FG_TITLE, JsonString(sName));
    NuiSetBind(oPC, nToken, SMIT_BIND_FG_CAT,   JsonString("[" + sCat + "]"));
    NuiSetBind(oPC, nToken, SMIT_BIND_FG_DESC,  JsonString(sDescr));
    NuiSetBind(oPC, nToken, SMIT_BIND_FG_DC,    JsonString(sDCInfo));
    NuiSetBind(oPC, nToken, SMIT_BIND_MAT_NAME, jMatNames);
    NuiSetBind(oPC, nToken, SMIT_BIND_MAT_HAVE, jMatHaves);
    NuiSetBind(oPC, nToken, SMIT_BIND_MAT_COL,  jMatCols);
    NuiSetBind(oPC, nToken, SMIT_BIND_MAT_CNT,  JsonInt(nMatCount));
    NuiSetBind(oPC, nToken, SMIT_BIND_FG_ENA,   JsonBool(bAllAvail));
    NuiSetBind(oPC, nToken, SMIT_BIND_FG_LBL,
        JsonString(bAllAvail ? "Wykuj" : "Brak materialow"));
}

// ----------------------------------------------------------------
// Feed: History Panel
// ----------------------------------------------------------------

void SmithFeedHistoryPanel(object oPC, int nToken)
{
    json jHist  = SmithGetHistory(oPC);
    int  nCount = JsonGetLength(jHist);

    json jNames = JsonArray();
    json jQuals = JsonArray();
    json jDates = JsonArray();
    json jCols  = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json   jRow    = JsonArrayGet(jHist, i);
        string sName   = JsonGetString(JsonObjectGet(jRow, "name"));
        int    nQ      = JsonGetInt   (JsonObjectGet(jRow, "quality"));
        int    nTS     = JsonGetInt   (JsonObjectGet(jRow, "forged_at"));

        jNames = JsonArrayInsert(jNames, JsonString(sName));
        jQuals = JsonArrayInsert(jQuals, JsonString(SmithQualName(nQ)));
        jDates = JsonArrayInsert(jDates, JsonString(SmithFormatDate(nTS)));
        jCols  = JsonArrayInsert(jCols,  SmithQualColor(nQ));
    }

    NuiSetBind(oPC, nToken, SMIT_BIND_HI_NAME,  jNames);
    NuiSetBind(oPC, nToken, SMIT_BIND_HI_QUAL,  jQuals);
    NuiSetBind(oPC, nToken, SMIT_BIND_HI_DATE,  jDates);
    NuiSetBind(oPC, nToken, SMIT_BIND_HI_COL,   jCols);
    NuiSetBind(oPC, nToken, SMIT_BIND_HI_COUNT, JsonInt(nCount));
}

#include "lib_ink_def"

void InkCreateWindow(object oPC);
void InkSwapToGrimoire(object oPC, int nToken);
void InkSwapToWorkshop(object oPC, int nToken, int nFormulaId);
void InkSwapToHistory(object oPC, int nToken);
void InkFeedGrimoire(object oPC, int nToken);
void InkFeedWorkshop(object oPC, int nToken, int nFormulaId);
void InkFeedHistory(object oPC, int nToken);
void InkDoInscribe(object oPC, int nToken, int nFormulaId);

// ----------------------------------------------------------------
// Item helpers
// ----------------------------------------------------------------

int InkCountItemsByTag(object oPC, string sTag)
{
    int nTotal = 0;
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem))
    {
        if(GetTag(oItem) == sTag)
            nTotal += GetItemStackSize(oItem);
        oItem = GetNextItemInInventory(oPC);
    }
    return nTotal;
}

// Removes nQty units of items with sTag from PC inventory.
void InkConsumeItems(object oPC, string sTag, int nQty)
{
    int nRemaining = nQty;
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem) && nRemaining > 0)
    {
        object oNext = GetNextItemInInventory(oPC);
        if(GetTag(oItem) == sTag)
        {
            int nStack = GetItemStackSize(oItem);
            if(nStack <= nRemaining)
            {
                nRemaining -= nStack;
                DestroyObject(oItem);
            }
            else
            {
                SetItemStackSize(oItem, nStack - nRemaining);
                nRemaining = 0;
            }
        }
        oItem = oNext;
    }
}

int InkHasAllComponents(object oPC, int nFormulaId)
{
    json jComps = InkGetFormulaComponents(nFormulaId);
    int nCount  = JsonGetLength(jComps);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jComp  = JsonArrayGet(jComps, i);
        string sTag = JsonGetString(JsonObjectGet(jComp, "tag"));
        int nQty    = JsonGetInt(JsonObjectGet(jComp, "qty"));
        if(InkCountItemsByTag(oPC, sTag) < nQty)
            return FALSE;
    }
    return TRUE;
}

// ----------------------------------------------------------------
// Shared tab bar
// ----------------------------------------------------------------

json InkBuildTabBar(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 28.0);
    float fBtnW = GetNuiScaleDimension(oPC, 130.0);

    json jTabG = NuiButton(JsonString("Grimuar"));
    jTabG = NuiId(jTabG, INK_BTN_TAB_GRIMOIRE);
    jTabG = NuiWidth(jTabG, fBtnW);
    jTabG = NuiHeight(jTabG, fBtnH);

    json jTabW = NuiButton(JsonString("Skryptorium"));
    jTabW = NuiId(jTabW, INK_BTN_TAB_WORKSHOP);
    jTabW = NuiWidth(jTabW, fBtnW);
    jTabW = NuiHeight(jTabW, fBtnH);

    json jTabH = NuiButton(JsonString("Kronika"));
    jTabH = NuiId(jTabH, INK_BTN_TAB_HISTORY);
    jTabH = NuiWidth(jTabH, fBtnW);
    jTabH = NuiHeight(jTabH, fBtnH);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jTabG);
    jRow = JsonArrayInsert(jRow, jTabW);
    jRow = JsonArrayInsert(jRow, jTabH);
    jRow = JsonArrayInsert(jRow, NuiSpacer());

    return NuiRow(jRow);
}

// ----------------------------------------------------------------
// Grimoire view — formula list
// ----------------------------------------------------------------

json BuildInkGrimoireView(object oPC)
{
    float fRowH  = GetNuiScaleDimension(oPC, 30.0);
    float fDcW   = GetNuiScaleDimension(oPC, 70.0);
    float fStatW = GetNuiScaleDimension(oPC, 110.0);

    json jNameLbl = NuiLabel(NuiBind(INK_BIND_FORM_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(INK_BIND_FORM_COLOR));

    json jDcLbl = NuiLabel(NuiBind(INK_BIND_FORM_DC_TXT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDcLbl = NuiWidth(jDcLbl, fDcW);
    jDcLbl = NuiStyleForegroundColor(jDcLbl, NuiBind(INK_BIND_FORM_COLOR));

    json jStatusLbl = NuiLabel(NuiBind(INK_BIND_FORM_STATUS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiWidth(jStatusLbl, fStatW);
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiBind(INK_BIND_FORM_COLOR));

    json jCellContent = JsonArray();
    jCellContent = JsonArrayInsert(jCellContent, jNameLbl);
    jCellContent = JsonArrayInsert(jCellContent, jDcLbl);
    jCellContent = JsonArrayInsert(jCellContent, jStatusLbl);

    json jCell = NuiGroup(NuiRow(jCellContent), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, INK_BTN_FORM_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(INK_BIND_FORM_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));

    float fListH = GetNuiScaleDimension(oPC, 360.0);
    json jList   = NuiList(jTmpl, NuiBind("ink_rowcount_g"), fRowH);
    jList = NuiHeight(jList, fListH);

    json jHint = NuiLabel(
        JsonString("Kliknij formułę, by otworzyć Skryptorium."),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHint = NuiHeight(jHint, GetNuiScaleDimension(oPC, 26.0));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, InkBuildTabBar(oPC));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, jHint);

    return NuiCol(jCol);
}

// ----------------------------------------------------------------
// Workshop view — crafting interface
// ----------------------------------------------------------------

json BuildInkWorkshopView(object oPC)
{
    float fBtnH   = GetNuiScaleDimension(oPC, 30.0);
    float fRowH   = GetNuiScaleDimension(oPC, 26.0);
    float fDescH  = GetNuiScaleDimension(oPC, 72.0);
    float fListH  = GetNuiScaleDimension(oPC, 138.0);

    json jTitleLbl = NuiLabel(NuiBind(INK_BIND_WS_TITLE), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, fBtnH);

    json jDescGrp = NuiGroup(NuiText(NuiBind(INK_BIND_WS_DESC), FALSE), TRUE, NUI_SCROLLBARS_NONE);
    jDescGrp = NuiHeight(jDescGrp, fDescH);

    json jDcLbl = NuiLabel(NuiBind(INK_BIND_WS_DC), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDcLbl = NuiHeight(jDcLbl, fRowH);

    json jSkillLbl = NuiLabel(NuiBind(INK_BIND_WS_SKILL), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jSkillLbl = NuiHeight(jSkillLbl, fRowH);

    json jStatRow = JsonArray();
    jStatRow = JsonArrayInsert(jStatRow, jDcLbl);
    jStatRow = JsonArrayInsert(jStatRow, NuiSpacer());
    jStatRow = JsonArrayInsert(jStatRow, jSkillLbl);

    // Component list
    json jCompNameLbl = NuiLabel(NuiBind(INK_BIND_COMP_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCompNameLbl = NuiStyleForegroundColor(jCompNameLbl, NuiBind(INK_BIND_COMP_COLOR));

    json jCompHaveLbl = NuiLabel(NuiBind(INK_BIND_COMP_HAVE), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jCompHaveLbl = NuiWidth(jCompHaveLbl, GetNuiScaleDimension(oPC, 130.0));
    jCompHaveLbl = NuiStyleForegroundColor(jCompHaveLbl, NuiBind(INK_BIND_COMP_COLOR));

    json jCompCellRow = JsonArray();
    jCompCellRow = JsonArrayInsert(jCompCellRow, jCompNameLbl);
    jCompCellRow = JsonArrayInsert(jCompCellRow, jCompHaveLbl);

    json jCompCell = NuiGroup(NuiRow(jCompCellRow), FALSE, NUI_SCROLLBARS_NONE);
    json jCompTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCompCell, 0.0, TRUE));
    json jCompList = NuiList(jCompTmpl, NuiBind("ink_comp_count"), fRowH);
    jCompList = NuiHeight(jCompList, fListH);

    json jResultLbl = NuiLabel(NuiBind(INK_BIND_WS_RESULT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jResultLbl = NuiHeight(jResultLbl, fRowH);

    json jInscribeBtn = NuiButton(JsonString("Zapisz Zaklęcie"));
    jInscribeBtn = NuiId(jInscribeBtn, INK_BTN_INSCRIBE);
    jInscribeBtn = NuiEnabled(jInscribeBtn, NuiBind(INK_BIND_WS_INSCR_EN));
    jInscribeBtn = NuiWidth(jInscribeBtn, GetNuiScaleDimension(oPC, 180.0));
    jInscribeBtn = NuiHeight(jInscribeBtn, fBtnH);

    json jBackBtn = NuiButton(JsonString("Grimuar"));
    jBackBtn = NuiId(jBackBtn, INK_BTN_WS_BACK);
    jBackBtn = NuiWidth(jBackBtn, GetNuiScaleDimension(oPC, 100.0));
    jBackBtn = NuiHeight(jBackBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jBackBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jInscribeBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, InkBuildTabBar(oPC));
    jCol = JsonArrayInsert(jCol, jTitleLbl);
    jCol = JsonArrayInsert(jCol, jDescGrp);
    jCol = JsonArrayInsert(jCol, NuiRow(jStatRow));
    jCol = JsonArrayInsert(jCol, jCompList);
    jCol = JsonArrayInsert(jCol, jResultLbl);
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    return NuiCol(jCol);
}

// ----------------------------------------------------------------
// History view — crafting log
// ----------------------------------------------------------------

json BuildInkHistoryView(object oPC)
{
    float fRowH = GetNuiScaleDimension(oPC, 26.0);

    json jTextLbl = NuiLabel(NuiBind(INK_BIND_HIST_TEXT), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTextLbl = NuiStyleForegroundColor(jTextLbl, NuiBind(INK_BIND_HIST_COLOR));

    json jCell = NuiGroup(NuiRow(JsonArrayInsert(JsonArray(), jTextLbl)), FALSE, NUI_SCROLLBARS_NONE);
    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));

    float fListH = GetNuiScaleDimension(oPC, 380.0);
    json jList   = NuiList(jTmpl, NuiBind("ink_hist_count"), fRowH);
    jList = NuiHeight(jList, fListH);

    json jHint = NuiLabel(
        JsonString("Historia twoich starań z atramentem — sukcesy i porażki."),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHint = NuiHeight(jHint, GetNuiScaleDimension(oPC, 26.0));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, InkBuildTabBar(oPC));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, jHint);

    return NuiCol(jCol);
}

// ----------------------------------------------------------------
// Window creation
// ----------------------------------------------------------------

void InkCreateWindow(object oPC)
{
    if(NuiFindWindow(oPC, INK_WINDOW) != 0)
    {
        InkSwapToGrimoire(oPC, NuiFindWindow(oPC, INK_WINDOW));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, INK_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, INK_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, INK_W), GetNuiScaleDimension(oPC, INK_H));

    float fBtnH = GetNuiScaleDimension(oPC, 30.0);

    json jTitleLbl = NuiLabel(
        JsonString("Inkantator — Skryptorium Zakazanych Zwojów"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, fBtnH);

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, INK_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTopBar = JsonArray();
    jTopBar = JsonArrayInsert(jTopBar, jTitleLbl);
    jTopBar = JsonArrayInsert(jTopBar, NuiSpacer());
    jTopBar = JsonArrayInsert(jTopBar, jCloseBtn);

    json jSwapGrp = NuiGroup(BuildInkGrimoireView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, INK_GRP_SWAP);

    json jRootCol = JsonArray();
    jRootCol = JsonArrayInsert(jRootCol, NuiRow(jTopBar));
    jRootCol = JsonArrayInsert(jRootCol, jSwapGrp);

    json jWin = NuiWindow(NuiCol(jRootCol),
        JsonBool(FALSE),
        NuiBind(INK_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, INK_WINDOW, INK_EV_SCRIPT);
    NuiSetBind(oPC, nToken, INK_WIN_GEOM, jGeom);

    InkSwapToGrimoire(oPC, nToken);
}

// ----------------------------------------------------------------
// View swap helpers
// ----------------------------------------------------------------

void InkSwapToGrimoire(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, INK_GRP_SWAP, BuildInkGrimoireView(oPC));
    InkFeedGrimoire(oPC, nToken);
}

void InkSwapToWorkshop(object oPC, int nToken, int nFormulaId)
{
    SetLocalInt(oPC, INK_LVAR_SEL_FORM, nFormulaId);
    NuiSetGroupLayout(oPC, nToken, INK_GRP_SWAP, BuildInkWorkshopView(oPC));
    InkFeedWorkshop(oPC, nToken, nFormulaId);
}

void InkSwapToHistory(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, INK_GRP_SWAP, BuildInkHistoryView(oPC));
    InkFeedHistory(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed: Grimoire list
// Rows are the 8 formulas in order; advanced & unknown shown as locked.
// Row index == formula_id - 1, so event handler uses nIdx + 1 directly.
// ----------------------------------------------------------------

void InkFeedGrimoire(object oPC, int nToken)
{
    json jNames    = JsonArray();
    json jDcTxts   = JsonArray();
    json jStatuses = JsonArray();
    json jEncs     = JsonArray();
    json jColors   = JsonArray();

    json jColorKnown = NuiColor(220, 190, 100);
    json jColorLocked = NuiColor(90, 90, 90);

    int i;
    for(i = 1; i <= INK_FORMULA_COUNT; i++)
    {
        int bKnown = InkIsFormulaKnown(oPC, i);
        int bAdv   = InkIsFormulaAdvanced(i);

        string sName;
        string sDc;
        string sStatus;
        json jColor;

        if(bKnown)
        {
            sName   = InkGetFormulaName(i);
            sDc     = "WM " + IntToString(InkGetFormulaDC(i));
            sStatus = bAdv ? "[zaawansowana]" : "[podstawowa]";
            jColor  = jColorKnown;
        }
        else if(bAdv)
        {
            sName   = "??? (zaawansowana)";
            sDc     = "???";
            sStatus = "[zapieczętowana]";
            jColor  = jColorLocked;
        }
        else
        {
            // Basic formula not yet granted — shouldn't happen after OnEnter, but handle gracefully
            sName   = InkGetFormulaName(i);
            sDc     = "WM " + IntToString(InkGetFormulaDC(i));
            sStatus = "[odblokuj]";
            jColor  = jColorLocked;
        }

        jNames    = JsonArrayInsert(jNames,    JsonString(sName));
        jDcTxts   = JsonArrayInsert(jDcTxts,   JsonString(sDc));
        jStatuses = JsonArrayInsert(jStatuses, JsonString(sStatus));
        jEncs     = JsonArrayInsert(jEncs,     JsonBool(FALSE));
        jColors   = JsonArrayInsert(jColors,   jColor);
    }

    NuiSetBind(oPC, nToken, INK_BIND_FORM_NAME,    jNames);
    NuiSetBind(oPC, nToken, INK_BIND_FORM_DC_TXT,  jDcTxts);
    NuiSetBind(oPC, nToken, INK_BIND_FORM_STATUS,  jStatuses);
    NuiSetBind(oPC, nToken, INK_BIND_FORM_ENC,     jEncs);
    NuiSetBind(oPC, nToken, INK_BIND_FORM_COLOR,   jColors);
    NuiSetBind(oPC, nToken, "ink_rowcount_g",       JsonInt(INK_FORMULA_COUNT));
}

// ----------------------------------------------------------------
// Feed: Workshop
// ----------------------------------------------------------------

void InkFeedWorkshop(object oPC, int nToken, int nFormulaId)
{
    string sName = InkGetFormulaName(nFormulaId);
    string sDesc = InkGetFormulaDesc(nFormulaId);
    int nDC      = InkGetFormulaDC(nFormulaId);
    int nSkill   = GetSkillRank(INK_SKILL_ID, oPC);

    NuiSetBind(oPC, nToken, INK_BIND_WS_TITLE,  JsonString(sName));
    NuiSetBind(oPC, nToken, INK_BIND_WS_DESC,   JsonString(sDesc));
    NuiSetBind(oPC, nToken, INK_BIND_WS_DC,
        JsonString("Próg trudności: " + IntToString(nDC)));
    NuiSetBind(oPC, nToken, INK_BIND_WS_SKILL,
        JsonString("Twoja Magia Zaklęć: " + IntToString(nSkill)));
    NuiSetBind(oPC, nToken, INK_BIND_WS_RESULT, JsonString(""));

    json jComps      = InkGetFormulaComponents(nFormulaId);
    int  nCompCount  = JsonGetLength(jComps);

    json jCompNames  = JsonArray();
    json jCompHaves  = JsonArray();
    json jCompColors = JsonArray();

    json jGreen = NuiColor(100, 210, 100);
    json jRed   = NuiColor(210, 80, 80);

    int bAllHave = TRUE;
    int i;
    for(i = 0; i < nCompCount; i++)
    {
        json jComp   = JsonArrayGet(jComps, i);
        string sTag  = JsonGetString(JsonObjectGet(jComp, "tag"));
        int nQty     = JsonGetInt(JsonObjectGet(jComp, "qty"));
        string sLbl  = JsonGetString(JsonObjectGet(jComp, "label"));
        int nHave    = InkCountItemsByTag(oPC, sTag);
        int bHave    = (nHave >= nQty);
        if(!bHave) bAllHave = FALSE;

        jCompNames  = JsonArrayInsert(jCompNames,  JsonString(sLbl));
        jCompHaves  = JsonArrayInsert(jCompHaves,  JsonString("Masz: " + IntToString(nHave) + "/" + IntToString(nQty)));
        jCompColors = JsonArrayInsert(jCompColors, bHave ? jGreen : jRed);
    }

    NuiSetBind(oPC, nToken, INK_BIND_COMP_NAME,   jCompNames);
    NuiSetBind(oPC, nToken, INK_BIND_COMP_HAVE,   jCompHaves);
    NuiSetBind(oPC, nToken, INK_BIND_COMP_COLOR,  jCompColors);
    NuiSetBind(oPC, nToken, "ink_comp_count",       JsonInt(nCompCount));
    NuiSetBind(oPC, nToken, INK_BIND_WS_INSCR_EN,  JsonBool(bAllHave));
}

// ----------------------------------------------------------------
// Feed: History
// ----------------------------------------------------------------

void InkFeedHistory(object oPC, int nToken)
{
    json jHistory = InkGetHistory(oPC);
    int  nCount   = JsonGetLength(jHistory);

    json jTexts  = JsonArray();
    json jColors = JsonArray();

    json jGreen  = NuiColor(100, 210, 100);
    json jRed    = NuiColor(210, 80, 80);
    json jYellow = NuiColor(230, 200, 60);

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow    = JsonArrayGet(jHistory, i);
        int  nFormId = JsonGetInt   (JsonObjectGet(jRow, "formula_id"));
        string sOut  = JsonGetString(JsonObjectGet(jRow, "outcome"));
        int  nTs     = JsonGetInt   (JsonObjectGet(jRow, "crafted_at"));

        string sDate = InkFormatDate(nTs);
        string sName = InkGetFormulaName(nFormId);
        string sLine = sDate + "  " + sName + " — " + sOut;

        json jColor;
        string sFirst = GetStringLeft(sOut, 1);
        if(sFirst == "W")       jColor = jYellow;  // Wyjątkowy sukces
        else if(sFirst == "S")  jColor = jGreen;   // Sukces
        else                    jColor = jRed;      // Porażka / Krytyczna

        jTexts  = JsonArrayInsert(jTexts,  JsonString(sLine));
        jColors = JsonArrayInsert(jColors, jColor);
    }

    NuiSetBind(oPC, nToken, INK_BIND_HIST_TEXT,  jTexts);
    NuiSetBind(oPC, nToken, INK_BIND_HIST_COLOR, jColors);
    NuiSetBind(oPC, nToken, "ink_hist_count",     JsonInt(nCount));
}

// ----------------------------------------------------------------
// Core inscription logic
// ----------------------------------------------------------------

void InkDoInscribe(object oPC, int nToken, int nFormulaId)
{
    if(!InkHasAllComponents(oPC, nFormulaId))
    {
        NuiSetBind(oPC, nToken, INK_BIND_WS_RESULT,
            JsonString("Brakuje składników do inkantacji."));
        return;
    }

    int nDC       = InkGetFormulaDC(nFormulaId);
    int nSkill    = GetSkillRank(INK_SKILL_ID, oPC);
    int nRoll     = d20();
    int nTotal    = nRoll + nSkill;
    int bCritFail = (nRoll == 1);
    int bSuccess  = (!bCritFail && nTotal >= nDC);
    int bExcellent = (bSuccess && nTotal >= nDC + 10);

    // Consume components: always consumed on success or crit fail;
    // on normal failure each component has 50% chance to survive.
    json jComps    = InkGetFormulaComponents(nFormulaId);
    int  nCompCount = JsonGetLength(jComps);
    int i;
    for(i = 0; i < nCompCount; i++)
    {
        json jComp  = JsonArrayGet(jComps, i);
        string sTag = JsonGetString(JsonObjectGet(jComp, "tag"));
        int nQty    = JsonGetInt(JsonObjectGet(jComp, "qty"));

        if(bSuccess || bCritFail)
        {
            InkConsumeItems(oPC, sTag, nQty);
        }
        else if(d2() == 1)
        {
            // 50% loss on failure
            InkConsumeItems(oPC, sTag, nQty);
        }
    }

    string sOutcome;
    string sMsg;

    if(bCritFail)
    {
        // Backlash: magical explosion
        int nDmg = d6() + 2;
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectDamage(nDmg, DAMAGE_TYPE_MAGICAL), oPC);
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectVisualEffect(VFX_IMP_FLAME_S), oPC);
        sOutcome = "Krytyczna porażka";
        sMsg     = "Atrament eksploduje! Zaklęcie obraca się przeciw tobie. Tracisz "
                   + IntToString(nDmg) + " punktów zdrowia.";
        FloatingTextStringOnCreature("Inkantacja spłonęła w twoich rękach...", oPC, FALSE);
    }
    else if(!bSuccess)
    {
        sOutcome = "Porażka (rzut " + IntToString(nRoll) + "+umiejętność " + IntToString(nSkill)
                   + "=" + IntToString(nTotal) + " vs. WM " + IntToString(nDC) + ")";
        sMsg     = "Litery drżą i rozlewają się — pergamin bezużyteczny. Część składników przepadła.";
        FloatingTextStringOnCreature("Zwój okazał się bezużyteczny.", oPC, FALSE);
    }
    else if(bExcellent)
    {
        string sResref = InkGetFormulaScrollResref(nFormulaId);
        if(sResref != "")
        {
            CreateItemOnObject(sResref, oPC);
            CreateItemOnObject(sResref, oPC);
        }
        sOutcome = "Wyjątkowy sukces (rzut " + IntToString(nTotal) + ")";
        sMsg     = "Twoja ręka nie drżała ani razu. Podwójny zwój — pieczęć atramentu doskonała.";
        FloatingTextStringOnCreature("Dwa zwoje z jednej inkantacji — mistrzostwo.", oPC, FALSE);
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectVisualEffect(VFX_IMP_GOOD_HELP), oPC);
    }
    else
    {
        string sResref = InkGetFormulaScrollResref(nFormulaId);
        if(sResref != "")
            CreateItemOnObject(sResref, oPC);
        sOutcome = "Sukces (rzut " + IntToString(nRoll) + "+umiejętność " + IntToString(nSkill)
                   + "=" + IntToString(nTotal) + " vs. WM " + IntToString(nDC) + ")";
        sMsg     = "Litery układają się w harmonii. Pieczęć krwi pulsuje słabo — zwój gotowy.";
        FloatingTextStringOnCreature("Inkantacja ukończona.", oPC, FALSE);
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectVisualEffect(VFX_IMP_MAGICAL_VISION), oPC);
    }

    InkLogCraft(oPC, nFormulaId, sOutcome);
    SendMessageToPC(oPC, "[Inkantator] " + sMsg);
    NuiSetBind(oPC, nToken, INK_BIND_WS_RESULT, JsonString(sMsg));

    // Refresh component availability display
    InkFeedWorkshop(oPC, nToken, nFormulaId);
}

#include "lib_por_def"

// ----------------------------------------------------------------
// Text and color helpers
// ----------------------------------------------------------------

string PorGetClassName(int nClass)
{
    if(nClass == CLASS_TYPE_BARBARIAN) return "Barbarzynca";
    if(nClass == CLASS_TYPE_BARD)      return "Bard";
    if(nClass == CLASS_TYPE_CLERIC)    return "Kleryk";
    if(nClass == CLASS_TYPE_DRUID)     return "Druid";
    if(nClass == CLASS_TYPE_FIGHTER)   return "Wojownik";
    if(nClass == CLASS_TYPE_MONK)      return "Mnich";
    if(nClass == CLASS_TYPE_PALADIN)   return "Paladyn";
    if(nClass == CLASS_TYPE_RANGER)    return "Lowca";
    if(nClass == CLASS_TYPE_ROGUE)     return "Lotrzy";
    if(nClass == CLASS_TYPE_SORCERER)  return "Czarownik";
    if(nClass == CLASS_TYPE_WIZARD)    return "Mag";
    return "Nieznany";
}

string PorGetAlignStr(object oPC)
{
    int nGE = GetAlignmentGoodEvil(oPC);
    int nLC = GetAlignmentLawChaos(oPC);
    string sGE = (nGE >= 70 ? "Dobry" : (nGE <= 30 ? "Zly" : "Neutralny"));
    string sLC = (nLC >= 70 ? "Praworzadny" : (nLC <= 30 ? "Chaotyczny" : "Neutralny"));
    if(sLC == "Neutralny" && sGE == "Neutralny") return "Neutralny";
    return sLC + " " + sGE;
}

string PorGetShadowDesc(int nScore)
{
    if(nScore >= POR_SHADOW_DAMNED)    return "Przeklety";
    if(nScore >= POR_SHADOW_CORRUPTED) return "Skazony";
    if(nScore >= POR_SHADOW_TAINTED)   return "Zmacony";
    return "Czysty";
}

json PorGetShadowColor(int nScore)
{
    if(nScore >= POR_SHADOW_DAMNED)    return NuiColor(210, 40,  40);
    if(nScore >= POR_SHADOW_CORRUPTED) return NuiColor(150, 60,  170);
    if(nScore >= POR_SHADOW_TAINTED)   return NuiColor(160, 130, 50);
    return NuiColor(200, 180, 110);
}

string PorGetStateStr(int nState)
{
    if(nState == POR_STATE_DAMAGED)  return "Zniszczony";
    if(nState == POR_STATE_MEMORIAL) return "Epitafium";
    return "Nienaruszony";
}

json PorGetStateColor(int nState)
{
    if(nState == POR_STATE_DAMAGED)  return NuiColor(200, 100, 50);
    if(nState == POR_STATE_MEMORIAL) return NuiColor(110, 110, 110);
    return NuiColor(200, 200, 200);
}

// ----------------------------------------------------------------
// Buff / curse application
// ----------------------------------------------------------------

void PorRemoveBuff(object oPC)
{
    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        if(GetEffectTag(e) == POR_TAG_BUFF)
            RemoveEffect(oPC, e);
        e = GetNextEffect(oPC);
    }
}

void PorApplyBuff(object oPC)
{
    PorRemoveBuff(oPC);
    effect eVis   = EffectVisualEffect(VFX_IMP_HOLY_AID);
    effect eSave  = EffectSavingThrowIncrease(SAVING_THROW_ALL, 1);
    effect eSkill = EffectSkillIncrease(SKILL_PERSUADE, 2);
    effect eLink  = EffectLinkEffects(eSave, eSkill);
    eLink         = TagEffect(eLink, POR_TAG_BUFF);
    ApplyEffectToObject(DURATION_TYPE_INSTANT,   eVis,  oPC);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eLink, oPC, POR_BUFF_DURATION);
}

void PorRemoveCurse(object oPC)
{
    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        if(GetEffectTag(e) == POR_TAG_CURSE)
            RemoveEffect(oPC, e);
        e = GetNextEffect(oPC);
    }
    DeleteLocalInt(oPC, POR_LVAR_CURSE);
}

void PorApplyCurse(object oPC)
{
    PorRemoveCurse(oPC);
    effect eVis  = EffectVisualEffect(VFX_IMP_DOOM);
    effect eSave = EffectSavingThrowDecrease(SAVING_THROW_ALL, 1);
    eSave        = TagEffect(eSave, POR_TAG_CURSE);
    ApplyEffectToObject(DURATION_TYPE_INSTANT,   eVis,  oPC);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eSave, oPC);
    SetLocalInt(oPC, POR_LVAR_CURSE, 1);
    SendMessageToPC(oPC, "[Portret] Twoj portret uległ zniszczeniu. Czujesz slabosci klatwy...");
}

// Called from sys_on_enter: reapply curse if portrait is damaged, remove if repaired.
void PorCheckOnEnter(object oPC)
{
    json jPor = PorGetByOwner(oPC);
    if(JsonGetType(jPor) == JSON_TYPE_NULL) return;

    int nState = JsonGetInt(JsonObjectGet(jPor, "state"));
    int bCurse = GetLocalInt(oPC, POR_LVAR_CURSE);

    if(nState == POR_STATE_DAMAGED && !bCurse)
        PorApplyCurse(oPC);
    else if(nState != POR_STATE_DAMAGED && bCurse)
        PorRemoveCurse(oPC);
}

// ----------------------------------------------------------------
// NUI layout — gallery view
// ----------------------------------------------------------------

json BuildPortraitListTemplate(object oPC)
{
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fNameW = GetNuiScaleDimension(oPC, 160.0);
    float fClsW  = GetNuiScaleDimension(oPC, 110.0);
    float fLvlW  = GetNuiScaleDimension(oPC, 44.0);
    float fShdW  = GetNuiScaleDimension(oPC, 88.0);

    json jName  = NuiLabel(NuiBind(POR_BIND_ROW_NAME),   JsonInt(NUI_HALIGN_LEFT),   JsonInt(NUI_VALIGN_MIDDLE));
    jName       = NuiStyleForegroundColor(jName, NuiBind(POR_BIND_ROW_COLOR));
    jName       = NuiWidth(jName, fNameW);

    json jCls   = NuiLabel(NuiBind(POR_BIND_ROW_CLASS),  JsonInt(NUI_HALIGN_LEFT),   JsonInt(NUI_VALIGN_MIDDLE));
    jCls        = NuiStyleForegroundColor(jCls, NuiBind(POR_BIND_ROW_COLOR));
    jCls        = NuiWidth(jCls, fClsW);

    json jLvl   = NuiLabel(NuiBind(POR_BIND_ROW_LVL),    JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLvl        = NuiStyleForegroundColor(jLvl, NuiBind(POR_BIND_ROW_COLOR));
    jLvl        = NuiWidth(jLvl, fLvlW);

    json jShd   = NuiLabel(NuiBind(POR_BIND_ROW_SHADOW), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jShd        = NuiStyleForegroundColor(jShd, NuiBind(POR_BIND_ROW_SHDCOL));
    jShd        = NuiWidth(jShd, fShdW);

    json jCells = JsonArray();
    jCells      = JsonArrayInsert(jCells, jName);
    jCells      = JsonArrayInsert(jCells, jCls);
    jCells      = JsonArrayInsert(jCells, jLvl);
    jCells      = JsonArrayInsert(jCells, jShd);

    json jCell  = NuiGroup(NuiRow(jCells), TRUE, NUI_SCROLLBARS_NONE);
    jCell       = NuiId(jCell, POR_BTN_ROW);
    jCell       = NuiEncouraged(jCell, NuiBind(POR_BIND_ROW_ENC));

    json jTmpl  = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    return jTmpl;
}

json BuildDetailPanel(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fLblH  = GetNuiScaleDimension(oPC, 22.0);
    float fMotH  = GetNuiScaleDimension(oPC, 90.0);

    json jTitle = NuiLabel(NuiBind(POR_BIND_DET_TITLE), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle      = NuiStyleForegroundColor(jTitle, NuiBind(POR_BIND_DET_TITLECOL));
    jTitle      = NuiHeight(jTitle, GetNuiScaleDimension(oPC, 28.0));

    json jSub   = NuiLabel(NuiBind(POR_BIND_DET_SUB),   JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSub        = NuiHeight(jSub, fLblH);

    json jAlign = NuiLabel(NuiBind(POR_BIND_DET_ALIGN), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jAlign      = NuiHeight(jAlign, fLblH);

    json jState = NuiLabel(NuiBind(POR_BIND_DET_STATE), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jState      = NuiHeight(jState, fLblH);

    json jShad  = NuiLabel(NuiBind(POR_BIND_DET_SHADOW), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jShad       = NuiStyleForegroundColor(jShad, NuiBind(POR_BIND_DET_SHDCOL));
    jShad       = NuiHeight(jShad, fLblH);

    json jDate  = NuiLabel(NuiBind(POR_BIND_DET_DATE),  JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDate       = NuiHeight(jDate, fLblH);

    json jMotLbl = NuiLabel(JsonString("Inskrypcja:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jMotLbl      = NuiHeight(jMotLbl, fLblH);

    json jMotto = NuiGroup(NuiText(NuiBind(POR_BIND_DET_MOTTO), FALSE), TRUE, NUI_SCROLLBARS_AUTO);
    jMotto      = NuiHeight(jMotto, fMotH);

    json jViewBtn = NuiButton(JsonString("Obejrzyj"));
    jViewBtn      = NuiId(jViewBtn, POR_BTN_VIEW);
    jViewBtn      = NuiEnabled(jViewBtn, NuiBind(POR_BIND_VIEW_ENA));
    jViewBtn      = NuiWidth(jViewBtn, GetNuiScaleDimension(oPC, 110.0));
    jViewBtn      = NuiHeight(jViewBtn, fBtnH);
    jViewBtn      = NuiTooltip(jViewBtn, JsonString("Kontempluj wlasny portret, by czerpac z niego sile (1 godz. odnowienie)."));

    json jRepairBtn = NuiButton(JsonString("Napraw"));
    jRepairBtn      = NuiId(jRepairBtn, POR_BTN_REPAIR);
    jRepairBtn      = NuiEnabled(jRepairBtn, NuiBind(POR_BIND_REPAIR_ENA));
    jRepairBtn      = NuiWidth(jRepairBtn, GetNuiScaleDimension(oPC, 90.0));
    jRepairBtn      = NuiHeight(jRepairBtn, fBtnH);
    jRepairBtn      = NuiTooltip(jRepairBtn, JsonString("Przywroc zniszczony portret za " + IntToString(POR_REPAIR_COST) + " sz."));

    json jMemBtn  = NuiButton(JsonString("Epitafium [MG]"));
    jMemBtn       = NuiId(jMemBtn, POR_BTN_MEMORIAL);
    jMemBtn       = NuiEnabled(jMemBtn, NuiBind(POR_BIND_MEM_ENA));
    jMemBtn       = NuiWidth(jMemBtn, GetNuiScaleDimension(oPC, 130.0));
    jMemBtn       = NuiHeight(jMemBtn, fBtnH);
    jMemBtn       = NuiTooltip(jMemBtn, JsonString("Oznacz portret jako pamiatke po poleglym [tylko MG]."));

    json jShadBtn = NuiButton(JsonString("+ Mrok [MG]"));
    jShadBtn      = NuiId(jShadBtn, POR_BTN_ADD_SHADOW);
    jShadBtn      = NuiEnabled(jShadBtn, NuiBind(POR_BIND_SHADOW_ENA));
    jShadBtn      = NuiWidth(jShadBtn, GetNuiScaleDimension(oPC, 110.0));
    jShadBtn      = NuiHeight(jShadBtn, fBtnH);
    jShadBtn      = NuiTooltip(jShadBtn, JsonString("Dodaj 10 pkt. mroku do wybranego portretu [tylko MG]."));

    json jActRow1 = JsonArray();
    jActRow1      = JsonArrayInsert(jActRow1, jViewBtn);
    jActRow1      = JsonArrayInsert(jActRow1, jRepairBtn);
    jActRow1      = JsonArrayInsert(jActRow1, NuiSpacer());

    json jActRow2 = JsonArray();
    jActRow2      = JsonArrayInsert(jActRow2, jMemBtn);
    jActRow2      = JsonArrayInsert(jActRow2, jShadBtn);
    jActRow2      = JsonArrayInsert(jActRow2, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jTitle);
    jCol = JsonArrayInsert(jCol, jSub);
    jCol = JsonArrayInsert(jCol, jAlign);
    jCol = JsonArrayInsert(jCol, jState);
    jCol = JsonArrayInsert(jCol, jShad);
    jCol = JsonArrayInsert(jCol, jDate);
    jCol = JsonArrayInsert(jCol, jMotLbl);
    jCol = JsonArrayInsert(jCol, jMotto);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jActRow1));
    jCol = JsonArrayInsert(jCol, NuiRow(jActRow2));

    return NuiGroup(NuiCol(jCol), FALSE, NUI_SCROLLBARS_NONE);
}

json BuildGalleryView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fListW = GetNuiScaleDimension(oPC, 430.0);
    float fListH = GetNuiScaleDimension(oPC, 380.0);

    // Column headers
    float fNameW = GetNuiScaleDimension(oPC, 160.0);
    float fClsW  = GetNuiScaleDimension(oPC, 110.0);
    float fLvlW  = GetNuiScaleDimension(oPC, 44.0);
    float fShdW  = GetNuiScaleDimension(oPC, 88.0);

    json jHdrName = NuiLabel(JsonString("Postac"),    JsonInt(NUI_HALIGN_LEFT),   JsonInt(NUI_VALIGN_MIDDLE));
    jHdrName      = NuiWidth(jHdrName, fNameW);
    json jHdrCls  = NuiLabel(JsonString("Klasa"),     JsonInt(NUI_HALIGN_LEFT),   JsonInt(NUI_VALIGN_MIDDLE));
    jHdrCls       = NuiWidth(jHdrCls,  fClsW);
    json jHdrLvl  = NuiLabel(JsonString("Poz."),      JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrLvl       = NuiWidth(jHdrLvl,  fLvlW);
    json jHdrShd  = NuiLabel(JsonString("Mrok"),      JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrShd       = NuiWidth(jHdrShd,  fShdW);
    json jHdrRow  = JsonArray();
    jHdrRow       = JsonArrayInsert(jHdrRow, jHdrName);
    jHdrRow       = JsonArrayInsert(jHdrRow, jHdrCls);
    jHdrRow       = JsonArrayInsert(jHdrRow, jHdrLvl);
    jHdrRow       = JsonArrayInsert(jHdrRow, jHdrShd);

    // Portrait list
    json jTmpl = BuildPortraitListTemplate(oPC);
    json jList = NuiList(jTmpl, NuiBind(POR_BIND_ROWCOUNT), fRowH);
    jList      = NuiHeight(jList, fListH);

    // Left column: header + list
    json jLeftCol = JsonArray();
    jLeftCol = JsonArrayInsert(jLeftCol, NuiRow(jHdrRow));
    jLeftCol = JsonArrayInsert(jLeftCol, jList);

    // Right column: detail panel
    json jLeftWrap  = NuiWidth(NuiCol(jLeftCol), fListW);
    json jRightWrap = NuiCol(JsonArrayInsert(JsonArray(), BuildDetailPanel(oPC)));

    json jSplitRow  = JsonArray();
    jSplitRow       = JsonArrayInsert(jSplitRow, jLeftWrap);
    jSplitRow       = JsonArrayInsert(jSplitRow, NuiSpacer());
    jSplitRow       = JsonArrayInsert(jSplitRow, jRightWrap);

    // Bottom bar: Commission button
    json jCommBtn = NuiButton(JsonString("Zamow Portret"));
    jCommBtn      = NuiId(jCommBtn, POR_BTN_COMMISSION);
    jCommBtn      = NuiEnabled(jCommBtn, NuiBind(POR_BIND_COMM_ENA));
    jCommBtn      = NuiWidth(jCommBtn, GetNuiScaleDimension(oPC, 140.0));
    jCommBtn      = NuiHeight(jCommBtn, fBtnH);
    jCommBtn      = NuiTooltip(jCommBtn, JsonString("Zlec namalowanie magicznego portretu za " + IntToString(POR_COMMISSION_COST) + " sz."));

    json jBotRow  = JsonArray();
    jBotRow       = JsonArrayInsert(jBotRow, jCommBtn);
    jBotRow       = JsonArrayInsert(jBotRow, NuiSpacer());

    json jRoot    = JsonArray();
    jRoot         = JsonArrayInsert(jRoot, NuiRow(jSplitRow));
    jRoot         = JsonArrayInsert(jRoot, CreateEmptyRow(oPC, 6.0));
    jRoot         = JsonArrayInsert(jRoot, NuiRow(jBotRow));

    return NuiCol(jRoot);
}

// ----------------------------------------------------------------
// NUI layout — commission view
// ----------------------------------------------------------------

json BuildCommissionView(object oPC)
{
    float fBtnH   = GetNuiScaleDimension(oPC, 30.0);
    float fMotH   = GetNuiScaleDimension(oPC, 120.0);
    float fLblH   = GetNuiScaleDimension(oPC, 22.0);

    json jTitleLbl = NuiLabel(
        JsonString("Zlecenie portretu"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, GetNuiScaleDimension(oPC, 28.0));

    json jDescLbl = NuiLabel(
        JsonString("Malarz magiczny utrwali oblicze twojej postaci na zawsze. Portret bedzie powoli"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDescLbl = NuiHeight(jDescLbl, fLblH);

    json jDescLbl2 = NuiLabel(
        JsonString("ciemniał wraz z twoimi czynami. Mozesz zostawic inskrypcje (maks. 120 znakow)."),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDescLbl2 = NuiHeight(jDescLbl2, fLblH);

    json jCostLbl = NuiLabel(NuiBind(POR_BIND_COM_COSTLBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCostLbl = NuiHeight(jCostLbl, fLblH);

    json jMotLbl = NuiLabel(JsonString("Inskrypcja (opcjonalna):"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jMotLbl = NuiHeight(jMotLbl, fLblH);

    json jMotEdit = NuiTextEdit(JsonString("Np. Krew za krew, dusza za dusze..."),
        NuiBind(POR_BIND_COM_MOTTO), 120, TRUE);
    jMotEdit = NuiHeight(jMotEdit, fMotH);

    json jConfBtn = NuiButton(JsonString("Potwierdz"));
    jConfBtn      = NuiId(jConfBtn, POR_BTN_COM_CONFIRM);
    jConfBtn      = NuiWidth(jConfBtn, GetNuiScaleDimension(oPC, 110.0));
    jConfBtn      = NuiHeight(jConfBtn, fBtnH);

    json jCancBtn = NuiButton(JsonString("Anuluj"));
    jCancBtn      = NuiId(jCancBtn, POR_BTN_COM_CANCEL);
    jCancBtn      = NuiWidth(jCancBtn, GetNuiScaleDimension(oPC, 90.0));
    jCancBtn      = NuiHeight(jCancBtn, fBtnH);

    json jBotRow  = JsonArray();
    jBotRow       = JsonArrayInsert(jBotRow, jConfBtn);
    jBotRow       = JsonArrayInsert(jBotRow, jCancBtn);
    jBotRow       = JsonArrayInsert(jBotRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jTitleLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jDescLbl);
    jCol = JsonArrayInsert(jCol, jDescLbl2);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jCostLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, jMotLbl);
    jCol = JsonArrayInsert(jCol, jMotEdit);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    // Center with side spacers
    json jSide    = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContW  = GetNuiScaleDimension(oPC, 640.0);
    json jMainRow = JsonArray();
    jMainRow      = JsonArrayInsert(jMainRow, jSide);
    jMainRow      = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContW));
    jMainRow      = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Feed functions
// ----------------------------------------------------------------

void FeedGalleryList(object oPC, int nToken)
{
    json jAll   = PorGetAll();
    int  nCount = JsonGetLength(jAll);
    int  nSelId = GetLocalInt(oPC, POR_LVAR_SEL_ID);

    json jNames   = JsonArray();
    json jClasses = JsonArray();
    json jLevels  = JsonArray();
    json jShadows = JsonArray();
    json jColors  = JsonArray();
    json jShdCols = JsonArray();
    json jEncs    = JsonArray();

    json jWhite  = NuiColor(200, 200, 200);
    json jGray   = NuiColor(110, 110, 110);

    int i;
    for(i = 0; i < nCount; i++)
    {
        json j       = JsonArrayGet(jAll, i);
        int  nId     = JsonGetInt(JsonObjectGet(j, "id"));
        int  nState  = JsonGetInt(JsonObjectGet(j, "state"));
        int  nScore  = JsonGetInt(JsonObjectGet(j, "shadow_score"));
        int  nLvl    = JsonGetInt(JsonObjectGet(j, "owner_level"));
        string sName = JsonGetString(JsonObjectGet(j, "owner_name"));
        string sCls  = JsonGetString(JsonObjectGet(j, "owner_class"));

        jNames   = JsonArrayInsert(jNames,   JsonString(sName));
        jClasses = JsonArrayInsert(jClasses, JsonString(sCls));
        jLevels  = JsonArrayInsert(jLevels,  JsonString(IntToString(nLvl)));
        jShadows = JsonArrayInsert(jShadows, JsonString(PorGetShadowDesc(nScore)));
        jColors  = JsonArrayInsert(jColors,  (nState == POR_STATE_MEMORIAL ? jGray : jWhite));
        jShdCols = JsonArrayInsert(jShdCols, PorGetShadowColor(nScore));
        jEncs    = JsonArrayInsert(jEncs,    JsonBool(nSelId > 0 && nId == nSelId));
    }

    NuiSetBind(oPC, nToken, POR_BIND_ROW_NAME,   jNames);
    NuiSetBind(oPC, nToken, POR_BIND_ROW_CLASS,  jClasses);
    NuiSetBind(oPC, nToken, POR_BIND_ROW_LVL,    jLevels);
    NuiSetBind(oPC, nToken, POR_BIND_ROW_SHADOW, jShadows);
    NuiSetBind(oPC, nToken, POR_BIND_ROW_COLOR,  jColors);
    NuiSetBind(oPC, nToken, POR_BIND_ROW_SHDCOL, jShdCols);
    NuiSetBind(oPC, nToken, POR_BIND_ROW_ENC,    jEncs);
    NuiSetBind(oPC, nToken, POR_BIND_ROWCOUNT,   JsonInt(nCount));

    // Commission button only if player doesn't already have a portrait
    int bHas = PorHasPortrait(oPC);
    NuiSetBind(oPC, nToken, POR_BIND_COMM_ENA, JsonBool(!bHas));
}

void FeedDetailEmpty(object oPC, int nToken)
{
    json jGray = NuiColor(140, 140, 140);
    NuiSetBind(oPC, nToken, POR_BIND_DET_TITLE,    JsonString("Wybierz portret z listy"));
    NuiSetBind(oPC, nToken, POR_BIND_DET_SUB,      JsonString(""));
    NuiSetBind(oPC, nToken, POR_BIND_DET_ALIGN,    JsonString(""));
    NuiSetBind(oPC, nToken, POR_BIND_DET_STATE,    JsonString(""));
    NuiSetBind(oPC, nToken, POR_BIND_DET_SHADOW,   JsonString(""));
    NuiSetBind(oPC, nToken, POR_BIND_DET_DATE,     JsonString(""));
    NuiSetBind(oPC, nToken, POR_BIND_DET_MOTTO,    JsonString(""));
    NuiSetBind(oPC, nToken, POR_BIND_DET_TITLECOL, jGray);
    NuiSetBind(oPC, nToken, POR_BIND_DET_SHDCOL,   jGray);
    NuiSetBind(oPC, nToken, POR_BIND_VIEW_ENA,     JsonBool(FALSE));
    NuiSetBind(oPC, nToken, POR_BIND_REPAIR_ENA,   JsonBool(FALSE));
    NuiSetBind(oPC, nToken, POR_BIND_MEM_ENA,      JsonBool(FALSE));
    NuiSetBind(oPC, nToken, POR_BIND_SHADOW_ENA,   JsonBool(FALSE));
}

void FeedPortraitDetail(object oPC, int nToken, int nId)
{
    json jPor = PorGetById(nId);
    if(JsonGetType(jPor) == JSON_TYPE_NULL)
    {
        FeedDetailEmpty(oPC, nToken);
        return;
    }

    string sOwnerUuid = JsonGetString(JsonObjectGet(jPor, "owner_uuid"));
    string sName      = JsonGetString(JsonObjectGet(jPor, "owner_name"));
    string sCls       = JsonGetString(JsonObjectGet(jPor, "owner_class"));
    int    nLvl       = JsonGetInt   (JsonObjectGet(jPor, "owner_level"));
    string sAlign     = JsonGetString(JsonObjectGet(jPor, "owner_align"));
    int    nScore     = JsonGetInt   (JsonObjectGet(jPor, "shadow_score"));
    int    nState     = JsonGetInt   (JsonObjectGet(jPor, "state"));
    string sMotto     = JsonGetString(JsonObjectGet(jPor, "motto"));
    int    nCreated   = JsonGetInt   (JsonObjectGet(jPor, "created_at"));
    int    nLastBuff  = JsonGetInt   (JsonObjectGet(jPor, "last_buff_at"));

    string sStateStr  = PorGetStateStr(nState);
    string sShadDesc  = PorGetShadowDesc(nScore);
    string sDate      = PorFormatDate(nCreated);
    string sMottoDisp = (sMotto != "" ? "\"" + sMotto + "\"" : "(brak inskrypcji)");

    // Determine whether buttons are enabled
    int bOwn    = (GetObjectUUID(oPC) == sOwnerUuid);
    int bIsDM   = GetIsDM(oPC);
    int bAlive  = (nState != POR_STATE_MEMORIAL);
    int bCanView= bOwn && bAlive && nState != POR_STATE_DAMAGED && PorBuffReady(nLastBuff);
    int bCanRep = bOwn && nState == POR_STATE_DAMAGED;
    int bCanMem = bIsDM && bAlive;
    int bCanShd = bIsDM;

    json jTitleCol = (nState == POR_STATE_MEMORIAL
        ? NuiColor(130, 130, 130)
        : PorGetShadowColor(nScore));

    NuiSetBind(oPC, nToken, POR_BIND_DET_TITLE,    JsonString(sName));
    NuiSetBind(oPC, nToken, POR_BIND_DET_SUB,      JsonString(sCls + " (poz. " + IntToString(nLvl) + ")"));
    NuiSetBind(oPC, nToken, POR_BIND_DET_ALIGN,    JsonString("Wyrownanie: " + sAlign));
    NuiSetBind(oPC, nToken, POR_BIND_DET_STATE,    JsonString("Stan: " + sStateStr));
    NuiSetBind(oPC, nToken, POR_BIND_DET_SHADOW,   JsonString("Mrok: " + sShadDesc + " (" + IntToString(nScore) + " pkt.)"));
    NuiSetBind(oPC, nToken, POR_BIND_DET_DATE,     JsonString("Namalowany: " + sDate));
    NuiSetBind(oPC, nToken, POR_BIND_DET_MOTTO,    JsonString(sMottoDisp));
    NuiSetBind(oPC, nToken, POR_BIND_DET_TITLECOL, jTitleCol);
    NuiSetBind(oPC, nToken, POR_BIND_DET_SHDCOL,   PorGetShadowColor(nScore));
    NuiSetBind(oPC, nToken, POR_BIND_VIEW_ENA,     JsonBool(bCanView));
    NuiSetBind(oPC, nToken, POR_BIND_REPAIR_ENA,   JsonBool(bCanRep));
    NuiSetBind(oPC, nToken, POR_BIND_MEM_ENA,      JsonBool(bCanMem));
    NuiSetBind(oPC, nToken, POR_BIND_SHADOW_ENA,   JsonBool(bCanShd));
}

void FeedCommissionView(object oPC, int nToken)
{
    string sCost = "Koszt: " + IntToString(POR_COMMISSION_COST) + " sztuk zlota "
        + "(posiadasz: " + IntToString(GetGold(oPC)) + " sz.)";
    NuiSetBind(oPC, nToken, POR_BIND_COM_COSTLBL, JsonString(sCost));
    NuiSetBind(oPC, nToken, POR_BIND_COM_MOTTO,   JsonString(""));
}

// ----------------------------------------------------------------
// Window lifecycle
// ----------------------------------------------------------------

void CreatePortraitWindow(object oPC)
{
    if(NuiFindWindow(oPC, POR_WINDOW) != 0)
    {
        SwapToGalleryView(oPC, NuiFindWindow(oPC, POR_WINDOW));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
        - GetNuiScaleDimension(oPC, POR_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
        - GetNuiScaleDimension(oPC, POR_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
        GetNuiScaleDimension(oPC, POR_W),
        GetNuiScaleDimension(oPC, POR_H));

    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn      = NuiId(jCloseBtn, POR_BTN_CLOSE);
    jCloseBtn      = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn      = NuiHeight(jCloseBtn, fBtnH);
    json jTopRow   = JsonArray();
    jTopRow        = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow        = JsonArrayInsert(jTopRow, jCloseBtn);

    json jSwapGrp  = NuiGroup(BuildGalleryView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp       = NuiId(jSwapGrp, POR_GRP_SWAP);

    json jRoot     = JsonArray();
    jRoot          = JsonArrayInsert(jRoot, NuiRow(jTopRow));
    jRoot          = JsonArrayInsert(jRoot, jSwapGrp);

    json jWin = NuiWindow(NuiCol(jRoot),
        JsonString("Galeria Portretow"),
        NuiBind(POR_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, POR_WINDOW, POR_EV_SCRIPT);
    NuiSetBind(oPC, nToken, POR_WIN_GEOM, jGeom);

    SwapToGalleryView(oPC, nToken);
}

void SwapToGalleryView(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, POR_GRP_SWAP, BuildGalleryView(oPC));
    SetLocalInt(oPC, POR_LVAR_SEL_ID, 0);
    FeedGalleryList(oPC, nToken);
    FeedDetailEmpty(oPC, nToken);
}

void SwapToCommissionView(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, POR_GRP_SWAP, BuildCommissionView(oPC));
    FeedCommissionView(oPC, nToken);
}

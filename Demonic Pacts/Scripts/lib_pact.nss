#include "lib_pact_def"

// ---- UI panel builders ----

json BuildPactListPanel(object oPC)
{
    float fW    = GetNuiScaleDimension(oPC, 185.0);
    float fRowH = GetNuiScaleDimension(oPC, 46.0);
    float fListH= GetNuiScaleDimension(oPC, 200.0);

    json jNameLbl = NuiLabel(NuiBind(PACT_BIND_LIST_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jCell = NuiGroup(NuiRow(JsonArrayInsert(JsonArray(), jNameLbl)), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, PACT_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(PACT_BIND_LIST_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(PACT_BIND_LIST_CNT), fRowH);
    jList = NuiHeight(jList, fListH);

    json jHeaderLbl = NuiLabel(JsonString("Dostepne pakty"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHeaderLbl = NuiHeight(jHeaderLbl, GetNuiScaleDimension(oPC, 24.0));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHeaderLbl);
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, NuiSpacer());

    return NuiWidth(NuiCol(jCol), fW);
}

json BuildPactDetailPanel(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fLoreH = GetNuiScaleDimension(oPC, 110.0);
    float fLblH  = GetNuiScaleDimension(oPC, 22.0);

    json jDemonName = NuiLabel(NuiBind(PACT_BIND_DETAIL_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDemonName = NuiHeight(jDemonName, GetNuiScaleDimension(oPC, 28.0));
    jDemonName = NuiStyleForegroundColor(jDemonName, NuiColor(210, 60, 60));

    json jLoreGrp = NuiGroup(NuiText(NuiBind(PACT_BIND_DETAIL_LORE), FALSE), FALSE, NUI_SCROLLBARS_NONE);
    jLoreGrp = NuiHeight(jLoreGrp, fLoreH);

    json jBuffLbl = NuiLabel(NuiBind(PACT_BIND_DETAIL_BUFF), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBuffLbl = NuiHeight(jBuffLbl, fLblH);
    jBuffLbl = NuiStyleForegroundColor(jBuffLbl, NuiColor(90, 200, 90));

    json jTollLbl = NuiLabel(NuiBind(PACT_BIND_DETAIL_TOLL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTollLbl = NuiHeight(jTollLbl, fLblH);
    jTollLbl = NuiStyleForegroundColor(jTollLbl, NuiColor(200, 80, 80));

    json jSignBtn = NuiButton(NuiBind(PACT_BIND_SIGN_LBL));
    jSignBtn = NuiId(jSignBtn, PACT_BTN_SIGN);
    jSignBtn = NuiEnabled(jSignBtn, NuiBind(PACT_BIND_SIGN_ENA));
    jSignBtn = NuiWidth(jSignBtn,  GetNuiScaleDimension(oPC, 230.0));
    jSignBtn = NuiHeight(jSignBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jSignBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jDemonName);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jLoreGrp);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jBuffLbl);
    jCol = JsonArrayInsert(jCol, jTollLbl);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    return NuiCol(jCol);
}

json BuildPactStatusBar(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fBarH = GetNuiScaleDimension(oPC, 46.0);

    json jStatusLbl = NuiLabel(NuiBind(PACT_BIND_STATUS_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jBreakBtn = NuiButton(NuiBind(PACT_BIND_BREAK_LBL));
    jBreakBtn = NuiId(jBreakBtn, PACT_BTN_BREAK);
    jBreakBtn = NuiEnabled(jBreakBtn, NuiBind(PACT_BIND_BREAK_ENA));
    jBreakBtn = NuiWidth(jBreakBtn,  GetNuiScaleDimension(oPC, 210.0));
    jBreakBtn = NuiHeight(jBreakBtn, fBtnH);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jStatusLbl);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jBreakBtn);

    json jBar = NuiGroup(NuiRow(jRow), TRUE, NUI_SCROLLBARS_NONE);
    jBar = NuiHeight(jBar, fBarH);
    return jBar;
}

// ---- Feed functions ----

void FeedPactList(object oPC, int nToken)
{
    json jActive  = PactGetActive(oPC);
    string sActId = "";
    if(JsonGetType(jActive) != JSON_TYPE_NULL)
        sActId = JsonGetString(JsonObjectGet(jActive, "demon_id"));

    string sSelId = GetLocalString(oPC, PACT_LVAR_SEL);

    json jNames = JsonArray();
    json jEncs  = JsonArray();
    int i;
    for(i = 0; i < PACT_DEMON_COUNT; i++)
    {
        string sId   = PactGetDemonId(i);
        string sName = PactGetDemonName(sId);
        if(sId == sActId) sName = "* " + sName;
        jNames = JsonArrayInsert(jNames, JsonString(sName));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(sId == sSelId));
    }

    NuiSetBind(oPC, nToken, PACT_BIND_LIST_NAME, jNames);
    NuiSetBind(oPC, nToken, PACT_BIND_LIST_ENC,  jEncs);
    NuiSetBind(oPC, nToken, PACT_BIND_LIST_CNT,  JsonInt(PACT_DEMON_COUNT));
}

void FeedPactDetail(object oPC, int nToken, string sDemonId)
{
    json   jActive = PactGetActive(oPC);
    string sActId  = "";
    if(JsonGetType(jActive) != JSON_TYPE_NULL)
        sActId = JsonGetString(JsonObjectGet(jActive, "demon_id"));

    int bHasPact  = (sActId != "");
    int bIsActive = (sDemonId == sActId);

    NuiSetBind(oPC, nToken, PACT_BIND_DETAIL_NAME, JsonString(PactGetDemonName(sDemonId)));
    NuiSetBind(oPC, nToken, PACT_BIND_DETAIL_LORE, JsonString(PactGetDemonLore(sDemonId)));
    NuiSetBind(oPC, nToken, PACT_BIND_DETAIL_BUFF, JsonString(PactGetDemonBuff(sDemonId)));
    NuiSetBind(oPC, nToken, PACT_BIND_DETAIL_TOLL, JsonString(PactGetDemonToll(sDemonId)));

    string sSignLbl;
    int    bSignEna;
    if(bIsActive)
    {
        sSignLbl = "Pakt aktywny";
        bSignEna = FALSE;
    }
    else if(bHasPact)
    {
        sSignLbl = "Masz juz aktywny pakt";
        bSignEna = FALSE;
    }
    else
    {
        sSignLbl = "Zawrzyj Pakt";
        bSignEna = TRUE;
    }

    NuiSetBind(oPC, nToken, PACT_BIND_SIGN_LBL, JsonString(sSignLbl));
    NuiSetBind(oPC, nToken, PACT_BIND_SIGN_ENA, JsonBool(bSignEna));
}

void FeedPactStatus(object oPC, int nToken)
{
    json jActive = PactGetActive(oPC);
    if(JsonGetType(jActive) == JSON_TYPE_NULL)
    {
        NuiSetBind(oPC, nToken, PACT_BIND_STATUS_LBL, JsonString("Brak aktywnego paktu. Pieczen oltarza pozostaje nienaruszona."));
        NuiSetBind(oPC, nToken, PACT_BIND_BREAK_LBL,  JsonString("Brak paktu"));
        NuiSetBind(oPC, nToken, PACT_BIND_BREAK_ENA,  JsonBool(FALSE));
        return;
    }

    string sId    = JsonGetString(JsonObjectGet(jActive, "demon_id"));
    int    nTolls = JsonGetInt   (JsonObjectGet(jActive, "toll_count"));

    string sStatus = "Aktywny: " + PactGetDemonName(sId) + "  |  Haracz pobrany: " + IntToString(nTolls) + "x";
    string sBreak  = "Zerwij Pakt (" + IntToString(PACT_BREAK_HP_COST) + " PZ + klatwa)";

    NuiSetBind(oPC, nToken, PACT_BIND_STATUS_LBL, JsonString(sStatus));
    NuiSetBind(oPC, nToken, PACT_BIND_BREAK_LBL,  JsonString(sBreak));
    NuiSetBind(oPC, nToken, PACT_BIND_BREAK_ENA,  JsonBool(TRUE));
}

// ---- Window creation ----

void CreatePactWindow(object oPC)
{
    int nExisting = NuiFindWindow(oPC, PACT_WINDOW);
    if(nExisting != 0)
    {
        FeedPactList(oPC, nExisting);
        FeedPactStatus(oPC, nExisting);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, PACT_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, PACT_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, PACT_W), GetNuiScaleDimension(oPC, PACT_H));

    // Top bar: title label + close button
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    json jTitleLbl = NuiLabel(JsonString("Oltarz Paktow"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiStyleForegroundColor(jTitleLbl, NuiColor(210, 60, 60));
    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, PACT_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn,  GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitleLbl);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jCloseBtn);

    // Content row: demon list (fixed width) | detail panel (elastic)
    json jSepCol = NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer())), GetNuiScaleDimension(oPC, 12.0));
    json jContentRow = JsonArray();
    jContentRow = JsonArrayInsert(jContentRow, BuildPactListPanel(oPC));
    jContentRow = JsonArrayInsert(jContentRow, jSepCol);
    jContentRow = JsonArrayInsert(jContentRow, BuildPactDetailPanel(oPC));

    // Root column
    json jRootCol = JsonArray();
    jRootCol = JsonArrayInsert(jRootCol, NuiRow(jTopRow));
    jRootCol = JsonArrayInsert(jRootCol, NuiRow(jContentRow));
    jRootCol = JsonArrayInsert(jRootCol, BuildPactStatusBar(oPC));

    json jWin = NuiWindow(NuiCol(jRootCol),
        JsonBool(FALSE),
        NuiBind(PACT_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, PACT_WINDOW, PACT_EV_SCRIPT);
    NuiSetBind(oPC, nToken, PACT_WIN_GEOM, jGeom);

    // Default selection: first demon
    SetLocalString(oPC, PACT_LVAR_SEL, PACT_DEMON_ORCUS);
    FeedPactList(oPC, nToken);
    FeedPactDetail(oPC, nToken, PACT_DEMON_ORCUS);
    FeedPactStatus(oPC, nToken);
}

// ---- Game logic ----

void PactRemoveEffects(object oPC)
{
    // Iterate effects; safe pattern for removal during iteration.
    effect eCur = GetFirstEffect(oPC);
    while(GetIsEffectValid(eCur))
    {
        effect eNext = GetNextEffect(oPC);
        if(GetStringLeft(GetEffectTag(eCur), GetStringLength(PACT_EFFECT_PREFIX)) == PACT_EFFECT_PREFIX)
            RemoveEffect(oPC, eCur);
        eCur = eNext;
    }
}

void PactApplyEffects(object oPC, string sDemonId)
{
    PactRemoveEffects(oPC);

    if(sDemonId == PACT_DEMON_ORCUS)
    {
        effect eRegen = EffectSetTag(SupernaturalEffect(EffectRegenerate(2, 6.0)), "PACT_ORCUS_REGEN");
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eRegen, oPC);
    }
    else if(sDemonId == PACT_DEMON_BAEL)
    {
        effect eStr = EffectSetTag(SupernaturalEffect(EffectAbilityIncrease(ABILITY_STRENGTH, 4)), "PACT_BAEL_STR");
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eStr, oPC);
    }
    else if(sDemonId == PACT_DEMON_GLASYA)
    {
        effect eHide = EffectSetTag(SupernaturalEffect(EffectSkillIncrease(SKILL_HIDE, 6)), "PACT_GLASYA_HIDE");
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eHide, oPC);

        effect eMove = EffectSetTag(SupernaturalEffect(EffectSkillIncrease(SKILL_MOVE_SILENTLY, 6)), "PACT_GLASYA_MOVE");
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eMove, oPC);
    }
    else if(sDemonId == PACT_DEMON_JUIBLEX)
    {
        effect eAC = EffectSetTag(SupernaturalEffect(EffectACIncrease(5, AC_NATURAL_BONUS)), "PACT_JUIBLEX_AC");
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eAC, oPC);
    }
}

void PactCollectToll(object oPC)
{
    json jActive = PactGetActive(oPC);
    if(JsonGetType(jActive) == JSON_TYPE_NULL) return;
    if(PactGetTimeSinceLastToll(oPC) < PACT_TOLL_INTERVAL) return;

    string sDemonId = JsonGetString(JsonObjectGet(jActive, "demon_id"));
    PactRecordToll(oPC);

    if(sDemonId == PACT_DEMON_ORCUS)
    {
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectDamage(12, DAMAGE_TYPE_NEGATIVE, DAMAGE_POWER_NORMAL), oPC);
        SendMessageToPC(oPC, "[Pakt] Pieczen krwi pulsuje slabo... Orcus pobiera swoj haracz.");
    }
    else if(sDemonId == PACT_DEMON_BAEL)
    {
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectDamage(8, DAMAGE_TYPE_NEGATIVE, DAMAGE_POWER_NORMAL), oPC);
        int nNewXP = GetXP(oPC) - 50;
        if(nNewXP < 0) nNewXP = 0;
        SetXP(oPC, nNewXP);
        SendMessageToPC(oPC, "[Pakt] Zelazna dlon zaciska sie na duszy... Bael pobiera swoj haracz.");
    }
    else if(sDemonId == PACT_DEMON_GLASYA)
    {
        int nNewXP = GetXP(oPC) - 60;
        if(nNewXP < 0) nNewXP = 0;
        SetXP(oPC, nNewXP);
        SendMessageToPC(oPC, "[Pakt] Fragment wspomnien odplywa w mrok... Glasya pobiera swoj haracz.");
    }
    else if(sDemonId == PACT_DEMON_JUIBLEX)
    {
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectDamage(10, DAMAGE_TYPE_ACID, DAMAGE_POWER_NORMAL), oPC);

        // Random curse chosen each toll — Juiblex is unpredictable.
        int nRoll = d4();
        effect eCurse;
        if(nRoll == 1)
            eCurse = EffectConfused();
        else if(nRoll == 2)
            eCurse = EffectBlindness();
        else if(nRoll == 3)
            eCurse = EffectAbilityDecrease(ABILITY_INTELLIGENCE, 2);
        else
            eCurse = EffectAbilityDecrease(ABILITY_WISDOM, 2);

        effect eLinked = EffectLinkEffects(eCurse, EffectVisualEffect(VFX_DUR_BLUR));
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eLinked, oPC, 30.0);
        SendMessageToPC(oPC, "[Pakt] Cos gnitego wnika w mysli... Juiblex pobiera swoj haracz.");
    }

    // Refresh open window if visible.
    int nToken = NuiFindWindow(oPC, PACT_WINDOW);
    if(nToken != 0) FeedPactStatus(oPC, nToken);
}

void PactCheckAndApply(object oPC)
{
    json jActive = PactGetActive(oPC);
    if(JsonGetType(jActive) == JSON_TYPE_NULL)
    {
        PactRemoveEffects(oPC);
        return;
    }

    string sDemonId = JsonGetString(JsonObjectGet(jActive, "demon_id"));
    int    nTolls   = JsonGetInt   (JsonObjectGet(jActive, "toll_count"));
    PactApplyEffects(oPC, sDemonId);
    SendMessageToPC(oPC, "[Pakt] Aktywny: " + PactGetDemonName(sDemonId)
        + " (haracz pobrany: " + IntToString(nTolls) + "x). Pieczen krwi plonie.");
}

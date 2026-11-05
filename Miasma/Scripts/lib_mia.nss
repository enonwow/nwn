#include "lib_mia_def"

// ================================================================
// Gauge HUD layout  (small overlay, top-right corner)
// ================================================================

json BuildMiaGaugeLayout(object oPC)
{
    float fW     = GetNuiScaleDimension(oPC, 210.0);
    float fBarH  = GetNuiScaleDimension(oPC, 16.0);
    float fLblH  = GetNuiScaleDimension(oPC, 20.0);
    float fBtnH  = GetNuiScaleDimension(oPC, 24.0);

    // Header: type name  e.g. "Opar – Demoniczny"
    json jHeader = NuiLabel(NuiBind(MIA_BIND_HEADER),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHeader = NuiHeight(jHeader, fLblH);

    // Progress bar showing exposure
    json jBar = NuiProgress(NuiBind(MIA_BIND_BAR));
    jBar = NuiHeight(jBar, fBarH);
    jBar = NuiStyleForegroundColor(jBar, NuiBind(MIA_BIND_BAR_COLOR));
    jBar = NuiTooltip(jBar, NuiBind(MIA_BIND_TIP));

    // Severity label  e.g. "Łagodny" / "Silny"
    json jSeverity = NuiLabel(NuiBind(MIA_BIND_SEVERITY),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jSeverity = NuiHeight(jSeverity, fLblH);

    // Cleanse button — consume herb from inventory
    json jCleanse = NuiButton(JsonString("Oczyść"));
    jCleanse = NuiId(jCleanse, MIA_BTN_CLEANSE);
    jCleanse = NuiWidth(jCleanse, GetNuiScaleDimension(oPC, 80.0));
    jCleanse = NuiHeight(jCleanse, fBtnH);
    jCleanse = NuiTooltip(jCleanse, JsonString("Użyj zioła oczyszczającego z ekwipunku."));

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jCleanse);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHeader);
    jCol = JsonArrayInsert(jCol, jBar);
    jCol = JsonArrayInsert(jCol, jSeverity);
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    return NuiCol(jCol);
}

// ================================================================
// Gauge window lifecycle
// ================================================================

void MiaShowGauge(object oPC)
{
    int nToken = NuiFindWindow(oPC, MIA_WINDOW);
    if(nToken != 0)
    {
        MiaFeedGauge(oPC, nToken);
        return;
    }

    float fW   = GetNuiScaleDimension(oPC, 220.0);
    float fH   = GetNuiScaleDimension(oPC, 110.0);
    float fGW  = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH));
    float fX   = fGW - fW - GetNuiScaleDimension(oPC, 10.0);
    float fY   = GetNuiScaleDimension(oPC, 10.0);
    json  jGeom = NuiRect(fX, fY, fW, fH);

    json jWin = NuiWindow(BuildMiaGaugeLayout(oPC),
        JsonBool(FALSE),
        NuiBind(MIA_BIND_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, MIA_WINDOW, MIA_EV_SCRIPT);
    NuiSetBind(oPC, nToken, MIA_BIND_GEOM, jGeom);
    MiaFeedGauge(oPC, nToken);
}

void MiaHideGauge(object oPC)
{
    int nToken = NuiFindWindow(oPC, MIA_WINDOW);
    if(nToken != 0)
        NuiDestroy(oPC, nToken);
}

void MiaFeedGauge(object oPC, int nToken)
{
    int nExposure = GetLocalInt(oPC, MIA_LVAR_EXPOSURE);
    int nType     = GetLocalInt(oPC, MIA_LVAR_TYPE);
    int nLvl      = MiaExposureToLevel(nExposure);

    string sHeader   = "Opar — " + MiaTypeName(nType);
    string sSeverity = MiaSeverityName(nLvl);
    if(sSeverity == "") sSeverity = "Zanika...";

    string sTip = "Ekspozycja: " + IntToString(nExposure) + "/" + IntToString(MIA_MAX_EXPOSURE);

    NuiSetBind(oPC, nToken, MIA_BIND_HEADER,    JsonString(sHeader));
    NuiSetBind(oPC, nToken, MIA_BIND_BAR,       JsonFloat(MiaExposureToProgress(nExposure)));
    NuiSetBind(oPC, nToken, MIA_BIND_BAR_COLOR, MiaLevelColor(nLvl));
    NuiSetBind(oPC, nToken, MIA_BIND_SEVERITY,  JsonString(sSeverity));
    NuiSetBind(oPC, nToken, MIA_BIND_TIP,       JsonString(sTip));
}

// ================================================================
// Effects: apply / remove debuffs based on exposure level
// ================================================================

void MiaRemoveEffects(object oPC)
{
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        if(GetEffectTag(eEff) == MIA_EFFECT_TAG)
            RemoveEffect(oPC, eEff);
        eEff = GetNextEffect(oPC);
    }
}

void MiaApplyNecrotic(object oPC, int nLvl)
{
    // Necrotic: Wisdom drain + Constitution drain at higher levels
    if(nLvl >= MIA_LVL_MILD)
    {
        effect eWis = TagEffect(EffectAbilityDecrease(ABILITY_WISDOM, 2), MIA_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eWis, oPC);
    }
    if(nLvl >= MIA_LVL_MODERATE)
    {
        effect eCon = TagEffect(EffectAbilityDecrease(ABILITY_CONSTITUTION, 2), MIA_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eCon, oPC);
        effect eVfx = TagEffect(EffectVisualEffect(VFX_DUR_SPELLTURNING), MIA_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eVfx, oPC);
    }
    if(nLvl >= MIA_LVL_SEVERE)
    {
        // Slow and bleed
        effect eSlow = TagEffect(EffectMovementSpeedDecrease(50), MIA_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eSlow, oPC);
        effect eBleed = TagEffect(EffectDamage(d4(), DAMAGE_TYPE_NEGATIVE), MIA_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, eBleed, oPC);
    }
}

void MiaApplySwamp(object oPC, int nLvl)
{
    // Swamp: Strength + Dexterity drain (heavy limbs), disease-like progression
    if(nLvl >= MIA_LVL_MILD)
    {
        effect eStr = TagEffect(EffectAbilityDecrease(ABILITY_STRENGTH, 2), MIA_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eStr, oPC);
    }
    if(nLvl >= MIA_LVL_MODERATE)
    {
        effect eDex = TagEffect(EffectAbilityDecrease(ABILITY_DEXTERITY, 2), MIA_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eDex, oPC);
        effect eVfx = TagEffect(EffectVisualEffect(VFX_DUR_PARALYZE_HOLD), MIA_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eVfx, oPC);
    }
    if(nLvl >= MIA_LVL_SEVERE)
    {
        effect eSick = TagEffect(EffectDisease(DISEASE_FILTH_FEVER), MIA_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eSick, oPC);
    }
}

void MiaApplyDemonic(object oPC, int nLvl)
{
    // Demonic: Charisma + Intelligence drain, fear at severe
    if(nLvl >= MIA_LVL_MILD)
    {
        effect eCha = TagEffect(EffectAbilityDecrease(ABILITY_CHARISMA, 2), MIA_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eCha, oPC);
    }
    if(nLvl >= MIA_LVL_MODERATE)
    {
        effect eInt = TagEffect(EffectAbilityDecrease(ABILITY_INTELLIGENCE, 2), MIA_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eInt, oPC);
        effect eVfx = TagEffect(EffectVisualEffect(VFX_DUR_INFERNO_HEAD), MIA_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eVfx, oPC);
    }
    if(nLvl >= MIA_LVL_SEVERE)
    {
        effect eFear = TagEffect(EffectFrightened(), MIA_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectLinkEffects(eFear,
            TagEffect(EffectVisualEffect(VFX_DUR_MIND_AFFECTING_FEAR), MIA_EFFECT_TAG)), oPC);
        // Demonic essence burns away HP
        effect eDmg = TagEffect(EffectDamage(d6(), DAMAGE_TYPE_FIRE), MIA_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, eDmg, oPC);
    }
}

void MiaApplyEffects(object oPC, int nExposure, int nType)
{
    MiaRemoveEffects(oPC);
    int nLvl = MiaExposureToLevel(nExposure);
    if(nLvl == MIA_LVL_NONE) return;

    if(nType == MIA_TYPE_NECROTIC) MiaApplyNecrotic(oPC, nLvl);
    else if(nType == MIA_TYPE_SWAMP)   MiaApplySwamp(oPC, nLvl);
    else if(nType == MIA_TYPE_DEMONIC) MiaApplyDemonic(oPC, nLvl);
}

// ================================================================
// Cleansing herb consumption (called from event handler)
// ================================================================

int MiaTryCleanseWithHerb(object oPC)
{
    object oHerb = GetItemPossessedBy(oPC, MIA_ITEM_HERB);
    if(!GetIsObjectValid(oHerb)) return FALSE;

    int nStack = GetItemStackSize(oHerb);
    if(nStack > 1)
        SetItemStackSize(oHerb, nStack - 1);
    else
        DestroyObject(oHerb);

    // Reduce exposure by half
    int nExposure = GetLocalInt(oPC, MIA_LVAR_EXPOSURE);
    nExposure = nExposure / 2;
    SetLocalInt(oPC, MIA_LVAR_EXPOSURE, nExposure);

    int nType = GetLocalInt(oPC, MIA_LVAR_TYPE);
    MiaApplyEffects(oPC, nExposure, nType);

    int nToken = NuiFindWindow(oPC, MIA_WINDOW);
    if(nToken != 0) MiaFeedGauge(oPC, nToken);

    SendMessageToPC(oPC, "[Opar] Zioło oczyszczające łagodzi toksyny. Ekspozycja zmniejszona o połowę.");
    return TRUE;
}

// ================================================================
// Tick loop — called every MIA_TICK_DELAY seconds per PC
// ================================================================

void MiaTick(object oPC)
{
    if(!GetIsObjectValid(oPC) || !GetIsPC(oPC))
    {
        DeleteLocalInt(oPC, MIA_LVAR_TICKING);
        return;
    }

    // Check if PC's current area is tainted
    object oArea    = GetArea(oPC);
    string sTag     = GetTag(oArea);
    json   jAreaData = MiaGetAreaData(sTag);
    int    nIntensity = JsonGetInt(JsonObjectGet(jAreaData, "intensity"));
    int    nAreaType  = JsonGetInt(JsonObjectGet(jAreaData, "mia_type"));

    int nExposure = GetLocalInt(oPC, MIA_LVAR_EXPOSURE);
    int nType     = GetLocalInt(oPC, MIA_LVAR_TYPE);

    if(nIntensity > 0)
    {
        // Accumulate exposure; type transitions to match current area
        nExposure += nIntensity;
        if(nExposure > MIA_MAX_EXPOSURE) nExposure = MIA_MAX_EXPOSURE;
        nType = nAreaType;
        SetLocalInt(oPC, MIA_LVAR_TYPE, nType);
    }
    else
    {
        // Decay when outside tainted area
        nExposure -= MIA_DECAY_PER_TICK;
        if(nExposure < 0) nExposure = 0;
    }

    SetLocalInt(oPC, MIA_LVAR_EXPOSURE, nExposure);

    int nLvl     = MiaExposureToLevel(nExposure);
    int nLastLvl = GetLocalInt(oPC, MIA_LVAR_LAST_LVL);

    // Show/hide gauge
    if(nExposure > 0)
        MiaShowGauge(oPC);
    else
        MiaHideGauge(oPC);

    // Only reapply effects when severity tier changes (avoids spam)
    if(nLvl != nLastLvl)
    {
        SetLocalInt(oPC, MIA_LVAR_LAST_LVL, nLvl);
        MiaApplyEffects(oPC, nExposure, nType);

        if(nLvl == MIA_LVL_MILD)
            FloatingTextStringOnCreature("Opar przenika twoje ciało... Czujesz mdłości.", oPC, FALSE);
        else if(nLvl == MIA_LVL_MODERATE)
            FloatingTextStringOnCreature("Skażenie wgryza się głębiej. Każdy oddech boli.", oPC, FALSE);
        else if(nLvl == MIA_LVL_SEVERE)
            FloatingTextStringOnCreature("Opar trawi cię od środka. Musisz uciekać!", oPC, FALSE);
        else if(nLvl == MIA_LVL_NONE && nLastLvl > MIA_LVL_NONE)
            FloatingTextStringOnCreature("Skażenie powoli ustępuje. Oddychasz z ulgą.", oPC, FALSE);
    }
    else if(nExposure > 0)
    {
        // Refresh gauge on every tick even without tier change
        int nToken = NuiFindWindow(oPC, MIA_WINDOW);
        if(nToken != 0) MiaFeedGauge(oPC, nToken);
    }

    // Stop the loop only once fully decayed and no active area
    if(nExposure == 0 && nIntensity == 0)
    {
        DeleteLocalInt(oPC, MIA_LVAR_TICKING);
        return;
    }

    DelayCommand(MIA_TICK_DELAY, MiaTick(oPC));
}

// Start the tick loop once — guard against double-start
void MiaStartTick(object oPC)
{
    if(GetLocalInt(oPC, MIA_LVAR_TICKING)) return;
    SetLocalInt(oPC, MIA_LVAR_TICKING, 1);
    DelayCommand(MIA_TICK_DELAY, MiaTick(oPC));
}

// ================================================================
// DM panel — allows DMs to taint / cleanse areas in real time
// ================================================================

json BuildMiaDmPanelLayout(object oPC)
{
    float fW     = GetNuiScaleDimension(oPC, 480.0);
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fListH = GetNuiScaleDimension(oPC, 160.0);
    float fLblH  = GetNuiScaleDimension(oPC, 22.0);

    // ---- Input section ----
    json jTagLbl = NuiLabel(JsonString("Tag obszaru:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTagLbl = NuiWidth(jTagLbl, GetNuiScaleDimension(oPC, 100.0));

    json jTagField = NuiTextEdit(JsonString(""), NuiBind(MIA_BIND_DM_AREA), 32, FALSE);
    jTagField = NuiHeight(jTagField, fBtnH);

    json jCurAreaBtn = NuiButton(JsonString("Tu"));
    jCurAreaBtn = NuiId(jCurAreaBtn, MIA_BTN_DM_CURAREA);
    jCurAreaBtn = NuiWidth(jCurAreaBtn, GetNuiScaleDimension(oPC, 36.0));
    jCurAreaBtn = NuiHeight(jCurAreaBtn, fBtnH);
    jCurAreaBtn = NuiTooltip(jCurAreaBtn, JsonString("Wypełnij tagiem bieżącego obszaru."));

    json jTagRow = JsonArray();
    jTagRow = JsonArrayInsert(jTagRow, jTagLbl);
    jTagRow = JsonArrayInsert(jTagRow, jTagField);
    jTagRow = JsonArrayInsert(jTagRow, NuiWidth(NuiSpacer(), 4.0));
    jTagRow = JsonArrayInsert(jTagRow, jCurAreaBtn);

    // Intensity slider (1–10)
    json jIntLbl = NuiLabel(JsonString("Intensywność (1-10):"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jIntLbl = NuiWidth(jIntLbl, GetNuiScaleDimension(oPC, 150.0));

    json jIntSlider = NuiSlider(NuiBind(MIA_BIND_DM_INTENS), JsonInt(1), JsonInt(10), JsonInt(1));
    jIntSlider = NuiHeight(jIntSlider, fBtnH);

    json jIntRow = JsonArray();
    jIntRow = JsonArrayInsert(jIntRow, jIntLbl);
    jIntRow = JsonArrayInsert(jIntRow, jIntSlider);

    // Type dropdown labels (3 options as radio-ish combo)
    json jTypeLbl = NuiLabel(JsonString("Typ:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTypeLbl = NuiWidth(jTypeLbl, GetNuiScaleDimension(oPC, 50.0));

    json jTypeOpts = JsonArray();
    jTypeOpts = JsonArrayInsert(jTypeOpts, JsonString("Nekrotyczny"));
    jTypeOpts = JsonArrayInsert(jTypeOpts, JsonString("Bagnienny"));
    jTypeOpts = JsonArrayInsert(jTypeOpts, JsonString("Demoniczny"));

    json jTypeCombo = NuiCombo(jTypeOpts, NuiBind(MIA_BIND_DM_TYPE));
    jTypeCombo = NuiHeight(jTypeCombo, fBtnH);

    json jTypeRow = JsonArray();
    jTypeRow = JsonArrayInsert(jTypeRow, jTypeLbl);
    jTypeRow = JsonArrayInsert(jTypeRow, jTypeCombo);

    // Set / Clear buttons
    json jSetBtn = NuiButton(JsonString("Ustaw skażenie"));
    jSetBtn = NuiId(jSetBtn, MIA_BTN_DM_SET);
    jSetBtn = NuiEnabled(jSetBtn, NuiBind(MIA_BIND_DM_SETENA));
    jSetBtn = NuiHeight(jSetBtn, fBtnH);

    json jClearBtn = NuiButton(JsonString("Oczyść obszar"));
    jClearBtn = NuiId(jClearBtn, MIA_BTN_DM_CLEAR);
    jClearBtn = NuiEnabled(jClearBtn, NuiBind(MIA_BIND_DM_SETENA));
    jClearBtn = NuiHeight(jClearBtn, fBtnH);

    json jActRow = JsonArray();
    jActRow = JsonArrayInsert(jActRow, jSetBtn);
    jActRow = JsonArrayInsert(jActRow, NuiWidth(NuiSpacer(), 8.0));
    jActRow = JsonArrayInsert(jActRow, jClearBtn);

    // Status message
    json jMsgLbl = NuiLabel(NuiBind(MIA_BIND_DM_MSG),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jMsgLbl = NuiHeight(jMsgLbl, fLblH);

    // ---- Active areas list ----
    json jListHdr = NuiLabel(JsonString("Aktywne strefy skażenia:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jListHdr = NuiHeight(jListHdr, fLblH);

    // List template: area_tag | intensity | type name
    float fTagW  = GetNuiScaleDimension(oPC, 200.0);
    float fIntW  = GetNuiScaleDimension(oPC, 80.0);

    json jRowTag  = NuiLabel(NuiBind(MIA_BIND_DM_ROWAREA),  JsonInt(NUI_HALIGN_LEFT),  JsonInt(NUI_VALIGN_MIDDLE));
    json jRowInt  = NuiLabel(NuiBind(MIA_BIND_DM_ROWINT),   JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jRowInt  = NuiWidth(jRowInt, fIntW);
    json jRowType = NuiLabel(NuiBind(MIA_BIND_DM_ROWTYPE), JsonInt(NUI_HALIGN_LEFT),  JsonInt(NUI_VALIGN_MIDDLE));

    json jCells = JsonArray();
    jCells = JsonArrayInsert(jCells, NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jRowTag)),  fTagW));
    jCells = JsonArrayInsert(jCells, NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jRowInt)),  fIntW));
    jCells = JsonArrayInsert(jCells, NuiCol(JsonArrayInsert(JsonArray(), jRowType)));

    json jCell = NuiGroup(NuiRow(jCells), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, MIA_BTN_DM_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(MIA_BIND_DM_ROWENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(MIA_BIND_DM_ROWCNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // ---- Assemble ----
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTagRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jIntRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jTypeRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jActRow));
    jCol = JsonArrayInsert(jCol, jMsgLbl);
    jCol = JsonArrayInsert(jCol, jListHdr);
    jCol = JsonArrayInsert(jCol, jList);

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 450.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

void MiaCreateDmPanel(object oPC)
{
    if(!GetIsDM(oPC)) return;

    if(NuiFindWindow(oPC, MIA_WIN_DM) != 0)
    {
        MiaFeedDmPanel(oPC, NuiFindWindow(oPC, MIA_WIN_DM));
        return;
    }

    float fW = GetNuiScaleDimension(oPC, 480.0);
    float fH = GetNuiScaleDimension(oPC, 440.0);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;
    json jGeom = NuiRect(fX, fY, fW, fH);

    json jWin = NuiWindow(BuildMiaDmPanelLayout(oPC),
        JsonString("Zarządzanie Oparem [MG]"),
        NuiBind(MIA_BIND_DM_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, MIA_WIN_DM, MIA_EV_SCRIPT);
    NuiSetBind(oPC, nToken, MIA_BIND_DM_GEOM, jGeom);
    NuiSetBindWatch(oPC, nToken, MIA_BIND_DM_AREA,  TRUE);

    MiaFeedDmPanel(oPC, nToken);
}

void MiaFeedDmPanel(object oPC, int nToken)
{
    json jAreas = MiaGetAllAreas();
    int nCount  = JsonGetLength(jAreas);

    json jTags  = JsonArray();
    json jInts  = JsonArray();
    json jTypes = JsonArray();
    json jEncs  = JsonArray();

    string sSelTag = GetLocalString(oPC, MIA_LVAR_DM_SEL);

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow = JsonArrayGet(jAreas, i);
        string sTag = JsonGetString(JsonObjectGet(jRow, "area_tag"));
        int    nInt = JsonGetInt   (JsonObjectGet(jRow, "intensity"));
        int    nTyp = JsonGetInt   (JsonObjectGet(jRow, "mia_type"));

        jTags  = JsonArrayInsert(jTags,  JsonString(sTag));
        jInts  = JsonArrayInsert(jInts,  JsonString("Poz. " + IntToString(nInt)));
        jTypes = JsonArrayInsert(jTypes, JsonString(MiaTypeName(nTyp)));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(sSelTag != "" && sSelTag == sTag));
    }

    NuiSetBind(oPC, nToken, MIA_BIND_DM_ROWAREA, jTags);
    NuiSetBind(oPC, nToken, MIA_BIND_DM_ROWINT,  jInts);
    NuiSetBind(oPC, nToken, MIA_BIND_DM_ROWTYPE, jTypes);
    NuiSetBind(oPC, nToken, MIA_BIND_DM_ROWENC,  jEncs);
    NuiSetBind(oPC, nToken, MIA_BIND_DM_ROWCNT,  JsonInt(nCount));

    // Default input values on fresh open
    NuiSetBind(oPC, nToken, MIA_BIND_DM_INTENS, JsonInt(3));
    NuiSetBind(oPC, nToken, MIA_BIND_DM_TYPE,   JsonInt(0));  // index 0 = Nekrotyczny
    NuiSetBind(oPC, nToken, MIA_BIND_DM_MSG,    JsonString(""));
    NuiSetBind(oPC, nToken, MIA_BIND_DM_SETENA, JsonBool(FALSE));
}

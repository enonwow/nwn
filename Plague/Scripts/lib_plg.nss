#include "lib_plg_def"

void CreatePlgWindow(object oPC);
void CreatePlgTestWindow(object oPC);
void PlgCheckProgression(object oPC);
void PlgApplyPerTick(object oPC);

// ================================================================
// Effect management
// ================================================================

// Removes all previously-applied plague effects by iterating the effect list.
// TagEffect + GetEffectTag are NWN:EE 8193+ functions.
void PlgRemoveEffects(object oPC)
{
    effect eEff  = GetFirstEffect(oPC);
    effect eNext;
    while(GetIsEffectValid(eEff))
    {
        eNext = GetNextEffect(oPC);
        if(GetEffectTag(eEff) == PLG_EFFECT_TAG)
            RemoveEffect(oPC, eEff);
        eEff = eNext;
    }
}

// Builds and applies stat-change effects for the given disease+phase.
// Always call PlgRemoveEffects first to avoid stacking.
void PlgApplyEffects(object oPC, int nDiseaseId, int nPhase)
{
    PlgRemoveEffects(oPC);
    if(nPhase < PLG_PHASE_MILD) return; // incubation: no mechanical effects

    effect eLink;

    if(nDiseaseId == PLG_DIS_BLACK_PLAGUE)
    {
        int nCon = (nPhase == PLG_PHASE_MILD) ? 2 : (nPhase == PLG_PHASE_SEVERE) ? 4 : 6;
        int nStr = (nPhase == PLG_PHASE_MILD) ? 0 : (nPhase == PLG_PHASE_SEVERE) ? 2 : 4;
        eLink = EffectAbilityDecrease(ABILITY_CONSTITUTION, nCon);
        if(nStr > 0)
            eLink = EffectLinkEffects(eLink, EffectAbilityDecrease(ABILITY_STRENGTH, nStr));
    }
    else if(nDiseaseId == PLG_DIS_BLOOD_ROT)
    {
        int nPen = (nPhase == PLG_PHASE_MILD) ? 1 : (nPhase == PLG_PHASE_SEVERE) ? 2 : 3;
        eLink = EffectACDecrease(nPen, AC_DODGE_BONUS);
        eLink = EffectLinkEffects(eLink, EffectSavingThrowDecrease(SAVING_THROW_FORT, nPen));
    }
    else if(nDiseaseId == PLG_DIS_SWAMP_FEVER)
    {
        int nDex = (nPhase == PLG_PHASE_MILD) ? 2 : (nPhase == PLG_PHASE_SEVERE) ? 4 : 6;
        int nWis = (nPhase == PLG_PHASE_MILD) ? 0 : (nPhase == PLG_PHASE_SEVERE) ? 2 : 4;
        eLink = EffectAbilityDecrease(ABILITY_DEXTERITY, nDex);
        if(nWis > 0)
            eLink = EffectLinkEffects(eLink, EffectAbilityDecrease(ABILITY_WISDOM, nWis));
    }
    else if(nDiseaseId == PLG_DIS_NECROTIC)
    {
        int nStr = (nPhase == PLG_PHASE_MILD) ? 1 : (nPhase == PLG_PHASE_SEVERE) ? 3 : 5;
        int nCon = (nPhase == PLG_PHASE_MILD) ? 0 : (nPhase == PLG_PHASE_SEVERE) ? 2 : 4;
        eLink = EffectAbilityDecrease(ABILITY_STRENGTH, nStr);
        if(nCon > 0)
            eLink = EffectLinkEffects(eLink, EffectAbilityDecrease(ABILITY_CONSTITUTION, nCon));
    }
    else if(nDiseaseId == PLG_DIS_LYCANTHROPY)
    {
        int nStr = (nPhase == PLG_PHASE_MILD) ? 2 : (nPhase == PLG_PHASE_SEVERE) ? 4 : 6;
        int nWis = (nPhase == PLG_PHASE_MILD) ? 2 : (nPhase == PLG_PHASE_SEVERE) ? 4 : 6;
        eLink = EffectAbilityIncrease(ABILITY_STRENGTH, nStr);
        eLink = EffectLinkEffects(eLink, EffectAbilityDecrease(ABILITY_WISDOM, nWis));
    }
    else return;

    eLink = TagEffect(eLink, PLG_EFFECT_TAG);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eLink, oPC);
}

// ================================================================
// Disease contraction and cure (high-level, with notifications)
// ================================================================

void PlgContractAndNotify(object oPC, int nDiseaseId)
{
    // Silently replace any existing disease — each PC carries at most one.
    PlgRemoveEffects(oPC);
    int nInterval = PlgPhaseInterval(nDiseaseId, PLG_PHASE_INCUBATION);
    PlgContractDisease(oPC, nDiseaseId, nInterval);
    SetLocalInt(oPC, PLG_LVAR_DISEASE, nDiseaseId);
    SetLocalInt(oPC, PLG_LVAR_PHASE,   PLG_PHASE_INCUBATION);
    SetLocalInt(oPC, PLG_LVAR_TICK,    0);

    string sMsg = "[Zaraza] Pieczęć choroby pulsuje słabo... Coś się we mnie wlało.";
    SendMessageToPC(oPC, sMsg);
    FloatingTextStringOnCreature(sMsg, oPC, FALSE);
}

void PlgCureAndNotify(object oPC)
{
    PlgRemoveEffects(oPC);
    PlgCureDisease(oPC);
    SetLocalInt(oPC, PLG_LVAR_DISEASE, PLG_DIS_NONE);
    SetLocalInt(oPC, PLG_LVAR_PHASE,   PLG_PHASE_NONE);
    SetLocalInt(oPC, PLG_LVAR_TICK,    0);

    string sMsg = "[Zaraza] Ciemność opuszcza twoje ciało. Jesteś wolny od zarazy.";
    SendMessageToPC(oPC, sMsg);
    FloatingTextStringOnCreature(sMsg, oPC, FALSE);

    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
        EffectVisualEffect(VFX_DUR_SPELL_BARKSKIN), oPC, 3.0);
}

// ================================================================
// Progression check (called from heartbeat for each PC)
// ================================================================

void PlgCheckProgression(object oPC)
{
    int nDiseaseId = GetLocalInt(oPC, PLG_LVAR_DISEASE);
    if(nDiseaseId == PLG_DIS_NONE) return;

    int nPhase = GetLocalInt(oPC, PLG_LVAR_PHASE);
    if(nPhase >= PLG_PHASE_CRITICAL) return; // critical does not advance further

    json jState = PlgGetState(oPC);
    if(JsonGetType(jState) == JSON_TYPE_NULL) return;

    int nPhaseEnd = JsonGetInt(JsonObjectGet(jState, "phase_end"));
    if(PlgUnixNow() < nPhaseEnd) return; // not time yet

    int nNewPhase    = nPhase + 1;
    // For critical phase, pass 0 interval so phase_end is stored as 0 (sentinel).
    int nNextInterval = (nNewPhase < PLG_PHASE_CRITICAL)
        ? PlgPhaseInterval(nDiseaseId, nNewPhase) : 0;

    PlgAdvancePhase(oPC, nNewPhase, nPhaseEnd, nNextInterval);
    SetLocalInt(oPC, PLG_LVAR_PHASE, nNewPhase);

    PlgApplyEffects(oPC, nDiseaseId, nNewPhase);

    string sName = PlgDiseaseName(nDiseaseId);
    string sPhase = PlgPhaseName(nNewPhase);
    string sMsg = "[Zaraza] " + sName + " — " + sPhase + ".";
    SendMessageToPC(oPC, sMsg);
    FloatingTextStringOnCreature(sMsg, oPC, FALSE);

    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
        EffectVisualEffect(VFX_COM_BLOOD_CRT_RED), oPC, 2.0);

    // Refresh open window immediately
    int nToken = NuiFindWindow(oPC, PLG_WINDOW);
    if(nToken != 0) FeedPlgWindow(oPC, nToken);
}

// ================================================================
// Per-tick damage for critical phases (called every heartbeat tick)
// Uses a simple counter so damage fires every ~30 s (5 × 6 s heartbeat).
// ================================================================

void PlgApplyPerTick(object oPC)
{
    int nDiseaseId = GetLocalInt(oPC, PLG_LVAR_DISEASE);
    int nPhase     = GetLocalInt(oPC, PLG_LVAR_PHASE);

    if(nDiseaseId == PLG_DIS_NONE || nPhase < PLG_PHASE_CRITICAL) return;

    int nTick = GetLocalInt(oPC, PLG_LVAR_TICK) + 1;
    if(nTick < 5)
    {
        SetLocalInt(oPC, PLG_LVAR_TICK, nTick);
        return;
    }
    SetLocalInt(oPC, PLG_LVAR_TICK, 0);

    if(nDiseaseId == PLG_DIS_BLOOD_ROT)
    {
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectDamage(4, DAMAGE_TYPE_MAGICAL), oPC);
        SendMessageToPC(oPC, "[Zaraza] Krwawa Zgnilizna wysysa twoją siłę życiową...");
    }
    else if(nDiseaseId == PLG_DIS_NECROTIC)
    {
        int nDmg = Random(4) + 1;
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectDamage(nDmg, DAMAGE_TYPE_NEGATIVE), oPC);
        SendMessageToPC(oPC, "[Zaraza] Nekrotyczna rana drenauje twoją żywotność...");
    }
    else if(nDiseaseId == PLG_DIS_LYCANTHROPY)
    {
        // Feral rage: 20 % chance per 30 s — visual only, no forced attack (avoid griefing)
        if(Random(100) < 20)
        {
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectVisualEffect(VFX_DUR_MIND_AFFECTING_NEGATIVE), oPC, 2.0);
            SendMessageToPC(oPC, "[Zaraza] Bestia wewnątrz wyje. Utrzymanie kontroli kosztuje cię wszystko...");
        }
    }
}

// ================================================================
// NUI — main plague status window
// ================================================================

json PlgBuildMainWindow(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fProgH = GetNuiScaleDimension(oPC, 18.0);
    float fBodyH = GetNuiScaleDimension(oPC, 160.0);
    float fRowH  = GetNuiScaleDimension(oPC, 24.0);

    // -- Header: disease name + phase --
    json jNameLbl = NuiLabel(NuiBind(PLG_BIND_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiHeight(jNameLbl, fBtnH);

    json jPhaseLbl = NuiLabel(NuiBind(PLG_BIND_PHASE), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jPhaseLbl = NuiWidth(jPhaseLbl, GetNuiScaleDimension(oPC, 140.0));
    jPhaseLbl = NuiHeight(jPhaseLbl, fBtnH);

    json jHdrRow = JsonArray();
    jHdrRow = JsonArrayInsert(jHdrRow, jNameLbl);
    jHdrRow = JsonArrayInsert(jHdrRow, jPhaseLbl);

    // -- Progress bar (time into current phase) --
    json jProg = NuiProgressBar(NuiBind(PLG_BIND_PROG));
    jProg = NuiHeight(jProg, fProgH);
    jProg = NuiStyleForegroundColor(jProg, NuiBind(PLG_BIND_PROG_COL));

    // -- Timer label --
    json jTimerLbl = NuiLabel(NuiBind(PLG_BIND_TIMER), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTimerLbl = NuiHeight(jTimerLbl, fRowH);

    // -- Separator label --
    json jSepLbl = NuiLabel(JsonString("OBJAWY"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSepLbl = NuiHeight(jSepLbl, fRowH);

    // -- Symptoms --
    json jSympLbl = NuiLabel(NuiBind(PLG_BIND_SYMPTOMS), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSympLbl = NuiHeight(jSympLbl, fRowH);

    // -- Flavor text (scrollable group) --
    json jFlavorSepLbl = NuiLabel(JsonString("OPIS"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jFlavorSepLbl = NuiHeight(jFlavorSepLbl, fRowH);

    json jFlavorTxt = NuiGroup(
        NuiText(NuiBind(PLG_BIND_FLAVOR), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jFlavorTxt = NuiHeight(jFlavorTxt, fBodyH);

    // -- Remedy section --
    json jRemSepLbl = NuiLabel(JsonString("LEKARSTWO"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRemSepLbl = NuiHeight(jRemSepLbl, fRowH);

    json jRemLbl = NuiLabel(NuiBind(PLG_BIND_REMEDY), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRemLbl = NuiHeight(jRemLbl, fRowH);

    // -- Cure button --
    json jCureBtn = NuiButton(JsonString("Użyj lekarstwa"));
    jCureBtn = NuiId(jCureBtn, PLG_BTN_CURE);
    jCureBtn = NuiEnabled(jCureBtn, NuiBind(PLG_BIND_CURE_ENA));
    jCureBtn = NuiHeight(jCureBtn, fBtnH);

    // -- Close button --
    json jCloseBtn = NuiButton(JsonString("Zamknij"));
    jCloseBtn = NuiId(jCloseBtn, PLG_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 80.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jCureBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jCloseBtn);

    // -- Assemble --
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jHdrRow));
    jCol = JsonArrayInsert(jCol, jProg);
    jCol = JsonArrayInsert(jCol, jTimerLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jSepLbl);
    jCol = JsonArrayInsert(jCol, jSympLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jFlavorSepLbl);
    jCol = JsonArrayInsert(jCol, jFlavorTxt);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jRemSepLbl);
    jCol = JsonArrayInsert(jCol, jRemLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, PLG_W - 40.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// Fills all binds based on current SQL state.
void FeedPlgWindow(object oPC, int nToken)
{
    int nDiseaseId = GetLocalInt(oPC, PLG_LVAR_DISEASE);
    int nPhase     = GetLocalInt(oPC, PLG_LVAR_PHASE);

    if(nDiseaseId == PLG_DIS_NONE || nPhase == PLG_PHASE_NONE)
    {
        NuiSetBind(oPC, nToken, PLG_BIND_NAME,     JsonString("Brak zarazy"));
        NuiSetBind(oPC, nToken, PLG_BIND_PHASE,    JsonString("—"));
        NuiSetBind(oPC, nToken, PLG_BIND_FLAVOR,   JsonString("Twoje ciało jest wolne od choroby."));
        NuiSetBind(oPC, nToken, PLG_BIND_SYMPTOMS, JsonString("—"));
        NuiSetBind(oPC, nToken, PLG_BIND_REMEDY,   JsonString("—"));
        NuiSetBind(oPC, nToken, PLG_BIND_CURE_ENA, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, PLG_BIND_PROG,     JsonFloat(0.0));
        NuiSetBind(oPC, nToken, PLG_BIND_PROG_COL, NuiColor(80, 80, 80));
        NuiSetBind(oPC, nToken, PLG_BIND_TIMER,    JsonString(""));
        return;
    }

    // Progress bar and timer
    float fProg = 0.0;
    string sTimer = "";
    json jState = PlgGetState(oPC);

    if(JsonGetType(jState) != JSON_TYPE_NULL)
    {
        int nPhaseStart = JsonGetInt(JsonObjectGet(jState, "phase_start"));
        int nPhaseEnd   = JsonGetInt(JsonObjectGet(jState, "phase_end"));
        int nNow        = PlgUnixNow();

        if(nPhase < PLG_PHASE_CRITICAL && nPhaseEnd > nPhaseStart)
        {
            int nDur     = nPhaseEnd - nPhaseStart;
            int nElapsed = nNow - nPhaseStart;
            if(nElapsed < 0) nElapsed = 0;
            fProg = IntToFloat(nElapsed) / IntToFloat(nDur);
            if(fProg > 1.0) fProg = 1.0;

            int nRemain = nPhaseEnd - nNow;
            if(nRemain < 0) nRemain = 0;
            int nH = nRemain / 3600;
            int nM = (nRemain % 3600) / 60;
            int nS = nRemain % 60;
            string sH = (nH < 10 ? "0" : "") + IntToString(nH);
            string sM = (nM < 10 ? "0" : "") + IntToString(nM);
            string sSec = (nS < 10 ? "0" : "") + IntToString(nS);
            sTimer = "Następna faza za: " + sH + ":" + sM + ":" + sSec;
        }
        else
        {
            // Critical — no next phase
            fProg = 1.0;
            sTimer = "Stan krytyczny — nie ma już kolejnej fazy.";
        }
    }

    // Cure button: enabled only if PC has the remedy item in inventory
    string sRemedyTag = PlgDiseaseRemedyTag(nDiseaseId);
    int bHasRemedy = GetIsObjectValid(GetItemPossessedBy(oPC, sRemedyTag));

    NuiSetBind(oPC, nToken, PLG_BIND_NAME,     JsonString(PlgDiseaseName(nDiseaseId)));
    NuiSetBind(oPC, nToken, PLG_BIND_PHASE,    JsonString(PlgPhaseName(nPhase)));
    NuiSetBind(oPC, nToken, PLG_BIND_FLAVOR,   JsonString(PlgPhaseFlavor(nDiseaseId, nPhase)));
    NuiSetBind(oPC, nToken, PLG_BIND_SYMPTOMS, JsonString(PlgPhaseSymptoms(nDiseaseId, nPhase)));
    NuiSetBind(oPC, nToken, PLG_BIND_REMEDY,   JsonString(PlgDiseaseRemedyName(nDiseaseId)));
    NuiSetBind(oPC, nToken, PLG_BIND_CURE_ENA, JsonBool(bHasRemedy));
    NuiSetBind(oPC, nToken, PLG_BIND_PROG,     JsonFloat(fProg));
    NuiSetBind(oPC, nToken, PLG_BIND_PROG_COL, PlgDiseaseColor(nDiseaseId));
    NuiSetBind(oPC, nToken, PLG_BIND_TIMER,    JsonString(sTimer));
}

void CreatePlgWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, PLG_WINDOW);
    if(nToken != 0)
    {
        FeedPlgWindow(oPC, nToken);
        return;
    }

    float fGuiW = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH));
    float fGuiH = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT));
    float fWinW = GetNuiScaleDimension(oPC, PLG_W);
    float fWinH = GetNuiScaleDimension(oPC, PLG_H);
    float fCX   = (fGuiW - fWinW) / 2.0;
    float fCY   = (fGuiH - fWinH) / 2.0;
    json jGeom  = NuiRect(fCX, fCY, fWinW, fWinH);

    json jWin = NuiWindow(
        PlgBuildMainWindow(oPC),
        JsonString("Schorzenie Postaci"),
        NuiBind(PLG_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, PLG_WINDOW, PLG_EV_SCRIPT);
    NuiSetBind(oPC, nToken, PLG_WIN_GEOM, jGeom);
    FeedPlgWindow(oPC, nToken);
}

// ================================================================
// NUI — test/debug window (placeable OnUsed)
// ================================================================

json PlgBuildTestWindow(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fRowH = GetNuiScaleDimension(oPC, 26.0);
    float fListH = GetNuiScaleDimension(oPC, 150.0);

    json jTitle = NuiLabel(JsonString("Zaraź się chorobą (debug):"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);

    // Disease list
    json jDisLbl  = NuiLabel(NuiBind(PLG_BIND_TEST_DIS), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jDisCell = NuiGroup(NuiRow(JsonArrayInsert(JsonArray(), jDisLbl)), TRUE, NUI_SCROLLBARS_NONE);
    jDisCell = NuiId(jDisCell, PLG_BTN_TEST_ROW);

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jDisCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(PLG_BIND_TEST_LEN), fRowH);
    jList = NuiHeight(jList, fListH);

    json jOpenBtn = NuiButton(JsonString("Sprawdź stan zdrowia"));
    jOpenBtn = NuiId(jOpenBtn, PLG_BTN_TEST_OPEN);
    jOpenBtn = NuiHeight(jOpenBtn, fBtnH);

    json jCureBtn = NuiButton(JsonString("Natychmiastowe uzdrowienie (debug)"));
    jCureBtn = NuiId(jCureBtn, PLG_BTN_TEST_CURE);
    jCureBtn = NuiHeight(jCureBtn, fBtnH);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jTitle);
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jOpenBtn);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jCureBtn);

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, PLG_TEST_W - 30.0);
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSide);
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiCol(jCol), fContentW));
    jRow = JsonArrayInsert(jRow, jSide);
    return NuiRow(jRow);
}

void FeedPlgTestWindow(object oPC, int nToken)
{
    json jNames = JsonArray();
    int i;
    for(i = 0; i < PLG_DIS_COUNT; i++)
        jNames = JsonArrayInsert(jNames, JsonString(PlgDiseaseName(i)));
    NuiSetBind(oPC, nToken, PLG_BIND_TEST_DIS, jNames);
    NuiSetBind(oPC, nToken, PLG_BIND_TEST_LEN, JsonInt(PLG_DIS_COUNT));
}

void CreatePlgTestWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, PLG_WIN_TEST);
    if(nToken != 0)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    float fGuiW = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH));
    float fGuiH = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT));
    float fWinW = GetNuiScaleDimension(oPC, PLG_TEST_W);
    float fWinH = GetNuiScaleDimension(oPC, PLG_TEST_H);
    json jGeom  = NuiRect((fGuiW - fWinW) / 2.0, (fGuiH - fWinH) / 2.0, fWinW, fWinH);

    json jWin = NuiWindow(
        PlgBuildTestWindow(oPC),
        JsonString("[Debug] Zwierciadło Diagnostyczne"),
        NuiBind(PLG_TEST_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, PLG_WIN_TEST, PLG_EV_SCRIPT);
    NuiSetBind(oPC, nToken, PLG_TEST_GEOM, jGeom);
    FeedPlgTestWindow(oPC, nToken);
}

// ================================================================
// OnClientEnter helper — reapplies effects after server restart
// ================================================================

void PlgOnClientEnter(object oPC)
{
    json jState = PlgGetState(oPC);
    if(JsonGetType(jState) == JSON_TYPE_NULL)
    {
        SetLocalInt(oPC, PLG_LVAR_DISEASE, PLG_DIS_NONE);
        SetLocalInt(oPC, PLG_LVAR_PHASE,   PLG_PHASE_NONE);
        return;
    }

    int nDiseaseId = JsonGetInt(JsonObjectGet(jState, "disease_id"));
    int nPhase     = JsonGetInt(JsonObjectGet(jState, "phase"));

    SetLocalInt(oPC, PLG_LVAR_DISEASE, nDiseaseId);
    SetLocalInt(oPC, PLG_LVAR_PHASE,   nPhase);
    SetLocalInt(oPC, PLG_LVAR_TICK,    0);

    PlgApplyEffects(oPC, nDiseaseId, nPhase);

    if(nDiseaseId != PLG_DIS_NONE && nPhase != PLG_PHASE_NONE)
    {
        string sMsg = "[Zaraza] " + PlgDiseaseName(nDiseaseId) + " — "
            + PlgPhaseName(nPhase) + ". Odwiedź zwierciadło diagnostyczne.";
        DelayCommand(5.0, SendMessageToPC(oPC, sMsg));
    }

    // Advance any overdue phases immediately
    DelayCommand(1.0, PlgCheckProgression(oPC));
}

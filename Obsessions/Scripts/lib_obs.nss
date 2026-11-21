#include "lib_obs_def"

// -----------------------------------------------------------------
// Effect management
// -----------------------------------------------------------------

void ObsRemoveOldBonuses(object oPC)
{
    // All bonus effects are applied as SUPERNATURAL from GetModule();
    // iterate and remove those whose creator is the module object.
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        effect eNext = GetNextEffect(oPC);
        if(GetEffectCreator(eEff) == GetModule() &&
           GetEffectDurationType(eEff) == DURATION_TYPE_TEMPORARY)
            RemoveEffect(oPC, eEff);
        eEff = eNext;
    }
}

// Duration chosen slightly longer than the check interval so effects
// never lapse between heartbeat checks.
const float OBS_EFFECT_DURATION = 120.0;

void ObsApplyBonusEffect(object oPC, string sCat, int nTier)
{
    if(sCat == OBS_CAT_UNDEAD)
    {
        effect e = EffectAttackIncrease(nTier, ATTACK_BONUS_ONHAND);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, SupernaturalEffect(e), oPC, OBS_EFFECT_DURATION);
    }
    else if(sCat == OBS_CAT_BLOOD)
    {
        // Only active when bloodied (< 50% HP)
        if(GetCurrentHitPoints(oPC) * 2 >= GetMaxHitPoints(oPC)) return;
        effect e = EffectAttackIncrease(nTier, ATTACK_BONUS_ONHAND);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, SupernaturalEffect(e), oPC, OBS_EFFECT_DURATION);
    }
    else if(sCat == OBS_CAT_THEFT)
    {
        effect e = EffectLinkEffects(
            EffectSkillIncrease(SKILL_OPEN_LOCK, nTier),
            EffectSkillIncrease(SKILL_PICK_POCKET, nTier));
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, SupernaturalEffect(e), oPC, OBS_EFFECT_DURATION);
    }
    else if(sCat == OBS_CAT_DRINK)
    {
        effect e = EffectLinkEffects(
            EffectSavingThrowIncrease(SAVING_THROW_WILL, nTier, SAVING_THROW_TYPE_FEAR),
            EffectTemporaryHitpoints(nTier * 5));
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, SupernaturalEffect(e), oPC, OBS_EFFECT_DURATION);
    }
    else if(sCat == OBS_CAT_ARCANE)
    {
        effect e = EffectSkillIncrease(SKILL_CONCENTRATION, nTier);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, SupernaturalEffect(e), oPC, OBS_EFFECT_DURATION);
    }
    else if(sCat == OBS_CAT_PAIN)
    {
        // Physical damage resistance across all three types
        effect e = EffectLinkEffects(
            EffectLinkEffects(
                EffectDamageResistance(DAMAGE_TYPE_BLUDGEONING, nTier * 2, 0),
                EffectDamageResistance(DAMAGE_TYPE_PIERCING,    nTier * 2, 0)),
            EffectDamageResistance(DAMAGE_TYPE_SLASHING,    nTier * 2, 0));
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, SupernaturalEffect(e), oPC, OBS_EFFECT_DURATION);
    }
    else if(sCat == OBS_CAT_SHADOW)
    {
        effect e = EffectLinkEffects(
            EffectSkillIncrease(SKILL_HIDE,          nTier),
            EffectSkillIncrease(SKILL_MOVE_SILENTLY, nTier));
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, SupernaturalEffect(e), oPC, OBS_EFFECT_DURATION);
    }
    else if(sCat == OBS_CAT_GOLD)
    {
        effect e = EffectSkillIncrease(SKILL_APPRAISE, nTier * 2);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, SupernaturalEffect(e), oPC, OBS_EFFECT_DURATION);
    }
    else if(sCat == OBS_CAT_BATTLE)
    {
        effect e = EffectAttackIncrease(nTier, ATTACK_BONUS_MISC);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, SupernaturalEffect(e), oPC, OBS_EFFECT_DURATION);
    }
    else if(sCat == OBS_CAT_DARKNESS)
    {
        effect eBase = EffectSavingThrowIncrease(SAVING_THROW_WILL, nTier, SAVING_THROW_TYPE_NONE);
        if(nTier >= 2)
            eBase = EffectLinkEffects(EffectUltravision(), eBase);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, SupernaturalEffect(eBase), oPC, OBS_EFFECT_DURATION);
    }
}

void ObsApplyBonuses(object oPC)
{
    ObsRemoveOldBonuses(oPC);
    int nIdx;
    for(nIdx = 0; nIdx < OBS_NUM_CATEGORIES; nIdx++)
    {
        string sCat = ObsGetCategoryAtIndex(nIdx);
        int nPoints = ObsGetPoints(oPC, sCat);
        int nTier   = ObsGetTier(nPoints);
        if(nTier <= 0) continue;
        if(ObsIsSuppressed(oPC, sCat)) continue;

        ObsApplyBonusEffect(oPC, sCat, nTier);

        if(nTier >= OBS_TIER_MADNESS)
        {
            effect eMad = EffectLinkEffects(
                EffectAbilityDecrease(ABILITY_WISDOM, 1),
                EffectSavingThrowDecrease(SAVING_THROW_ALL, 2, SAVING_THROW_TYPE_SPELL));
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, SupernaturalEffect(eMad), oPC, OBS_EFFECT_DURATION);
        }
    }
}

// -----------------------------------------------------------------
// Compulsion effects
// -----------------------------------------------------------------

void ObsFireCompulsion(object oPC, string sCat, int nTier)
{
    ObsIncrementTrigger(oPC, sCat);

    if(sCat == OBS_CAT_BLOOD || sCat == OBS_CAT_PAIN)
    {
        int nDmg = d4();
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectDamage(nDmg, DAMAGE_TYPE_MAGICAL), oPC);
        string sMsg;
        if(sCat == OBS_CAT_BLOOD)
        {
            sMsg = "[Obsesja — Krew] Drapiesz skórę paznokciami. Tracisz " + IntToString(nDmg) + " PŻ.";
            FloatingTextStringOnCreature("Pragnienie krwi...", oPC, FALSE);
        }
        else
        {
            sMsg = "[Obsesja — Ból] Ciało domaga się bólu. Tracisz " + IntToString(nDmg) + " PŻ.";
            FloatingTextStringOnCreature("Ból... oczyszcza...", oPC, FALSE);
        }
        SendMessageToPC(oPC, sMsg);
    }
    else if(sCat == OBS_CAT_DRINK)
    {
        effect ePen = EffectAttackDecrease(1, ATTACK_BONUS_ONHAND);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, ePen, oPC, 60.0);
        SendMessageToPC(oPC, "[Obsesja — Pijaństwo] Gardło płonie suchością. -1 do ataków przez chwilę.");
        FloatingTextStringOnCreature("Gdzie... trunek...", oPC, FALSE);
    }
    else if(sCat == OBS_CAT_ARCANE)
    {
        int nDmg = d4();
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectDamage(nDmg, DAMAGE_TYPE_ELECTRICAL), oPC);
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectVisualEffect(VFX_IMP_LIGHTNING_S), oPC);
        SendMessageToPC(oPC, "[Obsesja — Magia] Ładunek wyładowuje się niekontrolowanie. Tracisz " + IntToString(nDmg) + " PŻ.");
        FloatingTextStringOnCreature("Moc... przepełnia...", oPC, FALSE);
    }
    else if(sCat == OBS_CAT_SHADOW)
    {
        effect eCon = EffectConcealment(20, MISS_CHANCE_TYPE_NORMAL);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eCon, oPC, 10.0);
        SendMessageToPC(oPC, "[Obsesja — Cień] Instynkt każe ci wtopić się w mrok. 20% ukrycia przez chwilę.");
        FloatingTextStringOnCreature("Cień mnie powołuje...", oPC, FALSE);
    }
    else if(sCat == OBS_CAT_GOLD)
    {
        effect ePen = EffectSkillDecrease(SKILL_CONCENTRATION, 2);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, ePen, oPC, 15.0);
        SendMessageToPC(oPC, "[Obsesja — Złoto] Liczysz w myślach swe monety. -2 do Koncentracji przez chwilę.");
        FloatingTextStringOnCreature("Dwa, pięć, siedem...", oPC, FALSE);
    }
    else if(sCat == OBS_CAT_THEFT)
    {
        effect eBoost = EffectAbilityIncrease(ABILITY_DEXTERITY, 2);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eBoost, oPC, 20.0);
        SendMessageToPC(oPC, "[Obsesja — Złodziejstwo] Palce drżą z pragnienia. +2 do Zręczności przez chwilę.");
        FloatingTextStringOnCreature("Palce... drżą...", oPC, FALSE);
    }
    else if(sCat == OBS_CAT_UNDEAD || sCat == OBS_CAT_BATTLE)
    {
        effect eFury = EffectAttackIncrease(2, ATTACK_BONUS_ONHAND);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eFury, oPC, 30.0);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
            EffectVisualEffect(VFX_DUR_SPELLTURNING), oPC, 3.0);
        if(sCat == OBS_CAT_UNDEAD)
        {
            SendMessageToPC(oPC, "[Obsesja — Nieumarli] Pragnienie walki z nieumarłymi przemaga rozum. +2 do ataków.");
            FloatingTextStringOnCreature("Muszę zniszczyć nieumarłych!", oPC, FALSE);
        }
        else
        {
            SendMessageToPC(oPC, "[Obsesja — Bitwa] Żądza walki przemaga rozsądek. +2 do ataków przez chwilę.");
            FloatingTextStringOnCreature("Krew! Bitwa!", oPC, FALSE);
        }
    }
    else if(sCat == OBS_CAT_DARKNESS)
    {
        effect eUV = EffectUltravision();
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eUV, oPC, 30.0);
        SendMessageToPC(oPC, "[Obsesja — Mrok] Oczy przyzwyczajają się do ciemności. Tymczasowe widzenie w nocy.");
        FloatingTextStringOnCreature("Mrok jest... domem...", oPC, FALSE);
    }
}

void ObsCheckCompulsions(object oPC)
{
    int nIdx;
    for(nIdx = 0; nIdx < OBS_NUM_CATEGORIES; nIdx++)
    {
        string sCat = ObsGetCategoryAtIndex(nIdx);
        int nPoints = ObsGetPoints(oPC, sCat);
        int nTier   = ObsGetTier(nPoints);
        if(nTier <= 0) continue;
        if(ObsIsSuppressed(oPC, sCat)) continue;

        // Probability scales with tier: 15/30/50/75 %
        int nChance = nTier * 15 + (nTier > 2 ? 10 : 0);
        if(Random(100) >= nChance) continue;

        int nDC = 8 + nTier * 4;
        // Will save using the game's native save resolver (shows in combat log)
        int bResisted = WillSave(oPC, nDC, SAVING_THROW_TYPE_MIND_SPELLS, OBJECT_INVALID);
        if(bResisted) continue;

        ObsFireCompulsion(oPC, sCat, nTier);
    }
}

// -----------------------------------------------------------------
// NUI layout builders
// -----------------------------------------------------------------

json ObsBuildListPanel(object oPC)
{
    float fRowH  = GetNuiScaleDimension(oPC, 36.0);
    float fTierW = GetNuiScaleDimension(oPC, 70.0);

    json jNameLbl = NuiLabel(NuiBind(OBS_BIND_ROW_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(OBS_BIND_ROW_COLOR));

    json jTierLbl = NuiLabel(NuiBind(OBS_BIND_ROW_TIER), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jTierLbl = NuiWidth(jTierLbl, fTierW);
    jTierLbl = NuiStyleForegroundColor(jTierLbl, NuiBind(OBS_BIND_ROW_COLOR));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, jNameLbl);
    jCellRow = JsonArrayInsert(jCellRow, jTierLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, OBS_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(OBS_BIND_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));

    float fListH = GetNuiScaleDimension(oPC, OBS_WIN_H - 50.0);
    json jList = NuiList(jTmpl, NuiBind(OBS_BIND_LIST_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    json jPanel = JsonArrayInsert(JsonArray(), jList);
    return NuiWidth(NuiCol(jPanel), GetNuiScaleDimension(oPC, OBS_LIST_W));
}

json ObsBuildDetailsPanel(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 32.0);
    float fTextH = GetNuiScaleDimension(oPC, 22.0);
    float fDescH = GetNuiScaleDimension(oPC, 85.0);
    float fProgH = GetNuiScaleDimension(oPC, 16.0);

    json jHeader = NuiLabel(NuiBind(OBS_BIND_DET_HEADER), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHeader = NuiHeight(jHeader, GetNuiScaleDimension(oPC, 36.0));
    jHeader = NuiStyleForegroundColor(jHeader, NuiBind(OBS_BIND_DET_TIER_COLOR));

    json jTierLbl = NuiLabel(NuiBind(OBS_BIND_DET_TIER), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTierLbl = NuiHeight(jTierLbl, fTextH);
    jTierLbl = NuiStyleForegroundColor(jTierLbl, NuiBind(OBS_BIND_DET_TIER_COLOR));

    json jProgress = NuiProgress(NuiBind(OBS_BIND_DET_PROGRESS));
    jProgress = NuiHeight(jProgress, fProgH);

    json jPtsLbl = NuiLabel(NuiBind(OBS_BIND_DET_PTS_LBL), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jPtsLbl = NuiHeight(jPtsLbl, fTextH);

    json jSep = NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, 6.0));

    json jBonusLbl = NuiLabel(NuiBind(OBS_BIND_DET_BONUS), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jBonusLbl = NuiHeight(jBonusLbl, fDescH);

    json jCompLbl = NuiLabel(NuiBind(OBS_BIND_DET_COMPULSION), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jCompLbl = NuiHeight(jCompLbl, fDescH);

    json jSuppBtn = NuiButton(NuiBind(OBS_BIND_DET_SUPP_LBL));
    jSuppBtn = NuiId(jSuppBtn, OBS_BTN_SUPPRESS);
    jSuppBtn = NuiEnabled(jSuppBtn, NuiBind(OBS_BIND_DET_SUPP_ENA));
    jSuppBtn = NuiHeight(jSuppBtn, fBtnH);

    json jCloseBtn = NuiButton(JsonString("Zamknij"));
    jCloseBtn = NuiId(jCloseBtn, OBS_BTN_CLOSE);
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 100.0));

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jSuppBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jCloseBtn);

    json jPanel = JsonArray();
    jPanel = JsonArrayInsert(jPanel, jHeader);
    jPanel = JsonArrayInsert(jPanel, jTierLbl);
    jPanel = JsonArrayInsert(jPanel, jProgress);
    jPanel = JsonArrayInsert(jPanel, jPtsLbl);
    jPanel = JsonArrayInsert(jPanel, jSep);
    jPanel = JsonArrayInsert(jPanel, jBonusLbl);
    jPanel = JsonArrayInsert(jPanel, jCompLbl);
    jPanel = JsonArrayInsert(jPanel, NuiSpacer());
    jPanel = JsonArrayInsert(jPanel, NuiRow(jBotRow));

    return NuiCol(jPanel);
}

// -----------------------------------------------------------------
// Window management
// -----------------------------------------------------------------

void ObsOpenUI(object oPC)
{
    int nToken = NuiFindWindow(oPC, OBS_WINDOW);
    if(nToken != 0)
    {
        NuiFocus(oPC, nToken);
        return;
    }

    json jListPanel = ObsBuildListPanel(oPC);
    json jDetPanel  = ObsBuildDetailsPanel(oPC);

    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jListPanel);
    jMainRow = JsonArrayInsert(jMainRow, jDetPanel);

    json jRoot = NuiCol(JsonArrayInsert(JsonArray(), NuiRow(jMainRow)));

    float fW = GetNuiScaleDimension(oPC, OBS_WIN_W);
    float fH = GetNuiScaleDimension(oPC, OBS_WIN_H);

    json jWin = NuiWindow(jRoot, JsonString("Kronika Obsesji"),
        NuiRect(-1.0, -1.0, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    nToken = NuiCreate(oPC, jWin, OBS_WINDOW, OBS_EV_SCRIPT);
    if(nToken == 0) return;

    SetLocalInt(oPC, OBS_LVAR_SEL_IDX, 0);
    ObsFeedUI(oPC, nToken);
}

void ObsFeedDetails(object oPC, int nToken, int nIdx)
{
    string sCat = ObsGetCategoryAtIndex(nIdx);
    int nPoints = ObsGetPoints(oPC, sCat);
    int nTier   = ObsGetTier(nPoints);

    NuiSetBind(oPC, nToken, OBS_BIND_DET_HEADER,    JsonString(ObsCategoryLabel(sCat)));
    NuiSetBind(oPC, nToken, OBS_BIND_DET_TIER,      JsonString(ObsTierLabel(nTier)));
    NuiSetBind(oPC, nToken, OBS_BIND_DET_TIER_COLOR, ObsTierColor(nTier));

    float fProg = IntToFloat(nPoints) / IntToFloat(OBS_MAX_POINTS);
    NuiSetBind(oPC, nToken, OBS_BIND_DET_PROGRESS, JsonFloat(fProg));
    NuiSetBind(oPC, nToken, OBS_BIND_DET_PTS_LBL,  JsonString(IntToString(nPoints) + " / 125 pkt."));

    NuiSetBind(oPC, nToken, OBS_BIND_DET_BONUS,
        JsonString("Premia: " + ObsCategoryBonusDesc(sCat, nTier)));
    NuiSetBind(oPC, nToken, OBS_BIND_DET_COMPULSION,
        JsonString("Przymus: " + ObsCategoryCompulsionDesc(sCat, nTier)));

    int bSuppressed = ObsIsSuppressed(oPC, sCat);
    int bCanSuppress = (nTier >= OBS_TIER_FIXATION) && !bSuppressed;
    NuiSetBind(oPC, nToken, OBS_BIND_DET_SUPP_ENA, JsonBool(bCanSuppress));

    string sSuppLbl;
    if(bCanSuppress)
        sSuppLbl = "Stumień (" + IntToString(OBS_SUPPRESS_COST) + " zł)";
    else if(bSuppressed)
        sSuppLbl = "Stumiona (aktywna)";
    else
        sSuppLbl = "Brak obsesji";
    NuiSetBind(oPC, nToken, OBS_BIND_DET_SUPP_LBL, JsonString(sSuppLbl));

    SetLocalInt(oPC, OBS_LVAR_SEL_IDX, nIdx);

    // Update encouraged (selected) rows
    json jEnc = JsonArray();
    int i;
    for(i = 0; i < OBS_NUM_CATEGORIES; i++)
        jEnc = JsonArrayInsert(jEnc, JsonBool(i == nIdx));
    NuiSetBind(oPC, nToken, OBS_BIND_ROW_ENC, jEnc);
}

void ObsFeedUI(object oPC, int nToken)
{
    json jAll = ObsGetAllJson(oPC);

    json jNames  = JsonArray();
    json jTiers  = JsonArray();
    json jColors = JsonArray();
    json jEncs   = JsonArray();

    int nSelIdx = GetLocalInt(oPC, OBS_LVAR_SEL_IDX);
    int nIdx;
    for(nIdx = 0; nIdx < OBS_NUM_CATEGORIES; nIdx++)
    {
        string sCat = ObsGetCategoryAtIndex(nIdx);
        int nPoints = 0;
        json jEntry = JsonObjectGet(jAll, sCat);
        if(JsonGetType(jEntry) != JSON_TYPE_NULL)
            nPoints = JsonGetInt(JsonObjectGet(jEntry, "points"));

        int nTier = ObsGetTier(nPoints);

        jNames  = JsonArrayInsert(jNames,  JsonString(ObsCategoryLabel(sCat)));
        jTiers  = JsonArrayInsert(jTiers,  JsonString(ObsTierLabel(nTier)));
        jColors = JsonArrayInsert(jColors, ObsTierColor(nTier));
        jEncs   = JsonArrayInsert(jEncs,   JsonBool(nIdx == nSelIdx));
    }

    NuiSetBind(oPC, nToken, OBS_BIND_LIST_COUNT, JsonInt(OBS_NUM_CATEGORIES));
    NuiSetBind(oPC, nToken, OBS_BIND_ROW_NAME,   jNames);
    NuiSetBind(oPC, nToken, OBS_BIND_ROW_TIER,   jTiers);
    NuiSetBind(oPC, nToken, OBS_BIND_ROW_COLOR,  jColors);
    NuiSetBind(oPC, nToken, OBS_BIND_ROW_ENC,    jEncs);

    ObsFeedDetails(oPC, nToken, nSelIdx);
}

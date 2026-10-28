#include "lib_cvoid_def"

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------

string CvoidFormatCd(int nSecs)
{
    if(nSecs <= 0) return "Gotowa";
    if(nSecs < 60)  return IntToString(nSecs) + " s";
    return IntToString(nSecs / 60) + " min";
}

int CvoidCanAfford(object oPC, int nSel)
{
    int nHpCost  = CvoidGetCostHpPct(nSel);
    int nGoldCost = CvoidGetCostGold(nSel);

    if(nHpCost > 0)
    {
        int nHpMax     = GetMaxHitPoints(oPC);
        int nHpNeeded  = (nHpMax * nHpCost) / 100;
        if(GetCurrentHitPoints(oPC) <= nHpNeeded) return FALSE;
    }
    if(nGoldCost > 0 && GetGold(oPC) < nGoldCost) return FALSE;
    return TRUE;
}

int CvoidCanPerform(object oPC, int nSel)
{
    if(!CvoidCanAfford(oPC, nSel))             return FALSE;
    if(CvoidGetCdRemaining(oPC, nSel) > 0)     return FALSE;
    int nTaint   = CvoidGetTaint(oPC);
    int nMinTaint = CvoidGetMinTaint(nSel);
    if(nTaint < nMinTaint)                     return FALSE;
    return TRUE;
}

// ----------------------------------------------------------------
// Taint persistent effects (reapplied on enter and after change)
// ----------------------------------------------------------------

void CvoidApplyTaintEffects(object oPC, int nTaint)
{
    RemoveTaggedEffects(oPC, CVOID_EFFECT_TAG);
    if(nTaint <= 0) return;

    effect e;
    if(nTaint >= CVOID_TAINT_CONSUMED)
    {
        // Full consumption: powerful but damned
        e = TagEffect(EffectAttackIncrease(10), CVOID_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
        e = TagEffect(EffectDamageIncrease(5, DAMAGE_TYPE_MAGICAL), CVOID_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
        e = TagEffect(EffectSavingThrowDecrease(SAVING_THROW_ALL, 6), CVOID_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
        e = TagEffect(EffectAbilityDecrease(ABILITY_CHARISMA, 4), CVOID_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
        e = TagEffect(EffectVisualEffect(VFX_DUR_DARKNESS_20M), CVOID_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
        return;
    }
    if(nTaint >= CVOID_TAINT_SEVERE)
    {
        e = TagEffect(EffectSavingThrowDecrease(SAVING_THROW_ALL, 4), CVOID_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
        e = TagEffect(EffectAbilityDecrease(ABILITY_CHARISMA, 2), CVOID_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
        e = TagEffect(EffectVisualEffect(VFX_DUR_DARKNESS_20M), CVOID_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
        return;
    }
    if(nTaint >= CVOID_TAINT_MODERATE)
    {
        e = TagEffect(EffectSavingThrowDecrease(SAVING_THROW_ALL, 2), CVOID_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
        e = TagEffect(EffectAbilityDecrease(ABILITY_CHARISMA, 2), CVOID_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
        return;
    }
    // Minor (25-49): -1 will save only
    e = TagEffect(EffectSavingThrowDecrease(SAVING_THROW_WILL, 1), CVOID_EFFECT_TAG);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
}

// ----------------------------------------------------------------
// Canticle execution
// ----------------------------------------------------------------

void CvoidApplyCanticleEffect(object oPC, int nSel, int nDurSecs)
{
    float fDur   = IntToFloat(nDurSecs);

    switch(nSel)
    {
        case 0: // Litania Krwi — AB + dmg
        {
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectAttackIncrease(2), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectDamageIncrease(3, DAMAGE_TYPE_MAGICAL), oPC, fDur);
            break;
        }
        case 1: // Psalm Nocy — Hide + Move Silently
        {
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectSkillIncrease(SKILL_HIDE, 4), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectSkillIncrease(SKILL_MOVE_SILENTLY, 4), oPC, fDur);
            break;
        }
        case 2: // Wezwanie Cienia — Sanctuary
        {
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectSanctuary(14), oPC, fDur);
            break;
        }
        case 3: // Hymn Zatracenia — Haste
        {
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectHaste(), oPC, fDur);
            break;
        }
        case 4: // Modlitwa Glodu — Temp HP
        {
            int nTempHP = GetMaxHitPoints(oPC) / 2;
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectTemporaryHitpoints(nTempHP), oPC, fDur);
            break;
        }
        case 5: // Spiew Grozy — AB + dmg combo + saves
        {
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectAttackIncrease(4), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectDamageIncrease(2, DAMAGE_TYPE_MAGICAL), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectSavingThrowIncrease(SAVING_THROW_ALL, 2), oPC, fDur);
            break;
        }
        case 6: // Inwokacja Pustki — SR
        {
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectSpellResistanceIncrease(20), oPC, fDur);
            break;
        }
        case 7: // Ostatnia Litania — all effects combined
        {
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectAttackIncrease(2), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectDamageIncrease(3, DAMAGE_TYPE_MAGICAL), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectSkillIncrease(SKILL_HIDE, 4), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectSkillIncrease(SKILL_MOVE_SILENTLY, 4), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectHaste(), oPC, fDur);
            int nTempHP = GetMaxHitPoints(oPC) / 2;
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectTemporaryHitpoints(nTempHP), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectAttackIncrease(4), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectDamageIncrease(2, DAMAGE_TYPE_MAGICAL), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectSavingThrowIncrease(SAVING_THROW_ALL, 2), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectSpellResistanceIncrease(20), oPC, fDur);
            break;
        }
    }
}

void CvoidPerform(object oPC, int nToken, int nSel)
{
    if(nSel < 0 || nSel >= CVOID_COUNT) return;

    if(!CvoidCanAfford(oPC, nSel))
    {
        SendMessageToPC(oPC, "[Kantylen] Niewystarczające zasoby do odprawienia tej kantylen.");
        return;
    }
    if(CvoidGetCdRemaining(oPC, nSel) > 0)
    {
        SendMessageToPC(oPC, "[Kantylen] Ta kantylen jest jeszcze na czas wyczekiwania.");
        return;
    }
    int nTaint = CvoidGetTaint(oPC);
    int nMinTaint = CvoidGetMinTaint(nSel);
    if(nTaint < nMinTaint)
    {
        SendMessageToPC(oPC, "[Kantylen] Twoja zmaza jest zbyt słaba, by przywołać tę moc.");
        return;
    }

    // Deduct costs
    int nHpPct  = CvoidGetCostHpPct(nSel);
    int nGoldCost = CvoidGetCostGold(nSel);
    if(nHpPct > 0)
    {
        int nDmg = (GetMaxHitPoints(oPC) * nHpPct) / 100;
        effect eDmg = EffectDamage(nDmg, DAMAGE_TYPE_MAGICAL, DAMAGE_POWER_PLUS_TWENTY);
        ApplyEffectToObject(DURATION_TYPE_INSTANT, eDmg, oPC);
    }
    if(nGoldCost > 0)
        AssignCommand(oPC, TakeGoldFromCreature(nGoldCost, oPC, TRUE));

    // Apply effect
    int nDurSecs = CvoidGetDurationSecs(nSel);
    CvoidApplyCanticleEffect(oPC, nSel, nDurSecs);

    // Set cooldown and add taint
    CvoidSetCooldown(oPC, nSel, CvoidGetCooldownSecs(nSel));
    int nNewTaint = CvoidAddTaint(oPC, CvoidGetTaintGain(nSel));

    // Reapply persistent taint effects if threshold crossed
    CvoidApplyTaintEffects(oPC, nNewTaint);

    // Flavor feedback
    string sName = CvoidGetName(nSel);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_NEGATIVE_ENERGY), oPC);
    SendMessageToPC(oPC, "[Kantylen] " + sName + " pulsuje w twoich żyłach. Zmaza: " + IntToString(nNewTaint) + "/100.");

    if(nNewTaint >= CVOID_TAINT_CONSUMED)
        SendMessageToPC(oPC, "[Kantylen] Pięćńa pieczęć Pustki pochłania cię niemal całkowicie...");
    else if(nNewTaint >= CVOID_TAINT_SEVERE)
        SendMessageToPC(oPC, "[Kantylen] Mrok jest już częścią ciebie. Czy jest jeszcze droga powrotu?");

    // Refresh UI
    CvoidFeedList(oPC, nToken);
    CvoidFeedTaint(oPC, nToken);
    CvoidFeedDetail(oPC, nToken, nSel);
}

void CvoidPurify(object oPC, int nToken)
{
    int nCdRem = CvoidGetPurifyCdRemaining(oPC);
    if(nCdRem > 0)
    {
        SendMessageToPC(oPC, "[Kantylen] Oczyszczenie jest możliwe dopiero za " + CvoidFormatCd(nCdRem) + ".");
        return;
    }
    if(GetGold(oPC) < CVOID_PURIFY_COST)
    {
        SendMessageToPC(oPC, "[Kantylen] Oczyszczenie wymaga " + IntToString(CVOID_PURIFY_COST) + " sz.");
        return;
    }
    int nTaint = CvoidGetTaint(oPC);
    if(nTaint <= 0)
    {
        SendMessageToPC(oPC, "[Kantylen] Twoja dusza jest już czysta.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(CVOID_PURIFY_COST, oPC, TRUE));
    int nNew = nTaint - CVOID_PURIFY_REDUCE;
    if(nNew < 0) nNew = 0;
    CvoidSetTaint(oPC, nNew);
    CvoidSetPurifyCooldown(oPC, CVOID_PURIFY_CD_SECS);
    CvoidApplyTaintEffects(oPC, nNew);

    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_IMP_HOLY_AID), oPC);
    SendMessageToPC(oPC, "[Kantylen] Bol oczyszczenia przeszywa cię. Zmaza: " + IntToString(nNew) + "/100.");

    CvoidFeedTaint(oPC, nToken);
    CvoidFeedList(oPC, nToken);
    CvoidFeedDetail(oPC, nToken, GetLocalInt(oPC, CVOID_LVAR_SEL));
}

// ----------------------------------------------------------------
// NUI feed functions
// ----------------------------------------------------------------

void CvoidFeedTaint(object oPC, int nToken)
{
    int nTaint = CvoidGetTaint(oPC);
    float fProg = IntToFloat(nTaint) / 100.0;

    NuiSetBind(oPC, nToken, CVOID_BIND_TAINT_PROG,  JsonFloat(fProg));
    NuiSetBind(oPC, nToken, CVOID_BIND_TAINT_LBL,   JsonString("Zmaza: " + IntToString(nTaint) + "/100"));
    NuiSetBind(oPC, nToken, CVOID_BIND_CORR_LBL,    JsonString(CvoidGetCorruptionLabel(nTaint)));
    NuiSetBind(oPC, nToken, CVOID_BIND_CORR_COLOR,  CvoidGetCorruptionColor(nTaint));
}

void CvoidFeedList(object oPC, int nToken)
{
    int    nTaint  = CvoidGetTaint(oPC);
    int    nSel    = GetLocalInt(oPC, CVOID_LVAR_SEL);
    json   jNames  = JsonArray();
    json   jCosts  = JsonArray();
    json   jCds    = JsonArray();
    json   jTaints = JsonArray();
    json   jEncs   = JsonArray();
    json   jColors = JsonArray();
    int    i;

    for(i = 0; i < CVOID_COUNT; i++)
    {
        int    nCd       = CvoidGetCdRemaining(oPC, i);
        int    nMinT     = CvoidGetMinTaint(i);
        int    bReady    = (nCd <= 0 && nTaint >= nMinT && CvoidCanAfford(oPC, i));
        string sCdStr    = CvoidFormatCd(nCd);
        json   jColor    = bReady ? NuiColor(200, 200, 200) : NuiColor(120, 90, 90);
        if(nMinT > 0 && nTaint < nMinT)
            jColor = NuiColor(90, 90, 90); // locked — grayed out

        jNames  = JsonArrayInsert(jNames,  JsonString(CvoidGetName(i)));
        jCosts  = JsonArrayInsert(jCosts,  JsonString(CvoidGetCostShort(i)));
        jCds    = JsonArrayInsert(jCds,    JsonString(sCdStr));
        jTaints = JsonArrayInsert(jTaints, JsonString("+" + IntToString(CvoidGetTaintGain(i))));
        jEncs   = JsonArrayInsert(jEncs,   JsonBool(i == nSel));
        jColors = JsonArrayInsert(jColors, jColor);
    }

    NuiSetBind(oPC, nToken, CVOID_BIND_ROW_NAME,  jNames);
    NuiSetBind(oPC, nToken, CVOID_BIND_ROW_COST,  jCosts);
    NuiSetBind(oPC, nToken, CVOID_BIND_ROW_CD,    jCds);
    NuiSetBind(oPC, nToken, CVOID_BIND_ROW_TAINT, jTaints);
    NuiSetBind(oPC, nToken, CVOID_BIND_ROW_ENC,   jEncs);
    NuiSetBind(oPC, nToken, CVOID_BIND_ROW_COLOR, jColors);
    NuiSetBind(oPC, nToken, CVOID_BIND_ROW_COUNT, JsonInt(CVOID_COUNT));
}

void CvoidFeedDetail(object oPC, int nToken, int nSel)
{
    if(nSel < 0 || nSel >= CVOID_COUNT)
    {
        NuiSetBind(oPC, nToken, CVOID_BIND_DESC_LBL,    JsonString("Wybierz kantylen, aby zobaczyć szczegóły."));
        NuiSetBind(oPC, nToken, CVOID_BIND_DETAIL_COST, JsonString(""));
        NuiSetBind(oPC, nToken, CVOID_BIND_DETAIL_CD,   JsonString(""));
        NuiSetBind(oPC, nToken, CVOID_BIND_PERFORM_ENA, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, CVOID_BIND_PERFORM_LBL, JsonString("Odpraw kantylen"));
        return;
    }

    int    nTaint  = CvoidGetTaint(oPC);
    int    nCd     = CvoidGetCdRemaining(oPC, nSel);
    int    bCan    = CvoidCanPerform(oPC, nSel);

    NuiSetBind(oPC, nToken, CVOID_BIND_DESC_LBL,    JsonString(CvoidGetDesc(nSel)));
    NuiSetBind(oPC, nToken, CVOID_BIND_DETAIL_COST, JsonString("Koszt: " + CvoidGetCostShort(nSel)));
    NuiSetBind(oPC, nToken, CVOID_BIND_DETAIL_CD,   JsonString("Czas wyczekiwania: " + CvoidFormatCd(nCd)));
    NuiSetBind(oPC, nToken, CVOID_BIND_PERFORM_ENA, JsonBool(bCan));
    NuiSetBind(oPC, nToken, CVOID_BIND_PERFORM_LBL, JsonString("Odpraw: " + CvoidGetName(nSel)));

    // Purify button state
    int nPurifyCd = CvoidGetPurifyCdRemaining(oPC);
    int bCanPurify = (nPurifyCd <= 0 && GetGold(oPC) >= CVOID_PURIFY_COST && nTaint > 0);
    string sPurLbl = nPurifyCd > 0
        ? "Oczyszczenie (" + CvoidFormatCd(nPurifyCd) + ")"
        : "Oczyszczenie (" + IntToString(CVOID_PURIFY_COST) + " sz.)";
    NuiSetBind(oPC, nToken, CVOID_BIND_PURIFY_LBL, JsonString(sPurLbl));
    NuiSetBind(oPC, nToken, CVOID_BIND_PURIFY_ENA, JsonBool(bCanPurify));
}

// ----------------------------------------------------------------
// NUI window builder
// ----------------------------------------------------------------

json CvoidBuildWindow(object oPC)
{
    float fW     = GetNuiScaleDimension(oPC, CVOID_WIN_W);
    float fH     = GetNuiScaleDimension(oPC, CVOID_WIN_H);
    float fBtnH  = GetNuiScaleDimension(oPC, 32.0);
    float fRowH  = GetNuiScaleDimension(oPC, 30.0);
    float fDescH = GetNuiScaleDimension(oPC, 110.0);
    float fListH = GetNuiScaleDimension(oPC, 256.0);
    float fProgH = GetNuiScaleDimension(oPC, 20.0);
    float fCostW = GetNuiScaleDimension(oPC, 120.0);
    float fCdW   = GetNuiScaleDimension(oPC, 80.0);
    float fTW    = GetNuiScaleDimension(oPC, 48.0);

    // -- Taint bar row --
    json jTaintLbl  = NuiLabel(NuiBind(CVOID_BIND_TAINT_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTaintLbl = NuiWidth(jTaintLbl, GetNuiScaleDimension(oPC, 130.0));

    json jProgBar = NuiProgressBar(NuiBind(CVOID_BIND_TAINT_PROG));
    jProgBar = NuiHeight(jProgBar, fProgH);

    json jTaintRow = NuiRow(JsonArrayInsert(JsonArrayInsert(JsonArray(), jTaintLbl), jProgBar));

    // -- Corruption label --
    json jCorrLbl = NuiLabel(NuiBind(CVOID_BIND_CORR_LBL), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jCorrLbl = NuiStyleForegroundColor(jCorrLbl, NuiBind(CVOID_BIND_CORR_COLOR));
    jCorrLbl = NuiHeight(jCorrLbl, GetNuiScaleDimension(oPC, 22.0));
    json jCorrRow = NuiRow(JsonArrayInsert(JsonArray(), jCorrLbl));

    // -- Canticle list --
    // Template: [Name (elastic)] | [Cost (120)] | [CD (80)] | [+Taint (48)]
    json jNameLbl = NuiLabel(NuiBind(CVOID_BIND_ROW_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(CVOID_BIND_ROW_COLOR));

    json jCostLbl = NuiLabel(NuiBind(CVOID_BIND_ROW_COST), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jCostLbl = NuiWidth(jCostLbl, fCostW);
    jCostLbl = NuiStyleForegroundColor(jCostLbl, NuiBind(CVOID_BIND_ROW_COLOR));

    json jCdLbl = NuiLabel(NuiBind(CVOID_BIND_ROW_CD), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jCdLbl = NuiWidth(jCdLbl, fCdW);

    json jTaintLblRow = NuiLabel(NuiBind(CVOID_BIND_ROW_TAINT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTaintLblRow = NuiWidth(jTaintLblRow, fTW);
    jTaintLblRow = NuiStyleForegroundColor(jTaintLblRow, NuiColor(180, 80, 80));

    json jCellInner = JsonArray();
    jCellInner = JsonArrayInsert(jCellInner, jNameLbl);
    jCellInner = JsonArrayInsert(jCellInner, jCostLbl);
    jCellInner = JsonArrayInsert(jCellInner, jCdLbl);
    jCellInner = JsonArrayInsert(jCellInner, jTaintLblRow);

    json jCell = NuiGroup(NuiRow(jCellInner), FALSE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, CVOID_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(CVOID_BIND_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(CVOID_BIND_ROW_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // -- Description panel --
    json jDescTxt = NuiText(NuiBind(CVOID_BIND_DESC_LBL), FALSE);
    json jDescRow = NuiRow(JsonArrayInsert(JsonArray(), jDescTxt));

    json jDCostLbl = NuiLabel(NuiBind(CVOID_BIND_DETAIL_COST), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jDCdLbl   = NuiLabel(NuiBind(CVOID_BIND_DETAIL_CD),   JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    json jDRow = JsonArray();
    jDRow = JsonArrayInsert(jDRow, jDCostLbl);
    jDRow = JsonArrayInsert(jDRow, jDCdLbl);

    json jDescCol = JsonArray();
    jDescCol = JsonArrayInsert(jDescCol, jDescRow);
    jDescCol = JsonArrayInsert(jDescCol, NuiRow(jDRow));

    json jDescGroup = NuiGroup(NuiCol(jDescCol), TRUE, NUI_SCROLLBARS_NONE);
    jDescGroup = NuiHeight(jDescGroup, fDescH);

    // -- Bottom buttons row --
    json jPerfBtn = NuiButton(NuiBind(CVOID_BIND_PERFORM_LBL));
    jPerfBtn = NuiId(jPerfBtn, CVOID_BTN_PERFORM);
    jPerfBtn = NuiEnabled(jPerfBtn, NuiBind(CVOID_BIND_PERFORM_ENA));
    jPerfBtn = NuiHeight(jPerfBtn, fBtnH);

    json jPurBtn = NuiButton(NuiBind(CVOID_BIND_PURIFY_LBL));
    jPurBtn = NuiId(jPurBtn, CVOID_BTN_PURIFY);
    jPurBtn = NuiEnabled(jPurBtn, NuiBind(CVOID_BIND_PURIFY_ENA));
    jPurBtn = NuiHeight(jPurBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jPerfBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jPurBtn);

    // -- Assemble root column --
    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, jTaintRow);
    jRoot = JsonArrayInsert(jRoot, jCorrRow);
    jRoot = JsonArrayInsert(jRoot, CreateEmptyRow(oPC, 6.0));
    jRoot = JsonArrayInsert(jRoot, jList);
    jRoot = JsonArrayInsert(jRoot, jDescGroup);
    jRoot = JsonArrayInsert(jRoot, NuiRow(jBtnRow));

    json jGeom = NuiRect(200.0, 80.0, fW, fH);
    return NuiWindow(
        NuiCol(jRoot),
        JsonString("Kantylen Otchłani"),
        jGeom,
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(FALSE)
    );
}

// ----------------------------------------------------------------
// Open window
// ----------------------------------------------------------------

void CvoidOpenWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, CVOID_WINDOW);
    if(nToken != 0)
    {
        NuiDestroy(oPC, nToken);
    }

    // Register in DB if first visit
    CvoidTickDailyDecay(oPC);
    int nTaint = CvoidGetTaint(oPC);
    if(nTaint == 0)
    {
        // Ensure row exists for new visitors
        CvoidSetTaint(oPC, 0);
    }

    json jWin = CvoidBuildWindow(oPC);
    nToken = NuiCreate(oPC, jWin, CVOID_WINDOW);
    if(nToken == 0) return;

    SetLocalInt(oPC, CVOID_LVAR_SEL, -1);

    CvoidFeedTaint(oPC, nToken);
    CvoidFeedList(oPC, nToken);
    CvoidFeedDetail(oPC, nToken, -1);

    // Initial purify button state
    int bCanPurify = (CvoidGetPurifyCdRemaining(oPC) <= 0 && GetGold(oPC) >= CVOID_PURIFY_COST && nTaint > 0);
    NuiSetBind(oPC, nToken, CVOID_BIND_PURIFY_LBL, JsonString("Oczyszczenie (" + IntToString(CVOID_PURIFY_COST) + " sz.)"));
    NuiSetBind(oPC, nToken, CVOID_BIND_PURIFY_ENA, JsonBool(bCanPurify));
}

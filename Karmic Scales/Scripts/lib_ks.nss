#include "lib_ks_def"

// ----------------------------------------------------------------
// Scale DrawList visualization
// ----------------------------------------------------------------

json KsBuildScaleDrawList(object oPC, int nKarma)
{
    float fCX    = GetNuiScaleDimension(oPC, 300.0);  // pivot center X
    float fTopY  = GetNuiScaleDimension(oPC,  18.0);  // top of support post
    float fPivY  = GetNuiScaleDimension(oPC,  65.0);  // pivot Y
    float fArmW  = GetNuiScaleDimension(oPC, 125.0);  // half-arm length
    float fTilt  = GetNuiScaleDimension(oPC,  32.0);  // max tilt in px
    float fChain = GetNuiScaleDimension(oPC,  32.0);  // chain height
    float fPanW  = GetNuiScaleDimension(oPC,  22.0);  // pan half-width
    float fPivR  = GetNuiScaleDimension(oPC,   7.0);  // pivot ornament radius
    float fLblW  = GetNuiScaleDimension(oPC,  70.0);  // label width
    float fLblH  = GetNuiScaleDimension(oPC,  20.0);  // label height

    // karma range [-100, 100]: positive = light heavy (right pan down)
    float fRatio  = IntToFloat(nKarma) / 100.0;
    float fLeftX  = fCX - fArmW;
    float fRightX = fCX + fArmW;
    // Dark side (left) goes DOWN when karma is negative (dark heavy)
    float fLeftY  = fPivY - fRatio * fTilt;
    float fRightY = fPivY + fRatio * fTilt;
    float fLPanY  = fLeftY  + fChain;
    float fRPanY  = fRightY + fChain;

    json jGray  = NuiColor(160, 160, 165);
    json jGold  = NuiColor(200, 160,  40);
    json jDark  = NuiColor(190,  40,  60);
    json jLight = NuiColor(210, 185,  50);

    json jDl = JsonArray();

    // 1. Vertical support post
    jDl = JsonArrayInsert(jDl, NuiDrawListLine(
        JsonBool(TRUE), jGray, 3.0,
        NuiVector(fCX, fTopY),
        NuiVector(fCX, fPivY)));

    // 2. Pivot ornament (filled circle)
    jDl = JsonArrayInsert(jDl, NuiDrawListCircle(
        JsonBool(TRUE), jGold, 2.0, TRUE,
        NuiRect(fCX - fPivR, fPivY - fPivR, fPivR * 2.0, fPivR * 2.0)));

    // 3. Scale beam (tilted based on karma)
    jDl = JsonArrayInsert(jDl, NuiDrawListLine(
        JsonBool(TRUE), jGray, 2.5,
        NuiVector(fLeftX, fLeftY),
        NuiVector(fRightX, fRightY)));

    // 4. Left chain (dark side)
    jDl = JsonArrayInsert(jDl, NuiDrawListLine(
        JsonBool(TRUE), jDark, 1.5,
        NuiVector(fLeftX, fLeftY),
        NuiVector(fLeftX, fLPanY)));

    // 5. Right chain (light side)
    jDl = JsonArrayInsert(jDl, NuiDrawListLine(
        JsonBool(TRUE), jLight, 1.5,
        NuiVector(fRightX, fRightY),
        NuiVector(fRightX, fRPanY)));

    // 6. Left pan plate
    jDl = JsonArrayInsert(jDl, NuiDrawListLine(
        JsonBool(TRUE), jDark, 4.0,
        NuiVector(fLeftX - fPanW, fLPanY),
        NuiVector(fLeftX + fPanW, fLPanY)));

    // 7. Right pan plate
    jDl = JsonArrayInsert(jDl, NuiDrawListLine(
        JsonBool(TRUE), jLight, 4.0,
        NuiVector(fRightX - fPanW, fRPanY),
        NuiVector(fRightX + fPanW, fRPanY)));

    // 8. "MROK" label (left, dark red)
    float fMrokX = GetNuiScaleDimension(oPC,  93.0);
    jDl = JsonArrayInsert(jDl, NuiDrawListText(
        JsonBool(TRUE), jDark,
        NuiRect(fMrokX, fPivY - fLblH * 0.5, fLblW, fLblH),
        JsonString("MROK")));

    // 9. "SWIATLO" label (right, gold)
    float fLightX = GetNuiScaleDimension(oPC, 440.0);
    float fLightW = GetNuiScaleDimension(oPC,  88.0);
    jDl = JsonArrayInsert(jDl, NuiDrawListText(
        JsonBool(TRUE), jLight,
        NuiRect(fLightX, fPivY - fLblH * 0.5, fLightW, fLblH),
        JsonString("SWIATLO")));

    // 10. Karma value centered below scale (confirms current value)
    string sKarmaStr;
    if(nKarma > 0)      sKarmaStr = "+" + IntToString(nKarma);
    else if(nKarma < 0) sKarmaStr = IntToString(nKarma);
    else                sKarmaStr = "0";

    json   jKarmaColor = KsGetKarmaColor(nKarma);
    float  fValW       = GetNuiScaleDimension(oPC, 80.0);
    float  fValH       = GetNuiScaleDimension(oPC, 22.0);
    float  fValX       = fCX - fValW * 0.5;
    float  fValY       = fPivY + fChain + GetNuiScaleDimension(oPC, 16.0);
    jDl = JsonArrayInsert(jDl, NuiDrawListText(
        JsonBool(TRUE), jKarmaColor,
        NuiRect(fValX, fValY, fValW, fValH),
        JsonString(sKarmaStr)));

    return jDl;
}

// ----------------------------------------------------------------
// Passive effects
// ----------------------------------------------------------------

void KsApplyPassiveEffects(object oPC, int nKarma)
{
    // Strip all existing passive KS effects
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        effect eNext = GetNextEffect(oPC);
        if(GetEffectTag(eEff) == KS_EFFECT_TAG)
            RemoveEffect(oPC, eEff);
        eEff = eNext;
    }

    int nTier = KsGetTier(nKarma);

    if(nTier == KS_TIER_DAMNATION)
    {
        effect eA = TagEffect(EffectSkillDecrease(SKILL_PERSUADE, 3), KS_EFFECT_TAG);
        effect eB = TagEffect(EffectSkillDecrease(SKILL_HEAL, 3),     KS_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eA, oPC);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eB, oPC);
    }
    else if(nTier == KS_TIER_SHADOW)
    {
        effect eC = TagEffect(EffectAbilityDecrease(ABILITY_CHARISMA, 1), KS_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eC, oPC);
    }
    else if(nTier == KS_TIER_BLESSED)
    {
        effect eD = TagEffect(
            EffectSavingThrowIncrease(SAVING_THROW_WILL, 1, SAVING_THROW_TYPE_ALL),
            KS_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eD, oPC);
    }
    else if(nTier == KS_TIER_TRIAL)
    {
        effect eE = TagEffect(
            EffectSavingThrowIncrease(SAVING_THROW_ALL, 2, SAVING_THROW_TYPE_ALL),
            KS_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eE, oPC);
    }
    // KS_TIER_BALANCE: no passive effect
}

// ----------------------------------------------------------------
// Cooldown query (needs KS_RITUAL_COOLDOWN constant from def)
// ----------------------------------------------------------------

int KsGetRitualCooldownRemaining(object oPC)
{
    int nRitualAt = KsGetLastRitualAt(oPC);
    if(nRitualAt == 0) return 0;

    int nNow     = KsGetUnixNow();
    int nElapsed = nNow - nRitualAt;
    int nLeft    = KS_RITUAL_COOLDOWN - nElapsed;
    return (nLeft > 0 ? nLeft : 0);
}

// ----------------------------------------------------------------
// Window build / open
// ----------------------------------------------------------------

void CreateKsWindow(object oPC)
{
    // Always destroy the old window so the DrawList reflects current karma
    int nOld = NuiFindWindow(oPC, KS_WINDOW);
    if(nOld != 0) NuiDestroy(oPC, nOld);

    float fBtnH  = GetNuiScaleDimension(oPC, KS_ROW);
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);

    // ---- Scale region: a tall spacer reserves space for the DrawList ----
    json jScaleSpacer = NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, 155.0));

    // ---- Tier label ----
    json jTierLbl = NuiLabel(NuiBind(KS_BIND_TIER_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTierLbl = NuiHeight(jTierLbl, fBtnH);
    jTierLbl = NuiStyleForegroundColor(jTierLbl, NuiBind(KS_BIND_TIER_COL));

    // ---- Effect description (2-line, centered) ----
    json jEffLbl = NuiLabel(NuiBind(KS_BIND_EFFECT_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jEffLbl = NuiHeight(jEffLbl, GetNuiScaleDimension(oPC, 46.0));

    // ---- Log header ----
    json jLogHdr = NuiLabel(JsonString("Ostatnie zdarzenia:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLogHdr = NuiHeight(jLogHdr, GetNuiScaleDimension(oPC, 22.0));

    // ---- Log list ----
    json jLogLbl = NuiLabel(NuiBind(KS_BIND_LOG_TXT),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLogLbl = NuiStyleForegroundColor(jLogLbl, NuiBind(KS_BIND_LOG_COL));

    json jLogCell = NuiGroup(
        NuiRow(JsonArrayInsert(JsonArray(), jLogLbl)),
        TRUE, NUI_SCROLLBARS_NONE);

    json jLogTmpl = JsonArrayInsert(JsonArray(),
        NuiListTemplateCell(jLogCell, 0.0, TRUE));

    json jLogList = NuiList(jLogTmpl, NuiBind(KS_BIND_LOG_CNT), fRowH);
    jLogList = NuiHeight(jLogList, GetNuiScaleDimension(oPC, 100.0));

    // ---- Buttons ----
    json jBtnRitual = NuiButton(JsonString("Rytual Rownowagi (50 sz)"));
    jBtnRitual = NuiId(jBtnRitual, KS_BTN_RITUAL);
    jBtnRitual = NuiEnabled(jBtnRitual, NuiBind(KS_BIND_BTN_RIT_ENA));
    jBtnRitual = NuiTooltip(jBtnRitual, NuiBind(KS_BIND_BTN_RIT_TIP));
    jBtnRitual = NuiHeight(jBtnRitual, fBtnH);

    json jBtnShadow = NuiButton(JsonString("Uwolnij Cien (-25)"));
    jBtnShadow = NuiId(jBtnShadow, KS_BTN_SHADOW_SURGE);
    jBtnShadow = NuiEnabled(jBtnShadow, NuiBind(KS_BIND_BTN_SHAD_ENA));
    jBtnShadow = NuiTooltip(jBtnShadow,
        JsonString("Wydaj 25 pkt. Mroku. Zysk: +2 do ataku przez 60 sek."));
    jBtnShadow = NuiHeight(jBtnShadow, fBtnH);

    json jBtnLight = NuiButton(JsonString("Uwolnij Blask (-25)"));
    jBtnLight = NuiId(jBtnLight, KS_BTN_LIGHT_GRACE);
    jBtnLight = NuiEnabled(jBtnLight, NuiBind(KS_BIND_BTN_LIGHT_ENA));
    jBtnLight = NuiTooltip(jBtnLight,
        JsonString("Wydaj 25 pkt. Swiatla. Zysk: regeneracja 2 PZ/6s przez 60 sek."));
    jBtnLight = NuiHeight(jBtnLight, fBtnH);

    json jBtnClose = NuiButton(JsonString("Zamknij"));
    jBtnClose = NuiId(jBtnClose, KS_BTN_CLOSE);
    jBtnClose = NuiWidth(jBtnClose, GetNuiScaleDimension(oPC, 80.0));
    jBtnClose = NuiHeight(jBtnClose, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jBtnRitual);
    jBtnRow = JsonArrayInsert(jBtnRow, jBtnShadow);
    jBtnRow = JsonArrayInsert(jBtnRow, jBtnLight);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jBtnClose);

    // ---- Assemble root column ----
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jScaleSpacer);
    jCol = JsonArrayInsert(jCol, jTierLbl);
    jCol = JsonArrayInsert(jCol, jEffLbl);
    jCol = JsonArrayInsert(jCol, jLogHdr);
    jCol = JsonArrayInsert(jCol, jLogList);
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jRoot = NuiCol(jCol);

    // ---- Bake DrawList (snapshot of current karma) ----
    int nKarma = KsGetKarma(oPC);
    json jDl   = KsBuildScaleDrawList(oPC, nKarma);
    jRoot      = NuiDrawList(jRoot, JsonBool(FALSE), jDl);

    SetLocalInt(oPC, KS_LVAR_DRAWN_KARMA, nKarma);

    // ---- Window geometry: centered ----
    float fW = GetNuiScaleDimension(oPC, KS_W);
    float fH = GetNuiScaleDimension(oPC, KS_H);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;
    json jGeom = NuiRect(fX, fY, fW, fH);

    json jWin = NuiWindow(jRoot,
        JsonString("Szale Przeznaczenia"),
        NuiBind(KS_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, KS_WINDOW, KS_EV_SCRIPT);
    NuiSetBind(oPC, nToken, KS_WIN_GEOM, jGeom);

    FeedKsWindow(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed: update all bind values
// ----------------------------------------------------------------

void FeedKsWindow(object oPC, int nToken)
{
    int nKarma = KsGetKarma(oPC);

    NuiSetBind(oPC, nToken, KS_BIND_TIER_LBL,  JsonString(KsGetTierLabel(nKarma)));
    NuiSetBind(oPC, nToken, KS_BIND_TIER_COL,  KsGetTierColor(nKarma));
    NuiSetBind(oPC, nToken, KS_BIND_EFFECT_LBL, JsonString(KsGetTierEffectDescription(nKarma)));

    string sKarmaLbl;
    if(nKarma > 0)      sKarmaLbl = "+" + IntToString(nKarma);
    else if(nKarma < 0) sKarmaLbl = IntToString(nKarma);
    else                sKarmaLbl = "0";
    NuiSetBind(oPC, nToken, KS_BIND_KARMA_LBL, JsonString("Karma: " + sKarmaLbl));
    NuiSetBind(oPC, nToken, KS_BIND_KARMA_COL, KsGetKarmaColor(nKarma));

    // ---- Log entries ----
    json jLog    = KsGetLog(oPC);
    int  nCount  = JsonGetLength(jLog);
    json jTxts   = JsonArray();
    json jCols   = JsonArray();
    int  i;
    for(i = 0; i < nCount; i++)
    {
        json   jRow   = JsonArrayGet(jLog, i);
        int    nDelta = JsonGetInt(JsonObjectGet(jRow, "delta"));
        string sReas  = JsonGetString(JsonObjectGet(jRow, "reason"));

        string sSign = (nDelta >= 0 ? "+" : "");
        string sTxt  = "[" + sSign + IntToString(nDelta) + "] " + sReas;
        json   jCol  = (nDelta >= 0 ? NuiColor(140, 220, 70) : NuiColor(220, 70, 70));

        jTxts = JsonArrayInsert(jTxts, JsonString(sTxt));
        jCols = JsonArrayInsert(jCols, jCol);
    }
    NuiSetBind(oPC, nToken, KS_BIND_LOG_TXT, jTxts);
    NuiSetBind(oPC, nToken, KS_BIND_LOG_COL, jCols);
    NuiSetBind(oPC, nToken, KS_BIND_LOG_CNT, JsonInt(nCount));

    // ---- Button states ----
    int nCooldown = KsGetRitualCooldownRemaining(oPC);
    int bEnough   = (GetGold(oPC) >= KS_RITUAL_GOLD_COST);
    int bNeedsShift = (abs(nKarma) >= KS_RITUAL_SHIFT);
    int bRitualOk = (nCooldown <= 0 && bEnough && bNeedsShift);

    string sRitTip;
    if(nCooldown > 0)
        sRitTip = "Odmowa modlitwna. Poczekaj " + IntToString(nCooldown / 60 + 1) + " min.";
    else if(!bEnough)
        sRitTip = "Potrzebujesz " + IntToString(KS_RITUAL_GOLD_COST) + " sztuk zlota.";
    else if(!bNeedsShift)
        sRitTip = "Szale sa wystarczajaco zrownowazone.";
    else
        sRitTip = "Przesuwa karme o " + IntToString(KS_RITUAL_SHIFT) + " ku rownowadze. Koszt: "
                + IntToString(KS_RITUAL_GOLD_COST) + " sz.";

    NuiSetBind(oPC, nToken, KS_BIND_BTN_RIT_ENA,   JsonBool(bRitualOk));
    NuiSetBind(oPC, nToken, KS_BIND_BTN_RIT_TIP,   JsonString(sRitTip));
    NuiSetBind(oPC, nToken, KS_BIND_BTN_SHAD_ENA,  JsonBool(nKarma <= -KS_SURGE_COST));
    NuiSetBind(oPC, nToken, KS_BIND_BTN_LIGHT_ENA, JsonBool(nKarma >=  KS_GRACE_COST));
}

// ----------------------------------------------------------------
// Surge / Grace temporary effects
// ----------------------------------------------------------------

void KsApplyShadowSurge(object oPC)
{
    effect eSurge = TagEffect(EffectAttackIncrease(2, ATTACK_BONUS_MISC), KS_SURGE_TAG);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eSurge, oPC, 60.0);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
        EffectVisualEffect(VFX_DUR_SPELLTURNING), oPC, 2.0);
}

void KsApplyLightGrace(object oPC)
{
    effect eGrace = TagEffect(EffectRegenerate(2, 6.0), KS_GRACE_TAG);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eGrace, oPC, 60.0);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
        EffectVisualEffect(VFX_DUR_GLOBE_INVULNERABILITY), oPC, 2.0);
}

// ----------------------------------------------------------------
// Public API — call from module event scripts to modify karma
// ----------------------------------------------------------------

void KsAwardKarma(object oPC, int nDelta, string sReason)
{
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;
    if(nDelta == 0) return;

    int nOldKarma = KsGetKarma(oPC);
    int nOldTier  = KsGetTier(nOldKarma);
    int nNew      = KsAddKarma(oPC, nDelta);
    int nNewTier  = KsGetTier(nNew);

    KsLogEvent(oPC, nDelta, sReason);

    // Reapply passive effects only when tier changes
    if(nNewTier != nOldTier)
    {
        KsApplyPassiveEffects(oPC, nNew);
        string sMsg = KsGetTierChangeMessage(nNewTier);
        FloatingTextStringOnCreature(sMsg, oPC, FALSE);
        SendMessageToPC(oPC, sMsg);
        SendMessageToPC(oPC, "[Szale] " + KsGetTierEffectDescription(nNew));
    }

    // Refresh window: recreate so DrawList stays current
    if(NuiFindWindow(oPC, KS_WINDOW) != 0)
        CreateKsWindow(oPC);
}

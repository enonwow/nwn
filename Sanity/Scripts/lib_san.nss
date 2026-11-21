// lib_san.nss — UI construction, game-logic triggers, and effect management
//   for the Sanity module.

#include "lib_san_def"

// ================================================================
// Effect management
// ================================================================

// Removes every active effect on oPC that carries SAN_EFFECT_TAG.
void SanRemoveEffects(object oPC)
{
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        effect eNext = GetNextEffect(oPC);
        if(GetEffectTag(eEff) == SAN_EFFECT_TAG)
            RemoveEffect(oPC, eEff);
        eEff = eNext;
    }
}

// Recalculates and re-applies all permanent sanity debuffs from scratch.
void SanApplyEffects(object oPC)
{
    SanRemoveEffects(oPC);
    int nSan = SanGetSanity(oPC);
    if(nSan >= SAN_THR_UNEASE) return;

    // Accumulate penalties per threshold crossed.
    int nWis = 0;
    int nInt = 0;

    if(nSan < SAN_THR_UNEASE)   nWis += 2;
    if(nSan < SAN_THR_HORROR)   nWis += 2;
    if(nSan < SAN_THR_MADNESS)  { nWis += 2; nInt += 4; }
    if(nSan < SAN_THR_INSANITY) { nWis += 4; nInt += 4; }

    if(nWis > 0)
        ApplyEffectToObject(DURATION_TYPE_PERMANENT,
            TagEffect(EffectAbilityDecrease(ABILITY_WISDOM,       nWis), SAN_EFFECT_TAG), oPC);
    if(nInt > 0)
        ApplyEffectToObject(DURATION_TYPE_PERMANENT,
            TagEffect(EffectAbilityDecrease(ABILITY_INTELLIGENCE, nInt), SAN_EFFECT_TAG), oPC);
}

// Checks whether the threshold level changed and, if so, re-applies effects
// and notifies the player.  Avoids redundant effect churn on every tick.
void SanSyncEffects(object oPC)
{
    int nSan  = SanGetSanity(oPC);
    int nLvl  = SanThresholdLevel(nSan);
    int nLast = GetLocalInt(oPC, SAN_LVAR_SYNC_LVL);
    if(nLvl == nLast) return;

    SetLocalInt(oPC, SAN_LVAR_SYNC_LVL, nLvl);
    SanApplyEffects(oPC);
    SendMessageToPC(oPC, SanThresholdMessage(nLvl));
    FloatingTextStringOnCreature(SanThresholdMessage(nLvl), oPC, FALSE);
}

// ================================================================
// Random episodic effects  (called on every heartbeat tick)
// ================================================================

void SanApplyRandomEffect(object oPC)
{
    int nSan = SanGetSanity(oPC);
    if(nSan >= SAN_THR_HORROR) return;   // episodes only below GROZA

    int nRoll = Random(100);

    if(nSan < SAN_THR_INSANITY && nRoll < 5)
    {
        // Brief paralysis — the mind short-circuits entirely.
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectParalyze(), oPC, 3.0);
        FloatingTextStringOnCreature("Twój umysł zapada w otchłań obłędu...", oPC, FALSE);
        return;
    }
    if(nSan < SAN_THR_MADNESS && nRoll < 12)
    {
        // Hallucinations blot out vision.
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectBlindness(), oPC, 5.0);
        FloatingTextStringOnCreature("Halucynacje zamazują twój wzrok...", oPC, FALSE);
        return;
    }
    if(nRoll < 18)
    {
        // Irrational terror seizes the mind.
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectFear(), oPC, 6.0);
        FloatingTextStringOnCreature("Opanowuje cię irracjonalny terror...", oPC, FALSE);
    }
}

// ================================================================
// Sanity-loss triggers
// ================================================================

// Checks whether an undead creature is within 10 metres and drains sanity.
void SanCheckUndead(object oPC)
{
    object oUndead = GetNearestCreature(
        CREATURE_TYPE_RACIAL_TYPE, RACIAL_TYPE_UNDEAD, oPC, 1,
        CREATURE_TYPE_IS_ALIVE, TRUE);
    if(!GetIsObjectValid(oUndead)) return;
    if(GetDistanceBetween(oPC, oUndead) > 10.0) return;

    int nNew = SanAdjust(oPC, -SAN_LOSS_UNDEAD, "Obecność nieumarłych");
    if(nNew >= 0) SanSyncEffects(oPC);
}

// Drains sanity when the PC is near death (HP < 10 % of max).
void SanCheckNearDeath(object oPC)
{
    int nCurrent = GetCurrentHitPoints(oPC);
    int nMax     = GetMaxHitPoints(oPC);
    if(nMax <= 0 || nCurrent * 10 >= nMax) return;

    int nNew = SanAdjust(oPC, -SAN_LOSS_NEAR_DEATH, "Bliskość śmierci");
    if(nNew >= 0) SanSyncEffects(oPC);
}

// Drains sanity when the PC stands in an area tagged as a horror zone.
// Builders mark an area by setting its local integer SAN_HORROR_AREA = 1.
void SanCheckHorrorArea(object oPC)
{
    if(!GetLocalInt(GetArea(oPC), SAN_AREA_HORROR)) return;

    int nNew = SanAdjust(oPC, -SAN_LOSS_HORROR_AREA, "Przeklęte miejsce");
    if(nNew >= 0) SanSyncEffects(oPC);
}

// Drains sanity when a PC ally dies in the same area.
// Call this from the module's OnPlayerDeath hook (or a creature OnDeath).
void SanOnAllyDeath(object oPC, object oDeceased)
{
    if(!GetIsPC(oPC) || GetIsDead(oPC)) return;
    if(GetArea(oPC) != GetArea(oDeceased)) return;
    if(oPC == oDeceased) return;

    int nNew = SanAdjust(oPC, -SAN_LOSS_ALLY_DEATH, "Śmierć sojusznika");
    if(nNew >= 0) SanSyncEffects(oPC);
}

// Restores sanity via holy water (call from OnActivateItem).
void SanOnActivateItem(object oPC, object oItem)
{
    if(GetTag(oItem) != SAN_ITEM_TAG_HOLY) return;
    int nSan = SanGetSanity(oPC);
    if(nSan >= SAN_MAX)
    {
        SendMessageToPC(oPC, "[Szaleństwo] Twój umysł jest już spokojny.");
        return;
    }
    SanAdjust(oPC, SAN_GAIN_HOLY, "Święcona woda");
    SanSyncEffects(oPC);
    SendMessageToPC(oPC, "[Szaleństwo] Święcona woda koi twój umysł.");
    FloatingTextStringOnCreature("Pieczęć grozy słabnie...", oPC, FALSE);
    DestroyObject(oItem);
}

// ================================================================
// NUI — window construction
// ================================================================

json SanBuildWindow(object oPC)
{
    float fBtnH   = GetNuiScaleDimension(oPC,  32.0);
    float fBarH   = GetNuiScaleDimension(oPC,  26.0);
    float fSmallH = GetNuiScaleDimension(oPC,  22.0);
    float fFlavorH= GetNuiScaleDimension(oPC,  56.0);
    float fMedH   = GetNuiScaleDimension(oPC,  36.0);
    float fCloseW = GetNuiScaleDimension(oPC,  36.0);

    // ── Title row ──────────────────────────────────────────────
    json jTitleLbl = NuiLabel(
        JsonString("Stan Psychiczny"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, fBtnH);

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId    (jCloseBtn, SAN_BTN_CLOSE);
    jCloseBtn = NuiWidth (jCloseBtn, fCloseW);
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTitleArr = JsonArray();
    jTitleArr = JsonArrayInsert(jTitleArr, jTitleLbl);
    jTitleArr = JsonArrayInsert(jTitleArr, jCloseBtn);

    // ── Status label  (colored, e.g. "GROZA") ─────────────────
    json jStatusLbl = NuiLabel(
        NuiBind(SAN_BIND_STATUS_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiBind(SAN_BIND_STATUS_COL));
    jStatusLbl = NuiHeight(jStatusLbl, fBtnH);

    // ── Sanity progress bar ────────────────────────────────────
    json jBar = NuiProgress(NuiBind(SAN_BIND_BAR_VAL));
    jBar = NuiStyleForegroundColor(jBar, NuiBind(SAN_BIND_BAR_COL));
    jBar = NuiHeight(jBar, fBarH);

    // ── Numeric value "73 / 100" ──────────────────────────────
    json jValueLbl = NuiLabel(
        NuiBind(SAN_BIND_VALUE_TXT),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jValueLbl = NuiHeight(jValueLbl, fSmallH);

    // ── Flavor text ────────────────────────────────────────────
    json jFlavor = NuiLabel(
        NuiBind(SAN_BIND_FLAVOR_TXT),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jFlavor = NuiHeight(jFlavor, fFlavorH);

    // ── Event log header ───────────────────────────────────────
    json jLogHeader = NuiLabel(
        JsonString("Ostatnie zdarzenia:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLogHeader = NuiHeight(jLogHeader, fSmallH);

    // ── Event log list  (scrollable, SAN_EVENT_LOG_MAX rows) ──
    json jEvtLbl = NuiLabel(
        NuiBind(SAN_BIND_EVT_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEvtLbl = NuiStyleForegroundColor(jEvtLbl, NuiBind(SAN_BIND_EVT_COL));

    json jEvtRowArr = JsonArray();
    jEvtRowArr = JsonArrayInsert(jEvtRowArr, jEvtLbl);
    json jEvtList = NuiList(
        NuiRow(jEvtRowArr),
        NuiBind(SAN_BIND_EVT_COUNT),
        fSmallH);

    // ── Meditate button ────────────────────────────────────────
    json jMedBtn = NuiButton(JsonString("Medytuj  (+" + IntToString(SAN_GAIN_MEDITATE) + ")"));
    jMedBtn = NuiId     (jMedBtn, SAN_BTN_MEDITATE);
    jMedBtn = NuiEnabled(jMedBtn, NuiBind(SAN_BIND_MED_ENA));
    jMedBtn = NuiTooltip(jMedBtn, NuiBind(SAN_BIND_MED_TIP));
    jMedBtn = NuiHeight (jMedBtn, fMedH);

    // ── Assemble column ────────────────────────────────────────
    json jCol = JsonArray();

    jCol = JsonArrayInsert(jCol, NuiRow(jTitleArr));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jStatusLbl)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jBar)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jValueLbl)));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jFlavor)));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jLogHeader)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jEvtList)));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jMedBtn)));

    return NuiWindow(
        NuiCol(jCol),
        JsonString("Stan Psychiczny"),
        NuiBind(SAN_WIN_GEOM),
        JsonBool(FALSE),  // not resizable
        JsonBool(FALSE),  // not collapsed
        JsonBool(TRUE),   // closable
        JsonBool(FALSE),  // not transparent
        JsonBool(TRUE));  // has border
}

// ================================================================
// NUI — data feed
// ================================================================

void SanFeedWindow(object oPC, int nToken)
{
    int nSan = SanGetSanity(oPC);

    NuiSetBind(oPC, nToken, SAN_BIND_STATUS_LBL, JsonString(SanStatusText(nSan)));
    NuiSetBind(oPC, nToken, SAN_BIND_STATUS_COL, SanBarColor(nSan));
    NuiSetBind(oPC, nToken, SAN_BIND_BAR_VAL,    JsonFloat((nSan * 1.0) / SAN_MAX));
    NuiSetBind(oPC, nToken, SAN_BIND_BAR_COL,    SanBarColor(nSan));
    NuiSetBind(oPC, nToken, SAN_BIND_VALUE_TXT,
        JsonString(IntToString(nSan) + " / " + IntToString(SAN_MAX)));
    NuiSetBind(oPC, nToken, SAN_BIND_FLAVOR_TXT, JsonString(SanFlavorText(nSan)));

    // ── Event log ──────────────────────────────────────────────
    json jEvents = SanGetRecentEvents(oPC, SAN_EVENT_LOG_MAX);
    int  nCount  = JsonGetLength(jEvents);
    json jLabels = JsonArray();
    json jColors = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json   jEv     = JsonArrayGet(jEvents, i);
        int    nDelta  = JsonGetInt   (JsonObjectGet(jEv, "delta"));
        string sReason = JsonGetString(JsonObjectGet(jEv, "reason"));
        string sPrefix = (nDelta >= 0) ? "+" : "";

        jLabels = JsonArrayInsert(jLabels,
            JsonString(sPrefix + IntToString(nDelta) + "   " + sReason));
        jColors = JsonArrayInsert(jColors,
            (nDelta >= 0) ? NuiColor(80, 200, 80, 255) : NuiColor(200, 80, 80, 255));
    }
    // Pad empty rows so the list height stays stable.
    for(i = nCount; i < SAN_EVENT_LOG_MAX; i++)
    {
        jLabels = JsonArrayInsert(jLabels, JsonString(""));
        jColors = JsonArrayInsert(jColors, NuiColor(80, 80, 80, 255));
    }
    NuiSetBind(oPC, nToken, SAN_BIND_EVT_COUNT, JsonInt(nCount > 0 ? nCount : 1));
    NuiSetBind(oPC, nToken, SAN_BIND_EVT_LBL,   jLabels);
    NuiSetBind(oPC, nToken, SAN_BIND_EVT_COL,   jColors);

    // ── Meditate button ────────────────────────────────────────
    int bCanMed = SanCanMeditate(oPC, SAN_COOLDOWN_MEDITATE) && (nSan < SAN_MAX);
    NuiSetBind(oPC, nToken, SAN_BIND_MED_ENA, JsonBool(bCanMed));
    NuiSetBind(oPC, nToken, SAN_BIND_MED_TIP,
        JsonString(bCanMed
            ? "Usiądź w ciszy i uspokój umysł."
            : "Musisz poczekać przed następną medytacją."));
}

// ================================================================
// NUI — open / create
// ================================================================

void SanOpen(object oPC)
{
    SanEnsureChar(oPC);

    int nToken = NuiFindWindow(oPC, SAN_WINDOW);
    if(nToken != 0)
    {
        SanFeedWindow(oPC, nToken);
        return;
    }

    json jWindow = SanBuildWindow(oPC);
    nToken = NuiCreate(oPC, jWindow, SAN_WINDOW);

    // Centre the window on screen.
    float fSW = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH));
    float fSH = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT));
    float fW  = GetNuiScaleDimension(oPC, SAN_W);
    float fH  = GetNuiScaleDimension(oPC, SAN_H);
    NuiSetBind(oPC, nToken, SAN_WIN_GEOM,
        NuiRect((fSW - fW) * 0.5, (fSH - fH) * 0.5, fW, fH));

    SanFeedWindow(oPC, nToken);
}

// ================================================================
// Meditate action  (called from event handler on button click)
// ================================================================

void SanHandleMeditate(object oPC, int nToken)
{
    if(!SanCanMeditate(oPC, SAN_COOLDOWN_MEDITATE))
    {
        SendMessageToPC(oPC, "[Szaleństwo] Nie możesz jeszcze medytować.");
        return;
    }
    int nSan = SanGetSanity(oPC);
    if(nSan >= SAN_MAX)
    {
        SendMessageToPC(oPC, "[Szaleństwo] Twój umysł jest już spokojny.");
        return;
    }

    SanAdjust(oPC, SAN_GAIN_MEDITATE, "Medytacja");
    SanRecordMeditate(oPC);
    SanSyncEffects(oPC);

    FloatingTextStringOnCreature("Cisza koi twój niespokojny umysł...", oPC, FALSE);
    SanFeedWindow(oPC, nToken);
}

// ================================================================
// Registration  (call on module Enter)
// ================================================================

void SanOnPlayerEnter(object oPC)
{
    SanEnsureChar(oPC);
    SanSyncEffects(oPC);    // re-apply effects after relog

    int nSan = SanGetSanity(oPC);
    if(nSan < SAN_THR_UNEASE)
    {
        SendMessageToPC(oPC, "[Szaleństwo] Twój stan psychiczny: "
            + SanStatusText(nSan) + " (" + IntToString(nSan) + "/" + IntToString(SAN_MAX) + ")");
    }
}

// ================================================================
// Rest recovery  (call from module OnPlayerRest hook)
// ================================================================

void SanOnPlayerRest(object oPC)
{
    int nSan = SanGetSanity(oPC);
    if(nSan >= SAN_MAX) return;

    SanAdjust(oPC, SAN_GAIN_REST, "Odpoczynek");
    SanSyncEffects(oPC);
    FloatingTextStringOnCreature("Spokojny sen łagodzi pieczęć szaleństwa...", oPC, FALSE);

    int nToken = NuiFindWindow(oPC, SAN_WINDOW);
    if(nToken != 0) SanFeedWindow(oPC, nToken);
}

// ================================================================
// Heartbeat dispatcher  (call from module OnHeartbeat)
// ================================================================

void SanHeartbeatTick()
{
    int nTick = GetLocalInt(GetModule(), SAN_LVAR_TICK) + 1;
    SetLocalInt(GetModule(), SAN_LVAR_TICK, nTick);

    int bUndead = (nTick % SAN_TICK_UNDEAD     == 0);
    int bDeath  = (nTick % SAN_TICK_NEAR_DEATH == 0);
    int bHorror = (nTick % SAN_TICK_HORROR_AREA== 0);

    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(!GetIsDead(oPC))
        {
            if(bUndead) SanCheckUndead(oPC);
            if(bDeath)  SanCheckNearDeath(oPC);
            if(bHorror) SanCheckHorrorArea(oPC);
            SanApplyRandomEffect(oPC);

            // Refresh open window once per undead-check cycle.
            if(bUndead)
            {
                int nToken = NuiFindWindow(oPC, SAN_WINDOW);
                if(nToken != 0) SanFeedWindow(oPC, nToken);
            }
        }
        oPC = GetNextPC();
    }
}

// =============================================================================
// lib_wnt.nss
// =============================================================================
// Core logic for the Wanted system:
//   - HUD  (small, always-on): skull icon-button + level label + heat bar
//   - Records Panel (opened via HUD click): flavor text + bribe + surrender
//   - 10-second tick: refreshes HUD, detects threshold transitions
//   - WantedAddHeat()   — primary API for crime hooks
//   - WantedBribe()     — pay gold to reduce heat
//   - WantedSurrender() — pay per-crime fine, clear record
// =============================================================================

#include "lib_wnt_def"

// Forward declarations so helpers can be called before their definitions.
void WantedHudTick(object oPC);
void FeedWantedHud(object oPC, int nToken, int nHeat, int nLvl);
void FeedWantedPanel(object oPC, int nToken, int nHeat, int nLvl, int nCrimes);
void WantedDestroyPanel(object oPC);

// ===========================================================================
// HUD layout
// ===========================================================================

json BuildWantedHudLayout()
{
    // Clickable skull icon — fires "click" event with element WNT_BTN_OPEN.
    json jBtn = NuiButtonImage(NuiBind(WNT_BIND_ICON));
    jBtn = NuiId(jBtn, WNT_BTN_OPEN);
    jBtn = NuiWidth(jBtn,  WNT_HUD_ICON);
    jBtn = NuiHeight(jBtn, WNT_HUD_ICON);
    jBtn = NuiTooltip(jBtn, NuiBind(WNT_BIND_TIP));

    // Wanted level name label.
    json jLbl = NuiLabel(
        NuiBind(WNT_BIND_LVL_LBL),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jLbl = NuiWidth(jLbl, 100.0);

    // Heat progress bar — coloured by threshold.
    json jBar = NuiProgress(NuiBind(WNT_BIND_BAR));
    jBar = NuiHeight(jBar, 16.0);
    jBar = NuiStyleForegroundColor(jBar, NuiBind(WNT_BIND_COLOR));
    jBar = NuiTooltip(jBar, NuiBind(WNT_BIND_TIP));

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jBtn);
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), 6.0));
    jRow = JsonArrayInsert(jRow, jLbl);
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), 4.0));
    jRow = JsonArrayInsert(jRow, jBar);

    return NuiRow(jRow);
}

// ===========================================================================
// HUD lifecycle
// ===========================================================================

void WantedCreateHud(object oPC)
{
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;
    if(NuiFindWindow(oPC, WNT_HUD_WIN) != 0) return;

    string sUuid = GetObjectUUID(oPC);
    struct WantedUiPos pos = WantedGetUiPos(sUuid);

    json jGeom = NuiRect(pos.x, pos.y, WNT_HUD_W, WNT_HUD_H);
    json jWin  = NuiWindow(
        BuildWantedHudLayout(),
        JsonString(""),           // no visible title — acts as drag handle only
        NuiBind(WNT_BIND_GEOM),   // geometry bind (drag updates this)
        JsonBool(FALSE),          // resizable
        JsonBool(FALSE),          // collapsed
        JsonBool(FALSE),          // closable
        JsonBool(FALSE),          // transparent
        JsonBool(TRUE));          // border

    int nToken = NuiCreate(oPC, jWin, WNT_HUD_WIN, "lib_wnt_ev");
    if(nToken == 0) return;

    NuiSetBind(oPC, nToken, WNT_BIND_GEOM, jGeom);
    NuiSetBindWatch(oPC, nToken, WNT_BIND_GEOM, TRUE);
    SetLocalInt(oPC, WNT_LVAR_HUD_TOKEN, nToken);

    struct WantedState s = WantedGetState(sUuid);
    int nHeat = WantedCalcHeat(s);
    int nLvl  = WantedGetLevel(nHeat);
    FeedWantedHud(oPC, nToken, nHeat, nLvl);

    // Guard against double-chained ticks on reconnect.
    if(!GetLocalInt(oPC, WNT_LVAR_TICK_GUARD))
    {
        SetLocalInt(oPC, WNT_LVAR_TICK_GUARD, 1);
        DelayCommand(10.0, WantedHudTick(oPC));
    }
}

void WantedDestroyHud(object oPC)
{
    int nToken = GetLocalInt(oPC, WNT_LVAR_HUD_TOKEN);
    if(nToken != 0) NuiDestroy(oPC, nToken);
    DeleteLocalInt(oPC, WNT_LVAR_HUD_TOKEN);
    DeleteLocalInt(oPC, WNT_LVAR_GEOM_DELAY);
    DeleteLocalInt(oPC, WNT_LVAR_TICK_GUARD);
}

// ===========================================================================
// HUD data feed
// ===========================================================================

void FeedWantedHud(object oPC, int nToken, int nHeat, int nLvl)
{
    int nRgb = WantedGetColorRGB(nLvl);

    NuiSetBind(oPC, nToken, WNT_BIND_ICON,
        JsonString(WantedGetIconResref(nLvl)));
    NuiSetBind(oPC, nToken, WNT_BIND_LVL_LBL,
        JsonString(WantedGetLevelName(nLvl)));
    NuiSetBind(oPC, nToken, WNT_BIND_BAR,
        JsonFloat(IntToFloat(nHeat) / IntToFloat(WNT_MAX_HEAT)));
    NuiSetBind(oPC, nToken, WNT_BIND_COLOR,
        NuiColor((nRgb >> 16) & 0xFF, (nRgb >> 8) & 0xFF, nRgb & 0xFF));
    NuiSetBind(oPC, nToken, WNT_BIND_TIP,
        JsonString("Goraczka: " + IntToString(nHeat) + "/100 — "
            + WantedGetLevelName(nLvl)));
}

// ===========================================================================
// 10-second tick: refresh UI, detect threshold transitions
// ===========================================================================

void WantedHudTick(object oPC)
{
    if(!GetIsPC(oPC) || !GetIsObjectValid(oPC)) return;

    int nToken = GetLocalInt(oPC, WNT_LVAR_HUD_TOKEN);
    if(nToken == 0) return;

    if(NuiFindWindow(oPC, WNT_HUD_WIN) == 0)
    {
        // Player closed the HUD somehow; stop ticking.
        DeleteLocalInt(oPC, WNT_LVAR_HUD_TOKEN);
        return;
    }

    string sUuid = GetObjectUUID(oPC);
    struct WantedState s = WantedGetState(sUuid);
    int nHeat = WantedCalcHeat(s);
    int nLvl  = WantedGetLevel(nHeat);

    FeedWantedHud(oPC, nToken, nHeat, nLvl);

    if(nLvl != s.last_level)
    {
        WantedApplyEffects(oPC, nLvl);
        WantedWriteLastLevel(sUuid, nLvl);

        if(nLvl < s.last_level)
            FloatingTextStringOnCreature(
                "Goraczka opada... " + WantedGetLevelName(nLvl) + ".",
                oPC, FALSE);
        else
            FloatingTextStringOnCreature(
                "Jestes teraz " + WantedGetLevelName(nLvl) + "!",
                oPC, FALSE);

        // Keep the open panel in sync.
        int nPanelToken = GetLocalInt(oPC, WNT_LVAR_PANEL_TOKEN);
        if(nPanelToken != 0)
            FeedWantedPanel(oPC, nPanelToken, nHeat, nLvl, s.crimes_committed);
    }

    DelayCommand(10.0, WantedHudTick(oPC));
}

// ===========================================================================
// Records Panel layout
// ===========================================================================

json BuildWantedPanelLayout()
{
    // Large header: level name.
    json jHdr = NuiLabel(
        NuiBind(WNT_PANEL_BIND_HDR),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHdr = NuiHeight(jHdr, 28.0);

    // Flavor body text (multi-line).
    json jBody = NuiLabel(
        NuiBind(WNT_PANEL_BIND_BODY),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_TOP));
    jBody = NuiHeight(jBody, 70.0);

    // Stats line: current heat.
    json jHeat = NuiLabel(
        NuiBind(WNT_PANEL_BIND_HEAT),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jHeat = NuiHeight(jHeat, 20.0);

    // Stats line: crime count.
    json jCrimes = NuiLabel(
        NuiBind(WNT_PANEL_BIND_CRIMES),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jCrimes = NuiHeight(jCrimes, 20.0);

    // Bribe button — label contains dynamic gold cost.
    json jBtnBribe = NuiButton(NuiBind(WNT_PANEL_BIND_BRIBE));
    jBtnBribe = NuiId(jBtnBribe, WNT_BTN_BRIBE);
    jBtnBribe = NuiEnabled(jBtnBribe, NuiBind(WNT_PANEL_BIND_BRIBE_EN));
    jBtnBribe = NuiHeight(jBtnBribe, 28.0);

    // Surrender button — static label.
    json jBtnSurr = NuiButton(JsonString("Oddaj sie w rece prawa"));
    jBtnSurr = NuiId(jBtnSurr, WNT_BTN_SURRENDER);
    jBtnSurr = NuiEnabled(jBtnSurr, NuiBind(WNT_PANEL_BIND_SURR_EN));
    jBtnSurr = NuiHeight(jBtnSurr, 28.0);

    // Close button.
    json jBtnClose = NuiButton(JsonString("Zamknij"));
    jBtnClose = NuiId(jBtnClose, WNT_BTN_CLOSE);
    jBtnClose = NuiHeight(jBtnClose, 28.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHdr);
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 6.0));
    jCol = JsonArrayInsert(jCol, jBody);
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 4.0));
    jCol = JsonArrayInsert(jCol, jHeat);
    jCol = JsonArrayInsert(jCol, jCrimes);
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 10.0));
    jCol = JsonArrayInsert(jCol, jBtnBribe);
    jCol = JsonArrayInsert(jCol, jBtnSurr);
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), 4.0));
    jCol = JsonArrayInsert(jCol, jBtnClose);

    return NuiCol(jCol);
}

// ===========================================================================
// Records Panel lifecycle
// ===========================================================================

void WantedOpenPanel(object oPC)
{
    if(NuiFindWindow(oPC, WNT_PANEL_WIN) != 0) return;

    json jGeom = NuiRect(-1.0, -1.0, WNT_PANEL_W, WNT_PANEL_H);
    json jWin  = NuiWindow(
        BuildWantedPanelLayout(),
        JsonString("Rejestr Kryminalny"),
        NuiBind(WNT_PANEL_BIND_GEOM),
        JsonBool(FALSE),   // resizable
        JsonBool(FALSE),   // collapsed
        JsonBool(TRUE),    // closable — player can X it
        JsonBool(FALSE),   // transparent
        JsonBool(TRUE));   // border

    int nToken = NuiCreate(oPC, jWin, WNT_PANEL_WIN, "lib_wnt_ev");
    if(nToken == 0) return;

    SetLocalInt(oPC, WNT_LVAR_PANEL_TOKEN, nToken);

    string sUuid = GetObjectUUID(oPC);
    struct WantedState s = WantedGetState(sUuid);
    int nHeat = WantedCalcHeat(s);
    int nLvl  = WantedGetLevel(nHeat);

    FeedWantedPanel(oPC, nToken, nHeat, nLvl, s.crimes_committed);
}

void WantedDestroyPanel(object oPC)
{
    int nToken = GetLocalInt(oPC, WNT_LVAR_PANEL_TOKEN);
    if(nToken != 0) NuiDestroy(oPC, nToken);
    DeleteLocalInt(oPC, WNT_LVAR_PANEL_TOKEN);
}

// ===========================================================================
// Records Panel data feed
// ===========================================================================

void FeedWantedPanel(object oPC, int nToken, int nHeat, int nLvl, int nCrimes)
{
    int nBribeCost = nHeat * WNT_BRIBE_COST_PER_HEAT;
    int nSurrCost  = nCrimes * WNT_SURRENDER_PER_CRIME;
    if(nSurrCost < WNT_SURRENDER_MIN_COST) nSurrCost = WNT_SURRENDER_MIN_COST;

    NuiSetBind(oPC, nToken, WNT_PANEL_BIND_HDR,
        JsonString(WantedGetLevelName(nLvl)));
    NuiSetBind(oPC, nToken, WNT_PANEL_BIND_BODY,
        JsonString(WantedGetFlavorText(nLvl)));
    NuiSetBind(oPC, nToken, WNT_PANEL_BIND_HEAT,
        JsonString("Goraczka: " + IntToString(nHeat) + " / 100"));
    NuiSetBind(oPC, nToken, WNT_PANEL_BIND_CRIMES,
        JsonString("Przestepstwa: " + IntToString(nCrimes)));

    string sBribeLabel = nHeat > 0
        ? "Oplac kontrybucie (" + IntToString(nBribeCost) + " zl, -30 goraczki)"
        : "Kontrybucia nieopplacalna";
    NuiSetBind(oPC, nToken, WNT_PANEL_BIND_BRIBE,  JsonString(sBribeLabel));
    NuiSetBind(oPC, nToken, WNT_PANEL_BIND_BRIBE_EN,  JsonBool(nHeat > 0));
    NuiSetBind(oPC, nToken, WNT_PANEL_BIND_SURR_EN,
        JsonBool(nCrimes > 0));
}

// ===========================================================================
// HUD drag-position save (debounced)
// ===========================================================================

void WantedSaveHudPos(object oPC)
{
    DeleteLocalInt(oPC, WNT_LVAR_GEOM_DELAY);

    int nToken = GetLocalInt(oPC, WNT_LVAR_HUD_TOKEN);
    if(nToken == 0) return;

    json jGeom = NuiGetBind(oPC, nToken, WNT_BIND_GEOM);
    if(JsonGetType(jGeom) != JSON_TYPE_OBJECT) return;

    float fX = JsonGetFloat(JsonObjectGet(jGeom, "x"));
    float fY = JsonGetFloat(JsonObjectGet(jGeom, "y"));
    WantedSetUiPos(GetObjectUUID(oPC), fX, fY);
}

// ===========================================================================
// Core gameplay API
// ===========================================================================

// Add nAmt points of heat. Set bIsCrime = TRUE (default) to increment the
// crime counter (affects surrender cost). Call this from any crime hook.
void WantedAddHeat(object oPC, int nAmt, int bIsCrime)
{
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;
    if(nAmt <= 0) return;

    string sUuid = GetObjectUUID(oPC);
    struct WantedState s = WantedGetState(sUuid);
    int nCurrent = WantedCalcHeat(s);
    int nNew     = nCurrent + nAmt;
    if(nNew > WNT_MAX_HEAT) nNew = WNT_MAX_HEAT;

    WantedWriteHeat(sUuid, nNew, WantedNowUnix());
    if(bIsCrime) WantedIncrementCrimes(sUuid);

    int nLvl    = WantedGetLevel(nNew);
    int nOldLvl = s.last_level;
    if(nLvl != nOldLvl)
    {
        WantedApplyEffects(oPC, nLvl);
        WantedWriteLastLevel(sUuid, nLvl);
        FloatingTextStringOnCreature(
            "Jestes teraz " + WantedGetLevelName(nLvl) + "!",
            oPC, FALSE);
    }

    int nHudToken = GetLocalInt(oPC, WNT_LVAR_HUD_TOKEN);
    if(nHudToken != 0)
        FeedWantedHud(oPC, nHudToken, nNew, nLvl);

    int nPanelToken = GetLocalInt(oPC, WNT_LVAR_PANEL_TOKEN);
    if(nPanelToken != 0)
    {
        // Re-read state to get updated crime count.
        struct WantedState sNew = WantedGetState(sUuid);
        FeedWantedPanel(oPC, nPanelToken, nNew, nLvl, sNew.crimes_committed);
    }
}

// Pay gold to reduce heat by WNT_BRIBE_REDUCTION.
// Cost = current_heat * WNT_BRIBE_COST_PER_HEAT.
void WantedBribe(object oPC)
{
    if(!GetIsPC(oPC)) return;

    string sUuid = GetObjectUUID(oPC);
    struct WantedState s = WantedGetState(sUuid);
    int nHeat = WantedCalcHeat(s);
    if(nHeat <= 0) return;

    int nCost = nHeat * WNT_BRIBE_COST_PER_HEAT;
    if(GetGold(oPC) < nCost)
    {
        FloatingTextStringOnCreature(
            "Brakuje ci zlota na kontrybucie (" + IntToString(nCost) + " zl).",
            oPC, FALSE);
        return;
    }

    TakeGoldFromCreature(nCost, oPC, TRUE);

    int nNewHeat = nHeat - WNT_BRIBE_REDUCTION;
    if(nNewHeat < 0) nNewHeat = 0;
    WantedWriteHeat(sUuid, nNewHeat, WantedNowUnix());

    int nLvl = WantedGetLevel(nNewHeat);
    if(nLvl != s.last_level)
    {
        WantedApplyEffects(oPC, nLvl);
        WantedWriteLastLevel(sUuid, nLvl);
    }

    FloatingTextStringOnCreature(
        "Kontrybucia oplacona. Goraczka: " + IntToString(nNewHeat) + ".",
        oPC, FALSE);

    int nHudToken = GetLocalInt(oPC, WNT_LVAR_HUD_TOKEN);
    if(nHudToken != 0)
        FeedWantedHud(oPC, nHudToken, nNewHeat, nLvl);

    int nPanelToken = GetLocalInt(oPC, WNT_LVAR_PANEL_TOKEN);
    if(nPanelToken != 0)
        FeedWantedPanel(oPC, nPanelToken, nNewHeat, nLvl, s.crimes_committed);
}

// Pay per-crime fine, reset heat to 0 and clear the crime record.
// Minimum cost: WNT_SURRENDER_MIN_COST gold.
void WantedSurrender(object oPC)
{
    if(!GetIsPC(oPC)) return;

    string sUuid = GetObjectUUID(oPC);
    struct WantedState s = WantedGetState(sUuid);
    if(s.crimes_committed <= 0) return;

    int nCost = s.crimes_committed * WNT_SURRENDER_PER_CRIME;
    if(nCost < WNT_SURRENDER_MIN_COST) nCost = WNT_SURRENDER_MIN_COST;

    if(GetGold(oPC) < nCost)
    {
        FloatingTextStringOnCreature(
            "Nie mozesz pokryc kary (" + IntToString(nCost) + " zl).",
            oPC, FALSE);
        return;
    }

    TakeGoldFromCreature(nCost, oPC, TRUE);
    WantedWriteHeat(sUuid, 0, WantedNowUnix());
    WantedResetCrimes(sUuid);
    WantedWriteLastLevel(sUuid, WNT_LVL_CLEAN);
    WantedApplyEffects(oPC, WNT_LVL_CLEAN);

    FloatingTextStringOnCreature(
        "Oddales sie w rece prawa. Karta przestepstw wyczyszczona.",
        oPC, FALSE);

    int nHudToken = GetLocalInt(oPC, WNT_LVAR_HUD_TOKEN);
    if(nHudToken != 0)
        FeedWantedHud(oPC, nHudToken, 0, WNT_LVL_CLEAN);

    int nPanelToken = GetLocalInt(oPC, WNT_LVAR_PANEL_TOKEN);
    if(nPanelToken != 0)
        FeedWantedPanel(oPC, nPanelToken, 0, WNT_LVL_CLEAN, 0);
}

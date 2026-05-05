// =============================================================================
// lib_rations.nss
// =============================================================================
// HUD UI and gameplay logic for the Rations system.
// Owns:
//   - HUD window (CreateRationsHud / DestroyRationsHud / FeedRationsHud)
//   - 1-second self-loop tick (RationsHudTick) that refreshes binds + reapplies
//     debuffs when the player crosses a threshold
//   - Item consumption (RationsTryEatItem) called from OnActivateItem
//   - Death reset (RationsOnPlayerDeath)
//   - Drag debounce save (RationsSaveHudPos)
// =============================================================================

#include "lib_rations_def"
#include "lib_nui"

// Forward declarations (callers above definitions).
void RationsHudTick(object oPC);
void FeedRationsHud(object oPC, int nToken);

// -----------------------------------------------------------------------------
// HUD layout
// -----------------------------------------------------------------------------
// Build a single hunger-or-thirst row: [icon] [progress bar] [percentage]
json BuildRationsRow(string sIconBind, string sBarBind, string sLblBind,
                    string sColorBind, string sTipBind, string sRowId)
{
    json jIcon = NuiImage(NuiBind(sIconBind),
        JsonInt(NUI_ASPECT_FIT),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jIcon = NuiWidth(jIcon,  RAT_HUD_ICON);
    jIcon = NuiHeight(jIcon, RAT_HUD_ICON);
    jIcon = NuiTooltip(jIcon, NuiBind(sTipBind));

    json jBar = NuiProgress(NuiBind(sBarBind));
    jBar = NuiHeight(jBar, RAT_HUD_BAR_H);
    jBar = NuiStyleForegroundColor(jBar, NuiBind(sColorBind));
    jBar = NuiTooltip(jBar, NuiBind(sTipBind));

    json jPct = NuiLabel(NuiBind(sLblBind),
        JsonInt(NUI_HALIGN_RIGHT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jPct = NuiWidth(jPct, 40.0);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jIcon);
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), 6.0));
    jRow = JsonArrayInsert(jRow, jBar);
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), 4.0));
    jRow = JsonArrayInsert(jRow, jPct);

    return NuiId(NuiRow(jRow), sRowId);
}

json BuildRationsHudLayout()
{
    json jRowH = BuildRationsRow(
        RAT_BIND_ICON_H, RAT_BIND_BAR_H, RAT_BIND_LBL_H,
        RAT_BIND_COLOR_H, RAT_BIND_TIP_H, RAT_HUD_ROW_H);

    json jRowT = BuildRationsRow(
        RAT_BIND_ICON_T, RAT_BIND_BAR_T, RAT_BIND_LBL_T,
        RAT_BIND_COLOR_T, RAT_BIND_TIP_T, RAT_HUD_ROW_T);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jRowH);
    jCol = JsonArrayInsert(jCol, jRowT);
    return NuiCol(jCol);
}

// -----------------------------------------------------------------------------
// HUD lifecycle
// -----------------------------------------------------------------------------
void CreateRationsHud(object oPC)
{
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    // Already open?
    if(NuiFindWindow(oPC, RAT_HUD_WIN) != 0) return;

    string sUuid = GetObjectUUID(oPC);
    struct RationsUi sUi = RationsGetUi(sUuid);
    if(!sUi.visible) return;

    // Use saved position if it exists; otherwise -1/-1 lets NUI auto-place
    // the window. The player can then drag it; the saved position is used on
    // subsequent logins.
    float fX = sUi.x;
    float fY = sUi.y;

    json jGeom = NuiRect(fX, fY, RAT_HUD_W, RAT_HUD_H);
    json jWin  = NuiWindow(BuildRationsHudLayout(),
        JsonString("Rations"),     // title bar = drag handle
        NuiBind(RAT_BIND_GEOM),    // bound geom (drag updates the bind)
        JsonBool(FALSE),           // resizable
        JsonBool(FALSE),           // collapsed
        JsonBool(FALSE),           // closable
        JsonBool(FALSE),           // transparent (solid background)
        JsonBool(TRUE));           // border

    int nToken = NuiCreate(oPC, jWin, RAT_HUD_WIN, "lib_rations_ev");
    if(nToken == 0) return;

    NuiSetBind(oPC, nToken, RAT_BIND_GEOM, jGeom);
    NuiSetBindWatch(oPC, nToken, RAT_BIND_GEOM, TRUE);
    SetLocalInt(oPC, RAT_LVAR_HUD_TOKEN, nToken);

    FeedRationsHud(oPC, nToken);

    // Guard against double-chained ticks on reconnect.
    if(!GetLocalInt(oPC, RAT_LVAR_TICK_GUARD))
    {
        SetLocalInt(oPC, RAT_LVAR_TICK_GUARD, 1);
        DelayCommand(1.0, RationsHudTick(oPC));
    }
}

void DestroyRationsHud(object oPC)
{
    int nToken = GetLocalInt(oPC, RAT_LVAR_HUD_TOKEN);
    if(nToken != 0) NuiDestroy(oPC, nToken);
    DeleteLocalInt(oPC, RAT_LVAR_HUD_TOKEN);
    DeleteLocalInt(oPC, RAT_LVAR_GEOM_DELAY);
    DeleteLocalInt(oPC, RAT_LVAR_TICK_GUARD);
}

// -----------------------------------------------------------------------------
// HUD feed
// -----------------------------------------------------------------------------
void FeedRationsHud(object oPC, int nToken)
{
    // Internal storage: satiation 0..100 (100 = full belly, 0 = starving).
    // Bar / label show satiation (full bar = full belly).
    // Tooltip shows the inverse "hunger %" because that is what the threshold
    // names refer to (Starving = high hunger, not high satiation).
    int nH = RationsGetCurrentHunger(oPC);
    int nT = RationsGetCurrentThirst(oPC);
    int nLvlH = RationsGetThresholdLevel(nH);
    int nLvlT = RationsGetThresholdLevel(nT);

    NuiSetBind(oPC, nToken, RAT_BIND_BAR_H, JsonFloat(IntToFloat(nH) / IntToFloat(RAT_MAX)));
    NuiSetBind(oPC, nToken, RAT_BIND_BAR_T, JsonFloat(IntToFloat(nT) / IntToFloat(RAT_MAX)));

    NuiSetBind(oPC, nToken, RAT_BIND_LBL_H, JsonString(IntToString(nH) + "%"));
    NuiSetBind(oPC, nToken, RAT_BIND_LBL_T, JsonString(IntToString(nT) + "%"));

    NuiSetBind(oPC, nToken, RAT_BIND_ICON_H, JsonString(RationsGetIconResrefH(nLvlH)));
    NuiSetBind(oPC, nToken, RAT_BIND_ICON_T, JsonString(RationsGetIconResrefT(nLvlT)));

    int nRgbH = RationsGetThresholdColorRGB(nLvlH);
    int nRgbT = RationsGetThresholdColorRGB(nLvlT);
    NuiSetBind(oPC, nToken, RAT_BIND_COLOR_H,
        NuiColor((nRgbH >> 16) & 0xFF, (nRgbH >> 8) & 0xFF, nRgbH & 0xFF));
    NuiSetBind(oPC, nToken, RAT_BIND_COLOR_T,
        NuiColor((nRgbT >> 16) & 0xFF, (nRgbT >> 8) & 0xFF, nRgbT & 0xFF));

    string sTipH = RationsGetThresholdNameH(nLvlH) + " ("
        + IntToString(RAT_MAX - nH) + "% hunger). Eat food to keep it low.";
    string sTipT = RationsGetThresholdNameT(nLvlT) + " ("
        + IntToString(RAT_MAX - nT) + "% thirst). Drink to keep it low.";
    NuiSetBind(oPC, nToken, RAT_BIND_TIP_H, JsonString(sTipH));
    NuiSetBind(oPC, nToken, RAT_BIND_TIP_T, JsonString(sTipT));
}

// -----------------------------------------------------------------------------
// 1-second tick: refresh UI, reapply debuffs on threshold change.
// -----------------------------------------------------------------------------
void RationsHudTick(object oPC)
{
    if(!GetIsPC(oPC) || !GetIsObjectValid(oPC)) return;

    int nToken = GetLocalInt(oPC, RAT_LVAR_HUD_TOKEN);
    if(nToken == 0) return;

    // If player has the window closed somehow, stop ticking.
    if(NuiFindWindow(oPC, RAT_HUD_WIN) == 0)
    {
        DeleteLocalInt(oPC, RAT_LVAR_HUD_TOKEN);
        return;
    }

    FeedRationsHud(oPC, nToken);

    // Threshold cross detection: read cached level vs current.
    string sUuid = GetObjectUUID(oPC);
    int nNowH = RationsGetThresholdLevel(RationsGetCurrentHunger(oPC));
    int nNowT = RationsGetThresholdLevel(RationsGetCurrentThirst(oPC));
    int nWasH = RationsGetLastThH(sUuid);
    int nWasT = RationsGetLastThT(sUuid);

    if(nNowH != nWasH)
    {
        RationsApplyDebuffH(oPC, nNowH);
        RationsSetLastThH(sUuid, nNowH);
        if(nNowH < nWasH)
        {
            FloatingTextStringOnCreature(
                "You are now " + RationsGetThresholdNameH(nNowH) + ".",
                oPC, FALSE);
        }
    }
    if(nNowT != nWasT)
    {
        RationsApplyDebuffT(oPC, nNowT);
        RationsSetLastThT(sUuid, nNowT);
        if(nNowT < nWasT)
        {
            FloatingTextStringOnCreature(
                "You are now " + RationsGetThresholdNameT(nNowT) + ".",
                oPC, FALSE);
        }
    }

    DelayCommand(1.0, RationsHudTick(oPC));
}

// -----------------------------------------------------------------------------
// Item consumption (called from OnActivateItem)
// -----------------------------------------------------------------------------
int RationsTryEatItem(object oPC, object oItem)
{
    if(!GetIsObjectValid(oPC) || !GetIsObjectValid(oItem)) return FALSE;
    if(GetIsDM(oPC)) return FALSE;

    int nH = RationsGetItemRestoreH(oItem);
    int nT = RationsGetItemRestoreT(oItem);
    if(nH <= 0 && nT <= 0) return FALSE;

    if(nH > 0) RationsAddHunger(oPC, nH);
    if(nT > 0) RationsAddThirst(oPC, nT);

    string sMsg = "You consume " + GetName(oItem) + ".";
    if(nH > 0 && nT > 0)
        sMsg += " (+" + IntToString(nH) + " food, +" + IntToString(nT) + " water)";
    else if(nH > 0)
        sMsg += " (+" + IntToString(nH) + " food)";
    else
        sMsg += " (+" + IntToString(nT) + " water)";

    FloatingTextStringOnCreature(sMsg, oPC, FALSE);

    RationsRemoveOneFromStack(oItem);

    // Immediate UI refresh + threshold reapply.
    int nToken = GetLocalInt(oPC, RAT_LVAR_HUD_TOKEN);
    if(nToken != 0) FeedRationsHud(oPC, nToken);

    string sUuid = GetObjectUUID(oPC);
    int nLvlH = RationsGetThresholdLevel(RationsGetCurrentHunger(oPC));
    int nLvlT = RationsGetThresholdLevel(RationsGetCurrentThirst(oPC));
    if(nLvlH != RationsGetLastThH(sUuid))
    {
        RationsApplyDebuffH(oPC, nLvlH);
        RationsSetLastThH(sUuid, nLvlH);
    }
    if(nLvlT != RationsGetLastThT(sUuid))
    {
        RationsApplyDebuffT(oPC, nLvlT);
        RationsSetLastThT(sUuid, nLvlT);
    }
    return TRUE;
}

// -----------------------------------------------------------------------------
// Death reset (called from OnPlayerDeath)
// -----------------------------------------------------------------------------
void RationsOnPlayerDeath(object oPC)
{
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    RationsSetHungerValue(oPC, RAT_DEATH_RESET);
    RationsSetThirstValue(oPC, RAT_DEATH_RESET);

    string sUuid = GetObjectUUID(oPC);
    int nLvlH = RationsGetThresholdLevel(RAT_DEATH_RESET);
    int nLvlT = RationsGetThresholdLevel(RAT_DEATH_RESET);
    RationsApplyDebuffH(oPC, nLvlH);
    RationsApplyDebuffT(oPC, nLvlT);
    RationsSetLastThH(sUuid, nLvlH);
    RationsSetLastThT(sUuid, nLvlT);

    int nToken = GetLocalInt(oPC, RAT_LVAR_HUD_TOKEN);
    if(nToken != 0) FeedRationsHud(oPC, nToken);
}

// -----------------------------------------------------------------------------
// Drag debounce: read the geometry bind 0.5s after the watch event fires.
// -----------------------------------------------------------------------------
void RationsSaveHudPos(object oPC)
{
    DeleteLocalInt(oPC, RAT_LVAR_GEOM_DELAY);

    int nToken = GetLocalInt(oPC, RAT_LVAR_HUD_TOKEN);
    if(nToken == 0) return;

    json jGeom = NuiGetBind(oPC, nToken, RAT_BIND_GEOM);
    if(JsonGetType(jGeom) != JSON_TYPE_OBJECT) return;

    float fX = JsonGetFloat(JsonObjectGet(jGeom, "x"));
    float fY = JsonGetFloat(JsonObjectGet(jGeom, "y"));
    RationsSetUiPos(GetObjectUUID(oPC), fX, fY);
}

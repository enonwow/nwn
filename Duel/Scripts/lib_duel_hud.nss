// lib_duel_hud.nss
// Honor Duels - small overlay window showing HP bars during an active duel.
// Position is loaded from / saved to SQL per PC.
//
// Self-contained: owns all HUD-only constants. Included by lib_duel_def
// (one-way) so that flow logic can call CreateDuelHud / DestroyDuelHud.
#include "lib_nui"
#include "sql_duel"

// ============================================================
// HUD-only constants (referenced from def via include)
// ============================================================
const string DUEL_WIN_HUD              = "DUEL_WIN_HUD";
const string DUEL_EV_SCRIPT            = "lib_duel_ev";

const float  DUEL_HUD_W                = 240.0;
const float  DUEL_HUD_H                = 180.0;

const string DUEL_BIND_HUD_TITLE       = "duel_hud_title";
const string DUEL_BIND_HUD_OPP_HP      = "duel_hud_opp_hp";
const string DUEL_BIND_HUD_OPP_HP_TIP  = "duel_hud_opp_hp_tip";
const string DUEL_BIND_HUD_SELF_HP     = "duel_hud_self_hp";
const string DUEL_BIND_HUD_SELF_HP_TIP = "duel_hud_self_hp_tip";
const string DUEL_BIND_HUD_BOUNDS      = "duel_hud_bounds";
const string DUEL_BIND_HUD_GEOM        = "duel_hud_geom";

void DestroyDuelHud(object oPC)
{
    int nTk = NuiFindWindow(oPC, DUEL_WIN_HUD);
    if(nTk != 0) NuiDestroy(oPC, nTk);
}

void CreateDuelHud(object oPC, int nDuelId)
{
    DestroyDuelHud(oPC);

    float fW    = GetNuiScaleDimension(oPC, DUEL_HUD_W);
    float fH    = GetNuiScaleDimension(oPC, DUEL_HUD_H);
    float fBarH = GetNuiScaleDimension(oPC, 18.0);
    float fLblH = GetNuiScaleDimension(oPC, 22.0);

    json jOppLbl = NuiLabel(JsonString("Opponent"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jOppLbl = NuiHeight(jOppLbl, fLblH);
    json jOppBar = NuiProgress(NuiBind(DUEL_BIND_HUD_OPP_HP));
    jOppBar = NuiTooltip(jOppBar, NuiBind(DUEL_BIND_HUD_OPP_HP_TIP));
    jOppBar = NuiHeight(jOppBar, fBarH);

    json jSelfLbl = NuiLabel(JsonString("You"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSelfLbl = NuiHeight(jSelfLbl, fLblH);
    json jSelfBar = NuiProgress(NuiBind(DUEL_BIND_HUD_SELF_HP));
    jSelfBar = NuiTooltip(jSelfBar, NuiBind(DUEL_BIND_HUD_SELF_HP_TIP));
    jSelfBar = NuiHeight(jSelfBar, fBarH);

    json jBounds = NuiLabel(NuiBind(DUEL_BIND_HUD_BOUNDS),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jBounds = NuiHeight(jBounds, fLblH);
    jBounds = NuiStyleForegroundColor(jBounds, NuiColor(220, 60, 60));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jOppLbl);
    jCol = JsonArrayInsert(jCol, jOppBar);
    jCol = JsonArrayInsert(jCol, jSelfLbl);
    jCol = JsonArrayInsert(jCol, jSelfBar);
    jCol = JsonArrayInsert(jCol, jBounds);

    json jRoot = NuiCol(jCol);

    // Position from SQL or default top-left.
    float fX = 20.0;
    float fY = 60.0;
    json jPos = DuelUiLoadPosition(GetObjectUUID(oPC));
    if(JsonGetType(jPos) != JSON_TYPE_NULL)
    {
        fX = JsonGetFloat(JsonObjectGet(jPos, "x"));
        fY = JsonGetFloat(JsonObjectGet(jPos, "y"));
    }

    json jNui = NuiWindow(jRoot,
        NuiBind(DUEL_BIND_HUD_TITLE),
        NuiBind(DUEL_BIND_HUD_GEOM),
        JsonBool(FALSE),  // resizable
        JsonBool(FALSE),  // collapsed
        JsonBool(FALSE),  // closable - only via duel end
        JsonBool(FALSE),  // transparent
        JsonBool(TRUE));  // border (draggable title bar)

    int nTk = NuiCreate(oPC, jNui, DUEL_WIN_HUD, DUEL_EV_SCRIPT);

    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_GEOM,        NuiRect(fX, fY, fW, fH));
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_TITLE,       JsonString("Duel"));
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_OPP_HP,      JsonFloat(1.0));
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_SELF_HP,     JsonFloat(1.0));
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_OPP_HP_TIP,  JsonString("100%"));
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_SELF_HP_TIP, JsonString("100%"));
    NuiSetBind(oPC, nTk, DUEL_BIND_HUD_BOUNDS,      JsonString(""));

    NuiSetBindWatch(oPC, nTk, DUEL_BIND_HUD_GEOM, TRUE);
}

// Called from event router after a 0.5s delay (NuiGetBind has lag after drag).
void DuelHudSavePosition(object oPC, int nToken)
{
    if(NuiFindWindow(oPC, DUEL_WIN_HUD) != nToken) return;
    json jGeom = NuiGetBind(oPC, nToken, DUEL_BIND_HUD_GEOM);
    if(JsonGetType(jGeom) == JSON_TYPE_NULL) return;
    float fX = JsonGetFloat(JsonArrayGet(jGeom, 0));
    float fY = JsonGetFloat(JsonArrayGet(jGeom, 1));
    DuelUiSavePosition(GetObjectUUID(oPC), fX, fY);
}

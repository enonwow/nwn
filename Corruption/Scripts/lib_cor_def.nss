// lib_cor_def.nss  –  Corruption: constants, stage definitions, bind IDs

#include "lib_nui"
#include "sql_cor"

// Forward declarations (implemented in lib_cor.nss)
void CorOpenWindow(object oPC);
void CorRefreshWindow(object oPC);
void CorApplyEffects(object oPC);
void CorRemoveEffects(object oPC);
void CorGainCorruption(object oPC, int nAmount, string sFlavor);
void CorReduceCorruption(object oPC, int nAmount);

// ================================================================
// Stage constants
// ================================================================

const int COR_STAGE_PURE    = 0;  //  0-19
const int COR_STAGE_TAINTED = 1;  // 20-39
const int COR_STAGE_FALLEN  = 2;  // 40-59
const int COR_STAGE_CURSED  = 3;  // 60-79
const int COR_STAGE_DAMNED  = 4;  // 80-100

// ================================================================
// NUI window / group / event script IDs
// ================================================================

const string COR_WINDOW   = "COR_WINDOW";
const string COR_EV       = "lib_cor_ev";
const string COR_WIN_GEOM = "cor_win_geom";
const string COR_GRP_MAIN = "cor_grp_main";

// ================================================================
// Bind names
// ================================================================

const string COR_BIND_STAGE_LBL   = "cor_stage_lbl";
const string COR_BIND_VALUE_LBL   = "cor_value_lbl";
const string COR_BIND_BAR_VAL     = "cor_bar_val";
const string COR_BIND_FLAVOR_LBL  = "cor_flavor";
const string COR_BIND_PENALTY_LBL = "cor_penalty";
const string COR_BIND_RITUAL_ENA  = "cor_ritual_ena";
const string COR_BIND_RITUAL_LBL  = "cor_ritual_lbl";
const string COR_BIND_COOLDOWN_LBL= "cor_cooldown";

// ================================================================
// Button IDs
// ================================================================

const string COR_BTN_RITUAL = "cor_btn_ritual";
const string COR_BTN_CLOSE  = "cor_btn_close";
const string COR_BTN_HWATER = "cor_btn_hwater";

// ================================================================
// Local variables on PC
// ================================================================

const string COR_LVAR_CORRUPTION = "COR_VALUE";    // cached int (synced from DB on enter)
const string COR_LVAR_DIRTY      = "COR_DIRTY";    // 1 = effects need reapplication

// ================================================================
// Item / area tags recognised by the module
// ================================================================

// Usable item that reduces corruption by COR_HWATER_REDUCTION points.
const string COR_TAG_HOLY_WATER = "cor_holy_water";
// Area variable name: set LVAR = 1 on area to treat it as a sanctuary for rest.
const string COR_LVAR_AREA_SANCTUARY = "COR_AREA_SANCTUARY";
// Item variable name: set this LVAR to a positive int on any item to make it
// a "dark artifact" that raises corruption when acquired/equipped.
const string COR_IVAR_DARK_ARTIFACT  = "COR_DARK_ARTIFACT";

// ================================================================
// Tuning constants
// ================================================================

const int COR_RITUAL_GOLD_COST   = 500;   // gp to perform cleansing ritual
const int COR_RITUAL_COOLDOWN    = 86400; // seconds (24 h)
const int COR_RITUAL_REDUCTION   = 15;
const int COR_HWATER_REDUCTION   = 10;
const int COR_SANCTUARY_REDUCTION= 3;     // per rest in sanctuary area
const int COR_NEUTRAL_KILL_GAIN  = 8;     // killing neutral/friendly NPC
const int COR_DARK_ARTIFACT_GAIN = 5;     // per dark artifact picked up

// ================================================================
// Layout dimensions
// ================================================================

const float COR_W = 420.0;
const float COR_H = 390.0;

// ================================================================
// Effect tag
// ================================================================

const string COR_EFFECT_TAG = "COR_EFFECT";

// ================================================================
// Stage helpers
// ================================================================

int CorGetStage(int nCorruption)
{
    if(nCorruption >= 80) return COR_STAGE_DAMNED;
    if(nCorruption >= 60) return COR_STAGE_CURSED;
    if(nCorruption >= 40) return COR_STAGE_FALLEN;
    if(nCorruption >= 20) return COR_STAGE_TAINTED;
    return COR_STAGE_PURE;
}

string CorStageName(int nStage)
{
    switch(nStage)
    {
        case COR_STAGE_PURE:    return "Nieskażony";
        case COR_STAGE_TAINTED: return "Skażony";
        case COR_STAGE_FALLEN:  return "Upadły";
        case COR_STAGE_CURSED:  return "Przeklęty";
        case COR_STAGE_DAMNED:  return "Potępiony";
    }
    return "-";
}

string CorStageFlavor(int nStage)
{
    switch(nStage)
    {
        case COR_STAGE_PURE:
            return "Twoja dusza płonie słabym, lecz czystym światłem.\nDemony cię omijają.";
        case COR_STAGE_TAINTED:
            return "Cień zagościł w twoim sercu.\nNocami śnią ci się twarze tych, których skrzywdziłeś.";
        case COR_STAGE_FALLEN:
            return "Mrok wypełnił połowę twego jestestwa.\nKapłani odwracają wzrok gdy przechodzisz obok.";
        case COR_STAGE_CURSED:
            return "Twoja obecność mrozi krew w żyłach przechodniów.\nAnioły nie słyszą już twoich próśb.";
        case COR_STAGE_DAMNED:
            return "Dusza twoja jest przegniła do cna.\nZbawienie wymaga cudu albo ofiary, jakiej jeszcze nie złożyłeś.";
    }
    return "";
}

string CorStagePenalties(int nStage)
{
    switch(nStage)
    {
        case COR_STAGE_PURE:    return "Brak kar.";
        case COR_STAGE_TAINTED: return "• -1 do Charyzmy";
        case COR_STAGE_FALLEN:  return "• -2 do Charyzmy\n• -1 do Mądrości";
        case COR_STAGE_CURSED:  return "• -4 do Charyzmy\n• -2 do Mądrości\n• Aura nieczystości (efekt wizualny)";
        case COR_STAGE_DAMNED:  return "• -6 do Charyzmy\n• -4 do Mądrości\n• -2 do Siły\n• Aura grozy (efekt wizualny)";
    }
    return "";
}

// Returns a NuiColor representing the stage (dark-to-red palette).
json CorStageColor(int nStage)
{
    switch(nStage)
    {
        case COR_STAGE_PURE:    return NuiColor(160, 200, 255, 255);
        case COR_STAGE_TAINTED: return NuiColor(210, 180,  80, 255);
        case COR_STAGE_FALLEN:  return NuiColor(210, 110,  40, 255);
        case COR_STAGE_CURSED:  return NuiColor(190,  50, 190, 255);
        case COR_STAGE_DAMNED:  return NuiColor(230,  30,  30, 255);
    }
    return NuiColor(180, 180, 180, 255);
}

#include "lib_nui"
#include "sql_mia"

// Forward declarations
void MiaTick(object oPC);
void MiaShowGauge(object oPC);
void MiaHideGauge(object oPC);
void MiaFeedGauge(object oPC, int nToken);
void MiaRemoveEffects(object oPC);
void MiaApplyEffects(object oPC, int nExposure, int nType);
void MiaCreateDmPanel(object oPC);
void MiaFeedDmPanel(object oPC, int nToken);

// ----------------------------------------------------------------
// Window / event identifiers
// ----------------------------------------------------------------

const string MIA_WINDOW         = "MIA_GAUGE";
const string MIA_EV_SCRIPT      = "lib_mia_ev";
const string MIA_WIN_DM         = "MIA_DM";

// ----------------------------------------------------------------
// Gauge HUD binds  (small persistent overlay, top-right)
// ----------------------------------------------------------------

const string MIA_BIND_GEOM      = "mia_geom";
const string MIA_BIND_BAR       = "mia_bar";
const string MIA_BIND_BAR_COLOR = "mia_bar_color";
const string MIA_BIND_HEADER    = "mia_header";
const string MIA_BIND_SEVERITY  = "mia_severity";
const string MIA_BIND_TIP       = "mia_tip";

// ----------------------------------------------------------------
// DM panel binds
// ----------------------------------------------------------------

const string MIA_BIND_DM_GEOM    = "mia_dm_geom";
const string MIA_BIND_DM_AREA    = "mia_dm_area";
const string MIA_BIND_DM_INTENS  = "mia_dm_intens";
const string MIA_BIND_DM_TYPE    = "mia_dm_type";
const string MIA_BIND_DM_ROWAREA = "mia_dm_rowarea";
const string MIA_BIND_DM_ROWINT  = "mia_dm_rowint";
const string MIA_BIND_DM_ROWTYPE = "mia_dm_rowtype";
const string MIA_BIND_DM_ROWENC  = "mia_dm_rowenc";
const string MIA_BIND_DM_MSG     = "mia_dm_msg";
const string MIA_BIND_DM_ROWCNT  = "mia_dm_rowcnt";
const string MIA_BIND_DM_SETENA  = "mia_dm_setena";

// ----------------------------------------------------------------
// Buttons
// ----------------------------------------------------------------

const string MIA_BTN_CLOSE       = "mia_btn_close";
const string MIA_BTN_CLEANSE     = "mia_btn_cleanse";
const string MIA_BTN_DM_SET      = "mia_btn_dm_set";
const string MIA_BTN_DM_CLEAR    = "mia_btn_dm_clear";
const string MIA_BTN_DM_CLOSE    = "mia_btn_dm_close";
const string MIA_BTN_DM_ROW      = "mia_btn_dm_row";
const string MIA_BTN_DM_CURAREA  = "mia_btn_dm_curarea";

// ----------------------------------------------------------------
// LVARs on PC
// ----------------------------------------------------------------

const string MIA_LVAR_EXPOSURE   = "MIA_EXPOSURE";
const string MIA_LVAR_TYPE       = "MIA_TYPE";
const string MIA_LVAR_TICKING    = "MIA_TICKING";
const string MIA_LVAR_LAST_LVL   = "MIA_LAST_LVL";
const string MIA_LVAR_DM_SEL     = "MIA_DM_SEL";   // selected area_tag in DM panel

// Effect tag so we can remove our own effects cleanly
const string MIA_EFFECT_TAG      = "MIA_DEBUFF";

// ----------------------------------------------------------------
// Miasma types
// ----------------------------------------------------------------

const int MIA_TYPE_NECROTIC      = 1;  // graveyard, undead ritual sites
const int MIA_TYPE_SWAMP         = 2;  // rotting marshes, plague pits
const int MIA_TYPE_DEMONIC       = 3;  // hellfire, corruption rifts

// ----------------------------------------------------------------
// Tick + exposure constants
// ----------------------------------------------------------------

const float MIA_TICK_DELAY       = 6.0;  // seconds between ticks
const int   MIA_MAX_EXPOSURE     = 100;
const int   MIA_DECAY_PER_TICK   = 8;    // exposure lost per tick when outside tainted zone

// Severity thresholds
const int   MIA_LVL_NONE         = 0;
const int   MIA_LVL_MILD         = 1;   // exposure >= 20
const int   MIA_LVL_MODERATE     = 2;   // exposure >= 50
const int   MIA_LVL_SEVERE       = 3;   // exposure >= 80

// Cleansing herb resref (must exist in hak)
const string MIA_ITEM_HERB       = "mia_herb_clns";

// ----------------------------------------------------------------
// Small helpers — type/severity display strings
// ----------------------------------------------------------------

string MiaTypeName(int nType)
{
    if(nType == MIA_TYPE_NECROTIC) return "Nekrotyczny";
    if(nType == MIA_TYPE_SWAMP)    return "Bagnienny";
    if(nType == MIA_TYPE_DEMONIC)  return "Demoniczny";
    return "Nieznany";
}

string MiaSeverityName(int nLvl)
{
    if(nLvl == MIA_LVL_MILD)     return "Łagodny";
    if(nLvl == MIA_LVL_MODERATE) return "Umiarkowany";
    if(nLvl == MIA_LVL_SEVERE)   return "Silny";
    return "";
}

int MiaExposureToLevel(int nExposure)
{
    if(nExposure >= 80) return MIA_LVL_SEVERE;
    if(nExposure >= 50) return MIA_LVL_MODERATE;
    if(nExposure >= 20) return MIA_LVL_MILD;
    return MIA_LVL_NONE;
}

// Returns the bar progress value (0.0–1.0) for NuiProgress
float MiaExposureToProgress(int nExposure)
{
    return IntToFloat(nExposure) / IntToFloat(MIA_MAX_EXPOSURE);
}

json MiaLevelColor(int nLvl)
{
    if(nLvl == MIA_LVL_SEVERE)   return NuiColor(220, 60,  60);   // red
    if(nLvl == MIA_LVL_MODERATE) return NuiColor(220, 150, 50);   // orange
    if(nLvl == MIA_LVL_MILD)     return NuiColor(170, 220, 100);  // yellow-green
    return NuiColor(100, 180, 100);                                  // green (decaying)
}

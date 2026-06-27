#include "lib_nui"
#include "sql_sea"

// Forward declarations
void SeaApplyWeatherEffects(object oPC);
void SeaRemoveWeatherEffects(object oPC);
void SeaOpenWindow(object oPC);
void SeaFeedDMWindow(object oPC, int nToken);
void SeaFeedPlayerWindow(object oPC, int nToken);
void SeaUpdateAllPCs();
void SeaUpdateAllWindows();
void SeaNotifyAll(string sMsg);

// ----------------------------------------------------------------
// Season constants
// ----------------------------------------------------------------
const int SEA_SEASON_SPRING  = 0;
const int SEA_SEASON_SUMMER  = 1;
const int SEA_SEASON_AUTUMN  = 2;
const int SEA_SEASON_WINTER  = 3;
const int SEA_SEASON_DYING   = 4; // Tydzień Umierającego Boga — brief transition
const int SEA_SEASON_COUNT   = 5;

// ----------------------------------------------------------------
// Weather constants
// ----------------------------------------------------------------
const int SEA_WEATHER_CLEAR    = 0;
const int SEA_WEATHER_OVERCAST = 1;
const int SEA_WEATHER_RAIN     = 2;
const int SEA_WEATHER_STORM    = 3;
const int SEA_WEATHER_SNOW     = 4;
const int SEA_WEATHER_BLIZZARD = 5;
const int SEA_WEATHER_DROUGHT  = 6;
const int SEA_WEATHER_COUNT    = 7;

// ----------------------------------------------------------------
// Climate zone constants
// ----------------------------------------------------------------
const int SEA_CLIMATE_TEMPERATE = 0;
const int SEA_CLIMATE_ARCTIC    = 1;
const int SEA_CLIMATE_DESERT    = 2;
const int SEA_CLIMATE_COASTAL   = 3;
const int SEA_CLIMATE_CURSED    = 4;
const int SEA_CLIMATE_COUNT     = 5;

// ----------------------------------------------------------------
// Timing (real seconds)
// ----------------------------------------------------------------
const int   SEA_SEASON_DURATION  = 604800; // 7 days per season
const int   SEA_WEATHER_INTERVAL = 10800;  // weather changes every 3 hours
const float SEA_TICK_INTERVAL    = 60.0;   // heartbeat period

// ----------------------------------------------------------------
// NUI window identifiers
// ----------------------------------------------------------------
const string SEA_WIN_PLAYER  = "SEA_WIN_PLAYER";
const string SEA_WIN_DM      = "SEA_WIN_DM";
const string SEA_EV_SCRIPT   = "lib_sea_ev";

// ----------------------------------------------------------------
// NUI bind names — player window
// ----------------------------------------------------------------
const string SEA_BIND_SEASON_LBL  = "sea_season_lbl";
const string SEA_BIND_WEATHER_LBL = "sea_weather_lbl";
const string SEA_BIND_EFFECT_LBL  = "sea_effect_lbl";
const string SEA_BIND_NEXTCH_LBL  = "sea_nextch_lbl";

// ----------------------------------------------------------------
// NUI bind names — DM window
// ----------------------------------------------------------------
const string SEA_BIND_DM_SEA_LBL  = "sea_dm_sea_lbl";
const string SEA_BIND_DM_WEA_LBL  = "sea_dm_wea_lbl";
const string SEA_BIND_DM_AREA_LBL = "sea_dm_area_lbl";

// ----------------------------------------------------------------
// NUI button IDs — player window
// ----------------------------------------------------------------
const string SEA_BTN_CLOSE        = "sea_btn_close";

// ----------------------------------------------------------------
// NUI button IDs — DM window
// (climate buttons: SEA_BTN_CLIMATE + IntToString(0..4))
// ----------------------------------------------------------------
const string SEA_BTN_DM_CLOSE   = "sea_dm_close";
const string SEA_BTN_PREV_SEA   = "sea_btn_prev_sea";
const string SEA_BTN_NEXT_SEA   = "sea_btn_next_sea";
const string SEA_BTN_PREV_WEA   = "sea_btn_prev_wea";
const string SEA_BTN_NEXT_WEA   = "sea_btn_next_wea";
const string SEA_BTN_CLIMATE    = "sea_btn_clim"; // + "0".."4"

// ----------------------------------------------------------------
// Effect tag — all weather effects carry this so removal is clean
// ----------------------------------------------------------------
const string SEA_EFFECT_TAG     = "SEA_WEATHER_EFF";

// Module-level flags
const string SEA_LVAR_TICKING   = "SEA_TICKING";

// Window geometry constants
const float SEA_PLY_W  = 300.0;
const float SEA_PLY_H  = 230.0;
const float SEA_DM_W   = 480.0;
const float SEA_DM_H   = 340.0;

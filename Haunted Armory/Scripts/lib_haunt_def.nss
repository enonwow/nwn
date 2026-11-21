#include "lib_nui"
#include "sql_haunt"

void HauntOpenWindow(object oPC, object oWeapon);
void HauntFeedPanel(object oPC, int nToken, object oWeapon);
void HauntApplyEffects(object oPC, object oWeapon);
void HauntRemoveEffects(object oPC, string sItemUUID);
void HauntRecordKill(object oKiller, object oVictim);
void HauntProcessCurse(object oPC);

// ----------------------------------------------------------------
// NUI window identifiers
// ----------------------------------------------------------------

const string HAUNT_WINDOW    = "HAUNT_WINDOW";
const string HAUNT_EV_SCRIPT = "lib_haunt_ev";
const string HAUNT_WIN_GEOM  = "haunt_win_geom";

// ----------------------------------------------------------------
// Bind names
// ----------------------------------------------------------------

const string HAUNT_BIND_TITLE        = "haunt_title";
const string HAUNT_BIND_ITEM_NAME    = "haunt_item_name";
const string HAUNT_BIND_LEVEL_LBL    = "haunt_level_lbl";
const string HAUNT_BIND_KILLS_LBL    = "haunt_kills_lbl";
const string HAUNT_BIND_NEXT_LBL     = "haunt_next_lbl";
const string HAUNT_BIND_BONUS_LBL    = "haunt_bonus_lbl";
const string HAUNT_BIND_WHISPER_LBL  = "haunt_whisper_lbl";
const string HAUNT_BIND_HIST_NAME    = "haunt_hist_name";
const string HAUNT_BIND_HIST_DATE    = "haunt_hist_date";
const string HAUNT_BIND_HIST_RACE    = "haunt_hist_race";
const string HAUNT_BIND_EMBRACE_ENA  = "haunt_embrace_ena";
const string HAUNT_BIND_EMBRACE_LBL  = "haunt_embrace_lbl";
const string HAUNT_BIND_CLEANSE_ENA  = "haunt_cleanse_ena";
const string HAUNT_BIND_STATUS_COLOR = "haunt_status_col";

// ----------------------------------------------------------------
// Button identifiers
// ----------------------------------------------------------------

const string HAUNT_BTN_CLOSE   = "haunt_btn_close";
const string HAUNT_BTN_EMBRACE = "haunt_btn_embrace";
const string HAUNT_BTN_CLEANSE = "haunt_btn_cleanse";

// ----------------------------------------------------------------
// PC local variables
// ----------------------------------------------------------------

const string HAUNT_LVAR_OPEN_UUID = "HAUNT_OPEN_UUID";

// ----------------------------------------------------------------
// Gameplay constants
// ----------------------------------------------------------------

// Prefix of effects applied to the PC (+ item UUID)
const string HAUNT_FX_TAG = "HAUNT_FX_";

// Tag of the cleansing component item
const string HAUNT_CLEANSE_TAG = "haunt_holy_water";

// Kill thresholds per level
const int HAUNT_LVL1_KILLS = 10;
const int HAUNT_LVL2_KILLS = 30;
const int HAUNT_LVL3_KILLS = 75;
const int HAUNT_LVL4_KILLS = 150;
const int HAUNT_LVL5_KILLS = 300;

// ----------------------------------------------------------------
// Window layout constants
// ----------------------------------------------------------------

const float HAUNT_W = 580.0;
const float HAUNT_H = 530.0;

const int HAUNT_HIST_ROWS = 8;

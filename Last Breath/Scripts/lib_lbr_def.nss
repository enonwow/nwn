#include "lib_nui"
#include "sql_lbr"

void LbrOpenWindow(object oPC);
void LbrFeedWindow(object oPC, int nToken);
void LbrHarvestEssence(object oPC, object oCorpse);
void LbrConsumeEssence(object oPC, int nId);

// ----------------------------------------------------------------
// Window / event identifiers
// ----------------------------------------------------------------

const string LBR_WINDOW     = "LBR_WINDOW";
const string LBR_EV_SCRIPT  = "lib_lbr_ev";
const string LBR_WIN_GEOM   = "lbr_win_geom";

// ----------------------------------------------------------------
// List bind IDs
// ----------------------------------------------------------------

const string LBR_BIND_ROW_NAME  = "lbr_row_name";
const string LBR_BIND_ROW_TYPE  = "lbr_row_type";
const string LBR_BIND_ROW_AGE   = "lbr_row_age";
const string LBR_BIND_ROW_ENC   = "lbr_row_enc";
const string LBR_BIND_ROW_COLOR = "lbr_row_color";
const string LBR_BIND_STATUS    = "lbr_status";
const string LBR_BIND_FLAVOR    = "lbr_flavor";
const string LBR_BIND_DRINK_ENA = "lbr_drink_ena";
const string LBR_BIND_DISC_ENA  = "lbr_disc_ena";
const string LBR_BIND_ROWCOUNT  = "lbr_rowcount";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string LBR_BTN_CLOSE   = "lbr_btn_close";
const string LBR_BTN_DRINK   = "lbr_btn_drink";
const string LBR_BTN_DISCARD = "lbr_btn_discard";
const string LBR_BTN_HARVEST = "lbr_btn_harvest";
const string LBR_BTN_ROW     = "lbr_btn_row";

// ----------------------------------------------------------------
// Local vars on PC
// ----------------------------------------------------------------

const string LBR_LVAR_SEL_ID    = "LBR_SEL_ID";
const string LBR_LVAR_TARGETING = "LBR_TARGETING";

// ----------------------------------------------------------------
// Essence type constants
// ----------------------------------------------------------------

const int LBR_ESSENCE_WARRIOR = 1;
const int LBR_ESSENCE_BEAST   = 2;
const int LBR_ESSENCE_UNDEAD  = 3;
const int LBR_ESSENCE_DEMON   = 4;
const int LBR_ESSENCE_DIVINE  = 5;
const int LBR_ESSENCE_ARCANE  = 6;
const int LBR_ESSENCE_UNKNOWN = 7;

// Duration of consumed effects in real-time seconds
const int    LBR_EFFECT_DURATION = 300;

// Max essences held simultaneously
const int    LBR_MAX_ESSENCES    = 5;

// Minimum CR of target for harvest
const int    LBR_MIN_CR          = 3;

// Item tag for the vial consumed during harvest
const string LBR_VIAL_TAG        = "lbr_vial";

// ----------------------------------------------------------------
// Window dimensions
// ----------------------------------------------------------------

const float LBR_W = 480.0;
const float LBR_H = 460.0;

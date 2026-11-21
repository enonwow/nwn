#include "lib_nui"
#include "sql_bur"

void BurCreateWindow(object oPC);
void BurOpenRiteView(object oPC, object oCorpse);
void BurSwapToRegister(object oPC, int nToken);
void BurSwapToRite(object oPC, int nToken);
void BurFeedRegister(object oPC, int nToken);
void BurFeedRite(object oPC, int nToken);
void BurApplyRite(object oPC, int nRiteType, object oCorpse);
void BurDesecrate(object oPC, int nGraveId);
void BurMeditate(object oPC, int nGraveId);
void BurOnPlayerTarget(object oPC);
void BurShowDesecrateConfirm(object oPC, int nGraveId);
string BurRiteName(int nRiteType);
string BurRiteDesc(int nRiteType);

// ----------------------------------------------------------------
// Window / group IDs
// ----------------------------------------------------------------

const string BUR_WIN            = "BUR_WIN";
const string BUR_WIN_DESECRATE  = "BUR_WIN_DES";
const string BUR_EV_SCRIPT      = "lib_bur_ev";
const string BUR_GRP_SWAP       = "BUR_GRP_SWAP";
const string BUR_WIN_GEOM       = "bur_win_geom";

// ----------------------------------------------------------------
// Register view binds
// ----------------------------------------------------------------

const string BUR_BIND_TITLE          = "bur_title";
const string BUR_BIND_ROW_VICTIM     = "bur_row_victim";
const string BUR_BIND_ROW_RITE       = "bur_row_rite";
const string BUR_BIND_ROW_DATE       = "bur_row_date";
const string BUR_BIND_ROW_STATUS     = "bur_row_status";
const string BUR_BIND_ROW_ENC        = "bur_row_enc";
const string BUR_BIND_ROW_COUNT      = "bur_row_count";
const string BUR_BIND_INFO           = "bur_info";
const string BUR_BIND_MEDITATE_ENA   = "bur_med_ena";
const string BUR_BIND_DESECRATE_ENA  = "bur_des_ena";

// ----------------------------------------------------------------
// Rite selection view binds
// ----------------------------------------------------------------

const string BUR_BIND_VICTIM_NAME    = "bur_victim_name";
const string BUR_BIND_RITE0_DESC     = "bur_rite0_desc";
const string BUR_BIND_RITE1_DESC     = "bur_rite1_desc";
const string BUR_BIND_RITE2_DESC     = "bur_rite2_desc";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string BUR_BTN_CLOSE           = "bur_btn_close";
const string BUR_BTN_BURY_NEW        = "bur_btn_burynew";
const string BUR_BTN_ROW             = "bur_btn_row";
const string BUR_BTN_MEDITATE        = "bur_btn_meditate";
const string BUR_BTN_DESECRATE       = "bur_btn_desecrate";
const string BUR_BTN_RITE0           = "bur_btn_rite0";
const string BUR_BTN_RITE1           = "bur_btn_rite1";
const string BUR_BTN_RITE2           = "bur_btn_rite2";
const string BUR_BTN_CANCEL          = "bur_btn_cancel";
const string BUR_BTN_DES_CONFIRM     = "bur_btn_desconf";
const string BUR_BTN_DES_CANCEL      = "bur_btn_descancel";

// ----------------------------------------------------------------
// LVARs on PC
// ----------------------------------------------------------------

const string BUR_LVAR_SEL_GRAVE      = "BUR_SEL_GRAVE";
const string BUR_LVAR_TARGET_OBJ     = "BUR_TARGET_OBJ";
const string BUR_LVAR_VICTIM_NAME    = "BUR_VICTIM_NAME";
const string BUR_LVAR_TARGETING      = "BUR_TARGETING";

// ----------------------------------------------------------------
// Rite type constants
// ----------------------------------------------------------------

const int BUR_RITE_SIMPLE            = 0;
const int BUR_RITE_HONORED           = 1;
const int BUR_RITE_CURSED            = 2;

// ----------------------------------------------------------------
// Gameplay tuning
// ----------------------------------------------------------------

const int   BUR_HONORED_COST         = 100;
const int   BUR_MEDITATE_COOLDOWN    = 86400;
const int   BUR_DESECRATE_GOLD_MIN   = 20;
const int   BUR_DESECRATE_GOLD_MAX   = 80;
const int   BUR_SIMPLE_XP            = 25;
const int   BUR_HONORED_XP           = 50;

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------

const float BUR_W                    = 680.0;
const float BUR_H                    = 480.0;

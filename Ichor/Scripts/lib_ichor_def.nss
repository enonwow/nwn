#include "lib_nui"
#include "sql_ichor"

// ----------------------------------------------------------------
// Window / event-script IDs
// ----------------------------------------------------------------

const string ICHOR_WINDOW           = "ICHOR_WINDOW";
const string ICHOR_EV_SCRIPT        = "lib_ichor_ev";
const string ICHOR_GRP_SWAP         = "ICHOR_GRP_SWAP";
const string ICHOR_WIN_GEOM         = "ichor_win_geom";

// ----------------------------------------------------------------
// Bind names — essence list (array binds)
// ----------------------------------------------------------------

const string ICHOR_BIND_ESS_NAME    = "ichor_ess_name";
const string ICHOR_BIND_ESS_INFO    = "ichor_ess_info";     // "X ład." string
const string ICHOR_BIND_ESS_ENC     = "ichor_ess_enc";
const string ICHOR_BIND_ESS_COLOR   = "ichor_ess_color";
const string ICHOR_BIND_ESS_COUNT   = "ichor_ess_count";    // list row-count bind

// ----------------------------------------------------------------
// Bind names — effect description panel
// ----------------------------------------------------------------

const string ICHOR_BIND_DESC_TITLE  = "ichor_desc_title";
const string ICHOR_BIND_DESC_TEXT   = "ichor_desc_text";

// ----------------------------------------------------------------
// Bind names — weapon + active coatings panel
// ----------------------------------------------------------------

const string ICHOR_BIND_WPN_NAME    = "ichor_wpn_name";
const string ICHOR_BIND_S1_LBL      = "ichor_s1_lbl";
const string ICHOR_BIND_S1_TIMER    = "ichor_s1_timer";
const string ICHOR_BIND_S1_COLOR    = "ichor_s1_color";
const string ICHOR_BIND_S1_REM_ENA  = "ichor_s1_rem_ena";
const string ICHOR_BIND_S2_LBL      = "ichor_s2_lbl";
const string ICHOR_BIND_S2_TIMER    = "ichor_s2_timer";
const string ICHOR_BIND_S2_COLOR    = "ichor_s2_color";
const string ICHOR_BIND_S2_REM_ENA  = "ichor_s2_rem_ena";

const string ICHOR_BIND_APPLY_ENA   = "ichor_apply_ena";
const string ICHOR_BIND_STATUS      = "ichor_status";

// ----------------------------------------------------------------
// Buttons
// ----------------------------------------------------------------

const string ICHOR_BTN_CLOSE        = "ichor_btn_close";
const string ICHOR_BTN_ROW          = "ichor_btn_row";
const string ICHOR_BTN_APPLY        = "ichor_btn_apply";
const string ICHOR_BTN_REM1         = "ichor_btn_rem1";
const string ICHOR_BTN_REM2         = "ichor_btn_rem2";

// ----------------------------------------------------------------
// Local variables on PC
// ----------------------------------------------------------------

const string ICHOR_LVAR_SEL_IDX     = "ICHOR_SEL_IDX";     // index into essence list (0-based, -1 = none)
const string ICHOR_LVAR_ESS_JSON    = "ICHOR_ESS_JSON";     // cached JsonArray from DB

// ----------------------------------------------------------------
// Creature type keys
// ----------------------------------------------------------------

const string ICHOR_TYPE_UNDEAD      = "undead";
const string ICHOR_TYPE_DEMON       = "demon";
const string ICHOR_TYPE_DRAGON      = "dragon";
const string ICHOR_TYPE_LYCANTHROPE = "lycanthrope";
const string ICHOR_TYPE_CONSTRUCT   = "construct";
const string ICHOR_TYPE_FEY         = "fey";
const string ICHOR_TYPE_ABERRATION  = "aberration";
const string ICHOR_TYPE_BEAST       = "beast";

// ----------------------------------------------------------------
// Item-property type constants (NWN:EE, iprp_dmgtype.2da)
// ----------------------------------------------------------------

// Damage type sub-types used as first arg of ItemPropertyDamageBonus
const int ICHOR_DMGT_COLD       = 5;
const int ICHOR_DMGT_FIRE       = 8;
const int ICHOR_DMGT_NEGATIVE   = 9;
const int ICHOR_DMGT_ELECTRICAL = 7;
const int ICHOR_DMGT_ACID       = 4;
const int ICHOR_DMGT_SONIC      = 11;

// Dice damage values: second arg of ItemPropertyDamageBonus
// (IP_CONST_DAMAGEDICE_1d6 = 5 in NWN:EE iprp_damagecost.2da)
const int ICHOR_DICE_1d4        = 4;
const int ICHOR_DICE_1d6        = 5;
const int ICHOR_DICE_2d6        = 8;

// ----------------------------------------------------------------
// Timing
// ----------------------------------------------------------------

const int   ICHOR_DURATION_SEC  = 3600;    // 1 real hour per applied charge
const int   ICHOR_MAX_COATINGS  = 2;       // slots per weapon
const int   ICHOR_HARVEST_SEC   = 180;     // window to harvest after death

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------

const float ICHOR_W             = 680.0;
const float ICHOR_H             = 520.0;

// ----------------------------------------------------------------
// Forward declarations
// ----------------------------------------------------------------

void IchorOpen(object oPC);
void IchorFeed(object oPC, int nToken);
void IchorFeedEssences(object oPC, int nToken);
void IchorFeedWeapon(object oPC, int nToken);
void IchorApply(object oPC, int nToken);
void IchorRemoveSlotDB(object oPC, int nToken, int nSlot);
void IchorReapplyOnLogin(object oPC);
void IchorHarvestFromCorpse(object oPC, object oCorpse);

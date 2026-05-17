// lib_soc_def.nss — Soul Crystals: constants, bind names, forward declarations.

#include "lib_nui"
#include "sql_soc"

// Forward declarations (implementations in lib_soc.nss)
void SocOpenWindow(object oPC);
void SocFeedList(object oPC, int nToken);
void SocFeedDetail(object oPC, int nToken);
void SocFeedStats(object oPC, int nToken);
void SocOnPlayerTarget(object oPC, object oTarget);
void SocConsumeFor(object oPC, int nToken, int nCrystalId, int nConsumeType);
void SocReleaseCrystal(object oPC, int nToken, int nCrystalId);

// ---------------------------------------------------------------
// Window / event IDs
// ---------------------------------------------------------------

const string SOC_WINDOW     = "SOC_WINDOW";
const string SOC_EV_SCRIPT  = "lib_soc_ev";
const string SOC_WIN_GEOM   = "soc_win_geom";
const string SOC_GRP_DETAIL = "soc_grp_detail";  // swappable detail pane

// ---------------------------------------------------------------
// List binds  (NuiList array-per-row pattern)
// ---------------------------------------------------------------

const string SOC_BIND_ROW_NAME  = "soc_row_name";
const string SOC_BIND_ROW_TIER  = "soc_row_tier";
const string SOC_BIND_ROW_ESS   = "soc_row_ess";
const string SOC_BIND_ROW_ENC   = "soc_row_enc";
const string SOC_BIND_ROW_COLOR = "soc_row_color";
const string SOC_BIND_ROW_COUNT = "soc_row_count";

// ---------------------------------------------------------------
// Detail pane binds  (set after NuiSetGroupLayout each time)
// ---------------------------------------------------------------

const string SOC_BIND_DET_NAME     = "soc_det_name";
const string SOC_BIND_DET_RACE     = "soc_det_race";
const string SOC_BIND_DET_ESS      = "soc_det_ess";
const string SOC_BIND_DET_TIER     = "soc_det_tier";
const string SOC_BIND_BTN_STR_ENA  = "soc_btn_str_ena";
const string SOC_BIND_BTN_WIS_ENA  = "soc_btn_wis_ena";
const string SOC_BIND_BTN_AC_ENA   = "soc_btn_ac_ena";
const string SOC_BIND_BTN_REG_ENA  = "soc_btn_reg_ena";
const string SOC_BIND_BTN_FULL_ENA = "soc_btn_full_ena";
const string SOC_BIND_BTN_REL_ENA  = "soc_btn_rel_ena";

// ---------------------------------------------------------------
// Header / footer binds
// ---------------------------------------------------------------

const string SOC_BIND_CAP_LBL   = "soc_cap_lbl";
const string SOC_BIND_STATS_LBL = "soc_stats_lbl";
const string SOC_BIND_BTN_BIND_ENA = "soc_btn_bnd_ena";

// ---------------------------------------------------------------
// Button IDs
// ---------------------------------------------------------------

const string SOC_BTN_CLOSE   = "soc_btn_close";
const string SOC_BTN_ROW     = "soc_btn_row";
const string SOC_BTN_BIND    = "soc_btn_bind";
const string SOC_BTN_STR     = "soc_btn_str";
const string SOC_BTN_WIS     = "soc_btn_wis";
const string SOC_BTN_AC      = "soc_btn_ac";
const string SOC_BTN_REGEN   = "soc_btn_regen";
const string SOC_BTN_FULL    = "soc_btn_full";
const string SOC_BTN_RELEASE = "soc_btn_release";

// ---------------------------------------------------------------
// LVARs on PC
// ---------------------------------------------------------------

const string SOC_LVAR_SEL_ID  = "SOC_SEL_ID";   // currently selected crystal DB id (0=none)
const string SOC_LVAR_BINDING = "SOC_BINDING";  // 1 while targeting mode is active

// ---------------------------------------------------------------
// Race categories
// ---------------------------------------------------------------

const int SOC_RACE_HUMANOID = 1;  // humans, elves, gnomes, half-*, goblinoids, etc.
const int SOC_RACE_BEAST    = 2;  // animals, magical beasts, vermin, dragons
const int SOC_RACE_UNDEAD   = 3;  // undead
const int SOC_RACE_OUTSIDER = 4;  // outsiders, elementals, fey

// ---------------------------------------------------------------
// Crystal tiers
// ---------------------------------------------------------------

const int SOC_TIER_CRACKED  = 1;
const int SOC_TIER_COMMON   = 2;
const int SOC_TIER_GREATER  = 3;
const int SOC_TIER_FLAWLESS = 4;

// ---------------------------------------------------------------
// Tuning
// ---------------------------------------------------------------

const int SOC_MAX_CRYSTALS   = 8;    // max crystal slots per player

// Buff duration = (essence / 100) * DUR_PER_100 seconds
const float SOC_DUR_PER_100  = 120.0;   // 2 minutes per 100 essence
const float SOC_DUR_MIN      = 60.0;
const float SOC_DUR_MAX      = 600.0;   // hard cap: 10 minutes

// Full-consume power multiplier uses half-duration but is stronger
const int SOC_FULL_CD_SECS   = 300;     // 5 minute cooldown between full consumes

// ---------------------------------------------------------------
// Window layout
// ---------------------------------------------------------------

const float SOC_WIN_W = 640.0;
const float SOC_WIN_H = 480.0;

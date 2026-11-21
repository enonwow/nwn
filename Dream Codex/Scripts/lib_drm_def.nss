#include "lib_nui"

// ---- Window / event IDs ----
const string DRM_WIN_MAIN      = "DRM_WIN_MAIN";
const string DRM_EV_SCRIPT     = "lib_drm_ev";
const string DRM_GRP_SWAP      = "DRM_GRP_SWAP";
const string DRM_WIN_GEOM      = "drm_win_geom";

// ---- Trance view binds ----
const string DRM_BIND_PROGRESS  = "drm_progress";
const string DRM_BIND_CATEGORY  = "drm_category";
const string DRM_BIND_CAT_COLOR = "drm_cat_color";
const string DRM_BIND_TITLE     = "drm_title";
const string DRM_BIND_TEXT      = "drm_text";
const string DRM_BIND_FX_LBL    = "drm_fx_lbl";
const string DRM_BIND_ACC_LBL   = "drm_acc_lbl";
const string DRM_BIND_ACC_ENA   = "drm_acc_ena";
const string DRM_BIND_REJ_ENA   = "drm_rej_ena";
const string DRM_BIND_DONE_VIS  = "drm_done_vis";
const string DRM_BIND_TRANCE_VIS= "drm_trance_vis";

// ---- Journal view binds ----
const string DRM_BIND_J_DATE    = "drm_j_date";
const string DRM_BIND_J_CAT    = "drm_j_cat";
const string DRM_BIND_J_TITLE  = "drm_j_title";
const string DRM_BIND_J_COLOR  = "drm_j_color";
const string DRM_BIND_J_ENC    = "drm_j_enc";
const string DRM_BIND_J_BODY   = "drm_j_body";
const string DRM_BIND_J_COUNT  = "drm_j_count";

// ---- Button IDs ----
const string DRM_BTN_CLOSE     = "drm_btn_close";
const string DRM_BTN_ACCEPT    = "drm_btn_accept";
const string DRM_BTN_REJECT    = "drm_btn_reject";
const string DRM_BTN_JOURNAL   = "drm_btn_journal";
const string DRM_BTN_BACK      = "drm_btn_back";
const string DRM_BTN_J_ROW     = "drm_btn_jrow";

// ---- Per-PC local vars ----
const string DRM_LVAR_POOL     = "DRM_POOL";       // JsonArray — drawn visions for this session
const string DRM_LVAR_CURSOR   = "DRM_CURSOR";     // int — which vision we're on (0-based)
const string DRM_LVAR_ACCEPTED = "DRM_ACCEPTED";   // JsonArray of accepted vision IDs
const string DRM_LVAR_JSEL     = "DRM_JSEL";       // int — selected journal row index
const string DRM_LVAR_SAVED    = "DRM_SAVED";      // int — 1 after session persisted to SQL

// ---- Vision categories ----
const string DRM_CAT_DEATH    = "ŚMIERĆ";
const string DRM_CAT_TRIUMPH  = "TRYUMF";
const string DRM_CAT_CHAOS    = "CHAOS";
const string DRM_CAT_TRUTH    = "PRAWDA";
const string DRM_CAT_SHADOW   = "CIEŃ";
const string DRM_CAT_BLOOD    = "KREW";

// ---- Effect type codes ----
const int DRM_FX_NONE          = 0;
const int DRM_FX_ATTACK_BONUS  = 1;
const int DRM_FX_ATTACK_PENLT  = 2;
const int DRM_FX_AC_BONUS      = 3;
const int DRM_FX_AC_PENLT      = 4;
const int DRM_FX_SAVE_BONUS    = 5;
const int DRM_FX_SAVE_PENLT    = 6;
const int DRM_FX_STEALTH_BONUS = 7;
const int DRM_FX_DAMAGE_BONUS  = 8;
const int DRM_FX_TEMP_HP       = 9;
const int DRM_FX_CHAOS_RANDOM  = 10;
const int DRM_FX_REVEAL        = 11;

// ---- Tuning ----
const int   DRM_VISIONS_PER_SESSION = 3;
const int   DRM_JOURNAL_MAX         = 15;
const int   DRM_COOLDOWN_HOURS      = 8;
const float DRM_EFFECT_DURATION_S   = 14400.0;  // 4 hours in seconds
const float DRM_W                   = 560.0;
const float DRM_H                   = 530.0;

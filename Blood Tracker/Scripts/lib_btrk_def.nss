// Blood Tracker — constants and NUI bind identifiers.

// ---- Window IDs ----
const string BTRK_WINDOW           = "BTRK_WINDOW";
const string BTRK_EV_SCRIPT        = "lib_btrk_ev";
const string BTRK_WIN_GEOM         = "btrk_win_geom";

// ---- NUI bind names ----
const string BTRK_BIND_STATUS_LBL  = "btrk_status_lbl";
const string BTRK_BIND_STATUS_COL  = "btrk_status_col";
const string BTRK_BIND_ACT_LBL     = "btrk_act_lbl";
const string BTRK_BIND_SEARCH_ENA  = "btrk_search_ena";
const string BTRK_BIND_DIR_LBL     = "btrk_dir_lbl";
const string BTRK_BIND_FRESH_LBL   = "btrk_fresh_lbl";
const string BTRK_BIND_DIST_LBL    = "btrk_dist_lbl";
const string BTRK_BIND_SRC_LBL     = "btrk_src_lbl";
const string BTRK_BIND_LOG_ROW     = "btrk_log_row";
const string BTRK_BIND_LOG_COUNT   = "btrk_log_count";

// ---- Button IDs ----
const string BTRK_BTN_CLOSE        = "btrk_btn_close";
const string BTRK_BTN_ACTIVATE     = "btrk_btn_activate";
const string BTRK_BTN_SEARCH       = "btrk_btn_search";
const string BTRK_BTN_CLEAR_LOG    = "btrk_btn_clearlog";

// ---- Local variables on PC object ----
const string BTRK_LVAR_ACTIVE      = "BTRK_ACTIVE";        // 1 when tracking mode on
const string BTRK_LVAR_TRACKED_ID  = "BTRK_TRACKED_ID";    // trail id currently tracked
const string BTRK_LVAR_LOG         = "BTRK_LOG";            // JsonArray of log entry strings
const string BTRK_LVAR_HB_TICK     = "BTRK_HB_TICK";       // heartbeat tick counter on MODULE

// ---- Tuning ----
const float  BTRK_SEARCH_RANGE     = 45.0;   // meters — max trail search radius
const int    BTRK_DECAY_FRESH      = 300;    // seconds until stale
const int    BTRK_DECAY_STALE      = 900;    // seconds until cold
const int    BTRK_DECAY_COLD       = 1800;   // seconds until expiry
const int    BTRK_DC_FRESH         = 10;     // Search DC for fresh trail
const int    BTRK_DC_STALE         = 16;     // Search DC for stale trail
const int    BTRK_DC_COLD          = 22;     // Search DC for cold trail
const int    BTRK_LOG_MAX          = 7;      // visible rows in log list
const int    BTRK_XP_PER_TRAIL     = 20;    // XP per newly discovered trail
const int    BTRK_MIN_BLEED_DMG    = 5;      // min damage to leave a trail

// Creatures bleed at most once per interval (seconds) to avoid spam
const int    BTRK_BLEED_COOLDOWN   = 8;

// Heartbeat ticks between UI refreshes for active trackers
const int    BTRK_REFRESH_TICKS    = 2;

// SQLite campaign database name
const string BTRK_CAMPAIGN_DB      = "blood_tracker";

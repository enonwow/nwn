#include "lib_nui"
#include "sql_gla"

// Forward declarations
void ArenaOpenWindow(object oPC);
void ArenaFeedLeaderboard(object oPC, int nToken);
void ArenaFeedStatus(object oPC, int nToken);
void ArenaCheckWave(object oPC);
void ArenaSpawnWave(object oPC, int nWave);
void ArenaHandleWin(object oPC);
void ArenaHandleLoss(object oPC);
void ArenaClearSpawns(object oPC);

// ----------------------------------------------------------------
// Window / event identifiers
// ----------------------------------------------------------------

const string ARENA_WINDOW        = "ARENA_WINDOW";
const string ARENA_EV_SCRIPT     = "lib_gla_ev";
const string ARENA_WIN_GEOM      = "arena_win_geom";
const string ARENA_GRP_SWAP      = "arena_grp_swap";

// Buttons
const string ARENA_BTN_CLOSE     = "arena_btn_close";
const string ARENA_BTN_TAB_BOARD = "arena_btn_tab_board";
const string ARENA_BTN_TAB_MINE  = "arena_btn_tab_mine";
const string ARENA_BTN_L1        = "arena_btn_l1";
const string ARENA_BTN_L2        = "arena_btn_l2";
const string ARENA_BTN_L3        = "arena_btn_l3";
const string ARENA_BTN_FIGHT     = "arena_btn_fight";

// Leaderboard list binds (array-bound)
const string ARENA_BIND_BD_RANK  = "arena_bd_rank";
const string ARENA_BIND_BD_NAME  = "arena_bd_name";
const string ARENA_BIND_BD_LG    = "arena_bd_lg";
const string ARENA_BIND_BD_WINS  = "arena_bd_wins";
const string ARENA_BIND_BD_LOSS  = "arena_bd_loss";
const string ARENA_BIND_BD_INF   = "arena_bd_inf";
const string ARENA_BIND_BD_COUNT = "arena_bd_count";

// My status binds (scalar)
const string ARENA_BIND_MY_NAME  = "arena_my_name";
const string ARENA_BIND_MY_LG    = "arena_my_lg";
const string ARENA_BIND_MY_WINS  = "arena_my_wins";
const string ARENA_BIND_MY_LOSS  = "arena_my_loss";
const string ARENA_BIND_MY_INF   = "arena_my_inf";
const string ARENA_BIND_MY_TITLE = "arena_my_title";
const string ARENA_BIND_FLAVOR   = "arena_flavor";
const string ARENA_BIND_FIGHT_EN = "arena_fight_en";
const string ARENA_BIND_FIGHT_LB = "arena_fight_lb";
const string ARENA_BIND_L1_ENC   = "arena_l1_enc";
const string ARENA_BIND_L2_ENC   = "arena_l2_enc";
const string ARENA_BIND_L3_ENC   = "arena_l3_enc";

// Local variables stored on PC
const string ARENA_LVAR_TAB      = "ARENA_TAB";
const string ARENA_LVAR_LEAGUE   = "ARENA_LEAGUE_SEL";
const string ARENA_LVAR_IN_FIGHT = "ARENA_IN_FIGHT";
const string ARENA_LVAR_WAVE     = "ARENA_WAVE";
const string ARENA_LVAR_FT_LG    = "ARENA_FT_LG";
const string ARENA_LVAR_SPAWN_N  = "ARENA_SPAWN_N";
const string ARENA_LVAR_TIMEOUT  = "ARENA_TIMEOUT";

// League constants
const int ARENA_LEAGUE_RECRUIT   = 1;
const int ARENA_LEAGUE_WARRIOR   = 2;
const int ARENA_LEAGUE_CHAMPION  = 3;

// Fight config
const int ARENA_WAVES_PER_FIGHT  = 3;
const int ARENA_CHECK_DELAY      = 5;
const int ARENA_TIMEOUT_SEC      = 180;

// Infamy per league win / per loss
const int ARENA_INF_WIN_L1       = 50;
const int ARENA_INF_WIN_L2       = 120;
const int ARENA_INF_WIN_L3       = 250;
const int ARENA_INF_LOSS         = 15;

// Total-win thresholds for title upgrades
const int ARENA_WINS_FIGHTER     = 5;
const int ARENA_WINS_VETERAN     = 20;
const int ARENA_WINS_LEGEND      = 50;

// Layout
const int   ARENA_BOARD_ROWS     = 10;
const float ARENA_W              = 700.0;
const float ARENA_H              = 500.0;

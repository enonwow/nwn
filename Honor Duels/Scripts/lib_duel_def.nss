#include "lib_nui"
#include "sql_duel"

// ----------------------------------------------------------------
// Window IDs
// ----------------------------------------------------------------

const string DUEL_WINDOW            = "DUEL_WINDOW";
const string DUEL_WIN_CHALLENGE     = "DUEL_WIN_CHALLENGE";
const string DUEL_WIN_INCOMING      = "DUEL_WIN_INCOMING";
const string DUEL_WIN_HUD           = "DUEL_WIN_HUD";
const string DUEL_EV_SCRIPT         = "lib_duel_ev";

// ----------------------------------------------------------------
// View tabs (main window)
// ----------------------------------------------------------------

const int DUEL_VIEW_INCOMING        = 0;
const int DUEL_VIEW_HISTORY         = 1;
const int DUEL_VIEW_RANKING         = 2;

// ----------------------------------------------------------------
// Duel status
// ----------------------------------------------------------------

const int DUEL_STATUS_PENDING       = 0; // challenge sent, awaiting response
const int DUEL_STATUS_ACCEPTED      = 1; // accepted, countdown starting
const int DUEL_STATUS_IN_PROGRESS   = 2; // duel in progress
const int DUEL_STATUS_COMPLETED     = 3; // finished with a winner
const int DUEL_STATUS_DECLINED      = 4; // refused by challenged
const int DUEL_STATUS_EXPIRED       = 5; // timed out without response
const int DUEL_STATUS_CANCELED      = 6; // canceled by challenger

// ----------------------------------------------------------------
// Win conditions
// ----------------------------------------------------------------

const int DUEL_WIN_FIRST_BLOOD      = 0; // HP drops below threshold
const int DUEL_WIN_TO_DEATH         = 1; // until someone dies
const int DUEL_WIN_TO_YIELD         = 2; // until one yields

// ----------------------------------------------------------------
// Rule flags (bitmask on rules_mask column)
// ----------------------------------------------------------------

const int DUEL_RULE_NO_MAGIC        = 0x01;
const int DUEL_RULE_NO_ITEMS        = 0x02;
const int DUEL_RULE_NO_CRIT         = 0x04;

// ----------------------------------------------------------------
// Honor adjustments
// ----------------------------------------------------------------

const int DUEL_HONOR_WIN            = 10;
const int DUEL_HONOR_LOSE           = -3;   // graceful loss is not severe
const int DUEL_HONOR_DECLINE        = -15;  // refusing a challenge stains honor
const int DUEL_HONOR_FORFEIT        = -25;  // leaving arena or yielding mid-duel
const int DUEL_HONOR_KILL_BONUS     = 5;    // extra honor for death duels

// ----------------------------------------------------------------
// Mechanics
// ----------------------------------------------------------------

const float DUEL_ARENA_RADIUS       = 10.0; // meters from arena center
const float DUEL_OUT_OF_BOUNDS_TIME = 6.0;  // seconds outside before forfeit
const int   DUEL_COUNTDOWN_SECONDS  = 5;
const int   DUEL_PENDING_TTL        = 300;  // 5 min for response
const float DUEL_FIRST_BLOOD_FRAC   = 0.50; // forfeit at <50% HP
const int   DUEL_HISTORY_LIMIT      = 20;
const int   DUEL_RANKING_LIMIT      = 10;
const int   DUEL_TICK_PERIOD        = 1;    // seconds, periodic checks

// ----------------------------------------------------------------
// Effect tags
// ----------------------------------------------------------------

const string DUEL_EFFECT_TAG        = "DUEL_INVULN_PRESTART";

// ----------------------------------------------------------------
// LVARs on PC
// ----------------------------------------------------------------

const string DUEL_LVAR_DRAFT_TARGET     = "DUEL_DRAFT_TARGET_UUID";
const string DUEL_LVAR_DRAFT_NAME       = "DUEL_DRAFT_TARGET_NAME";
const string DUEL_LVAR_DRAFT_RULES      = "DUEL_DRAFT_RULES";
const string DUEL_LVAR_DRAFT_WIN        = "DUEL_DRAFT_WIN";
const string DUEL_LVAR_DRAFT_STAKE      = "DUEL_DRAFT_STAKE";
const string DUEL_LVAR_ACTIVE_DUEL      = "DUEL_ACTIVE_ID";
const string DUEL_LVAR_OUT_OF_BOUNDS    = "DUEL_OOB_TICKS";
const string DUEL_LVAR_VIEW             = "DUEL_VIEW";
const string DUEL_LVAR_INCOMING_ID      = "DUEL_INCOMING_ID";

// ----------------------------------------------------------------
// Bind names
// ----------------------------------------------------------------

// Main window
const string DUEL_BIND_TITLE            = "duel_title";
const string DUEL_BIND_HONOR_LBL        = "duel_honor_lbl";
const string DUEL_BIND_RECORD_LBL       = "duel_record_lbl";

// Tabs
const string DUEL_BIND_TAB_INCOMING_ENC = "duel_tab_inc_enc";
const string DUEL_BIND_TAB_HISTORY_ENC  = "duel_tab_his_enc";
const string DUEL_BIND_TAB_RANKING_ENC  = "duel_tab_rnk_enc";

// Row binds (shared list)
const string DUEL_BIND_ROW_PRIMARY      = "duel_row_primary";   // main label
const string DUEL_BIND_ROW_SECONDARY    = "duel_row_secondary"; // detail label
const string DUEL_BIND_ROW_RIGHT        = "duel_row_right";     // right-aligned label
const string DUEL_BIND_ROW_COLOR        = "duel_row_color";

// Empty placeholder
const string DUEL_BIND_EMPTY_VIS        = "duel_empty_vis";
const string DUEL_BIND_EMPTY_TXT        = "duel_empty_txt";

// Challenge config window
const string DUEL_BIND_CH_TARGET_LBL    = "duel_ch_target_lbl";
const string DUEL_BIND_CH_RULE_NOMAGIC  = "duel_ch_rule_nomagic";
const string DUEL_BIND_CH_RULE_NOITEMS  = "duel_ch_rule_noitems";
const string DUEL_BIND_CH_RULE_NOCRIT   = "duel_ch_rule_nocrit";
const string DUEL_BIND_CH_WIN_FB        = "duel_ch_win_fb";
const string DUEL_BIND_CH_WIN_DEATH     = "duel_ch_win_death";
const string DUEL_BIND_CH_WIN_YIELD     = "duel_ch_win_yield";
const string DUEL_BIND_CH_STAKE_TXT     = "duel_ch_stake_txt";
const string DUEL_BIND_CH_SEND_ENA      = "duel_ch_send_ena";

// Incoming challenge popup
const string DUEL_BIND_INC_TITLE        = "duel_inc_title";
const string DUEL_BIND_INC_RULES        = "duel_inc_rules";
const string DUEL_BIND_INC_STAKE        = "duel_inc_stake";
const string DUEL_BIND_INC_WIN          = "duel_inc_win";

// HUD (active duel overlay)
const string DUEL_BIND_HUD_TITLE        = "duel_hud_title";
const string DUEL_BIND_HUD_OPP_HP       = "duel_hud_opp_hp";
const string DUEL_BIND_HUD_OPP_HP_TIP   = "duel_hud_opp_hp_tip";
const string DUEL_BIND_HUD_SELF_HP      = "duel_hud_self_hp";
const string DUEL_BIND_HUD_SELF_HP_TIP  = "duel_hud_self_hp_tip";
const string DUEL_BIND_HUD_STATE        = "duel_hud_state";
const string DUEL_BIND_HUD_BOUNDS       = "duel_hud_bounds";
const string DUEL_BIND_HUD_GEOM         = "duel_hud_geom";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string DUEL_BTN_CHALLENGE         = "duel_btn_challenge";
const string DUEL_BTN_CLOSE             = "duel_btn_close";
const string DUEL_BTN_TAB_INCOMING      = "duel_btn_tab_inc";
const string DUEL_BTN_TAB_HISTORY       = "duel_btn_tab_his";
const string DUEL_BTN_TAB_RANKING       = "duel_btn_tab_rnk";

const string DUEL_BTN_INC_ACCEPT        = "duel_btn_inc_accept";
const string DUEL_BTN_INC_DECLINE       = "duel_btn_inc_decline";
const string DUEL_BTN_ROW               = "duel_btn_row";        // pending challenge row in incoming list
const string DUEL_BTN_CANCEL_OUTGOING   = "duel_btn_cancel_out"; // cancel an outgoing challenge

const string DUEL_BTN_CH_RULE_NOMAGIC   = "duel_btn_ch_rule_nm";
const string DUEL_BTN_CH_RULE_NOITEMS   = "duel_btn_ch_rule_ni";
const string DUEL_BTN_CH_RULE_NOCRIT    = "duel_btn_ch_rule_nc";
const string DUEL_BTN_CH_WIN_FB         = "duel_btn_ch_win_fb";
const string DUEL_BTN_CH_WIN_DEATH      = "duel_btn_ch_win_death";
const string DUEL_BTN_CH_WIN_YIELD      = "duel_btn_ch_win_yield";
const string DUEL_BTN_CH_SEND           = "duel_btn_ch_send";
const string DUEL_BTN_CH_CANCEL         = "duel_btn_ch_cancel";

const string DUEL_BTN_HUD_YIELD         = "duel_btn_hud_yield";

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------

const float DUEL_W                  = 600.0;
const float DUEL_H                  = 500.0;
const float DUEL_CHALLENGE_W        = 420.0;
const float DUEL_CHALLENGE_H        = 360.0;
const float DUEL_INCOMING_W         = 460.0;
const float DUEL_INCOMING_H         = 260.0;
const float DUEL_HUD_W              = 240.0;
const float DUEL_HUD_H              = 130.0;

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------

string DuelStatusToString(int nStatus)
{
    switch(nStatus)
    {
        case DUEL_STATUS_PENDING:     return "Oczekuje";
        case DUEL_STATUS_ACCEPTED:    return "Przyjete";
        case DUEL_STATUS_IN_PROGRESS: return "W trakcie";
        case DUEL_STATUS_COMPLETED:   return "Zakonczone";
        case DUEL_STATUS_DECLINED:    return "Odrzucone";
        case DUEL_STATUS_EXPIRED:     return "Wygaslo";
        case DUEL_STATUS_CANCELED:    return "Anulowane";
    }
    return "?";
}

string DuelWinConditionToString(int nWin)
{
    switch(nWin)
    {
        case DUEL_WIN_FIRST_BLOOD: return "Pierwsza krew";
        case DUEL_WIN_TO_DEATH:    return "Na smierc";
        case DUEL_WIN_TO_YIELD:    return "Do poddania";
    }
    return "?";
}

string DuelRulesToString(int nMask)
{
    string sOut = "";
    if(nMask & DUEL_RULE_NO_MAGIC) sOut += "bez magii, ";
    if(nMask & DUEL_RULE_NO_ITEMS) sOut += "bez mikstur, ";
    if(nMask & DUEL_RULE_NO_CRIT)  sOut += "bez krytykow, ";
    if(sOut == "") return "honorowy";
    return GetStringLeft(sOut, GetStringLength(sOut) - 2);
}

object DuelGetPCByUUID(string sUuid)
{
    if(sUuid == "") return OBJECT_INVALID;
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(GetObjectUUID(oPC) == sUuid) return oPC;
        oPC = GetNextPC();
    }
    return OBJECT_INVALID;
}

int DuelIsActiveStatus(int nStatus)
{
    return (nStatus == DUEL_STATUS_PENDING
         || nStatus == DUEL_STATUS_ACCEPTED
         || nStatus == DUEL_STATUS_IN_PROGRESS);
}

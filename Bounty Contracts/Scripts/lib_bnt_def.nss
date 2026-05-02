// lib_bnt_def.nss — Bounty Contracts: constants, bind names, forward declarations.
#include "lib_nui"
#include "sql_bnt"

// ============================================================
// Forward declarations (resolved in lib_bnt.nss)
// ============================================================
void BntOpenWindow(object oPC);
void BntSwapToBoard(object oPC, int nToken);
void BntSwapToActive(object oPC, int nToken);
void BntSwapToMine(object oPC, int nToken);
void BntSwapToPost(object oPC, int nToken);
void BntFeedBoard(object oPC, int nToken);
void BntFeedActive(object oPC, int nToken);
void BntFeedMine(object oPC, int nToken);
void BntFeedPost(object oPC, int nToken);

// ============================================================
// Window / group IDs
// ============================================================
const string BNT_WINDOW         = "BNT_WINDOW";
const string BNT_EV_SCRIPT      = "lib_bnt_ev";
const string BNT_GRP_SWAP       = "BNT_GRP_SWAP";
const string BNT_WIN_GEOM       = "bnt_win_geom";

// ============================================================
// Board-view binds  (list rows)
// ============================================================
const string BNT_BIND_BD_TARGET  = "bnt_bd_target";
const string BNT_BIND_BD_REWARD  = "bnt_bd_reward";
const string BNT_BIND_BD_POSTER  = "bnt_bd_poster";
const string BNT_BIND_BD_EXP     = "bnt_bd_exp";
const string BNT_BIND_BD_ENC     = "bnt_bd_enc";
const string BNT_BIND_BD_COLOR   = "bnt_bd_color";
const string BNT_BIND_BD_COUNT   = "bnt_bd_count";
const string BNT_BIND_BD_DETAIL  = "bnt_bd_detail";
const string BNT_BIND_ACCEPT_ENA = "bnt_accept_ena";

// ============================================================
// Active-contract-view binds
// ============================================================
const string BNT_BIND_ACT_HEADER = "bnt_act_header";
const string BNT_BIND_ACT_TARGET = "bnt_act_target";
const string BNT_BIND_ACT_DESC   = "bnt_act_desc";
const string BNT_BIND_ACT_REWARD = "bnt_act_reward";
const string BNT_BIND_ACT_POSTER = "bnt_act_poster";
const string BNT_BIND_ACT_EXP    = "bnt_act_exp";
const string BNT_BIND_CLAIM_ENA  = "bnt_claim_ena";

// ============================================================
// My-contracts-view binds  (list rows + cancel button)
// ============================================================
const string BNT_BIND_MINE_TARGET = "bnt_mine_target";
const string BNT_BIND_MINE_REWARD = "bnt_mine_reward";
const string BNT_BIND_MINE_STATE  = "bnt_mine_state";
const string BNT_BIND_MINE_HUNTER = "bnt_mine_hunter";
const string BNT_BIND_MINE_ENC    = "bnt_mine_enc";
const string BNT_BIND_MINE_COLOR  = "bnt_mine_color";
const string BNT_BIND_MINE_COUNT  = "bnt_mine_count";
const string BNT_BIND_CANCEL_ENA  = "bnt_cancel_ena";

// ============================================================
// Post-view binds
// ============================================================
const string BNT_BIND_POST_TARGET = "bnt_post_target";
const string BNT_BIND_POST_DESC   = "bnt_post_desc";
const string BNT_BIND_POST_REWARD = "bnt_post_reward";
const string BNT_BIND_POST_IS_PC  = "bnt_post_ispc";
const string BNT_BIND_POST_STATUS = "bnt_post_status";
const string BNT_BIND_POST_SUB_ENA= "bnt_post_sub_ena";

// ============================================================
// Button IDs
// ============================================================
const string BNT_BTN_CLOSE        = "bnt_btn_close";
const string BNT_BTN_TAB_BOARD    = "bnt_btn_tab_bd";
const string BNT_BTN_TAB_ACTIVE   = "bnt_btn_tab_act";
const string BNT_BTN_TAB_MINE     = "bnt_btn_tab_mine";
const string BNT_BTN_TAB_POST     = "bnt_btn_tab_post";
const string BNT_BTN_BD_ROW       = "bnt_btn_bd_row";
const string BNT_BTN_ACCEPT       = "bnt_btn_accept";
const string BNT_BTN_CLAIM        = "bnt_btn_claim";
const string BNT_BTN_ABANDON      = "bnt_btn_abandon";
const string BNT_BTN_MINE_ROW     = "bnt_btn_mine_row";
const string BNT_BTN_CANCEL_OWN   = "bnt_btn_cancel";
const string BNT_BTN_SUBMIT       = "bnt_btn_submit";

// ============================================================
// PC-local vars
// ============================================================
const string BNT_LVAR_SEL_ID      = "BNT_SEL_ID";       // selected board row contract id
const string BNT_LVAR_MINE_SEL    = "BNT_MINE_SEL";     // selected mine row contract id

// ============================================================
// Layout
// ============================================================
const float BNT_W                 = 720.0;
const float BNT_H                 = 500.0;

// ============================================================
// Helper: find online PC by UUID
// ============================================================
object BntGetPCByUUID(string sUuid)
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

// State int → short Polish label
string BntStateName(int nState)
{
    switch(nState)
    {
        case BNT_STATE_OPEN:      return "otwarty";
        case BNT_STATE_ACCEPTED:  return "przyjety";
        case BNT_STATE_COMPLETED: return "ukonczony";
        case BNT_STATE_EXPIRED:   return "wygasly";
        case BNT_STATE_CANCELLED: return "anulowany";
    }
    return "?";
}

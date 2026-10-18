#include "lib_nui"
#include "sql_ma"

// ----------------------------------------------------------------
// Master & Apprentice
// ----------------------------------------------------------------
// PvP-friendly mentorship system:
//   - One PC may be Master to up to MA_MAX_APPRENTICES.
//   - One PC may have at most one Master at a time.
//   - On apprentice level-up the Master receives MA_MASTER_XP_PER_LEVEL
//     * <new_level> bonus XP (capped to apprentice's level <= master's).
//   - Apprentice gains MA_SKILL_BONUS to every skill the Master has at
//     rank >= MA_SKILL_THRESHOLD. Bonuses re-apply on login.
//
// Hooks:
//   OnModuleLoad     -> sys_on_load    (init schema)
//   OnPlayerLevelUp  -> sys_on_levelup (XP transfer to master)
//   OnClientEnter    -> sys_on_enter   (reapply skill bonuses)
//   OnPlayerTarget   -> sys_on_target  (apprentice selection)
//
// Open the panel from a placeable's OnUsed:
//   #include "lib_ma"
//   void main() { CreateMaWindow(GetLastUsedBy()); }
// ----------------------------------------------------------------

const string MA_WINDOW           = "MA_WINDOW";
const string MA_WIN_PROPOSAL     = "MA_WIN_PROPOSAL";
const string MA_EV_SCRIPT        = "lib_ma_ev";

// Tunables
const int   MA_MAX_APPRENTICES   = 3;
const int   MA_MASTER_XP_PER_LEVEL = 200;   // master gets this * apprentice_new_level
const int   MA_SKILL_BONUS       = 2;       // bonus ranks granted to apprentice
const int   MA_SKILL_THRESHOLD   = 5;       // master must have at least this rank to grant
const int   MA_MAX_SKILL_INDEX   = 27;      // standard NWN skill range (0..27)
const float MA_PROPOSAL_DISTANCE = 6.0;     // meters

// Effect tag for granted skill bonuses (so we can remove cleanly)
const string MA_EFFECT_TAG       = "MA_APPRENTICE_BONUS";

// LVARs on PC
const string MA_LVAR_PROPOSAL_FROM   = "MA_PROPOSAL_FROM_UUID";
const string MA_LVAR_PROPOSAL_NAME   = "MA_PROPOSAL_FROM_NAME";

// Bind names
const string MA_BIND_TITLE           = "ma_title";
const string MA_BIND_MASTER_LBL      = "ma_master_lbl";
const string MA_BIND_BONUS_LBL       = "ma_bonus_lbl";
const string MA_BIND_LEAVE_VIS       = "ma_leave_vis";
const string MA_BIND_TAKE_ENA        = "ma_take_ena";
const string MA_BIND_SECTION_LBL     = "ma_section_lbl";
const string MA_BIND_ROW_NAME        = "ma_row_name";
const string MA_BIND_ROW_INFO        = "ma_row_info";
const string MA_BIND_ROW_COLOR       = "ma_row_color";
const string MA_BIND_EMPTY_VIS       = "ma_empty_vis";
const string MA_BIND_EMPTY_TXT       = "ma_empty_txt";
// Proposal popup
const string MA_BIND_PROP_TITLE      = "ma_prop_title";
const string MA_BIND_PROP_DETAIL     = "ma_prop_detail";

// Button IDs
const string MA_BTN_CLOSE            = "ma_btn_close";
const string MA_BTN_TAKE_APPRENTICE  = "ma_btn_take";
const string MA_BTN_LEAVE            = "ma_btn_leave";
const string MA_BTN_ROW              = "ma_btn_row";   // dismiss apprentice row
const string MA_BTN_PROP_ACCEPT      = "ma_btn_prop_accept";
const string MA_BTN_PROP_DECLINE     = "ma_btn_prop_decline";

// Layout
const float MA_W = 560.0;
const float MA_H = 460.0;
const float MA_PROP_W = 420.0;
const float MA_PROP_H = 220.0;

object MaGetPCByUUID(string sUuid)
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

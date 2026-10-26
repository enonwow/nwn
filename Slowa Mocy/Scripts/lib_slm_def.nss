#include "lib_nui"
#include "sql_slm"

// Forward declarations
void FeedSlmForge(object oPC, int nToken);
void FeedSlmIncan(object oPC, int nToken);

// ----------------------------------------------------------------
// Window / group identifiers
// ----------------------------------------------------------------
const string SLM_WINDOW      = "SLM_WINDOW";
const string SLM_EV_SCRIPT   = "lib_slm_ev";
const string SLM_GRP_SWAP    = "SLM_GRP_SWAP";
const string SLM_WIN_GEOM    = "slm_win_geom";

// ----------------------------------------------------------------
// Word category IDs
// Elements 1-6, Targets 11-14, Powers 21-23 (non-overlapping ranges)
// ----------------------------------------------------------------
const int SLM_ELEM_FIRE     = 1;
const int SLM_ELEM_ICE      = 2;
const int SLM_ELEM_SHADOW   = 3;
const int SLM_ELEM_LIGHT    = 4;
const int SLM_ELEM_THUNDER  = 5;
const int SLM_ELEM_VOID     = 6;

const int SLM_TARGET_ENEMY  = 11;
const int SLM_TARGET_ALLY   = 12;
const int SLM_TARGET_SELF   = 13;
const int SLM_TARGET_AREA   = 14;

const int SLM_POWER_WHISPER = 21;
const int SLM_POWER_VOICE   = 22;
const int SLM_POWER_SCREAM  = 23;

// ----------------------------------------------------------------
// Limits and costs
// ----------------------------------------------------------------
const int SLM_MAX_SLOTS     = 6;
const int SLM_HP_BASE       = 8;     // HP cost at Szept; doubles/quadruples for higher tiers
const int SLM_LEARN_GOLD    = 500;   // gold to learn one word from a teacher

// ----------------------------------------------------------------
// Window dimensions
// ----------------------------------------------------------------
const float SLM_W           = 680.0;
const float SLM_H           = 560.0;

// ----------------------------------------------------------------
// Bind names — Forge (word-selection) view
// ----------------------------------------------------------------
const string SLM_BIND_ELEM_SEL    = "slm_elem_sel";   // int — selected element combo index
const string SLM_BIND_TGT_SEL     = "slm_tgt_sel";    // int — selected target combo index
const string SLM_BIND_POW_SEL     = "slm_pow_sel";    // int — selected power combo index
const string SLM_BIND_PREVIEW     = "slm_preview";    // string — effect description
const string SLM_BIND_COST_LBL    = "slm_cost_lbl";   // string — "Koszt: X PŻ"
const string SLM_BIND_FORGE_ENA   = "slm_forge_ena";  // bool
// Slot buttons (0..SLM_MAX_SLOTS-1): id = SLM_BTN_SLOT + IntToString(i)
const string SLM_BIND_SLOT_ENC    = "slm_slot_enc";   // + IntToString(i) — selected slot highlight
const string SLM_BIND_SLOT_LBL    = "slm_slot_lbl";   // + IntToString(i) — "i+1" or check mark

// ----------------------------------------------------------------
// Bind names — Incantations list view
// ----------------------------------------------------------------
const string SLM_BIND_INCAN_NAME  = "slm_inc_name";   // string array
const string SLM_BIND_INCAN_COST  = "slm_inc_cost";   // string array
const string SLM_BIND_INCAN_DESC  = "slm_inc_desc";   // string array (short)
const string SLM_BIND_INCAN_ENC   = "slm_inc_enc";    // bool array — row highlight
const string SLM_BIND_INCAN_CNT   = "slm_inc_cnt";    // int — row count
const string SLM_BIND_INVOKE_ENA  = "slm_invoke_ena"; // bool
const string SLM_BIND_ERASE_ENA   = "slm_erase_ena";  // bool

// ----------------------------------------------------------------
// Button / element IDs
// ----------------------------------------------------------------
const string SLM_BTN_CLOSE        = "slm_btn_close";
const string SLM_BTN_TAB_FORGE    = "slm_tab_forge";
const string SLM_BTN_TAB_INCAN    = "slm_tab_incan";
const string SLM_BTN_FORGE        = "slm_btn_forge";
const string SLM_BTN_SLOT         = "slm_btn_slot";   // + IntToString(0..5)
const string SLM_BTN_INCAN_ROW    = "slm_btn_inc_row";
const string SLM_BTN_INVOKE       = "slm_btn_invoke";
const string SLM_BTN_ERASE        = "slm_btn_erase";
const string SLM_BTN_BACK_FORGE   = "slm_btn_backfrg";

// ----------------------------------------------------------------
// Local variables stored on PC
// ----------------------------------------------------------------
const string SLM_LVAR_VIEW        = "SLM_VIEW";       // 0=forge, 1=incan
const string SLM_LVAR_SEL_SLOT    = "SLM_SEL_SLOT";   // 0..5 — save slot index
const string SLM_LVAR_SEL_INCAN   = "SLM_SEL_INCAN";  // index in current incan list, -1=none
const string SLM_LVAR_TARGETING   = "SLM_TARGETING";  // 1 = waiting for target object
const string SLM_LVAR_INVOKE_ELEM = "SLM_INV_ELEM";
const string SLM_LVAR_INVOKE_TGT  = "SLM_INV_TGT";
const string SLM_LVAR_INVOKE_POW  = "SLM_INV_POW";

// ----------------------------------------------------------------
// Word display helpers
// ----------------------------------------------------------------

string SlmGetElemName(int nId)
{
    switch(nId)
    {
        case SLM_ELEM_FIRE:    return "Ogień";
        case SLM_ELEM_ICE:     return "Lód";
        case SLM_ELEM_SHADOW:  return "Cień";
        case SLM_ELEM_LIGHT:   return "Światło";
        case SLM_ELEM_THUNDER: return "Piorun";
        case SLM_ELEM_VOID:    return "Mrok";
    }
    return "?";
}

string SlmGetTargetName(int nId)
{
    switch(nId)
    {
        case SLM_TARGET_ENEMY: return "Wróg";
        case SLM_TARGET_ALLY:  return "Sojusznik";
        case SLM_TARGET_SELF:  return "Siebie";
        case SLM_TARGET_AREA:  return "Przestrzeń";
    }
    return "?";
}

string SlmGetPowerName(int nId)
{
    switch(nId)
    {
        case SLM_POWER_WHISPER: return "Szept";
        case SLM_POWER_VOICE:   return "Głos";
        case SLM_POWER_SCREAM:  return "Krzyk";
    }
    return "?";
}

int SlmGetHPCost(int nPower)
{
    switch(nPower)
    {
        case SLM_POWER_WHISPER: return SLM_HP_BASE;
        case SLM_POWER_VOICE:   return SLM_HP_BASE * 2;
        case SLM_POWER_SCREAM:  return SLM_HP_BASE * 4;
    }
    return SLM_HP_BASE;
}

string SlmGetIncantationName(int nElem, int nTarget, int nPower)
{
    return SlmGetElemName(nElem) + " / " + SlmGetTargetName(nTarget) + " / " + SlmGetPowerName(nPower);
}

// Returns 1-based tier (Szept=1, Głos=2, Krzyk=3)
int SlmGetTier(int nPower)
{
    return nPower - SLM_POWER_WHISPER + 1;
}

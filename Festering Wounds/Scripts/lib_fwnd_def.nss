#include "lib_nui"
#include "sql_fwnd"

void FwndOpen(object oPC);
void FwndPCLoop(object oPC);

// ----------------------------------------------------------------
// Wound types
// ----------------------------------------------------------------

const int FWND_TYPE_VAMPIRE  = 1; // "Ukąszenie Wampira"   — CON drain
const int FWND_TYPE_NECROTIC = 2; // "Gnilna Rana"         — STR drain
const int FWND_TYPE_DEMONIC  = 3; // "Szrama Demoniczna"   — WIS drain
const int FWND_TYPE_VENOM    = 4; // "Głębokie Zatrucie"   — DEX penalty
const int FWND_TYPE_CURSED   = 5; // "Przeklęte Cięcie"    — ATK penalty

// Treatment item resrefs (must exist in module/HAK)
const string FWND_ITEM_HOLY_WATER = "fwnd_holy_water";
const string FWND_ITEM_LIFE_SALVE = "fwnd_life_salve";
const string FWND_ITEM_WARD_HERB  = "fwnd_ward_herb";
const string FWND_ITEM_ANTITOXIN  = "fwnd_antitoxin";
const string FWND_ITEM_EXORCISM   = "fwnd_exorcism";
const string FWND_ITEM_LIFE_LEAF  = "fwnd_life_leaf"; // universal -1 severity

// Marks all active wound debuff effects for clean removal
const string FWND_EFFECT_TAG    = "FWND_DEBUFF";

// Heartbeat loop delay in seconds
const float FWND_LOOP_DELAY     = 30.0;

// LVAR — 1 while loop should fire, 0 after logout
const string FWND_LVAR_LOOP_RUN = "FWND_LOOP";

// LVAR — DB id of the wound selected in UI
const string FWND_LVAR_SEL_ID   = "FWND_SEL_ID";

// ----------------------------------------------------------------
// NUI identifiers
// ----------------------------------------------------------------

const string FWND_WINDOW    = "FWND_WINDOW";
const string FWND_EV_SCRIPT = "lib_fwnd_ev";
const string FWND_GRP_SWAP  = "FWND_GRP_SWAP";
const string FWND_WIN_GEOM  = "fwnd_win_geom";

// List view binds
const string FWND_BIND_LIST_ICON = "fwnd_list_icon";
const string FWND_BIND_LIST_NAME = "fwnd_list_name";
const string FWND_BIND_LIST_SEV  = "fwnd_list_sev";
const string FWND_BIND_LIST_COL  = "fwnd_list_col";
const string FWND_BIND_LIST_ENC  = "fwnd_list_enc";
const string FWND_BIND_ROWCOUNT  = "fwnd_rowcount";
const string FWND_BIND_HEADER    = "fwnd_header";

// Detail view binds
const string FWND_BIND_DET_WNAME = "fwnd_det_wname";
const string FWND_BIND_DET_TYPE  = "fwnd_det_type";
const string FWND_BIND_DET_SEV   = "fwnd_det_sev";
const string FWND_BIND_DET_DESC  = "fwnd_det_desc";
const string FWND_BIND_DET_TREAT = "fwnd_det_treat";
const string FWND_BIND_TREAT_ENA = "fwnd_treat_ena";

// Button IDs
const string FWND_BTN_CLOSE = "fwnd_btn_close";
const string FWND_BTN_ROW   = "fwnd_btn_row";
const string FWND_BTN_TREAT = "fwnd_btn_treat";
const string FWND_BTN_BACK  = "fwnd_btn_back";

// Window dimensions (unscaled)
const float FWND_W = 560.0;
const float FWND_H = 400.0;

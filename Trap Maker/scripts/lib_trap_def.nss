#include "lib_nui"
#include "sql_trap"

void TrapOpenCraftWindow(object oPC);
void TrapFeedRecipeList(object oPC, int nToken);
void TrapFeedRecipeDetail(object oPC, int nToken, int nIdx);
void TrapFeedComponentInventory(object oPC, int nToken);
void TrapHandleCraft(object oPC, int nToken);
void TrapEnterDeployMode(object oPC, int nToken);
void TrapPlaceAtLocation(object oPC, location lTarget);
void TrapHeartbeat(object oTrap);
void TrapTryDefuse(object oTrap);
void TrapFireEffect(object oTrap, object oTarget);
int  TrapCountComponent(object oPC, string sCompTag);
void TrapConsumeComponents(object oPC, int nRecipeIdx);
int  TrapCountPlacedByPC(object oPC);
json TrapGetRecipes();

// ================================================================
// NUI window
// ================================================================

const string TRAP_WIN_CRAFT         = "TRAP_WIN_CRAFT";
const string TRAP_EV_SCRIPT         = "lib_trap_ev";

// Bind: recipe list (left panel — NuiList)
const string TRAP_BIND_REC_NAME     = "trap_rec_name";
const string TRAP_BIND_REC_ENC      = "trap_rec_enc";
const string TRAP_BIND_REC_COLOR    = "trap_rec_color";
const string TRAP_BIND_REC_CNT      = "trap_rec_cnt";

// Bind: recipe detail (center panel)
const string TRAP_BIND_DET_TITLE    = "trap_det_title";
const string TRAP_BIND_DET_DESC     = "trap_det_desc";
const string TRAP_BIND_DET_EFFECT   = "trap_det_effect";

// Bind: component requirement rows (NuiList)
const string TRAP_BIND_COMP_NAME    = "trap_comp_name";
const string TRAP_BIND_COMP_NEED    = "trap_comp_need";
const string TRAP_BIND_COMP_HAVE    = "trap_comp_have";
const string TRAP_BIND_COMP_COLOR   = "trap_comp_color";
const string TRAP_BIND_COMP_CNT     = "trap_comp_cnt";

// Bind: bottom status
const string TRAP_BIND_CRAFT_ENA    = "trap_craft_ena";
const string TRAP_BIND_CRAFT_LBL    = "trap_craft_lbl";
const string TRAP_BIND_STATUS       = "trap_status";
const string TRAP_BIND_STATUS_COLOR = "trap_status_col";
const string TRAP_BIND_PLACED_LBL   = "trap_placed_lbl";

// Buttons
const string TRAP_BTN_CLOSE         = "trap_btn_close";
const string TRAP_BTN_REC_ROW       = "trap_btn_rec_row";
const string TRAP_BTN_CRAFT         = "trap_btn_craft";
const string TRAP_BTN_DEPLOY        = "trap_btn_deploy";

// LVARs on PC
const string TRAP_LVAR_SEL_IDX      = "TRAP_SEL_IDX";
const string TRAP_LVAR_DEPLOYING    = "TRAP_DEPLOYING";
const string TRAP_LVAR_DEPLOY_TYPE  = "TRAP_DEPLOY_TYPE";
const string TRAP_LVAR_DEPLOY_DARM  = "TRAP_DEPLOY_DISARM_DC";

// LVARs on placed trap placeable
const string TRAP_LVAR_TYPE         = "TRAP_TYPE";
const string TRAP_LVAR_SETTER_UUID  = "TRAP_SETTER_UUID";
const string TRAP_LVAR_SETTER_NAME  = "TRAP_SETTER_NAME";
const string TRAP_LVAR_DISARM_DC    = "TRAP_DISARM_DC";
const string TRAP_LVAR_DETECT_DC    = "TRAP_DETECT_DC";
const string TRAP_LVAR_ARMED        = "TRAP_ARMED";

// Script names set on placed placeable
const string TRAP_SCRIPT_HB         = "trap_hb";
const string TRAP_SCRIPT_DEF        = "trap_def";

// Component item tags (must match items in HAK / toolset)
const string TRAP_COMP_BLADE        = "TRAP_COMP_BLADE";
const string TRAP_COMP_SPRING       = "TRAP_COMP_SPRING";
const string TRAP_COMP_DART         = "TRAP_COMP_DART";
const string TRAP_COMP_POISON       = "TRAP_COMP_POISON";
const string TRAP_COMP_OIL          = "TRAP_COMP_OIL";
const string TRAP_COMP_FLINT        = "TRAP_COMP_FLINT";
const string TRAP_COMP_POWDER       = "TRAP_COMP_POWDER";
const string TRAP_COMP_GLASS        = "TRAP_COMP_GLASS";
const string TRAP_COMP_BELL         = "TRAP_COMP_BELL";
const string TRAP_COMP_WIRE         = "TRAP_COMP_WIRE";
const string TRAP_COMP_ROPE         = "TRAP_COMP_ROPE";
const string TRAP_COMP_HOOK         = "TRAP_COMP_HOOK";

// Trap type string constants
const string TRAP_TYPE_BLADE        = "BLADE";
const string TRAP_TYPE_DART         = "DART";
const string TRAP_TYPE_FLAME        = "FLAME";
const string TRAP_TYPE_STUN         = "STUN";
const string TRAP_TYPE_ALARM        = "ALARM";
const string TRAP_TYPE_SNARE        = "SNARE";

// Tags for the resulting trap items and placed placeables
const string TRAP_ITEM_PREFIX       = "TRAP_ITEM_";
const string TRAP_PLACED_PREFIX     = "TRAP_PLACED_";

// Resref for placed trap placeable (visible floor marker)
// Replace with a custom model in HAK for better visuals.
const string TRAP_PLACEA_RESREF     = "x2_plc_trap001";

// Proximity radius for heartbeat trigger check
const float  TRAP_TRIGGER_RADIUS    = 2.5;

// Max traps a single PC may have active at once
const int    TRAP_MAX_ACTIVE        = 5;

// Window dimensions
const float  TRAP_W                 = 700.0;
const float  TRAP_H                 = 500.0;

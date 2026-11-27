#include "lib_nui"
#include "sql_bb"

void BbOpenWindow(object oPC);
void BbFeedBeastList(object oPC, int nToken);
void BbFeedBeastDetails(object oPC, int nToken, int nBeastId);
void BbCaptureMode(object oPC);
void BbActivateBeast(object oPC, int nBeastId);
void BbDismissBeast(object oPC);
void BbDoRelease(object oPC, int nBeastId);
void BbFeedBeast(object oPC, int nBeastId);

// Window / event
const string BB_WINDOW      = "BB_WINDOW";
const string BB_EV_SCRIPT   = "lib_bb_ev";
const string BB_WIN_GEOM    = "bb_win_geom";

// List column binds
const string BB_BIND_ROW_NAME   = "bb_row_name";
const string BB_BIND_ROW_BOND   = "bb_row_bond";
const string BB_BIND_ROW_STATUS = "bb_row_status";
const string BB_BIND_ROW_ENC    = "bb_row_enc";
const string BB_BIND_ROW_COLOR  = "bb_row_color";
const string BB_BIND_ROW_COUNT  = "bb_rowcount";

// Detail panel binds
const string BB_BIND_DET_NAME   = "bb_det_name";
const string BB_BIND_DET_BOND_P = "bb_det_bond_p";
const string BB_BIND_DET_BOND_L = "bb_det_bond_l";
const string BB_BIND_DET_KILLS  = "bb_det_kills";
const string BB_BIND_DET_FLAVOR = "bb_det_flavor";
const string BB_BIND_DET_STATUS = "bb_det_status";

// Button enable binds
const string BB_BIND_BTN_ACT_ENA  = "bb_btn_act_ena";
const string BB_BIND_BTN_FEED_ENA = "bb_btn_feed_ena";
const string BB_BIND_BTN_REL_ENA  = "bb_btn_rel_ena";
const string BB_BIND_BTN_DIS_ENA  = "bb_btn_dis_ena";
const string BB_BIND_BTN_CAP_ENA  = "bb_btn_cap_ena";

// Button IDs
const string BB_BTN_CLOSE    = "bb_btn_close";
const string BB_BTN_CAPTURE  = "bb_btn_capture";
const string BB_BTN_DISMISS  = "bb_btn_dismiss";
const string BB_BTN_ACTIVATE = "bb_btn_activate";
const string BB_BTN_FEED     = "bb_btn_feed";
const string BB_BTN_RELEASE  = "bb_btn_release";
const string BB_BTN_ROW      = "bb_btn_row";

// Local vars on PC
const string BB_LVAR_SEL_ID    = "BB_SEL_ID";
const string BB_LVAR_BEAST_OBJ = "BB_BEAST_OBJ";
const string BB_LVAR_CAPTURING = "BB_CAPTURING";

// Gameplay config
const int    BB_MAX_BEASTS     = 5;
const int    BB_BOND_MAX       = 100;
const int    BB_BOND_FEED      = 15;        // bonding gained per feeding
const int    BB_HP_CAP_THRESH  = 25;        // must be below X% HP to capture
const int    BB_CAP_SKILL_DC   = 14;
const string BB_FOOD_TAG       = "bb_meat"; // tag of food item in HAK

// Bonding milestones for HP bonus grant
const int    BB_BOND_TIER_HP   = 80;        // bonding >= this grants +20 HP
const int    BB_BOND_TIER_FULL = 100;       // fully tamed

// Layout
const float  BB_W        = 640.0;
const float  BB_H        = 480.0;
const float  BB_LEFT_W   = 230.0;

// Polish flavor text by bonding tier (0-4 maps to 0,25,50,75,100)
const string BB_FLAVOR_0 = "Bestia patrzy na ciebie nieufnie, gotowa do ataku przy pierwszej okazji.";
const string BB_FLAVOR_1 = "W oczach bestii tli się niepewność — nie czysty strach, lecz oczekiwanie.";
const string BB_FLAVOR_2 = "Bestia toleruje twoją obecność, choć wciąż napięta jak struna.";
const string BB_FLAVOR_3 = "Bestia podąża za tobą — czujna, lecz posłuszna twym rozkazom.";
const string BB_FLAVOR_4 = "Więź jest silna. Dusza bestii związana z twoją jak łańcuchem z Ciemności.";

string BbGetFlavorText(int nBonding)
{
    if(nBonding >= 100) return BB_FLAVOR_4;
    if(nBonding >= 75)  return BB_FLAVOR_3;
    if(nBonding >= 50)  return BB_FLAVOR_2;
    if(nBonding >= 25)  return BB_FLAVOR_1;
    return BB_FLAVOR_0;
}

string BbBondingToBar(int nBonding)
{
    int nFill = nBonding / 10;  // 0-10 filled chars
    int i;
    string sFill = "";
    string sEmpty = "";
    for(i = 0; i < nFill; i++)       sFill  = sFill  + "#";
    for(i = nFill; i < 10; i++)      sEmpty = sEmpty + "-";
    return "[" + sFill + sEmpty + "] " + IntToString(nBonding) + "/100";
}

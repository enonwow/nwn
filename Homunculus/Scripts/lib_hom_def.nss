// lib_hom_def.nss — constants, bind IDs, and tier helpers for Homunculus module
#include "lib_nui"
#include "sql_hom"

void HomCreateWindow(object oPC);
void HomShowMain(object oPC, int nToken);
void HomShowRename(object oPC, int nToken);
void HomCheckMaintenance(object oPC);
void HomApplyPresenceVFX(object oPC);
void HomRemovePresenceVFX(object oPC);

// ----------------------------------------------------------------
// Window identifiers
// ----------------------------------------------------------------

const string HOM_WINDOW    = "HOM_WINDOW";
const string HOM_EV_SCRIPT = "lib_hom_ev";
const string HOM_GRP_SWAP  = "HOM_GRP_SWAP";
const string HOM_WIN_GEOM  = "hom_win_geom";

const float  HOM_W         = 620.0;
const float  HOM_H         = 490.0;

// ----------------------------------------------------------------
// Bind IDs — main (status) view
// ----------------------------------------------------------------

const string HOM_BIND_TITLE     = "hom_title";
const string HOM_BIND_BOND_LBL  = "hom_bond_lbl";  // e.g. "Więź: 4 / 10  •  Lojalny"
const string HOM_BIND_BOND_PROG = "hom_bond_prog";  // float 0.0–1.0 for progress bar
const string HOM_BIND_STATUS    = "hom_status";     // maintenance status sentence
const string HOM_BIND_STATUS_CLR= "hom_status_clr"; // color of status text
const string HOM_BIND_ANAME     = "hom_aname";      // ability name
const string HOM_BIND_ADESC     = "hom_adesc";      // ability description (multiline)
const string HOM_BIND_AENA      = "hom_aena";       // ability button enabled
const string HOM_BIND_ABTN_LBL  = "hom_abtn_lbl";  // button label (includes cooldown hint)
const string HOM_BIND_FEED_ENA  = "hom_feed_ena";   // feed button enabled
const string HOM_BIND_SAC_ENA   = "hom_sac_ena";    // sacrifice button enabled (bond=10 only)
const string HOM_BIND_LOG0      = "hom_log0";
const string HOM_BIND_LOG1      = "hom_log1";
const string HOM_BIND_LOG2      = "hom_log2";

// "No companion" craft panel bind
const string HOM_BIND_CRAFT_MSG = "hom_craft_msg";

// ----------------------------------------------------------------
// Bind IDs — rename view
// ----------------------------------------------------------------

const string HOM_BIND_NAME_TXT  = "hom_name_txt";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string HOM_BTN_CLOSE     = "hom_btn_close";
const string HOM_BTN_USE       = "hom_btn_use";
const string HOM_BTN_FEED      = "hom_btn_feed";
const string HOM_BTN_RENAME    = "hom_btn_rename";
const string HOM_BTN_SACRIFICE = "hom_btn_sac";
const string HOM_BTN_CRAFT     = "hom_btn_craft";
const string HOM_BTN_RENAME_OK = "hom_btn_rnok";
const string HOM_BTN_RENAME_CC = "hom_btn_rncc";

// ----------------------------------------------------------------
// Local variables on PC
// ----------------------------------------------------------------

const string HOM_LVAR_VIEW     = "HOM_VIEW";   // 0 = status, 1 = rename
const string HOM_LVAR_VFX_SLOT = "HOM_VFX";   // slot ID of the presence effect

// ----------------------------------------------------------------
// Gameplay constants
// ----------------------------------------------------------------

// Iounstone orbiting VFX symbolises the homunculus presence
const int    HOM_VFX            = VFX_DUR_IOUNSTONE_BLUE;

// Feed interval: companion expects sustenance every 24 hours (real time via campaign DB clock)
const int    HOM_FEED_INTERVAL  = 86400;

// If not fed within 48 hours, bond begins to collapse
const int    HOM_STARVE_TIMEOUT = 172800;

// Daily ability cooldown (one use per 24h)
const int    HOM_ABILITY_CD     = 86400;

// Crafting recipe: player must carry this many HOM_REAGENT_TAG items to create a companion
const string HOM_REAGENT_TAG    = "hom_reagent";
const int    HOM_REAGENT_NEEDED = 3;

// Feeding item (1 consumed per feeding)
const string HOM_FEED_ITEM_TAG  = "hom_feed";

// Max name length for the rename field
const int    HOM_MAX_NAME       = 32;

// ----------------------------------------------------------------
// Tier helpers — pure functions, no SQL
// ----------------------------------------------------------------

string HomTierName(int nBond)
{
    if(nBond <= 0) return "Martwy";
    if(nBond <= 2) return "Zaciekawiony";
    if(nBond <= 5) return "Lojalny";
    if(nBond <= 8) return "Oddany";
    return "Jednomyślny";
}

string HomAbilityName(int nBond)
{
    if(nBond <= 2) return "Percepcja Zagrożeń";
    if(nBond <= 5) return "Zbieraczka Składników";
    if(nBond <= 8) return "Tarcza Alchemiczna";
    return "Wzmocnienie Duszy";
}

string HomAbilityDesc(int nBond)
{
    if(nBond <= 2)
        return "Homunkulus wyostrzył zmysły i szepcze ostrzeżenia\n"
             + "o pobliskich wrogach i aktywnych pułapkach.\n"
             + "(Zasięg: 15 m — efekt natychmiastowy)";
    if(nBond <= 5)
        return "Wierna istotka przeszukuje zakamarki i wraca\n"
             + "z garścią alchemicznych składników.\n"
             + "(Otrzymujesz losowy reagent — 1×)";
    if(nBond <= 8)
        return "Homunkulus oplata cię błoną alchemicznej substancji,\n"
             + "wzmacniając pancerz i żywotność.\n"
             + "(+10 tymcz. HP,  +2 AC  przez 1 godzinę)";
    return "Istota wlewa w ciebie strumień skondensowanej esencji.\n"
         + "Twoje zmysły i refleks osiągają nadludzki poziom.\n"
         + "(+4 do wszystkich rzutów obronnych przez 30 minut)";
}

// Returns the resref of a random alchemical ingredient to give via the Scavenge ability.
string HomRandomIngredientResref()
{
    int nRoll = d4();
    if(nRoll == 1) return "nw_it_mpotion001"; // potion placeholder
    if(nRoll == 2) return "nw_it_mpotion002";
    if(nRoll == 3) return "nw_it_msmlmisc18"; // misc component
    return "nw_it_msmlmisc20";
}

#include "lib_nui"
#include "sql_fam"

void FamOpenWindow(object oPC);
void FeedBondingView(object oPC, int nToken);
void FeedMainView(object oPC, int nToken, json jFam);
void FamExecuteScout(object oPC, int nToken, json jFam);
void FamExecuteForage(object oPC, int nToken, json jFam);
void FamExecuteVigil(object oPC, int nToken, json jFam);
void FamExecuteCarry(object oPC, int nToken);
void FamExecuteDismiss(object oPC, int nToken, json jFam);

// ---- window / group IDs ----
const string FAM_WINDOW         = "FAM_WINDOW";
const string FAM_EV_SCRIPT      = "lib_fam_ev";
const string FAM_GRP_SWAP       = "FAM_GRP_SWAP";
const string FAM_WIN_GEOM       = "fam_win_geom";

// ---- familiar type constants ----
const int FAM_TYPE_RAVEN        = 0;
const int FAM_TYPE_CAT          = 1;
const int FAM_TYPE_TOAD         = 2;
const int FAM_TYPE_SPIDER       = 3;
const int FAM_TYPE_OWL          = 4;
const int FAM_TYPE_COUNT        = 5;

// ---- task IDs ----
const int FAM_TASK_IDLE         = 0;
const int FAM_TASK_FORAGE       = 1;

// ---- timing (seconds) ----
const int FAM_FORAGE_DURATION   = 300;  // 5 real minutes
const int FAM_SCOUT_COOLDOWN    = 120;  // 2 minutes between scouts
const int FAM_VIGIL_DURATION    = 600;  // 10 minutes of vigilance
const int FAM_HP_REGEN_ON_CHECK = 2;    // HP recovered each time UI is opened

// ---- HP cost per command ----
const int FAM_HP_COST_SCOUT     = 2;
const int FAM_HP_COST_FORAGE    = 3;
const int FAM_HP_COST_VIGIL     = 4;
const int FAM_HP_COST_CARRY     = 1;

// ---- forage item resrefs (place in HAK, see INTEGRATION.md) ----
const string FAM_ITEM_RAVEN     = "fam_loot_raven";
const string FAM_ITEM_CAT       = "fam_loot_cat";
const string FAM_ITEM_TOAD      = "fam_loot_toad";
const string FAM_ITEM_SPIDER    = "fam_loot_spider";
const string FAM_ITEM_OWL       = "fam_loot_owl";

// ---- bonding view binds ----
const string FAM_BIND_TYPE_DESC = "fam_type_desc";
const string FAM_BIND_BOND_ENA  = "fam_bond_ena";
const string FAM_BTN_TYPE       = "fam_btn_type"; // append IntToString(i)
const string FAM_BTN_BOND       = "fam_btn_bond";

// ---- main view binds ----
const string FAM_BIND_TITLE     = "fam_title";
const string FAM_BIND_BOND_LVL  = "fam_bond_lvl";
const string FAM_BIND_HP_TXT    = "fam_hp_txt";
const string FAM_BIND_STATUS    = "fam_status";
const string FAM_BIND_CARRY_TXT = "fam_carry_txt";

const string FAM_BIND_SCOUT_ENA = "fam_scout_ena";
const string FAM_BIND_SCOUT_LBL = "fam_scout_lbl";
const string FAM_BIND_FORAGE_ENA= "fam_forage_ena";
const string FAM_BIND_FORAGE_LBL= "fam_forage_lbl";
const string FAM_BIND_VIGIL_ENA = "fam_vigil_ena";
const string FAM_BIND_VIGIL_LBL = "fam_vigil_lbl";
const string FAM_BIND_CARRY_ENA = "fam_carry_ena";
const string FAM_BIND_CARRY_LBL = "fam_carry_lbl";
const string FAM_BIND_DISMISS_ENA = "fam_dismiss_ena";
const string FAM_BIND_DISMISS_LBL = "fam_dismiss_lbl";
const string FAM_BIND_RETRV_ENA = "fam_retrv_ena";
const string FAM_BIND_RETRV_LBL = "fam_retrv_lbl";

// ---- button IDs ----
const string FAM_BTN_SCOUT      = "fam_btn_scout";
const string FAM_BTN_FORAGE     = "fam_btn_forage";
const string FAM_BTN_VIGIL      = "fam_btn_vigil";
const string FAM_BTN_CARRY      = "fam_btn_carry";
const string FAM_BTN_DISMISS    = "fam_btn_dismiss";
const string FAM_BTN_RETRIEVE   = "fam_btn_retrieve";
const string FAM_BTN_RELEASE    = "fam_btn_release";
const string FAM_BTN_CLOSE      = "fam_btn_close";

// ---- local variables on PC ----
const string FAM_LVAR_SEL_TYPE  = "FAM_SEL_TYPE";   // chosen type in bonding view
const string FAM_LVAR_TARGETING = "FAM_TARGETING";  // 1 = carry targeting active
const string FAM_LVAR_PREV_HP   = "FAM_PREV_HP";    // previous familiar HP for display

// ---- layout dimensions ----
const float FAM_W               = 460.0;
const float FAM_H               = 400.0;

// ---- helper: familiar type display name ----
string FamTypeName(int nType)
{
    switch(nType)
    {
        case FAM_TYPE_RAVEN:  return "Kruk";
        case FAM_TYPE_CAT:    return "Czarny Kot";
        case FAM_TYPE_TOAD:   return "Jadowita Ropucha";
        case FAM_TYPE_SPIDER: return "Tkacz-Cień";
        case FAM_TYPE_OWL:    return "Puchacz";
    }
    return "Nieznany";
}

// ---- helper: description shown in bonding view ----
string FamTypeDesc(int nType)
{
    switch(nType)
    {
        case FAM_TYPE_RAVEN:
            return "Kruk widzi wszystko z góry. Potrafi zwiadować teren "
                   "i przynosić błyskotki znalezione wzdłuż drogi.\n\n"
                   "Zwiad: Wykrywa wrogów w pobliżu.\n"
                   "Zbieranie: Przynosi złoto i drobiazgi.";
        case FAM_TYPE_CAT:
            return "Czarny Kot porusza się niezauważony w ciemności. "
                   "Wyczuwa magię i zbiera alchemiczne składniki.\n\n"
                   "Zwiad: Wykrywa ukrytych wrogów.\n"
                   "Zbieranie: Przynosi zioła i surowce.";
        case FAM_TYPE_TOAD:
            return "Jadowita Ropucha kryje się w bagnach i zna tajemnice "
                   "trucizn. Zbiera rzadkie grzyby i składniki.\n\n"
                   "Zwiad: Ostrzega przed zatruciem w obszarze.\n"
                   "Zbieranie: Przynosi trujące zioła i grzyby.";
        case FAM_TYPE_SPIDER:
            return "Tkacz-Cień snuje sieć ostrzeżeń. Czuje każde drganie "
                   "podłoża i ostrzega przed skradającymi się wrogami.\n\n"
                   "Zwiad: Wykrywa ukrytych i niewidzialnych.\n"
                   "Zbieranie: Przynosi kokonowe składniki i jad.";
        case FAM_TYPE_OWL:
            return "Puchacz widzi w ciemności i zna przyszłość. Strzeże "
                   "podczas odpoczynku i wyczuwa nieszczęście.\n\n"
                   "Zwiad: Ostrzega przed nadchodzącą walką.\n"
                   "Zbieranie: Przynosi magiczne pióra i runy.";
    }
    return "";
}

// ---- helper: bond level (1–5) from XP ----
int FamBondLevel(int nBondXp)
{
    int nLevel = nBondXp / FAM_BOND_STEPS + 1;
    if(nLevel > 5) nLevel = 5;
    return nLevel;
}

// ---- helper: bond level display name ----
string FamBondName(int nLevel)
{
    switch(nLevel)
    {
        case 1: return "Obcość";
        case 2: return "Znajomość";
        case 3: return "Towarzystwo";
        case 4: return "Więź";
        case 5: return "Duch-Brat";
    }
    return "Obcość";
}

// ---- helper: star rating string for bond level ----
string FamBondStars(int nLevel)
{
    string sFull = "★";
    string sEmpty= "☆";
    string s = "";
    int i;
    for(i = 1; i <= 5; i++)
        s = s + (i <= nLevel ? sFull : sEmpty);
    return s;
}

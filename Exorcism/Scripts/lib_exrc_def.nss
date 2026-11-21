#include "lib_nui"
#include "sql_exrc"

void ExrcOpenDetectWindow(object oPC, object oTarget);
void ExrcOpenRitualWindow(object oPC, object oTarget);
void ExrcFeedRitual(object oPC, int nToken);
void ExrcApplyPossessionEffects(object oPC, int nLevel);
void ExrcRemovePossessionEffects(object oPC);
void ExrcInflictPossession(object oPC, int nLevel, string sEntity);
void ExrcTickTimer(object oPC);
void ExrcHandleTimeout(object oPC);
void ExrcScheduleWhispers(object oPC);

// ----------------------------------------------------------------
// Window / script IDs
// ----------------------------------------------------------------

const string EXRC_WINDOW     = "EXRC_WINDOW";
const string EXRC_WIN_DETECT = "EXRC_WIN_DETECT";
const string EXRC_EV_SCRIPT  = "lib_exrc_ev";
const string EXRC_WIN_GEOM   = "exrc_win_geom";
const string EXRC_DET_GEOM   = "exrc_det_geom";

// ----------------------------------------------------------------
// Bind names — ritual window
// ----------------------------------------------------------------

const string EXRC_BIND_TNAME      = "exrc_tname";
const string EXRC_BIND_LVL_TXT    = "exrc_lvl_txt";
const string EXRC_BIND_LVL_COL    = "exrc_lvl_col";
const string EXRC_BIND_ENT_TXT    = "exrc_ent_txt";
const string EXRC_BIND_WATER      = "exrc_water";
const string EXRC_BIND_SEQ_IMG    = "exrc_seq_img";     // list bind — 4 icons
const string EXRC_BIND_SEQ_CNT    = "exrc_seq_cnt";
const string EXRC_BIND_SEQ_COL    = "exrc_seq_col";     // per-slot colour (green when hit)
const string EXRC_BIND_PROG_TXT   = "exrc_prog";
const string EXRC_BIND_TIMER      = "exrc_timer";
const string EXRC_BIND_RESULT     = "exrc_result";
const string EXRC_BIND_RESULT_COL = "exrc_result_col";
const string EXRC_BIND_BEGIN_ENA  = "exrc_begin_ena";
const string EXRC_BIND_SYMS_ENA   = "exrc_syms_ena";    // list bind — 6 booleans
const string EXRC_BIND_SYMS_IMG   = "exrc_syms_img";    // list bind — 6 icons

// ----------------------------------------------------------------
// Bind names — detect window
// ----------------------------------------------------------------

const string EXRC_BIND_DET_NAME = "exrc_det_name";
const string EXRC_BIND_DET_LVL  = "exrc_det_lvl";
const string EXRC_BIND_DET_ENT  = "exrc_det_ent";
const string EXRC_BIND_DET_AGE  = "exrc_det_age";
const string EXRC_BIND_DET_EXNA = "exrc_det_exna";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string EXRC_BTN_CLOSE    = "exrc_btn_close";
const string EXRC_BTN_BEGIN    = "exrc_btn_begin";
const string EXRC_BTN_SYM      = "exrc_btn_sym";        // + IntToString(i)

const string EXRC_BTN_DETCLOSE = "exrc_btn_detcls";
const string EXRC_BTN_EXORCISE = "exrc_btn_exrc";

// ----------------------------------------------------------------
// LVARs on exorcist PC
// ----------------------------------------------------------------

const string EXRC_LVAR_TARGET   = "EXRC_TARGET";
const string EXRC_LVAR_SEQUENCE = "EXRC_SEQUENCE";      // JsonArray of 4 ints
const string EXRC_LVAR_PROGRESS = "EXRC_PROGRESS";
const string EXRC_LVAR_STARTED  = "EXRC_STARTED";
const string EXRC_LVAR_DEADLINE = "EXRC_DEADLINE";      // stored as int (unix seconds)

// ----------------------------------------------------------------
// Possession levels
// ----------------------------------------------------------------

const int EXRC_LEVEL_CLEAN      = 0;
const int EXRC_LEVEL_WHISPERS   = 1;    // Szepty demonów
const int EXRC_LEVEL_DOMINATED  = 2;    // Opanowanie
const int EXRC_LEVEL_MANIFESTED = 3;    // Manifestacja

// ----------------------------------------------------------------
// Ritual config
// ----------------------------------------------------------------

const int   EXRC_SEQ_LENGTH      = 4;
const int   EXRC_SYMBOL_COUNT    = 6;
const float EXRC_RITUAL_TIMEOUT  = 35.0;
const string EXRC_HOLY_WATER_TAG  = "exrc_holy_water";
const string EXRC_EFFECT_TAG      = "EXRC_EFFECT";

// Icon resrefs for the 6 ritual symbols (TGA files in HAK).
// Replace with custom artwork or reuse stock NWN spell icons.
const string EXRC_ICON_0 = "is_blessng";    // Krzyż
const string EXRC_ICON_1 = "is_holywrd";    // Słowo Święte
const string EXRC_ICON_2 = "is_divinef";    // Boska Tarcza
const string EXRC_ICON_3 = "is_recallp";    // Znak Cofnięcia
const string EXRC_ICON_4 = "is_resurr";     // Zmartwychwstanie
const string EXRC_ICON_5 = "is_death2";     // Pieczęć Śmierci

// ----------------------------------------------------------------
// Window layout
// ----------------------------------------------------------------

const float EXRC_WIN_W = 480.0;
const float EXRC_WIN_H = 520.0;
const float EXRC_DET_W = 420.0;
const float EXRC_DET_H = 280.0;

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------

string ExrcGetIconByIndex(int nIdx)
{
    if(nIdx == 0) return EXRC_ICON_0;
    if(nIdx == 1) return EXRC_ICON_1;
    if(nIdx == 2) return EXRC_ICON_2;
    if(nIdx == 3) return EXRC_ICON_3;
    if(nIdx == 4) return EXRC_ICON_4;
    return EXRC_ICON_5;
}

string ExrcGetLevelName(int nLevel)
{
    if(nLevel == EXRC_LEVEL_WHISPERS)   return "Szepty demonów";
    if(nLevel == EXRC_LEVEL_DOMINATED)  return "Opanowanie";
    if(nLevel == EXRC_LEVEL_MANIFESTED) return "Manifestacja";
    return "Czysta dusza";
}

json ExrcGetLevelColor(int nLevel)
{
    if(nLevel == EXRC_LEVEL_WHISPERS)   return NuiColor(220, 200, 50);
    if(nLevel == EXRC_LEVEL_DOMINATED)  return NuiColor(220, 100, 50);
    if(nLevel == EXRC_LEVEL_MANIFESTED) return NuiColor(180,  30, 30);
    return NuiColor(120, 200, 120);
}

// Returns how many holy water vials the ritual requires for this target's level
int ExrcWaterCost(int nLevel)
{
    return nLevel;   // level 1 = 1 vial, level 2 = 2, level 3 = 3
}

int ExrcCountHolyWater(object oPC)
{
    int nCount = 0;
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem))
    {
        if(GetTag(oItem) == EXRC_HOLY_WATER_TAG)
            nCount += GetItemStackSize(oItem);
        oItem = GetNextItemInInventory(oPC);
    }
    return nCount;
}

void ExrcConsumeHolyWater(object oPC, int nAmount)
{
    int nLeft = nAmount;
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem) && nLeft > 0)
    {
        if(GetTag(oItem) == EXRC_HOLY_WATER_TAG)
        {
            int nStack = GetItemStackSize(oItem);
            if(nStack <= nLeft)
            {
                nLeft -= nStack;
                DestroyObject(oItem);
            }
            else
            {
                SetItemStackSize(oItem, nStack - nLeft);
                nLeft = 0;
            }
        }
        oItem = GetNextItemInInventory(oPC);
    }
}

// Returns the unix time from the campaign DB (portable across NWN versions)
int ExrcNowUnix()
{
    sqlquery q = SqlPrepareQueryCampaign("exorcism",
        "SELECT CAST(strftime('%s','now') AS INTEGER)");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

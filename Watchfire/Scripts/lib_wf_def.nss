// lib_wf_def.nss — Watchfire: constants, recipe data, forward declarations

#include "lib_nui"
#include "sql_wf"

void WfOpenWindow(object oPC, object oCampfire);
void WfFeedCampTab(object oPC, int nToken);
void WfFeedCookTab(object oPC, int nToken);
void WfFeedJournalTab(object oPC, int nToken);
void WfDoRest(object oPC, int nToken, int nType);   // nType: 0=short, 1=long
void WfDoWake(object oPC, int nToken);
void WfDoCook(object oPC, int nToken);

// ----------------------------------------------------------------
// Window / layout
// ----------------------------------------------------------------

const string WF_WINDOW      = "WF_WINDOW";
const string WF_EV_SCRIPT   = "lib_wf_ev";
const string WF_GRP_TABS    = "WF_GRP_TABS";
const string WF_WIN_GEOM    = "wf_win_geom";

const float  WF_W  = 680.0;
const float  WF_H  = 500.0;

// ----------------------------------------------------------------
// Tabs
// ----------------------------------------------------------------

const int WF_TAB_CAMP  = 0;
const int WF_TAB_COOK  = 1;
const int WF_TAB_LOG   = 2;

// ----------------------------------------------------------------
// Buttons
// ----------------------------------------------------------------

const string WF_BTN_CLOSE      = "wf_btn_close";
const string WF_BTN_TAB_CAMP   = "wf_btn_tab_camp";
const string WF_BTN_TAB_COOK   = "wf_btn_tab_cook";
const string WF_BTN_TAB_LOG    = "wf_btn_tab_log";
const string WF_BTN_REST_SHORT = "wf_btn_rest_s";
const string WF_BTN_REST_LONG  = "wf_btn_rest_l";
const string WF_BTN_WAKE       = "wf_btn_wake";
const string WF_BTN_WATCH      = "wf_btn_watch";
const string WF_BTN_COOK       = "wf_btn_cook";
const string WF_BTN_REC_ROW    = "wf_btn_rec";

// ----------------------------------------------------------------
// Binds — camp tab
// ----------------------------------------------------------------

const string WF_BIND_STATUS_LBL   = "wf_status_lbl";
const string WF_BIND_DANGER_LBL   = "wf_danger_lbl";
const string WF_BIND_WATCH_LBL    = "wf_watch_lbl";
const string WF_BIND_WATCH_ENA    = "wf_watch_ena";
const string WF_BIND_REST_S_ENA   = "wf_rest_s_ena";
const string WF_BIND_REST_L_ENA   = "wf_rest_l_ena";
const string WF_BIND_WAKE_ENA     = "wf_wake_ena";
const string WF_BIND_RESULT_LBL   = "wf_result_lbl";

// ----------------------------------------------------------------
// Binds — cook tab
// ----------------------------------------------------------------

const string WF_BIND_REC_NAME     = "wf_rec_name";
const string WF_BIND_REC_EFF      = "wf_rec_eff";
const string WF_BIND_REC_ENC      = "wf_rec_enc";
const string WF_BIND_REC_COUNT    = "wf_rec_count";
const string WF_BIND_CAN_COOK     = "wf_can_cook";
const string WF_BIND_CAN_COOK_ENA = "wf_can_cook_ena";
const string WF_BIND_COOK_ENA     = "wf_cook_ena";
const string WF_BIND_COOK_MSG     = "wf_cook_msg";

// ----------------------------------------------------------------
// Binds — journal tab
// ----------------------------------------------------------------

const string WF_BIND_LOG_DAY      = "wf_log_day";
const string WF_BIND_LOG_AREA     = "wf_log_area";
const string WF_BIND_LOG_TYPE     = "wf_log_type";
const string WF_BIND_LOG_ENC      = "wf_log_enc";
const string WF_BIND_LOG_MEAL     = "wf_log_meal";
const string WF_BIND_LOG_ROW_CNT  = "wf_log_cnt";

// ----------------------------------------------------------------
// LVARs on PC
// ----------------------------------------------------------------

const string WF_LVAR_TAB          = "WF_TAB";
const string WF_LVAR_CAMPFIRE     = "WF_CAMPFIRE";
const string WF_LVAR_STATE        = "WF_STATE";       // 0=idle, 1=resting
const string WF_LVAR_WATCH_ON     = "WF_WATCH_ON";    // 1=keeping watch
const string WF_LVAR_REST_TYPE    = "WF_REST_TYPE";   // 0=short, 1=long
const string WF_LVAR_SEL_REC      = "WF_SEL_REC";     // selected recipe index
const string WF_LVAR_RESULT       = "WF_RESULT";      // last rest result string
const string WF_LVAR_ENCOUNTER    = "WF_ENCOUNTER";   // 1=had encounter this rest
const string WF_LVAR_MEAL_NAME    = "WF_MEAL_NAME";   // name of meal cooked this rest

// LVARs on Campfire object
const string WF_OVAR_DANGER       = "WF_DANGER";      // 0-5, set by DM via toolset

// ----------------------------------------------------------------
// States
// ----------------------------------------------------------------

const int WF_STATE_IDLE    = 0;
const int WF_STATE_RESTING = 1;

// ----------------------------------------------------------------
// Recipes  (6 total, indexed 0-5)
// Each recipe: name, effect description, ingredient1 tag, ingredient2 tag (or "" if none)
// ----------------------------------------------------------------

const int WF_RECIPE_COUNT = 6;

string WfRecipeName(int nIdx)
{
    if(nIdx == 0) return "Ogrzewający Wywar";
    if(nIdx == 1) return "Leśny Napar";
    if(nIdx == 2) return "Wojownicza Zupa";
    if(nIdx == 3) return "Wiedźmia Mieszanka";
    if(nIdx == 4) return "Krew Wilka";
    if(nIdx == 5) return "Mroczna Herbata";
    return "";
}

string WfRecipeEffect(int nIdx)
{
    if(nIdx == 0) return "Regeneracja 1 PŻ/rundę przez 1 godz.";
    if(nIdx == 1) return "Natychmiastowe leczenie: 10 PŻ";
    if(nIdx == 2) return "+2 Siła przez 2 godz.";
    if(nIdx == 3) return "+3 Spostrzegawczość i Słuch przez 2 godz.";
    if(nIdx == 4) return "+15 tymczasowych PŻ przez 2 godz.";
    if(nIdx == 5) return "+3 Koncentracja i +1 Mądrość przez 2 godz.";
    return "";
}

string WfRecipeIng1(int nIdx)
{
    if(nIdx == 0) return "wf_herb_fire";
    if(nIdx == 1) return "wf_herb_heal";
    if(nIdx == 2) return "wf_meat";
    if(nIdx == 3) return "wf_herb_mind";
    if(nIdx == 4) return "wf_meat";
    if(nIdx == 5) return "wf_dark_water";
    return "";
}

string WfRecipeIng2(int nIdx)
{
    if(nIdx == 0) return "wf_ration";
    if(nIdx == 1) return "";
    if(nIdx == 2) return "wf_herb_power";
    if(nIdx == 3) return "wf_dark_water";
    if(nIdx == 4) return "wf_ration";
    if(nIdx == 5) return "wf_herb_mind";
    return "";
}

string WfRecipeIngLabel(int nIdx)
{
    string s1 = WfRecipeIng1(nIdx);
    string s2 = WfRecipeIng2(nIdx);
    if(s2 == "") return s1;
    return s1 + " + " + s2;
}

// Returns TRUE if the PC has all required ingredients in inventory
int WfHasIngredients(object oPC, int nIdx)
{
    string s1 = WfRecipeIng1(nIdx);
    string s2 = WfRecipeIng2(nIdx);

    object oI1 = GetItemPossessedBy(oPC, s1);
    if(!GetIsObjectValid(oI1)) return FALSE;
    if(s2 == "") return TRUE;

    // If both ingredients are the same tag, need 2 of them
    if(s1 == s2)
    {
        object oI2 = GetNextItemInInventory(oPC);
        while(GetIsObjectValid(oI2))
        {
            if(GetTag(oI2) == s2 && oI2 != oI1) return TRUE;
            oI2 = GetNextItemInInventory(oPC);
        }
        return FALSE;
    }
    return GetIsObjectValid(GetItemPossessedBy(oPC, s2));
}

// Consume ingredients from PC inventory
void WfConsumeIngredients(object oPC, int nIdx)
{
    string s1 = WfRecipeIng1(nIdx);
    string s2 = WfRecipeIng2(nIdx);

    object oI1 = GetItemPossessedBy(oPC, s1);
    if(GetIsObjectValid(oI1)) DestroyObject(oI1);

    if(s2 == "" || s1 == s2) return;

    object oI2 = GetItemPossessedBy(oPC, s2);
    if(GetIsObjectValid(oI2)) DestroyObject(oI2);
}

// Apply meal buff to PC
void WfApplyMealBuff(object oPC, int nIdx)
{
    float fDur2h = 7200.0;
    float fDur1h = 3600.0;

    if(nIdx == 0)
    {
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
            EffectRegenerate(1, 6.0), oPC, fDur1h);
    }
    else if(nIdx == 1)
    {
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(10), oPC);
    }
    else if(nIdx == 2)
    {
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
            EffectAbilityIncrease(ABILITY_STRENGTH, 2), oPC, fDur2h);
    }
    else if(nIdx == 3)
    {
        effect eSpot   = EffectSkillIncrease(SKILL_SPOT,   3);
        effect eListen = EffectSkillIncrease(SKILL_LISTEN, 3);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eSpot,   oPC, fDur2h);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eListen, oPC, fDur2h);
    }
    else if(nIdx == 4)
    {
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
            EffectTemporaryHitpoints(15), oPC, fDur2h);
    }
    else if(nIdx == 5)
    {
        effect eConc = EffectSkillIncrease(SKILL_CONCENTRATION, 3);
        effect eWis  = EffectAbilityIncrease(ABILITY_WISDOM, 1);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eConc, oPC, fDur2h);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eWis,  oPC, fDur2h);
    }
}

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------

int WfGetDangerLevel(object oCampfire)
{
    int nDanger = GetLocalInt(oCampfire, WF_OVAR_DANGER);
    if(nDanger < 0) nDanger = 0;
    if(nDanger > 5) nDanger = 5;
    return nDanger;
}

string WfDangerLabel(int nDanger)
{
    if(nDanger == 0) return "Spokojne";
    if(nDanger == 1) return "Niskie";
    if(nDanger == 2) return "Umiarkowane";
    if(nDanger == 3) return "Wysokie";
    if(nDanger == 4) return "Bardzo wysokie";
    return "Śmiertelne";
}

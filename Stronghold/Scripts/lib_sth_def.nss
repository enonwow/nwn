#include "lib_nui"
#include "sql_sth"

void StrongholdOpen(object oPC);
void StrongholdApplyBonuses(object oPC);
void StrongholdCheckUpgrades(object oPC);
void StrongholdFeedGrid(object oPC, int nToken);
void StrongholdFeedDetail(object oPC, int nToken, int nBldId);

// ----------------------------------------------------------------
// Window / event IDs
// ----------------------------------------------------------------

const string STH_WINDOW       = "STH_WINDOW";
const string STH_EV_SCRIPT    = "lib_sth_ev";

// Bind names
const string STH_BIND_HEADER  = "sth_header";
const string STH_BIND_GOLD    = "sth_gold";

const string STH_BIND_BLD_NAME = "sth_bld_name";  // + IntToString(i)
const string STH_BIND_BLD_LVL  = "sth_bld_lvl";
const string STH_BIND_BLD_SUB  = "sth_bld_sub";
const string STH_BIND_BLD_ENC  = "sth_bld_enc";

const string STH_BIND_SEL_VIS  = "sth_sel_vis";
const string STH_BIND_SEL_HDR  = "sth_sel_hdr";
const string STH_BIND_SEL_DESC = "sth_sel_desc";
const string STH_BIND_SEL_EFF  = "sth_sel_eff";
const string STH_BIND_SEL_NEXT = "sth_sel_next";
const string STH_BIND_UPG_LBL  = "sth_upg_lbl";
const string STH_BIND_UPG_ENA  = "sth_upg_ena";
const string STH_BIND_CAN_ENA  = "sth_can_ena";
const string STH_WIN_GEOM      = "sth_win_geom";

// Button IDs
const string STH_BTN_CLOSE    = "sth_btn_close";
const string STH_BTN_BLD      = "sth_btn_bld";   // + IntToString(i)
const string STH_BTN_UPGRADE  = "sth_btn_upg";
const string STH_BTN_CANCEL   = "sth_btn_can";

// LVARs on PC
const string STH_LVAR_SEL     = "STH_SEL_BLD";   // selected building id (-1 = none)

// Building IDs
const int STH_BLD_BARRACKS    = 0;
const int STH_BLD_LAB         = 1;
const int STH_BLD_CHAPEL      = 2;
const int STH_BLD_LIBRARY     = 3;
const int STH_BLD_DUNGEON     = 4;
const int STH_BLD_WATCHTOWER  = 5;
const int STH_BLD_COUNT       = 6;
const int STH_MAX_LEVEL       = 3;

// Effect tag used to identify all stronghold bonuses
const string STH_EFFECT_TAG   = "STH_BONUS";

// Window dimensions
const float STH_W             = 630.0;
const float STH_H             = 530.0;

// ----------------------------------------------------------------
// Building data helpers
// ----------------------------------------------------------------

int StrongholdUpgradeCost(int nTargetLevel)
{
    switch(nTargetLevel)
    {
        case 1: return 500;
        case 2: return 1500;
        case 3: return 3000;
    }
    return 0;
}

// Delay in seconds before an upgrade finishes
float StrongholdUpgradeDelay(int nTargetLevel)
{
    switch(nTargetLevel)
    {
        case 1: return 60.0;
        case 2: return 300.0;
        case 3: return 600.0;
    }
    return 60.0;
}

string StrongholdBuildingName(int nBldId)
{
    switch(nBldId)
    {
        case STH_BLD_BARRACKS:   return "Koszary";
        case STH_BLD_LAB:        return "Laboratorium";
        case STH_BLD_CHAPEL:     return "Kaplica";
        case STH_BLD_LIBRARY:    return "Biblioteka";
        case STH_BLD_DUNGEON:    return "Lochy";
        case STH_BLD_WATCHTOWER: return "Wieżyczka";
    }
    return "?";
}

string StrongholdBuildingDesc(int nBldId)
{
    switch(nBldId)
    {
        case STH_BLD_BARRACKS:
            return "Wyszkoleni żołnierze śpią w twoich murach. Ich dyscyplina jest zaraźliwa — budzisz się ostrzejszy.";
        case STH_BLD_LAB:
            return "Alchemiczne athanory trzaszczą nocami. Esencje destylowane tu chronią umysł przed mrokiem zaklęć.";
        case STH_BLD_CHAPEL:
            return "Bóstwo jest martwe, lecz jego kości wciąż oddają ciepło. Modlitwy tu odmawiane krzepiły ciało przed śmiercią.";
        case STH_BLD_LIBRARY:
            return "Półki uginają się od zakazanych tomów. Wiedza tu zebrana skala, lecz i ocala — widzisz świat dokładniej.";
        case STH_BLD_DUNGEON:
            return "Podziemne komnaty uczą milczenia i obserwacji. Spojrzenie, które spędziło tu godzinę, niczemu już nie ufa.";
        case STH_BLD_WATCHTOWER:
            return "Stąd widać wszystko: nadciągającego wroga, ranę na linii horyzontu, cień w cieniu. Nic nie umknie twej uwadze.";
    }
    return "";
}

string StrongholdBuildingEffectDesc(int nBldId, int nLevel)
{
    if(nLevel <= 0)
        return "Ruina — budynek nie daje żadnych premii.";

    switch(nBldId)
    {
        case STH_BLD_BARRACKS:
            switch(nLevel)
            {
                case 1: return "+1 do trafienia";
                case 2: return "+2 do trafienia";
                case 3: return "+2 do trafienia, +2 do obrażeń";
            }
            break;
        case STH_BLD_LAB:
            switch(nLevel)
            {
                case 1: return "+1 do wszystkich rzutów obronnych";
                case 2: return "+2 do wszystkich rzutów obronnych";
                case 3: return "+2 do rzutów obronnych, +4 odporności na zaklęcia";
            }
            break;
        case STH_BLD_CHAPEL:
            switch(nLevel)
            {
                case 1: return "+10 tymczasowych punktów życia";
                case 2: return "+20 tymczasowych punktów życia";
                case 3: return "+30 tymczasowych punktów życia";
            }
            break;
        case STH_BLD_LIBRARY:
            switch(nLevel)
            {
                case 1: return "+3 do Lore i Appraise";
                case 2: return "+5 do Lore i Appraise";
                case 3: return "+5 do Lore i Appraise, +1 Inteligencji";
            }
            break;
        case STH_BLD_DUNGEON:
            switch(nLevel)
            {
                case 1: return "+3 do Zastraszania (Intimidate)";
                case 2: return "+3 Intimidate, +2 Perswazji (Persuade)";
                case 3: return "+4 Intimidate, +3 Persuade, +1 AC";
            }
            break;
        case STH_BLD_WATCHTOWER:
            switch(nLevel)
            {
                case 1: return "+3 do Spostrzegawczości i Słuchu";
                case 2: return "+4 Spot/Listen, +3 Przeszukiwania (Search)";
                case 3: return "+5 Spot/Listen/Search, +2 Tumble";
            }
            break;
    }
    return "";
}

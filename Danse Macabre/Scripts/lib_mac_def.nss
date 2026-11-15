#include "lib_nui"
#include "sql_mac"

void MacOpenWindow(object oPC);
void MacShowBargainView(object oPC, int nToken);
void MacShowMainView(object oPC, int nToken);
void MacFeedMainView(object oPC, int nToken);
void MacFeedBargainView(object oPC, int nToken);
void MacSendOmen(object oPC, int nProximity);
void MacApplyProximityEffects(object oPC, int nOldProximity, int nNewProximity);

// ----------------------------------------------------------------
// Window / event identifiers
// ----------------------------------------------------------------

const string MAC_WINDOW      = "MAC_WINDOW";
const string MAC_EV_SCRIPT   = "lib_mac_ev";
const string MAC_GRP_SWAP    = "MAC_GRP_SWAP";
const string MAC_WIN_GEOM    = "mac_win_geom";

// Main view binds
const string MAC_BIND_PROXIMITY_VAL  = "mac_prox_val";
const string MAC_BIND_PROXIMITY_BAR  = "mac_prox_bar";
const string MAC_BIND_TIER_LABEL     = "mac_tier_lbl";
const string MAC_BIND_TIER_COLOR     = "mac_tier_color";
const string MAC_BIND_OMEN_TEXT      = "mac_omen_text";
const string MAC_BIND_OMEN_PROX      = "mac_omen_prox";
const string MAC_BIND_OMEN_COLOR     = "mac_omen_color";
const string MAC_BIND_OMEN_COUNT     = "mac_omen_count";
const string MAC_BIND_CONTRACT_TYPE  = "mac_ctr_type";
const string MAC_BIND_CONTRACT_SAC   = "mac_ctr_sac";
const string MAC_BIND_CONTRACT_DATE  = "mac_ctr_date";
const string MAC_BIND_CONTRACT_ENC   = "mac_ctr_enc";
const string MAC_BIND_CONTRACT_COUNT = "mac_ctr_count";
const string MAC_BIND_HEADER_LBL     = "mac_header_lbl";

// Bargain view binds
const string MAC_BIND_BARG_FLAVOR    = "mac_barg_flavor";
const string MAC_BIND_BARG_COST1     = "mac_barg_cost1";
const string MAC_BIND_BARG_COST2     = "mac_barg_cost2";
const string MAC_BIND_BARG_COST3     = "mac_barg_cost3";
const string MAC_BIND_BARG_MEM_TXT   = "mac_barg_mem";
const string MAC_BIND_BARG_MEM_ENA   = "mac_barg_mem_ena";

// Buttons
const string MAC_BTN_CLOSE           = "mac_btn_close";
const string MAC_BTN_OFFER_HP        = "mac_btn_hp";
const string MAC_BTN_OFFER_GOLD      = "mac_btn_gold";
const string MAC_BTN_OFFER_XP        = "mac_btn_xp";
const string MAC_BTN_OFFER_MEMORY    = "mac_btn_mem";
const string MAC_BTN_REFUSE          = "mac_btn_refuse";
const string MAC_BTN_CONTRACT_ROW    = "mac_btn_ctr_row";

// LVARs on PC
const string MAC_LVAR_IN_BARGAIN     = "MAC_IN_BARGAIN";
const string MAC_LVAR_MEM_DRAFT      = "MAC_MEM_DRAFT";

// Contract types
const int MAC_CONTRACT_HP      = 1;  // sacrificed HP
const int MAC_CONTRACT_GOLD    = 2;  // sacrificed gold
const int MAC_CONTRACT_XP      = 3;  // sacrificed XP
const int MAC_CONTRACT_MEMORY  = 4;  // sacrificed a memory
const int MAC_CONTRACT_REFUSED = 5;  // refused, took damage

// Proximity tier thresholds
const int MAC_TIER_SAFE     = 25;
const int MAC_TIER_WATCHED  = 50;
const int MAC_TIER_STALKED  = 75;
const int MAC_TIER_IMMINENT = 100;

// Gold cost for the gold bargain
const int MAC_BARGAIN_GOLD_COST = 1000;

// Constitution reduction for the HP bargain (Con -2 → roughly -1 to -2 max HP per level)
const int MAC_BARGAIN_HP_COST = 2;

// XP fraction lost for the XP bargain (integer percent)
const int MAC_BARGAIN_XP_PCT = 8;

// Layout
const float MAC_WIN_W = 500.0;
const float MAC_WIN_H = 560.0;

// ----------------------------------------------------------------
// Proximity tier helpers
// ----------------------------------------------------------------

string MacGetTierLabel(int nProximity)
{
    if(nProximity >= MAC_TIER_IMMINENT)
        return "NIEUCHRONNA";
    if(nProximity >= MAC_TIER_STALKED)
        return "Skrada sie za toba";
    if(nProximity >= MAC_TIER_WATCHED)
        return "Obserwuje cie";
    if(nProximity >= MAC_TIER_SAFE)
        return "Czai sie w cieniu";
    return "Spoczywa w oddali";
}

json MacGetTierColor(int nProximity)
{
    if(nProximity >= MAC_TIER_IMMINENT)  return NuiColor(220,  40,  40);
    if(nProximity >= MAC_TIER_STALKED)   return NuiColor(200, 100,  30);
    if(nProximity >= MAC_TIER_WATCHED)   return NuiColor(180, 160,  40);
    if(nProximity >= MAC_TIER_SAFE)      return NuiColor(140, 140, 140);
    return                                      NuiColor( 90,  90,  90);
}

json MacGetOmenColor(int nProximity)
{
    if(nProximity >= MAC_TIER_STALKED) return NuiColor(200,  70,  70);
    if(nProximity >= MAC_TIER_WATCHED) return NuiColor(180, 140,  60);
    return                                    NuiColor(130, 130, 130);
}

string MacGetContractTypeName(int nType)
{
    switch(nType)
    {
        case MAC_CONTRACT_HP:      return "Sila zyciowa";
        case MAC_CONTRACT_GOLD:    return "Zloto";
        case MAC_CONTRACT_XP:      return "Doswiadczenie";
        case MAC_CONTRACT_MEMORY:  return "Wspomnienie";
        case MAC_CONTRACT_REFUSED: return "Odmowa";
    }
    return "Nieznany";
}

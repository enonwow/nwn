// lib_nec_def.nss — Necromancy: constants, type helpers, servant meta-data

#include "sql_nec"
#include "lib_nui"

// ----------------------------------------------------------------
// Window / script identifiers
// ----------------------------------------------------------------

const string NEC_WINDOW     = "NEC_WINDOW";
const string NEC_EV_SCRIPT  = "lib_nec_ev";
const string NEC_WIN_GEOM   = "nec_win_geom";

// ----------------------------------------------------------------
// Bind names — roster list (array binds)
// ----------------------------------------------------------------

const string NEC_BIND_ROW_COUNT   = "nec_row_count";
const string NEC_BIND_ROW_NAME    = "nec_row_name";
const string NEC_BIND_ROW_TYPE    = "nec_row_type";
const string NEC_BIND_ROW_HP      = "nec_row_hp";
const string NEC_BIND_ROW_ESS     = "nec_row_ess";
const string NEC_BIND_ROW_ENC     = "nec_row_enc";

// ----------------------------------------------------------------
// Bind names — header / footer
// ----------------------------------------------------------------

const string NEC_BIND_SLOT_LBL    = "nec_slot_lbl";
const string NEC_BIND_ESSENCE_LBL = "nec_essence_lbl";
const string NEC_BIND_BIND_ENA    = "nec_bind_ena";

// ----------------------------------------------------------------
// Bind names — detail panel
// ----------------------------------------------------------------

const string NEC_BIND_DET_NAME    = "nec_det_name";
const string NEC_BIND_DET_INFO    = "nec_det_info";
const string NEC_BIND_DET_HP_BAR  = "nec_det_hp_bar";
const string NEC_BIND_DET_ESS_BAR = "nec_det_ess_bar";
const string NEC_BIND_FEED_AMT    = "nec_feed_amt";
const string NEC_BIND_FEED_ENA    = "nec_feed_ena";
const string NEC_BIND_DISMISS_ENA = "nec_dismiss_ena";

// ----------------------------------------------------------------
// Button identifiers
// ----------------------------------------------------------------

const string NEC_BTN_CLOSE   = "nec_btn_close";
const string NEC_BTN_BIND    = "nec_btn_bind";
const string NEC_BTN_DISMISS = "nec_btn_dismiss";
const string NEC_BTN_FEED    = "nec_btn_feed";
const string NEC_BTN_ROW     = "nec_btn_row";

// ----------------------------------------------------------------
// Local variables on PC
// ----------------------------------------------------------------

const string NEC_LVAR_SEL_ID    = "NEC_SEL_ID";
const string NEC_LVAR_TARGETING = "NEC_TARGETING";

// ----------------------------------------------------------------
// Servant type IDs
// ----------------------------------------------------------------

const int NEC_TYPE_SKELETON = 0;
const int NEC_TYPE_ZOMBIE   = 1;
const int NEC_TYPE_SHADE    = 2;
const int NEC_TYPE_WIGHT    = 3;

// ----------------------------------------------------------------
// Servant blueprints
// Stock NWN resrefs — verify/override for your HAK content.
// Shade and Wight fall back to shadow/wight NWN defaults.
// ----------------------------------------------------------------

const string NEC_RESREF_SKELETON = "nw_s_skelwar";
const string NEC_RESREF_ZOMBIE   = "nw_zombie01";
const string NEC_RESREF_SHADE    = "nw_s_shadow";
const string NEC_RESREF_WIGHT    = "nw_s_wight";

// ----------------------------------------------------------------
// Essence drain per heartbeat tick (~6 s)
// ----------------------------------------------------------------

const int NEC_DRAIN_SKELETON = 2;
const int NEC_DRAIN_ZOMBIE   = 3;
const int NEC_DRAIN_SHADE    = 4;
const int NEC_DRAIN_WIGHT    = 6;

// ----------------------------------------------------------------
// Essence economy
// ----------------------------------------------------------------

const int NEC_MAX_ESSENCE     = 200;
const int NEC_START_ESSENCE   = 100;   // essence a fresh servant starts with
const int NEC_BIND_COST       = 60;    // pool cost to raise one servant
const int NEC_FEED_DEFAULT    = 25;    // default feed amount shown in text field
const int NEC_ESSENCE_LOW_CR  = 5;    // kills CR 1-5
const int NEC_ESSENCE_MED_CR  = 15;   // kills CR 6-12
const int NEC_ESSENCE_HIGH_CR = 30;   // kills CR 13+

// ----------------------------------------------------------------
// Servant base HP
// ----------------------------------------------------------------

const int NEC_HP_SKELETON = 20;
const int NEC_HP_ZOMBIE   = 35;
const int NEC_HP_SHADE    = 15;
const int NEC_HP_WIGHT    = 50;

// ----------------------------------------------------------------
// Window geometry
// ----------------------------------------------------------------

const float NEC_W = 630.0;
const float NEC_H = 510.0;

// ----------------------------------------------------------------
// Type helpers
// ----------------------------------------------------------------

// Maximum number of simultaneous servants, scaled by character level.
int NecGetMaxServants(object oPC)
{
    int nLevel = GetHitDice(oPC);
    if (nLevel >= 20) return 5;
    if (nLevel >= 15) return 4;
    if (nLevel >= 10) return 3;
    if (nLevel >= 5)  return 2;
    return 1;
}

// Infer best servant type from a freshly slain creature.
int NecGetServantType(object oCorpse)
{
    int nCR = FloatToInt(GetChallengeRating(oCorpse));
    if (GetRacialType(oCorpse) == RACIAL_TYPE_UNDEAD) return NEC_TYPE_SHADE;
    if (nCR >= 10) return NEC_TYPE_WIGHT;
    if (nCR >= 5)  return NEC_TYPE_ZOMBIE;
    return NEC_TYPE_SKELETON;
}

string NecTypeName(int nType)
{
    switch (nType)
    {
        case NEC_TYPE_SKELETON: return "Szkielet";
        case NEC_TYPE_ZOMBIE:   return "Zombie";
        case NEC_TYPE_SHADE:    return "Cień";
        case NEC_TYPE_WIGHT:    return "Wight";
    }
    return "Nieznany";
}

string NecTypeResRef(int nType)
{
    switch (nType)
    {
        case NEC_TYPE_SKELETON: return NEC_RESREF_SKELETON;
        case NEC_TYPE_ZOMBIE:   return NEC_RESREF_ZOMBIE;
        case NEC_TYPE_SHADE:    return NEC_RESREF_SHADE;
        case NEC_TYPE_WIGHT:    return NEC_RESREF_WIGHT;
    }
    return NEC_RESREF_SKELETON;
}

int NecTypeDrain(int nType)
{
    switch (nType)
    {
        case NEC_TYPE_SKELETON: return NEC_DRAIN_SKELETON;
        case NEC_TYPE_ZOMBIE:   return NEC_DRAIN_ZOMBIE;
        case NEC_TYPE_SHADE:    return NEC_DRAIN_SHADE;
        case NEC_TYPE_WIGHT:    return NEC_DRAIN_WIGHT;
    }
    return NEC_DRAIN_SKELETON;
}

int NecTypeBaseHP(int nType)
{
    switch (nType)
    {
        case NEC_TYPE_SKELETON: return NEC_HP_SKELETON;
        case NEC_TYPE_ZOMBIE:   return NEC_HP_ZOMBIE;
        case NEC_TYPE_SHADE:    return NEC_HP_SHADE;
        case NEC_TYPE_WIGHT:    return NEC_HP_WIGHT;
    }
    return NEC_HP_SKELETON;
}

// Unique in-game tag derived from PC UUID + DB row id.
string NecServantTag(string sOwnerUuid, int nId)
{
    return "NEC_" + GetStringLeft(sOwnerUuid, 8) + "_" + IntToString(nId);
}

// Essence yield from a single kill by the creature's CR.
int NecEssenceForCR(object oCorpse)
{
    int nCR = FloatToInt(GetChallengeRating(oCorpse));
    if (nCR >= 13) return NEC_ESSENCE_HIGH_CR;
    if (nCR >= 6)  return NEC_ESSENCE_MED_CR;
    return NEC_ESSENCE_LOW_CR;
}

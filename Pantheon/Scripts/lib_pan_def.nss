#include "lib_nui"
#include "sql_pan"

// =================================================================
// Pantheon - custom deity worship & miracles
// =================================================================
// Devotion to one of three custom deities (good / neutral / evil).
// Build favor by praying or offering gold; spend favor on miracles
// granted by your deity's domain. Six ranks scale prayer gain and
// miracle potency.
//
// Pantheon (id):
//   0 - Aurelia    (NG, Light & Mercy)        - grants Heal + Bless
//   1 - Vesperis   (TN, Balance & Justice)    - grants all four miracles
//   2 - Mor'thalas (CE, Wrath & Shadow)       - grants Smite + Sanctuary
//
// Miracles (favor threshold / cooldown / favor cost):
//   0 - Heal      (10 / 5 min  / -2)  restores 25% max HP to caster
//   1 - Bless     (25 / 10 min / -3)  +2 atk/saves to party in 10m, 60s
//   2 - Smite     (25 / 5 min  / -3)  3d6 divine damage to a target
//   3 - Sanctuary (50 / 20 min / -5)  immunity for 18s
//
// Ranks (favor range / pray gain / miracle bonus):
//   Disfavored      -50..-1   / 5    / no bonus (post-switch landing zone)
//   Acolyte           0..24   / 5    / baseline
//   Devoted          25..49   / 5    / Bless 75s, Sanctuary 22s
//   Blessed          50..74   / 5    / Heal 35%, Bless 90s, Smite 4d6, Sanctuary 28s
//   Chosen           75..100  / 5    / Blessed bonuses + 25% CD reduction
//
// Gold offering: 10 gold = +1 favor (min 100). Pays no prayer cooldown.
//
// Hooks:
//   OnModuleLoad   -> sys_on_load
//   OnClientEnter  -> sys_on_enter
//   OnPlayerTarget -> sys_on_target
//
// Two separate placeables (deity choice is intentionally NOT in the altar UI):
//   1. Altar         OnUsed -> test_pan       (CreatePanWindow)
//   2. Shrine/oracle OnUsed -> test_pan_deity (PanShowDeitySelector)
// Place them in different areas - the deity is a life decision, not a
// click-through option on every altar.
// =================================================================

const string PAN_WINDOW              = "PAN_WIN";
const string PAN_WIN_DEITY           = "PAN_WIN_DEITY";
const string PAN_EV_SCRIPT           = "lib_pan_ev";

// Tunables
const int    PAN_PRAY_COOLDOWN_S         = 3600;
const int    PAN_PRAY_FAVOR_GAIN         = 5;
const int    PAN_FAVOR_MIN               = -50;
const int    PAN_FAVOR_MAX               = 100;
const int    PAN_DEITY_SWITCH_DISFAVOR   = 25;

// Deity ids
const int    PAN_DEITY_NONE        = -1;
const int    PAN_DEITY_AURELIA     = 0;  // good
const int    PAN_DEITY_VESPERIS    = 1;  // neutral
const int    PAN_DEITY_MORTHALAS   = 2;  // evil
const int    PAN_DEITY_COUNT       = 3;

// Miracle ids
const int    PAN_MIRACLE_HEAL      = 0;
const int    PAN_MIRACLE_BLESS     = 1;
const int    PAN_MIRACLE_SMITE     = 2;
const int    PAN_MIRACLE_SANCTUARY = 3;
const int    PAN_MIRACLE_COUNT     = 4;

// Session-only LVAR (targeting handshake)
const string PAN_LVAR_PENDING_TARGET = "PAN_TARGET_MIR"; // miracle id+1; 0 = none

// Cached state for the open window (avoids per-tick SQL).
// Refreshed on OPEN and after pray/cast/deity-change.
const string PAN_LVAR_LOAD_NOW    = "PAN_LD_NOW";    // unix timestamp at last refresh
const string PAN_LVAR_TICK_OFFSET = "PAN_TK_OFF";    // seconds since last refresh
const string PAN_LVAR_DEITY       = "PAN_C_DEITY";
const string PAN_LVAR_FAVOR       = "PAN_C_FAVOR";
const string PAN_LVAR_LAST_PRAYED = "PAN_C_LASTPR";
const string PAN_LVAR_CD_PREFIX   = "PAN_C_CD_";     // + IntToString(nMir) -> ready_at

// Bind names
const string PAN_BIND_TITLE          = "pan_title";
const string PAN_BIND_DEITY_LBL      = "pan_deity";
const string PAN_BIND_FAVOR_LBL      = "pan_favor";
const string PAN_BIND_RANK_LBL       = "pan_rank";
const string PAN_BIND_PRAY_ENA       = "pan_pray_ena";
const string PAN_BIND_PRAY_TIP       = "pan_pray_tip";
const string PAN_BIND_PRAY_LBL       = "pan_pray_lbl";
const string PAN_BIND_MIR_NAME       = "pan_mir_name";
const string PAN_BIND_MIR_DESC       = "pan_mir_desc";
const string PAN_BIND_MIR_COST       = "pan_mir_cost";
const string PAN_BIND_MIR_BTN        = "pan_mir_btn";
const string PAN_BIND_MIR_BTN_ENA    = "pan_mir_btn_ena";
const string PAN_BIND_MIR_COLOR      = "pan_mir_color";
const string PAN_BIND_DEITY_ROW_LBL  = "pan_d_lbl";
const string PAN_BIND_DEITY_ROW_DESC = "pan_d_desc";
const string PAN_BIND_MIR_LEN        = "pan_mir_len";
const string PAN_BIND_DEITY_LEN      = "pan_d_len";
const string PAN_BIND_RANK_PROG      = "pan_rank_prog";   // float 0.0-1.0
const string PAN_BIND_RANK_NEXT      = "pan_rank_next";   // "+20 to Devoted"
const string PAN_BIND_RANK_COLOR     = "pan_rank_color";  // NuiColor (deity-tinted bar)
const string PAN_BIND_RANK_TIP       = "pan_rank_tip";    // "12 / 25 to Devoted"
const string PAN_BIND_BG_IMAGE       = "pan_bg_image";    // resref of side panel deity art
const string PAN_BIND_OFFER_INFO     = "pan_off_info";
const string PAN_BIND_OFFER_AMT      = "pan_off_amt";

// Button IDs
const string PAN_BTN_CLOSE         = "pan_close";
const string PAN_BTN_PRAY          = "pan_pray";
const string PAN_BTN_OFFER         = "pan_offer";
const string PAN_BTN_OFFER_OK      = "pan_off_ok";
const string PAN_BTN_OFFER_NO      = "pan_off_no";
const string PAN_BTN_MIRACLE       = "pan_mir";
const string PAN_BTN_DEITY_ROW     = "pan_d_row";

// Offer (gold sacrifice)
const string PAN_WIN_OFFER             = "PAN_WIN_OFFER";
const int    PAN_OFFER_GOLD_PER_FAVOR  = 10;
const int    PAN_OFFER_MIN_GOLD        = 100;

// Layout
const float  PAN_W = 555.0;
const float  PAN_H = 1000.0;
const float  PAN_DEITY_W = 465.0;
const float  PAN_DEITY_H = 220.0;
const float  PAN_OFFER_W = 395.0;
const float  PAN_OFFER_H = 180.0;

// ---- Static accessors ----

string PanDeityName(int n)
{
    switch(n)
    {
        case PAN_DEITY_AURELIA:   return "Aurelia";
        case PAN_DEITY_VESPERIS:  return "Vesperis";
        case PAN_DEITY_MORTHALAS: return "Mor'thalas";
    }
    return "-";
}

string PanDeityDomain(int n)
{
    switch(n)
    {
        case PAN_DEITY_AURELIA:   return "Light and Mercy (NG)";
        case PAN_DEITY_VESPERIS:  return "Balance and Justice (TN)";
        case PAN_DEITY_MORTHALAS: return "Wrath and Shadow (CE)";
    }
    return "";
}

// Deity-tinted color used for the rank progress bar.
json PanDeityColor(int n)
{
    switch(n)
    {
        case PAN_DEITY_AURELIA:   return NuiColor(255, 215, 100);  // gold
        case PAN_DEITY_VESPERIS:  return NuiColor(180, 180, 200);  // silver
        case PAN_DEITY_MORTHALAS: return NuiColor(200,  60,  60);  // blood red
    }
    return NuiColor(140, 140, 140);  // gray (no deity)
}

// PNG resref of the side panel art for each deity (placed in HAK).
string PanDeityImage(int n)
{
    switch(n)
    {
        case PAN_DEITY_AURELIA:   return "pan_alt_aurelia";
        case PAN_DEITY_VESPERIS:  return "pan_alt_vesperis";
        case PAN_DEITY_MORTHALAS: return "pan_alt_morthal";
    }
    return "";  // no deity = no image
}

string PanMiracleName(int n)
{
    switch(n)
    {
        case PAN_MIRACLE_HEAL:      return "Heal Wounds";
        case PAN_MIRACLE_BLESS:     return "Bless Companions";
        case PAN_MIRACLE_SMITE:     return "Divine Smite";
        case PAN_MIRACLE_SANCTUARY: return "Sanctuary";
    }
    return "?";
}

string PanMiracleDescription(int n)
{
    switch(n)
    {
        case PAN_MIRACLE_HEAL:      return "Restore 25% max HP to yourself.";
        case PAN_MIRACLE_BLESS:     return "+2 attack and saves to party within 10m for 60s.";
        case PAN_MIRACLE_SMITE:     return "3d6 divine damage to a target enemy.";
        case PAN_MIRACLE_SANCTUARY: return "Become immune to attacks for 18s.";
    }
    return "";
}

int PanMiracleFavorReq(int n)
{
    switch(n)
    {
        case PAN_MIRACLE_HEAL:      return 10;
        case PAN_MIRACLE_BLESS:     return 25;
        case PAN_MIRACLE_SMITE:     return 25;
        case PAN_MIRACLE_SANCTUARY: return 50;
    }
    return 999;
}

int PanMiracleFavorCost(int n)
{
    switch(n)
    {
        case PAN_MIRACLE_HEAL:      return 2;
        case PAN_MIRACLE_BLESS:     return 3;
        case PAN_MIRACLE_SMITE:     return 3;
        case PAN_MIRACLE_SANCTUARY: return 5;
    }
    return 999;
}

int PanMiracleCooldownS(int n)
{
    switch(n)
    {
        case PAN_MIRACLE_HEAL:      return 300;
        case PAN_MIRACLE_BLESS:     return 600;
        case PAN_MIRACLE_SMITE:     return 300;
        case PAN_MIRACLE_SANCTUARY: return 1200;
    }
    return 0;
}

int PanMiracleNeedsTarget(int n)
{
    return (n == PAN_MIRACLE_SMITE);
}

// Each deity grants a subset of the four miracles based on its alignment.
// Aurelia    (good)    - Heal & Bless           (supportive only)
// Vesperis   (neutral) - all four miracles      (balanced flexibility)
// Mor'thalas (evil)    - Smite & Sanctuary      (offense + self-protection)
int PanDeityHasMiracle(int nDeity, int nMir)
{
    switch(nDeity)
    {
        case PAN_DEITY_AURELIA:
            return (nMir == PAN_MIRACLE_HEAL || nMir == PAN_MIRACLE_BLESS);
        case PAN_DEITY_VESPERIS:
            return TRUE;  // all four
        case PAN_DEITY_MORTHALAS:
            return (nMir == PAN_MIRACLE_SMITE || nMir == PAN_MIRACLE_SANCTUARY);
    }
    return FALSE;
}

// Rank ids (sorted lowest -> highest)
const int PAN_RANK_DISFAVORED = 0;
const int PAN_RANK_ACOLYTE    = 1;
const int PAN_RANK_DEVOTED    = 2;
const int PAN_RANK_BLESSED    = 3;
const int PAN_RANK_CHOSEN     = 4;

int PanGetRankId(int nFavor)
{
    if(nFavor <  0)  return PAN_RANK_DISFAVORED;
    if(nFavor < 25)  return PAN_RANK_ACOLYTE;
    if(nFavor < 50)  return PAN_RANK_DEVOTED;
    if(nFavor < 75)  return PAN_RANK_BLESSED;
    return PAN_RANK_CHOSEN;
}

string PanFavorRank(int nFavor)
{
    switch(PanGetRankId(nFavor))
    {
        case PAN_RANK_DISFAVORED: return "Disfavored";
        case PAN_RANK_ACOLYTE:    return "Acolyte";
        case PAN_RANK_DEVOTED:    return "Devoted";
        case PAN_RANK_BLESSED:    return "Blessed";
        case PAN_RANK_CHOSEN:     return "Chosen";
    }
    return "-";
}

// How much favor a single prayer grants based on the current rank.
int PanGetPrayGain(int nRank)
{
    return PAN_PRAY_FAVOR_GAIN;
}

// Rank-aware version: returns the description with the values the player
// will actually get at their current rank. Used in the UI cell.
string PanMiracleDescriptionRank(int nMir, int nRank)
{
    int nPct = 25;
    int nBlessDur = 60;
    int nDice = 3;
    int nSancDur = 18;

    if(nRank >= PAN_RANK_BLESSED) nPct = 35;
    if(nRank == PAN_RANK_DEVOTED) nBlessDur = 75;
    else if(nRank >= PAN_RANK_BLESSED) nBlessDur = 90;
    if(nRank >= PAN_RANK_BLESSED) nDice = 4;
    if(nRank == PAN_RANK_DEVOTED) nSancDur = 22;
    else if(nRank >= PAN_RANK_BLESSED) nSancDur = 28;

    if(nMir == PAN_MIRACLE_HEAL)
        return "Restore " + IntToString(nPct) + "% max HP to yourself.";
    if(nMir == PAN_MIRACLE_BLESS)
        return "+2 attack and saves to party within 10m for "
            + IntToString(nBlessDur) + "s.";
    if(nMir == PAN_MIRACLE_SMITE)
        return IntToString(nDice) + "d6 divine damage to a target enemy.";
    if(nMir == PAN_MIRACLE_SANCTUARY)
        return "Become immune to attacks for " + IntToString(nSancDur) + "s.";
    return "";
}

// Inclusive favor bounds for a given rank.
int PanRankMinFavor(int nRank)
{
    switch(nRank)
    {
        case PAN_RANK_DISFAVORED: return -50;
        case PAN_RANK_ACOLYTE:    return   0;
        case PAN_RANK_DEVOTED:    return  25;
        case PAN_RANK_BLESSED:    return  50;
        case PAN_RANK_CHOSEN:     return  75;
    }
    return -50;
}

int PanRankMaxFavor(int nRank)
{
    switch(nRank)
    {
        case PAN_RANK_DISFAVORED: return  -1;
        case PAN_RANK_ACOLYTE:    return  24;
        case PAN_RANK_DEVOTED:    return  49;
        case PAN_RANK_BLESSED:    return  74;
        case PAN_RANK_CHOSEN:     return  100;
    }
    return 100;
}

// 0.0 = just entered this rank, 1.0 = on the cusp of the next.
// Acolyte spans -24..24 but the progress bar only fills with positive favor
// (0 favor = empty, 25 favor = Devoted). Other ranks use full range.
float PanGetRankProgress(int nFavor)
{
    int   nRank = PanGetRankId(nFavor);
    int   nMin  = PanRankMinFavor(nRank);
    int   nMax  = PanRankMaxFavor(nRank);

    if(nRank == PAN_RANK_CHOSEN) return 1.0;
    if(nMax <= nMin) return 1.0;

    float fP = IntToFloat(nFavor - nMin) / IntToFloat(nMax - nMin + 1);
    if(fP < 0.0) fP = 0.0;
    if(fP > 1.0) fP = 1.0;
    return fP;
}

string PanGetNextRankName(int nRank)
{
    switch(nRank)
    {
        case PAN_RANK_DISFAVORED: return "Acolyte";
        case PAN_RANK_ACOLYTE:    return "Devoted";
        case PAN_RANK_DEVOTED:    return "Blessed";
        case PAN_RANK_BLESSED:    return "Chosen";
    }
    return "";  // Chosen is max
}

// Favor needed to reach next rank (0 if Chosen).
int PanGetFavorToNextRank(int nFavor)
{
    int nRank = PanGetRankId(nFavor);
    if(nRank == PAN_RANK_CHOSEN) return 0;
    return PanRankMaxFavor(nRank) + 1 - nFavor;
}

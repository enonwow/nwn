#include "lib_nui"
#include "sql_pr"

// ----------------------------------------------------------------
// Prayer & Miracles
// ----------------------------------------------------------------
// Devotion to one of five deities, daily prayer to build favor,
// and miracles unlocked at favor thresholds. Each miracle costs
// favor and has its own cooldown.
//
// Pantheon (id):
//   0 — Lumis    (Light & Dawn)
//   1 — Mortis   (Death & Rest)
//   2 — Bellator (War & Honor)
//   3 — Tenebris (Shadows & Secrets)
//   4 — Sylva    (Wilds & Beasts)
//
// Miracles (favor threshold / cooldown / favor cost):
//   0 — Heal      (10 / 5 min  / -2)   restores 25 HP to caster
//   1 — Bless     (25 / 10 min / -3)   +2 attack & saves, party in 10m, 60s
//   2 — Smite     (25 / 5 min  / -3)   3d6 divine damage to target
//   3 — Sanctuary (50 / 20 min / -5)   immunity to attacks for 18s
//   4 — Raise     (75 / 60 min / -10)  raise target dead PC at 25% HP
//
// Hooks:
//   OnModuleLoad  -> sys_on_load   (init schema)
//   OnClientEnter -> sys_on_enter  (register devotion row)
//   OnPlayerTarget -> sys_on_target (Smite/Raise targeting)
//
// Open the panel from a placeable's OnUsed:
//   #include "lib_pr"
//   void main() { CreatePrWindow(GetLastUsedBy()); }
// ----------------------------------------------------------------

const string PR_WINDOW              = "PR_WINDOW";
const string PR_WIN_DEITY           = "PR_WIN_DEITY";
const string PR_EV_SCRIPT           = "lib_pr_ev";

// Tunables
const int   PR_PRAY_COOLDOWN_S      = 3600;   // 1 IRL hour between prayers
const int   PR_PRAY_FAVOR_GAIN      = 5;
const int   PR_FAVOR_MIN            = -100;
const int   PR_FAVOR_MAX            = 100;

const int   PR_DEITY_NONE           = -1;
const int   PR_DEITY_COUNT          = 5;

// Miracle indices
const int   PR_MIRACLE_HEAL         = 0;
const int   PR_MIRACLE_BLESS        = 1;
const int   PR_MIRACLE_SMITE        = 2;
const int   PR_MIRACLE_SANCTUARY    = 3;
const int   PR_MIRACLE_RAISE        = 4;
const int   PR_MIRACLE_COUNT        = 5;

// LVAR prefixes (cooldown timestamps per miracle)
const string PR_LVAR_CD_PREFIX      = "PR_CD_";          // + IntToString(idx)
const string PR_LVAR_PENDING_TARGET = "PR_TARGET_MIR";   // miracle id awaiting OnPlayerTarget

// Bind names
const string PR_BIND_TITLE          = "pr_title";
const string PR_BIND_DEITY_LBL      = "pr_deity_lbl";
const string PR_BIND_FAVOR_LBL      = "pr_favor_lbl";
const string PR_BIND_RANK_LBL       = "pr_rank_lbl";
const string PR_BIND_PRAY_ENA       = "pr_pray_ena";
const string PR_BIND_PRAY_TIP       = "pr_pray_tip";
const string PR_BIND_MIR_NAME       = "pr_mir_name";
const string PR_BIND_MIR_DESC       = "pr_mir_desc";
const string PR_BIND_MIR_BTN        = "pr_mir_btn";       // label per row
const string PR_BIND_MIR_BTN_ENA    = "pr_mir_btn_ena";
const string PR_BIND_MIR_COLOR      = "pr_mir_color";
const string PR_BIND_DEITY_ROW_LBL  = "pr_d_row_lbl";
const string PR_BIND_DEITY_ROW_DESC = "pr_d_row_desc";

// Button IDs
const string PR_BTN_CLOSE           = "pr_btn_close";
const string PR_BTN_PRAY            = "pr_btn_pray";
const string PR_BTN_CHANGE_DEITY    = "pr_btn_change";
const string PR_BTN_MIRACLE         = "pr_btn_mir";       // row click in list
const string PR_BTN_DEITY_ROW       = "pr_btn_d_row";     // deity selection row

// Layout
const float PR_W = 600.0;
const float PR_H = 500.0;
const float PR_DEITY_W = 480.0;
const float PR_DEITY_H = 360.0;

// ---- Static data accessors ----

string PrDeityName(int nDeity)
{
    switch(nDeity)
    {
        case 0: return "Lumis";
        case 1: return "Mortis";
        case 2: return "Bellator";
        case 3: return "Tenebris";
        case 4: return "Sylva";
    }
    return "—";
}

string PrDeityDomain(int nDeity)
{
    switch(nDeity)
    {
        case 0: return "Light and Dawn";
        case 1: return "Death and Rest";
        case 2: return "War and Honor";
        case 3: return "Shadows and Secrets";
        case 4: return "Wilds and Beasts";
    }
    return "";
}

string PrMiracleName(int n)
{
    switch(n)
    {
        case PR_MIRACLE_HEAL:      return "Heal Wounds";
        case PR_MIRACLE_BLESS:     return "Bless Companions";
        case PR_MIRACLE_SMITE:     return "Divine Smite";
        case PR_MIRACLE_SANCTUARY: return "Sanctuary";
        case PR_MIRACLE_RAISE:     return "Raise the Fallen";
    }
    return "?";
}

int PrMiracleFavorReq(int n)
{
    switch(n)
    {
        case PR_MIRACLE_HEAL:      return 10;
        case PR_MIRACLE_BLESS:     return 25;
        case PR_MIRACLE_SMITE:     return 25;
        case PR_MIRACLE_SANCTUARY: return 50;
        case PR_MIRACLE_RAISE:     return 75;
    }
    return 999;
}

int PrMiracleFavorCost(int n)
{
    switch(n)
    {
        case PR_MIRACLE_HEAL:      return 2;
        case PR_MIRACLE_BLESS:     return 3;
        case PR_MIRACLE_SMITE:     return 3;
        case PR_MIRACLE_SANCTUARY: return 5;
        case PR_MIRACLE_RAISE:     return 10;
    }
    return 999;
}

int PrMiracleCooldownS(int n)
{
    switch(n)
    {
        case PR_MIRACLE_HEAL:      return 300;
        case PR_MIRACLE_BLESS:     return 600;
        case PR_MIRACLE_SMITE:     return 300;
        case PR_MIRACLE_SANCTUARY: return 1200;
        case PR_MIRACLE_RAISE:     return 3600;
    }
    return 0;
}

int PrMiracleNeedsTarget(int n)
{
    return (n == PR_MIRACLE_SMITE || n == PR_MIRACLE_RAISE);
}

string PrMiracleDescription(int n)
{
    switch(n)
    {
        case PR_MIRACLE_HEAL:      return "Restore 25 HP to yourself.";
        case PR_MIRACLE_BLESS:     return "+2 attack and saves to allies within 10m for 60s.";
        case PR_MIRACLE_SMITE:     return "3d6 divine damage to a target enemy.";
        case PR_MIRACLE_SANCTUARY: return "Become immune to all attacks for 18s.";
        case PR_MIRACLE_RAISE:     return "Raise a slain ally at 25% HP.";
    }
    return "";
}

string PrFavorRank(int nFavor)
{
    if(nFavor <= -75) return "Excommunicated";
    if(nFavor <= -25) return "Disfavored";
    if(nFavor <    25) return "Acolyte";
    if(nFavor <    50) return "Devoted";
    if(nFavor <    75) return "Blessed";
    return "Chosen";
}

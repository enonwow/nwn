#include "lib_nui"
#include "sql_exc"

void ExcOpen(object oPC, object oSite);
void ExcFeedDigView(object oPC, int nToken);
void ExcFeedCodexView(object oPC, int nToken);
void ExcApplyRelicEffects(object oPC);
void ExcDoDigAttempt(object oPC, int nToken);
void ExcDoAssemble(object oPC, int nToken, int nEra);

// ----------------------------------------------------------------
// Era identifiers and gameplay tuning
// ----------------------------------------------------------------

const int EXC_ERA_PRECATACLYSM  = 0;   // bonus: +STR
const int EXC_ERA_DARK_AGE      = 1;   // bonus: +CON
const int EXC_ERA_IMPERIAL      = 2;   // bonus: +INT
const int EXC_ERA_FORGOTTEN     = 3;   // bonus: +WIS
const int EXC_ERA_COUNT         = 4;

const int EXC_SHARDS_PER_RELIC  = 3;
const int EXC_MAX_RELICS_PER_ERA = 3;
const int EXC_DIG_HP_COST_PCT   = 5;   // percent of max HP per dig attempt
const int EXC_PROGRESS_MIN      = 15;
const int EXC_PROGRESS_MAX      = 40;

// ----------------------------------------------------------------
// NUI window / bind identifiers
// ----------------------------------------------------------------

const string EXC_WINDOW    = "EXC_WINDOW";
const string EXC_EV_SCRIPT = "lib_exc_ev";
const string EXC_GRP_SWAP  = "EXC_GRP_SWAP";

const float EXC_W = 520.0;
const float EXC_H = 460.0;

// Shared
const string EXC_BIND_WIN_GEOM      = "exc_geom";

// Dig view binds
const string EXC_BIND_SITE_NAME     = "exc_site_name";
const string EXC_BIND_SITE_ERA_LBL  = "exc_site_era";
const string EXC_BIND_PROGRESS      = "exc_progress";
const string EXC_BIND_PROGRESS_LBL  = "exc_prog_lbl";
const string EXC_BIND_TRIES_LBL     = "exc_tries_lbl";
const string EXC_BIND_DIG_ENA       = "exc_dig_ena";
const string EXC_BIND_RESULT_LBL    = "exc_result";
const string EXC_BIND_HP_COST_LBL   = "exc_hp_cost";

// Codex view binds (list arrays, length == EXC_ERA_COUNT)
const string EXC_BIND_ERA_NAMES     = "exc_era_names";
const string EXC_BIND_ERA_SHARDS    = "exc_era_shards";
const string EXC_BIND_ERA_RELICS    = "exc_era_relics";
const string EXC_BIND_ERA_BONUS     = "exc_era_bonus";
const string EXC_BIND_ASSEMBLE_ENA  = "exc_assemble_ena";
const string EXC_BIND_ERA_ENC       = "exc_era_enc";
const string EXC_BIND_CODEX_STATUS  = "exc_codex_status";

// Button IDs
const string EXC_BTN_CLOSE     = "exc_close";
const string EXC_BTN_DIG       = "exc_dig";
const string EXC_BTN_TAB_DIG   = "exc_tab_dig";
const string EXC_BTN_TAB_COD   = "exc_tab_cod";
const string EXC_BTN_ASSEMBLE  = "exc_assemble";
const string EXC_BTN_ERA_ROW   = "exc_era_row";

// LVARs on PC
const string EXC_LVAR_SITE_TAG = "EXC_SITE_TAG";
const string EXC_LVAR_VIEW     = "EXC_VIEW";

// Views
const int EXC_VIEW_DIG   = 0;
const int EXC_VIEW_CODEX = 1;

// Effect tag for removal
const string EXC_EFFECT_TAG = "EXC_RELIC";

// ----------------------------------------------------------------
// Name / flavour helpers
// ----------------------------------------------------------------

string ExcEraName(int nEra)
{
    switch(nEra)
    {
        case EXC_ERA_PRECATACLYSM: return "Praczasy";
        case EXC_ERA_DARK_AGE:     return "Wiek Mroku";
        case EXC_ERA_IMPERIAL:     return "Epoka Cesarska";
        case EXC_ERA_FORGOTTEN:    return "Zapomniana Era";
    }
    return "Nieznana Era";
}

string ExcShardName(int nEra)
{
    switch(nEra)
    {
        case EXC_ERA_PRECATACLYSM: return "Kamienny odłamek sprzed kataklizmu";
        case EXC_ERA_DARK_AGE:     return "Obsydianowy odłamek Mrocznej Ery";
        case EXC_ERA_IMPERIAL:     return "Złoty odłamek Cesarstwa";
        case EXC_ERA_FORGOTTEN:    return "Przerażający odłamek Zapomnianej Ery";
    }
    return "Odłamek nieznanej ery";
}

string ExcRelicName(int nEra)
{
    switch(nEra)
    {
        case EXC_ERA_PRECATACLYSM: return "Relikwia Praczasów";
        case EXC_ERA_DARK_AGE:     return "Relikwia Mrocznego Wieku";
        case EXC_ERA_IMPERIAL:     return "Cesarska Pieczęć";
        case EXC_ERA_FORGOTTEN:    return "Relikwia Zapomnienia";
    }
    return "Relikwia";
}

string ExcEraBonus(int nEra, int nRelics)
{
    string sAttr;
    switch(nEra)
    {
        case EXC_ERA_PRECATACLYSM: sAttr = "SIŁ"; break;
        case EXC_ERA_DARK_AGE:     sAttr = "BUD"; break;
        case EXC_ERA_IMPERIAL:     sAttr = "INT"; break;
        case EXC_ERA_FORGOTTEN:    sAttr = "MĄD"; break;
        default: return "-";
    }
    if(nRelics <= 0) return "-";
    return "+" + IntToString(nRelics) + " " + sAttr;
}

int ExcEraAbility(int nEra)
{
    switch(nEra)
    {
        case EXC_ERA_PRECATACLYSM: return ABILITY_STRENGTH;
        case EXC_ERA_DARK_AGE:     return ABILITY_CONSTITUTION;
        case EXC_ERA_IMPERIAL:     return ABILITY_INTELLIGENCE;
        case EXC_ERA_FORGOTTEN:    return ABILITY_WISDOM;
    }
    return -1;
}

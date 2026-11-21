// lib_trph_def.nss — Trophy Hall: constants, category data, NUI bind IDs

#include "lib_nui"
#include "sql_trph"

// ============================================================
// Category IDs
// ============================================================

const int TRPH_CAT_UNDEAD    = 0;
const int TRPH_CAT_OUTSIDER  = 1;
const int TRPH_CAT_DRAGON    = 2;
const int TRPH_CAT_ANIMAL    = 3;
const int TRPH_CAT_HUMANOID  = 4;
const int TRPH_CAT_CONSTRUCT = 5;
const int TRPH_CAT_COUNT     = 6;

// Trophy item tag base: TRPH_ITEM_TAG + IntToString(nCat)
const string TRPH_ITEM_TAG = "trph_trophy_";

// Custom talisman resref base (HAK): trph_tal_<cat>_min / trph_tal_<cat>_maj
// Falls back to nw_it_mneck001 (amulet) with dynamic properties if resref missing.
const string TRPH_TALISMAN_RESREF_BASE = "trph_tal_";

// Crafting thresholds
const int TRPH_CRAFT_MINOR = 5;
const int TRPH_CRAFT_MAJOR = 15;

// ============================================================
// Window / bind / button IDs
// ============================================================

const string TRPH_WINDOW          = "TRPH_WINDOW";
const string TRPH_EV_SCRIPT       = "lib_trph_ev";

const string TRPH_BIND_GEOM       = "trph_geom";
const string TRPH_BIND_CAT_LABEL  = "trph_cat_lbl";
const string TRPH_BIND_CAT_ENC    = "trph_cat_enc";
const string TRPH_BIND_DET_TITLE  = "trph_det_title";
const string TRPH_BIND_DET_FLAVOR = "trph_det_flavor";
const string TRPH_BIND_MY_COUNT   = "trph_my_count";
const string TRPH_BIND_CRAFT_INFO = "trph_craft_info";
const string TRPH_BIND_DEP_ENA    = "trph_dep_ena";
const string TRPH_BIND_FMIN_ENA   = "trph_fmin_ena";
const string TRPH_BIND_FMAJ_ENA   = "trph_fmaj_ena";
const string TRPH_BIND_LB_NAME    = "trph_lb_name";
const string TRPH_BIND_LB_COUNT   = "trph_lb_count";

const string TRPH_BTN_CLOSE       = "trph_btn_close";
const string TRPH_BTN_CAT_ROW     = "trph_btn_cat";
const string TRPH_BTN_DEPOSIT     = "trph_btn_deposit";
const string TRPH_BTN_FORGE_MINOR = "trph_btn_fmin";
const string TRPH_BTN_FORGE_MAJOR = "trph_btn_fmaj";

// Local variable on PC: currently selected category index
const string TRPH_LVAR_SEL_CAT   = "TRPH_SEL_CAT";

// Window dimensions (pre-scale)
const float TRPH_W  = 700.0;
const float TRPH_H  = 500.0;
// Leaderboard rows (always rendered; empty rows show "—")
const int   TRPH_LB_ROWS = 5;

// ============================================================
// Category metadata
// ============================================================

string TrphCatName(int nCat)
{
    switch(nCat)
    {
        case TRPH_CAT_UNDEAD:    return "Nieumarli";
        case TRPH_CAT_OUTSIDER:  return "Demony";
        case TRPH_CAT_DRAGON:    return "Smoki";
        case TRPH_CAT_ANIMAL:    return "Bestie";
        case TRPH_CAT_HUMANOID:  return "Humanoidy";
        case TRPH_CAT_CONSTRUCT: return "Konstrukty";
    }
    return "Nieznane";
}

string TrphCatFlavor(int nCat)
{
    switch(nCat)
    {
        case TRPH_CAT_UNDEAD:
            return "Szczątki nieumarłych emanują gnijącą mocą. "
                 + "Zbiór trofeów hartuje duszę myśliwego przeciw zimnej grozie nieśmierci. "
                 + "Czaszka licha różni się od czaszki upiora — znawca pozna różnicę.";
        case TRPH_CAT_OUTSIDER:
            return "Demony i pozaplanarni najeźdźcy zostawiają po sobie substancje, "
                 + "które palą zwykłe drewno. Kieł demona, zebrany z wiarą, "
                 + "staje się pieczęcią chroniącą przed demonicznymi sztuczkami.";
        case TRPH_CAT_DRAGON:
            return "Smocze łuski przetrwają wieki po śmierci ich właściciela. "
                 + "Każda z nich to świadectwo odwagi — lub głupoty — myśliwego. "
                 + "Najcenniejsi kolekcjonerzy milczą o tym, jak je zdobyli.";
        case TRPH_CAT_ANIMAL:
            return "Kły, pazury i skóry dzikich bestii. "
                 + "Prawo ciemnego lasu jest proste: silniejszy pożera słabszego. "
                 + "Noszenie zębów pokonanej bestii mówi jej pobratymcom: tu poluje ktoś groźniejszy.";
        case TRPH_CAT_HUMANOID:
            return "Skalpy i połamane ostrza wrogich wojowników — mroczny zwyczaj "
                 + "granicznych rubieży. Nie każdy, kto nosi ludzką twarz, "
                 + "zasługuje na miłosierdzie. Myśliwy zbiera dowody swoich wyroków.";
        case TRPH_CAT_CONSTRUCT:
            return "Odłamki golemów, rdzewiejące tryby mechanizmów, wytłuczone kryształy. "
                 + "Pamiątki po mądrości magów, którzy tworzyli posłuszne narzędzia śmierci. "
                 + "Rdzeń golema pulsuje martwą magią — nawet po rozpadzie konstrukcji.";
    }
    return "";
}

string TrphItemName(int nCat)
{
    switch(nCat)
    {
        case TRPH_CAT_UNDEAD:    return "Czaszka Nieumarłego";
        case TRPH_CAT_OUTSIDER:  return "Demoniczny Kieł";
        case TRPH_CAT_DRAGON:    return "Smocza Łuska";
        case TRPH_CAT_ANIMAL:    return "Kły Bestii";
        case TRPH_CAT_HUMANOID:  return "Skalp";
        case TRPH_CAT_CONSTRUCT: return "Rdzeń Golema";
    }
    return "Trofeum";
}

string TrphTalismanMinorName(int nCat)
{
    switch(nCat)
    {
        case TRPH_CAT_UNDEAD:    return "Amulet Myśliwego Nieumarłych";
        case TRPH_CAT_OUTSIDER:  return "Pieczęć Pogromcy Demonów";
        case TRPH_CAT_DRAGON:    return "Łuska Pogromcy Smoków";
        case TRPH_CAT_ANIMAL:    return "Kieł Łowcy Bestii";
        case TRPH_CAT_HUMANOID:  return "Pętla Łowcy Skalp";
        case TRPH_CAT_CONSTRUCT: return "Fragment Magicznego Rdzenia";
    }
    return "Talizman Myśliwego";
}

string TrphTalismanMajorName(int nCat)
{
    switch(nCat)
    {
        case TRPH_CAT_UNDEAD:    return "Pieczęć Nieustraszonych — Bane Nieumarłych";
        case TRPH_CAT_OUTSIDER:  return "Znak Pogromcy Piekła";
        case TRPH_CAT_DRAGON:    return "Serce Smoczego Pogromcy";
        case TRPH_CAT_ANIMAL:    return "Korona Dzikiego Łowcy";
        case TRPH_CAT_HUMANOID:  return "Krwawa Pętla Zbrojmistrza";
        case TRPH_CAT_CONSTRUCT: return "Wielki Rdzeń Golemobójcy";
    }
    return "Wielki Talizman Myśliwego";
}

// Returns RACIAL_TYPE_* constant used to identify creature category on death.
int TrphCatRacialType(int nCat)
{
    switch(nCat)
    {
        case TRPH_CAT_UNDEAD:    return RACIAL_TYPE_UNDEAD;
        case TRPH_CAT_OUTSIDER:  return RACIAL_TYPE_OUTSIDER;
        case TRPH_CAT_DRAGON:    return RACIAL_TYPE_DRAGON;
        case TRPH_CAT_ANIMAL:    return RACIAL_TYPE_ANIMAL;
        case TRPH_CAT_HUMANOID:  return RACIAL_TYPE_HUMANOID_HUMAN;
        case TRPH_CAT_CONSTRUCT: return RACIAL_TYPE_CONSTRUCT;
    }
    return RACIAL_TYPE_INVALID;
}

// Returns IP_CONST_RACIALTYPE_* for item property "attack bonus vs race".
// Returns -1 for categories without a clean IP mapping (handled as generic +AB).
int TrphCatIPRacial(int nCat)
{
    switch(nCat)
    {
        case TRPH_CAT_UNDEAD:    return IP_CONST_RACIALTYPE_UNDEAD;
        case TRPH_CAT_OUTSIDER:  return IP_CONST_RACIALTYPE_OUTSIDER;
        case TRPH_CAT_DRAGON:    return IP_CONST_RACIALTYPE_DRAGON;
        case TRPH_CAT_ANIMAL:    return IP_CONST_RACIALTYPE_ANIMAL;
        case TRPH_CAT_HUMANOID:  return IP_CONST_RACIALTYPE_HUMANOID;
        case TRPH_CAT_CONSTRUCT: return IP_CONST_RACIALTYPE_CONSTRUCT;
    }
    return -1;
}

// Maps GetRacialType() result to TRPH_CAT_*, returns -1 if not tracked.
int TrphGetCategory(int nRacialType)
{
    switch(nRacialType)
    {
        case RACIAL_TYPE_UNDEAD:              return TRPH_CAT_UNDEAD;
        case RACIAL_TYPE_OUTSIDER:            return TRPH_CAT_OUTSIDER;
        case RACIAL_TYPE_DRAGON:              return TRPH_CAT_DRAGON;
        case RACIAL_TYPE_ANIMAL:              return TRPH_CAT_ANIMAL;
        case RACIAL_TYPE_HUMANOID_HUMAN:      return TRPH_CAT_HUMANOID;
        case RACIAL_TYPE_HUMANOID_ORC:        return TRPH_CAT_HUMANOID;
        case RACIAL_TYPE_HUMANOID_GOBLINOID:  return TRPH_CAT_HUMANOID;
        case RACIAL_TYPE_HUMANOID_REPTILIAN:  return TRPH_CAT_HUMANOID;
        case RACIAL_TYPE_CONSTRUCT:           return TRPH_CAT_CONSTRUCT;
    }
    return -1;
}

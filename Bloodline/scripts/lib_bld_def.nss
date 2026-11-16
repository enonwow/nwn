#include "lib_nui"
#include "sql_bld"

void BldOpenWindow(object oPC);
void BldFeedWindow(object oPC, int nToken);
void BldApplyEffects(object oPC);
void BldRemoveEffects(object oPC);

// ----------------------------------------------------------------
// Bloodline types
// ----------------------------------------------------------------

const int BLD_TYPE_TYRANT    = 0;  // Krew Tyrana — siła dawnych władców
const int BLD_TYPE_FADING    = 1;  // Krew Blaknienia — elficki zmierzch
const int BLD_TYPE_IRONBORN  = 2;  // Krew Żelaznorodzona — głębiny krasnoludów
const int BLD_TYPE_INFERNAL  = 3;  // Krew Piekielna — demoniczne dziedzictwo
const int BLD_TYPE_CELESTIAL = 4;  // Krew Niebiańska — boski przodek
const int BLD_TYPE_DRACONIC  = 5;  // Krew Drakońska — smocze dziedzictwo
const int BLD_TYPE_COUNT     = 6;

// ----------------------------------------------------------------
// Purity tiers (thresholds in purity points 0–100)
// ----------------------------------------------------------------

const int BLD_TIER_DORMANT    = 0;
const int BLD_TIER_STIRRING   = 1;
const int BLD_TIER_AWAKENED   = 2;
const int BLD_TIER_ASCENDANT  = 3;

const int BLD_PURITY_STIRRING  = 25;
const int BLD_PURITY_AWAKENED  = 50;
const int BLD_PURITY_ASCENDANT = 75;

// ----------------------------------------------------------------
// Ritual costs
// ----------------------------------------------------------------

const int BLD_RITUAL_HP_PCT_DORMANT   = 10;   // % of max HP to advance Dormant→Stirring
const int BLD_RITUAL_HP_PCT_STIRRING  = 20;   // % to advance Stirring→Awakened
const int BLD_RITUAL_HP_PCT_AWAKENED  = 35;   // % to advance Awakened→Ascendant

const int BLD_RITUAL_GOLD_DORMANT   = 500;
const int BLD_RITUAL_GOLD_STIRRING  = 2000;
const int BLD_RITUAL_GOLD_AWAKENED  = 5000;

const int BLD_RITUAL_COOLDOWN       = 86400;  // 24 hours in seconds (real time via SQLite)

// ----------------------------------------------------------------
// NUI identifiers
// ----------------------------------------------------------------

const string BLD_WINDOW          = "BLD_WINDOW";
const string BLD_EV_SCRIPT       = "lib_bld_ev";
const string BLD_GRP_CONTENT     = "BLD_GRP_CONTENT";
const string BLD_WIN_GEOM        = "bld_win_geom";

// Main view binds
const string BLD_BIND_LINEAGE_NAME   = "bld_lin_name";
const string BLD_BIND_LINEAGE_LORE   = "bld_lin_lore";
const string BLD_BIND_PURITY_VAL     = "bld_purity_val";
const string BLD_BIND_TIER_NAME      = "bld_tier_name";
const string BLD_BIND_TIER_COLOR     = "bld_tier_color";
const string BLD_BIND_EFFECTS_T1     = "bld_eff_t1";
const string BLD_BIND_EFFECTS_T2     = "bld_eff_t2";
const string BLD_BIND_EFFECTS_T3     = "bld_eff_t3";
const string BLD_BIND_TIER1_COLOR    = "bld_t1_col";
const string BLD_BIND_TIER2_COLOR    = "bld_t2_col";
const string BLD_BIND_TIER3_COLOR    = "bld_t3_col";
const string BLD_BIND_RITUAL_LBL     = "bld_ritual_lbl";
const string BLD_BIND_RITUAL_ENA     = "bld_ritual_ena";
const string BLD_BIND_RITUAL_DESC    = "bld_ritual_desc";
const string BLD_BIND_COOLDOWN_LBL   = "bld_cd_lbl";

// Choose view binds
const string BLD_BIND_CHOICE_ROW_NAME = "bld_ch_name";
const string BLD_BIND_CHOICE_ROW_ENC  = "bld_ch_enc";
const string BLD_BIND_CHOICE_CNT      = "bld_ch_cnt";

// Buttons
const string BLD_BTN_CLOSE          = "bld_btn_close";
const string BLD_BTN_RITUAL         = "bld_btn_ritual";
const string BLD_BTN_CHOICE_ROW     = "bld_btn_ch";
const string BLD_BTN_CHOOSE_CONFIRM = "bld_btn_chconf";
const string BLD_BTN_CHOOSE_CANCEL  = "bld_btn_chcancel";

// LVARs on PC
const string BLD_LVAR_PENDING_TYPE  = "BLD_PENDING_TYPE";   // 0-based index; valid only if BLD_HAS_PENDING=1
const string BLD_LVAR_HAS_PENDING   = "BLD_HAS_PENDING";    // 1 when a row is selected in choose view

// ----------------------------------------------------------------
// Bloodline data helpers
// ----------------------------------------------------------------

string BldGetName(int nType)
{
    switch(nType)
    {
        case 0: return "Krew Tyrana";
        case 1: return "Krew Blaknienia";
        case 2: return "Krew Zelaznorodzona";
        case 3: return "Krew Piekielna";
        case 4: return "Niebianskie Dziedzictwo";
        case 5: return "Krew Drakonu";
    }
    return "Nieznana Krew";
}

string BldGetLore(int nType)
{
    switch(nType)
    {
        case 0:
            return "W zylach plynie krew dawnych tyranow, ktorzy przemoca poskramiali imperia."
                + " Ta krew pamięta kazda bitwę, kazda zdradę, kazde miasto spalone z rozkazu."
                + " Budzi sie z gluchy dudnieniem — jak armia maszerujaca w nocy."
                + " Obudzona, zaczyna kszaltowac wolę otoczenia.";
        case 1:
            return "Elficki przodek przeszedl przez Mroczny Zmierzch i wyniosl stamtad czesc cienia."
                + " Krew ta jest lodowata i cicha, jak ksiezycowe odbicie w stojacej wodzie."
                + " Im bardziej sie przebudza, tym mniej postac rzuca cien."
                + " Na skraju wzniesienia — cialo staje sie prawie niewidzialne w zmroku.";
        case 2:
            return "Glebinowi krasnoludy przekuli kiedys swoje serca w zelazo, by przezyc pod ziemia."
                + " Ich krew jest gesta, ciemna, pelna mineralow. Obudzona — zmienia kosci"
                + " w cos twardszego niz kamien. Blizny goja sie szybciej."
                + " Na szczycie przebudzenia skora twardnieje jak kora drzewa.";
        case 3:
            return "Gdzies w drzewie genealogicznym stal demon lub piekielny lord."
                + " Krew pieczy w zylach ciepl Nieskonczonej Warstwy. Przebudzona,"
                + " zaczyna wypalac sie na zewnatrz — jako cieplo skory, zapach siarki, blask oczu."
                + " Dar niesmiertelnosci, przeklete dziedzictwo.";
        case 4:
            return "Blogoslawiona linia — anjol lub bostwo dotknielo jednego z przodkow."
                + " Krew ta jest czysta i bolesna w przebudzeniu, bo wymaga wyrzeczenia sie"
                + " wszystkiego, co ciemne. Daje jasnosc widzenia i moc leczenia,"
                + " ale zada ceny — zawsze zada ceny.";
        case 5:
            return "Smoczy krew nie zna umiaru. Przodek zawarl pakt, spil smoczy eliksir"
                + " lub po prostu urodzil sie z luskami pod skora. Obudzona — sprawia,"
                + " ze skora twardnieje, a strach innych staje sie namacalny."
                + " Na szczycie — oddech smoka jest wyczuwalny w kazdym oddechu.";
    }
    return "";
}

string BldGetTierName(int nTier)
{
    switch(nTier)
    {
        case 0: return "Drzemlaca";
        case 1: return "Budzaca sie";
        case 2: return "Obudzona";
        case 3: return "Wzniosla";
    }
    return "?";
}

string BldGetTierEffectDesc(int nType, int nTier)
{
    if(nTier == BLD_TIER_STIRRING)
    {
        switch(nType)
        {
            case 0: return "+2 STR, +1 CON — Krew Tyrana drzy pod skora.";
            case 1: return "+2 DEX, +1 INT — Ruchy staja sie milczace jak cien.";
            case 2: return "+2 CON, +1 STR — Miesnie kryja kamien w swoim wnetrzu.";
            case 3: return "+2 CHA, 5% odp. ogien — Piekielny urok zaczyna promieniowac.";
            case 4: return "+2 WIS, +1 CHA — Blogoslawione spojrzenie uspokaja wrogow.";
            case 5: return "+2 STR, 5% odp. kwas — Luski rosna pod skora.";
        }
    }
    if(nTier == BLD_TIER_AWAKENED)
    {
        switch(nType)
        {
            case 0: return "+2 STR, +1 CON, immunitet strach — Tyran nie zna lęku.";
            case 1: return "+2 DEX, +1 INT, +2 do rzutow obronnych — Elficki instynkt.";
            case 2: return "+2 CON, +1 STR, +2 AC naturalne — Skora jak granit.";
            case 3: return "+2 CHA, 10% ogien, regeneracja 1/6s — Pieklo leczy pieklo.";
            case 4: return "+2 WIS, +1 CHA, +2 do rzutow obronnych — Niebieska tarcza.";
            case 5: return "+2 STR, 10% kwas, +2 AC naturalne — Smoczy pancerz.";
        }
    }
    if(nTier == BLD_TIER_ASCENDANT)
    {
        switch(nType)
        {
            case 0: return "+4 STR, +2 CON, str.+imm., +2 do ataku — Wladca Pola Bitwy.";
            case 1: return "+4 DEX, +2 INT, +3 do rzutow, +2 AC — Cien wsrod cieni.";
            case 2: return "+4 CON, +2 STR, +4 AC naturalne — Zelazne serce.";
            case 3: return "+4 CHA, 25% ogien, regen 2/6s, +2 STR — Wybrany Piekla.";
            case 4: return "+4 WIS, +2 CHA, +4 rzuty, regen 1/6s — Swiety.";
            case 5: return "+4 STR, 25% kwas, +4 AC, imm. strach — Pol-Smok.";
        }
    }
    return "Brak efektow na tym poziomie.";
}

int BldGetCurrentTier(int nPurity)
{
    if(nPurity >= BLD_PURITY_ASCENDANT) return BLD_TIER_ASCENDANT;
    if(nPurity >= BLD_PURITY_AWAKENED)  return BLD_TIER_AWAKENED;
    if(nPurity >= BLD_PURITY_STIRRING)  return BLD_TIER_STIRRING;
    return BLD_TIER_DORMANT;
}

int BldGetRitualHPPct(int nCurrentTier)
{
    switch(nCurrentTier)
    {
        case 0: return BLD_RITUAL_HP_PCT_DORMANT;
        case 1: return BLD_RITUAL_HP_PCT_STIRRING;
        case 2: return BLD_RITUAL_HP_PCT_AWAKENED;
    }
    return 0;
}

int BldGetRitualGoldCost(int nCurrentTier)
{
    switch(nCurrentTier)
    {
        case 0: return BLD_RITUAL_GOLD_DORMANT;
        case 1: return BLD_RITUAL_GOLD_STIRRING;
        case 2: return BLD_RITUAL_GOLD_AWAKENED;
    }
    return 0;
}

int BldGetNextTierPurityThreshold(int nCurrentTier)
{
    switch(nCurrentTier)
    {
        case 0: return BLD_PURITY_STIRRING;
        case 1: return BLD_PURITY_AWAKENED;
        case 2: return BLD_PURITY_ASCENDANT;
    }
    return 100;
}

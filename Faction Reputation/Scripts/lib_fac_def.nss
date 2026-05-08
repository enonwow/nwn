// lib_fac_def.nss - Faction Reputation: constants, faction data, standing helpers
//
// Single source of truth for:
//   - 4 faction IDs and their display data
//   - Standing thresholds and names
//   - NUI window/bind/button constants
//   - Rivalry map
//   - Consequences text per faction per standing

#include "lib_nui"
#include "sql_fac"

// ================================================================
// Faction IDs
// ================================================================

const int FAC_ID_IRON_GUARD     = 0;  // Żelazna Straż
const int FAC_ID_SHADOW         = 1;  // Bractwo Cienia
const int FAC_ID_NIGHT_CULT     = 2;  // Kult Wiecznej Nocy
const int FAC_ID_ORDER_FLAME    = 3;  // Zakon Płomienia
const int FAC_COUNT             = 4;

// ================================================================
// Standing level IDs (ascending prestige)
// ================================================================

const int FAC_STANDING_HOSTILE      = 0;  // <= -500
const int FAC_STANDING_UNFRIENDLY   = 1;  // -499 .. -100
const int FAC_STANDING_NEUTRAL      = 2;  // -99  ..  99
const int FAC_STANDING_FRIENDLY     = 3;  //  100 .. 499
const int FAC_STANDING_HONORED      = 4;  //  500 .. 749
const int FAC_STANDING_EXALTED      = 5;  //  750 .. 1000

// ================================================================
// Point range
// ================================================================

const int FAC_POINTS_MIN =  -1000;
const int FAC_POINTS_MAX =   1000;

// Gaining rep with one faction costs this % of the delta from the rival.
const int FAC_RIVAL_PENALTY_PCT = 50;

// ================================================================
// Effect tag prefix (one permanent effect stack per faction)
// ================================================================

const string FAC_EFFECT_TAG = "FAC_EFF_";  // + IntToString(faction_id)

// ================================================================
// Local variables on PC object
// ================================================================

const string FAC_LVAR_SEL_FACTION = "FAC_SEL_FACTION";  // int: selected faction in UI

// ================================================================
// NUI window constants
// ================================================================

const string FAC_WINDOW       = "FAC_WINDOW";
const string FAC_EV_SCRIPT    = "lib_fac_ev";
const float  FAC_WIN_W        = 680.0;
const float  FAC_WIN_H        = 530.0;
const string FAC_BIND_WIN_GEOM = "fac_win_geom";

// List binds (JsonArray of FAC_COUNT elements)
const string FAC_BIND_LST_NAME     = "fac_lst_name";      // JsonArray<string>
const string FAC_BIND_LST_STANDING = "fac_lst_standing";  // JsonArray<string>
const string FAC_BIND_LST_COLOR    = "fac_lst_color";     // JsonArray<NuiColor>
const string FAC_BIND_LST_POINTS   = "fac_lst_points";    // JsonArray<string>
const string FAC_BIND_LST_ROW_ENC  = "fac_lst_enc";       // JsonArray<bool>
const string FAC_BIND_LST_COUNT    = "fac_lst_count";     // JsonInt

// Detail panel binds (single faction)
const string FAC_BIND_DET_NAME     = "fac_det_name";
const string FAC_BIND_DET_STANDING = "fac_det_standing";
const string FAC_BIND_DET_COLOR    = "fac_det_color";
const string FAC_BIND_DET_POINTS   = "fac_det_pts";
const string FAC_BIND_DET_PROGRESS = "fac_det_prog";
const string FAC_BIND_DET_FLAVOR   = "fac_det_flavor";
const string FAC_BIND_DET_CONS     = "fac_det_cons";

// Button IDs
const string FAC_BTN_CLOSE    = "fac_btn_close";
const string FAC_BTN_ROW      = "fac_btn_row";

// ================================================================
// Faction display data
// ================================================================

string FacName(int nId)
{
    switch(nId)
    {
        case FAC_ID_IRON_GUARD:     return "Zelazna Straz";
        case FAC_ID_SHADOW:         return "Bractwo Cienia";
        case FAC_ID_NIGHT_CULT:     return "Kult Wiecznej Nocy";
        case FAC_ID_ORDER_FLAME:    return "Zakon Plomienia";
    }
    return "Nieznana Frakcja";
}

string FacDesc(int nId)
{
    switch(nId)
    {
        case FAC_ID_IRON_GUARD:
            return "Strazacy prawa i porzadku, zbrojne ramie "
                 + "miast i krolewskich dekreow. Milcza na zloto, "
                 + "lecz nie na krew. Ich lancuchy sa widoczne — "
                 + "i dlatego tak wielu je nosi.";
        case FAC_ID_SHADOW:
            return "Zlodzieje, mordercy i handlarze tajemnic. "
                 + "Ich symbol to cien rzucony przez nieistniejaca "
                 + "swiece. Nie pytaja, skad pochodzi moneta — "
                 + "pytaja tylko ile jej jest.";
        case FAC_ID_NIGHT_CULT:
            return "Wyznawcy Wiecznej Nocy, mistrzowie nekromancji "
                 + "i plugawych rytualow. Gromadza sie w miejscach, "
                 + "gdzie ziemia pamieeta smierc i marzy o powrocie.";
        case FAC_ID_ORDER_FLAME:
            return "Templariusze i kaplani Wiecznego Plomienia. "
                 + "Wiernosc dla nich nie jest cnota — jest "
                 + "obowiazkiem wypalonym w duszy zywym ogniem. "
                 + "Herezja plonie. Zawsze.";
    }
    return "";
}

// ================================================================
// Standing helpers
// ================================================================

int FacGetStanding(int nPoints)
{
    if(nPoints <= -500) return FAC_STANDING_HOSTILE;
    if(nPoints <= -100) return FAC_STANDING_UNFRIENDLY;
    if(nPoints <   100) return FAC_STANDING_NEUTRAL;
    if(nPoints <   500) return FAC_STANDING_FRIENDLY;
    if(nPoints <   750) return FAC_STANDING_HONORED;
    return FAC_STANDING_EXALTED;
}

string FacStandingName(int nStanding)
{
    switch(nStanding)
    {
        case FAC_STANDING_HOSTILE:      return "Wrogi";
        case FAC_STANDING_UNFRIENDLY:   return "Nieufny";
        case FAC_STANDING_NEUTRAL:      return "Neutralny";
        case FAC_STANDING_FRIENDLY:     return "Przychylny";
        case FAC_STANDING_HONORED:      return "Szanowany";
        case FAC_STANDING_EXALTED:      return "Wyniesiony";
    }
    return "?";
}

json FacStandingColor(int nStanding)
{
    switch(nStanding)
    {
        case FAC_STANDING_HOSTILE:      return NuiColor(220, 60,  60,  255);
        case FAC_STANDING_UNFRIENDLY:   return NuiColor(210, 130, 50,  255);
        case FAC_STANDING_NEUTRAL:      return NuiColor(170, 170, 170, 255);
        case FAC_STANDING_FRIENDLY:     return NuiColor(180, 210, 100, 255);
        case FAC_STANDING_HONORED:      return NuiColor(80,  200, 80,  255);
        case FAC_STANDING_EXALTED:      return NuiColor(210, 175, 55,  255);
    }
    return NuiColor(255, 255, 255, 255);
}

// Maps -1000..1000 to 0.0..1.0 for progress bar.
float FacProgressNorm(int nPoints)
{
    int nClamped = nPoints;
    if(nClamped < FAC_POINTS_MIN) nClamped = FAC_POINTS_MIN;
    if(nClamped > FAC_POINTS_MAX) nClamped = FAC_POINTS_MAX;
    return (IntToFloat(nClamped) + 1000.0) / 2000.0;
}

// ================================================================
// Consequences text (player-visible Polish, dark-fantasy flavour)
// ================================================================

string FacConsequences(int nFactionId, int nStanding)
{
    if(nFactionId == FAC_ID_IRON_GUARD)
    {
        switch(nStanding)
        {
            case FAC_STANDING_HOSTILE:
                return "- Strazacy atakuja na widok\n"
                     + "- Nakaz pojmania rozeslany\n"
                     + "- Kupcy gildyjni zamykaja drzwi";
            case FAC_STANDING_UNFRIENDLY:
                return "- Strazacy obserwuja z podejrzliwoscia\n"
                     + "- Posterunki zamkniete\n"
                     + "- Ceny u kupców +15%";
            case FAC_STANDING_NEUTRAL:
                return "- Normalne relacje, brak bonusow i kar";
            case FAC_STANDING_FRIENDLY:
                return "- +1 Charyzma, +2 Perswazja\n"
                     + "- Strazacy wspomagaja w walce (raz/godz.)\n"
                     + "- Kupcy gildyjni: -5% ceny";
            case FAC_STANDING_HONORED:
                return "- +2 Charyzma, +4 Perswazja, +1 KP\n"
                     + "- Dostep do zbrojowni strazy\n"
                     + "- Kupcy gildyjni: -10% ceny";
            case FAC_STANDING_EXALTED:
                return "- +3 Charyzma, +6 Perswazja, +2 KP, +1 atak\n"
                     + "- Status zastepcy kapitana\n"
                     + "- Kupcy gildyjni: -15% ceny\n"
                     + "- Dostep do strzezonych stref";
        }
    }
    else if(nFactionId == FAC_ID_SHADOW)
    {
        switch(nStanding)
        {
            case FAC_STANDING_HOSTILE:
                return "- Zabojcy Bractwa tropia bohatera\n"
                     + "- Kieszonkowcy kradna przy okazji\n"
                     + "- Dzielnica Cienia zamknieta";
            case FAC_STANDING_UNFRIENDLY:
                return "- Handlarze Bractwa odwracaja sie\n"
                     + "- Informatorzy milcza\n"
                     + "- Ryzyko zasadzki w zaaulkach";
            case FAC_STANDING_NEUTRAL:
                return "- Normalne relacje, brak bonusow i kar";
            case FAC_STANDING_FRIENDLY:
                return "- +3 Ukrywanie, +3 Ciche Kroki\n"
                     + "- Dostep do fenca Bractwa\n"
                     + "- Informatorzy szepca plotki";
            case FAC_STANDING_HONORED:
                return "- +6 Ukrywanie, +6 Ciche Kroki, +3 Kieszonk.\n"
                     + "- Ochrona przed ulicznymi zlodziejami\n"
                     + "- Bezpieczny przeejazd przez Dzielnice Cienia";
            case FAC_STANDING_EXALTED:
                return "- +9 Ukrywanie, +9 Ciche Kroki, +6 Kieszonk.\n"
                     + "- 10% Ukrycie z mroku\n"
                     + "- Tytul Mistrza Cienia\n"
                     + "- Tajne kontrakty Bractwa";
        }
    }
    else if(nFactionId == FAC_ID_NIGHT_CULT)
    {
        switch(nStanding)
        {
            case FAC_STANDING_HOSTILE:
                return "- Kultysci i nieumarli atakuja\n"
                     + "- Klatwa nekrotyczna: -2 do rzutow obronnych\n"
                     + "- Swiatynie Kultu zamkniete";
            case FAC_STANDING_UNFRIENDLY:
                return "- Kultysci obserwuja z wrogoscia\n"
                     + "- Nieumarli wykazuja agresje\n"
                     + "- Rytualy Kultu niedostepne";
            case FAC_STANDING_NEUTRAL:
                return "- Normalne relacje, brak bonusow i kar";
            case FAC_STANDING_FRIENDLY:
                return "- +3 Wiedza Czarow, +2 Erudycja\n"
                     + "- Nieumarli ignoruja postac noca\n"
                     + "- Rytualy nizszej rangi dostepne";
            case FAC_STANDING_HONORED:
                return "- +6 Wiedza Czarow, +4 Erudycja, +1 Budowa\n"
                     + "- Blogoslawienstwo Nocy (ikona efektu)\n"
                     + "- Biblioteka nekromantyczna dostepna";
            case FAC_STANDING_EXALTED:
                return "- +9 Wiedza Czarow, +6 Erudycja, +2 Sila, +1 Budowa\n"
                     + "- Nieumarli sojusznicy w walce\n"
                     + "- Tytul Herolda Wiecznej Nocy\n"
                     + "- Krypta Zalozycieli dostepna";
        }
    }
    else if(nFactionId == FAC_ID_ORDER_FLAME)
    {
        switch(nStanding)
        {
            case FAC_STANDING_HOSTILE:
                return "- Templariusze atakuja\n"
                     + "- Klatwa pariasa: -2 Madrosc\n"
                     + "- Swiatynie zamkniete, leczenie nedostepne";
            case FAC_STANDING_UNFRIENDLY:
                return "- Kaplani odmawiaja blogoslawienstw\n"
                     + "- Leczenie w swiatyniach +30% drozej\n"
                     + "- Templariusze ignoruja prosby";
            case FAC_STANDING_NEUTRAL:
                return "- Normalne relacje, brak bonusow i kar";
            case FAC_STANDING_FRIENDLY:
                return "- +1 Madrosc, +2 Leczenie\n"
                     + "- Leczenie w swiatyniach -10% taniej\n"
                     + "- Blogoslawienstwo kaplana raz dziennie";
            case FAC_STANDING_HONORED:
                return "- +2 Madrosc, +4 Leczenie, +1 do rzutow obrnn.\n"
                     + "- Leczenie w swiatyniach -20% taniej\n"
                     + "- Templariusze wspomagaja w walce";
            case FAC_STANDING_EXALTED:
                return "- +3 Madrosc, +6 Leczenie, +2 rzuty obrnn., +1 KP\n"
                     + "- Tytul Mistrza Plomienia\n"
                     + "- Leczenie w swiatyniach bezplatne\n"
                     + "- Odpornosc ogien +10%, +2 Opedzanie Nieumarle";
        }
    }
    return "";
}

// ================================================================
// Rivalry
// ================================================================

// Returns the rival faction ID, or -1 if none.
// Pair: Iron Guard <-> Shadow Brotherhood | Night Cult <-> Order of Flame
int FacGetRival(int nFactionId)
{
    switch(nFactionId)
    {
        case FAC_ID_IRON_GUARD:  return FAC_ID_SHADOW;
        case FAC_ID_SHADOW:      return FAC_ID_IRON_GUARD;
        case FAC_ID_NIGHT_CULT:  return FAC_ID_ORDER_FLAME;
        case FAC_ID_ORDER_FLAME: return FAC_ID_NIGHT_CULT;
    }
    return -1;
}

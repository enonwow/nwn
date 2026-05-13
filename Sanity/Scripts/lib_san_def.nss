// lib_san_def.nss — constants, bind/button IDs, and lightweight helpers
//   for the Sanity module.

#include "lib_nui"
#include "sql_san"

// Forward declarations for functions defined in lib_san.nss.
void SanOpen(object oPC);
void SanFeedWindow(object oPC, int nToken);
void SanApplyEffects(object oPC);
void SanSyncEffects(object oPC);

// ----------------------------------------------------------------
// Window / script identifiers
// ----------------------------------------------------------------

const string SAN_WINDOW    = "SAN_WINDOW";
const string SAN_EV_SCRIPT = "lib_san_ev";
const string SAN_WIN_GEOM  = "san_win_geom";

// ----------------------------------------------------------------
// Sanity thresholds  (exclusive lower bounds)
// ----------------------------------------------------------------

const int SAN_THR_UNEASE   = 75;   // [75, 100] — SPOKOJNY
const int SAN_THR_HORROR   = 50;   // [50,  74] — NIEPOKÓJ
const int SAN_THR_MADNESS  = 25;   // [25,  49] — GROZA
const int SAN_THR_INSANITY = 10;   // [10,  24] — OBŁĘD
                                   // [ 0,   9] — SZALEŃSTWO

// ----------------------------------------------------------------
// Delta values for each trigger
// ----------------------------------------------------------------

const int SAN_LOSS_UNDEAD     =  3;
const int SAN_LOSS_NEAR_DEATH =  5;
const int SAN_LOSS_HORROR_AREA=  2;
const int SAN_LOSS_ALLY_DEATH =  8;

const int SAN_GAIN_REST      = 15;
const int SAN_GAIN_MEDITATE  =  5;
const int SAN_GAIN_HOLY      = 10;

// ----------------------------------------------------------------
// Cooldowns  (seconds)
// ----------------------------------------------------------------

const int SAN_COOLDOWN_MEDITATE  = 120;

// Heartbeat-tick cadence: module OnHeartbeat fires every 6 s.
// We keep a global tick counter and gate checks by modulus.
const int SAN_TICK_UNDEAD     = 10;   //  60 s
const int SAN_TICK_NEAR_DEATH = 20;   // 120 s
const int SAN_TICK_HORROR_AREA= 30;   // 180 s
const int SAN_TICK_RAND_FX    =  1;   // every heartbeat, probability-gated

// ----------------------------------------------------------------
// Local variable names  (on PC object)
// ----------------------------------------------------------------

const string SAN_LVAR_SYNC_LVL = "SAN_SYNC_LVL";   // last applied effect level

// ----------------------------------------------------------------
// Tag for holy-water item that restores sanity
// ----------------------------------------------------------------

const string SAN_ITEM_TAG_HOLY = "san_holy_water";

// Tag applied to every SAN effect so they can be found and removed.
const string SAN_EFFECT_TAG    = "SAN_EFFECT";

// Local variable on Module for heartbeat counter
const string SAN_LVAR_TICK     = "SAN_TICK";

// Local variable on Area to mark it as a horror zone
const string SAN_AREA_HORROR   = "SAN_HORROR_AREA";

// ----------------------------------------------------------------
// NUI bind names
// ----------------------------------------------------------------

const string SAN_BIND_STATUS_LBL = "san_status_lbl";
const string SAN_BIND_STATUS_COL = "san_status_col";
const string SAN_BIND_VALUE_TXT  = "san_value_txt";
const string SAN_BIND_BAR_VAL    = "san_bar_val";
const string SAN_BIND_BAR_COL    = "san_bar_col";
const string SAN_BIND_FLAVOR_TXT = "san_flavor";
const string SAN_BIND_EVT_LBL    = "san_evt_lbl";
const string SAN_BIND_EVT_COL    = "san_evt_col";
const string SAN_BIND_EVT_COUNT  = "san_evt_cnt";
const string SAN_BIND_MED_ENA    = "san_med_ena";
const string SAN_BIND_MED_TIP    = "san_med_tip";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string SAN_BTN_CLOSE    = "san_btn_close";
const string SAN_BTN_MEDITATE = "san_btn_meditate";

// ----------------------------------------------------------------
// Layout dimensions  (unscaled; scaled via GetNuiScaleDimension)
// ----------------------------------------------------------------

const float SAN_W = 380.0;
const float SAN_H = 440.0;

// ----------------------------------------------------------------
// Inline helpers
// ----------------------------------------------------------------

// Returns a NUI color JSON appropriate for the current sanity level.
json SanBarColor(int nSan)
{
    if(nSan >= SAN_THR_UNEASE)   return NuiColor( 80, 200,  80, 255);  // green
    if(nSan >= SAN_THR_HORROR)   return NuiColor(220, 200,  50, 255);  // yellow
    if(nSan >= SAN_THR_MADNESS)  return NuiColor(220, 120,  30, 255);  // orange
    if(nSan >= SAN_THR_INSANITY) return NuiColor(200,  60,  60, 255);  // red
    return                              NuiColor(160,  30, 160, 255);  // deep purple
}

// Short label displayed prominently in the UI.
string SanStatusText(int nSan)
{
    if(nSan >= SAN_THR_UNEASE)   return "SPOKOJNY";
    if(nSan >= SAN_THR_HORROR)   return "NIEPOKÓJ";
    if(nSan >= SAN_THR_MADNESS)  return "GROZA";
    if(nSan >= SAN_THR_INSANITY) return "OBŁĘD";
    return                              "SZALEŃSTWO";
}

// Two-line flavor text shown below the bar.
string SanFlavorText(int nSan)
{
    if(nSan >= SAN_THR_UNEASE)
        return "Twój umysł jest trzeźwy.\nCienie nie mają nad tobą władzy.";
    if(nSan >= SAN_THR_HORROR)
        return "Coś drąży w ciemności twego umysłu.\nSny nie przynoszą ukojenia.";
    if(nSan >= SAN_THR_MADNESS)
        return "Groza zlewa się z rzeczywistością.\nWidzisz rzeczy, które nie powinny istnieć.";
    if(nSan >= SAN_THR_INSANITY)
        return "Krzyki wypełniają głowę.\nNie wiesz już, co jest prawdziwe, a co ułudą.";
    return "Umysł pęka pod ciężarem obłędu.\nSzaleństwo jest jedyną prawdą.";
}

// Encodes the current sanity into one of 5 levels (0-4) used to detect
// threshold crossings without comparing full integer values.
int SanThresholdLevel(int nSan)
{
    if(nSan >= SAN_THR_UNEASE)   return 0;
    if(nSan >= SAN_THR_HORROR)   return 1;
    if(nSan >= SAN_THR_MADNESS)  return 2;
    if(nSan >= SAN_THR_INSANITY) return 3;
    return 4;
}

// Notification sent to PC when crossing a threshold.
string SanThresholdMessage(int nLevel)
{
    switch(nLevel)
    {
        case 1: return "[Szaleństwo] Niepokój zaczyna gryzć od środka. Twój wzrok jest cięższy.";
        case 2: return "[Szaleństwo] Groza przesącza się przez myśli. Wizje zacierają rzeczywistość.";
        case 3: return "[Szaleństwo] Obłąkanie rozdziera umysł. Nie kontrolujesz własnych myśli.";
        case 4: return "[Szaleństwo] Szaleństwo całkowicie cię pochłania. Jesteś złamany.";
    }
    return "[Szaleństwo] Spokój powraca. Cienie cofają się.";
}

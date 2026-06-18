// lib_vic_def.nss — Constants, NUI bind/button IDs, substance metadata, and
// timing helpers for the Vices (Nałogi) system.
#include "lib_nui"
#include "sql_vic"

// ============================================================
// Forward declarations (bodies in lib_vic.nss)
// ============================================================
void FeedViceWindow(object oPC, int nToken);
void VicApplyEffects(object oPC, int nSubstance, int nState, int nLevel);
void VicRemoveEffects(object oPC, int nSubstance);
void VicTick(object oPC);

// ============================================================
// Substance IDs
// ============================================================
const int VICE_MOONFIRE     = 0;   // Księżycowy Trunek — destylat rosy i korzenia silvari
const int VICE_DREAMDUST    = 1;   // Proch Snów — proch z Czarnego Lotosu
const int VICE_DEMON_BLOOD  = 2;   // Krew Demona — skrzepnięta krew z niższych warstw
const int VICE_BLACKROOT    = 3;   // Czarny Korzeń — ekstrakt z krypt
const int VICE_WITCH_MILK   = 4;   // Mleko Czarownicy — białawy płyn z Drzewa Wiedźmy
const int VICE_SHADOW_PASTE = 5;   // Pasta Cienia — czarna maź Zakonu Cienia
const int VICE_COUNT        = 6;

// ============================================================
// Runtime addiction states (not persisted — derived each tick)
// ============================================================
const int VICE_STATE_SOBER      = 0;
const int VICE_STATE_SATISFIED  = 1;
const int VICE_STATE_CRAVING    = 2;
const int VICE_STATE_WITHDRAWAL = 3;

// ============================================================
// Window / script IDs
// ============================================================
const string VIC_WINDOW    = "VIC_WINDOW";
const string VIC_EV_SCRIPT = "lib_vic_ev";
const string VIC_WIN_GEOM  = "vic_win_geom";

// ============================================================
// Bind names  (suffix = IntToString(substanceId) for per-row binds)
// ============================================================
const string VIC_BIND_NAME    = "vic_name_";    // + substId
const string VIC_BIND_STATE   = "vic_state_";   // + substId
const string VIC_BIND_LEVEL   = "vic_level_";   // + substId
const string VIC_BIND_COLOR   = "vic_color_";   // + substId
const string VIC_BIND_BTENA   = "vic_btena_";   // consume btn enabled + substId
const string VIC_BIND_CLEAN   = "vic_clean_";   // detox btn enabled + substId
const string VIC_BIND_FLAVOR  = "vic_flavor";
const string VIC_BIND_WARNING = "vic_warning";

// ============================================================
// Button IDs
// ============================================================
const string VIC_BTN_CONSUME  = "vic_consume_";  // + substId
const string VIC_BTN_BREAK    = "vic_break_";    // + substId

// ============================================================
// LVARs on PC
// ============================================================
const string VIC_LVAR_TICK      = "VIC_TICK";
const string VIC_LVAR_STATE_PFX = "VIC_LAST_";  // + substId → last known state int

// Effect tags — used with TagEffect() to locate effects for removal.
const string VIC_ETAG_BUFF   = "VIC_B_";   // + substId
const string VIC_ETAG_WITHDR = "VIC_W_";   // + substId

// Tick interval (seconds)
const float VIC_TICK_INTERVAL = 60.0;

// Detox minimum wait without dosing before attempting (30 min real-time).
const int VIC_DETOX_MIN_WAIT = 1800;

// ============================================================
// Timing helpers
// ============================================================

// Seconds after last dose before craving onset.
int VicCravingOnset(int nLevel)
{
    switch(nLevel)
    {
        case 1: return 1800;  // 30 min
        case 2: return 1500;  // 25 min
        case 3: return 1200;  // 20 min
        case 4: return  900;  // 15 min
        case 5: return  420;  //  7 min
    }
    return 99999;
}

// Seconds after last dose before full withdrawal onset.
int VicWithdrawalOnset(int nLevel)
{
    switch(nLevel)
    {
        case 1: return 3600;  // 60 min
        case 2: return 2400;  // 40 min
        case 3: return 1800;  // 30 min
        case 4: return 1200;  // 20 min
        case 5: return  600;  // 10 min
    }
    return 99999;
}

// Effect magnitude (buff bonus) scales with addiction level.
int VicBuffMagnitude(int nLevel)
{
    if(nLevel <= 2) return 1;
    if(nLevel <= 4) return 2;
    return 3;
}

// ============================================================
// Display helpers
// ============================================================

string VicSubstanceName(int nSub)
{
    switch(nSub)
    {
        case VICE_MOONFIRE:     return "Księżycowy Trunek";
        case VICE_DREAMDUST:    return "Proch Snów";
        case VICE_DEMON_BLOOD:  return "Krew Demona";
        case VICE_BLACKROOT:    return "Czarny Korzeń";
        case VICE_WITCH_MILK:   return "Mleko Czarownicy";
        case VICE_SHADOW_PASTE: return "Pasta Cienia";
    }
    return "Nieznana Substancja";
}

string VicStateName(int nState)
{
    switch(nState)
    {
        case VICE_STATE_SOBER:      return "Trzeźwy";
        case VICE_STATE_SATISFIED:  return "Nasycony";
        case VICE_STATE_CRAVING:    return "Pragnie";
        case VICE_STATE_WITHDRAWAL: return "Odstawienie";
    }
    return "";
}

json VicStateColor(int nState)
{
    switch(nState)
    {
        case VICE_STATE_SOBER:      return NuiColor(170, 170, 170, 255);
        case VICE_STATE_SATISFIED:  return NuiColor(90,  210, 90,  255);
        case VICE_STATE_CRAVING:    return NuiColor(220, 180, 60,  255);
        case VICE_STATE_WITHDRAWAL: return NuiColor(220, 50,  50,  255);
    }
    return NuiColor(255, 255, 255, 255);
}

string VicFlavorText(int nSub, int nState, int nLevel)
{
    if(nState == VICE_STATE_SATISFIED)
    {
        switch(nSub)
        {
            case VICE_MOONFIRE:     return "Ciepło rozlewa się po ciele jak roztopiony bursztyn. Mięśnie nie znają zmęczenia.";
            case VICE_DREAMDUST:    return "Zmysły wyostrzają się. Świat mówi przez ukryte wzory i szepty pod powierzchnią.";
            case VICE_DEMON_BLOOD:  return "Krew się gotuje, gniew i siła stają się jednym. Pieczęć na skórze pulsuje czerwienią.";
            case VICE_BLACKROOT:    return "Strach milknie jak zdmuchnięta świeca. Zostaje tylko zimna, krystaliczna determinacja.";
            case VICE_WITCH_MILK:   return "Słowa płyną jak jedwab przez palce. Inni słuchają — i wierzą każdemu słowu.";
            case VICE_SHADOW_PASTE: return "Cień staje się twoim sojusznikiem. Kroki cichną bez wysiłku, wzrok ostrzy się w mroku.";
        }
    }
    else if(nState == VICE_STATE_CRAVING)
    {
        switch(nSub)
        {
            case VICE_MOONFIRE:     return "Usta wysychają. Głowa pulsuje bolesnym rytmem. Jeden łyk… jeden tylko łyk.";
            case VICE_DREAMDUST:    return "Rzeczywistość jest zbyt głośna, zbyt ostra. Musisz uśmierzyć ten hałas.";
            case VICE_DEMON_BLOOD:  return "Ciało żąda więcej mocy. Ten głód to nie pragnienie — to rozkaz z wnętrzności.";
            case VICE_BLACKROOT:    return "Stary strach pełza z powrotem jak mgła z krypty. Korzeń by go zagnał.";
            case VICE_WITCH_MILK:   return "Słowa plączą się na języku. Czujesz się błahym, zwykłym, nudnym.";
            case VICE_SHADOW_PASTE: return "Cienie wokół wydają się wrogie. Czujesz się obnażony i zbyt widoczny.";
        }
    }
    else if(nState == VICE_STATE_WITHDRAWAL)
    {
        switch(nSub)
        {
            case VICE_MOONFIRE:     return "Trzęsą ci się ręce. Każda kość boli jakby ktoś wbijał w nią gwoździe. Karczma zbawia.";
            case VICE_DREAMDUST:    return "Bez prochu świat to agonalne błoto. Myśli rwą się jak spróchniała lina nad przepaścią.";
            case VICE_DEMON_BLOOD:  return "Ciało buntuje się gwałtownie. Mięśnie kurczą się. Pieczęć pali jak rozgrzany metal.";
            case VICE_BLACKROOT:    return "Strach powrócił w pełnej chwale. Każdy cień to wróg. Każdy krok to pułapka.";
            case VICE_WITCH_MILK:   return "Mdłości. Drżenie rąk. Jesteś niczym — pustym workiem na kości — bez mleka.";
            case VICE_SHADOW_PASTE: return "Czujesz się śmiertelnie obnażony. Pasta to nie luksus — to jedyna rzecz, która ma sens.";
        }
    }
    // SOBER — first time description
    switch(nSub)
    {
        case VICE_MOONFIRE:     return "Destylat ze zmrożonej rosy i korzenia silvari. Wędrowcy mówią, że rozgrzewa krew przed bitwą.";
        case VICE_DREAMDUST:    return "Proszek mielony z suszonego kwiatu Czarnego Lotosu. Wróżbiarze cenią go nad złoto.";
        case VICE_DEMON_BLOOD:  return "Skrzepnięta krew z głębokich warstw. Smakuje metalicznie i niesie obietnicę potęgi.";
        case VICE_BLACKROOT:    return "Ekstrakt z korzenia rosnącego tylko w mroku krypt. Medycy używają go jako środka przeciwbólowego.";
        case VICE_WITCH_MILK:   return "Biały płyn z drzewa Czarownicy. Przyciąga wzrok i przykuwa języki. Ceniony przez dyplomatów.";
        case VICE_SHADOW_PASTE: return "Czarna maź wyrabiana przez złodziei Zakonu Cienia i wcierana w skórę przed pracą.";
    }
    return "";
}

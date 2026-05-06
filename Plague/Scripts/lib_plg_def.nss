#include "lib_nui"
#include "sql_plg"

// Forward declarations (defined in lib_plg.nss)
void FeedPlgWindow(object oPC, int nToken);
void PlgApplyEffects(object oPC, int nDiseaseId, int nPhase);
void PlgRemoveEffects(object oPC);
void PlgContractAndNotify(object oPC, int nDiseaseId);
void PlgCureAndNotify(object oPC);

// ================================================================
// Window / UI constants
// ================================================================
const string PLG_WINDOW        = "PLG_WIN";
const string PLG_WIN_TEST      = "PLG_WIN_TEST";
const string PLG_EV_SCRIPT     = "lib_plg_ev";
const string PLG_WIN_GEOM      = "plg_win_geom";
const string PLG_TEST_GEOM     = "plg_test_geom";

const string PLG_BIND_NAME     = "plg_name";        // disease name label
const string PLG_BIND_PHASE    = "plg_phase";       // phase name label
const string PLG_BIND_FLAVOR   = "plg_flavor";      // phase flavor text body
const string PLG_BIND_SYMPTOMS = "plg_symptoms";    // symptom list label
const string PLG_BIND_REMEDY   = "plg_remedy";      // remedy name label
const string PLG_BIND_CURE_ENA = "plg_cure_ena";    // cure button enabled
const string PLG_BIND_TIMER    = "plg_timer";       // "Następna faza za: HH:MM:SS"
const string PLG_BIND_PROG     = "plg_prog";        // progress bar 0.0-1.0
const string PLG_BIND_PROG_COL = "plg_prog_col";   // progress bar tint color

// test window binds
const string PLG_BIND_TEST_DIS = "plg_t_dis";      // disease name array for list
const string PLG_BIND_TEST_LEN = "plg_t_len";      // list row count

const string PLG_BTN_CLOSE     = "plg_close";
const string PLG_BTN_CURE      = "plg_cure";
const string PLG_BTN_TEST_ROW  = "plg_t_row";      // list row in test window
const string PLG_BTN_TEST_CURE = "plg_t_cure";     // instant cure in test window
const string PLG_BTN_TEST_OPEN = "plg_t_open";     // open main window from test

const float  PLG_W             = 440.0;
const float  PLG_H             = 510.0;
const float  PLG_TEST_W        = 360.0;
const float  PLG_TEST_H        = 300.0;

// ================================================================
// Disease IDs
// ================================================================
const int PLG_DIS_NONE         = -1;
const int PLG_DIS_BLACK_PLAGUE = 0;
const int PLG_DIS_BLOOD_ROT    = 1;
const int PLG_DIS_SWAMP_FEVER  = 2;
const int PLG_DIS_NECROTIC     = 3;
const int PLG_DIS_LYCANTHROPY  = 4;
const int PLG_DIS_COUNT        = 5;

// ================================================================
// Phase IDs
// ================================================================
const int PLG_PHASE_NONE       = 0;
const int PLG_PHASE_INCUBATION = 1;
const int PLG_PHASE_MILD       = 2;
const int PLG_PHASE_SEVERE     = 3;
const int PLG_PHASE_CRITICAL   = 4;

// ================================================================
// Local variables (cached on PC for fast heartbeat read)
// ================================================================
const string PLG_LVAR_DISEASE  = "PLG_DISEASE";   // int: disease id, -1 = none
const string PLG_LVAR_PHASE    = "PLG_PHASE";     // int: current phase
const string PLG_LVAR_TICK     = "PLG_TICK";      // int: heartbeat tick counter for DoT

// Tag on every effect applied by this system; allows clean removal via effect loop
const string PLG_EFFECT_TAG    = "PLG_EFFECT";

// ================================================================
// Static disease data
// ================================================================

string PlgDiseaseName(int nId)
{
    switch(nId)
    {
        case PLG_DIS_BLACK_PLAGUE: return "Czarna Dżuma";
        case PLG_DIS_BLOOD_ROT:   return "Krwawa Zgnilizna";
        case PLG_DIS_SWAMP_FEVER: return "Bagienka Gorączka";
        case PLG_DIS_NECROTIC:    return "Nekrotyczna Rana";
        case PLG_DIS_LYCANTHROPY: return "Przekleństwo Wilkołaka";
    }
    return "Brak";
}

string PlgDiseaseRemedyTag(int nId)
{
    switch(nId)
    {
        case PLG_DIS_BLACK_PLAGUE: return "plg_rem_plaga";
        case PLG_DIS_BLOOD_ROT:   return "plg_rem_krew";
        case PLG_DIS_SWAMP_FEVER: return "plg_rem_bagna";
        case PLG_DIS_NECROTIC:    return "plg_rem_nkr";
        case PLG_DIS_LYCANTHROPY: return "plg_rem_wilk";
    }
    return "";
}

string PlgDiseaseRemedyName(int nId)
{
    switch(nId)
    {
        case PLG_DIS_BLACK_PLAGUE: return "Napar z czarnej malwy";
        case PLG_DIS_BLOOD_ROT:   return "Ziołowy bandaż hemostatyczny";
        case PLG_DIS_SWAMP_FEVER: return "Korzeń topoli bagiennej";
        case PLG_DIS_NECROTIC:    return "Poświęcona woda";
        case PLG_DIS_LYCANTHROPY: return "Srebrna woda";
    }
    return "Nieznane lekarstwo";
}

// Color tinting the progression bar per disease
json PlgDiseaseColor(int nId)
{
    switch(nId)
    {
        case PLG_DIS_BLACK_PLAGUE: return NuiColor(100,  60, 120);  // dark purple
        case PLG_DIS_BLOOD_ROT:   return NuiColor(200,  40,  40);  // crimson
        case PLG_DIS_SWAMP_FEVER: return NuiColor( 80, 160,  60);  // sickly green
        case PLG_DIS_NECROTIC:    return NuiColor( 60,  80, 120);  // necrotic blue-grey
        case PLG_DIS_LYCANTHROPY: return NuiColor(180, 140,  60);  // amber
    }
    return NuiColor(120, 120, 120);
}

string PlgPhaseName(int nPhase)
{
    switch(nPhase)
    {
        case PLG_PHASE_INCUBATION: return "Inkubacja";
        case PLG_PHASE_MILD:       return "Łagodne objawy";
        case PLG_PHASE_SEVERE:     return "Choroba";
        case PLG_PHASE_CRITICAL:   return "Stan krytyczny";
    }
    return "—";
}

string PlgPhaseFlavor(int nDiseaseId, int nPhase)
{
    if(nDiseaseId == PLG_DIS_BLACK_PLAGUE)
    {
        switch(nPhase)
        {
            case PLG_PHASE_INCUBATION:
                return "Czujesz lekkie drżenie mięśni i nieustępliwe zmęczenie. Plamy pod pachami swędzą — nie przypisujesz im znaczenia.";
            case PLG_PHASE_MILD:
                return "Gorączka nie odpuszcza od kilku godzin. Węzły chłonne puchną boleśnie pod skórą. Krew w ślinie zabarwia chustę na różowo.";
            case PLG_PHASE_SEVERE:
                return "Czarne bąble pękają, wydzielając cuchnącą meszę. Każdy oddech to agonia. Okoliczne istoty odsuwają się instynktownie.";
            case PLG_PHASE_CRITICAL:
                return "Ciemność pulsuje za oczami. Skóra czernieje wzdłuż żył. Bez natychmiastowego leczenia śmierć jest pewna.";
        }
    }
    else if(nDiseaseId == PLG_DIS_BLOOD_ROT)
    {
        switch(nPhase)
        {
            case PLG_PHASE_INCUBATION:
                return "Stare blizny zaczęły piec bez powodu. Krew pod paznokciami ma zbyt ciemny kolor.";
            case PLG_PHASE_MILD:
                return "Żyły na przedramionach mienią się purpurą. Rany nie chcą się zagoić — każde zadrapanie krwawi zbyt długo.";
            case PLG_PHASE_SEVERE:
                return "Skóra pęka wzdłuż żył, jakby ciało chciało otworzyć się od wewnątrz. Każdy ruch zostawia na ubraniu brązowe ślady.";
            case PLG_PHASE_CRITICAL:
                return "Krew sączy się z oczu i uszu. Twoje serce bije nieregularnie. Każda chwila bez lekarstwa to kolejna miara życia utracona.";
        }
    }
    else if(nDiseaseId == PLG_DIS_SWAMP_FEVER)
    {
        switch(nPhase)
        {
            case PLG_PHASE_INCUBATION:
                return "Mdły zapach błota tkwi w nozdrzach, choć jesteś daleko od mokradeł. Palce drżą przy porannym wstawaniu.";
            case PLG_PHASE_MILD:
                return "Gorączka bagienna robi swoje — rzeczywistość zaciera kontury. Widzisz cienie tam, gdzie ich nie ma.";
            case PLG_PHASE_SEVERE:
                return "Halucynacje przybierają na sile. Pewność ruchów zanika; nogi niosą cię chwiejnie jak pijanego.";
            case PLG_PHASE_CRITICAL:
                return "Drżączka unieruchamia palce. Świat kręci się wokół ciebie. Tylko zimne lekarstwo może przywrócić jasność umysłu.";
        }
    }
    else if(nDiseaseId == PLG_DIS_NECROTIC)
    {
        switch(nPhase)
        {
            case PLG_PHASE_INCUBATION:
                return "Rana, od której się wszystko zaczęło, przestała boleć. Mięso wokół jest blade — zbyt blade.";
            case PLG_PHASE_MILD:
                return "Nekrotyczna tkanka pełznie wzdłuż ramienia. Skóra zgrabiała i stwardniała jak skóra trupa.";
            case PLG_PHASE_SEVERE:
                return "Zaraza sięga głębiej — czujesz, jak siła uchodzi z mięśni, jakby coś wysysało cię od wewnątrz.";
            case PLG_PHASE_CRITICAL:
                return "Połowa ciała jest zimna jak kamień. Nekromantyczna trucizna żywi się twoją żywotnością. Poświęcona woda to jedyna nadzieja.";
        }
    }
    else if(nDiseaseId == PLG_DIS_LYCANTHROPY)
    {
        switch(nPhase)
        {
            case PLG_PHASE_INCUBATION:
                return "Ugryzienie zagoiło się szybciej, niż powinno. W nocy masz sny o polowaniach i krwi.";
            case PLG_PHASE_MILD:
                return "Mięśnie rosną niespodziewanie. Instynkt podpowiada ci zagrożenia, zanim je dostrzeżesz. Coś w tobie tęskni za księżycem.";
            case PLG_PHASE_SEVERE:
                return "Myśli stają się prostsze — łup, krew, terytorium. Utrzymanie człowieczeństwa kosztuje coraz więcej wysiłku woli.";
            case PLG_PHASE_CRITICAL:
                return "Bestia walczy o kontrolę. Ruchy stają się gwałtowne i niekontrolowane. Srebrna woda jest ostatnią szansą przed pełną przemianą.";
        }
    }
    return "";
}

// Returns human-readable list of current penalties for the UI symptoms field.
string PlgPhaseSymptoms(int nDiseaseId, int nPhase)
{
    if(nPhase <= PLG_PHASE_INCUBATION) return "Brak widocznych objawów.";
    if(nDiseaseId == PLG_DIS_BLACK_PLAGUE)
    {
        switch(nPhase)
        {
            case PLG_PHASE_MILD:     return "-2 Kondycja";
            case PLG_PHASE_SEVERE:   return "-4 Kondycja, -2 Siła";
            case PLG_PHASE_CRITICAL: return "-6 Kondycja, -4 Siła";
        }
    }
    else if(nDiseaseId == PLG_DIS_BLOOD_ROT)
    {
        switch(nPhase)
        {
            case PLG_PHASE_MILD:     return "-1 Pancerz, -1 do Rzutów Obronnych";
            case PLG_PHASE_SEVERE:   return "-2 Pancerz, -2 do Rzutów Obronnych";
            case PLG_PHASE_CRITICAL: return "-3 Pancerz, -3 do Rzutów Obronnych, krwotok co 30s";
        }
    }
    else if(nDiseaseId == PLG_DIS_SWAMP_FEVER)
    {
        switch(nPhase)
        {
            case PLG_PHASE_MILD:     return "-2 Zręczność";
            case PLG_PHASE_SEVERE:   return "-4 Zręczność, -2 Mądrość";
            case PLG_PHASE_CRITICAL: return "-6 Zręczność, -4 Mądrość";
        }
    }
    else if(nDiseaseId == PLG_DIS_NECROTIC)
    {
        switch(nPhase)
        {
            case PLG_PHASE_MILD:     return "-1 Siła";
            case PLG_PHASE_SEVERE:   return "-3 Siła, -2 Kondycja";
            case PLG_PHASE_CRITICAL: return "-5 Siła, -4 Kondycja, obrażenia nekrotyczne co 30s";
        }
    }
    else if(nDiseaseId == PLG_DIS_LYCANTHROPY)
    {
        switch(nPhase)
        {
            case PLG_PHASE_MILD:     return "+2 Siła, -2 Mądrość";
            case PLG_PHASE_SEVERE:   return "+4 Siła, -4 Mądrość";
            case PLG_PHASE_CRITICAL: return "+6 Siła, -6 Mądrość, napady wściekłości";
        }
    }
    return "";
}

// Seconds before this phase advances to the next one.
// Phase 4 (critical) never advances — pass 0 to PlgAdvancePhase.
int PlgPhaseInterval(int nDiseaseId, int nPhase)
{
    if(nDiseaseId == PLG_DIS_BLACK_PLAGUE)
    {
        switch(nPhase)
        {
            case PLG_PHASE_INCUBATION: return 3600;
            case PLG_PHASE_MILD:       return 7200;
            case PLG_PHASE_SEVERE:     return 14400;
        }
    }
    else if(nDiseaseId == PLG_DIS_BLOOD_ROT)
    {
        switch(nPhase)
        {
            case PLG_PHASE_INCUBATION: return 1800;
            case PLG_PHASE_MILD:       return 3600;
            case PLG_PHASE_SEVERE:     return 7200;
        }
    }
    else if(nDiseaseId == PLG_DIS_SWAMP_FEVER)
    {
        // Fastest-progressing disease — good for demo/testing
        switch(nPhase)
        {
            case PLG_PHASE_INCUBATION: return 900;
            case PLG_PHASE_MILD:       return 1800;
            case PLG_PHASE_SEVERE:     return 3600;
        }
    }
    else if(nDiseaseId == PLG_DIS_NECROTIC)
    {
        switch(nPhase)
        {
            case PLG_PHASE_INCUBATION: return 1800;
            case PLG_PHASE_MILD:       return 3600;
            case PLG_PHASE_SEVERE:     return 10800;
        }
    }
    else if(nDiseaseId == PLG_DIS_LYCANTHROPY)
    {
        switch(nPhase)
        {
            case PLG_PHASE_INCUBATION: return 7200;
            case PLG_PHASE_MILD:       return 14400;
            case PLG_PHASE_SEVERE:     return 28800;
        }
    }
    return 3600;
}

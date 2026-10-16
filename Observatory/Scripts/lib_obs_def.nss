#include "lib_nui"
#include "sql_obs"

// ----------------------------------------------------------------
// Window & bind IDs
// ----------------------------------------------------------------

const string OBS_WINDOW         = "OBS_WINDOW";
const string OBS_EV_SCRIPT      = "lib_obs_ev";

const string OBS_BIND_MAP_DL    = "obs_map_dl";      // DrawList for star map
const string OBS_BIND_CONS_NAME = "obs_cons_name";   // dominant constellation name
const string OBS_BIND_CONS_LORE = "obs_cons_lore";   // lore / flavor text
const string OBS_BIND_EFF_DESC  = "obs_eff_desc";    // reading effect description
const string OBS_BIND_BIRTH_LBL = "obs_birth_lbl";   // birth sign label
const string OBS_BIND_BIRTH_EFF = "obs_birth_eff";   // birth sign effect description
const string OBS_BIND_READ_ENA  = "obs_read_ena";    // read button enabled
const string OBS_BIND_READ_HINT = "obs_read_hint";   // read button hint / cooldown text
const string OBS_BIND_RESULT    = "obs_result";      // last reading result text
const string OBS_BIND_GEOM      = "obs_geom";
const string OBS_BIND_CNT_LBL   = "obs_cnt_lbl";     // "X odczytań" label

const string OBS_BTN_READ       = "obs_btn_read";
const string OBS_BTN_CLOSE      = "obs_btn_close";

// Local variables on PC
const string OBS_LVAR_RESULT    = "OBS_RESULT";

// Module local variable – prevents duplicate convergence announcements.
const string OBS_LVAR_CONV_SEEN = "OBS_CONV_SEEN";

// Effect tags (NWN:EE TagEffect support)
const string OBS_TAG_READING    = "OBS_READING";
const string OBS_TAG_BIRTH      = "OBS_BIRTH";

// Reading cooldown in real seconds (7200 = 2h ≈ 24 game hours at default rate).
const int OBS_READING_DURATION  = 7200;

// Lore skill DC for a successful reading.
const int OBS_READ_DC           = 12;

// Number of constellations.
const int OBS_NUM_CONSTELLATIONS = 12;

// Star map draw area dimensions.
const float OBS_MAP_W           = 240.0;
const float OBS_MAP_H           = 340.0;

// Window dimensions.
const float OBS_WIN_W           = 560.0;
const float OBS_WIN_H           = 430.0;

// ----------------------------------------------------------------
// Constellation data accessors
// Returns a JsonObject: {name, lore, eff_read, eff_birth}
// ----------------------------------------------------------------

string ObsGetConstellationName(int n)
{
    switch(n)
    {
        case  0: return "Wisielec";
        case  1: return "Krwawe Oko";
        case  2: return "Pożeracz";
        case  3: return "Czarny Kot";
        case  4: return "Żelazna Pięść";
        case  5: return "Cierniowa Korona";
        case  6: return "Złamany Miecz";
        case  7: return "Widmo";
        case  8: return "Lodowy Tron";
        case  9: return "Węzeł Ciemności";
        case 10: return "Płonące Wrzeciono";
        case 11: return "Kruk";
    }
    return "Nieznana";
}

string ObsGetConstellationLore(int n)
{
    switch(n)
    {
        case  0: return "Wisielec kołysze się na sznurze między światami. Ci, którzy odczytają jego przesłanie, zyskują precyzję kata — każde uderzenie pewniejsze, każda rana głębsza.";
        case  1: return "Krwawe Oko nigdy nie zasypia. Wpatrzone w niebiański sklepień, dostrzega to, co ukryte. Obserwatorzy uczą się widzieć w ciemności i kłamstwie.";
        case  2: return "Pożeracz żywi się słabością. Konstelacja, której groza zmusza ciało do oporu — serce bije mocniej, wola opiera się truciźnie i śmierci.";
        case  3: return "Czarny Kot przemierza noce bez śladu. Pod jego egidą nogi są lżejsze, a los zdaje się unikać pułapek... przynajmniej przez chwilę.";
        case  4: return "Żelazna Pięść kształtuje bohaterów i tyranów. Mięśnie nalewają się mocą, ciosy kruszą zbroje. Brutalność staje się narzędziem woli.";
        case  5: return "Cierniowa Korona zdobi czoło bólu. Jej kolce są zarazem ochroną — ci, którzy noszą cierpienie jak tarczę, stają się dla wrogów trudniejsi do dosięgnięcia.";
        case  6: return "Złamany Miecz to konstelacja upadku i przestrogi. Kto ją odczyta, pozna smak porażki — lecz ta wiedza hartuje umysł przeciwko ciemniejszym pokusom.";
        case  7: return "Widmo przemieszcza się między ścianami nocy. Pod tą gwiazdą cień staje się schronieniem, a kroki milkną jak westchnienie umierającego.";
        case  8: return "Lodowy Tron — siedziba bóstw zimy. Krew staje się chłodniejsza, ruchy powolniejsze lecz pewne. Mróz nie dosięga tych, którzy sami go przyjmą.";
        case  9: return "Węzeł Ciemności splata nieskończone drogi wiedzy. Pod jego wpływem umysł wchłania informacje szybciej, dłonie nabierają wprawy we wszystkim, czego dotkną.";
        case 10: return "Płonące Wrzeciono tka płomienne przeznaczenie. Charisma rozkwita, słowa palą się jak pochodnie, a ogień staje się sojusznikiem, nie wrogiem.";
        case 11: return "Kruk to posłaniec między żywymi a martwymi. Jego obecność na niebie odstrasza śmierć — ci, których on ochrania, regenerują rany powoli lecz nieustannie.";
    }
    return "Gwiazdy milczą.";
}

string ObsGetReadingEffectDesc(int n)
{
    switch(n)
    {
        case  0: return "Premia do ataku: +1";
        case  1: return "Spostrzegawczość i Przeszukiwanie: +3";
        case  2: return "Rzuty obronne na Wytrwałość: +2";
        case  3: return "Rzuty obronne na Refleks: +2";
        case  4: return "Siła: +1";
        case  5: return "Klasa Pancerza: +1 (ugięcie)";
        case  6: return "Rzuty obronne na Wolę: +2";
        case  7: return "Ukrywanie i Cichy Chód: +3";
        case  8: return "Odporność na Zimno 25%, Kondycja: +1";
        case  9: return "Wszystkie umiejętności: +2";
        case 10: return "Odporność na Ogień 10%, Charyzma: +1";
        case 11: return "Regeneracja (1 HP / 10 s)";
    }
    return "";
}

string ObsGetBirthEffectDesc(int n)
{
    switch(n)
    {
        case  0: return "Premia do ataku: +1";
        case  1: return "Spostrzegawczość i Przeszukiwanie: +2";
        case  2: return "Rzuty obronne na Wytrwałość: +1";
        case  3: return "Rzuty obronne na Refleks: +1";
        case  4: return "Siła: +1";
        case  5: return "Klasa Pancerza: +1";
        case  6: return "Rzuty obronne na Wolę: +1";
        case  7: return "Ukrywanie i Cichy Chód: +2";
        case  8: return "Odporność na Zimno: 10%";
        case  9: return "Wszystkie umiejętności: +1";
        case 10: return "Odporność na Ogień 5%, Charyzma: +1";
        case 11: return "Regeneracja (1 HP / 30 s)";
    }
    return "";
}

// Returns which constellation is currently dominant (0-11), based on game month.
int ObsGetDominantConstellation()
{
    return GetCalendarMonth() - 1;
}

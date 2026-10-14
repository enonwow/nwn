#include "lib_nui"
#include "sql_nit"

// Forward declarations
void NitOpenWindow(object oPC);
void FeedNitWindow(object oPC, int nToken, int nVal);
void NitApplyTierEffects(object oPC, int nTier);
void NitDrainThread(object oPC, int nAmount, string sSource);
void NitRestoreThread(object oPC, int nAmount);
int  NitGetTier(int nVal);
void NitOnClientEnter(object oPC);
void NitOnClientLeave(object oPC);
void NitHeartbeatTick(object oPC);
void NitTryCleanse(object oPC, int nToken);

// ----------------------------------------------------------------
// Window / bind / button IDs
// ----------------------------------------------------------------

const string NIT_WINDOW          = "NIT_WIN";
const string NIT_EV_SCRIPT       = "lib_nit_ev";
const string NIT_WIN_GEOM        = "nit_geom";

const string NIT_BIND_TIER_NAME  = "nit_tier_name";
const string NIT_BIND_VALUE      = "nit_value";
const string NIT_BIND_FLAVOR     = "nit_flavor";
const string NIT_BIND_EFFECTS    = "nit_effects";
const string NIT_BIND_PROGRESS   = "nit_progress";
const string NIT_BIND_COLOR      = "nit_color";
const string NIT_BIND_CLEANSE_ENA= "nit_cleanse_ena";
const string NIT_BIND_CLEANSE_TIP= "nit_cleanse_tip";

const string NIT_BTN_CLOSE       = "nit_btn_close";
const string NIT_BTN_CLEANSE     = "nit_btn_cleanse";

// ----------------------------------------------------------------
// Local variables on PC
// ----------------------------------------------------------------

const string NIT_LVAR_VALUE      = "NIT_VAL";
const string NIT_LVAR_HB_CTR     = "NIT_HB_CTR";
const string NIT_LVAR_RST_CTR    = "NIT_RST_CTR";

// ----------------------------------------------------------------
// Area variables (set in toolset per area)
// ----------------------------------------------------------------

// INT: drain points per drain-interval tick while PC is in this area
const string NIT_AVAR_DRAIN      = "NIT_AREA_DRAIN";
// INT: restore points per restore-interval tick (holy ground)
const string NIT_AVAR_RESTORE    = "NIT_AREA_RESTORE";

// ----------------------------------------------------------------
// Item tags
// ----------------------------------------------------------------

// Item with this exact tag: consumed to restore NIT_CLEANSE_RESTORE points
const string NIT_ITEM_CLEANSE    = "nit_cleanse";

// Effect tags for RemoveEffect loop
const string NIT_ETAG_SAVES      = "NIT_EFF_SAVES";
const string NIT_ETAG_AC         = "NIT_EFF_AC";
const string NIT_ETAG_STR        = "NIT_EFF_STR";
const string NIT_ETAG_TOUCH      = "NIT_EFF_TOUCH";

// ----------------------------------------------------------------
// Numeric constants
// ----------------------------------------------------------------

const int NIT_MAX                = 100;
// One drain-interval ≈ NIT_DRAIN_INTERVAL * 6s ≈ 60s
const int NIT_DRAIN_INTERVAL     = 10;
// One restore-interval ≈ NIT_RST_INTERVAL * 6s ≈ 12 min
const int NIT_RST_INTERVAL       = 120;
// Points restored by a single cleanse item
const int NIT_CLEANSE_RESTORE    = 15;
// Points restored by manual Cleanse button in a holy area
const int NIT_HOLY_CLEANSE_BONUS = 3;

// ----------------------------------------------------------------
// Tier boundaries (inclusive lower bounds)
// ----------------------------------------------------------------
// tier 5: 80-100  tier 4: 60-79  tier 3: 40-59
// tier 2: 20-39   tier 1:  1-19  tier 0: 0 (Death-Touched)

int NitGetTier(int nVal)
{
    if(nVal >= 80) return 5;
    if(nVal >= 60) return 4;
    if(nVal >= 40) return 3;
    if(nVal >= 20) return 2;
    if(nVal >= 1)  return 1;
    return 0;
}

string NitTierName(int nTier)
{
    switch(nTier)
    {
        case 5: return "Żywa Nić";
        case 4: return "Strzępek";
        case 3: return "Rozdarta";
        case 2: return "Postrzępiona";
        case 1: return "Rozwijająca się";
        case 0: return "Dotknięta Śmiercią";
    }
    return "—";
}

string NitTierFlavor(int nTier)
{
    switch(nTier)
    {
        case 5: return "Twoja dusza płonie pełnym blaskiem. Mrok nie zdołał wedrzeć się w jej tkankę. Żywa Nić wibruje ciepłem.";
        case 4: return "Czujesz ledwie wyczuwalny chłód — jakby ktoś delikatnie ciągnął za coś bardzo głęboko. Nić drżała, lecz jeszcze trzyma.";
        case 3: return "Zimno pełza od kości ku skórze. Sny są niespokojne, a w lustrach zamiast twarzy widzisz cień. Coś nadgryza twoją istotę.";
        case 2: return "Postrzępione resztki duszy trzepocą jak płomień na wietrze. Każdy cios wroga i każde ciemne zaklęcie dorzucają kolejne pęknięcia.";
        case 1: return "Nić jest prawie zerwana. Słyszysz głosy umarłych i rozumiesz ich słowa. Kapłan lub święty przedmiot to jedyna droga.";
        case 0: return "Puste miejsce tam, gdzie tlił się ogień. Jesteś Dotknięty Śmiercią — coś między żywym a umarłym. Pieczęć krwi pulsuje słabo…";
    }
    return "";
}

string NitTierEffects(int nTier)
{
    switch(nTier)
    {
        case 5: return "Brak kar";
        case 4: return "-1 do rzutów obronnych";
        case 3: return "-2 do rzutów obronnych  ·  -1 KP";
        case 2: return "-3 do rzutów obronnych  ·  -2 KP";
        case 1: return "-5 do rzutów obronnych  ·  -3 KP  ·  -2 Siły";
        case 0: return "-5 do rzutów  ·  -3 KP  ·  -2 Siły  ·  [Dotknięty Śmiercią]";
    }
    return "";
}

json NitTierColor(int nTier)
{
    switch(nTier)
    {
        case 5: return NuiColor(140, 210, 140);  // jasna zieleń
        case 4: return NuiColor(220, 220, 80);   // żółty
        case 3: return NuiColor(220, 150, 50);   // pomarańczowy
        case 2: return NuiColor(210, 70,  70);   // czerwony
        case 1: return NuiColor(160, 60,  200);  // fiolet
        case 0: return NuiColor(100, 100, 140);  // ciemny błękit
    }
    return NuiColor(128, 128, 128);
}

// ----------------------------------------------------------------
// Player notification text on tier change
// ----------------------------------------------------------------

string NitDropMessage(int nNewTier)
{
    switch(nNewTier)
    {
        case 4: return "[Nić] Twoja dusza zaczyna strzępić się. Czujesz zimno, którego nie sposób ogrzać.";
        case 3: return "[Nić] Nić jest rozdarta. Kary się nasilają. Szukaj kapłana.";
        case 2: return "[Nić] Twoja dusza ledwo trzyma się w całości. Bez oczyszczenia grozi ci przemiana.";
        case 1: return "[Nić] OSTRZEŻENIE: Nić na skraju zerwania! Natychmiast poszukaj kapłana lub świętego przedmiotu!";
        case 0: return "[Nić] Nić zerwana. Jesteś Dotknięty Śmiercią. Powrót jest możliwy, lecz kosztowny.";
    }
    return "";
}

string NitRiseMessage(int nNewTier)
{
    switch(nNewTier)
    {
        case 5: return "[Nić] Dusza odzyskała pełnię. Żywa Nić płonie jasno.";
        case 4: return "[Nić] Oczyszczenie przyniosło ulgę. Nić jest słabsza, lecz mniej rozdarta.";
        case 3: return "[Nić] Poczułeś ciepło powracającego życia. Nić jest częściowo przywrócona.";
        case 2: return "[Nić] Rysa jest mniejsza. Kontynuuj oczyszczanie.";
        case 1: return "[Nić] Nić drżała, lecz nie pękła. Rysy wciąż widoczne — bądź ostrożny.";
    }
    return "";
}

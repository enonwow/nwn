#include "lib_nui"
#include "sql_lycan"

// -----------------------------------------------------------------------
// NUI window / event
// -----------------------------------------------------------------------

const string LYCAN_WIN_STATUS   = "LYCAN_WIN_STATUS";
const string LYCAN_EV_SCRIPT    = "lib_lycan_ev";

// Bind names
const string LYCAN_BIND_WIN_GEOM    = "lycan_win_geom";
const string LYCAN_BIND_MOON_LABEL  = "lycan_moon_label";
const string LYCAN_BIND_MOON_BAR    = "lycan_moon_bar";
const string LYCAN_BIND_STAGE_LBL   = "lycan_stage_lbl";
const string LYCAN_BIND_STAGE_COLOR = "lycan_stage_color";
const string LYCAN_BIND_DAYS_LBL    = "lycan_days_lbl";
const string LYCAN_BIND_FORM_LBL    = "lycan_form_lbl";
const string LYCAN_BIND_FORM_COLOR  = "lycan_form_color";
const string LYCAN_BIND_DESC_TXT    = "lycan_desc_txt";
const string LYCAN_BIND_CURE_ENA    = "lycan_cure_ena";
const string LYCAN_BIND_CURE_LBL    = "lycan_cure_lbl";
const string LYCAN_BIND_XFORM_ENA   = "lycan_xform_ena";
const string LYCAN_BIND_XFORM_LBL   = "lycan_xform_lbl";

// Button IDs
const string LYCAN_BTN_CLOSE        = "lycan_btn_close";
const string LYCAN_BTN_CURE         = "lycan_btn_cure";
const string LYCAN_BTN_TRANSFORM    = "lycan_btn_transform";

// -----------------------------------------------------------------------
// Local variables on PC object
// -----------------------------------------------------------------------

const string LYCAN_LVAR_TRANSFORMED = "LYCAN_TRANSFORMED";  // 1 = in wolf form

// -----------------------------------------------------------------------
// Infection stages
// -----------------------------------------------------------------------

const int LYCAN_STAGE_NONE    = 0;  // not infected
const int LYCAN_STAGE_LATENT  = 1;  // 0-2 real days since bite
const int LYCAN_STAGE_ACTIVE  = 2;  // 3-6 real days — minor effects
const int LYCAN_STAGE_FULL    = 3;  // 7+ real days — full werewolf

// -----------------------------------------------------------------------
// Moon cycle (real-time seconds)
//
// Default tuning: 1 NWN calendar month ≈ 3 real hours → full 28-day
// moon cycle ≈ 2.1 real hours (7560 s).  Administrators can change
// LYCAN_MOON_CYCLE_S to suit their server's NWN-day length.
//
// Full moon occupies days 12-16 of the 28-day cycle.
// -----------------------------------------------------------------------

const int LYCAN_MOON_CYCLE_S      = 7560;   // real seconds per 28-day cycle
const int LYCAN_FULL_MOON_START   = 12;     // first full-moon day (0-indexed)
const int LYCAN_FULL_MOON_END     = 16;     // last full-moon day (inclusive)

// -----------------------------------------------------------------------
// Appearance / wolf form
//
// Row 285 of appearance.2da is the Dire Wolf. Change to any row that
// fits your hak (e.g. a custom werewolf appearance).
// -----------------------------------------------------------------------

const int LYCAN_WOLF_APPEARANCE   = 285;   // Dire Wolf appearance.2da row

// Effect tags — used to identify and remove lycanthropy effects cleanly.
const string LYCAN_EFF_ACTIVE     = "LYCAN_ACTIVE_EFF";
const string LYCAN_EFF_FULL       = "LYCAN_FULL_EFF";

// Cure kit — item with this tag is consumed when the PC attempts a cure.
const string LYCAN_CURE_KIT_TAG   = "lycan_cure_kit";

// Silver — weapon tags / names containing this substring deal bonus damage
// to a transformed lycanthrope.
const string LYCAN_SILVER_SUBSTR  = "silver";

// Window dimensions (pre-scale)
const float LYCAN_WIN_W  = 460.0;
const float LYCAN_WIN_H  = 390.0;

// -----------------------------------------------------------------------
// Moon helpers (only SQL dependency, safe to call from def layer)
// -----------------------------------------------------------------------

// Returns the current day within the 28-day moon cycle (0-27).
int LycanGetMoonDay()
{
    int nStart   = LycanGetMoonCycleStart();
    int nDayLen  = LYCAN_MOON_CYCLE_S / 28;
    if(nDayLen < 1) nDayLen = 1;

    sqlquery q = SqlPrepareQueryCampaign("lycanthropy",
        "SELECT CAST((strftime('%s','now') - @start) AS INTEGER)");
    SqlBindInt(q, "@start", nStart);
    if(!SqlStep(q)) return 0;

    int nElapsed = SqlGetInt(q, 0);
    if(nElapsed < 0) nElapsed = 0;
    return (nElapsed / nDayLen) % 28;
}

int LycanIsFullMoon()
{
    int nDay = LycanGetMoonDay();
    return (nDay >= LYCAN_FULL_MOON_START && nDay <= LYCAN_FULL_MOON_END);
}

// Returns 0-7 mapping from the 28-day cycle to a display phase.
int LycanGetMoonPhase()
{
    int nDay = LycanGetMoonDay();
    return (nDay * 8) / 28;
}

string LycanGetMoonPhaseName()
{
    switch(LycanGetMoonPhase())
    {
        case 0: return "Nów Księżyca";
        case 1: return "Sierp Wschodzący";
        case 2: return "Pierwsza Kwadra";
        case 3: return "Księżyc Wschodzący";
        case 4: return "Pełnia Księżyca";
        case 5: return "Księżyc Zachodzący";
        case 6: return "Ostatnia Kwadra";
        case 7: return "Sierp Zachodzący";
    }
    return "Nów Księżyca";
}

// Returns a simple ASCII progress bar showing the moon cycle position.
string LycanGetMoonBar()
{
    int nDay  = LycanGetMoonDay();
    int nFull = (nDay >= LYCAN_FULL_MOON_START && nDay <= LYCAN_FULL_MOON_END);

    // 14-character bar: each char = 2 days
    string sBar  = "[";
    int i;
    for(i = 0; i < 14; i++)
    {
        int nDayPos = i * 2;
        int bInFull = (nDayPos >= LYCAN_FULL_MOON_START && nDayPos <= LYCAN_FULL_MOON_END);
        if(i == nDay / 2)
            sBar = sBar + (nFull ? "*" : "o");
        else
            sBar = sBar + (bInFull ? "F" : ".");
    }
    sBar = sBar + "]";
    return sBar;
}

string LycanGetStageLabel(int nStage)
{
    switch(nStage)
    {
        case LYCAN_STAGE_NONE:   return "Bez Klątwy";
        case LYCAN_STAGE_LATENT: return "Infekcja Utajona";
        case LYCAN_STAGE_ACTIVE: return "Klątwa Aktywna";
        case LYCAN_STAGE_FULL:   return "Pełne Wilkołactwo";
    }
    return "Nieznany";
}

string LycanGetStageDesc(int nStage)
{
    switch(nStage)
    {
        case LYCAN_STAGE_NONE:
            return "Krew czysta. Nie nosisz piętna bestii.";
        case LYCAN_STAGE_LATENT:
            return "Ziarno klątwy kiełkuje w żyłach.\n"
                 + "Objawy jeszcze nie widoczne — lecz nadejdą.\n"
                 + "Działaj, póki czas.";
        case LYCAN_STAGE_ACTIVE:
            return "Krew wre. Siła rośnie, lecz umysł się mgli.\n"
                 + "W pełnię księżyca przemiana nastąpi wbrew woli.\n"
                 + "Srebro pali jak ogień.";
        case LYCAN_STAGE_FULL:
            return "Bestia jest częścią ciebie.\n"
                 + "W pełnię — zmienisz się, czy chcesz, czy nie.\n"
                 + "Zarażasz innych samą obecnością w formie wilka.\n"
                 + "Srebro jest twoją zmorą.";
    }
    return "";
}

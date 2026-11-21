// lib_wyrd_def.nss — Wyrd System constants, boon config, and forward declarations.
// Include from lib_wyrd.nss only; other scripts include lib_wyrd.nss.
#include "sql_wyrd"
#include "lib_nui"

// ============================================================
// NUI window and group IDs
// ============================================================
const string WYRD_WINDOW       = "WYRD_WINDOW";
const string WYRD_EV_SCRIPT    = "lib_wyrd_ev";
const string WYRD_WIN_GEOM     = "wyrd_win_geom";
const string WYRD_GRP_CONTENT  = "wyrd_grp_content";

// ============================================================
// NUI bind names
// ============================================================
const string WYRD_BIND_METER      = "wyrd_meter";       // float 0..1
const string WYRD_BIND_METER_LBL  = "wyrd_meter_lbl";   // "45 / 100"
const string WYRD_BIND_STATUS_LBL = "wyrd_status_lbl";
const string WYRD_BIND_STATUS_COL = "wyrd_status_col";

// Per-boon binds — append IntToString(boonId) to each prefix.
const string WYRD_BIND_BOON_BTN   = "wyrd_b_btn";       // button text "Kup"/"Aktywna"
const string WYRD_BIND_BOON_ENA   = "wyrd_b_ena";       // bool

// ============================================================
// Button IDs
// ============================================================
const string WYRD_BTN_CLOSE      = "wyrd_btn_close";
const string WYRD_BTN_BUY        = "wyrd_btn_buy";      // + IntToString(boonId)
const string WYRD_BTN_TAB_BOONS  = "wyrd_tab_boons";
const string WYRD_BTN_TAB_LEDGER = "wyrd_tab_ledger";

// ============================================================
// LVARs on PC
// ============================================================
const string WYRD_LVAR_WYRD       = "WYRD_VAL";
const string WYRD_LVAR_SPENT      = "WYRD_SPENT";
const string WYRD_LVAR_LAST_DECAY = "WYRD_LAST_DECAY";
const string WYRD_LVAR_VIEW       = "WYRD_VIEW";    // 0 = boons, 1 = ledger
const string WYRD_LVAR_BOON       = "WYRD_BOON_";   // + boonId = expiry game-sec

// ============================================================
// Boon IDs
// ============================================================
const int WYRD_BOON_SAVES       = 1;   // +2 all saves, 60min, 10 wyrd
const int WYRD_BOON_ATTACK      = 2;   // +1 attack bonus, 30min, 10 wyrd
const int WYRD_BOON_CONCEAL     = 3;   // +15% concealment, 60min, 25 wyrd
const int WYRD_BOON_SKILLS      = 4;   // +10 all skills, 30min, 25 wyrd
const int WYRD_BOON_SEEING      = 5;   // True Seeing, 10min, 50 wyrd
const int WYRD_BOON_CHEAT_DEATH = 6;   // survive 1 death at 1 HP, 24h, 50 wyrd
const int WYRD_BOON_COUNT       = 6;

// ============================================================
// Spirit / max constants
// ============================================================
const int WYRD_SPIRIT_THRESHOLD = 75;
const int WYRD_MAX              = 100;
const int WYRD_DECAY_INTERVAL   = 60;   // game-seconds between -1 wyrd decay ticks

// ============================================================
// Layout
// ============================================================
const float WYRD_W = 580.0;
const float WYRD_H = 480.0;

// ============================================================
// Boon config accessors (static lookup tables)
// ============================================================

string WyrdBoonName(int nId)
{
    switch(nId)
    {
        case WYRD_BOON_SAVES:       return "Szept Losu";
        case WYRD_BOON_ATTACK:      return "Laska Ślepych Bogów";
        case WYRD_BOON_CONCEAL:     return "Cien Zapomnienia";
        case WYRD_BOON_SKILLS:      return "Klucz Przypadku";
        case WYRD_BOON_SEEING:      return "Oko Opatrznosci";
        case WYRD_BOON_CHEAT_DEATH: return "Ocalenie";
    }
    return "?";
}

int WyrdBoonCost(int nId)
{
    switch(nId)
    {
        case WYRD_BOON_SAVES:       return 10;
        case WYRD_BOON_ATTACK:      return 10;
        case WYRD_BOON_CONCEAL:     return 25;
        case WYRD_BOON_SKILLS:      return 25;
        case WYRD_BOON_SEEING:      return 50;
        case WYRD_BOON_CHEAT_DEATH: return 50;
    }
    return 9999;
}

// Duration in minutes (for display and for expiry tracking)
int WyrdBoonDurMin(int nId)
{
    switch(nId)
    {
        case WYRD_BOON_SAVES:       return 60;
        case WYRD_BOON_ATTACK:      return 30;
        case WYRD_BOON_CONCEAL:     return 60;
        case WYRD_BOON_SKILLS:      return 30;
        case WYRD_BOON_SEEING:      return 10;
        case WYRD_BOON_CHEAT_DEATH: return 1440;
    }
    return 0;
}

// Effect duration for ApplyEffectToObject (real seconds; 60s per game-minute at 1:1)
float WyrdBoonDurSec(int nId)
{
    return IntToFloat(WyrdBoonDurMin(nId)) * 60.0;
}

string WyrdBoonDesc(int nId)
{
    switch(nId)
    {
        case WYRD_BOON_SAVES:
            return "+2 do rzutow obronnych (60min) — Szept przeznaczenia osłania cię.";
        case WYRD_BOON_ATTACK:
            return "+1 do rzutow na trafienie (30min) — Slepacy bogowie prowadza twoja rec.";
        case WYRD_BOON_CONCEAL:
            return "+15% ukrycia (60min) — Cien zapomnienia owija sie wokol ciebie.";
        case WYRD_BOON_SKILLS:
            return "+10 do wszystkich umiejetnosci (30min) — Los otwiera zamknięte drzwi.";
        case WYRD_BOON_SEEING:
            return "Prawdziwe Widzenie (10min) — Przeznaczenie odsłania ukryte.";
        case WYRD_BOON_CHEAT_DEATH:
            return "Przezyjesz jedno smiertelne trafienie z 1 HP (24h) — Przeznaczenie odsuwa śmierc.";
    }
    return "";
}

string WyrdBoonDurLabel(int nId)
{
    int nMin = WyrdBoonDurMin(nId);
    if(nMin >= 1440) return "24h";
    if(nMin >= 60)   return IntToString(nMin / 60) + "h";
    return IntToString(nMin) + "min";
}

// ============================================================
// Game-time seconds counter (approximate, for decay/expiry)
// ============================================================

int WyrdGameSec()
{
    // Month * ~30 days to keep it large but avoid overflow for long-running servers.
    return GetCalendarMonth() * 2592000
         + GetCalendarDay()   * 86400
         + GetTimeHour()      * 3600
         + GetTimeMinute()    * 60
         + GetTimeSecond();
}

// ============================================================
// Forward declarations (defined in lib_wyrd.nss)
// ============================================================
void WyrdOpenWindow(object oPC);
void WyrdFeedWindow(object oPC, int nToken);
void WyrdGrant(object oPC, int nAmount, string sReason);
void WyrdSwapView(object oPC, int nToken, int nView);

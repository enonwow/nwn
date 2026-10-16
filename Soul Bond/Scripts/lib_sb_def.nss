#include "lib_nui"
#include "sql_sb"

// ----------------------------------------------------------------
// Window / event IDs
// ----------------------------------------------------------------

const string SB_WINDOW       = "SB_WINDOW";
const string SB_EV_SCRIPT    = "lib_sb_ev";
const string SB_GRP_DETAIL   = "SB_GRP_DETAIL";
const string SB_WIN_GEOM     = "sb_win_geom";
const string SB_WIN_CONFIRM  = "SB_WIN_CONFIRM";

// ----------------------------------------------------------------
// Bind IDs
// ----------------------------------------------------------------

const string SB_BIND_WPNAME     = "sb_wpname";
const string SB_BIND_BONDNAME   = "sb_bondname";
const string SB_BIND_RANK_LBL   = "sb_rank_lbl";
const string SB_BIND_KILLS_LBL  = "sb_kills_lbl";
const string SB_BIND_PROGRESS   = "sb_progress";
const string SB_BIND_NEXT_LBL   = "sb_next_lbl";
const string SB_BIND_BONUS_TXT  = "sb_bonus_txt";
const string SB_BIND_NEXT_BONUS = "sb_next_bonus";
const string SB_BIND_BONDER_LBL = "sb_bonder_lbl";
const string SB_BIND_BREAK_ENA  = "sb_break_ena";
const string SB_BIND_STATUS_LBL = "sb_status_lbl";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string SB_BTN_CLOSE       = "sb_btn_close";
const string SB_BTN_INSPECT     = "sb_btn_inspect";
const string SB_BTN_BREAK       = "sb_btn_break";
const string SB_BTN_CONF_YES    = "sb_btn_conf_yes";
const string SB_BTN_CONF_NO     = "sb_btn_conf_no";

// ----------------------------------------------------------------
// LVARs on PC
// ----------------------------------------------------------------

const string SB_LVAR_INSPECTED  = "SB_INSPECTED_UUID";

// ----------------------------------------------------------------
// Mechanics
// ----------------------------------------------------------------

const string SB_TAG             = "SB_RES";
const int    SB_MAX_RANK        = 5;
const int    SB_KILLS_RANK_1    = 10;
const int    SB_KILLS_RANK_2    = 50;
const int    SB_KILLS_RANK_3    = 200;
const int    SB_KILLS_RANK_4    = 500;
const int    SB_KILLS_RANK_5    = 1000;
const int    SB_BREAK_COST      = 500;

const float  SB_W               = 520.0;
const float  SB_H               = 420.0;

// ----------------------------------------------------------------
// Rank helpers
// ----------------------------------------------------------------

string SbRankLabel(int nRank)
{
    if(nRank == 1) return "Przebudzona";
    if(nRank == 2) return "Skuta Krwią";
    if(nRank == 3) return "Spragniona";
    if(nRank == 4) return "Wściekła";
    if(nRank == 5) return "Wykuta z Duszy";
    return "Uśpiona";
}

int SbRankThreshold(int nRank)
{
    if(nRank <= 0) return 0;
    if(nRank == 1) return SB_KILLS_RANK_1;
    if(nRank == 2) return SB_KILLS_RANK_2;
    if(nRank == 3) return SB_KILLS_RANK_3;
    if(nRank == 4) return SB_KILLS_RANK_4;
    return SB_KILLS_RANK_5;
}

// Picks an epithet by rank and a small index derived from kills count
string SbPickEpithet(int nRank, int nKills)
{
    int nIdx = nKills % 5;
    if(nRank == 1)
    {
        if(nIdx == 0) return "Wdowica";
        if(nIdx == 1) return "Bladaczka";
        if(nIdx == 2) return "Cicha";
        if(nIdx == 3) return "Gorzka";
        return "Łaknąca";
    }
    if(nRank == 2)
    {
        if(nIdx == 0) return "Krwiopijca";
        if(nIdx == 1) return "Bólodrca";
        if(nIdx == 2) return "Szkieletnica";
        if(nIdx == 3) return "Mroczna";
        return "Gorączkowa";
    }
    if(nRank == 3)
    {
        if(nIdx == 0) return "Duszogryz";
        if(nIdx == 1) return "Pożeraczka";
        if(nIdx == 2) return "Nienasycona";
        if(nIdx == 3) return "Wyjąca";
        return "Bezlitosna";
    }
    if(nRank == 4)
    {
        if(nIdx == 0) return "Rozszarpywaczka";
        if(nIdx == 1) return "Siewca Grozy";
        if(nIdx == 2) return "Mrozodajna";
        if(nIdx == 3) return "Zatruta";
        return "Wściekła";
    }
    // rank 5
    if(nIdx == 0) return "Wieczna Żniwiarka";
    if(nIdx == 1) return "Karmicielka Cienia";
    if(nIdx == 2) return "Strażniczka Popiołów";
    if(nIdx == 3) return "Trójca Zguby";
    return "Wykuta z Duszy";
}

string SbBonusDescription(int nRank)
{
    if(nRank <= 0) return "Ostrze nie zaznało krwi — żadnych premii.";
    if(nRank == 1) return "Wzmocnienie +1.";
    if(nRank == 2) return "Wzmocnienie +1\nObrażenia zimnem +1k4.";
    if(nRank == 3) return "Wzmocnienie +2\nObrażenia zimnem +1k4.";
    if(nRank == 4) return "Wzmocnienie +2\nObrażenia zimnem +1k6\nZastraszanie +2.";
    return "Wzmocnienie +3\nObrażenia zimnem +1k6\nZastraszanie +4\nRegeneracja +1.";
}

string SbNextBonusDescription(int nCurrentRank)
{
    if(nCurrentRank >= SB_MAX_RANK)
        return "Ostrze osiągnęło pełnię mrocznej chwały.";
    return SbBonusDescription(nCurrentRank + 1);
}

float SbCalcProgress(int nKills, int nRank)
{
    if(nRank >= SB_MAX_RANK) return 1.0;
    int nPrev = SbRankThreshold(nRank);
    int nNext = SbRankThreshold(nRank + 1);
    if(nNext <= nPrev) return 1.0;
    float fP = IntToFloat(nKills - nPrev) / IntToFloat(nNext - nPrev);
    if(fP < 0.0) return 0.0;
    if(fP > 1.0) return 1.0;
    return fP;
}

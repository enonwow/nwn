#include "lib_nui"

void SetsApplyEffects(object oPC, int nSetId, int nCount);
void SetsRemoveEffects(object oPC, int nSetId);
void SetsUpdateAll(object oPC);

// ----------------------------------------------------------------
// NUI identifiers
// ----------------------------------------------------------------

const string SETS_WINDOW    = "SETS_WINDOW";
const string SETS_EV_SCRIPT = "lib_sets_ev";
const string SETS_WIN_GEOM  = "sets_win_geom";

// Array binds for the set roster NuiList
const string SETS_BIND_NAME  = "sets_name";
const string SETS_BIND_COUNT = "sets_count";
const string SETS_BIND_ENC   = "sets_enc";
const string SETS_BIND_COLOR = "sets_color";

// Detail pane binds
const string SETS_BIND_DET_TITLE = "sets_det_title";
const string SETS_BIND_DET_BONUS = "sets_det_bonus";
const string SETS_BIND_ITEM_NAME = "sets_iname";
const string SETS_BIND_ITEM_COL  = "sets_icol";
const string SETS_BIND_ITEM_SYM  = "sets_isym";
const string SETS_BIND_ITEM_CNT  = "sets_item_cnt";

// Buttons
const string SETS_BTN_CLOSE = "sets_btn_close";
const string SETS_BTN_ROW   = "sets_btn_row";

// Effect tag prefix – one unique tag per set keeps removal clean
const string SETS_FX_PREFIX = "SETS_FX_";

// Layout
const float SETS_W = 460.0;
const float SETS_H = 580.0;

// Number of defined sets (keep in sync with the data below)
const int SETS_TOTAL = 5;

// Set IDs
const int SETS_ID_DARK_KNIGHT   = 0;
const int SETS_ID_DEAD_MAGE     = 1;
const int SETS_ID_CORSAIR       = 2;
const int SETS_ID_DAMNED_RINGS  = 3;
const int SETS_ID_DEATH_MADNESS = 4;

// PC-local variable: currently selected set index in the NUI (-1 = none)
const string SETS_LVAR_SEL = "SETS_SEL";

// ----------------------------------------------------------------
// Set data – names
// ----------------------------------------------------------------

string SetsGetName(int nId)
{
    if(nId == SETS_ID_DARK_KNIGHT)   return "Zbroja Mrocznego Rycerza";
    if(nId == SETS_ID_DEAD_MAGE)     return "Szaty Martwego Maga";
    if(nId == SETS_ID_CORSAIR)       return "Rząd Korsarza";
    if(nId == SETS_ID_DAMNED_RINGS)  return "Pierścienie Przeklętych";
    if(nId == SETS_ID_DEATH_MADNESS) return "Śmiertelny Obłęd";
    return "";
}

// ----------------------------------------------------------------
// Set data – item counts
// ----------------------------------------------------------------

int SetsGetItemCount(int nId)
{
    if(nId == SETS_ID_DARK_KNIGHT)   return 3;
    if(nId == SETS_ID_DEAD_MAGE)     return 3;
    if(nId == SETS_ID_CORSAIR)       return 4;
    if(nId == SETS_ID_DAMNED_RINGS)  return 2;
    if(nId == SETS_ID_DEATH_MADNESS) return 4;
    return 0;
}

// ----------------------------------------------------------------
// Set data – item tags (pipe-separated)
// Items must have these exact tags in the toolset.
// ----------------------------------------------------------------

string SetsGetItemTags(int nId)
{
    if(nId == SETS_ID_DARK_KNIGHT)   return "set_dk_helm|set_dk_chest|set_dk_gaunt";
    if(nId == SETS_ID_DEAD_MAGE)     return "set_dm_robe|set_dm_ring|set_dm_staff";
    if(nId == SETS_ID_CORSAIR)       return "set_co_coat|set_co_gloves|set_co_boots|set_co_blade";
    if(nId == SETS_ID_DAMNED_RINGS)  return "set_pr_ring1|set_pr_ring2";
    if(nId == SETS_ID_DEATH_MADNESS) return "set_so_mask|set_so_robe|set_so_bracer|set_so_blade";
    return "";
}

// ----------------------------------------------------------------
// Set data – item display names (pipe-separated, same order)
// ----------------------------------------------------------------

string SetsGetItemNames(int nId)
{
    if(nId == SETS_ID_DARK_KNIGHT)
        return "Hełm Mroku|Napierśnik Cienia|Rękawice Kata";
    if(nId == SETS_ID_DEAD_MAGE)
        return "Szata Kości|Obrączka Mumii|Kostur Liszy";
    if(nId == SETS_ID_CORSAIR)
        return "Płaszcz Krwi|Rękawice Czarnej Dłoni|Buty Przemytnika|Szabla Korsarza";
    if(nId == SETS_ID_DAMNED_RINGS)
        return "Pierścień Pożogi|Pierścień Mrozu";
    if(nId == SETS_ID_DEATH_MADNESS)
        return "Maska Obłędu|Szata Bólu|Naramiennik Skazańca|Ostrze Szaleńca";
    return "";
}

// ----------------------------------------------------------------
// Set data – bonus tiers
// nTier is 0-indexed; returns "" when the tier doesn't exist.
// ----------------------------------------------------------------

string SetsGetBonusAtTier(int nId, int nTier)
{
    if(nId == SETS_ID_DARK_KNIGHT)
    {
        if(nTier == 0) return "(2): +2 do trafień";
        if(nTier == 1) return "(3): Immunitet na strach";
    }
    if(nId == SETS_ID_DEAD_MAGE)
    {
        if(nTier == 0) return "(2): Inteligencja +2";
        if(nTier == 1) return "(3): Charyzma +2";
    }
    if(nId == SETS_ID_CORSAIR)
    {
        if(nTier == 0) return "(2): Zręczność +2";
        if(nTier == 1) return "(3): Skradanie +4, Cichobieg +4";
        if(nTier == 2) return "(4): Zręczność +2, +2 do trafień";
    }
    if(nId == SETS_ID_DAMNED_RINGS)
    {
        if(nTier == 0) return "(2): Wola +4, wrażliwość na boskość 25%";
    }
    if(nId == SETS_ID_DEATH_MADNESS)
    {
        if(nTier == 0) return "(2): Redukcja obrażeń 5/+1";
        if(nTier == 1) return "(3): Regeneracja 1 co 6 sek.";
        if(nTier == 2) return "(4): Kondycja +2";
    }
    return "";
}

int SetsGetBonusTierThreshold(int nId, int nTier)
{
    if(nId == SETS_ID_DARK_KNIGHT)
    {
        if(nTier == 0) return 2;
        if(nTier == 1) return 3;
    }
    if(nId == SETS_ID_DEAD_MAGE)
    {
        if(nTier == 0) return 2;
        if(nTier == 1) return 3;
    }
    if(nId == SETS_ID_CORSAIR)
    {
        if(nTier == 0) return 2;
        if(nTier == 1) return 3;
        if(nTier == 2) return 4;
    }
    if(nId == SETS_ID_DAMNED_RINGS)
    {
        if(nTier == 0) return 2;
    }
    if(nId == SETS_ID_DEATH_MADNESS)
    {
        if(nTier == 0) return 2;
        if(nTier == 1) return 3;
        if(nTier == 2) return 4;
    }
    return 0;
}

// Returns a multi-line string of all active bonus descriptions for nCount equipped pieces.
string SetsGetActiveBonusDesc(int nId, int nCount)
{
    if(nCount < 2) return "Brak aktywnych premii.";
    string sResult = "";
    int i;
    for(i = 0; i < 3; i++)
    {
        string sTier = SetsGetBonusAtTier(nId, i);
        if(sTier == "") break;
        int nThresh = SetsGetBonusTierThreshold(nId, i);
        if(nThresh > 0 && nCount >= nThresh)
        {
            if(sResult != "") sResult = sResult + "\n";
            sResult = sResult + sTier;
        }
    }
    if(sResult == "") return "Brak aktywnych premii.";
    return sResult;
}

// ----------------------------------------------------------------
// String utility – returns nIdx-th pipe-delimited token (0-indexed)
// ----------------------------------------------------------------

string SetsGetToken(string s, int nIdx)
{
    int nCur = 0;
    int nLen = GetStringLength(s);
    string sCur = "";
    int i;
    for(i = 0; i < nLen; i++)
    {
        string c = GetSubString(s, i, 1);
        if(c == "|")
        {
            if(nCur == nIdx) return sCur;
            nCur++;
            sCur = "";
        }
        else
            sCur = sCur + c;
    }
    if(nCur == nIdx) return sCur;
    return "";
}

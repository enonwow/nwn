#include "lib_nui"
#include "sql_crs"

void CrsOpenWindow(object oPC);
void CrsFeedList(object oPC, int nToken);
void CrsApplyEffects(object oPC, int nCurseId, int nStage);
void CrsRemoveEffects(object oPC, int nCurseId);
void CrsApplyAllEffects(object oPC);
void CrsRemoveAllEffects(object oPC);
void CrsInflict(object oPC, int nCurseId);
void CrsCleanse(object oPC, int nCurseId);
void CrsStartTicking(object oPC);
void CrsTick(object oPC);

// ----------------------------------------------------------------
// Window identity
// ----------------------------------------------------------------

const string CRS_WINDOW     = "CRS_WINDOW";
const string CRS_EV_SCRIPT  = "lib_crs_ev";
const string CRS_WIN_GEOM   = "crs_win_geom";

const float CRS_W           = 600.0;
const float CRS_H           = 500.0;

// ----------------------------------------------------------------
// Bind names (parallel arrays for NuiList)
// ----------------------------------------------------------------

const string CRS_BIND_ROWCOUNT  = "crs_row_cnt";
const string CRS_BIND_NAME      = "crs_row_name";
const string CRS_BIND_STAGE_DOT = "crs_row_dot";
const string CRS_BIND_DESC      = "crs_row_desc";
const string CRS_BIND_COLOR     = "crs_row_color";
const string CRS_BIND_BTN_ENA   = "crs_row_btn_ena";
const string CRS_BIND_BTN_LBL   = "crs_row_btn_lbl";
const string CRS_BIND_INFO      = "crs_info_lbl";
const string CRS_BIND_EMPTY_VIS = "crs_empty_vis";

// ----------------------------------------------------------------
// Buttons
// ----------------------------------------------------------------

const string CRS_BTN_CLOSE   = "crs_btn_close";
const string CRS_BTN_CLEANSE = "crs_btn_clns";   // + IntToString(row index)

// ----------------------------------------------------------------
// Local variables on PC
// ----------------------------------------------------------------

const string CRS_LVAR_TICKING    = "CRS_TICKING";
const string CRS_LVAR_CURSE_ROW  = "CRS_CURSE_ROW";  // json array: curse_id per visible row

// ----------------------------------------------------------------
// Items / consumables
// ----------------------------------------------------------------

// Tag of the item required for cleansing; must exist in the HAK or module palette.
const string CRS_ITEM_HOLY_OIL   = "crs_hol_oil";

// ----------------------------------------------------------------
// Progression timing
// ----------------------------------------------------------------

// Every CRS_TICK_INTERVAL real seconds the tick function fires.
const float CRS_TICK_INTERVAL    = 60.0;

// After CRS_TICKS_PER_STAGE ticks a curse advances one stage (max 3).
const int   CRS_TICKS_PER_STAGE  = 10;

// ----------------------------------------------------------------
// Curse IDs
// ----------------------------------------------------------------

const int CRS_CURSE_ROTTING_HAND   = 1;
const int CRS_CURSE_PLAGUE_BRAND   = 2;
const int CRS_CURSE_SHADOW_DESPAIR = 3;
const int CRS_CURSE_TREMBLING      = 4;
const int CRS_CURSE_SOUL_FROST     = 5;
const int CRS_CURSE_BLOOD_SEAL     = 6;

// ----------------------------------------------------------------
// Effect tag prefix (used with TagEffect for identification)
// ----------------------------------------------------------------

const string CRS_EFF_TAG_PREFIX = "CRS_EFF_";

// ----------------------------------------------------------------
// Curse name lookup
// ----------------------------------------------------------------

string CrsGetName(int nCurseId)
{
    switch(nCurseId)
    {
        case CRS_CURSE_ROTTING_HAND:    return "Gnijąca Dłoń";
        case CRS_CURSE_PLAGUE_BRAND:    return "Piętno Zarazy";
        case CRS_CURSE_SHADOW_DESPAIR:  return "Cień Rozpaczy";
        case CRS_CURSE_TREMBLING:       return "Klątwa Drżenia";
        case CRS_CURSE_SOUL_FROST:      return "Mróz Duszy";
        case CRS_CURSE_BLOOD_SEAL:      return "Pieczęć Krwi";
    }
    return "Nieznana klątwa";
}

// ----------------------------------------------------------------
// Stage description lookup  (flavor text, Polish)
// ----------------------------------------------------------------

string CrsGetDesc(int nCurseId, int nStage)
{
    switch(nCurseId)
    {
        case CRS_CURSE_ROTTING_HAND:
            switch(nStage)
            {
                case 1: return "Dłoń powoli więdnie. Ból przeszywa kości przy każdym zamachu.";
                case 2: return "Palce czernieją. Chwyt słabnie, a oręż wypada z rąk bez ostrzeżenia.";
                case 3: return "Ręka to zbutwiały kikut. Dotknięcie śmierci sączy się ku ramienion.";
            }
            break;
        case CRS_CURSE_PLAGUE_BRAND:
            switch(nStage)
            {
                case 1: return "Czarne znamię na skórze pulsuje ciepłem. Ciało traci siły.";
                case 2: return "Znamię rozszerza się. Wnętrzności gnią od środka. Każdy oddech kosztuje.";
                case 3: return "Skóra odpada płatami. Śmierć zbliża się powoli, nieubłaganie.";
            }
            break;
        case CRS_CURSE_SHADOW_DESPAIR:
            switch(nStage)
            {
                case 1: return "Czarny cień przylgnął do duszy. Słowa stają się puste i pozbawione sensu.";
                case 2: return "Dusza kruszy się pod ciężarem rozpaczy. Inni wyczuwają obcość i stronią.";
                case 3: return "Pustka wewnątrz jest nieodwracalna. Bogowie nie słyszą już modlitw.";
            }
            break;
        case CRS_CURSE_TREMBLING:
            switch(nStage)
            {
                case 1: return "Ręce drżą bez ustanku. Cel wydaje się daleki, a strzały chybią.";
                case 2: return "Całe ciało trzęsie się konwulsyjnie. Każdy krok to walka z własnymi nogami.";
                case 3: return "Kości szczękają. Ciało odmawia posłuszeństwa. Ucieczka staje się niemożliwa.";
            }
            break;
        case CRS_CURSE_SOUL_FROST:
            switch(nStage)
            {
                case 1: return "Zimno skuło duszę. Myśli są jak lód, zaklęcia wymykają się z umysłu.";
                case 2: return "Lód wkrada się do żył. Pamięć blednie. Słowa zaklęć znikają przed wymówieniem.";
                case 3: return "Dusza zamarznięta. Magia odpycha czarodzieja jak ciało odtrąca metal.";
            }
            break;
        case CRS_CURSE_BLOOD_SEAL:
            switch(nStage)
            {
                case 1: return "Krwawa pieczęć na piersi pulsuje słabo. Krew spływa bez widocznej rany.";
                case 2: return "Pieczęć rozszerza się. Siły witalne opadają z każdym biciem serca.";
                case 3: return "Pieczęć pochłania życie. Ciało umiera za życia, krok po kroku.";
            }
            break;
    }
    return "";
}

// ----------------------------------------------------------------
// Gold cost to cleanse (per stage)
// ----------------------------------------------------------------

int CrsGetCleanseCost(int nCurseId, int nStage)
{
    // Base cost scales with stage; some curses cost more
    int nBase;
    switch(nCurseId)
    {
        case CRS_CURSE_BLOOD_SEAL:  nBase = 300; break;
        case CRS_CURSE_PLAGUE_BRAND: nBase = 250; break;
        default:                     nBase = 150; break;
    }
    return nBase * nStage;
}

// ----------------------------------------------------------------
// HP drain per tick (0 = none)
// ----------------------------------------------------------------

int CrsGetDrainPerTick(int nCurseId, int nStage)
{
    switch(nCurseId)
    {
        case CRS_CURSE_PLAGUE_BRAND:
            switch(nStage) { case 1: return 3; case 2: return 7; case 3: return 14; }
            break;
        case CRS_CURSE_BLOOD_SEAL:
            switch(nStage) { case 1: return 2; case 2: return 6; case 3: return 12; }
            break;
    }
    return 0;
}

#include "lib_nui"
#include "sql_mit"

void MitShowWindow(object oPC);
void MitFeedPoisons(object oPC, int nToken);
void MitFeedDetail(object oPC, int nToken, int nPoisonId);
void MitTakeDose(object oPC, int nToken, int nPoisonId);
void MitCraftAntidote(object oPC, int nToken, int nPoisonId);
void MitApplyTolerance(object oPC);

// ----------------------------------------------------------------
// Window / bind constants
// ----------------------------------------------------------------

const string MIT_WINDOW           = "MIT_WINDOW";
const string MIT_EV_SCRIPT        = "lib_mit_ev";
const string MIT_WIN_GEOM         = "mit_win_geom";

// List binds (arrays, length MIT_POISON_COUNT)
const string MIT_BIND_ROW_NAME    = "mit_row_name";
const string MIT_BIND_ROW_LEVEL   = "mit_row_level";
const string MIT_BIND_ROW_ENC     = "mit_row_enc";
const string MIT_BIND_ROW_COLOR   = "mit_row_color";

// Detail panel binds
const string MIT_BIND_DET_NAME    = "mit_det_name";
const string MIT_BIND_DET_DESC    = "mit_det_desc";
const string MIT_BIND_DET_DC      = "mit_det_dc";
const string MIT_BIND_DET_DOSES   = "mit_det_doses";
const string MIT_BIND_DET_OD      = "mit_det_od";
const string MIT_BIND_DET_LVLBUF  = "mit_det_lvlbuf";
const string MIT_BIND_DET_NEXT    = "mit_det_next";
const string MIT_BIND_DET_CD      = "mit_det_cd";
const string MIT_BIND_DOSE_ENA    = "mit_dose_ena";
const string MIT_BIND_DOSE_LBL    = "mit_dose_lbl";
const string MIT_BIND_ANTI_ENA    = "mit_anti_ena";

// Buttons
const string MIT_BTN_CLOSE        = "mit_btn_close";
const string MIT_BTN_DOSE         = "mit_btn_dose";
const string MIT_BTN_ANTIDOTE     = "mit_btn_antidote";
const string MIT_BTN_ROW          = "mit_btn_row";

// Local variable on PC: selected poison id
const string MIT_LVAR_SEL         = "MIT_SEL_POISON";

// Poison count
const int    MIT_POISON_COUNT     = 10;
// Tolerance levels: 0 (none) → 4 (full immunity)
const int    MIT_MAX_LEVEL        = 4;
// Gold cost per dose (apothecary provides controlled doses)
const int    MIT_DOSE_COST        = 50;
// Gold cost for crafting one antidote (components abstracted)
const int    MIT_ANTIDOTE_COST    = 200;
// Cooldown between doses in seconds (1 real hour)
const int    MIT_DOSE_COOLDOWN    = 3600;

// Window dimensions
const float  MIT_W                = 740.0;
const float  MIT_H                = 490.0;

// ----------------------------------------------------------------
// Poison data accessors — static game data, not in SQL
// ----------------------------------------------------------------

string MitGetPoisonName(int nId)
{
    switch(nId)
    {
        case 0: return "Arsenowy proch";
        case 1: return "Cykuta";
        case 2: return "Wilcza jagoda";
        case 3: return "Jad kobry";
        case 4: return "Mandragora";
        case 5: return "Kwiat śmierci";
        case 6: return "Jad wiwerna";
        case 7: return "Ropuszyn";
        case 8: return "Żelazobójca";
        case 9: return "Zarodnik nicości";
    }
    return "Nieznana trucizna";
}

string MitGetPoisonDesc(int nId)
{
    switch(nId)
    {
        case 0: return "Metaliczny proszek, bezbarwny i bezwonny. Niszczy wnętrzności powoli i pewnie. Faworyt trucicieli z dobrymi manierami.";
        case 1: return "Wyciąg z cykuty zabójczej. Zna go każdy apotekarz i każdy zabójca. Skurcze zaczynają się po godzinie, śmierć — po trzech.";
        case 2: return "Słodkie jagody, które smakują jak śmierć. Sny, jakie dają, nie kończą się nigdy. Oczy ofiary pozostają otwarte.";
        case 3: return "Cienka igła kobrowego kła zostawia dawkę, która zatrzymuje serce w ciągu godziny. W Południowym Imperium — broń arystokracji.";
        case 4: return "Korzeń wykopany tylko w bezksiężycową noc. Ból jest częścią rytuału, mówią wiedźmy. Odurzenie trwa trzy doby.";
        case 5: return "Czarny nektar z rośliny kwitnącej raz na siedem lat. Każda kropla kosztuje życie. Zbieracze kwiatu nie wracają.";
        case 6: return "Żółta ciecz zbierana z ogona wiwerna. Wypalona skóra już nie rośnie z powrotem. Rycerze owijają grotki w watę przesiąkniętą tym jadem.";
        case 7: return "Ropuch śmierdzących nie brakuje na bagnach. Ich wydzielina paraliżuje i niszczy mięśnie. Śmierć przez uduszenie jest wyjątkowo powolna.";
        case 8: return "Alchemiczna synteza rozkładająca żelazo i kości z jednakową skutecznością. Wytrawia zbroje od środka, ciało — od zewnątrz.";
        case 9: return "Zarodniki z Pustki, tam gdzie bogowie nie patrzą. Rozżerają umysł od środka. Ostatnie słowa ofiar to zwykle imiona, których nikt nie zna.";
    }
    return "";
}

int MitGetPoisonDC(int nId)
{
    switch(nId)
    {
        case 0: return 14;
        case 1: return 15;
        case 2: return 16;
        case 3: return 17;
        case 4: return 14;
        case 5: return 18;
        case 6: return 20;
        case 7: return 13;
        case 8: return 16;
        case 9: return 22;
    }
    return 15;
}

// Cumulative successful doses required to reach each tolerance level.
int MitDosesForLevel(int nLevel)
{
    switch(nLevel)
    {
        case 1: return 3;
        case 2: return 8;
        case 3: return 15;
        case 4: return 24;
    }
    return 9999;
}

int MitGetSaveBonus(int nLevel)
{
    switch(nLevel)
    {
        case 1: return 2;
        case 2: return 4;
        case 3: return 6;
        case 4: return 10;
    }
    return 0;
}

string MitGetLevelName(int nLevel)
{
    switch(nLevel)
    {
        case 0: return "Brak";
        case 1: return "Znikoma";
        case 2: return "Umiarkowana";
        case 3: return "Silna";
        case 4: return "Pełna odporność";
    }
    return "?";
}

string MitGetLevelBuffDesc(int nLevel)
{
    switch(nLevel)
    {
        case 0: return "Żadnej odporności na tę truciznę.";
        case 1: return "+2 do rzutów obronnych Wytrwałości (Trucizna).";
        case 2: return "+4 do rzutów. Połowa obrażeń przy nieudanym rzucie.";
        case 3: return "+6 do rzutów. Ćwierć obrażeń przy nieudanym rzucie.";
        case 4: return "Pełna odporność. Trucizna nie ma żadnego efektu.";
    }
    return "";
}

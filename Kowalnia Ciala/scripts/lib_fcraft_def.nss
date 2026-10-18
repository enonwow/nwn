#include "lib_nui"

// ----------------------------------------------------------------
// Window IDs
// ----------------------------------------------------------------

const string FCRAFT_WIN_MAIN    = "FCRAFT_WIN_MAIN";
const string FCRAFT_EV_SCRIPT   = "lib_fcraft_ev";
const string FCRAFT_WIN_GEOM    = "fcraft_win_geom";

// ----------------------------------------------------------------
// Bind names — catalog tab
// ----------------------------------------------------------------

const string FCRAFT_BIND_CAT_NAME   = "fcraft_cat_name";
const string FCRAFT_BIND_CAT_COST   = "fcraft_cat_cost";
const string FCRAFT_BIND_CAT_ENC    = "fcraft_cat_enc";
const string FCRAFT_BIND_CAT_AVAIL  = "fcraft_cat_avail";

// Bind names — detail panel
const string FCRAFT_BIND_DET_TITLE  = "fcraft_det_title";
const string FCRAFT_BIND_DET_FLAVOR = "fcraft_det_flavor";
const string FCRAFT_BIND_DET_EFFECT = "fcraft_det_effect";
const string FCRAFT_BIND_DET_COST   = "fcraft_det_cost";
const string FCRAFT_BIND_DET_COMP   = "fcraft_det_comp";
const string FCRAFT_BIND_IMPL_ENA   = "fcraft_impl_ena";
const string FCRAFT_BIND_IMPL_LBL   = "fcraft_impl_lbl";

// Bind names — active tab
const string FCRAFT_BIND_ACT_NAME   = "fcraft_act_name";
const string FCRAFT_BIND_ACT_EFF    = "fcraft_act_eff";
const string FCRAFT_BIND_ACT_ENC    = "fcraft_act_enc";
const string FCRAFT_BIND_USE_VIS    = "fcraft_use_vis";
const string FCRAFT_BIND_USE_COOL   = "fcraft_use_cool";
const string FCRAFT_BIND_USE_ENA    = "fcraft_use_ena";
const string FCRAFT_BIND_REM_ENA    = "fcraft_rem_ena";
const string FCRAFT_BIND_REM_COST   = "fcraft_rem_cost";

// ----------------------------------------------------------------
// Button / element IDs
// ----------------------------------------------------------------

const string FCRAFT_BTN_CLOSE       = "fcraft_btn_close";
const string FCRAFT_BTN_TAB_CAT     = "fcraft_btn_tabcat";
const string FCRAFT_BTN_TAB_ACT     = "fcraft_btn_tabact";
const string FCRAFT_BTN_CAT_ROW     = "fcraft_btn_catrow";
const string FCRAFT_BTN_ACT_ROW     = "fcraft_btn_actrow";
const string FCRAFT_BTN_IMPLANT     = "fcraft_btn_impl";
const string FCRAFT_BTN_USE         = "fcraft_btn_use";
const string FCRAFT_BTN_REMOVE      = "fcraft_btn_rem";

// ----------------------------------------------------------------
// Local variables on PC
// ----------------------------------------------------------------

const string FCRAFT_LVAR_SEL_IDX    = "FCRAFT_SEL_IDX";
const string FCRAFT_LVAR_SEL_ACT    = "FCRAFT_SEL_ACT";
const string FCRAFT_LVAR_TAB        = "FCRAFT_TAB";        // 0=catalog, 1=active
const string FCRAFT_LVAR_TARGETING  = "FCRAFT_TARGETING";  // mod id being used

// ----------------------------------------------------------------
// Layout constants
// ----------------------------------------------------------------

const float  FCRAFT_W               = 780.0;
const float  FCRAFT_H               = 520.0;
const int    FCRAFT_MAX_MODS        = 5;
const int    FCRAFT_REMOVE_MULT     = 2; // removal costs 2x the implant price

// ----------------------------------------------------------------
// Modification IDs
// ----------------------------------------------------------------

const string FCRAFT_MOD_CHITIN      = "CHITIN";
const string FCRAFT_MOD_DEMONSEYE   = "DEMONSEYE";
const string FCRAFT_MOD_SINEWARM    = "SINEWARM";
const string FCRAFT_MOD_BONEFIST    = "BONEFIST";
const string FCRAFT_MOD_SPIDERGLAND = "SPIDER";
const string FCRAFT_MOD_IRONHIDE    = "IRONHIDE";
const string FCRAFT_MOD_VENOMFANG   = "VENOMFANG";
const string FCRAFT_MOD_HEARTVAULT  = "HEARTVAULT";
const string FCRAFT_MOD_STONEEYE    = "STONEEYE";
const string FCRAFT_MOD_SHADOWLIMB  = "SHADOW";

const int    FCRAFT_MOD_COUNT       = 10;

// ----------------------------------------------------------------
// Component resrefs (required item in PC inventory)
// ----------------------------------------------------------------

const string FCRAFT_COMP_CHITIN     = "fcraft_comp_chitin";
const string FCRAFT_COMP_DEMONSEYE  = "fcraft_comp_deye";
const string FCRAFT_COMP_SINEWARM   = "fcraft_comp_sinew";
const string FCRAFT_COMP_BONEFIST   = "fcraft_comp_bone";
const string FCRAFT_COMP_SPIDERGLAND= "fcraft_comp_sgland";
const string FCRAFT_COMP_IRONHIDE   = "fcraft_comp_ironfl";
const string FCRAFT_COMP_VENOMFANG  = "fcraft_comp_venom";
const string FCRAFT_COMP_HEARTVAULT = "fcraft_comp_heart";
const string FCRAFT_COMP_STONEEYE   = "fcraft_comp_beye";
const string FCRAFT_COMP_SHADOWLIMB = "fcraft_comp_shade";

// ----------------------------------------------------------------
// Active-ability cooldown tags
// ----------------------------------------------------------------

const string FCRAFT_COOL_WEB        = "FCRAFT_COOL_WEB";
const string FCRAFT_COOL_POISON     = "FCRAFT_COOL_PSN";
const string FCRAFT_COOL_BLINK      = "FCRAFT_COOL_BLNK";

// ----------------------------------------------------------------
// Helpers: catalog access by index
// ----------------------------------------------------------------

string FcraftModId(int i)
{
    switch(i)
    {
        case 0: return FCRAFT_MOD_CHITIN;
        case 1: return FCRAFT_MOD_DEMONSEYE;
        case 2: return FCRAFT_MOD_SINEWARM;
        case 3: return FCRAFT_MOD_BONEFIST;
        case 4: return FCRAFT_MOD_SPIDERGLAND;
        case 5: return FCRAFT_MOD_IRONHIDE;
        case 6: return FCRAFT_MOD_VENOMFANG;
        case 7: return FCRAFT_MOD_HEARTVAULT;
        case 8: return FCRAFT_MOD_STONEEYE;
        case 9: return FCRAFT_MOD_SHADOWLIMB;
    }
    return "";
}

string FcraftModName(string sId)
{
    if(sId == FCRAFT_MOD_CHITIN)      return "Chitynowy Pancerz";
    if(sId == FCRAFT_MOD_DEMONSEYE)   return "Oko Demona";
    if(sId == FCRAFT_MOD_SINEWARM)    return "Żylaste Ramię";
    if(sId == FCRAFT_MOD_BONEFIST)    return "Chitynowa Dłoń";
    if(sId == FCRAFT_MOD_SPIDERGLAND) return "Gruczoł Pająka";
    if(sId == FCRAFT_MOD_IRONHIDE)    return "Żelazna Skóra";
    if(sId == FCRAFT_MOD_VENOMFANG)   return "Jadowite Kły";
    if(sId == FCRAFT_MOD_HEARTVAULT)  return "Wzmocnione Serce";
    if(sId == FCRAFT_MOD_STONEEYE)    return "Kamienne Oczy";
    if(sId == FCRAFT_MOD_SHADOWLIMB)  return "Macka Cienia";
    return "Nieznana";
}

int FcraftModCost(string sId)
{
    if(sId == FCRAFT_MOD_CHITIN)      return 3000;
    if(sId == FCRAFT_MOD_DEMONSEYE)   return 4000;
    if(sId == FCRAFT_MOD_SINEWARM)    return 2500;
    if(sId == FCRAFT_MOD_BONEFIST)    return 2000;
    if(sId == FCRAFT_MOD_SPIDERGLAND) return 3500;
    if(sId == FCRAFT_MOD_IRONHIDE)    return 5000;
    if(sId == FCRAFT_MOD_VENOMFANG)   return 2500;
    if(sId == FCRAFT_MOD_HEARTVAULT)  return 3000;
    if(sId == FCRAFT_MOD_STONEEYE)    return 6000;
    if(sId == FCRAFT_MOD_SHADOWLIMB)  return 7000;
    return 9999;
}

string FcraftModComp(string sId)
{
    if(sId == FCRAFT_MOD_CHITIN)      return FCRAFT_COMP_CHITIN;
    if(sId == FCRAFT_MOD_DEMONSEYE)   return FCRAFT_COMP_DEMONSEYE;
    if(sId == FCRAFT_MOD_SINEWARM)    return FCRAFT_COMP_SINEWARM;
    if(sId == FCRAFT_MOD_BONEFIST)    return FCRAFT_COMP_BONEFIST;
    if(sId == FCRAFT_MOD_SPIDERGLAND) return FCRAFT_COMP_SPIDERGLAND;
    if(sId == FCRAFT_MOD_IRONHIDE)    return FCRAFT_COMP_IRONHIDE;
    if(sId == FCRAFT_MOD_VENOMFANG)   return FCRAFT_COMP_VENOMFANG;
    if(sId == FCRAFT_MOD_HEARTVAULT)  return FCRAFT_COMP_HEARTVAULT;
    if(sId == FCRAFT_MOD_STONEEYE)    return FCRAFT_COMP_STONEEYE;
    if(sId == FCRAFT_MOD_SHADOWLIMB)  return FCRAFT_COMP_SHADOWLIMB;
    return "";
}

string FcraftModFlavor(string sId)
{
    if(sId == FCRAFT_MOD_CHITIN)
        return "Chityna owadzia obszywa grzbiet i ramiona; każdy krok brzęczy cicho jak zbroja z insektów. Gdy ją dotykasz, pod skórą czujesz chłód martwej powłoki.";
    if(sId == FCRAFT_MOD_DEMONSEYE)
        return "Puste oczodół Rzeźbiarz wypełnia kulą zrodzoną z oka demonicy. Widzisz teraz w mroku rzeczy, których nie chcesz widzieć.";
    if(sId == FCRAFT_MOD_SINEWARM)
        return "Pasma mięśni olbrzyma wpleciono w twoje ramię jak liny do belki. Uścisk dłoni druzgoce kości, lecz palce trzęsą się przy igielnej pracy.";
    if(sId == FCRAFT_MOD_BONEFIST)
        return "Kości bestii wrosły pod skórę dłoni; knykcie sterczą jak zęby. W bójce każde uderzenie dziurawi skórę jak ostry kamień.";
    if(sId == FCRAFT_MOD_SPIDERGLAND)
        return "Pod żebrami pulsuje coś miękkiego — gruczoł olbrzymiego pająka. W piersiach czujesz delikatną, lepką wilgoć. Gdy ją ściskasz, sznury przędzy tryskają z ust.";
    if(sId == FCRAFT_MOD_IRONHIDE)
        return "Dermę poddano procesowi, który Rzeźbiarz opisuje jedynie jako 'utwardzenie od środka'. Skóra w dotyku brzmi jak stłuczone naczynie.";
    if(sId == FCRAFT_MOD_VENOMFANG)
        return "Kły żmii — dwa zakrzywione igły — wrosły za zębami. Gruczoł pod językiem wypełnia je powoli przy każdej myśli o łupie.";
    if(sId == FCRAFT_MOD_HEARTVAULT)
        return "Serce owinięto żyłami golemów. Bije mocniej, wolniej, z rytmem kowalskiego miecha. Mówią, że można usłyszeć jego uderzenia przez żebrowe klatki.";
    if(sId == FCRAFT_MOD_STONEEYE)
        return "Beholder oddał jedno oko za darmo — bo uważa cię za niegodnego. Kamień barwy grafitu siedzi w oczodole i widzi wszystko, co ukryte.";
    if(sId == FCRAFT_MOD_SHADOWLIMB)
        return "Ramię po ramię rośnie cień — niematerialny, posłuszny. Dotknąć nim można ścianę lub twarz z odległości kroku. Zimne jest zawsze.";
    return "";
}

string FcraftModEffectDesc(string sId)
{
    if(sId == FCRAFT_MOD_CHITIN)      return "ZBR +3 (odchylenie), ZR -1, Perswazja -2";
    if(sId == FCRAFT_MOD_DEMONSEYE)   return "+5 Dostrzegania, +5 Słuchania, Perswazja -2";
    if(sId == FCRAFT_MOD_SINEWARM)    return "SIŁ +2, ZR -1";
    if(sId == FCRAFT_MOD_BONEFIST)    return "AB +1 (walka bez broni), SIŁ +1";
    if(sId == FCRAFT_MOD_SPIDERGLAND) return "ZR +1, odporność na splątanie; zdolność aktywna: Sieć (1/spoczynek)";
    if(sId == FCRAFT_MOD_IRONHIDE)    return "ZBR +2 (naturalna), ZR -1";
    if(sId == FCRAFT_MOD_VENOMFANG)   return "BUD +1, odporność na truciznę; zdolność aktywna: Ukąszenie (1/spoczynek)";
    if(sId == FCRAFT_MOD_HEARTVAULT)  return "BUD +2, Odporność +2";
    if(sId == FCRAFT_MOD_STONEEYE)    return "MĄD +2, +5 Dostrzegania, odporność na oślepienie";
    if(sId == FCRAFT_MOD_SHADOWLIMB)  return "ZR +2, SIŁ -1; zdolność aktywna: Skok Cienia (1/spoczynek)";
    return "";
}

// Returns 1 if this mod has an activatable ability
int FcraftModHasAbility(string sId)
{
    if(sId == FCRAFT_MOD_SPIDERGLAND) return TRUE;
    if(sId == FCRAFT_MOD_VENOMFANG)   return TRUE;
    if(sId == FCRAFT_MOD_SHADOWLIMB)  return TRUE;
    return FALSE;
}

// Returns cooldown tag for active ability
string FcraftModCooldownTag(string sId)
{
    if(sId == FCRAFT_MOD_SPIDERGLAND) return FCRAFT_COOL_WEB;
    if(sId == FCRAFT_MOD_VENOMFANG)   return FCRAFT_COOL_POISON;
    if(sId == FCRAFT_MOD_SHADOWLIMB)  return FCRAFT_COOL_BLINK;
    return "";
}

// Returns mutual-exclusion partner (empty = none)
string FcraftModExcludes(string sId)
{
    if(sId == FCRAFT_MOD_DEMONSEYE)   return FCRAFT_MOD_STONEEYE;
    if(sId == FCRAFT_MOD_STONEEYE)    return FCRAFT_MOD_DEMONSEYE;
    if(sId == FCRAFT_MOD_CHITIN)      return FCRAFT_MOD_IRONHIDE;
    if(sId == FCRAFT_MOD_IRONHIDE)    return FCRAFT_MOD_CHITIN;
    return "";
}

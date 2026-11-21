// lib_alch_def.nss
// Constants, recipe metadata and helpers for the Alchemy Workshop module.
#include "nw_inc_nui"
#include "sql_alch"

// ----------------------------------------------------------------
// Forward declarations
// ----------------------------------------------------------------
void FeedRecipeList(object oPC, int nToken);
void FeedDetailPanel(object oPC, int nToken, int nIdx);

// ----------------------------------------------------------------
// Window / event
// ----------------------------------------------------------------
const string ALCH_WINDOW    = "ALCH_WINDOW";
const string ALCH_EV_SCRIPT = "lib_alch_ev";

const float ALCH_WIN_W = 700.0;
const float ALCH_WIN_H = 500.0;

// ----------------------------------------------------------------
// Bind names — recipe list
// ----------------------------------------------------------------
const string ALCH_BIND_REC_NAME  = "alch_rec_name";
const string ALCH_BIND_REC_ENC   = "alch_rec_enc";
const string ALCH_BIND_REC_COLOR = "alch_rec_color";
const string ALCH_BIND_REC_COUNT = "alch_rec_count";

// ----------------------------------------------------------------
// Bind names — detail panel
// ----------------------------------------------------------------
const string ALCH_BIND_DET_NAME  = "alch_det_name";
const string ALCH_BIND_DET_DESC  = "alch_det_desc";
const string ALCH_BIND_DET_FLAV  = "alch_det_flav";

const string ALCH_BIND_ING1_NAME = "alch_ing1_name";
const string ALCH_BIND_ING2_NAME = "alch_ing2_name";
const string ALCH_BIND_ING3_NAME = "alch_ing3_name";
const string ALCH_BIND_ING1_HAVE = "alch_ing1_have";
const string ALCH_BIND_ING2_HAVE = "alch_ing2_have";
const string ALCH_BIND_ING3_HAVE = "alch_ing3_have";
const string ALCH_BIND_ING1_COL  = "alch_ing1_col";
const string ALCH_BIND_ING2_COL  = "alch_ing2_col";
const string ALCH_BIND_ING3_COL  = "alch_ing3_col";

const string ALCH_BIND_DC_LBL    = "alch_dc_lbl";
const string ALCH_BIND_SKILL_LBL = "alch_skill_lbl";
const string ALCH_BIND_BREW_EN   = "alch_brew_en";
const string ALCH_BIND_LOCKED_LBL= "alch_locked_lbl";
const string ALCH_BIND_LOCKED_VIS= "alch_locked_vis";

// ----------------------------------------------------------------
// Buttons
// ----------------------------------------------------------------
const string ALCH_BTN_CLOSE = "alch_btn_x";
const string ALCH_BTN_ROW   = "alch_btn_row";
const string ALCH_BTN_BREW  = "alch_btn_brew";

// ----------------------------------------------------------------
// PC local variables
// ----------------------------------------------------------------
const string ALCH_LVAR_SEL_IDX = "ALCH_SEL_IDX";   // int, -1 = none

// ----------------------------------------------------------------
// Ingredient resrefs — add items with these resrefs to your hak
// ----------------------------------------------------------------
const string ALCH_ING_PIOLUN  = "alch_piolun";     // Piołun (wormwood)
const string ALCH_ING_KOSCIOL = "alch_kosciol";    // Kość Trupna (bone meal)
const string ALCH_ING_KREW_N  = "alch_krew_n";     // Krew Nocna (night blood)
const string ALCH_ING_GRZYB   = "alch_grzyb";      // Czarny Grzyb (black mushroom)
const string ALCH_ING_RTEC    = "alch_rtec";        // Rtęć (mercury)
const string ALCH_ING_OLEJ    = "alch_olej";        // Tłuszcz Szczurzy (rat fat)
const string ALCH_ING_OKO     = "alch_oko";         // Oko Sowy (owl eye)
const string ALCH_ING_KWIAT   = "alch_kwiat";       // Kwiat Bladej Damy (pale lady flower)
const string ALCH_ING_KREW_O  = "alch_krew_o";     // Krew Ogra (ogre blood)
const string ALCH_ING_ZELAZ   = "alch_zelaz";       // Pył Żelazny (iron dust)

// ----------------------------------------------------------------
// Recipe scroll tags — picking up ALCH_REC_N unlocks recipe N
// ----------------------------------------------------------------
const string ALCH_REC_TAG_PREFIX = "ALCH_REC_";

// ----------------------------------------------------------------
// Recipe count
// ----------------------------------------------------------------
const int ALCH_RECIPE_COUNT = 9;

// Recipes 0 and 1 are known by default; others require recipe scrolls.
const int ALCH_STARTER_A = 0;
const int ALCH_STARTER_B = 1;

// ----------------------------------------------------------------
// Recipe accessors — switch-based to avoid global arrays in NWScript
// ----------------------------------------------------------------

string AlchGetRecipeName(int nId)
{
    switch(nId)
    {
        case 0: return "Nalewka Gojąca";
        case 1: return "Odwar Mrocznego Wzroku";
        case 2: return "Wywar Pancerza Krwi";
        case 3: return "Eliksir Siły Ogra";
        case 4: return "Wywar Cieni";
        case 5: return "Odwar Odporności";
        case 6: return "Eliksir Szybkości";
        case 7: return "Wywar Ostrza";
        case 8: return "Nalewka Czarnego Serca";
    }
    return "Nieznany Wywar";
}

string AlchGetRecipeDesc(int nId)
{
    switch(nId)
    {
        case 0: return "Leczy 15 punktów ran. Prosta, niezawodna mikstura.";
        case 1: return "Ultrawzrok przez 3 minuty. Widzisz w ciemności i dostrzegasz ukryte.";
        case 2: return "Pancerz magiczny +4 do KP przez 5 minut. Skóra twardnieje jak kamień.";
        case 3: return "Siła +4 przez 5 minut. Mięśnie nabrzmiewają jak u ogra.";
        case 4: return "Niewidzialność przez 2 minuty. Wtapiasz się w cień.";
        case 5: return "Odporność na rzuty obronne +2 przez 5 minut. Wewnętrzna tarcza.";
        case 6: return "Przyśpieszenie (Haste) przez 18 sekund. Każda żyła płonie.";
        case 7: return "Premia do ataku +3 przez 5 minut. Ręka prowadzi broń pewniej.";
        case 8: return "Regeneracja 2 PŻ / rundę przez 5 minut. Ciało naprawia samo siebie.";
    }
    return "";
}

string AlchGetRecipeFlavor(int nId)
{
    switch(nId)
    {
        case 0: return "„Smakuje jak ziemia i rdza, ale ból odpływa szybko."";
        case 1: return "„Po wypiciu źrenice rozszerzają się niczym u kota — widzisz każdy cień."";
        case 2: return "„Skóra błyszczy przez chwilę srebrno, zanim efekt znika pod tkanią."";
        case 3: return "„Zapach krwi ogra nie znika przez kilka godzin. Warto."";
        case 4: return "„Ciało staje się nieokreślone. Nawet własne dłonie wydają się mgliste."";
        case 5: return "„Gorzkie i metaliczne. Chroni, lecz smak zostaje długo."";
        case 6: return "„Rtęć śpiewa w żyłach. Ruszasz się zanim zdążysz pomyśleć."";
        case 7: return "„Ręka unosi się sama ku rękojeści. Instynkt staje się ostrym ostrzem."";
        case 8: return "„Serce bije wolno, lecz równo. Rany zaciskają się jak usta milczące."";
    }
    return "";
}

int AlchGetRecipeDC(int nId)
{
    switch(nId)
    {
        case 0: return 12;
        case 1: return 14;
        case 2: return 14;
        case 3: return 16;
        case 4: return 16;
        case 5: return 18;
        case 6: return 18;
        case 7: return 20;
        case 8: return 22;
    }
    return 15;
}

string AlchGetRecipeIng1(int nId)
{
    switch(nId)
    {
        case 0: return ALCH_ING_PIOLUN;
        case 1: return ALCH_ING_GRZYB;
        case 2: return ALCH_ING_ZELAZ;
        case 3: return ALCH_ING_KREW_O;
        case 4: return ALCH_ING_OKO;
        case 5: return ALCH_ING_RTEC;
        case 6: return ALCH_ING_RTEC;
        case 7: return ALCH_ING_KREW_O;
        case 8: return ALCH_ING_GRZYB;
    }
    return "";
}

string AlchGetRecipeIng2(int nId)
{
    switch(nId)
    {
        case 0: return ALCH_ING_KOSCIOL;
        case 1: return ALCH_ING_OKO;
        case 2: return ALCH_ING_OLEJ;
        case 3: return ALCH_ING_ZELAZ;
        case 4: return ALCH_ING_GRZYB;
        case 5: return ALCH_ING_KWIAT;
        case 6: return ALCH_ING_KWIAT;
        case 7: return ALCH_ING_ZELAZ;
        case 8: return ALCH_ING_KREW_N;
    }
    return "";
}

string AlchGetRecipeIng3(int nId)
{
    switch(nId)
    {
        case 0: return ALCH_ING_KREW_N;
        case 1: return ALCH_ING_RTEC;
        case 2: return ALCH_ING_KOSCIOL;
        case 3: return ALCH_ING_OLEJ;
        case 4: return ALCH_ING_KOSCIOL;
        case 5: return ALCH_ING_KOSCIOL;
        case 6: return ALCH_ING_OLEJ;
        case 7: return ALCH_ING_OLEJ;
        case 8: return ALCH_ING_KWIAT;
    }
    return "";
}

// Polish display name for each ingredient resref
string AlchGetIngredientName(string sResRef)
{
    if(sResRef == ALCH_ING_PIOLUN)  return "Piołun";
    if(sResRef == ALCH_ING_KOSCIOL) return "Kość Trupna";
    if(sResRef == ALCH_ING_KREW_N)  return "Krew Nocna";
    if(sResRef == ALCH_ING_GRZYB)   return "Czarny Grzyb";
    if(sResRef == ALCH_ING_RTEC)    return "Rtęć";
    if(sResRef == ALCH_ING_OLEJ)    return "Tłuszcz Szczurzy";
    if(sResRef == ALCH_ING_OKO)     return "Oko Sowy";
    if(sResRef == ALCH_ING_KWIAT)   return "Kwiat Bladej Damy";
    if(sResRef == ALCH_ING_KREW_O)  return "Krew Ogra";
    if(sResRef == ALCH_ING_ZELAZ)   return "Pył Żelazny";
    return sResRef;
}

// ----------------------------------------------------------------
// Inventory helpers
// ----------------------------------------------------------------

// Count total stack size of items matching sResRef in PC inventory
int AlchCountIngredient(object oPC, string sResRef)
{
    int nCount = 0;
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem))
    {
        if(GetResRef(oItem) == sResRef)
            nCount += GetItemStackSize(oItem);
        oItem = GetNextItemInInventory(oPC);
    }
    return nCount;
}

// Remove exactly one unit of sResRef from PC inventory (reduces stack or destroys)
void AlchTakeIngredient(object oPC, string sResRef)
{
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem))
    {
        if(GetResRef(oItem) == sResRef)
        {
            int nStack = GetItemStackSize(oItem);
            if(nStack > 1)
                SetItemStackSize(oItem, nStack - 1);
            else
                DestroyObject(oItem);
            return;
        }
        oItem = GetNextItemInInventory(oPC);
    }
}

// ----------------------------------------------------------------
// Craft skill bonus: Spellcraft rank + INT modifier
// ----------------------------------------------------------------
int AlchGetCraftBonus(object oPC)
{
    int nSkill = GetSkillRank(SKILL_SPELLCRAFT, oPC);
    int nInt   = GetAbilityScore(oPC, ABILITY_INTELLIGENCE);
    int nMod   = (nInt - 10) / 2;
    return nSkill + nMod;
}

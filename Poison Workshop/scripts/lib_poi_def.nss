#include "lib_nui"
#include "sql_poi"

// Forward declarations (bodies in lib_poi.nss)
void FeedWorkshop(object oPC, int nToken);
void FeedArsenal(object oPC, int nToken);
void PoiOnWeaponTarget(object oPC);

// ----------------------------------------------------------------
// Ingredient IDs
// ----------------------------------------------------------------

const int POI_ING_NIGHTSHADE  = 0;
const int POI_ING_BLOODROOT   = 1;
const int POI_ING_SPIDER      = 2;
const int POI_ING_MARSH       = 3;
const int POI_ING_CORPSE      = 4;
const int POI_ING_WITCHBANE   = 5;
const int POI_ING_BILE        = 6;
const int POI_ING_IRON        = 7;

// ----------------------------------------------------------------
// Poison vial IDs
// ----------------------------------------------------------------

const int POI_VIAL_SLOW       = 0;
const int POI_VIAL_PARALYZE   = 1;
const int POI_VIAL_BLIND      = 2;
const int POI_VIAL_WEAKEN     = 3;
const int POI_VIAL_LETHAL     = 4;
const int POI_VIAL_WITCHBANE  = 5;

// ----------------------------------------------------------------
// Weapon-state local vars on PC
// ----------------------------------------------------------------

const string POI_LVAR_PENDING   = "POI_PENDING_VIAL";  // vial_id+1 while targeting; 0 = none
const string POI_LVAR_POISON_ID = "POI_WEP_ID";        // active poison id+1 on weapon; 0 = none

// ----------------------------------------------------------------
// Duration a single dose stays active on the weapon (seconds)
// ----------------------------------------------------------------

const float POI_WEAPON_DURATION = 120.0;

// ----------------------------------------------------------------
// Window / group IDs
// ----------------------------------------------------------------

const string POI_WINDOW         = "POI_WIN";
const string POI_EV_SCRIPT      = "lib_poi_ev";
const string POI_GRP_SWAP       = "POI_GRP_SWAP";
const string POI_WIN_GEOM       = "poi_win_geom";

// ----------------------------------------------------------------
// Bind names — Workshop view
// ----------------------------------------------------------------

const string POI_BIND_ING_NAME      = "poi_ing_name";
const string POI_BIND_ING_COUNT     = "poi_ing_cnt";
const string POI_BIND_ING_COLOR     = "poi_ing_col";
const string POI_BIND_ING_LEN       = "poi_ing_len";

const string POI_BIND_REC_NAME      = "poi_rec_name";
const string POI_BIND_REC_INGR      = "poi_rec_ingr";
const string POI_BIND_REC_CRAFT_ENA = "poi_rec_cena";
const string POI_BIND_REC_COLOR     = "poi_rec_col";
const string POI_BIND_REC_LEN       = "poi_rec_len";

// ----------------------------------------------------------------
// Bind names — Arsenal view
// ----------------------------------------------------------------

const string POI_BIND_ARS_NAME      = "poi_ars_name";
const string POI_BIND_ARS_COUNT     = "poi_ars_cnt";
const string POI_BIND_ARS_APPLY_ENA = "poi_ars_aena";
const string POI_BIND_ARS_COLOR     = "poi_ars_col";
const string POI_BIND_ARS_LEN       = "poi_ars_len";
const string POI_BIND_ARS_ACTIVE    = "poi_ars_act";

// ----------------------------------------------------------------
// Bind names — tab state
// ----------------------------------------------------------------

const string POI_BIND_TAB_WORK_ENC  = "poi_tab_wenc";
const string POI_BIND_TAB_ARS_ENC   = "poi_tab_aenc";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string POI_BTN_CLOSE          = "poi_close";
const string POI_BTN_TAB_WORKSHOP   = "poi_tab_work";
const string POI_BTN_TAB_ARSENAL    = "poi_tab_ars";
const string POI_BTN_CRAFT          = "poi_craft";   // array: index = vial id
const string POI_BTN_APPLY          = "poi_apply";   // array: index = vial id

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------

const float POI_W = 580.0;
const float POI_H = 620.0;

// ----------------------------------------------------------------
// Static data — names, colors, recipes
// ----------------------------------------------------------------

string PoiIngredientName(int n)
{
    switch(n)
    {
        case POI_ING_NIGHTSHADE: return "Jagoda Cieniu Nocy";
        case POI_ING_BLOODROOT:  return "Korzeń Krwawnika";
        case POI_ING_SPIDER:     return "Worek Jadu Pająka";
        case POI_ING_MARSH:      return "Kryształy Mgieł";
        case POI_ING_CORPSE:     return "Pyłek Kwiatu Zwłok";
        case POI_ING_WITCHBANE:  return "Grzyb Czarownic";
        case POI_ING_BILE:       return "Żółć Jaskiniowa";
        case POI_ING_IRON:       return "Proch Żelaza";
    }
    return "?";
}

string PoiPoisonName(int n)
{
    switch(n)
    {
        case POI_VIAL_SLOW:      return "Trucizna Wolna";
        case POI_VIAL_PARALYZE:  return "Jad Paraliżu";
        case POI_VIAL_BLIND:     return "Jad Ślepoty";
        case POI_VIAL_WEAKEN:    return "Trucizna Osłabienia";
        case POI_VIAL_LETHAL:    return "Wyciąg Nocy";
        case POI_VIAL_WITCHBANE: return "Jad Czarownicy";
    }
    return "?";
}

string PoiPoisonEffect(int n)
{
    switch(n)
    {
        case POI_VIAL_SLOW:      return "Spowalnia cel na 30s";
        case POI_VIAL_PARALYZE:  return "Paraliżuje cel na 6s";
        case POI_VIAL_BLIND:     return "Zaślepia cel na 20s";
        case POI_VIAL_WEAKEN:    return "-4 Sił celu na 60s";
        case POI_VIAL_LETHAL:    return "+2k6 obrażeń od kwasu";
        case POI_VIAL_WITCHBANE: return "Dispeluje magię celu";
    }
    return "";
}

json PoiPoisonColor(int n)
{
    switch(n)
    {
        case POI_VIAL_SLOW:      return NuiColor( 80, 200,  80);
        case POI_VIAL_PARALYZE:  return NuiColor(220, 220,  50);
        case POI_VIAL_BLIND:     return NuiColor( 80, 140, 220);
        case POI_VIAL_WEAKEN:    return NuiColor(220, 120,  50);
        case POI_VIAL_LETHAL:    return NuiColor(210,  50,  50);
        case POI_VIAL_WITCHBANE: return NuiColor(160,  60, 210);
    }
    return NuiColor(200, 200, 200);
}

// Fills up to three ingredient slots for a recipe; -1 = unused slot.
void PoiGetRecipe(int nPoisonId, int &nIng0, int &nIng1, int &nIng2)
{
    nIng0 = -1; nIng1 = -1; nIng2 = -1;
    switch(nPoisonId)
    {
        case POI_VIAL_SLOW:
            nIng0 = POI_ING_BLOODROOT;
            nIng1 = POI_ING_IRON;
            break;
        case POI_VIAL_PARALYZE:
            nIng0 = POI_ING_SPIDER;
            nIng1 = POI_ING_IRON;
            break;
        case POI_VIAL_BLIND:
            nIng0 = POI_ING_MARSH;
            nIng1 = POI_ING_IRON;
            break;
        case POI_VIAL_WEAKEN:
            nIng0 = POI_ING_CORPSE;
            nIng1 = POI_ING_IRON;
            break;
        case POI_VIAL_LETHAL:
            nIng0 = POI_ING_NIGHTSHADE;
            nIng1 = POI_ING_BLOODROOT;
            nIng2 = POI_ING_CORPSE;
            break;
        case POI_VIAL_WITCHBANE:
            nIng0 = POI_ING_WITCHBANE;
            nIng1 = POI_ING_BILE;
            nIng2 = POI_ING_IRON;
            break;
    }
}

string PoiRecipeString(int nPoisonId)
{
    int i0, i1, i2;
    PoiGetRecipe(nPoisonId, i0, i1, i2);
    string s = (i0 >= 0) ? PoiIngredientName(i0) : "";
    if(i1 >= 0) s = s + " + " + PoiIngredientName(i1);
    if(i2 >= 0) s = s + " + " + PoiIngredientName(i2);
    return s;
}

// ----------------------------------------------------------------
// Weapon expiry callback — called via DelayCommand after duration
// ----------------------------------------------------------------

void PoiClearWeaponPoison(object oPC)
{
    int nWasId = GetLocalInt(oPC, POI_LVAR_POISON_ID) - 1;
    DeleteLocalInt(oPC, POI_LVAR_POISON_ID);

    if(nWasId < 0) return;

    SendMessageToPC(oPC, "[Trucizny] " + PoiPoisonName(nWasId) + " wyparowała z ostrza.");

    int nToken = NuiFindWindow(oPC, POI_WINDOW);
    if(nToken != 0)
        FeedArsenal(oPC, nToken);
}

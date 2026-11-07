// lib_wca_def.nss — Witch Cauldron: constants, recipe catalog, ingredient helpers
#include "lib_nui"
#include "sql_wca"

// Forward declarations
void WcaOpenWindow(object oPC, object oCauldron);
void WcaOnPlayerTarget(object oPC);
void WcaFeedSlots(object oPC, int nToken);
void WcaFeedRecipeList(object oPC, int nToken);
void WcaFeedSelectedRecipe(object oPC, int nToken);
void WcaLearnRecipe(object oPC, int nRecipeId);

// ---- Window / NUI IDs ----
const string WCA_WINDOW         = "WCA_WINDOW";
const string WCA_EV_SCRIPT      = "lib_wca_ev";
const string WCA_WIN_GEOM       = "wca_win_geom";

// ---- Binds (array binds use JsonArray) ----
const string WCA_BIND_REC_NAMES  = "wca_rec_names";   // JsonArray<string>
const string WCA_BIND_REC_ENC    = "wca_rec_enc";     // JsonArray<bool>
const string WCA_BIND_REC_NAME   = "wca_recname";     // string — selected recipe name
const string WCA_BIND_REC_DESC   = "wca_recdesc";     // string — selected recipe desc
const string WCA_BIND_REQ_LBL    = "wca_req_lbl";     // string — required ingredients text
const string WCA_BIND_SLOT_LBL   = "wca_slot_lbl";    // JsonArray<string> — slot labels [0..3]
const string WCA_BIND_SLOT_ENA   = "wca_slot_ena";    // JsonArray<bool>   — remove btn enabled
const string WCA_BIND_ADD_ENA    = "wca_add_ena";     // JsonArray<bool>   — add btn enabled
const string WCA_BIND_BREW_ENA   = "wca_brew_ena";    // bool
const string WCA_BIND_STATUS     = "wca_status";      // string
const string WCA_BIND_PROGRESS   = "wca_progress";    // float 0.0-1.0
const string WCA_BIND_PROG_VIS   = "wca_prog_vis";    // bool

// ---- Button IDs ----
const string WCA_BTN_CLOSE       = "wca_btn_close";
const string WCA_BTN_BREW        = "wca_btn_brew";
const string WCA_BTN_REC_ROW     = "wca_btn_rec";     // list row click
const string WCA_BTN_SLOT_ADD    = "wca_btn_add";     // list row click (slot index)
const string WCA_BTN_SLOT_REMOVE = "wca_btn_rmv";     // list row click (slot index)

// ---- Local vars on PC ----
const string WCA_LVAR_CAULDRON   = "WCA_CAULDRON_UUID";   // UUID of the cauldron placeable
const string WCA_LVAR_SLOTS      = "WCA_SLOTS";           // JsonArray[4]: null or {tag,name}
const string WCA_LVAR_SEL_REC    = "WCA_SEL_REC";         // int (-1 = none selected)
const string WCA_LVAR_TARG_SLOT  = "WCA_TARG_SLOT";       // int (which slot we're filling)
const string WCA_LVAR_BREWING    = "WCA_BREWING";          // int 1 = brew in progress

// ---- Layout constants ----
const float WCA_W         = 540.0;
const float WCA_H         = 450.0;
const int   WCA_SLOTS     = 4;
const float WCA_BREW_TIME = 7.0;   // seconds for the brewing ritual
const float WCA_BREW_TICK = 0.5;   // progress update interval

// ================================================================
// Ingredient tags and display names
// ================================================================

const string WCA_ING_MANDRAKE    = "wca_mandrake";
const string WCA_ING_NIGHTSHADE  = "wca_nightshade";
const string WCA_ING_BLOODMOSS   = "wca_bloodmoss";
const string WCA_ING_GRAVESOIL   = "wca_gravesoil";
const string WCA_ING_BONETHORN   = "wca_bonethorn";
const string WCA_ING_SHADOWFERN  = "wca_shadowfern";
const string WCA_ING_HELLBANE    = "wca_hellbane";
const string WCA_ING_SPECTER_ASH = "wca_specter_ash";
const string WCA_ING_BAT_WING    = "wca_bat_wing";
const string WCA_ING_WOLFBANE    = "wca_wolfbane";

string WcaGetIngredientName(string sTag)
{
    if(sTag == WCA_ING_MANDRAKE)    return "Korzeń Mandragory";
    if(sTag == WCA_ING_NIGHTSHADE)  return "Wilcza Jagoda";
    if(sTag == WCA_ING_BLOODMOSS)   return "Skrzepły Mech";
    if(sTag == WCA_ING_GRAVESOIL)   return "Ziemia z Grobu";
    if(sTag == WCA_ING_BONETHORN)   return "Ciernista Kość";
    if(sTag == WCA_ING_SHADOWFERN)  return "Czarna Paproć";
    if(sTag == WCA_ING_HELLBANE)    return "Płomyk Piekielny";
    if(sTag == WCA_ING_SPECTER_ASH) return "Popiół Widmy";
    if(sTag == WCA_ING_BAT_WING)    return "Skrzydło Nietoperza";
    if(sTag == WCA_ING_WOLFBANE)    return "Tojad Wilczy";
    return sTag;
}

int WcaIsKnownIngredient(string sTag)
{
    return (sTag == WCA_ING_MANDRAKE   || sTag == WCA_ING_NIGHTSHADE ||
            sTag == WCA_ING_BLOODMOSS  || sTag == WCA_ING_GRAVESOIL  ||
            sTag == WCA_ING_BONETHORN  || sTag == WCA_ING_SHADOWFERN ||
            sTag == WCA_ING_HELLBANE   || sTag == WCA_ING_SPECTER_ASH ||
            sTag == WCA_ING_BAT_WING   || sTag == WCA_ING_WOLFBANE);
}

// ================================================================
// Recipe catalog  (5 recipes, IDs 0-4)
// ================================================================

const int WCA_RECIPE_COUNT = 5;

// Tome item tags that unlock each recipe (placed in module item palette)
const string WCA_TOME_0 = "wca_tome_0";   // Worek Klątwy
const string WCA_TOME_1 = "wca_tome_1";   // Przeklęty Olejek
const string WCA_TOME_2 = "wca_tome_2";   // Mroczny Fetysz
const string WCA_TOME_3 = "wca_tome_3";   // Fiolka Rozpaczy
const string WCA_TOME_4 = "wca_tome_4";   // Krucha Nić Ochrony

string WcaGetRecipeName(int nId)
{
    switch(nId)
    {
        case 0: return "Worek Klątwy";
        case 1: return "Przeklęty Olejek";
        case 2: return "Mroczny Fetysz";
        case 3: return "Fiolka Rozpaczy";
        case 4: return "Krucha Nić Ochrony";
    }
    return "";
}

string WcaGetRecipeDesc(int nId)
{
    switch(nId)
    {
        case 0: return "Drobny worek szyty z czarnej tkaniny. Rzucony pod próg wrogowi sieje słabość i omdlenie.";
        case 1: return "Lepki olejek o zapachu rozkładu. Nałożony na broń przepoją metal przekleństwem; ofiara traci siłę woli.";
        case 2: return "Figurka z gliny i kości, wiążąca żywą istotę. Użyta z rytuałem może zadać ból z odległości.";
        case 3: return "Trunek z płomyka piekielnego i popiołu widmy. Sieje obezwładniający lęk; duchy nękają umysł.";
        case 4: return "Linka z tojadu, ziemi grobu i korzenia mandragory. Zerwana przy progu wroga niszczy jego ochronne zaklęcia.";
    }
    return "";
}

// Returns 4-element JsonArray of ingredient tags; "" = slot unused
json WcaGetRecipeIngredients(int nId)
{
    json j = JsonArray();
    switch(nId)
    {
        case 0:
            j = JsonArrayInsert(j, JsonString(WCA_ING_MANDRAKE));
            j = JsonArrayInsert(j, JsonString(WCA_ING_NIGHTSHADE));
            j = JsonArrayInsert(j, JsonString(""));
            j = JsonArrayInsert(j, JsonString(""));
            break;
        case 1:
            j = JsonArrayInsert(j, JsonString(WCA_ING_BLOODMOSS));
            j = JsonArrayInsert(j, JsonString(WCA_ING_GRAVESOIL));
            j = JsonArrayInsert(j, JsonString(""));
            j = JsonArrayInsert(j, JsonString(""));
            break;
        case 2:
            j = JsonArrayInsert(j, JsonString(WCA_ING_BONETHORN));
            j = JsonArrayInsert(j, JsonString(WCA_ING_SHADOWFERN));
            j = JsonArrayInsert(j, JsonString(WCA_ING_BAT_WING));
            j = JsonArrayInsert(j, JsonString(""));
            break;
        case 3:
            j = JsonArrayInsert(j, JsonString(WCA_ING_HELLBANE));
            j = JsonArrayInsert(j, JsonString(WCA_ING_SPECTER_ASH));
            j = JsonArrayInsert(j, JsonString(""));
            j = JsonArrayInsert(j, JsonString(""));
            break;
        case 4:
            j = JsonArrayInsert(j, JsonString(WCA_ING_WOLFBANE));
            j = JsonArrayInsert(j, JsonString(WCA_ING_GRAVESOIL));
            j = JsonArrayInsert(j, JsonString(WCA_ING_MANDRAKE));
            j = JsonArrayInsert(j, JsonString(""));
            break;
        default:
            j = JsonArrayInsert(j, JsonString(""));
            j = JsonArrayInsert(j, JsonString(""));
            j = JsonArrayInsert(j, JsonString(""));
            j = JsonArrayInsert(j, JsonString(""));
            break;
    }
    return j;
}

// Number of real (non-empty) ingredients in this recipe
int WcaGetRecipeIngredientCount(int nId)
{
    json jIng = WcaGetRecipeIngredients(nId);
    int nCount = 0;
    int i;
    for(i = 0; i < WCA_SLOTS; i++)
    {
        if(JsonGetString(JsonArrayGet(jIng, i)) != "")
            nCount++;
    }
    return nCount;
}

string WcaGetRecipeResultResref(int nId)
{
    switch(nId)
    {
        case 0: return "wca_hex_bag";
        case 1: return "wca_curse_oil";
        case 2: return "wca_dark_fetish";
        case 3: return "wca_despair_vial";
        case 4: return "wca_ward_breaker";
    }
    return "";
}

int WcaGetRecipeTier(int nId)
{
    switch(nId)
    {
        case 0: case 1: return 1;
        case 2: case 3: return 2;
        case 4:         return 3;
    }
    return 1;
}

// Returns the recipe ID whose tome tag matches, or -1
int WcaGetRecipeIdByTomeTag(string sTag)
{
    if(sTag == WCA_TOME_0) return 0;
    if(sTag == WCA_TOME_1) return 1;
    if(sTag == WCA_TOME_2) return 2;
    if(sTag == WCA_TOME_3) return 3;
    if(sTag == WCA_TOME_4) return 4;
    return -1;
}

// ---- Slots helpers ----

json WcaInitSlots()
{
    json j = JsonArray();
    int i;
    for(i = 0; i < WCA_SLOTS; i++)
        j = JsonArrayInsert(j, JsonNull());
    return j;
}

json WcaGetSlots(object oPC)
{
    json j = GetLocalJson(oPC, WCA_LVAR_SLOTS);
    if(JsonGetType(j) != JSON_TYPE_ARRAY)
        j = WcaInitSlots();
    return j;
}

// Returns how many slots are filled
int WcaCountFilledSlots(json jSlots)
{
    int nFilled = 0;
    int i;
    for(i = 0; i < WCA_SLOTS; i++)
    {
        if(JsonGetType(JsonArrayGet(jSlots, i)) != JSON_TYPE_NULL)
            nFilled++;
    }
    return nFilled;
}

// Returns TRUE if slots contain exactly the ingredients required by nRecipeId (order-independent)
int WcaIngredientsMatch(json jSlots, int nRecipeId)
{
    json jRequired = WcaGetRecipeIngredients(nRecipeId);

    // Count required tags
    string sTags[4];
    int nReqCount = 0;
    int i;
    for(i = 0; i < WCA_SLOTS; i++)
    {
        string sReq = JsonGetString(JsonArrayGet(jRequired, i));
        if(sReq != "")
        {
            sTags[nReqCount] = sReq;
            nReqCount++;
        }
    }

    // Count placed tags (non-null slots)
    string sPlaced[4];
    int nPlacedCount = 0;
    for(i = 0; i < WCA_SLOTS; i++)
    {
        json jSlot = JsonArrayGet(jSlots, i);
        if(JsonGetType(jSlot) != JSON_TYPE_NULL)
        {
            sPlaced[nPlacedCount] = JsonGetString(JsonObjectGet(jSlot, "tag"));
            nPlacedCount++;
        }
    }

    if(nPlacedCount != nReqCount) return FALSE;

    // Every required tag must be present in placed (consume matched)
    int bUsed[4];
    int r;
    for(r = 0; r < nReqCount; r++)
    {
        int bFound = FALSE;
        int p;
        for(p = 0; p < nPlacedCount; p++)
        {
            if(!bUsed[p] && sPlaced[p] == sTags[r])
            {
                bUsed[p] = TRUE;
                bFound = TRUE;
                break;
            }
        }
        if(!bFound) return FALSE;
    }
    return TRUE;
}

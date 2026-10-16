// lib_syn_def.nss — Szynkarz: constants, recipes, ingredient helpers

#include "lib_nui"
#include "sql_syn"

// Forward declarations (defined in lib_syn.nss)
void SynOpenWindow(object oPC);
void SynFeedRecipesGroup(object oPC, int nToken);
void SynFeedBrewGroup(object oPC, int nToken);
void SynFeedCellarGroup(object oPC, int nToken);
void SynUpdateIntoxBar(object oPC, int nToken, int nLevel);

// ----------------------------------------------------------------
// Window / bind / button IDs
// ----------------------------------------------------------------

const string SYN_WINDOW          = "SYN_MAIN";
const string SYN_EV_SCRIPT       = "lib_syn_ev";
const string SYN_WIN_GEOM        = "syn_win_geom";

const string SYN_CONTENT_GROUP   = "syn_content";      // NuiId of swappable group

// Tab strip buttons
const string SYN_BTN_TAB_REC     = "syn_tab_rec";
const string SYN_BTN_TAB_BREW    = "syn_tab_brew";
const string SYN_BTN_TAB_CEL     = "syn_tab_cel";
const string SYN_BTN_CLOSE       = "syn_btn_close";

// Intox bar (always visible at bottom of window)
const string SYN_BIND_INTOX_LBL  = "syn_intox_lbl";   // "Trzeźwy" / "Pijany" etc.
const string SYN_BIND_INTOX_VAL  = "syn_intox_val";   // float 0.0-1.0 for progress bar
const string SYN_BIND_INTOX_COL  = "syn_intox_col";   // NuiColor JSON

// Recipes tab
const string SYN_BTN_REC_ROW     = "syn_rec_row";
const string SYN_BIND_REC_NAMES  = "syn_rec_names";
const string SYN_BIND_REC_ENC    = "syn_rec_enc";
const string SYN_BIND_DET_NAME   = "syn_det_name";
const string SYN_BIND_DET_FLAV   = "syn_det_flav";
const string SYN_BIND_DET_INGS   = "syn_det_ings";
const string SYN_BIND_DET_EFFS   = "syn_det_effs";
const string SYN_BIND_DET_INTOX  = "syn_det_intox";

// Brew tab
const string SYN_BIND_BREW_NAME  = "syn_brew_name";
const string SYN_BIND_BREW_LINES = "syn_brew_lines";  // ingredient status rows label
const string SYN_BIND_BREW_ENA   = "syn_brew_ena";    // bool: brew button enabled
const string SYN_BTN_BREW        = "syn_btn_brew";

// Cellar tab
const string SYN_BTN_CEL_ROW     = "syn_cel_row";
const string SYN_BIND_CEL_NAMES  = "syn_cel_names";
const string SYN_BIND_CEL_QTYS   = "syn_cel_qtys";
const string SYN_BIND_CEL_ENC    = "syn_cel_enc";
const string SYN_BTN_DRINK       = "syn_btn_drink";
const string SYN_BIND_DRINK_ENA  = "syn_drink_ena";

// LVARs on PC
const string SYN_LVAR_SEL_REC    = "SYN_SEL_REC";     // selected recipe id (−1 = none)
const string SYN_LVAR_SEL_CEL_ID = "SYN_SEL_CEL_ID";  // selected cellar row id (0 = none)
const string SYN_LVAR_SEL_CEL_RI = "SYN_SEL_CEL_RI";  // recipe_id of selected cellar row
const string SYN_LVAR_HB_TICK    = "SYN_HB_TICK";     // heartbeat counter
const string SYN_LVAR_INTOX_THR  = "SYN_INTOX_THR";   // last applied threshold (0-5)
const string SYN_LVAR_ACTIVE_TAB = "SYN_ACTIVE_TAB";  // 0=recipes 1=brew 2=cellar

// ----------------------------------------------------------------
// Intox thresholds and decay
// ----------------------------------------------------------------

const int SYN_INTOX_TIPSY        = 10;   // lekko wstawiony
const int SYN_INTOX_DRUNK        = 30;   // pijany
const int SYN_INTOX_HEAVY        = 55;   // mocno pijany
const int SYN_INTOX_SEVERE       = 75;   // totalnie pijany
const int SYN_INTOX_BLACKOUT     = 90;   // nieprzytomny

const int SYN_HB_DECAY_EVERY     = 5;    // decay 1 point every N heartbeats (≈30 s)

// ----------------------------------------------------------------
// Recipe IDs
// ----------------------------------------------------------------

const int SYN_REC_ALE            = 0;
const int SYN_REC_GRAVEDIGGER    = 1;
const int SYN_REC_GRAVE_MEAD     = 2;
const int SYN_REC_BLOOD_WINE     = 3;
const int SYN_REC_WRAITHWATER    = 4;
const int SYN_REC_IRON_BREW      = 5;
const int SYN_REC_SPIDER_GIN     = 6;
const int SYN_REC_WARLOCK_VOD    = 7;
const int SYN_REC_COUNT          = 8;

// ----------------------------------------------------------------
// Ingredient item tags
// ----------------------------------------------------------------

const string SYN_ING_HOP         = "syn_hop";
const string SYN_ING_BARLEY      = "syn_barley";
const string SYN_ING_MIDNIGHT    = "syn_midnight";
const string SYN_ING_HONEY       = "syn_honey";
const string SYN_ING_WORMWOOD    = "syn_wormwood";
const string SYN_ING_BONE_DUST   = "syn_bone_dust";
const string SYN_ING_GRAPES      = "syn_grapes";
const string SYN_ING_BLOOD       = "syn_blood";
const string SYN_ING_GHOST_ESS   = "syn_ghost_ess";
const string SYN_ING_MOONWATER   = "syn_moonwater";
const string SYN_ING_IRON_FIL    = "syn_iron_fil";
const string SYN_ING_CINDER      = "syn_cinder";
const string SYN_ING_SPIDER_VEN  = "syn_spider_ven";
const string SYN_ING_ARCANE_CRY  = "syn_arcane_cry";

// ----------------------------------------------------------------
// Recipe metadata
// ----------------------------------------------------------------

string SynRecipeName(int nId)
{
    switch(nId)
    {
        case SYN_REC_ALE:         return "Karczmarskie Piwo";
        case SYN_REC_GRAVEDIGGER: return "Gorzałka Grabacza";
        case SYN_REC_GRAVE_MEAD:  return "Miód Grobowy";
        case SYN_REC_BLOOD_WINE:  return "Wino Krwi";
        case SYN_REC_WRAITHWATER: return "Woda Zjaw";
        case SYN_REC_IRON_BREW:   return "Żelazny Napar";
        case SYN_REC_SPIDER_GIN:  return "Dżin Pająka";
        case SYN_REC_WARLOCK_VOD: return "Wódka Czarnoksiężnika";
    }
    return "Nieznana receptura";
}

string SynRecipeFlavor(int nId)
{
    switch(nId)
    {
        case SYN_REC_ALE:
            return "Cierpkie piwo z karczemnych beczek. Pachnie pleśnią i starym drewnem."
                 + " Rozgrzewa żołądek, koi nerwy przed bitwą.";
        case SYN_REC_GRAVEDIGGER:
            return "Mocna gorzała destylowana przy blasku pochodni na cmentarzu."
                 + " Grabarze twierdzą, że chroni przed zimnem — i przed strachem.";
        case SYN_REC_GRAVE_MEAD:
            return "Miód warzony w kryptach, fermentowany miesiącami wśród kości."
                 + " Słodkawy, z gorzkawym posmakiem prochu. Martwe pszczoły nigdy nie przestają pracować.";
        case SYN_REC_BLOOD_WINE:
            return "Wino wzbogacone kroplą bitewnej krwi. Wzmacnia i pobudza łowieckie instynkty."
                 + " Nie pytaj, czyja to krew.";
        case SYN_REC_WRAITHWATER:
            return "Przezroczysta ciecz, jakby woda — ale chłodna jak śmierć."
                 + " Esencja zaklętej zjawy schwytanej w flaszkę. Sprawia, że cień wyprzedza ciało.";
        case SYN_REC_IRON_BREW:
            return "Krasnoludzkiej tradycji napar — gorzki od opiłków żelaza, piekący jak kuźnia."
                 + " Nikt nie wie, czy smakuje, czy tylko tak strasznie boli.";
        case SYN_REC_SPIDER_GIN:
            return "Destylat z jadu pająka, rozrzedzony wodą księżycową."
                 + " Trucizna i antidotum w jednym. Mróz w żyłach.";
        case SYN_REC_WARLOCK_VOD:
            return "Czysta jak kryształ, ale w środku tańczą niebieskie iskry."
                 + " Czarownicy dodają kryształ arkanistyczny do alembika i milczą o tym, co widzą w dymie.";
    }
    return "";
}

string SynRecipeEffects(int nId)
{
    switch(nId)
    {
        case SYN_REC_ALE:         return "+1 STR, -1 DEX, +1 CHA, +5 max HP (10 min)";
        case SYN_REC_GRAVEDIGGER: return "+2 STR, -2 DEX, odporność na zimno 5/- (10 min)";
        case SYN_REC_GRAVE_MEAD:  return "Odporność na Strach, +3 do rzutów obronnych vs. nieumarli (15 min)";
        case SYN_REC_BLOOD_WINE:  return "+1 do ataku vs. żywe istoty, regeneracja 2 PZ po zabiciu (5 min)";
        case SYN_REC_WRAITHWATER: return "Niewidzialność częściowa 25% (5 min), -4 WIS";
        case SYN_REC_IRON_BREW:   return "+2 CON, odporność na cięcie 5/- (10 min), -1 INT";
        case SYN_REC_SPIDER_GIN:  return "Pełna odporność na trucizny (30 min), +2 DEX";
        case SYN_REC_WARLOCK_VOD: return "+1 poziom rzucającego (5 min), losowe przesunięcie magiczne";
    }
    return "";
}

int SynRecipeIntox(int nId)
{
    switch(nId)
    {
        case SYN_REC_ALE:         return 10;
        case SYN_REC_GRAVEDIGGER: return 20;
        case SYN_REC_GRAVE_MEAD:  return 15;
        case SYN_REC_BLOOD_WINE:  return 10;
        case SYN_REC_WRAITHWATER: return 30;
        case SYN_REC_IRON_BREW:   return 20;
        case SYN_REC_SPIDER_GIN:  return 20;
        case SYN_REC_WARLOCK_VOD: return 25;
    }
    return 10;
}

// ----------------------------------------------------------------
// Ingredient list helpers
// ----------------------------------------------------------------

json SynMakeIng(string sTag, int nQty, string sName)
{
    json j = JsonObject();
    j = JsonObjectSet(j, "tag",  JsonString(sTag));
    j = JsonObjectSet(j, "qty",  JsonInt(nQty));
    j = JsonObjectSet(j, "name", JsonString(sName));
    return j;
}

// Returns JsonArray of {tag, qty, name} for the recipe
json SynGetRecipeIngredients(int nId)
{
    json jList = JsonArray();
    switch(nId)
    {
        case SYN_REC_ALE:
            jList = JsonArrayInsert(jList, SynMakeIng(SYN_ING_HOP,       2, "Chmiel"));
            jList = JsonArrayInsert(jList, SynMakeIng(SYN_ING_BARLEY,    1, "Słód Jęczmienny"));
            break;
        case SYN_REC_GRAVEDIGGER:
            jList = JsonArrayInsert(jList, SynMakeIng(SYN_ING_BARLEY,    1, "Słód Jęczmienny"));
            jList = JsonArrayInsert(jList, SynMakeIng(SYN_ING_MIDNIGHT,  1, "Korzeń Północy"));
            break;
        case SYN_REC_GRAVE_MEAD:
            jList = JsonArrayInsert(jList, SynMakeIng(SYN_ING_HONEY,     1, "Miód Dzikich Pszczół"));
            jList = JsonArrayInsert(jList, SynMakeIng(SYN_ING_WORMWOOD,  1, "Piołun"));
            jList = JsonArrayInsert(jList, SynMakeIng(SYN_ING_BONE_DUST, 1, "Proch Kostny"));
            break;
        case SYN_REC_BLOOD_WINE:
            jList = JsonArrayInsert(jList, SynMakeIng(SYN_ING_GRAPES,    2, "Czarne Winogrona"));
            jList = JsonArrayInsert(jList, SynMakeIng(SYN_ING_BLOOD,     1, "Świeża Krew"));
            break;
        case SYN_REC_WRAITHWATER:
            jList = JsonArrayInsert(jList, SynMakeIng(SYN_ING_GHOST_ESS, 1, "Esencja Zjaw"));
            jList = JsonArrayInsert(jList, SynMakeIng(SYN_ING_MOONWATER, 1, "Woda Księżycowa"));
            break;
        case SYN_REC_IRON_BREW:
            jList = JsonArrayInsert(jList, SynMakeIng(SYN_ING_IRON_FIL,  1, "Opiłki Żelaza"));
            jList = JsonArrayInsert(jList, SynMakeIng(SYN_ING_BARLEY,    1, "Słód Jęczmienny"));
            jList = JsonArrayInsert(jList, SynMakeIng(SYN_ING_CINDER,    1, "Korzeń Żużlowy"));
            break;
        case SYN_REC_SPIDER_GIN:
            jList = JsonArrayInsert(jList, SynMakeIng(SYN_ING_SPIDER_VEN,1, "Jad Pająka"));
            jList = JsonArrayInsert(jList, SynMakeIng(SYN_ING_MOONWATER, 1, "Woda Księżycowa"));
            break;
        case SYN_REC_WARLOCK_VOD:
            jList = JsonArrayInsert(jList, SynMakeIng(SYN_ING_ARCANE_CRY,1, "Kryształ Arkanistyczny"));
            jList = JsonArrayInsert(jList, SynMakeIng(SYN_ING_BARLEY,    2, "Słód Jęczmienny"));
            break;
    }
    return jList;
}

// ----------------------------------------------------------------
// Inventory helpers
// ----------------------------------------------------------------

int SynCountInInventory(object oPC, string sTag)
{
    int nCount = 0;
    object oItem = GetFirstItemInInventory(oPC);
    while(GetIsObjectValid(oItem))
    {
        if(GetTag(oItem) == sTag)
            nCount += GetItemStackSize(oItem);
        oItem = GetNextItemInInventory(oPC);
    }
    return nCount;
}

int SynCanBrew(object oPC, int nRecipeId)
{
    json jIngs  = SynGetRecipeIngredients(nRecipeId);
    int  nCount = JsonGetLength(jIngs);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jIng   = JsonArrayGet(jIngs, i);
        string sTag = JsonGetString(JsonObjectGet(jIng, "tag"));
        int nReq    = JsonGetInt   (JsonObjectGet(jIng, "qty"));
        if(SynCountInInventory(oPC, sTag) < nReq)
            return FALSE;
    }
    return TRUE;
}

void SynConsumeIngredients(object oPC, int nRecipeId)
{
    json jIngs  = SynGetRecipeIngredients(nRecipeId);
    int  nCount = JsonGetLength(jIngs);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jIng    = JsonArrayGet(jIngs, i);
        string sTag  = JsonGetString(JsonObjectGet(jIng, "tag"));
        int nNeeded  = JsonGetInt   (JsonObjectGet(jIng, "qty"));
        int nLeft    = nNeeded;

        object oItem = GetFirstItemInInventory(oPC);
        while(GetIsObjectValid(oItem) && nLeft > 0)
        {
            if(GetTag(oItem) == sTag)
            {
                int nStack = GetItemStackSize(oItem);
                if(nStack <= nLeft)
                {
                    nLeft -= nStack;
                    DestroyObject(oItem);
                    oItem = GetFirstItemInInventory(oPC);
                }
                else
                {
                    SetItemStackSize(oItem, nStack - nLeft);
                    nLeft = 0;
                }
            }
            else
                oItem = GetNextItemInInventory(oPC);
        }
    }
}

// ----------------------------------------------------------------
// Intox display helpers
// ----------------------------------------------------------------

string SynIntoxLabel(int nLevel)
{
    if(nLevel >= SYN_INTOX_BLACKOUT) return "Nieprzytomny";
    if(nLevel >= SYN_INTOX_SEVERE)   return "Totalnie Pijany";
    if(nLevel >= SYN_INTOX_HEAVY)    return "Mocno Pijany";
    if(nLevel >= SYN_INTOX_DRUNK)    return "Pijany";
    if(nLevel >= SYN_INTOX_TIPSY)    return "Lekko Wstawiony";
    return "Trzeźwy";
}

// 0=sober 1=tipsy 2=drunk 3=heavy 4=severe 5=blackout
int SynIntoxThreshold(int nLevel)
{
    if(nLevel >= SYN_INTOX_BLACKOUT) return 5;
    if(nLevel >= SYN_INTOX_SEVERE)   return 4;
    if(nLevel >= SYN_INTOX_HEAVY)    return 3;
    if(nLevel >= SYN_INTOX_DRUNK)    return 2;
    if(nLevel >= SYN_INTOX_TIPSY)    return 1;
    return 0;
}

// Color: green → amber → red as intox rises
json SynIntoxColor(int nLevel)
{
    if(nLevel >= SYN_INTOX_BLACKOUT) return NuiColor(200,  20,  20);
    if(nLevel >= SYN_INTOX_SEVERE)   return NuiColor(220,  60,  40);
    if(nLevel >= SYN_INTOX_HEAVY)    return NuiColor(210, 140,  30);
    if(nLevel >= SYN_INTOX_DRUNK)    return NuiColor(200, 180,  40);
    if(nLevel >= SYN_INTOX_TIPSY)    return NuiColor(140, 200,  60);
    return NuiColor(80, 160, 80);
}

#include "lib_nui"

void AlchOpenWindow(object oPC);
void AlchFeedRecipeList(object oPC, int nToken);
void AlchFeedSlotLabels(object oPC, int nToken);
void AlchFeedRecipeInfo(object oPC, int nToken, int nRecipeId);
void AlchBrew(object oPC, int nToken);
void AlchHandleTargeting(object oPC);

// ----------------------------------------------------------------
// Window / event
// ----------------------------------------------------------------

const string ALCH_WINDOW        = "ALCH_WINDOW";
const string ALCH_EV_SCRIPT     = "lib_alch_ev";
const string ALCH_WIN_GEOM      = "alch_win_geom";

// ----------------------------------------------------------------
// Bind names
// ----------------------------------------------------------------

// Recipe list (listbox)
const string ALCH_BIND_RCP_LABEL  = "alch_rcp_label";
const string ALCH_BIND_RCP_ENA    = "alch_rcp_ena";
const string ALCH_BIND_RCP_COLOR  = "alch_rcp_color";
const string ALCH_BIND_RCP_ENC    = "alch_rcp_enc";

// Recipe detail panel (right side, top)
const string ALCH_BIND_RCP_NAME   = "alch_rcp_name";
const string ALCH_BIND_RCP_DESC   = "alch_rcp_desc";
const string ALCH_BIND_RCP_INGR1  = "alch_rcp_ingr1";
const string ALCH_BIND_RCP_INGR2  = "alch_rcp_ingr2";
const string ALCH_BIND_RCP_INGR3  = "alch_rcp_ingr3";
const string ALCH_BIND_RCP_DIFF   = "alch_rcp_diff";

// Workbench slots
const string ALCH_BIND_SLOT_LBL   = "alch_slot_lbl";   // + "1"/"2"/"3"
const string ALCH_BIND_SLOT_ENA   = "alch_slot_ena";   // + "1"/"2"/"3"
const string ALCH_BIND_SLOT_CLR   = "alch_slot_clr";   // + "1"/"2"/"3"

// Brew result feedback
const string ALCH_BIND_RESULT_LBL = "alch_result_lbl";
const string ALCH_BIND_RESULT_COL = "alch_result_col";

// Brew button
const string ALCH_BIND_BREW_ENA   = "alch_brew_ena";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string ALCH_BTN_CLOSE       = "alch_btn_close";
const string ALCH_BTN_RCP_ROW     = "alch_btn_rcp_row";  // + IntToString(id)
const string ALCH_BTN_SLOT        = "alch_btn_slot";     // + "1"/"2"/"3"
const string ALCH_BTN_SLOT_CLR    = "alch_btn_slotclr";  // + "1"/"2"/"3"
const string ALCH_BTN_BREW        = "alch_btn_brew";

// ----------------------------------------------------------------
// Local variables on PC
// ----------------------------------------------------------------

const string ALCH_LVAR_SEL_RCP    = "ALCH_SEL_RCP";       // selected recipe id (-1 = none)
const string ALCH_LVAR_SLOT1      = "ALCH_SLOT1_TAG";
const string ALCH_LVAR_SLOT2      = "ALCH_SLOT2_TAG";
const string ALCH_LVAR_SLOT3      = "ALCH_SLOT3_TAG";
const string ALCH_LVAR_SLOT1_OBJ  = "ALCH_SLOT1_OBJ";
const string ALCH_LVAR_SLOT2_OBJ  = "ALCH_SLOT2_OBJ";
const string ALCH_LVAR_SLOT3_OBJ  = "ALCH_SLOT3_OBJ";
const string ALCH_LVAR_TARGETING  = "ALCH_TARGETING_SLOT"; // 1/2/3 during targeting mode

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------

const float ALCH_W          = 680.0;
const float ALCH_H          = 500.0;
const int   ALCH_RCP_ROWS   = 10;

// ----------------------------------------------------------------
// Recipes
// Each recipe: id, name (PL), description (PL), 3 ingredient tags,
//              result resref, result stack count, difficulty (1-3).
// Ingredient tag "" = slot unused (recipe needs fewer than 3 items).
// Ingredient tags reference items that must exist in the HAK/module.
// ----------------------------------------------------------------

const int ALCH_RECIPE_COUNT = 10;

// Recipe IDs
const int ALCH_RCP_HEAL_MINOR   = 0;
const int ALCH_RCP_HEAL_MAJOR   = 1;
const int ALCH_RCP_ANTIDOTE     = 2;
const int ALCH_RCP_SHADOW_OIL   = 3;
const int ALCH_RCP_FIRE_RESIST  = 4;
const int ALCH_RCP_POISON_BLADE = 5;
const int ALCH_RCP_SPEED        = 6;
const int ALCH_RCP_STONESKIN    = 7;
const int ALCH_RCP_NECTAR_DEATH = 8;
const int ALCH_RCP_WITCHBLOOD   = 9;

// XP reward tables
const int ALCH_XP_BREW_BASE     = 25;   // per successful brew
const int ALCH_XP_DISCOVER      = 100;  // bonus for first discovery

string AlchGetRecipeName(int nId)
{
    switch(nId)
    {
        case ALCH_RCP_HEAL_MINOR:   return "Eliksir Uzdrowienia";
        case ALCH_RCP_HEAL_MAJOR:   return "Wielki Eliksir Uzdrowienia";
        case ALCH_RCP_ANTIDOTE:     return "Antidotum";
        case ALCH_RCP_SHADOW_OIL:   return "Olej Cienia";
        case ALCH_RCP_FIRE_RESIST:  return "Napar z Ognistego Korzenia";
        case ALCH_RCP_POISON_BLADE: return "Trucizna Ostrza";
        case ALCH_RCP_SPEED:        return "Esencja Przyspieszenia";
        case ALCH_RCP_STONESKIN:    return "Wywar z Kamiennej Skóry";
        case ALCH_RCP_NECTAR_DEATH: return "Nektar Umarłych";
        case ALCH_RCP_WITCHBLOOD:   return "Krew Czarownicy";
    }
    return "Nieznany przepis";
}

string AlchGetRecipeDesc(int nId)
{
    switch(nId)
    {
        case ALCH_RCP_HEAL_MINOR:
            return "Prosta nalewka z korzenia głogu i łez elfiego drzewa. Zamyka płytkie rany, lecz nie uleczy tych głębokich.";
        case ALCH_RCP_HEAL_MAJOR:
            return "Potężna mikstura warzona trzema składnikami przez noc pełni. Przywraca siły po nawet najcięższych zranieniach.";
        case ALCH_RCP_ANTIDOTE:
            return "Wywar z Rośliny Archanioła i sproszkowanego kamienia bezoarowego neutralizuje większość trucizn krążących w tym świecie.";
        case ALCH_RCP_SHADOW_OIL:
            return "Nakłada się na ostrze przed zasadzką. Zabija głos kroków i rozmazuje sylwetkę w mroku. Lubiany przez cichociemnych.";
        case ALCH_RCP_FIRE_RESIST:
            return "Alchemik z Krainy Ognia opisał ten przepis przed śmiercią na stosie. Skóra nim namaszczona odpiera żar przez krótką chwilę.";
        case ALCH_RCP_POISON_BLADE:
            return "Ciemnozielona maź z jadu żmii i soku krowiej pietruszki. Jedna dawka starczy na trzy ciosy. Nie liż palców.";
        case ALCH_RCP_SPEED:
            return "Destylat z serc wróbli i ziela kolibrzycy przyspiesza krew i myśl ponad miarę człowieka. Efekt trwa krótko, lecz bywa zbawczy.";
        case ALCH_RCP_STONESKIN:
            return "Mieszanka gliny z Głębinowych Kopalni i oleju kamiennego twardnieje na skórze jak zbroja. Ciężka, lecz skuteczna.";
        case ALCH_RCP_NECTAR_DEATH:
            return "Przepis zakazany przez Kościół Świętego Ognia. Wzmacnia nieumarłe siły w krwi. Pita przez żywego — pali od środka.";
        case ALCH_RCP_WITCHBLOOD:
            return "Z krwi wiedźmy, odrostów grzyba-cienia i pyłu z rozgniecionej runy. Wzmacnia magiczne zdolności na jedną walkę.";
    }
    return "";
}

// Ingredient tag — tag of the item object (GetTag). "" = slot empty.
string AlchGetRecipeIngr(int nId, int nSlot)
{
    switch(nId)
    {
        case ALCH_RCP_HEAL_MINOR:
            if(nSlot == 1) return "alch_herb_glasswort";
            if(nSlot == 2) return "alch_herb_elfwood";
            return "";
        case ALCH_RCP_HEAL_MAJOR:
            if(nSlot == 1) return "alch_herb_glasswort";
            if(nSlot == 2) return "alch_herb_elfwood";
            if(nSlot == 3) return "alch_herb_bloodmoss";
            return "";
        case ALCH_RCP_ANTIDOTE:
            if(nSlot == 1) return "alch_herb_archangel";
            if(nSlot == 2) return "alch_mineral_bezoar";
            return "";
        case ALCH_RCP_SHADOW_OIL:
            if(nSlot == 1) return "alch_herb_nightshade";
            if(nSlot == 2) return "alch_fat_shadowcat";
            return "";
        case ALCH_RCP_FIRE_RESIST:
            if(nSlot == 1) return "alch_herb_firecoral";
            if(nSlot == 2) return "alch_mineral_sulfur";
            if(nSlot == 3) return "alch_fat_salamander";
            return "";
        case ALCH_RCP_POISON_BLADE:
            if(nSlot == 1) return "alch_gland_viper";
            if(nSlot == 2) return "alch_herb_cowparsley";
            return "";
        case ALCH_RCP_SPEED:
            if(nSlot == 1) return "alch_gland_sparrowheart";
            if(nSlot == 2) return "alch_herb_colibrina";
            if(nSlot == 3) return "alch_mineral_quartz";
            return "";
        case ALCH_RCP_STONESKIN:
            if(nSlot == 1) return "alch_clay_deep";
            if(nSlot == 2) return "alch_oil_stone";
            return "";
        case ALCH_RCP_NECTAR_DEATH:
            if(nSlot == 1) return "alch_herb_deathcap";
            if(nSlot == 2) return "alch_blood_unholy";
            if(nSlot == 3) return "alch_mineral_ashbone";
            return "";
        case ALCH_RCP_WITCHBLOOD:
            if(nSlot == 1) return "alch_blood_witch";
            if(nSlot == 2) return "alch_shroom_shadow";
            if(nSlot == 3) return "alch_dust_rune";
            return "";
    }
    return "";
}

// Resref of result item (must exist in HAK or standard resources)
string AlchGetRecipeResultResref(int nId)
{
    switch(nId)
    {
        case ALCH_RCP_HEAL_MINOR:   return "alch_pot_heal_s";
        case ALCH_RCP_HEAL_MAJOR:   return "alch_pot_heal_l";
        case ALCH_RCP_ANTIDOTE:     return "alch_pot_antidote";
        case ALCH_RCP_SHADOW_OIL:   return "alch_oil_shadow";
        case ALCH_RCP_FIRE_RESIST:  return "alch_pot_fireres";
        case ALCH_RCP_POISON_BLADE: return "alch_oil_poison";
        case ALCH_RCP_SPEED:        return "alch_pot_speed";
        case ALCH_RCP_STONESKIN:    return "alch_pot_stone";
        case ALCH_RCP_NECTAR_DEATH: return "alch_pot_death";
        case ALCH_RCP_WITCHBLOOD:   return "alch_pot_witch";
    }
    return "";
}

int AlchGetRecipeDifficulty(int nId)
{
    switch(nId)
    {
        case ALCH_RCP_HEAL_MINOR:   return 1;
        case ALCH_RCP_HEAL_MAJOR:   return 2;
        case ALCH_RCP_ANTIDOTE:     return 1;
        case ALCH_RCP_SHADOW_OIL:   return 2;
        case ALCH_RCP_FIRE_RESIST:  return 3;
        case ALCH_RCP_POISON_BLADE: return 2;
        case ALCH_RCP_SPEED:        return 2;
        case ALCH_RCP_STONESKIN:    return 3;
        case ALCH_RCP_NECTAR_DEATH: return 3;
        case ALCH_RCP_WITCHBLOOD:   return 3;
    }
    return 1;
}

string AlchGetRecipeIngrLabel(int nId, int nSlot)
{
    string sTag = AlchGetRecipeIngr(nId, nSlot);
    if(sTag == "") return "—";
    return sTag;
}

string AlchDifficultyLabel(int nDiff)
{
    switch(nDiff)
    {
        case 1: return "Prosta";
        case 2: return "Złożona";
        case 3: return "Mistrzowska";
    }
    return "";
}

// Returns a sorted 3-element signature string used for recipe matching.
// Order of slots doesn't matter — we canonicalise by sorting.
string AlchBuildSignature(string sA, string sB, string sC)
{
    // Bubble-sort three strings
    string sTmp;
    if(sA > sB) { sTmp = sA; sA = sB; sB = sTmp; }
    if(sB > sC) { sTmp = sB; sB = sC; sC = sTmp; }
    if(sA > sB) { sTmp = sA; sA = sB; sB = sTmp; }
    return sA + "|" + sB + "|" + sC;
}

string AlchGetRecipeSignature(int nId)
{
    return AlchBuildSignature(
        AlchGetRecipeIngr(nId, 1),
        AlchGetRecipeIngr(nId, 2),
        AlchGetRecipeIngr(nId, 3));
}

// Returns recipe id whose canonical ingredient signature matches, or -1.
int AlchFindRecipeBySignature(string sSig)
{
    int i;
    for(i = 0; i < ALCH_RECIPE_COUNT; i++)
    {
        if(AlchGetRecipeSignature(i) == sSig)
            return i;
    }
    return -1;
}

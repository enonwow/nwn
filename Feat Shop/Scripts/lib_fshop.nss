//::///////////////////////////////////////////////////////////////
//:: lib_fshop — Feat Shop, główny UI (LIST VIEW, rewrite)
//::///////////////////////////////////////////////////////////////
//:: Prosty list-based renderer. Brak depth, brak SlotMap, brak
//:: arrowów, brak Variant B, brak harness'a, brak NWNX fallback.
//::
//:: Layout (1100x700):
//::   - Top bar (50px):  Buy/Sell + Search + Gold
//::   - Left bar (130px): 6 sekcji (Walka/Aktywne/Obrona/Magia/Klasowe/Inne)
//::   - Center (flex):    scrollowalna lista featow w sekcji
//::                       (ikona + przycisk z nazwa, ramka kolorem stanu)
//::   - Right (280px):    panel szczegolow (icon + nazwa + wymagania
//::                       + opis + Kup/Sprzedaj button)
//::
//:: Wymagania (prereqi) sa tekstem w panelu szczegolow zamiast
//:: graficznego drzewa. Polish chars uproszczone do ASCII bo
//:: poprzedni encoding rozjebal "Sprzedaz".
//::///////////////////////////////////////////////////////////////

#include "lib_nui"
#include "lib_fshop_st"


// Usunięto lokalny blok FS_* — używamy silnikowych stałych NUI_* z auto-loaded
// nw_inc_nui (dostępne projekt-wide). Lokalny NUI_ASPECT_FIT = 0 był BUGIEM —
// w NWN EE wartość 0 to NUI_ASPECT_FILL (rozciąga, deformuje), a NUI_ASPECT_FIT
// to wartość 1 (zachowuje proporcje, dodaje bandy).


// ===== Wymiary =====
const float FSHOP_W           = 1100.0;
const float FSHOP_H           = 760.0;
const float FSHOP_LEFT_W      = 130.0;
const float FSHOP_RIGHT_W     = 280.0;
const float FSHOP_TOP_H       = 50.0;
const float FSHOP_ICON_SIZE      = 32.0;  // ikona feata w main list + variant picker (standard NWN)
const float FSHOP_TREE_ICON_SIZE = 64.0;  // ikona feata w drzewie (większa, bo z mocnymi strzałkami)
const float FSHOP_TILE_SIZE      = 32.0;  // rozmiar arrow tile (lh/lv/chr/corner) — fixed by HAK
const float FSHOP_TREE_GAP    = 32.0;     // szerokosc spacer'a (poziomo) miedzy cellami tree
const float FSHOP_ROW_GAP     = 32.0;     // odstep pionowy miedzy wierszami tree
const int   FSHOP_ICONS_PER_ROW = 9;

// Geometria tree liczona inline z konstant powyzej:
//   cell krok poziomy = ICON_SIZE + TREE_GAP
//   cell krok pionowy = ICON_SIZE + ROW_GAP
//   tile center y     = (ICON_SIZE - TILE_SIZE) / 2  (lokalne y w spacerze)
//   corner end y      = tile center + TILE_SIZE      (start lv pod cornerem)

// Default ikona dla feat family rep (gdy gracz nie wybral konkretnego wariantu).
// Wzorzec z NWN level-up dialog: "Weapon Focus..." + generic shield icon.
// PODMIEN na resref jakiego chcesz uzyc dla rodzin (default = ife_charsel).
const string FSHOP_FAMILY_ICON_RESREF = "ife_charsel";
const string FSHOP_FAMILY_NAME_SUFFIX = "...";


// ===== ID i bindy (uzywane przez lib_fshop_ev — nie zmieniaj) =====
const string FSHOP_WIN_ID            = "FSHOP";

const string FSHOP_BTN_BUY           = "fs_buy";
const string FSHOP_BTN_SELL          = "fs_sell";
const string FSHOP_BIND_MODE_ENC_B   = "fs_mode_enc_b";
const string FSHOP_BIND_MODE_ENC_S   = "fs_mode_enc_s";

const string FSHOP_BTN_SEC_PRE       = "fs_sec_";
const string FSHOP_BIND_SEC_ENC_PRE  = "fs_sec_enc_";

const string FSHOP_BTN_FILTER_ACQ      = "fs_flt_acq";
const string FSHOP_BIND_FILTER_ACQ_ENC = "fs_flt_acq_enc";

const string FSHOP_BIND_SEARCH       = "fs_search";
const string FSHOP_BTN_SEARCH        = "fs_search_go";  // przycisk wykonania filtra (bez watch on type)

const string FSHOP_BTN_FEAT_PRE      = "fs_f_";
const string FSHOP_BIND_FEAT_ENC     = "fs_f_enc_";
const string FSHOP_BIND_FEAT_COL     = "fs_f_col_";

const string FSHOP_BIND_SEL_NAME     = "fs_sel_name";
const string FSHOP_BIND_SEL_DESC     = "fs_sel_desc";
const string FSHOP_BIND_SEL_ICON     = "fs_sel_icon";
const string FSHOP_BIND_SEL_COL      = "fs_sel_col";
const string FSHOP_BIND_BTN_LBL      = "fs_btn_lbl";
const string FSHOP_BIND_BTN_EN       = "fs_btn_en";
const string FSHOP_BIND_BTN_VIS      = "fs_btn_vis";
const string FSHOP_BTN_ACTION        = "fs_act";
const string FSHOP_BIND_GOLD         = "fs_gold";
const string FSHOP_BIND_TREE_BTN_EN  = "fs_tree_btn_en";  // enabled state buttona "Pokaz drzewo"
const string FSHOP_BIND_VAR_BTN_VIS  = "fs_var_btn_vis";  // visibility "Detale" — tylko gdy rodzina > 1
const string FSHOP_BIND_PANEL_VIS    = "fs_panel_vis";    // visibility header (icon+name+desc) — TRUE tylko gdy feat wybrany

const string FSHOP_BIND_GEOM         = "fs_geom";

// Tree window
const string FSHOP_TREE_WIN_ID       = "FSHOP_TREE";
const string FSHOP_BTN_TREE_OPEN     = "fs_tree_open";    // button w info panel main
const string FSHOP_BTN_VARIANTS      = "fs_variants";     // button "Detale" — variant picker
const string FSHOP_BTN_TREE_FEAT_PRE = "fst_";            // feaTy w tree window
const string FSHOP_BTN_TREE_REFOCUS  = "fst_refocus";     // button "Pokaz drzewo" w tree's right panel
const string FSHOP_BTN_TREE_BACK     = "fst_back";        // button "Wstecz" — pop history
const string FSHOP_BIND_TREE_GEOM    = "fst_geom";
const string FSHOP_BIND_TREE_TITLE   = "fst_title";
const string FSHOP_BIND_TREE_SEL_NAME = "fst_sel_name";
const string FSHOP_BIND_TREE_SEL_DESC = "fst_sel_desc";
const string FSHOP_BIND_TREE_SEL_ICON = "fst_sel_icon";
const string FSHOP_BIND_TREE_SEL_COL  = "fst_sel_col";

// Variant picker window — popup po kliknieciu "Detale" na rep feacie z rodziny
const string FSHOP_VAR_WIN_ID        = "FSHOP_VAR";
const string FSHOP_LVAR_VAR_TOKEN    = "FSHOP_VAR_TOKEN";
const string FSHOP_BTN_VAR_FEAT_PRE  = "fsv_";            // prefix przyciskow wariantow
const string FSHOP_BIND_VAR_GEOM     = "fsv_geom";


// ===== Local vars na PC =====
const string FSHOP_LVAR_TOKEN        = "FSHOP_TOKEN";
const string FSHOP_LVAR_MODE         = "FSHOP_MODE";
const string FSHOP_LVAR_SECTION      = "FSHOP_SECTION";
const string FSHOP_LVAR_SEL_FEAT     = "FSHOP_SEL_FEAT";
const string FSHOP_LVAR_SEL_MODE     = "FSHOP_SEL_MODE";    // 0=GENERIC (rep z rodziny), 1=SPECIFIC (uzytkownik wybral wariant)
const string FSHOP_LVAR_SEARCH       = "FSHOP_SEARCH";
const string FSHOP_LVAR_FILTER_ACQ   = "FSHOP_FILTER_ACQ";  // 1=pokaz tylko AVAILABLE
const string FSHOP_LVAR_STATES       = "FSHOP_STATES";
const string FSHOP_LVAR_SEC_EXPANDED = "FSHOP_SEC_EXPANDED";
const string FSHOP_LVAR_TREE_TOKEN   = "FSHOP_TREE_TOKEN";
const string FSHOP_LVAR_TREE_PANEL   = "FSHOP_TREE_PANEL";   // featId aktualnie wyswietlany w prawym panelu tree
const string FSHOP_LVAR_TREE_FOCUS   = "FSHOP_TREE_FOCUS";   // featId obecnego focusa drzewa (+1 offset, 0 = brak)
const string FSHOP_LVAR_TREE_F_SPEC  = "FSHOP_TREE_F_SPEC";  // 1 = focus to specific variant (ma parens w nazwie); 0 = standalone
const string FSHOP_LVAR_TREE_HISTORY = "FSHOP_TREE_HISTORY"; // JsonArray feat IDs — stack starych focusow (Pokaz drzewo navigation)

// Tryby
const int FSHOP_MODE_BUY  = 0;
const int FSHOP_MODE_SELL = 1;

// Tryby selekcji feata
const int FSHOP_SEL_MODE_GENERIC  = 0;
const int FSHOP_SEL_MODE_SPECIFIC = 1;


// ===== Tree arrow drawing helpers =====
// Wszystkie zwracaja zaktualizowane jDraws (insert NuiDrawListImage przy x,y).
// Tile size 32x32. Color suffix jest separately appended.
// nOrder: NUI_DRAW_LIST_ITEM_ORDER_BEFORE (-1) = behind widget content (default)
//         NUI_DRAW_LIST_ITEM_ORDER_AFTER (1) = on top of widget content
json FShopDrawTile(json jDraws, string sResRef, float fX, float fY, int nOrder = NUI_DRAW_LIST_ITEM_ORDER_BEFORE);
json FShopDrawLh(json jDraws, float fX, float fY, string sCol);
json FShopDrawLv(json jDraws, float fX, float fY, string sCol);
json FShopDrawChr(json jDraws, float fX, float fY, string sCol);
json FShopDrawCorner(json jDraws, float fX, float fY, string sCornerType, string sCol);


// ===== Forward declarations =====
void   CreateFShopWindow(object oPC, int nMode = -1, int nSection = -1);
void   DestroyFShopWindow(object oPC);
void   FeedFShopAll(object oPC, int nToken);
void   FeedFShopFeatStates(object oPC, int nToken, int nMode, int nSection, json jCache, json jSec);
void   FeedFShopInfoPanel(object oPC, int nToken);
void   FeedFShopSearch(object oPC, int nToken, string sQuery);

string FShopSectionName(int nSection);
string FShopGoldText(int nGold);
int    FShopMode(object oPC);
int    FShopSection(object oPC);
int    FShopSelectedFeat(object oPC);
void   FShopSetSelectedFeat(object oPC, int nFeatId);
json   FShopColorForState(int nState);
string FShopArrowSuffixForState(int nState);
string FShopBuildPrereqText(json jCache, json jFeat);
int    FShopHasTreeRelations(json jCache, int nFeatId, json jFeat);

json   BuildFShopRoot(object oPC, int nMode, int nSection, json jCache, json jSec, json jStates);
json   BuildFShopTopBar();
json   BuildFShopSectionBar();
json   BuildFShopFeatList(object oPC, int nMode, json jCache, json jSec, json jStates);
json   BuildFShopInfoPanel();
json   BuildFShopFeatHeader(string sIconBind, string sNameBind, string sColorBind, string sDescBind, float fDescH, float fWidth);

// Tree window (osobny popup pokazujacy drzewo wybranego feata)
void   CreateFShopTreeWindow(object oPC, int nFocusFeatId);
void   DestroyFShopTreeWindow(object oPC);

// Variant picker window (popup pokazujacy wszystkie warianty z rodziny)
void   CreateFShopVariantWindow(object oPC, int nRepFeatId);
void   DestroyFShopVariantWindow(object oPC);

// Aktualizuje right panel binds tree window'a do wyswietlania nFeatId.
// Uzywane przez tree feat click ORAZ Wstecz button (history pop).
// Spojny display (focus has spec → specific; inaczej → group rep).
void   FeedFShopTreePanel(object oPC, int nTreeToken, int nFeatId);

// Helpery rodziny variantow
string FShopGetNameBase(string sName);
json   FShopGetFamilyVariants(json jCache, int nFeatId, json jFeat);
int    FShopSelMode(object oPC);
void   FShopSetSelMode(object oPC, int nMode);
json   FShopGetFeatDisplayData(json jFeat);


// ===== State helpery =====

string FShopSectionName(int nSection)
{
    switch(nSection)
    {
        case 0: return "All";
        case 1: return "Combat";
        case 2: return "Active";
        case 3: return "Defense";
        case 4: return "Magic";
        case 5: return "Class";
        case 6: return "Other";
    }
    return "?";
}

string FShopGoldText(int nGold)
{
    return IntToString(nGold) + " gp";
}


// ===== Tree arrow drawing helpers =====

// Generic tile drawing — 32x32 at (x, y) z resref'em.
// nOrder: BEFORE (-1, default, behind widget) | AFTER (1, on top of widget content)
json FShopDrawTile(json jDraws, string sResRef, float fX, float fY, int nOrder = NUI_DRAW_LIST_ITEM_ORDER_BEFORE)
{
    return JsonArrayInsert(jDraws, NuiDrawListImage(JsonBool(TRUE),
        JsonString(sResRef),
        NuiRect(fX, fY, 32.0, 32.0), JsonInt(5),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE),
        nOrder, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
}

// Pozioma linia (─). Order BEFORE (default).
json FShopDrawLh(json jDraws, float fX, float fY, string sCol)
{
    return FShopDrawTile(jDraws, "ft_lh_" + sCol, fX, fY);
}

// Pionowa linia (│). Order BEFORE (behind).
json FShopDrawLv(json jDraws, float fX, float fY, string sCol)
{
    return FShopDrawTile(jDraws, "ft_lv_" + sCol, fX, fY, NUI_DRAW_LIST_ITEM_ORDER_BEFORE);
}

// Chevron / strzalka (>). Order BEFORE (default).
json FShopDrawChr(json jDraws, float fX, float fY, string sCol)
{
    return FShopDrawTile(jDraws, "ft_chr_" + sCol, fX, fY);
}

// Corner — sCornerType to "cbl"/"cbr"/"ctl"/"ctr". Order AFTER (na wierzchu).
json FShopDrawCorner(json jDraws, float fX, float fY, string sCornerType, string sCol)
{
    return FShopDrawTile(jDraws, "ft_" + sCornerType + "_" + sCol, fX, fY, NUI_DRAW_LIST_ITEM_ORDER_AFTER);
}

int FShopMode(object oPC) { return GetLocalInt(oPC, FSHOP_LVAR_MODE); }

int FShopSection(object oPC)
{
    // Storage: section + 1 (zeby 0 oznaczalo nieustawione → default Wszystkie).
    // 1=Wszystkie, 2=Walka, ..., 7=Inne.
    int n = GetLocalInt(oPC, FSHOP_LVAR_SECTION);
    if(n <= 0) return 0;            // niesetowane → Wszystkie
    int real = n - 1;
    if(real < 0 || real > 6) return 0;
    return real;
}

int FShopFilterAcq(object oPC)
{
    // Storage offset+1 (0=unset → default ON):
    //   0 = unset    → 1 (ON, default)
    //   1 = jawnie OFF → 0
    //   2 = jawnie ON  → 1
    int n = GetLocalInt(oPC, FSHOP_LVAR_FILTER_ACQ);
    if(n == 0) return 1;     // default ON
    return n - 1;             // 1→0 (OFF), 2→1 (ON)
}

int FShopSelectedFeat(object oPC)
{
    int n = GetLocalInt(oPC, FSHOP_LVAR_SEL_FEAT);
    if(n <= 0) return -1;
    return n - 1;
}

void FShopSetSelectedFeat(object oPC, int nFeatId)
{
    if(nFeatId < 0) DeleteLocalInt(oPC, FSHOP_LVAR_SEL_FEAT);
    else SetLocalInt(oPC, FSHOP_LVAR_SEL_FEAT, nFeatId + 1);
}

int FShopSelMode(object oPC)
{
    return GetLocalInt(oPC, FSHOP_LVAR_SEL_MODE);
}

void FShopSetSelMode(object oPC, int nMode)
{
    if(nMode == FSHOP_SEL_MODE_GENERIC) DeleteLocalInt(oPC, FSHOP_LVAR_SEL_MODE);
    else SetLocalInt(oPC, FSHOP_LVAR_SEL_MODE, nMode);
}

// Wyciaga base name z featu z parens: "Weapon Focus (club)" -> "Weapon Focus".
// Zwraca "" jezeli brak parens (standalone feat bez wariantow).
string FShopGetNameBase(string sName)
{
    int nParen = FindSubString(sName, "(");
    if(nParen <= 0) return "";
    string sBase = GetSubString(sName, 0, nParen);
    int nBL = GetStringLength(sBase);
    if(nBL > 0 && GetSubString(sBase, nBL - 1, 1) == " ")
        sBase = GetSubString(sBase, 0, nBL - 1);
    return sBase;
}

// Zwraca JsonArray feat IDs wszystkich wariantow z tej samej rodziny co nFeatId
// (wlacznie z nim samym). Match po MASTERFEAT (gdy >0) lub po prefix nazwy przed "(".
// Pusta tablica = feat nie ma wariantow (standalone).
json FShopGetFamilyVariants(json jCache, int nFeatId, json jFeat)
{
    json jResult = JsonArray();
    int nMf = JsonGetInt(JsonObjectGet(jFeat, FK_MF));
    string sBase = "";
    // UWAGA: nMf == 0 to VALID masterfeat (ImprovedCritical)! Tylko -1 = brak.
    if(nMf < 0)
    {
        sBase = FShopGetNameBase(JsonGetString(JsonObjectGet(jFeat, FK_NAME)));
        if(sBase == "") return jResult;  // standalone, brak wariantow
    }

    json jKeys = JsonObjectKeys(jCache);
    int nLen = JsonGetLength(jKeys);
    int i;
    for(i = 0; i < nLen; i++)
    {
        string sK = JsonGetString(JsonArrayGet(jKeys, i));
        int nOther = StringToInt(sK);
        json jOF = JsonObjectGet(jCache, sK);
        if(JsonGetType(jOF) != JSON_TYPE_OBJECT) continue;
        int bMatch = FALSE;
        if(nMf >= 0)
        {
            int nMfO = JsonGetInt(JsonObjectGet(jOF, FK_MF));
            if(nMfO == nMf) bMatch = TRUE;
        }
        else
        {
            string sNameO = JsonGetString(JsonObjectGet(jOF, FK_NAME));
            string sBaseO = FShopGetNameBase(sNameO);
            if(sBaseO != "" && sBaseO == sBase) bMatch = TRUE;
        }
        if(bMatch) jResult = JsonArrayInsert(jResult, JsonInt(nOther));
    }
    return jResult;
}

// Zwraca {n, d, i} display data dla feata. Gdy MF > 0 i masterfeats.2da ma
// dane — zwraca grupe z "..." suffix. Inaczej feat data unchanged.
//
// Uzywane wszedzie gdzie chcemy pokazac family rep zamiast specific variant
// (np. tree window nodes, list, info panel GENERIC view).
json FShopGetFeatDisplayData(json jFeat)
{
    json jOut = JsonObject();
    string sN = JsonGetString(JsonObjectGet(jFeat, FK_NAME));
    string sD = JsonGetString(JsonObjectGet(jFeat, FK_DESC));
    string sI = JsonGetString(JsonObjectGet(jFeat, FK_ICON));

    int nMf = JsonGetInt(JsonObjectGet(jFeat, FK_MF));
    if(nMf >= 0)   // 0 = VALID (ImprovedCritical), -1 = brak
    {
        json jGrp = FShopGetMasterfeatData(nMf);
        if(JsonGetType(jGrp) == JSON_TYPE_OBJECT)
        {
            string sGN = "";
            string sGD = "";
            string sGI = "";
            json jN = JsonObjectGet(jGrp, FK_MF_NAME);
            json jD = JsonObjectGet(jGrp, FK_MF_DESC);
            json jI = JsonObjectGet(jGrp, FK_MF_ICON);
            if(JsonGetType(jN) == JSON_TYPE_STRING) sGN = JsonGetString(jN);
            if(JsonGetType(jD) == JSON_TYPE_STRING) sGD = JsonGetString(jD);
            if(JsonGetType(jI) == JSON_TYPE_STRING) sGI = JsonGetString(jI);

            // Nazwa: priorytet group → fallback strip "(weapon)" z featu
            if(sGN != "")
            {
                sN = sGN + FSHOP_FAMILY_NAME_SUFFIX;
            }
            else
            {
                string sBase = FShopGetNameBase(sN);
                if(sBase != "") sN = sBase + FSHOP_FAMILY_NAME_SUFFIX;
            }

            if(sGD != "") sD = sGD;
            if(sGI != "") sI = sGI;   // brak group icon → zostaje feat icon
        }
    }

    jOut = JsonObjectSet(jOut, FK_MF_NAME, JsonString(sN));
    jOut = JsonObjectSet(jOut, FK_MF_DESC, JsonString(sD));
    jOut = JsonObjectSet(jOut, FK_MF_ICON, JsonString(sI));
    return jOut;
}

json FShopColorForState(int nState)
{
    switch(nState)
    {
        case FSHOP_ST_OWNED:         return NuiColor(218, 165, 32, 255);
        case FSHOP_ST_AVAILABLE:     return NuiColor(80, 220, 100, 255);
        case FSHOP_ST_LOCKED_PREREQ: return NuiColor(150, 150, 150, 255);
        case FSHOP_ST_LOCKED_STATS:  return NuiColor(220, 60, 60, 255);
    }
    return NuiColor(255, 255, 255, 255);
}

// Suffix dla tile arrow (ft_lh_X, ft_chr_X itp.) wg stanu feata.
// UWAGA: konwencja nazewnictwa textur w HAK:
//   _g = gold (zolty)   = OWNED
//   _v = verde (zielony) = AVAILABLE
//   _a = ash (szary)    = LOCKED_PREREQ
//   _r = red (czerwony) = LOCKED_STATS
string FShopArrowSuffixForState(int nState)
{
    switch(nState)
    {
        case FSHOP_ST_OWNED:         return "g";
        case FSHOP_ST_AVAILABLE:     return "v";
        case FSHOP_ST_LOCKED_PREREQ: return "a";
        case FSHOP_ST_LOCKED_STATS:  return "r";
    }
    return "a";  // default = szary (ash)
}


// ===== Build prereq text dla info panela =====
//
// Zwraca tekst typu:
//   "Wymaga: Power Attack, Cleave"
//   "Lub jeden z: Combat Casting, Spell Focus"
//   "Wymagania: STR 13 BAB +4 Poziom 6"
// Lub "Brak wymagan." jesli feat nie ma zadnych.

string FShopBuildPrereqText(json jCache, json jFeat)
{
    string sAnd = "";   // PREREQFEAT1 + PREREQFEAT2
    string sOr  = "";   // OrReqFeat0..4
    string sStt = "";   // statsy + level + skille

    int p1 = JsonGetInt(JsonObjectGet(jFeat, FK_P1));
    int p2 = JsonGetInt(JsonObjectGet(jFeat, FK_P2));

    if(p1 >= 0)
    {
        json jP = JsonObjectGet(jCache, IntToString(p1));
        if(JsonGetType(jP) == JSON_TYPE_OBJECT)
            sAnd += JsonGetString(JsonObjectGet(jP, FK_NAME));
    }
    if(p2 >= 0)
    {
        json jP = JsonObjectGet(jCache, IntToString(p2));
        if(JsonGetType(jP) == JSON_TYPE_OBJECT)
        {
            if(sAnd != "") sAnd += ", ";
            sAnd += JsonGetString(JsonObjectGet(jP, FK_NAME));
        }
    }

    json jOr = JsonObjectGet(jFeat, FK_OR);
    int nOrLen = JsonGetLength(jOr);
    int oi;
    int bFirst = TRUE;
    for(oi = 0; oi < nOrLen; oi++)
    {
        int nO = JsonGetInt(JsonArrayGet(jOr, oi));
        json jP = JsonObjectGet(jCache, IntToString(nO));
        if(JsonGetType(jP) != JSON_TYPE_OBJECT) continue;
        if(!bFirst) sOr += ", ";
        sOr += JsonGetString(JsonObjectGet(jP, FK_NAME));
        bFirst = FALSE;
    }

    int v;
    v = JsonGetInt(JsonObjectGet(jFeat, FK_MIN_STR));   if(v > 0) sStt += "STR " + IntToString(v) + " ";
    v = JsonGetInt(JsonObjectGet(jFeat, FK_MIN_DEX));   if(v > 0) sStt += "DEX " + IntToString(v) + " ";
    v = JsonGetInt(JsonObjectGet(jFeat, FK_MIN_CON));   if(v > 0) sStt += "CON " + IntToString(v) + " ";
    v = JsonGetInt(JsonObjectGet(jFeat, FK_MIN_INT));   if(v > 0) sStt += "INT " + IntToString(v) + " ";
    v = JsonGetInt(JsonObjectGet(jFeat, FK_MIN_WIS));   if(v > 0) sStt += "WIS " + IntToString(v) + " ";
    v = JsonGetInt(JsonObjectGet(jFeat, FK_MIN_CHA));   if(v > 0) sStt += "CHA " + IntToString(v) + " ";
    v = JsonGetInt(JsonObjectGet(jFeat, FK_MIN_BAB));   if(v > 0) sStt += "BAB +" + IntToString(v) + " ";
    v = JsonGetInt(JsonObjectGet(jFeat, FK_MIN_LEVEL)); if(v > 0) sStt += "Level " + IntToString(v) + " ";
    v = JsonGetInt(JsonObjectGet(jFeat, FK_EPIC));      if(v == 1) sStt += "EPIC ";

    string sOut = "";
    if(sAnd != "") sOut += "Requires: " + sAnd;
    if(sOr  != "") { if(sOut != "") sOut += "\n"; sOut += "One of: " + sOr; }
    if(sStt != "") { if(sOut != "") sOut += "\n"; sOut += "Requirements: " + sStt; }

    if(sOut == "") return "No requirements.";
    return sOut;
}


// Sprawdza czy feat ma JAKIES powiazania w drzewie (rodzic LUB dziecko).
// Uzywane do enabled state buttona "Pokaz drzewo" — nie ma sensu otwierac
// drzewa dla featu izolowanego.
//
// Cost: O(1) dla feaTow ktore maja prereqi (early exit), O(N) dla samotnych.
int FShopHasTreeRelations(json jCache, int nFeatId, json jFeat)
{
    // Has parent? (PREREQFEAT1/2)
    int p1 = JsonGetInt(JsonObjectGet(jFeat, FK_P1));
    if(p1 >= 0 && JsonGetType(JsonObjectGet(jCache, IntToString(p1))) == JSON_TYPE_OBJECT) return TRUE;
    int p2 = JsonGetInt(JsonObjectGet(jFeat, FK_P2));
    if(p2 >= 0 && JsonGetType(JsonObjectGet(jCache, IntToString(p2))) == JSON_TYPE_OBJECT) return TRUE;

    // Has parent? (OrReqFeat)
    json jOr = JsonObjectGet(jFeat, FK_OR);
    int nOrLen = JsonGetLength(jOr);
    int oi;
    for(oi = 0; oi < nOrLen; oi++)
    {
        int nO = JsonGetInt(JsonArrayGet(jOr, oi));
        if(nO >= 0 && JsonGetType(JsonObjectGet(jCache, IntToString(nO))) == JSON_TYPE_OBJECT) return TRUE;
    }

    // Has child? Skanujemy cache — drogie ale tylko dla feaTow bez rodzicow
    json jKeys = JsonObjectKeys(jCache);
    int nLen = JsonGetLength(jKeys);
    int i;
    for(i = 0; i < nLen; i++)
    {
        string sKey = JsonGetString(JsonArrayGet(jKeys, i));
        json jOther = JsonObjectGet(jCache, sKey);
        int op1 = JsonGetInt(JsonObjectGet(jOther, FK_P1));
        if(op1 == nFeatId) return TRUE;
        int op2 = JsonGetInt(JsonObjectGet(jOther, FK_P2));
        if(op2 == nFeatId) return TRUE;
        json jOOr = JsonObjectGet(jOther, FK_OR);
        int nOOrLen = JsonGetLength(jOOr);
        int ooi;
        for(ooi = 0; ooi < nOOrLen; ooi++)
        {
            if(JsonGetInt(JsonArrayGet(jOOr, ooi)) == nFeatId) return TRUE;
        }
    }
    return FALSE;
}


// ===== Build pieces =====

json BuildFShopTopBar()
{
    json jChildren = JsonArray();

    json jBuy = NuiButton(JsonString("Buy"));
    jBuy = NuiId(jBuy, FSHOP_BTN_BUY);
    jBuy = NuiWidth(jBuy, 100.0);
    jBuy = NuiHeight(jBuy, FSHOP_TOP_H - 10.0);
    jBuy = NuiEncouraged(jBuy, NuiBind(FSHOP_BIND_MODE_ENC_B));
    jChildren = JsonArrayInsert(jChildren, jBuy);

    json jSell = NuiButton(JsonString("Sell"));
    jSell = NuiId(jSell, FSHOP_BTN_SELL);
    jSell = NuiWidth(jSell, 100.0);
    jSell = NuiHeight(jSell, FSHOP_TOP_H - 10.0);
    jSell = NuiEncouraged(jSell, NuiBind(FSHOP_BIND_MODE_ENC_S));
    jChildren = JsonArrayInsert(jChildren, jSell);

    jChildren = JsonArrayInsert(jChildren, NuiSpacer());

    json jSearch = NuiTextEdit(JsonString("Search..."), NuiBind(FSHOP_BIND_SEARCH), 64, FALSE);
    jSearch = NuiWidth(jSearch, 200.0);
    jSearch = NuiHeight(jSearch, FSHOP_TOP_H - 10.0);
    jChildren = JsonArrayInsert(jChildren, jSearch);

    // Przycisk "Szukaj" — filter triggered eksplicytnie (bez watch on type),
    // bo rebuild okna na kazdy znak jest zbyt drogi dla NUI przy duzym datasecie
    json jSearchBtn = NuiButton(JsonString("Search"));
    jSearchBtn = NuiId(jSearchBtn, FSHOP_BTN_SEARCH);
    jSearchBtn = NuiWidth(jSearchBtn, 80.0);
    jSearchBtn = NuiHeight(jSearchBtn, FSHOP_TOP_H - 10.0);
    jChildren = JsonArrayInsert(jChildren, jSearchBtn);

    json jBar = NuiRow(jChildren);
    jBar = NuiHeight(jBar, FSHOP_TOP_H);
    return jBar;
}

json BuildFShopSectionBar()
{
    json jChildren = JsonArray();
    int s;
    for(s = 0; s <= 6; s++)  // 0=Wszystkie, 1..6=oryginalne sekcje
    {
        json jBtn = NuiButton(JsonString(FShopSectionName(s)));
        jBtn = NuiId(jBtn, FSHOP_BTN_SEC_PRE + IntToString(s));
        jBtn = NuiWidth(jBtn, 130.0);
        jBtn = NuiHeight(jBtn, FSHOP_TOP_H - 10.0);
        jBtn = NuiEncouraged(jBtn, NuiBind(FSHOP_BIND_SEC_ENC_PRE + IntToString(s)));
        jChildren = JsonArrayInsert(jChildren, jBtn);
    }

    // Toggle filter — pokaz tylko AVAILABLE feaTy
    json jAcqBtn = NuiButton(JsonString("Available"));
    jAcqBtn = NuiId(jAcqBtn, FSHOP_BTN_FILTER_ACQ);
    jAcqBtn = NuiWidth(jAcqBtn, 130.0);
    jAcqBtn = NuiHeight(jAcqBtn, FSHOP_TOP_H - 10.0);
    jAcqBtn = NuiEncouraged(jAcqBtn, NuiBind(FSHOP_BIND_FILTER_ACQ_ENC));
    jChildren = JsonArrayInsert(jChildren, jAcqBtn);

    jChildren = JsonArrayInsert(jChildren, NuiSpacer());
    json jBar = NuiRow(jChildren);
    jBar = NuiHeight(jBar, FSHOP_TOP_H);
    return jBar;
}

// LISTA featow w sekcji (vertical, scroll Y). Kazdy wiersz: ikona + nazwa.
// Filter: BUY skip OWNED (gracz nie chce kupowac tego co ma), SELL only OWNED.
// Drzewo zaleznosci jest w osobnym oknie — patrz CreateFShopTreeWindow.
json BuildFShopFeatList(object oPC, int nMode, json jCache, json jSec, json jStates)
{
    json jRows = JsonArray();

    if(JsonGetType(jSec) != JSON_TYPE_ARRAY)
    {
        json jLab = NuiLabel(JsonString("No feats in this section."),
                             JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
        return NuiGroup(jLab, FALSE, NUI_SCROLLBARS_NONE);
    }

    int nLen = JsonGetLength(jSec);
    int i;
    int bAny = FALSE;

    // Search query — case-insensitive substring filter na FK_NAME (LIKE).
    // Pusty = brak filtra. Lower-case raz, nie per iter.
    string sSearch = GetStringLowerCase(GetLocalString(oPC, FSHOP_LVAR_SEARCH));

    // MASTERFEAT dedupe — pierwsza wariant z rodziny wygrywa, reszta skipowane
    json jSeenMF = JsonObject();

    for(i = 0; i < nLen; i++)
    {
        int nFeatId = JsonGetInt(JsonArrayGet(jSec, i));
        json jFeat = JsonObjectGet(jCache, IntToString(nFeatId));
        if(JsonGetType(jFeat) != JSON_TYPE_OBJECT) continue;

        int nState = JsonGetInt(JsonObjectGet(jStates, IntToString(nFeatId)));
        if(nState == FSHOP_ST_HIDDEN) continue;
        if(nMode == FSHOP_MODE_BUY  && nState == FSHOP_ST_OWNED) continue;
        if(nMode == FSHOP_MODE_SELL && nState != FSHOP_ST_OWNED) continue;
        if(nMode == FSHOP_MODE_BUY && FShopFilterAcq(oPC) && nState != FSHOP_ST_AVAILABLE) continue;

        // Search filter — substring case-insensitive na FK_NAME
        if(sSearch != "")
        {
            string sFeatName = GetStringLowerCase(JsonGetString(JsonObjectGet(jFeat, FK_NAME)));
            if(FindSubString(sFeatName, sSearch) < 0) continue;
        }

        // Dedupe rodziny: MASTERFEAT jesli dostepny, fallback na string prefix
        // przed "(" (np. "Improved Critical (dagger)" -> "Improved Critical")
        // UWAGA: nMfM == 0 to VALID masterfeat row (ImprovedCritical)!
        string sFamKey;
        int nMfM = JsonGetInt(JsonObjectGet(jFeat, FK_MF));
        if(nMfM >= 0)
        {
            sFamKey = "mf:" + IntToString(nMfM);
        }
        else
        {
            string sNameDp = JsonGetString(JsonObjectGet(jFeat, FK_NAME));
            int nParen = FindSubString(sNameDp, "(");
            if(nParen >= 0)
            {
                string sBase = GetSubString(sNameDp, 0, nParen);
                int nBL = GetStringLength(sBase);
                if(nBL > 0 && GetSubString(sBase, nBL - 1, 1) == " ")
                    sBase = GetSubString(sBase, 0, nBL - 1);
                sFamKey = "n:" + sBase;
            }
            else
            {
                sFamKey = "fid:" + IntToString(nFeatId);  // unique
            }
        }
        if(JsonGetType(JsonObjectGet(jSeenMF, sFamKey)) == JSON_TYPE_INTEGER) continue;
        jSeenMF = JsonObjectSet(jSeenMF, sFamKey, JsonInt(1));

        bAny = TRUE;

        string sName = JsonGetString(JsonObjectGet(jFeat, FK_NAME));
        string sIcon = JsonGetString(JsonObjectGet(jFeat, FK_ICON));

        // Detect rodzine: nazwa zawiera "(...)" LUB MASTERFEAT >= 0.
        // Jezeli rodzina — zamien ikone na family default i dodaj "..." do nazwy
        // (wzorzec NWN level-up: "Weapon Focus..." + shield icon).
        // UWAGA: nMfDsp == 0 to VALID masterfeat row (ImprovedCritical)!
        int bIsFamily = FALSE;
        int nMfDsp = JsonGetInt(JsonObjectGet(jFeat, FK_MF));
        if(nMfDsp >= 0) bIsFamily = TRUE;
        int nParenDsp = FindSubString(sName, "(");
        if(nParenDsp > 0) bIsFamily = TRUE;

        if(bIsFamily)
        {
            // Z masterfeats.2da: nazwa, ikona (priority). Fallback dla rodzin
            // bez MF (string-prefix dedupe): strip "(weapon)" i generic icon.
            json jMfGrp = FShopGetMasterfeatData(nMfDsp);
            string sGroupName = "";
            string sGroupIcon = "";
            if(JsonGetType(jMfGrp) == JSON_TYPE_OBJECT)
            {
                json jGN = JsonObjectGet(jMfGrp, FK_MF_NAME);
                json jGI = JsonObjectGet(jMfGrp, FK_MF_ICON);
                if(JsonGetType(jGN) == JSON_TYPE_STRING) sGroupName = JsonGetString(jGN);
                if(JsonGetType(jGI) == JSON_TYPE_STRING) sGroupIcon = JsonGetString(jGI);
            }

            if(sGroupName != "")
            {
                sName = sGroupName + FSHOP_FAMILY_NAME_SUFFIX;
            }
            else
            {
                // Fallback: strip suffix z feat name
                if(nParenDsp > 0)
                {
                    string sNameDsp = GetSubString(sName, 0, nParenDsp);
                    int nNDL = GetStringLength(sNameDsp);
                    if(nNDL > 0 && GetSubString(sNameDsp, nNDL - 1, 1) == " ")
                        sNameDsp = GetSubString(sNameDsp, 0, nNDL - 1);
                    sName = sNameDsp;
                }
                sName = sName + FSHOP_FAMILY_NAME_SUFFIX;
            }

            // Fallback: gdy masterfeats.2da nie ma ICON dla tej grupy, zostawiamy
            // ikone pierwszego wariantu (= sIcon przed tym blokiem) — lepsze niz
            // generic placeholder bo czesto pasuje do calej rodziny.
            if(sGroupIcon != "") sIcon = sGroupIcon;
        }

        // Wiersz: ikona po lewej + przycisk z nazwa
        json jRowChildren = JsonArray();

        json jImg = NuiImage(JsonString(sIcon),
                             JsonInt(NUI_ASPECT_FIT),
                             JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
        jImg = NuiWidth(jImg, FSHOP_ICON_SIZE);
        jImg = NuiHeight(jImg, FSHOP_ICON_SIZE);
        jRowChildren = JsonArrayInsert(jRowChildren, jImg);

        // Label zamiast buttona — szerszy, mieści pełną nazwę. Klik na cały row
        // przez NuiGroup poniżej (mousedown event). Wysokosc = pelna row height
        // zeby VALIGN_MIDDLE centralizowal tekst pionowo.
        json jLbl = NuiLabel(JsonString(sName),
                             JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
        jLbl = NuiHeight(jLbl, FSHOP_ICON_SIZE + 14.0);
        jLbl = NuiStyleForegroundColor(jLbl, NuiBind(FSHOP_BIND_FEAT_COL + IntToString(nFeatId)));
        jRowChildren = JsonArrayInsert(jRowChildren, jLbl);

        // Cala row = klikalny NuiGroup z NuiId. Event = MOUSEDOWN (NuiGroup
        // nie obsluguje click). Encouraged binding na grupie, color na labelu.
        json jRow = NuiGroup(NuiRow(jRowChildren), TRUE, NUI_SCROLLBARS_NONE);
        jRow = NuiId(jRow, FSHOP_BTN_FEAT_PRE + IntToString(nFeatId));
        jRow = NuiEncouraged(jRow, NuiBind(FSHOP_BIND_FEAT_ENC + IntToString(nFeatId)));
        jRow = NuiHeight(jRow, FSHOP_ICON_SIZE + 14.0);
        jRows = JsonArrayInsert(jRows, jRow);
    }

    if(!bAny)
    {
        json jLab = NuiLabel(JsonString("No feats to show."),
                             JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
        jRows = JsonArrayInsert(jRows, jLab);
    }

    return NuiGroup(NuiCol(jRows), TRUE, NUI_SCROLLBARS_AUTO);
}

// Helper: buduje header feata (icon centered + name centered + desc) opakowany
// w NuiGroup z ramka. Uzywany w BuildFShopInfoPanel (main window) i tree window
// right panel — jeden source of truth dla layoutu.
//   sIconBind  — bind name dla ikony (string)
//   sNameBind  — bind name dla nazwy (string)
//   sColorBind — bind name dla koloru nazwy (json color)
//   sDescBind  — bind name dla opisu (string)
//   fDescH     — wysokosc NuiText opisu (jawna, bo NuiText wymaga)
json BuildFShopFeatHeader(string sIconBind, string sNameBind, string sColorBind, string sDescBind, float fDescH, float fWidth)
{
    json jInner = JsonArray();

    // Ikona — NuiImage opakowana w NuiRow z NuiSpacer() po obu stronach
    // dla horizontal centerowania (standard wzorzec projektu, NuiCol +
    // NuiWidth na obrazku samo nie centruje w szerszym rodzicu).
    json jIcon = NuiImage(NuiBind(sIconBind),
                          JsonInt(NUI_ASPECT_FIT),
                          JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jIcon = NuiWidth(jIcon, 80.0);
    jIcon = NuiHeight(jIcon, 80.0);

    json jIconRow = JsonArray();
    jIconRow = JsonArrayInsert(jIconRow, NuiSpacer());
    jIconRow = JsonArrayInsert(jIconRow, jIcon);
    jIconRow = JsonArrayInsert(jIconRow, NuiSpacer());
    jInner = JsonArrayInsert(jInner, NuiRow(jIconRow));

    // Nazwa — both align center
    json jName = NuiLabel(NuiBind(sNameBind),
                          JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiHeight(jName, 20.0);
    jName = NuiStyleForegroundColor(jName, NuiBind(sColorBind));
    jInner = JsonArrayInsert(jInner, jName);

    // Opis (multiline). NuiText wymaga jawnej wysokosci.
    json jDesc = NuiText(NuiBind(sDescBind));
    jDesc = NuiHeight(jDesc, fDescH);
    jInner = JsonArrayInsert(jInner, jDesc);

    // NuiGroup z ramka. Bez NuiWidth/NuiHeight — wcześniej explicit dimensions
    // powodowały collapse layoutu do mini-ikony. Teraz height=auto z sumy
    // dzieci (icon row + name + desc), width=auto z parent col.
    return NuiGroup(NuiCol(jInner), TRUE, NUI_SCROLLBARS_NONE);
}

json BuildFShopInfoPanel()
{
    json jChildren = JsonArray();

    // Header (icon + name + desc) w jednej grupie z ramka — patrz BuildFShopFeatHeader.
    // Visibility na bindzie: ukryj cały panel gdy feat nie wybrany.
    json jHeader = BuildFShopFeatHeader(FSHOP_BIND_SEL_ICON, FSHOP_BIND_SEL_NAME,
                                        FSHOP_BIND_SEL_COL,  FSHOP_BIND_SEL_DESC,
                                        FSHOP_H - 330.0, FSHOP_RIGHT_W);
    jHeader = NuiVisible(jHeader, NuiBind(FSHOP_BIND_PANEL_VIS));
    jChildren = JsonArrayInsert(jChildren, jHeader);

    // Button "Pokaz drzewo" — visibility i enabled na tym samym bindzie:
    // ukryty gdy feat nie ma rodzicow/dzieci ani jest w GENERIC mode.
    // Bez NuiEnabled (zbedne — visible == enabled).
    json jTreeBtn = NuiButton(JsonString("Show Tree"));
    jTreeBtn = NuiId(jTreeBtn, FSHOP_BTN_TREE_OPEN);
    jTreeBtn = NuiHeight(jTreeBtn, 35.0);
    jTreeBtn = NuiVisible(jTreeBtn, NuiBind(FSHOP_BIND_TREE_BTN_EN));
    jChildren = JsonArrayInsert(jChildren, jTreeBtn);

    // Button "Detale" — pod nim, osobny wiersz. Visibility osobna od BTN_VIS,
    // bo Detale pokazujemy TYLKO gdy feat ma >1 wariant w rodzinie.
    json jVarBtn = NuiButton(JsonString("Details"));
    jVarBtn = NuiId(jVarBtn, FSHOP_BTN_VARIANTS);
    jVarBtn = NuiHeight(jVarBtn, 35.0);
    jVarBtn = NuiVisible(jVarBtn, NuiBind(FSHOP_BIND_VAR_BTN_VIS));
    jChildren = JsonArrayInsert(jChildren, jVarBtn);

    // Action button (Kup/Sprzedaj)
    json jBtn = NuiButton(NuiBind(FSHOP_BIND_BTN_LBL));
    jBtn = NuiId(jBtn, FSHOP_BTN_ACTION);
    jBtn = NuiHeight(jBtn, 40.0);
    jBtn = NuiEnabled(jBtn, NuiBind(FSHOP_BIND_BTN_EN));
    jBtn = NuiVisible(jBtn, NuiBind(FSHOP_BIND_BTN_VIS));
    jChildren = JsonArrayInsert(jChildren, jBtn);

    return NuiCol(jChildren);
}

json BuildFShopRoot(object oPC, int nMode, int nSection, json jCache, json jSec, json jStates)
{
    // Body row: list | right info panel (section bar moved to top)
    json jBody = JsonArray();

    json jList = BuildFShopFeatList(oPC, nMode, jCache, jSec, jStates);
    jBody = JsonArrayInsert(jBody, jList);

    json jRight = BuildFShopInfoPanel();
    jRight = NuiWidth(jRight, FSHOP_RIGHT_W);
    jBody = JsonArrayInsert(jBody, jRight);

    json jBodyRow = NuiRow(jBody);

    // Top bar (Kupno/Sprzedaz/Szukaj) + section bar (Walka/Aktywne/.../Inne) + body
    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, BuildFShopTopBar());
    jRoot = JsonArrayInsert(jRoot, BuildFShopSectionBar());
    jRoot = JsonArrayInsert(jRoot, jBodyRow);

    return NuiCol(jRoot);
}


// ===== Glowny entry =====

void CreateFShopWindow(object oPC, int nMode = -1, int nSection = -1)
{
    if(GetLocalInt(GetModule(), FSHOP_LVAR_BUILT) != 1)
    {
        SendMessageToPC(oPC, "Feat shop: cache not built. DM must run 'fshop_build'.");
        return;
    }

    if(nMode < 0) nMode = FShopMode(oPC);
    if(nSection < 0) nSection = FShopSection(oPC);
    SetLocalInt(oPC, FSHOP_LVAR_MODE, nMode);
    SetLocalInt(oPC, FSHOP_LVAR_SECTION, nSection + 1);  // +1 offset (0=unset)

    DestroyFShopWindow(oPC);

    json jCache = FShopGetCache();
    // Section = filter po TOOLSCATEGORIES (0=Wszystkie listuje wszystko z cache).
    // BEZ FShopExpandSectionWithPrereqs — drzewo zaleznosci ma osobny dostep
    // do calego cache, nie ma sensu duplikowac prereqow w widocznej liscie.
    json jSec   = FShopGetSection(nSection);

    json jStates = FShopBuildStatesMap(oPC, jCache, jSec);
    SetLocalJson(oPC, FSHOP_LVAR_STATES, jStates);
    SetLocalJson(oPC, FSHOP_LVAR_SEC_EXPANDED, jSec);

    json jRoot = BuildFShopRoot(oPC, nMode, nSection, jCache, jSec, jStates);

    json jWindow = NuiWindow(
        jRoot,
        JsonString("Feat Shop"),
        NuiBind(FSHOP_BIND_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE)
    );

    int nToken = NuiCreate(oPC, jWindow, FSHOP_WIN_ID, "lib_fshop_ev");
    SetLocalInt(oPC, FSHOP_LVAR_TOKEN, nToken);

    NuiSetBind(oPC, nToken, FSHOP_BIND_GEOM, NuiRect(-1.0, -1.0, FSHOP_W, FSHOP_H));

    // Defaulty bindow (ustawiane PRZED watchem)
    NuiSetBind(oPC, nToken, FSHOP_BIND_BTN_VIS,     JsonBool(FALSE));
    NuiSetBind(oPC, nToken, FSHOP_BIND_BTN_EN,      JsonBool(FALSE));
    NuiSetBind(oPC, nToken, FSHOP_BIND_TREE_BTN_EN, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, FSHOP_BIND_VAR_BTN_VIS, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, FSHOP_BIND_PANEL_VIS,   JsonBool(FALSE));
    NuiSetBind(oPC, nToken, FSHOP_BIND_BTN_LBL,  JsonString(""));
    NuiSetBind(oPC, nToken, FSHOP_BIND_SEL_NAME, JsonString(""));
    NuiSetBind(oPC, nToken, FSHOP_BIND_SEL_DESC, JsonString("Select a feat from the list."));
    NuiSetBind(oPC, nToken, FSHOP_BIND_SEL_ICON, JsonString(""));
    NuiSetBind(oPC, nToken, FSHOP_BIND_SEL_COL,  NuiColor(255, 255, 255, 255));
    NuiSetBind(oPC, nToken, FSHOP_BIND_GOLD,     JsonString(""));
    // Preserve search query across rebuilds — bez tego po kazdym znaku
    // pole sie czysci (FeedFShopSearch robi recreate na watch evencie)
    NuiSetBind(oPC, nToken, FSHOP_BIND_SEARCH,   JsonString(GetLocalString(oPC, FSHOP_LVAR_SEARCH)));

    // Bez watch na search bind — filter triggered klikiem przycisku FSHOP_BTN_SEARCH
    // (rebuild na kazdy znak byl zbyt drogi dla duzego datasetu featow)

    FeedFShopAll(oPC, nToken);
}

void DestroyFShopWindow(object oPC)
{
    int nToken = GetLocalInt(oPC, FSHOP_LVAR_TOKEN);
    if(nToken > 0) NuiDestroy(oPC, nToken);
    DeleteLocalInt(oPC, FSHOP_LVAR_TOKEN);
    DeleteLocalJson(oPC, FSHOP_LVAR_STATES);
    DeleteLocalJson(oPC, FSHOP_LVAR_SEC_EXPANDED);
    DeleteLocalInt(oPC, FSHOP_LVAR_SEL_MODE);
    DestroyFShopVariantWindow(oPC);
}


// ===== Feed funkcje =====

void FeedFShopAll(object oPC, int nToken)
{
    int nMode = FShopMode(oPC);
    int nSection = FShopSection(oPC);

    NuiSetBind(oPC, nToken, FSHOP_BIND_MODE_ENC_B, JsonBool(nMode == FSHOP_MODE_BUY));
    NuiSetBind(oPC, nToken, FSHOP_BIND_MODE_ENC_S, JsonBool(nMode == FSHOP_MODE_SELL));

    int s;
    for(s = 0; s <= 6; s++)  // 0=Wszystkie, 1..6=oryginalne sekcje
    {
        NuiSetBind(oPC, nToken, FSHOP_BIND_SEC_ENC_PRE + IntToString(s),
                   JsonBool(s == nSection));
    }

    NuiSetBind(oPC, nToken, FSHOP_BIND_FILTER_ACQ_ENC, JsonBool(FShopFilterAcq(oPC) == 1));

    NuiSetBind(oPC, nToken, FSHOP_BIND_GOLD,
               JsonString("Posiadasz: " + FShopGoldText(GetGold(oPC))));

    json jCache = FShopGetCache();
    json jSec   = FShopGetSection(nSection);
    FeedFShopFeatStates(oPC, nToken, nMode, nSection, jCache, jSec);
    FeedFShopInfoPanel(oPC, nToken);
}

void FeedFShopFeatStates(object oPC, int nToken, int nMode, int nSection, json jCache, json jSec)
{
    int nSelected = FShopSelectedFeat(oPC);

    // Uzyj rozszerzonej sekcji + states z LVAR
    json jSecExp = GetLocalJson(oPC, FSHOP_LVAR_SEC_EXPANDED);
    json jStates = GetLocalJson(oPC, FSHOP_LVAR_STATES);
    if(JsonGetType(jSecExp) == JSON_TYPE_ARRAY) jSec = jSecExp;

    if(JsonGetType(jSec) != JSON_TYPE_ARRAY) return;

    int nLen = JsonGetLength(jSec);
    int i;
    for(i = 0; i < nLen; i++)
    {
        int nFeatId = JsonGetInt(JsonArrayGet(jSec, i));
        json jFeat = JsonObjectGet(jCache, IntToString(nFeatId));

        // Encouraged: tylko wybrany feat (search filtruje liste, nie podswietla)
        int bEnc = (nFeatId == nSelected);
        NuiSetBind(oPC, nToken, FSHOP_BIND_FEAT_ENC + IntToString(nFeatId), JsonBool(bEnc));

        // Kolor ramki = stan
        int nState = JsonGetInt(JsonObjectGet(jStates, IntToString(nFeatId)));
        NuiSetBind(oPC, nToken, FSHOP_BIND_FEAT_COL + IntToString(nFeatId),
                   FShopColorForState(nState));
    }
}

void FeedFShopInfoPanel(object oPC, int nToken)
{
    int nFeatId = FShopSelectedFeat(oPC);
    int nMode = FShopMode(oPC);

    if(nFeatId < 0)
    {
        // Ukryj cały panel header (icon+name+desc) — gracz nic nie wybral
        NuiSetBind(oPC, nToken, FSHOP_BIND_PANEL_VIS,   JsonBool(FALSE));
        NuiSetBind(oPC, nToken, FSHOP_BIND_BTN_VIS,     JsonBool(FALSE));
        NuiSetBind(oPC, nToken, FSHOP_BIND_BTN_LBL,     JsonString(""));
        NuiSetBind(oPC, nToken, FSHOP_BIND_BTN_EN,      JsonBool(FALSE));
        NuiSetBind(oPC, nToken, FSHOP_BIND_TREE_BTN_EN, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, FSHOP_BIND_VAR_BTN_VIS, JsonBool(FALSE));
        return;
    }

    // Feat wybrany — pokaz panel
    NuiSetBind(oPC, nToken, FSHOP_BIND_PANEL_VIS, JsonBool(TRUE));

    json jCache = FShopGetCache();
    json jFeat = JsonObjectGet(jCache, IntToString(nFeatId));
    string sName = JsonGetString(JsonObjectGet(jFeat, FK_NAME));
    string sDesc = JsonGetString(JsonObjectGet(jFeat, FK_DESC));
    string sIcon = JsonGetString(JsonObjectGet(jFeat, FK_ICON));

    json jStates = GetLocalJson(oPC, FSHOP_LVAR_STATES);
    int nState = JsonGetInt(JsonObjectGet(jStates, IntToString(nFeatId)));
    json jColor = FShopColorForState(nState);

    string sPrereq = FShopBuildPrereqText(jCache, jFeat);

    // Sprawdz czy feat ma rodzine wariantow (>1 elementu z tej samej masterfeat / name prefix)
    json jVariants = FShopGetFamilyVariants(jCache, nFeatId, jFeat);
    int bHasVariants = (JsonGetLength(jVariants) > 1);

    int nSelMode = FShopSelMode(oPC);
    int bGenericView = bHasVariants && (nSelMode == FSHOP_SEL_MODE_GENERIC);

    // GENERIC view: pelne metadata grupy z masterfeats.2da
    // (name + desc + icon). Fallback dla rodzin bez MF: strip suffix + generic icon.
    if(bGenericView)
    {
        int nMfFp = JsonGetInt(JsonObjectGet(jFeat, FK_MF));
        json jMfGrpFp = FShopGetMasterfeatData(nMfFp);
        string sGN = "";
        string sGD = "";
        string sGI = "";
        if(JsonGetType(jMfGrpFp) == JSON_TYPE_OBJECT)
        {
            json jN = JsonObjectGet(jMfGrpFp, FK_MF_NAME);
            json jD = JsonObjectGet(jMfGrpFp, FK_MF_DESC);
            json jI = JsonObjectGet(jMfGrpFp, FK_MF_ICON);
            if(JsonGetType(jN) == JSON_TYPE_STRING) sGN = JsonGetString(jN);
            if(JsonGetType(jD) == JSON_TYPE_STRING) sGD = JsonGetString(jD);
            if(JsonGetType(jI) == JSON_TYPE_STRING) sGI = JsonGetString(jI);
        }

        if(sGN != "") sName = sGN;
        else
        {
            string sBase = FShopGetNameBase(sName);
            if(sBase != "") sName = sBase;
        }
        sName = sName + FSHOP_FAMILY_NAME_SUFFIX;

        if(sGD != "") sDesc = sGD;  // opis grupy zamiast opisu pierwszego wariantu

        // Fallback: brak ICON w masterfeats.2da → zostaw sIcon pierwszego wariantu
        if(sGI != "") sIcon = sGI;
    }

    NuiSetBind(oPC, nToken, FSHOP_BIND_SEL_NAME, JsonString(sName));
    // W trybie GENERIC nie pokazujemy prereqow (grupa nie ma — kazdy wariant ma swoje)
    if(bGenericView)
        NuiSetBind(oPC, nToken, FSHOP_BIND_SEL_DESC, JsonString(sDesc));
    else
        NuiSetBind(oPC, nToken, FSHOP_BIND_SEL_DESC, JsonString(sPrereq + "\n\n" + sDesc));
    NuiSetBind(oPC, nToken, FSHOP_BIND_SEL_ICON, JsonString(sIcon));
    NuiSetBind(oPC, nToken, FSHOP_BIND_SEL_COL,  jColor);

    // "Pokaz drzewo" widoczny tylko gdy:
    //   - feat ma rodzica/dziecko, ORAZ
    //   - NIE GENERIC view (gracz wybral konkretny wariant ALBO feat nie ma rodziny)
    // W GENERIC view "Pokaz drzewo" hidden — kazdy wariant rodziny moze miec inne drzewo.
    int bHasTree = FShopHasTreeRelations(jCache, nFeatId, jFeat);
    int bTreeVis = bHasTree && !bGenericView;
    NuiSetBind(oPC, nToken, FSHOP_BIND_TREE_BTN_EN, JsonBool(bTreeVis));

    // "Detale" visible tylko gdy feat ma rodzine wariantow
    NuiSetBind(oPC, nToken, FSHOP_BIND_VAR_BTN_VIS, JsonBool(bHasVariants));

    if(nMode == FSHOP_MODE_BUY)
    {
        // W trybie GENERIC blokujemy zakup — gracz musi najpierw wybrac wariant
        int bCanBuy = !bGenericView && (nState == FSHOP_ST_AVAILABLE) && (GetGold(oPC) >= FSHOP_PRICE_BUY);
        NuiSetBind(oPC, nToken, FSHOP_BIND_BTN_VIS, JsonBool(TRUE));
        NuiSetBind(oPC, nToken, FSHOP_BIND_BTN_LBL,
                   JsonString("Buy for " + FShopGoldText(FSHOP_PRICE_BUY)));
        NuiSetBind(oPC, nToken, FSHOP_BIND_BTN_EN, JsonBool(bCanBuy));
    }
    else
    {
        int bCanSell = !bGenericView && FShopCanSell(oPC, nFeatId, jCache);
        NuiSetBind(oPC, nToken, FSHOP_BIND_BTN_VIS, JsonBool(TRUE));
        NuiSetBind(oPC, nToken, FSHOP_BIND_BTN_LBL,
                   JsonString("Sell for " + FShopGoldText(FSHOP_PRICE_SELL)));
        NuiSetBind(oPC, nToken, FSHOP_BIND_BTN_EN, JsonBool(bCanSell));
    }
}

void FeedFShopSearch(object oPC, int nToken, string sQuery)
{
    SetLocalString(oPC, FSHOP_LVAR_SEARCH, sQuery);
    // Recreate window — search filter w BuildFShopFeatList wymaga
    // pelnego rebuilda listy (NUI nie pozwala mutowac sub-tree).
    CreateFShopWindow(oPC, FShopMode(oPC), FShopSection(oPC));
}


// ============================================================================
// TREE WINDOW — osobny popup pokazujacy drzewo zaleznosci feaTu
// ============================================================================
//
// Algorytm:
//   1) start z nFocusFeatId
//   2) BFS UP — zbierz wszystkich przodkow (PREREQFEAT chain az do roota)
//   3) BFS DOWN — zbierz wszystkich potomkow (z lokalnego children indexu cache)
//   4) Dla kazdego visible feata oblicz depth (longest path do roota uchwycenia)
//   5) Layout: col = depth, row = greedy slot
//   6) Render: ikony jako NuiButtonImage z prefixem fst_ + arrows (lh+chr+corner tile)
//
// Drzewo dla pojedynczego feata jest male (5-20 nodow) → tani render.
// Click na ikone = closetree + select w main window.

void CreateFShopTreeWindow(object oPC, int nFocusFeatId)
{
    if(GetLocalInt(GetModule(), FSHOP_LVAR_BUILT) != 1) return;

    DestroyFShopTreeWindow(oPC);

    json jCache = FShopGetCache();
    json jFocus = JsonObjectGet(jCache, IntToString(nFocusFeatId));
    if(JsonGetType(jFocus) != JSON_TYPE_OBJECT) return;

    // Czy focus jest specific variantem (parens w nazwie, np. "Epic Weapon Focus
    // (trident)")? Wpływa na display w tree:
    //   bFocusHasSpec = TRUE  → tree pokazuje specific variants (trident dla wszystkich)
    //   bFocusHasSpec = FALSE → tree pokazuje group reps (np. "Devastating Critical...")
    // ALE: jezeli user jest w GENERIC mode (nie wybral wariantu przez Detale),
    // wymuszamy generic display w tree, niezaleznie od czy focus name ma parens.
    string sFocusNameForSpec = JsonGetString(JsonObjectGet(jFocus, FK_NAME));
    int bFocusHasSpec = (FindSubString(sFocusNameForSpec, "(") > 0);
    if(FShopSelMode(oPC) == FSHOP_SEL_MODE_GENERIC) bFocusHasSpec = FALSE;

    // ---- Pobierz pre-built children index z modułu (PREREQFEAT only) ----
    // Zbudowany raz w fshop_build, oszczedza ~10-15k ops per render tree window.
    json jAllChildren = FShopGetChildrenIndex();
    if(JsonGetType(jAllChildren) != JSON_TYPE_OBJECT) jAllChildren = JsonObject();

    // Cap visible feats — zapobiega pathological eksplozji drzewa
    int nVisibleCap = 25;
    int nOrCap = 4;  // max alternatyw OR per feat (z ~5-6 mozliwych)

    // jSeenMF — set widzianych masterfeat ID; pierwszy wariant z rodziny wygrywa,
    // pozostale skipowane. To jest THE optymalizacja przeciw weapon-variant explosion.
    json jSeenMF = JsonObject();
    int nFocusMF = JsonGetInt(JsonObjectGet(jFocus, FK_MF));
    if(nFocusMF >= 0) jSeenMF = JsonObjectSet(jSeenMF, IntToString(nFocusMF), JsonInt(1));

    // ---- Pre-build class set (jClassSet) ----
    // Potrzebne w BFS zeby skipowac feaTy klasowo nie pasujace do gracza
    // (np. ranger nie powinien widziec Weapon Proficiency (monk) w drzewie).
    json jClassSetBfs = FShopBuildClassFeatSet(oPC);

    // ---- BFS UP only z focus ----
    json jVisible = JsonObject();
    jVisible = JsonObjectSet(jVisible, IntToString(nFocusFeatId), JsonInt(1));

    json jUpQ = JsonArray();
    jUpQ = JsonArrayInsert(jUpQ, JsonInt(nFocusFeatId));
    int upi = 0;
    while(upi < JsonGetLength(jUpQ) && JsonGetLength(jVisible) < nVisibleCap)
    {
        int nFidU = JsonGetInt(JsonArrayGet(jUpQ, upi));
        upi++;
        json jFU = JsonObjectGet(jCache, IntToString(nFidU));
        if(JsonGetType(jFU) != JSON_TYPE_OBJECT) continue;

        int up1 = JsonGetInt(JsonObjectGet(jFU, FK_P1));
        int up2 = JsonGetInt(JsonObjectGet(jFU, FK_P2));
        int upp;
        for(upp = 0; upp < 2; upp++)
        {
            if(JsonGetLength(jVisible) >= nVisibleCap) break;
            int nPidU = (upp == 0 ? up1 : up2);
            if(nPidU < 0) continue;
            string sPidU = IntToString(nPidU);
            if(JsonGetType(JsonObjectGet(jVisible, sPidU)) == JSON_TYPE_INTEGER) continue;
            json jPidF = JsonObjectGet(jCache, sPidU);
            if(JsonGetType(jPidF) != JSON_TYPE_OBJECT) continue;
            // BRAK class filter — pokazujemy WSZYSTKIE featy (czerwony state).
            // Jedyna rezerwa to FShopShouldSkipFeat (na poziomie cache build).
            // MF dedupe — jezeli rodzina ma juz reprezentanta, skip.
            // nMfU >= 0: row 0 (ImprovedCritical) to VALID masterfeat.
            int nMfU = JsonGetInt(JsonObjectGet(jPidF, FK_MF));
            if(nMfU >= 0)
            {
                string sMfU = IntToString(nMfU);
                if(JsonGetType(JsonObjectGet(jSeenMF, sMfU)) == JSON_TYPE_INTEGER) continue;
                jSeenMF = JsonObjectSet(jSeenMF, sMfU, JsonInt(1));
            }
            jVisible = JsonObjectSet(jVisible, sPidU, JsonInt(1));
            jUpQ = JsonArrayInsert(jUpQ, JsonInt(nPidU));
        }

        json jUOr = JsonObjectGet(jFU, FK_OR);
        int nUOrLen = JsonGetLength(jUOr);
        if(nUOrLen > nOrCap) nUOrLen = nOrCap;
        int uoi;
        for(uoi = 0; uoi < nUOrLen; uoi++)
        {
            if(JsonGetLength(jVisible) >= nVisibleCap) break;
            int nOrUp = JsonGetInt(JsonArrayGet(jUOr, uoi));
            if(nOrUp < 0) continue;
            string sOrUp = IntToString(nOrUp);
            if(JsonGetType(JsonObjectGet(jVisible, sOrUp)) == JSON_TYPE_INTEGER) continue;
            json jOrF = JsonObjectGet(jCache, sOrUp);
            if(JsonGetType(jOrF) != JSON_TYPE_OBJECT) continue;
            // BRAK class filter — wszystkie OR-prereqi widoczne (czerwony state).
            int nMfO = JsonGetInt(JsonObjectGet(jOrF, FK_MF));
            if(nMfO >= 0)
            {
                string sMfO = IntToString(nMfO);
                if(JsonGetType(JsonObjectGet(jSeenMF, sMfO)) == JSON_TYPE_INTEGER) continue;
                jSeenMF = JsonObjectSet(jSeenMF, sMfO, JsonInt(1));
            }
            jVisible = JsonObjectSet(jVisible, sOrUp, JsonInt(1));
            jUpQ = JsonArrayInsert(jUpQ, JsonInt(nOrUp));
        }
    }

    // ---- BFS DOWN only z focus ----
    json jDnQ = JsonArray();
    jDnQ = JsonArrayInsert(jDnQ, JsonInt(nFocusFeatId));
    int dni = 0;
    while(dni < JsonGetLength(jDnQ) && JsonGetLength(jVisible) < nVisibleCap)
    {
        int nFidD = JsonGetInt(JsonArrayGet(jDnQ, dni));
        dni++;
        json jKidsD = JsonObjectGet(jAllChildren, IntToString(nFidD));
        if(JsonGetType(jKidsD) != JSON_TYPE_ARRAY) continue;
        int nKD = JsonGetLength(jKidsD);
        int kdc;
        for(kdc = 0; kdc < nKD; kdc++)
        {
            if(JsonGetLength(jVisible) >= nVisibleCap) break;
            int nKidIdD = JsonGetInt(JsonArrayGet(jKidsD, kdc));
            string sKidIdD = IntToString(nKidIdD);
            if(JsonGetType(JsonObjectGet(jVisible, sKidIdD)) == JSON_TYPE_INTEGER) continue;
            json jKidF = JsonObjectGet(jCache, sKidIdD);
            if(JsonGetType(jKidF) != JSON_TYPE_OBJECT) continue;
            // BRAK class filter — wszystkie dzieci widoczne (czerwony state).
            int nMfK = JsonGetInt(JsonObjectGet(jKidF, FK_MF));
            if(nMfK >= 0)
            {
                string sMfK = IntToString(nMfK);
                if(JsonGetType(JsonObjectGet(jSeenMF, sMfK)) == JSON_TYPE_INTEGER) continue;
                jSeenMF = JsonObjectSet(jSeenMF, sMfK, JsonInt(1));
            }
            jVisible = JsonObjectSet(jVisible, sKidIdD, JsonInt(1));
            jDnQ = JsonArrayInsert(jDnQ, JsonInt(nKidIdD));
        }
    }

    // Combine visible into single queue for layout pass (kolejnosc nie ma znaczenia)
    json jQueue = JsonArray();
    json jVisKeys = JsonObjectKeys(jVisible);
    int vki;
    int nVisKeysLen = JsonGetLength(jVisKeys);
    for(vki = 0; vki < nVisKeysLen; vki++)
    {
        int nVId2 = StringToInt(JsonGetString(JsonArrayGet(jVisKeys, vki)));
        jQueue = JsonArrayInsert(jQueue, JsonInt(nVId2));
    }

    // Build jStates dla visible feaTow w tree — uzywane do kolorowania ikon i strzalek.
    // jClassSetBfs juz zbudowany przed BFS — reuse.
    json jStates = JsonObject();
    int sti;
    for(sti = 0; sti < nVisKeysLen; sti++)
    {
        int nVStId = StringToInt(JsonGetString(JsonArrayGet(jVisKeys, sti)));
        json jVStF = JsonObjectGet(jCache, IntToString(nVStId));
        int nVSt = FShopGetState(oPC, nVStId, jVStF, jClassSetBfs);
        jStates = JsonObjectSet(jStates, IntToString(nVStId), JsonInt(nVSt));
    }

    // ---- Compute depth per visible: longest PREREQ chain w obrebie visible ----
    // Iteracyjnie: relaxation pass do stabilizacji (max 10 iter, depth bounded).
    json jDepths = JsonObject();
    int nVisLen = JsonGetLength(jQueue);
    int dv;
    for(dv = 0; dv < nVisLen; dv++)
    {
        jDepths = JsonObjectSet(jDepths, IntToString(JsonGetInt(JsonArrayGet(jQueue, dv))), JsonInt(0));
    }
    int nIter;
    for(nIter = 0; nIter < 12; nIter++)
    {
        int bChanged = FALSE;
        int vi;
        for(vi = 0; vi < nVisLen; vi++)
        {
            int nVId = JsonGetInt(JsonArrayGet(jQueue, vi));
            json jVF = JsonObjectGet(jCache, IntToString(nVId));
            int vp1 = JsonGetInt(JsonObjectGet(jVF, FK_P1));
            int vp2 = JsonGetInt(JsonObjectGet(jVF, FK_P2));
            int dCur = JsonGetInt(JsonObjectGet(jDepths, IntToString(nVId)));
            int dNew = 0;
            if(vp1 >= 0)
            {
                json jDpA = JsonObjectGet(jDepths, IntToString(vp1));
                if(JsonGetType(jDpA) == JSON_TYPE_INTEGER)
                {
                    int nDpA = JsonGetInt(jDpA) + 1;
                    if(nDpA > dNew) dNew = nDpA;
                }
            }
            if(vp2 >= 0)
            {
                json jDpB = JsonObjectGet(jDepths, IntToString(vp2));
                if(JsonGetType(jDpB) == JSON_TYPE_INTEGER)
                {
                    int nDpB = JsonGetInt(jDpB) + 1;
                    if(nDpB > dNew) dNew = nDpB;
                }
            }
            // OrReqFeat tez wplywa na depth (najwiekszy z OR alternatives + 1)
            json jVOr2 = JsonObjectGet(jVF, FK_OR);
            int nVOr2Len = JsonGetLength(jVOr2);
            int voi2;
            for(voi2 = 0; voi2 < nVOr2Len; voi2++)
            {
                int nOrPx = JsonGetInt(JsonArrayGet(jVOr2, voi2));
                if(nOrPx < 0) continue;
                json jDpC = JsonObjectGet(jDepths, IntToString(nOrPx));
                if(JsonGetType(jDpC) == JSON_TYPE_INTEGER)
                {
                    int nDpC = JsonGetInt(jDpC) + 1;
                    if(nDpC > dNew) dNew = nDpC;
                }
            }
            if(dNew > dCur)
            {
                jDepths = JsonObjectSet(jDepths, IntToString(nVId), JsonInt(dNew));
                bChanged = TRUE;
            }
        }
        if(!bChanged) break;
    }

    // ---- Compute subtree_depth per node (for chain-first sort) ----
    // subtree_depth[id] = max(depth of any descendant in tree). Node z wiekszym
    // subtree_depth ma dluzszy chain — placement go pierwszy → dostaje row 0,
    // chain ladnie idzie wzdluz row 0 zamiast wpadac w side branches.
    json jSubDepth = JsonObject();
    int sdi;
    for(sdi = 0; sdi < nVisLen; sdi++)
    {
        int nSdId = JsonGetInt(JsonArrayGet(jQueue, sdi));
        int nDp = JsonGetInt(JsonObjectGet(jDepths, IntToString(nSdId)));
        jSubDepth = JsonObjectSet(jSubDepth, IntToString(nSdId), JsonInt(nDp));
    }
    // Iteracyjnie propaguj depth dziecka w gore na rodzicow
    int nSdIter;
    for(nSdIter = 0; nSdIter < 12; nSdIter++)
    {
        int bSdChanged = FALSE;
        int sdj;
        for(sdj = 0; sdj < nVisLen; sdj++)
        {
            int nSdFid = JsonGetInt(JsonArrayGet(jQueue, sdj));
            json jSdF = JsonObjectGet(jCache, IntToString(nSdFid));
            int nMyDepth = JsonGetInt(JsonObjectGet(jSubDepth, IntToString(nSdFid)));
            int sp1 = JsonGetInt(JsonObjectGet(jSdF, FK_P1));
            int sp2 = JsonGetInt(JsonObjectGet(jSdF, FK_P2));
            int spp;
            for(spp = 0; spp < 2; spp++)
            {
                int nSdPid = (spp == 0 ? sp1 : sp2);
                if(nSdPid < 0) continue;
                if(JsonGetType(JsonObjectGet(jVisible, IntToString(nSdPid))) != JSON_TYPE_INTEGER) continue;
                int nParSd = JsonGetInt(JsonObjectGet(jSubDepth, IntToString(nSdPid)));
                if(nMyDepth > nParSd)
                {
                    jSubDepth = JsonObjectSet(jSubDepth, IntToString(nSdPid), JsonInt(nMyDepth));
                    bSdChanged = TRUE;
                }
            }
        }
        if(!bSdChanged) break;
    }

    // ---- Sort jQueue: depth ASC (parents first), within bucket: subtree_depth DESC ----
    // Buckets per depth, sortowane wewnatrz bucketu (chain-first), potem concat.
    json jByDepth = JsonObject();
    int sbi;
    for(sbi = 0; sbi < nVisLen; sbi++)
    {
        int nFb = JsonGetInt(JsonArrayGet(jQueue, sbi));
        int nDb = JsonGetInt(JsonObjectGet(jDepths, IntToString(nFb)));
        string sDb = IntToString(nDb);
        json jBucket = JsonObjectGet(jByDepth, sDb);
        if(JsonGetType(jBucket) != JSON_TYPE_ARRAY) jBucket = JsonArray();
        // Insertion sort by subtree_depth DESC
        int nMySd = JsonGetInt(JsonObjectGet(jSubDepth, IntToString(nFb)));
        int bInserted = FALSE;
        int nBLen = JsonGetLength(jBucket);
        int bi;
        json jNewBucket = JsonArray();
        for(bi = 0; bi < nBLen; bi++)
        {
            int nExisting = JsonGetInt(JsonArrayGet(jBucket, bi));
            int nExSd = JsonGetInt(JsonObjectGet(jSubDepth, IntToString(nExisting)));
            if(!bInserted && nMySd > nExSd)
            {
                jNewBucket = JsonArrayInsert(jNewBucket, JsonInt(nFb));
                bInserted = TRUE;
            }
            jNewBucket = JsonArrayInsert(jNewBucket, JsonInt(nExisting));
        }
        if(!bInserted) jNewBucket = JsonArrayInsert(jNewBucket, JsonInt(nFb));
        jByDepth = JsonObjectSet(jByDepth, sDb, jNewBucket);
    }
    json jQueueSorted = JsonArray();
    int sd;
    int nMaxDepthCalc = 0;
    int sbk;
    for(sbk = 0; sbk < nVisLen; sbk++)
    {
        int nFc = JsonGetInt(JsonArrayGet(jQueue, sbk));
        int nDc = JsonGetInt(JsonObjectGet(jDepths, IntToString(nFc)));
        if(nDc > nMaxDepthCalc) nMaxDepthCalc = nDc;
    }
    for(sd = 0; sd <= nMaxDepthCalc; sd++)
    {
        json jBucket = JsonObjectGet(jByDepth, IntToString(sd));
        if(JsonGetType(jBucket) != JSON_TYPE_ARRAY) continue;
        int nBLen = JsonGetLength(jBucket);
        int sbj;
        for(sbj = 0; sbj < nBLen; sbj++)
        {
            jQueueSorted = JsonArrayInsert(jQueueSorted, JsonArrayGet(jBucket, sbj));
        }
    }
    jQueue = jQueueSorted;

    // ---- Layout: col = depth, row = greedy slot ----
    json jSlotMap = JsonObject();
    json jPositions = JsonObject();   // featId -> {c, r}
    json jColUsed = JsonObject();     // col -> {row: 1}
    int nMaxCol = 0;
    int nMaxRow = -1;

    int li;
    for(li = 0; li < nVisLen; li++)
    {
        int nFId2 = JsonGetInt(JsonArrayGet(jQueue, li));
        int nCol = JsonGetInt(JsonObjectGet(jDepths, IntToString(nFId2)));

        // Suggested row = MIN(rows of placed parents) — preferuj polozenie blizej topu.
        // Sprawdzamy PREREQFEAT1/2 + OrReqFeat0..4. Pierwszy znaleziony placed parent
        // ustawia nSugg, kolejne moga obnizyc (=mniejsza row, blizej topu).
        int nSugg = -1;
        json jVF = JsonObjectGet(jCache, IntToString(nFId2));
        int vp1 = JsonGetInt(JsonObjectGet(jVF, FK_P1));
        int vp2 = JsonGetInt(JsonObjectGet(jVF, FK_P2));
        if(vp1 >= 0)
        {
            json jPP = JsonObjectGet(jPositions, IntToString(vp1));
            if(JsonGetType(jPP) == JSON_TYPE_OBJECT)
            {
                int rr = JsonGetInt(JsonObjectGet(jPP, "r"));
                if(nSugg < 0 || rr < nSugg) nSugg = rr;
            }
        }
        if(vp2 >= 0)
        {
            json jPP = JsonObjectGet(jPositions, IntToString(vp2));
            if(JsonGetType(jPP) == JSON_TYPE_OBJECT)
            {
                int rr = JsonGetInt(JsonObjectGet(jPP, "r"));
                if(nSugg < 0 || rr < nSugg) nSugg = rr;
            }
        }
        // OR-parents tez wplywaja na suggested row
        json jVOrL = JsonObjectGet(jVF, FK_OR);
        int nVOrLLen = JsonGetLength(jVOrL);
        int voli;
        for(voli = 0; voli < nVOrLLen; voli++)
        {
            int nOrL = JsonGetInt(JsonArrayGet(jVOrL, voli));
            if(nOrL < 0) continue;
            json jPP = JsonObjectGet(jPositions, IntToString(nOrL));
            if(JsonGetType(jPP) == JSON_TYPE_OBJECT)
            {
                int rr = JsonGetInt(JsonObjectGet(jPP, "r"));
                if(nSugg < 0 || rr < nSugg) nSugg = rr;
            }
        }
        if(nSugg < 0) nSugg = 0;

        string sCol = IntToString(nCol);
        json jUsed = JsonObjectGet(jColUsed, sCol);
        if(JsonGetType(jUsed) != JSON_TYPE_OBJECT) jUsed = JsonObject();
        int nRow = nSugg;
        while(JsonGetType(JsonObjectGet(jUsed, IntToString(nRow))) == JSON_TYPE_INTEGER) nRow++;
        jUsed = JsonObjectSet(jUsed, IntToString(nRow), JsonInt(1));
        jColUsed = JsonObjectSet(jColUsed, sCol, jUsed);

        json jPos = JsonObject();
        jPos = JsonObjectSet(jPos, "c", JsonInt(nCol));
        jPos = JsonObjectSet(jPos, "r", JsonInt(nRow));
        jPositions = JsonObjectSet(jPositions, IntToString(nFId2), jPos);
        jSlotMap = JsonObjectSet(jSlotMap, IntToString(nCol) + "_" + IntToString(nRow), JsonInt(nFId2));

        if(nCol > nMaxCol) nMaxCol = nCol;
        if(nRow > nMaxRow) nMaxRow = nRow;
    }

    // ---- Render: arrows (DrawList) + grid ikonek ----
    //
    // Per-spacer drawing dla SAME-ROW arrows: kazdy gap dostaje wlasny DrawList
    // z arrow w lokalnych wspolrzednych (y=16 = polowa wysokosci spacera 64).
    // Eliminuje problemy z absolute alignment przez NUI layout.
    //
    // jSpacerLine[row_col]    = TRUE jezeli linia przechodzi przez ten gap
    // jSpacerChev[row_col]    = TRUE jezeli chevron konczy sie tutaj
    // jSpacerCorner[row_col]  = "cbl"/"cbr"/"ctl"/"ctr" jezeli corner bend
    // jSpacerLineCol[row_col] = kolor linii
    // jSpacerChevCol[row_col] = kolor chevrona (priorytet > line)
    // jSpacerCornerCol[row_col] = kolor cornera
    // jSpacerLvY[row_col]     = JsonArray of {y, color} dla lv tiles attached do tego spacera
    //
    // Lv attached do upper row's spacer z lokalnymi y values (mogą wykraczać poza
    // spacer bounds — NUI renderuje outside). Lokalny x=0 → automatyczne wyrownanie.
    json jSpacerLine      = JsonObject();
    json jSpacerChev      = JsonObject();
    json jSpacerCorner    = JsonObject();
    json jSpacerLineCol   = JsonObject();
    json jSpacerChevCol   = JsonObject();
    json jSpacerCornerCol = JsonObject();
    json jSpacerLvY       = JsonObject();

    // jCellHLine[row_col] = TRUE jezeli horizontal line przechodzi przez jPad cell.
    // Dla cross-row source row, line idzie od source icon przez jPad cells po drodze
    // do bend'a (xC-1 gap). Cells sa 64 wide, potrzeba 2 lh tile per cell.
    json jCellHLine    = JsonObject();
    json jCellHLineCol = JsonObject();
    json jArrows = JsonArray();
    int aL;
    for(aL = 0; aL < nVisLen; aL++)
    {
        int nFId3 = JsonGetInt(JsonArrayGet(jQueue, aL));
        json jPosX = JsonObjectGet(jPositions, IntToString(nFId3));
        if(JsonGetType(jPosX) != JSON_TYPE_OBJECT) continue;
        int xC = JsonGetInt(JsonObjectGet(jPosX, "c"));
        int xR = JsonGetInt(JsonObjectGet(jPosX, "r"));

        // Build list of ALL parents — PREREQFEAT1/2 (AND) + OrReqFeat0..4 (OR).
        // Wszystkie rysujemy tymi samymi tile'ami (dla teraz; dashed dla OR — TODO).
        json jVF2 = JsonObjectGet(jCache, IntToString(nFId3));
        json jAllParents = JsonArray();
        int yp1 = JsonGetInt(JsonObjectGet(jVF2, FK_P1));
        int yp2 = JsonGetInt(JsonObjectGet(jVF2, FK_P2));
        if(yp1 >= 0) jAllParents = JsonArrayInsert(jAllParents, JsonInt(yp1));
        if(yp2 >= 0) jAllParents = JsonArrayInsert(jAllParents, JsonInt(yp2));
        json jOrP = JsonObjectGet(jVF2, FK_OR);
        int nOrPLen = JsonGetLength(jOrP);
        int oipx;
        for(oipx = 0; oipx < nOrPLen; oipx++)
        {
            int nOrPP = JsonGetInt(JsonArrayGet(jOrP, oipx));
            if(nOrPP >= 0) jAllParents = JsonArrayInsert(jAllParents, JsonInt(nOrPP));
        }

        int nAllParLen = JsonGetLength(jAllParents);
        int ypp;
        for(ypp = 0; ypp < nAllParLen; ypp++)
        {
            int nPidA = JsonGetInt(JsonArrayGet(jAllParents, ypp));
            if(nPidA < 0) continue;
            json jPP = JsonObjectGet(jPositions, IntToString(nPidA));
            if(JsonGetType(jPP) != JSON_TYPE_OBJECT) continue;
            int pC = JsonGetInt(JsonObjectGet(jPP, "c"));
            int pR = JsonGetInt(JsonObjectGet(jPP, "r"));
            if(xC <= pC) continue;  // safety: child musi byc na prawo od parenta

            float fCellW = FSHOP_TREE_ICON_SIZE + FSHOP_TREE_GAP;
            float fCellH = FSHOP_TREE_ICON_SIZE + FSHOP_ROW_GAP;
            // (fParY/fChdY removed — were unused dead code)

            // Kolor strzalki = stan CHILD (target). Dla OR-relationship:
            // jezeli dziecko jest AVAILABLE/OWNED, znaczy ze przynajmniej jeden
            // OR-rodzic spelnia warunek → wszystkie strzalki zielone/zlote
            // (niezaleznie czy KONKRETNY rodzic na tej strzalce jest LOCKED).
            int nTgtSt = JsonGetInt(JsonObjectGet(jStates, IntToString(nFId3)));
            string sCol = FShopArrowSuffixForState(nTgtSt);

            // Per-gap tile chains — kazdy 32x32 tile w gap area (32px) miedzy ikonami.
            // Stretching nie dziala bo ikony sa polprzezroczyste — linia bylaby widoczna
            // przez srodek ikon. Per-gap = clean visual (ikona przerywa linie).
            // Cross-row multi-col enabled (bez cap'a) — multi-tile cost akceptowany.

            if(xR == pR)
            {
                // SAME ROW: zapisz per-spacer flags. Line i chevron mają osobne
                // kolory zeby chevron wygrywal w gapie gdzie tez przechodzi linia
                // innego edge (np. PA→Cleave chevron + PA→GC line w gap 0).
                int gapColMc;
                for(gapColMc = pC; gapColMc < xC - 1; gapColMc++)
                {
                    // intermediate gap: tylko line
                    string sKey = IntToString(xR) + "_" + IntToString(gapColMc);
                    jSpacerLine    = JsonObjectSet(jSpacerLine,    sKey, JsonInt(1));
                    jSpacerLineCol = JsonObjectSet(jSpacerLineCol, sKey, JsonString(sCol));
                }
                // last gap: linia + chevron (chevron color = priority)
                string sKeyLast = IntToString(xR) + "_" + IntToString(xC - 1);
                jSpacerLine    = JsonObjectSet(jSpacerLine,    sKeyLast, JsonInt(1));
                jSpacerChev    = JsonObjectSet(jSpacerChev,    sKeyLast, JsonInt(1));
                jSpacerLineCol = JsonObjectSet(jSpacerLineCol, sKeyLast, JsonString(sCol));
                jSpacerChevCol = JsonObjectSet(jSpacerChevCol, sKeyLast, JsonString(sCol));
            }
            else
            {
                // CROSS ROW: per-spacer dla horizontal+corner, absolute dla lv.
                // Intermediate gaps w source row: line.
                // Last gap source row: line + corner (cbl=DOWN, ctl=UP).
                // Last gap target row: corner (ctr=DOWN, cbr=UP).
                // Lv pieces miedzy rows: absolute (brak spacera miedzy).
                int gapColCr;
                for(gapColCr = pC; gapColCr < xC - 1; gapColCr++)
                {
                    string sIntKey = IntToString(pR) + "_" + IntToString(gapColCr);
                    jSpacerLine    = JsonObjectSet(jSpacerLine,    sIntKey, JsonInt(1));
                    jSpacerLineCol = JsonObjectSet(jSpacerLineCol, sIntKey, JsonString(sCol));
                }
                // Last gap source row (parent's row): line + corner top.
                // Last gap target row (child's row): corner top + chevron.
                // Corner w LEFT half spacera, chr (target only) w RIGHT half.
                // Lv x rowniez w left half — connects oba corners pionowo.
                string sSrcCornerType;
                string sChdCornerType;
                if(xR > pR)
                {
                    sSrcCornerType = "cbl";
                    sChdCornerType = "ctr";
                }
                else
                {
                    sSrcCornerType = "ctl";
                    sChdCornerType = "cbr";
                }

                // Source last gap: tylko corner (line w intermediate gaps wystarcza).
                string sParKey = IntToString(pR) + "_" + IntToString(xC - 1);
                jSpacerCorner    = JsonObjectSet(jSpacerCorner,    sParKey, JsonString(sSrcCornerType));
                jSpacerCornerCol = JsonObjectSet(jSpacerCornerCol, sParKey, JsonString(sCol));

                // Last gap target row: corner + chevron (chr po corner).
                string sChdKey = IntToString(xR) + "_" + IntToString(xC - 1);
                jSpacerCorner    = JsonObjectSet(jSpacerCorner,    sChdKey, JsonString(sChdCornerType));
                jSpacerCornerCol = JsonObjectSet(jSpacerCornerCol, sChdKey, JsonString(sCol));
                jSpacerChev      = JsonObjectSet(jSpacerChev,      sChdKey, JsonInt(1));
                jSpacerChevCol   = JsonObjectSet(jSpacerChevCol,   sChdKey, JsonString(sCol));

                // Lv per-spacer: attach do UPPER row's spacer (= mniejszy row index).
                // Local x=0 (= spacer left edge, automatycznie wyrownane).
                // Local y values relative do upper spacer top.
                int nUpperRow = (pR < xR ? pR : xR);
                int nLowerRow = (pR < xR ? xR : pR);
                string sUpperKey = IntToString(nUpperRow) + "_" + IntToString(xC - 1);

                // Lv y span: od bottom upper corner (= TILE_OFF_Y + TILE_SIZE)
                // do top lower corner (= delta_rows * CELL_H + TILE_OFF_Y).
                float fTileOffY  = (FSHOP_TREE_ICON_SIZE - FSHOP_TILE_SIZE) / 2.0;
                float fStartY    = fTileOffY + FSHOP_TILE_SIZE;
                float fEndY      = IntToFloat(nLowerRow - nUpperRow) * fCellH + fTileOffY;

                json jLvList = JsonObjectGet(jSpacerLvY, sUpperKey);
                if(JsonGetType(jLvList) != JSON_TYPE_ARRAY) jLvList = JsonArray();
                float fY;
                for(fY = fStartY; fY < fEndY; fY += FSHOP_TILE_SIZE)
                {
                    json jEntry = JsonObject();
                    jEntry = JsonObjectSet(jEntry, "y", JsonFloat(fY));
                    jEntry = JsonObjectSet(jEntry, "c", JsonString(sCol));
                    jLvList = JsonArrayInsert(jLvList, jEntry);
                }
                jSpacerLvY = JsonObjectSet(jSpacerLvY, sUpperKey, jLvList);

                // jPad cells w source row miedzy source iconą a bendem (xC-1):
                // cells pC+1 .. xC-1 dostają horizontal line (2 lh tiles per cell).
                int nCellCol;
                for(nCellCol = pC + 1; nCellCol <= xC - 1; nCellCol++)
                {
                    string sCellKey = IntToString(pR) + "_" + IntToString(nCellCol);
                    jCellHLine    = JsonObjectSet(jCellHLine,    sCellKey, JsonInt(1));
                    jCellHLineCol = JsonObjectSet(jCellHLineCol, sCellKey, JsonString(sCol));
                }
            }
        }
    }

    // Grid ikon
    json jGRows = JsonArray();
    int gr;
    for(gr = 0; gr <= nMaxRow; gr++)
    {
        json jGRowCells = JsonArray();
        int gc;
        for(gc = 0; gc <= nMaxCol; gc++)
        {
            string sK = IntToString(gc) + "_" + IntToString(gr);
            json jCell = JsonObjectGet(jSlotMap, sK);
            if(JsonGetType(jCell) == JSON_TYPE_INTEGER)
            {
                int nFId4 = JsonGetInt(jCell);
                json jFx = JsonObjectGet(jCache, IntToString(nFId4));
                // Display: jezeli focus ma specjalizacje (parens) → pokazuj
                // specific variant (BFS dal nam dokladnie matching specjalizacje
                // przez PREREQFEAT chain). Inaczej → group display przez masterfeats.
                string sIcon;
                string sName;
                if(bFocusHasSpec)
                {
                    sIcon = JsonGetString(JsonObjectGet(jFx, FK_ICON));
                    sName = JsonGetString(JsonObjectGet(jFx, FK_NAME));
                }
                else
                {
                    json jDisp = FShopGetFeatDisplayData(jFx);
                    sIcon = JsonGetString(JsonObjectGet(jDisp, FK_MF_ICON));
                    sName = JsonGetString(JsonObjectGet(jDisp, FK_MF_NAME));
                }

                int nIcSt = JsonGetInt(JsonObjectGet(jStates, IntToString(nFId4)));
                json jBtn = NuiButtonImage(JsonString(sIcon));
                jBtn = NuiId(jBtn, FSHOP_BTN_TREE_FEAT_PRE + IntToString(nFId4));
                jBtn = NuiWidth(jBtn, FSHOP_TREE_ICON_SIZE);
                jBtn = NuiHeight(jBtn, FSHOP_TREE_ICON_SIZE);
                jBtn = NuiTooltip(jBtn, JsonString(sName));
                jBtn = NuiStyleForegroundColor(jBtn, FShopColorForState(nIcSt));
                jGRowCells = JsonArrayInsert(jGRowCells, jBtn);
            }
            else
            {
                json jPad = NuiLabel(JsonString(""),
                                     JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
                jPad = NuiWidth(jPad, FSHOP_TREE_ICON_SIZE);
                jPad = NuiHeight(jPad, FSHOP_TREE_ICON_SIZE);

                // Per-cell DrawList: jezeli horizontal line przechodzi przez ten
                // empty cell (cross-row source row path), narysuj 2 lh tiles zeby
                // wypelnic cala 64px szerokosc cella.
                string sCellKey = IntToString(gr) + "_" + IntToString(gc);
                if(JsonGetType(JsonObjectGet(jCellHLine, sCellKey)) == JSON_TYPE_INTEGER)
                {
                    string sCellLineCol = JsonGetString(JsonObjectGet(jCellHLineCol, sCellKey));
                    float fCellLocalY = (FSHOP_TREE_ICON_SIZE - FSHOP_TILE_SIZE) / 2.0;
                    json jCellDraws = JsonArray();
                    jCellDraws = FShopDrawLh(jCellDraws, 0.0,             fCellLocalY, sCellLineCol);
                    jCellDraws = FShopDrawLh(jCellDraws, FSHOP_TILE_SIZE, fCellLocalY, sCellLineCol);
                    jPad = NuiDrawList(jPad, JsonBool(FALSE), jCellDraws);
                }

                jGRowCells = JsonArrayInsert(jGRowCells, jPad);
            }
            // Spacer miedzy kolumnami z per-spacer DrawList (lokalne wspolrzedne).
            // Y center = (FSHOP_ICON_SIZE - 32) / 2 = 16. Eliminuje absolute alignment.
            if(gc < nMaxCol)
            {
                string sSpKey = IntToString(gr) + "_" + IntToString(gc);
                int bHasLine = (JsonGetType(JsonObjectGet(jSpacerLine, sSpKey)) == JSON_TYPE_INTEGER);
                int bHasChev = (JsonGetType(JsonObjectGet(jSpacerChev, sSpKey)) == JSON_TYPE_INTEGER);
                json jSpDraws = JsonArray();

                int bHasCorner = (JsonGetType(JsonObjectGet(jSpacerCorner, sSpKey)) == JSON_TYPE_STRING);
                json jLvList = JsonObjectGet(jSpacerLvY, sSpKey);
                int bHasLv = (JsonGetType(jLvList) == JSON_TYPE_ARRAY && JsonGetLength(jLvList) > 0);
                if(bHasLv)
                {
                    // Lv tiles per-spacer: lokalny x=0, y z jLvList (moze wykraczac
                    // poza spacer bounds, NUI renderuje outside)
                    int nLvIdx;
                    int nLvLen = JsonGetLength(jLvList);
                    for(nLvIdx = 0; nLvIdx < nLvLen; nLvIdx++)
                    {
                        json jLvEntry = JsonArrayGet(jLvList, nLvIdx);
                        float fLvLocalY = JsonGetFloat(JsonObjectGet(jLvEntry, "y"));
                        string sLvCol = JsonGetString(JsonObjectGet(jLvEntry, "c"));
                        jSpDraws = FShopDrawLv(jSpDraws, 0.0, fLvLocalY, sLvCol);
                    }
                }
                if(bHasLine || bHasChev || bHasCorner)
                {
                    // Priorytet kolorow: corner > chevron > line
                    string sLineCol = JsonGetString(JsonObjectGet(jSpacerLineCol, sSpKey));
                    string sChevCol = JsonGetString(JsonObjectGet(jSpacerChevCol, sSpKey));
                    string sCornerCol = JsonGetString(JsonObjectGet(jSpacerCornerCol, sSpKey));
                    string sFinalCol;
                    if(bHasCorner && sCornerCol != "") sFinalCol = sCornerCol;
                    else if(bHasChev && sChevCol != "") sFinalCol = sChevCol;
                    else if(bHasLine && sLineCol != "") sFinalCol = sLineCol;
                    else                                sFinalCol = "v";

                    // Order: lh → chr → corner (corner LAST = na wierzchu
                    // jezeli NUI renderuje insertion order = later=top).
                    float fLocalY = (FSHOP_TREE_ICON_SIZE - FSHOP_TILE_SIZE) / 2.0;
                    if(bHasLine)
                        jSpDraws = FShopDrawLh(jSpDraws, 0.0, fLocalY, sFinalCol);
                    if(bHasChev)
                        jSpDraws = FShopDrawChr(jSpDraws, 5.0, fLocalY, sFinalCol);  // +5 shift
                    if(bHasCorner)
                    {
                        string sCornerType = JsonGetString(JsonObjectGet(jSpacerCorner, sSpKey));
                        jSpDraws = FShopDrawCorner(jSpDraws, 0.0, fLocalY, sCornerType, sFinalCol);
                    }
                }

                json jGap = NuiLabel(JsonString(""),
                                     JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
                jGap = NuiWidth(jGap, FSHOP_TREE_GAP);
                jGap = NuiHeight(jGap, FSHOP_TREE_ICON_SIZE);
                if(JsonGetLength(jSpDraws) > 0)
                    jGap = NuiDrawList(jGap, JsonBool(FALSE), jSpDraws);
                jGRowCells = JsonArrayInsert(jGRowCells, jGap);
            }
        }
        jGRowCells = JsonArrayInsert(jGRowCells, NuiSpacer());
        // NuiHeight na NuiRow = ICON_SIZE + ROW_GAP = pelna wysokosc cell-step.
        // KONIECZNE — cross-row lv math uzywa fCellH=96 (delta_rows * 96).
        // Bez tego row ma natural height=64 i lv tiles ladują w złych Y.
        json jGRow = NuiRow(jGRowCells);
        jGRow = NuiHeight(jGRow, FSHOP_TREE_ICON_SIZE + FSHOP_ROW_GAP);
        jGRows = JsonArrayInsert(jGRows, jGRow);
    }

    json jGrid = NuiCol(jGRows);
    jGrid = NuiDrawList(jGrid, JsonBool(FALSE), jArrows);
    json jScroll = NuiGroup(jGrid, TRUE, NUI_SCROLLBARS_AUTO);

    // === Right info panel — header (ikona+nazwa+opis) w grupie z ramka ===
    json jRightChildren = JsonArray();

    json jHeader = BuildFShopFeatHeader(FSHOP_BIND_TREE_SEL_ICON, FSHOP_BIND_TREE_SEL_NAME,
                                        FSHOP_BIND_TREE_SEL_COL,  FSHOP_BIND_TREE_SEL_DESC,
                                        450.0, 320.0);
    jRightChildren = JsonArrayInsert(jRightChildren, jHeader);

    // Vertical stack: "Wstecz" (history pop) na gorze, "Pokaz drzewo" (refocus tree) na dole.
    json jBackBtn = NuiButton(JsonString("Back"));
    jBackBtn = NuiId(jBackBtn, FSHOP_BTN_TREE_BACK);
    jBackBtn = NuiHeight(jBackBtn, 40.0);
    jRightChildren = JsonArrayInsert(jRightChildren, jBackBtn);

    json jRefocusBtn = NuiButton(JsonString("Show Tree"));
    jRefocusBtn = NuiId(jRefocusBtn, FSHOP_BTN_TREE_REFOCUS);
    jRefocusBtn = NuiHeight(jRefocusBtn, 40.0);
    jRightChildren = JsonArrayInsert(jRightChildren, jRefocusBtn);

    json jRPanel = NuiCol(jRightChildren);
    jRPanel = NuiWidth(jRPanel, 320.0);

    // === Body row: tree grid + right panel ===
    json jBody = JsonArray();
    jBody = JsonArrayInsert(jBody, jScroll);
    jBody = JsonArrayInsert(jBody, jRPanel);
    json jBodyRow = NuiRow(jBody);

    string sFocusName = JsonGetString(JsonObjectGet(jFocus, FK_NAME));

    json jWindow = NuiWindow(
        jBodyRow,
        JsonString("Tree: " + sFocusName),
        NuiBind(FSHOP_BIND_TREE_GEOM),
        JsonBool(TRUE),    // resizable
        JsonBool(FALSE),
        JsonBool(TRUE),    // closable
        JsonBool(FALSE),
        JsonBool(TRUE)
    );

    int nToken = NuiCreate(oPC, jWindow, FSHOP_TREE_WIN_ID, "lib_fshop_ev");
    SetLocalInt(oPC, FSHOP_LVAR_TREE_TOKEN, nToken);
    SetLocalInt(oPC, FSHOP_LVAR_TREE_PANEL, nFocusFeatId + 1);  // +1 zeby 0 oznaczalo "brak"
    SetLocalInt(oPC, FSHOP_LVAR_TREE_FOCUS, nFocusFeatId + 1);  // +1 offset jak panel
    SetLocalInt(oPC, FSHOP_LVAR_TREE_F_SPEC, bFocusHasSpec);    // ustawiony juz wczesniej
    NuiSetBind(oPC, nToken, FSHOP_BIND_TREE_GEOM, NuiRect(-1.0, -1.0, 1300.0, 700.0));

    // Init right panel binds — wstepnie pokazuje focused feat
    string sFocusDesc = JsonGetString(JsonObjectGet(jFocus, FK_DESC));
    string sFocusIcon = JsonGetString(JsonObjectGet(jFocus, FK_ICON));
    string sPrereqText = FShopBuildPrereqText(jCache, jFocus);

    NuiSetBind(oPC, nToken, FSHOP_BIND_TREE_SEL_NAME, JsonString(sFocusName));
    NuiSetBind(oPC, nToken, FSHOP_BIND_TREE_SEL_DESC, JsonString(sPrereqText + "\n\n" + sFocusDesc));
    NuiSetBind(oPC, nToken, FSHOP_BIND_TREE_SEL_ICON, JsonString(sFocusIcon));
    NuiSetBind(oPC, nToken, FSHOP_BIND_TREE_SEL_COL,  NuiColor(255, 255, 255, 255));
}

void DestroyFShopTreeWindow(object oPC)
{
    int nToken = GetLocalInt(oPC, FSHOP_LVAR_TREE_TOKEN);
    if(nToken > 0) NuiDestroy(oPC, nToken);
    DeleteLocalInt(oPC, FSHOP_LVAR_TREE_TOKEN);
    DeleteLocalInt(oPC, FSHOP_LVAR_TREE_PANEL);
    DeleteLocalInt(oPC, FSHOP_LVAR_TREE_FOCUS);
    DeleteLocalInt(oPC, FSHOP_LVAR_TREE_F_SPEC);
    DeleteLocalJson(oPC, FSHOP_LVAR_TREE_HISTORY);
}


// Aktualizuje right panel binds tree window'a dla danego feata.
// Wywolywane przez tree feat click handler ORAZ Wstecz (history pop).
// Spojny display:
//   focus has spec → raw feat data (specific variant + prereqi)
//   focus standalone → group display (gdy MF >= 0, bez prereqow)
void FeedFShopTreePanel(object oPC, int nTreeToken, int nFeatId)
{
    if(nTreeToken <= 0) return;
    json jCache = FShopGetCache();
    json jFeat = JsonObjectGet(jCache, IntToString(nFeatId));
    if(JsonGetType(jFeat) != JSON_TYPE_OBJECT) return;

    int bFocusHasSpec = GetLocalInt(oPC, FSHOP_LVAR_TREE_F_SPEC);
    string sName;
    string sDesc;
    string sIcon;
    if(bFocusHasSpec)
    {
        sName = JsonGetString(JsonObjectGet(jFeat, FK_NAME));
        sDesc = JsonGetString(JsonObjectGet(jFeat, FK_DESC));
        sIcon = JsonGetString(JsonObjectGet(jFeat, FK_ICON));
    }
    else
    {
        json jDisp = FShopGetFeatDisplayData(jFeat);
        sName = JsonGetString(JsonObjectGet(jDisp, FK_MF_NAME));
        sDesc = JsonGetString(JsonObjectGet(jDisp, FK_MF_DESC));
        sIcon = JsonGetString(JsonObjectGet(jDisp, FK_MF_ICON));
    }

    int nMf = JsonGetInt(JsonObjectGet(jFeat, FK_MF));
    string sBody;
    if(bFocusHasSpec || nMf < 0)
    {
        string sPrereq = FShopBuildPrereqText(jCache, jFeat);
        sBody = sPrereq + "\n\n" + sDesc;
    }
    else
    {
        sBody = sDesc;
    }

    NuiSetBind(oPC, nTreeToken, FSHOP_BIND_TREE_SEL_NAME, JsonString(sName));
    NuiSetBind(oPC, nTreeToken, FSHOP_BIND_TREE_SEL_DESC, JsonString(sBody));
    NuiSetBind(oPC, nTreeToken, FSHOP_BIND_TREE_SEL_ICON, JsonString(sIcon));
    NuiSetBind(oPC, nTreeToken, FSHOP_BIND_TREE_SEL_COL,  NuiColor(255, 255, 255, 255));

    // Track aktualnie wyswietlany feat w panelu (dla Pokaz drzewo refocus)
    SetLocalInt(oPC, FSHOP_LVAR_TREE_PANEL, nFeatId + 1);
}


// ============================================================================
// VARIANT PICKER WINDOW — popup po kliknieciu "Detale"
// ============================================================================
//
// Pokazuje wszystkie warianty z rodziny aktualnie wybranego feata. Klikniecie
// w wariant przelacza tryb na SPECIFIC i odswieza main info panel.

void CreateFShopVariantWindow(object oPC, int nRepFeatId)
{
    if(GetLocalInt(GetModule(), FSHOP_LVAR_BUILT) != 1) return;

    DestroyFShopVariantWindow(oPC);

    json jCache = FShopGetCache();
    json jRep = JsonObjectGet(jCache, IntToString(nRepFeatId));
    if(JsonGetType(jRep) != JSON_TYPE_OBJECT) return;

    json jVariants = FShopGetFamilyVariants(jCache, nRepFeatId, jRep);
    int nVarLen = JsonGetLength(jVariants);
    if(nVarLen <= 1) return;  // standalone — nie ma sensu otwierac

    string sBase = FShopGetNameBase(JsonGetString(JsonObjectGet(jRep, FK_NAME)));
    if(sBase == "") sBase = JsonGetString(JsonObjectGet(jRep, FK_NAME));

    // Pre-build states map dla wariantow (potrzebne do kolorowania)
    json jClassSet = FShopBuildClassFeatSet(oPC);
    json jStates = JsonObject();
    int si;
    for(si = 0; si < nVarLen; si++)
    {
        int nVId = JsonGetInt(JsonArrayGet(jVariants, si));
        json jVF = JsonObjectGet(jCache, IntToString(nVId));
        int nSt = FShopGetState(oPC, nVId, jVF, jClassSet);
        jStates = JsonObjectSet(jStates, IntToString(nVId), JsonInt(nSt));
    }

    // ---- Build list rows: ikona + przycisk z pelna nazwa wariantu ----
    json jRows = JsonArray();
    int vi;
    for(vi = 0; vi < nVarLen; vi++)
    {
        int nVId = JsonGetInt(JsonArrayGet(jVariants, vi));
        json jVF = JsonObjectGet(jCache, IntToString(nVId));
        if(JsonGetType(jVF) != JSON_TYPE_OBJECT) continue;

        string sVName = JsonGetString(JsonObjectGet(jVF, FK_NAME));
        string sVIcon = JsonGetString(JsonObjectGet(jVF, FK_ICON));
        int nVSt = JsonGetInt(JsonObjectGet(jStates, IntToString(nVId)));

        json jRowChildren = JsonArray();

        json jImg = NuiImage(JsonString(sVIcon),
                             JsonInt(NUI_ASPECT_FIT),
                             JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
        jImg = NuiWidth(jImg, FSHOP_ICON_SIZE);
        jImg = NuiHeight(jImg, FSHOP_ICON_SIZE);
        jRowChildren = JsonArrayInsert(jRowChildren, jImg);

        json jLbl = NuiLabel(JsonString(sVName),
                             JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
        jLbl = NuiHeight(jLbl, FSHOP_ICON_SIZE + 14.0);
        jLbl = NuiStyleForegroundColor(jLbl, FShopColorForState(nVSt));
        jRowChildren = JsonArrayInsert(jRowChildren, jLbl);

        json jRow = NuiGroup(NuiRow(jRowChildren), TRUE, NUI_SCROLLBARS_NONE);
        jRow = NuiId(jRow, FSHOP_BTN_VAR_FEAT_PRE + IntToString(nVId));
        jRow = NuiHeight(jRow, FSHOP_ICON_SIZE + 14.0);
        jRows = JsonArrayInsert(jRows, jRow);
    }

    json jList = NuiGroup(NuiCol(jRows), TRUE, NUI_SCROLLBARS_AUTO);

    // Window
    json jWindow = NuiWindow(
        jList,
        JsonString("Select variant: " + sBase),
        NuiBind(FSHOP_BIND_VAR_GEOM),
        JsonBool(TRUE),    // resizable
        JsonBool(FALSE),
        JsonBool(TRUE),    // closable
        JsonBool(FALSE),
        JsonBool(TRUE)
    );

    int nToken = NuiCreate(oPC, jWindow, FSHOP_VAR_WIN_ID, "lib_fshop_ev");
    SetLocalInt(oPC, FSHOP_LVAR_VAR_TOKEN, nToken);
    NuiSetBind(oPC, nToken, FSHOP_BIND_VAR_GEOM, NuiRect(-1.0, -1.0, 480.0, 500.0));
}

void DestroyFShopVariantWindow(object oPC)
{
    int nToken = GetLocalInt(oPC, FSHOP_LVAR_VAR_TOKEN);
    if(nToken > 0) NuiDestroy(oPC, nToken);
    DeleteLocalInt(oPC, FSHOP_LVAR_VAR_TOKEN);
}

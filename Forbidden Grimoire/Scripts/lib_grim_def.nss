#include "lib_nui"
#include "sql_grim"

void GrimOpenWindow(object oPC);
void GrimFeedFragmentList(object oPC, int nToken);
void GrimFeedSlots(object oPC, int nToken);
void GrimFeedResult(object oPC, int nToken, string sText);
void GrimOpenCodexWindow(object oPC);

// ----------------------------------------------------------------
// Constants
// ----------------------------------------------------------------

const string GRIM_WINDOW         = "GRIM_WINDOW";
const string GRIM_EV_SCRIPT      = "lib_grim_ev";
const string GRIM_WIN_CODEX      = "GRIM_WIN_CODEX";

// Fragment arcane types
const int GRIM_TYPE_IGNIS   = 0;
const int GRIM_TYPE_GLACIES  = 1;
const int GRIM_TYPE_UMBRA   = 2;
const int GRIM_TYPE_VOID    = 3;
const int GRIM_TYPE_VITA    = 4;
const int GRIM_TYPE_COUNT   = 5;

// Item tag prefix; full tag = GRIM_FRAG_PREFIX + IntToString(type) + "_" + IntToString(tier)
// e.g. "gf_0_1" = Minor Ignis Fragment
const string GRIM_FRAG_PREFIX   = "gf_";

const int GRIM_SLOT_COUNT       = 2;
const int GRIM_RECIPE_COUNT     = 8;
const int GRIM_MASTERY_USES     = 3;   // successful uses to reach mastery
const int GRIM_FREE_CAST_CD     = 86400; // seconds between free masterly casts (24h)

// Window dimensions
const float GRIM_W              = 680.0;
const float GRIM_H              = 500.0;

// Binds — fragment list (list arrays)
const string GRIM_BIND_FRAG_NAME    = "grim_frag_name";
const string GRIM_BIND_FRAG_TYPE    = "grim_frag_type";
const string GRIM_BIND_FRAG_AVAIL   = "grim_frag_avail";
const string GRIM_BIND_FRAG_ENC     = "grim_frag_enc";
const string GRIM_BIND_FRAG_ROWCNT  = "grim_frag_rowcnt";

// Binds — selected research slots (append "0" or "1")
const string GRIM_BIND_SLOT_LBL     = "grim_slot_lbl";
const string GRIM_BIND_SLOT_ENA     = "grim_slot_ena";

// Binds — controls and output
const string GRIM_BIND_RESULT       = "grim_result";
const string GRIM_BIND_RESEARCH_ENA = "grim_res_ena";
const string GRIM_BIND_WIN_GEOM     = "grim_win_geom";

// Buttons
const string GRIM_BTN_CLOSE         = "grim_btn_close";
const string GRIM_BTN_RESEARCH      = "grim_btn_research";
const string GRIM_BTN_CODEX         = "grim_btn_codex";
const string GRIM_BTN_FRAG_ROW      = "grim_btn_frow";
const string GRIM_BTN_CLEAR_SLOT    = "grim_btn_clr";   // + "0" or "1"

// Codex popup binds
const string GRIM_BIND_COD_NAME     = "grim_cod_name";
const string GRIM_BIND_COD_REQ      = "grim_cod_req";
const string GRIM_BIND_COD_USES     = "grim_cod_uses";
const string GRIM_BIND_COD_MASTER   = "grim_cod_master";
const string GRIM_BIND_COD_CAST_ENA = "grim_cod_cast_ena";
const string GRIM_BIND_COD_ROWCNT   = "grim_cod_rowcnt";
const string GRIM_BTN_COD_CAST      = "grim_cod_cast";  // + IntToString(recipe_id)

// LVARs on PC
const string GRIM_LVAR_SEL          = "GRIM_SELECTED";   // JsonArray of {type, tier}, max 2
const string GRIM_LVAR_FRAG_ROWS    = "GRIM_FRAG_ROWS";  // display list: [{type, tier, total}]

// ----------------------------------------------------------------
// Fragment / recipe helpers
// ----------------------------------------------------------------

string GrimTypeName(int nType)
{
    if(nType == GRIM_TYPE_IGNIS)   return "Ignis";
    if(nType == GRIM_TYPE_GLACIES)  return "Glacies";
    if(nType == GRIM_TYPE_UMBRA)   return "Umbra";
    if(nType == GRIM_TYPE_VOID)    return "Void";
    if(nType == GRIM_TYPE_VITA)    return "Vita";
    return "?";
}

string GrimTierName(int nTier)
{
    if(nTier == 1) return "Mniejszy";
    if(nTier == 2) return "Większy";
    if(nTier == 3) return "Szczytowy";
    return "?";
}

string GrimFragName(int nType, int nTier)
{
    return GrimTierName(nTier) + " Fragment " + GrimTypeName(nType);
}

// Item tag for a fragment of given type+tier
string GrimFragTag(int nType, int nTier)
{
    return GRIM_FRAG_PREFIX + IntToString(nType) + "_" + IntToString(nTier);
}

// ----------------------------------------------------------------
// Recipe data
// ----------------------------------------------------------------

struct GrimRecipe
{
    int     nType0;
    int     nTier0;
    int     nType1;
    int     nTier1;
    string  sName;
    string  sDesc;
    int     nEffectId;
};

struct GrimRecipe GrimGetRecipe(int nId)
{
    struct GrimRecipe r;
    r.nType0 = 0; r.nTier0 = 0; r.nType1 = 0; r.nTier1 = 0;
    r.sName = ""; r.sDesc = ""; r.nEffectId = 0;
    switch(nId)
    {
        case 1:
            r.nType0=GRIM_TYPE_IGNIS;   r.nTier0=1;
            r.nType1=GRIM_TYPE_IGNIS;   r.nTier1=1;
            r.sName="Kula Ognia";
            r.sDesc="Ogniste kule rozrywają ciało wrogów.";
            r.nEffectId=1; break;
        case 2:
            r.nType0=GRIM_TYPE_GLACIES;  r.nTier0=1;
            r.nType1=GRIM_TYPE_GLACIES;  r.nTier1=1;
            r.sName="Lodowy Uścisk";
            r.sDesc="Mróz spowija wroga jak całun śmierci.";
            r.nEffectId=2; break;
        case 3:
            r.nType0=GRIM_TYPE_UMBRA;   r.nTier0=1;
            r.nType1=GRIM_TYPE_UMBRA;   r.nTier1=1;
            r.sName="Zasłona Mroku";
            r.sDesc="Ciemność zaślepia i paraliżuje zmysły.";
            r.nEffectId=3; break;
        case 4:
            r.nType0=GRIM_TYPE_VOID;    r.nTier0=1;
            r.nType1=GRIM_TYPE_VOID;    r.nTier1=1;
            r.sName="Pustka Rozdarcia";
            r.sDesc="Pustka pochłania materię bez śladu.";
            r.nEffectId=4; break;
        case 5:
            r.nType0=GRIM_TYPE_VITA;    r.nTier0=1;
            r.nType1=GRIM_TYPE_VITA;    r.nTier1=1;
            r.sName="Tchnięcie Życia";
            r.sDesc="Życiodajna energia zszywa rany i goi kości.";
            r.nEffectId=5; break;
        case 6:
            r.nType0=GRIM_TYPE_IGNIS;   r.nTier0=2;
            r.nType1=GRIM_TYPE_VITA;    r.nTier1=1;
            r.sName="Żar Krwi";
            r.sDesc="Broń bucha żywym ogniem wzmocnionym krwią.";
            r.nEffectId=6; break;
        case 7:
            r.nType0=GRIM_TYPE_GLACIES;  r.nTier0=2;
            r.nType1=GRIM_TYPE_UMBRA;   r.nTier1=1;
            r.sName="Widmo Zimy";
            r.sDesc="Lodowy strach paraliżuje duszę ofiary.";
            r.nEffectId=7; break;
        case 8:
            r.nType0=GRIM_TYPE_VOID;    r.nTier0=2;
            r.nType1=GRIM_TYPE_UMBRA;   r.nTier1=2;
            r.sName="Rozdarcie Duszy";
            r.sDesc="Zakazana formuła niszcząca dusze wokół ciebie.";
            r.nEffectId=8; break;
    }
    return r;
}

// Returns recipe id matching combination, or -1 if unknown.
// Order of fragments does not matter.
int GrimMatchRecipe(int nType0, int nTier0, int nType1, int nTier1)
{
    int i;
    for(i = 1; i <= GRIM_RECIPE_COUNT; i++)
    {
        struct GrimRecipe r = GrimGetRecipe(i);
        int bFwd = (r.nType0 == nType0 && r.nTier0 == nTier0 &&
                    r.nType1 == nType1 && r.nTier1 == nTier1);
        int bRev = (r.nType0 == nType1 && r.nTier0 == nTier1 &&
                    r.nType1 == nType0 && r.nTier1 == nTier0);
        if(bFwd || bRev) return i;
    }
    return -1;
}

// Combined caster level (all spellcasting classes)
int GrimGetCasterLevel(object oPC)
{
    int nCl = 0;
    nCl += GetLevelByClass(oPC, CLASS_TYPE_WIZARD);
    nCl += GetLevelByClass(oPC, CLASS_TYPE_SORCERER);
    nCl += GetLevelByClass(oPC, CLASS_TYPE_CLERIC);
    nCl += GetLevelByClass(oPC, CLASS_TYPE_DRUID);
    nCl += GetLevelByClass(oPC, CLASS_TYPE_BARD);
    nCl += GetLevelByClass(oPC, CLASS_TYPE_PALADIN);
    nCl += GetLevelByClass(oPC, CLASS_TYPE_RANGER);
    return nCl;
}

// Research success chance 30-90%, scales with caster level
int GrimResearchChance(object oPC)
{
    int nBase   = 40;
    int nBonus  = GrimGetCasterLevel(oPC) * 3;
    int nChance = nBase + nBonus;
    if(nChance > 90) nChance = 90;
    if(nChance < 30) nChance = 30;
    return nChance;
}

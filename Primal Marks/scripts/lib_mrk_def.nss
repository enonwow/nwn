#include "lib_nui"
#include "sql_mrk"

// ----------------------------------------------------------------
// Window / event identifiers
// ----------------------------------------------------------------

const string MRK_WINDOW         = "MRK_WINDOW";
const string MRK_EV_SCRIPT      = "lib_mrk_ev";
const string MRK_WIN_GEOM       = "mrk_win_geom";
const string MRK_GRP_CONTENT    = "mrk_grp_content";

// ----------------------------------------------------------------
// Essence type indices
// ----------------------------------------------------------------

const int MRK_TYPE_BEAST        = 0;
const int MRK_TYPE_UNDEAD       = 1;
const int MRK_TYPE_ELEMENTAL    = 2;
const int MRK_TYPE_INFERNAL     = 3;
const int MRK_TYPE_FEY          = 4;
const int MRK_TYPE_COUNT        = 5;

// ----------------------------------------------------------------
// Gameplay tuning
// ----------------------------------------------------------------

const int   MRK_THRESHOLD       = 100;    // essence to enable transform
const int   MRK_TRANSFORM_COST  = 100;    // spent on activation
const int   MRK_BRAND_TOTAL     = 500;    // cumulative kills before brand triggers
const float MRK_TRANSFORM_DUR   = 180.0;  // seconds active
const float MRK_COOLDOWN        = 600.0;  // seconds between uses of same type
const int   MRK_ESSENCE_MIN     = 5;
const int   MRK_ESSENCE_MAX     = 50;

// ----------------------------------------------------------------
// NUI bind names (prefix mrk_)
// ----------------------------------------------------------------

const string MRK_BIND_BARLBL    = "mrk_bl";   // + IntToString(type)
const string MRK_BIND_BARVAL    = "mrk_bv";   // + IntToString(type): float 0.0-1.0
const string MRK_BIND_BARPCT    = "mrk_bp";   // + IntToString(type): "nn / 100"
const string MRK_BIND_BTN_ENA   = "mrk_be";   // + IntToString(type)
const string MRK_BIND_BTN_LBL   = "mrk_bl2";  // + IntToString(type)
const string MRK_BIND_STATUS    = "mrk_st";   // + IntToString(type)
const string MRK_BIND_BRAND_LBL = "mrk_brd";  // + IntToString(type)
const string MRK_BIND_BRAND_VIS = "mrk_brv";  // + IntToString(type): JsonBool
const string MRK_BIND_INFO      = "mrk_info";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string MRK_BTN_CLOSE      = "mrk_close";
const string MRK_BTN_TRANSFORM  = "mrk_tf";   // + IntToString(type)

// ----------------------------------------------------------------
// Local variables on PC
// ----------------------------------------------------------------

const string MRK_LVAR_ACTIVE    = "MRK_ACTIVE";   // active type index, -1 = none
const string MRK_LVAR_CD        = "MRK_CD_";      // + IntToString(type): float expiry time
const string MRK_LVAR_TRANSFORM = "MRK_TF_END";   // float: when transform expires

// ----------------------------------------------------------------
// Window dimensions
// ----------------------------------------------------------------

const float MRK_W               = 480.0;
const float MRK_H               = 530.0;

// ----------------------------------------------------------------
// Flavor helpers
// ----------------------------------------------------------------

string MrkTypeName(int nType)
{
    switch(nType)
    {
        case MRK_TYPE_BEAST:     return "Bestia";
        case MRK_TYPE_UNDEAD:    return "Nieumarły";
        case MRK_TYPE_ELEMENTAL: return "Żywioł";
        case MRK_TYPE_INFERNAL:  return "Piekielny";
        case MRK_TYPE_FEY:       return "Mroczna Feja";
    }
    return "Nieznane";
}

string MrkTypeDesc(int nType)
{
    switch(nType)
    {
        case MRK_TYPE_BEAST:
            return "+2 atak, +5 Czujność/Tropienie, Regeneracja 1 HP/6s";
        case MRK_TYPE_UNDEAD:
            return "+2 pancerz, Aura strachu (5m), Odporność na Strach";
        case MRK_TYPE_ELEMENTAL:
            return "+3 Ochrona Ognia/Zimna/Elektryczności, +1 runda/zaczar";
        case MRK_TYPE_INFERNAL:
            return "+2 STR, Mroczny ogień: 1d6 dodatkowych obrażeń, +4 Zastraszanie";
        case MRK_TYPE_FEY:
            return "+4 Zwinność, Zacieranie +20%, +2 Odporność na czary";
    }
    return "";
}

string MrkBrandFlavor(int nType)
{
    switch(nType)
    {
        case MRK_TYPE_BEAST:
            return "Piętno Bestii — oczy płoną złotawo, kły lekko wydłużone. +1 STR.";
        case MRK_TYPE_UNDEAD:
            return "Piętno Nieumarłego — skóra blada jak marmur, cień zimna w oddechu. +1 CON.";
        case MRK_TYPE_ELEMENTAL:
            return "Piętno Żywiołu — żyły jarząc się słabą poświatą. +3 Odp. na ogień.";
        case MRK_TYPE_INFERNAL:
            return "Piętno Piekielne — zapach siarki, oczy płoną czerwienią w mroku. +1 CHA.";
        case MRK_TYPE_FEY:
            return "Piętno Mrocznej Feji — ruchy ciche jak cień, głos melodyjny i niepokojący. +1 DEX.";
    }
    return "";
}

// Column names used in SQL queries
string MrkColName(int nType)
{
    switch(nType)
    {
        case MRK_TYPE_BEAST:     return "beast";
        case MRK_TYPE_UNDEAD:    return "undead";
        case MRK_TYPE_ELEMENTAL: return "elemental";
        case MRK_TYPE_INFERNAL:  return "infernal";
        case MRK_TYPE_FEY:       return "fey";
    }
    return "beast";
}

// Read one essence value from loaded data json
int MrkGetEssenceFromData(json jData, int nType)
{
    return JsonGetInt(JsonObjectGet(jData, MrkColName(nType)));
}

int MrkGetTotalFromData(json jData, int nType)
{
    return JsonGetInt(JsonObjectGet(jData, MrkColName(nType) + "_total"));
}

// Classify victim into an essence type; returns -1 if irrelevant
int MrkGetEssenceType(object oVictim)
{
    int nRace = GetRacialType(oVictim);
    switch(nRace)
    {
        case RACIAL_TYPE_ANIMAL:
        case RACIAL_TYPE_BEAST:
        case RACIAL_TYPE_MAGICAL_BEAST:
            return MRK_TYPE_BEAST;
        case RACIAL_TYPE_UNDEAD:
            return MRK_TYPE_UNDEAD;
        case RACIAL_TYPE_ELEMENTAL:
            return MRK_TYPE_ELEMENTAL;
        case RACIAL_TYPE_FEY:
            return MRK_TYPE_FEY;
        case RACIAL_TYPE_OUTSIDER:
            if(GetAlignmentGoodEvil(oVictim) == ALIGNMENT_EVIL)
                return MRK_TYPE_INFERNAL;
            return MRK_TYPE_FEY;
    }
    return -1;
}

// Essence gained per kill: scales with challenge rating
int MrkEssenceFromKill(object oVictim)
{
    int nCR  = FloatToInt(GetChallengeRating(oVictim));
    int nEss = nCR * 5;
    if(nEss < MRK_ESSENCE_MIN) nEss = MRK_ESSENCE_MIN;
    if(nEss > MRK_ESSENCE_MAX) nEss = MRK_ESSENCE_MAX;
    return nEss;
}

// Visual effect per type (applied during transform)
int MrkTransformVFX(int nType)
{
    switch(nType)
    {
        case MRK_TYPE_BEAST:     return VFX_DUR_PROTECTION_ELEMENTS;
        case MRK_TYPE_UNDEAD:    return VFX_DUR_GHOST_SMOKE;
        case MRK_TYPE_ELEMENTAL: return VFX_DUR_PROTECTION_ELEMENTS;
        case MRK_TYPE_INFERNAL:  return VFX_DUR_DARKFIRE;
        case MRK_TYPE_FEY:       return VFX_DUR_BLUR;
    }
    return VFX_DUR_BLUR;
}

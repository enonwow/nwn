#include "lib_nui"
#include "sql_echo"

void EchoOpenDetector(object oPC);
void EchoFeedTraceList(object oPC, int nToken);
void EchoFeedDetail(object oPC, int nToken, int nTraceId);
void EchoFeedDetailEmpty(object oPC, int nToken);
void EchoOnSpellCast(object oCaster, int nSpellId);
string EchoBuildCasterMask(object oCaster);

// ----------------------------------------------------------------
// Window / element IDs
// ----------------------------------------------------------------

const string ECHO_WINDOW         = "ECHO_WINDOW";
const string ECHO_EV_SCRIPT      = "lib_echo_ev";
const string ECHO_GRP_DETAIL     = "ECHO_GRP_DETAIL";
const string ECHO_WIN_GEOM       = "echo_win_geom";

// Binds — trace list
const string ECHO_BIND_SCHOOL_LBL   = "echo_school";
const string ECHO_BIND_AGE_LBL      = "echo_age";
const string ECHO_BIND_INTENSITY    = "echo_intensity";
const string ECHO_BIND_SPELL_LBL    = "echo_spell";
const string ECHO_BIND_ROW_ENC      = "echo_enc";
const string ECHO_BIND_ROW_COLOR    = "echo_color";

// Binds — detail pane
const string ECHO_BIND_DETAIL_SCHOOL  = "echo_det_school";
const string ECHO_BIND_DETAIL_AGE     = "echo_det_age";
const string ECHO_BIND_DETAIL_SPELL   = "echo_det_spell";
const string ECHO_BIND_DETAIL_POWER   = "echo_det_power";
const string ECHO_BIND_DETAIL_CASTER  = "echo_det_caster";
const string ECHO_BIND_DETAIL_ERASE   = "echo_det_erase";
const string ECHO_BIND_ERASE_ENA      = "echo_erase_ena";
const string ECHO_BIND_ERASE_LBL      = "echo_erase_lbl";

// Buttons
const string ECHO_BTN_CLOSE        = "echo_btn_close";
const string ECHO_BTN_ROW          = "echo_btn_row";
const string ECHO_BTN_ERASE        = "echo_btn_erase";
const string ECHO_BTN_REFRESH      = "echo_btn_refresh";

// LVARs on PC
const string ECHO_LVAR_SEL_ID      = "ECHO_SEL_ID";
const string ECHO_LVAR_IS_OWN      = "ECHO_SEL_OWN";

// Layout
const float  ECHO_W                = 680.0;
const float  ECHO_H                = 520.0;

// Config
const int    ECHO_DECAY_HOURS      = 48;   // traces older than this are pruned
const int    ECHO_MAX_LIST         = 30;   // max traces shown
const int    ECHO_ERASE_GOLD_COST  = 50;   // gold cost to erase own trace

// Item tag of the detector crystal (place in HAK)
const string ECHO_CRYSTAL_TAG      = "echo_crystal";

// ----------------------------------------------------------------
// Spell school helpers
// ----------------------------------------------------------------

// Maps NWN spell school constant to a short display label (Polish)
string EchoSchoolLabel(int nSchool)
{
    switch(nSchool)
    {
        case SPELL_SCHOOL_ABJURATION:    return "Abjuracja";
        case SPELL_SCHOOL_CONJURATION:   return "Przywołanie";
        case SPELL_SCHOOL_DIVINATION:    return "Wróżbiarstwo";
        case SPELL_SCHOOL_ENCHANTMENT:   return "Zaklęcia";
        case SPELL_SCHOOL_EVOCATION:     return "Ewokacja";
        case SPELL_SCHOOL_ILLUSION:      return "Iluzja";
        case SPELL_SCHOOL_NECROMANCY:    return "Nekromancja";
        case SPELL_SCHOOL_TRANSMUTATION: return "Transmutacja";
        case SPELL_SCHOOL_GENERAL:       return "Ogólna";
        default:                         return "Nieznana";
    }
}

string EchoSchoolIcon(int nSchool)
{
    switch(nSchool)
    {
        case SPELL_SCHOOL_ABJURATION:    return "ir_abjura";
        case SPELL_SCHOOL_CONJURATION:   return "ir_conjur";
        case SPELL_SCHOOL_DIVINATION:    return "ir_divin";
        case SPELL_SCHOOL_ENCHANTMENT:   return "ir_encha";
        case SPELL_SCHOOL_EVOCATION:     return "ir_evoca";
        case SPELL_SCHOOL_ILLUSION:      return "ir_illus";
        case SPELL_SCHOOL_NECROMANCY:    return "ir_necro";
        case SPELL_SCHOOL_TRANSMUTATION: return "ir_trans";
        default:                         return "ir_gensp";
    }
}

// Human-readable age string
string EchoAgeLabel(int nUnixAge)
{
    int nNow     = FloatToInt(IntToFloat(GetTimeSecond()) + 0.0);
    // We use SQL-side age from stored ts; nUnixAge is seconds since epoch
    // Caller passes seconds_old (delta), not epoch
    int nSec = nUnixAge;
    if(nSec < 60)
        return IntToString(nSec) + " sek.";
    if(nSec < 3600)
        return IntToString(nSec / 60) + " min.";
    if(nSec < 86400)
        return IntToString(nSec / 3600) + " godz.";
    return IntToString(nSec / 86400) + " dni";
}

// Power rank 1-5 from caster level stored in trace
string EchoPowerLabel(int nCasterLevel)
{
    if(nCasterLevel <= 3)  return "Nikłe";
    if(nCasterLevel <= 7)  return "Słabe";
    if(nCasterLevel <= 12) return "Wyraźne";
    if(nCasterLevel <= 17) return "Silne";
    return "Potężne";
}

// Color tint by school
json EchoSchoolColor(int nSchool)
{
    switch(nSchool)
    {
        case SPELL_SCHOOL_EVOCATION:     return NuiColor(255, 120,  60);  // fiery orange
        case SPELL_SCHOOL_NECROMANCY:    return NuiColor( 80, 220,  80);  // sickly green
        case SPELL_SCHOOL_CONJURATION:   return NuiColor(100, 180, 255);  // cold blue
        case SPELL_SCHOOL_ILLUSION:      return NuiColor(200, 100, 255);  // purple
        case SPELL_SCHOOL_ENCHANTMENT:   return NuiColor(255, 200,  60);  // gold
        case SPELL_SCHOOL_TRANSMUTATION: return NuiColor(150, 255, 200);  // teal
        case SPELL_SCHOOL_ABJURATION:    return NuiColor(200, 200, 255);  // silver
        case SPELL_SCHOOL_DIVINATION:    return NuiColor(255, 160, 200);  // pink
        default:                         return NuiColor(200, 200, 200);
    }
}

// Masked caster description: we reveal race but not name unless caster_uuid == viewer
string EchoCasterMask(string sCasterUuid, string sCasterMask, object oViewer)
{
    if(GetObjectUUID(oViewer) == sCasterUuid)
        return "Ty sam";
    // sCasterMask is like "Człowiek / Mag"
    return sCasterMask;
}

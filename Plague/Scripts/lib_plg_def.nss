// lib_plg_def.nss - Plague v2 constants, static data, helper functions
//
// Domain layer - single source of truth for:
//   - 4 biological diseases (Black Plague, Blood Rot, Swamp Fever, Necrotic Wound)
//   - Disease phases (Incubation, Mild, Severe, Critical)
//   - DCs for rolls (contract, progression, apteczka)
//   - Remedy ranking system (3 ranks per disease)
//   - Contagion properties (range, DC, tick interval)
//   - Immunity stub (FALSE in v1, extension point)

#include "sql_plg"

// ============================================================
// Disease IDs
// ============================================================

const int PLG_DIS_NONE         = -1;
const int PLG_DIS_BLACK_PLAGUE = 0;
const int PLG_DIS_BLOOD_ROT    = 1;
const int PLG_DIS_SWAMP_FEVER  = 2;
const int PLG_DIS_NECROTIC     = 3;
const int PLG_DIS_COUNT        = 4;
// Future (phase 2): PLG_DIS_NECROPLAGUE = 4 (magical, conversion in critical)

// ============================================================
// Phase IDs
// ============================================================

const int PLG_PHASE_NONE       = 0;
const int PLG_PHASE_INCUBATION = 1;
const int PLG_PHASE_MILD       = 2;
const int PLG_PHASE_SEVERE     = 3;
const int PLG_PHASE_CRITICAL   = 4;

// ============================================================
// Save throw results
// ============================================================

const int PLG_SAVE_FAIL         = 0; // d20 + Fort < DC
const int PLG_SAVE_SUCCESS      = 1; // d20 + Fort >= DC, no nat 20
const int PLG_SAVE_CRIT_SUCCESS = 2; // d20 = 20 (cure on mild/incubation)
const int PLG_SAVE_CRIT_FAIL    = 3; // d20 = 1

// ============================================================
// Local variables on PC
// ============================================================

const string PLG_LVAR_HAS         = "PLG_HAS_";          // + diseaseId -> int (1 if has)
const string PLG_LVAR_TICK        = "PLG_TICK_";         // + diseaseId -> int (heartbeat counter for DoT)
const string PLG_LVAR_CONTAG_TICK = "PLG_CONTAG_TICK_";  // + diseaseId -> int (heartbeat counter for contagion)
const string PLG_LVAR_DIAGNOSED   = "PLG_DIAGNOSED_";    // + diseaseId -> int (1 if known)
const string PLG_LVAR_TOKEN       = "PLG_NUI_TOKEN";     // main NUI window token

// ============================================================
// Effect tags
// ============================================================

// One tag per disease, applied to the linked stat-decrease effect.
// Stat decrease icons in the buff bar are visible to the player by default,
// so a separate aura VFX is not needed. Diagnostic lens reads this tag.
const string PLG_ICON_TAG = "PLG_ICON_"; // + diseaseId

// ============================================================
// Area variables (toolset)
// ============================================================

// Builder sets this LVAR = 1 in area variables (Properties -> Variables)
// for inns, temples, player homes. Freezes disease offline.
const string PLG_LVAR_AREA_FREEZE = "PLG_AREA_FREEZE_DISEASE";

// ============================================================
// Disease names + flavor + symptoms
// ============================================================

string PlgDiseaseName(int nId)
{
    switch(nId)
    {
        case PLG_DIS_BLACK_PLAGUE: return "Black Plague";
        case PLG_DIS_BLOOD_ROT:    return "Blood Rot";
        case PLG_DIS_SWAMP_FEVER:  return "Swamp Fever";
        case PLG_DIS_NECROTIC:     return "Necrotic Wound";
    }
    return "None";
}

string PlgPhaseName(int nPhase)
{
    switch(nPhase)
    {
        case PLG_PHASE_INCUBATION: return "Incubation";
        case PLG_PHASE_MILD:       return "Mild Symptoms";
        case PLG_PHASE_SEVERE:     return "Sickness";
        case PLG_PHASE_CRITICAL:   return "Critical";
    }
    return "-";
}

string PlgPhaseFlavor(int nDiseaseId, int nPhase)
{
    if(nDiseaseId == PLG_DIS_BLACK_PLAGUE)
    {
        switch(nPhase)
        {
            case PLG_PHASE_INCUBATION: return "You feel mild muscle tremors and persistent fatigue. Spots under your arms itch - you don't think much of them.";
            case PLG_PHASE_MILD:       return "The fever has not let up for hours. Lymph nodes swell painfully under the skin. Blood in your saliva stains your kerchief pink.";
            case PLG_PHASE_SEVERE:     return "Black buboes rupture, oozing foul matter. Every breath is agony. Nearby creatures instinctively step back.";
            case PLG_PHASE_CRITICAL:   return "Darkness pulses behind your eyes. Skin blackens along your veins. Without immediate treatment, death is certain.";
        }
    }
    else if(nDiseaseId == PLG_DIS_BLOOD_ROT)
    {
        switch(nPhase)
        {
            case PLG_PHASE_INCUBATION: return "Old scars have started to burn for no reason. The blood under your nails is too dark.";
            case PLG_PHASE_MILD:       return "Veins on your forearms shimmer purple. Wounds refuse to heal - every scratch bleeds too long.";
            case PLG_PHASE_SEVERE:     return "Skin splits along your veins, as if your body wanted to open from within. Every movement leaves brown stains on your clothes.";
            case PLG_PHASE_CRITICAL:   return "Blood seeps from your eyes and ears. Your heart beats irregularly. Every moment without a remedy is another measure of life lost.";
        }
    }
    else if(nDiseaseId == PLG_DIS_SWAMP_FEVER)
    {
        switch(nPhase)
        {
            case PLG_PHASE_INCUBATION: return "A faint smell of mud lingers in your nostrils, though you are far from any wetlands. Your fingers tremble in the morning.";
            case PLG_PHASE_MILD:       return "The swamp fever does its work - reality blurs at the edges. You see shadows where there are none.";
            case PLG_PHASE_SEVERE:     return "Hallucinations grow stronger. Your sure-footedness fades; your legs carry you unsteadily, like a drunkard's.";
            case PLG_PHASE_CRITICAL:   return "Tremors lock your fingers. The world spins around you. Only a cold remedy can restore clarity of mind.";
        }
    }
    else if(nDiseaseId == PLG_DIS_NECROTIC)
    {
        switch(nPhase)
        {
            case PLG_PHASE_INCUBATION: return "The wound where it all began has stopped hurting. The flesh around it is pale - too pale.";
            case PLG_PHASE_MILD:       return "Necrotic tissue creeps along your arm. The skin has stiffened and hardened like a corpse's.";
            case PLG_PHASE_SEVERE:     return "The disease reaches deeper - you feel strength leaving your muscles, as though something were sucking you dry from within.";
            case PLG_PHASE_CRITICAL:   return "Half your body is cold as stone. The necromantic poison feeds on your vitality. Holy water is your only hope.";
        }
    }
    return "";
}

// Generic flavor for undiagnosed disease (player doesn't know which one).
string PlgPhaseFlavorMasked(int nPhase)
{
    switch(nPhase)
    {
        case PLG_PHASE_INCUBATION: return ""; // invisible - player does not know they are sick
        case PLG_PHASE_MILD:       return "You feel weak. Something is wrong with you, but you don't know exactly what.";
        case PLG_PHASE_SEVERE:     return "Your body shows clear symptoms of disease - but you don't know which. See a healer.";
        case PLG_PHASE_CRITICAL:   return "You are dying. Without identifying the disease, you won't find the right cure.";
    }
    return "";
}

string PlgPhaseSymptoms(int nDiseaseId, int nPhase)
{
    if(nPhase <= PLG_PHASE_INCUBATION) return "No visible symptoms.";

    if(nDiseaseId == PLG_DIS_BLACK_PLAGUE)
    {
        switch(nPhase)
        {
            case PLG_PHASE_MILD:     return "-2 Constitution";
            case PLG_PHASE_SEVERE:   return "-4 Constitution, -2 Strength";
            case PLG_PHASE_CRITICAL: return "-6 Constitution, -4 Strength";
        }
    }
    else if(nDiseaseId == PLG_DIS_BLOOD_ROT)
    {
        switch(nPhase)
        {
            case PLG_PHASE_MILD:     return "-1 AC, -1 to Saving Throws";
            case PLG_PHASE_SEVERE:   return "-2 AC, -2 to Saving Throws";
            case PLG_PHASE_CRITICAL: return "-3 AC, -3 to Saving Throws, bleeding every 30s";
        }
    }
    else if(nDiseaseId == PLG_DIS_SWAMP_FEVER)
    {
        switch(nPhase)
        {
            case PLG_PHASE_MILD:     return "-2 Dexterity";
            case PLG_PHASE_SEVERE:   return "-4 Dexterity, -2 Wisdom";
            case PLG_PHASE_CRITICAL: return "-6 Dexterity, -4 Wisdom";
        }
    }
    else if(nDiseaseId == PLG_DIS_NECROTIC)
    {
        switch(nPhase)
        {
            case PLG_PHASE_MILD:     return "-1 Strength";
            case PLG_PHASE_SEVERE:   return "-3 Strength, -2 Constitution";
            case PLG_PHASE_CRITICAL: return "-5 Strength, -4 Constitution, necrotic damage every 30s";
        }
    }
    return "";
}

// ============================================================
// Debug mode (accelerated intervals for testing)
// ============================================================

const string PLG_LVAR_DEBUG_MODE = "PLG_DEBUG_MODE"; // GetModule() LVAR

int PlgIsDebugMode()
{
    return GetLocalInt(GetModule(), PLG_LVAR_DEBUG_MODE);
}

void PlgSetDebugMode(int bEnabled)
{
    SetLocalInt(GetModule(), PLG_LVAR_DEBUG_MODE, bEnabled);
}

// In debug mode all phases use this short interval.
const int PLG_DEBUG_PHASE_SEC = 30; // 30 seconds per phase

// ============================================================
// Phase intervals - seconds until next phase boundary
// Critical does not advance (terminal in v1).
// In debug mode: PLG_DEBUG_PHASE_SEC for all phases.
// ============================================================

int PlgPhaseInterval(int nDiseaseId, int nPhase)
{
    // Debug mode - short intervals for testing
    if(PlgIsDebugMode()) return PLG_DEBUG_PHASE_SEC;

    if(nDiseaseId == PLG_DIS_BLACK_PLAGUE)
    {
        switch(nPhase)
        {
            case PLG_PHASE_INCUBATION: return 3600;  // 1h
            case PLG_PHASE_MILD:       return 7200;  // 2h
            case PLG_PHASE_SEVERE:     return 14400; // 4h
        }
    }
    else if(nDiseaseId == PLG_DIS_BLOOD_ROT)
    {
        switch(nPhase)
        {
            case PLG_PHASE_INCUBATION: return 1800;  // 30min
            case PLG_PHASE_MILD:       return 3600;  // 1h
            case PLG_PHASE_SEVERE:     return 7200;  // 2h
        }
    }
    else if(nDiseaseId == PLG_DIS_SWAMP_FEVER)
    {
        // Demo/test disease - fastest progression
        switch(nPhase)
        {
            case PLG_PHASE_INCUBATION: return 900;   // 15min
            case PLG_PHASE_MILD:       return 1800;  // 30min
            case PLG_PHASE_SEVERE:     return 3600;  // 1h
        }
    }
    else if(nDiseaseId == PLG_DIS_NECROTIC)
    {
        switch(nPhase)
        {
            case PLG_PHASE_INCUBATION: return 1800;  // 30min
            case PLG_PHASE_MILD:       return 3600;  // 1h
            case PLG_PHASE_SEVERE:     return 10800; // 3h
        }
    }
    return 3600; // default fallback
}

// ============================================================
// DC functions - one place to balance difficulty
// ============================================================

// Base DC per disease (used for contract and as progression base).
int PlgGetBaseDC(int nDiseaseId)
{
    switch(nDiseaseId)
    {
        case PLG_DIS_BLACK_PLAGUE: return 13;
        case PLG_DIS_BLOOD_ROT:    return 12;
        case PLG_DIS_SWAMP_FEVER:  return 11;
        case PLG_DIS_NECROTIC:     return 14;
    }
    return 12;
}

// Fort save DC when contracting the disease.
int PlgGetContractDC(int nDiseaseId)
{
    switch(nDiseaseId)
    {
        case PLG_DIS_BLACK_PLAGUE: return 15;
        case PLG_DIS_BLOOD_ROT:    return 14;
        case PLG_DIS_SWAMP_FEVER:  return 12;
        case PLG_DIS_NECROTIC:     return 16;
    }
    return 14;
}

// Body fight DC at phase boundary (scales with phase).
int PlgGetProgressionDC(int nDiseaseId, int nPhase)
{
    int nBase = PlgGetBaseDC(nDiseaseId);
    switch(nPhase)
    {
        case PLG_PHASE_INCUBATION: return nBase;
        case PLG_PHASE_MILD:       return nBase + 2;
        case PLG_PHASE_SEVERE:     return nBase + 4;
        case PLG_PHASE_CRITICAL:   return nBase + 6;
    }
    return nBase;
}

// Heal skill DC for first-aid kit per phase per disease.
// Returns -1 if first-aid does NOT work on this phase (critical or no disease).
// Higher rank curing - on success, retreats one phase
// (incubation/mild -> cured, severe -> mild).
int PlgGetFirstAidDC(int nDiseaseId, int nPhase)
{
    int nBaseDC;
    switch(nPhase)
    {
        case PLG_PHASE_INCUBATION: nBaseDC = 10; break; // very easy (early intervention)
        case PLG_PHASE_MILD:       nBaseDC = 15; break; // easy
        case PLG_PHASE_SEVERE:     nBaseDC = 22; break; // hard but possible
        case PLG_PHASE_CRITICAL:   return -1;           // impossible - requires RP/spell/rank3 remedy
        default:                   return -1;           // PLG_PHASE_NONE - no disease
    }

    // Per-disease modifier
    switch(nDiseaseId)
    {
        case PLG_DIS_BLACK_PLAGUE: nBaseDC += 2; break; // 12/17/24
        case PLG_DIS_NECROTIC:     nBaseDC += 1; break; // 11/16/23
    }
    return nBaseDC;
}

// ============================================================
// Immunity - STUB FUNCTION (extension point)
// V1: always FALSE - all players equally exposed
// V2/v3: extension for feat-based, item-based, race-based
// ============================================================

int PlgIsImmune(object oPC, int nDiseaseId)
{
    // Hook for future extension:
    // - Magic items/spells with disease resistance
    // - Plague Doctor outfit
    // - Late game capstone (lvl 15+) immunity
    return FALSE;
}

// ============================================================
// Remedy ranking system
// ============================================================

const int PLG_REMEDY_RANK_NONE     = 0;
const int PLG_REMEDY_RANK_MILD     = 1; // cures mild
const int PLG_REMEDY_RANK_SEVERE   = 2; // cures mild + severe
const int PLG_REMEDY_RANK_CRITICAL = 3; // cures mild + severe + critical (universal)

// Tag prefix for remedy items: plg_rem_<disease>_<rank>
// e.g. plg_rem_plague_2 = severe-tier remedy for Black Plague
const string PLG_REMEDY_TAG_PRE = "plg_rem_";

string PlgGetRemedyTag(int nDiseaseId, int nRank)
{
    string sBase = PLG_REMEDY_TAG_PRE;
    switch(nDiseaseId)
    {
        case PLG_DIS_BLACK_PLAGUE: sBase += "plague_"; break;
        case PLG_DIS_BLOOD_ROT:    sBase += "blood_";  break;
        case PLG_DIS_SWAMP_FEVER:  sBase += "swamp_";  break;
        case PLG_DIS_NECROTIC:     sBase += "necro_";  break;
        default: return "";
    }
    return sBase + IntToString(nRank);
}

string PlgGetRemedyName(int nDiseaseId, int nRank)
{
    if(nDiseaseId == PLG_DIS_BLACK_PLAGUE)
    {
        switch(nRank)
        {
            case 1: return "Black Mallow Tincture";
            case 2: return "White Bistort Elixir";
            case 3: return "Archpriest's Holy Brew";
        }
    }
    else if(nDiseaseId == PLG_DIS_BLOOD_ROT)
    {
        switch(nRank)
        {
            case 1: return "Herbal Bandage";
            case 2: return "Bloodhunter's Elixir";
            case 3: return "Blood of a Saint";
        }
    }
    else if(nDiseaseId == PLG_DIS_SWAMP_FEVER)
    {
        switch(nRank)
        {
            case 1: return "Marsh Poplar Root";
            case 2: return "Bog Moss Decoction";
            case 3: return "Tonic of Clear Mind";
        }
    }
    else if(nDiseaseId == PLG_DIS_NECROTIC)
    {
        switch(nRank)
        {
            case 1: return "Graveyard Moss Salve";
            case 2: return "Holy Water";
            case 3: return "Divine Regeneration Balm";
        }
    }
    return "Unknown remedy";
}

// Checks if remedy works for given phase.
// Higher rank also cures lower phases (rank 1 cures incubation+mild,
// rank 2 cures incubation+mild+severe, rank 3 universal).
int PlgCanRemedyHeal(int nRemedyRank, int nPhase)
{
    int nRequiredRank;
    switch(nPhase)
    {
        case PLG_PHASE_INCUBATION: nRequiredRank = 1; break;
        case PLG_PHASE_MILD:       nRequiredRank = 1; break;
        case PLG_PHASE_SEVERE:     nRequiredRank = 2; break;
        case PLG_PHASE_CRITICAL:   nRequiredRank = 3; break;
        default: return FALSE; // PLG_PHASE_NONE - no disease, nothing to cure
    }
    return nRemedyRank >= nRequiredRank;
}

// Internal helper - parses item tag, returns JSON {disease_id, rank} or JsonNull.
// Tag format: plg_rem_<disease>_<rank>
json PlgParseRemedyTag(string sTag)
{
    int nPreLen = GetStringLength(PLG_REMEDY_TAG_PRE); // 8
    if(GetStringLeft(sTag, nPreLen) != PLG_REMEDY_TAG_PRE) return JsonNull();

    string sRest = GetSubString(sTag, nPreLen, GetStringLength(sTag) - nPreLen);
    // sRest = "plague_2", "blood_1", "swamp_3", "necro_2"

    int nDiseaseId = -1;
    string sDiseaseStr = "";
    if(GetStringLeft(sRest, 7) == "plague_") {
        nDiseaseId = PLG_DIS_BLACK_PLAGUE;
        sDiseaseStr = "plague_";
    } else if(GetStringLeft(sRest, 6) == "blood_") {
        nDiseaseId = PLG_DIS_BLOOD_ROT;
        sDiseaseStr = "blood_";
    } else if(GetStringLeft(sRest, 6) == "swamp_") {
        nDiseaseId = PLG_DIS_SWAMP_FEVER;
        sDiseaseStr = "swamp_";
    } else if(GetStringLeft(sRest, 6) == "necro_") {
        nDiseaseId = PLG_DIS_NECROTIC;
        sDiseaseStr = "necro_";
    } else return JsonNull();

    string sRankStr = GetSubString(sRest, GetStringLength(sDiseaseStr),
                                   GetStringLength(sRest) - GetStringLength(sDiseaseStr));
    int nRank = StringToInt(sRankStr);
    if(nRank < 1 || nRank > 3) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "disease_id", JsonInt(nDiseaseId));
    j = JsonObjectSet(j, "rank",       JsonInt(nRank));
    return j;
}

// Convenience: is this item a remedy?
int PlgIsRemedyTag(string sTag)
{
    return JsonGetType(PlgParseRemedyTag(sTag)) != JSON_TYPE_NULL;
}

// Convenience: get disease_id from tag (-1 if not a remedy).
int PlgGetRemedyDiseaseId(string sTag)
{
    json j = PlgParseRemedyTag(sTag);
    if(JsonGetType(j) == JSON_TYPE_NULL) return -1;
    return JsonGetInt(JsonObjectGet(j, "disease_id"));
}

// Convenience: get rank from tag (-1 if not a remedy).
int PlgGetRemedyRank(string sTag)
{
    json j = PlgParseRemedyTag(sTag);
    if(JsonGetType(j) == JSON_TYPE_NULL) return -1;
    return JsonGetInt(JsonObjectGet(j, "rank"));
}

// ============================================================
// Contagion properties (per disease)
// ============================================================

int PlgIsContagious(int nDiseaseId)
{
    switch(nDiseaseId)
    {
        case PLG_DIS_BLACK_PLAGUE: return TRUE;
        case PLG_DIS_BLOOD_ROT:    return TRUE;
        case PLG_DIS_SWAMP_FEVER:  return FALSE; // environmental
        case PLG_DIS_NECROTIC:     return FALSE; // single wound
    }
    return FALSE;
}

float PlgGetContagionRange(int nDiseaseId)
{
    switch(nDiseaseId)
    {
        case PLG_DIS_BLACK_PLAGUE: return 10.0; // airborne, wide range
        case PLG_DIS_BLOOD_ROT:    return 10.0;
    }
    return 0.0;
}

// Contagion DC - same as standard contract DC.
int PlgGetContagionDC(int nDiseaseId)
{
    return PlgGetContractDC(nDiseaseId);
}

// How often (in seconds) a carrier emits an infection check.
int PlgGetContagionTick(int nDiseaseId)
{
    switch(nDiseaseId)
    {
        case PLG_DIS_BLACK_PLAGUE: return 60; // every 60s
        case PLG_DIS_BLOOD_ROT:    return 90; // every 90s
    }
    return 0;
}

// ============================================================
// Color helpers (packed RGB int - lib_plg.nss wraps in NuiColor)
// ============================================================

// Returns packed RGB int (R << 16) | (G << 8) | B
int PlgDiseaseColorPacked(int nDiseaseId)
{
    switch(nDiseaseId)
    {
        case PLG_DIS_BLACK_PLAGUE: return (100 << 16) | (60  << 8) | 120; // dark purple
        case PLG_DIS_BLOOD_ROT:    return (200 << 16) | (40  << 8) | 40;  // crimson
        case PLG_DIS_SWAMP_FEVER:  return (80  << 16) | (160 << 8) | 60;  // sickly green
        case PLG_DIS_NECROTIC:     return (60  << 16) | (80  << 8) | 120; // necrotic blue-grey
    }
    return (120 << 16) | (120 << 8) | 120; // grey fallback
}

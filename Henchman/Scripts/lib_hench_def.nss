// lib_hench_def.nss
// Constants, helpers and HenchScanRoster for the henchman system
#include "lib_hench_cmd"

// ============================================================
// UI / window constants
// ============================================================
const string HENCH_WINDOW        = "HENCH_WIN";
const string HENCH_EVT_SCRIPT    = "lib_hench_ev";

const float  HENCH_WIN_W         = 1000.0;
const float  HENCH_WIN_H         = 750.0;
const float  HENCH_SWAP_H        = 680.0;  // WIN_H - padT(30) - closeRow(24) - padB(16)

// Binds
const string HENCH_BIND_PORT     = "h_port";       // portrait (NuiList)
const string HENCH_BIND_NAME     = "h_name";
const string HENCH_BIND_CLASS    = "h_class";
const string HENCH_BIND_ENC      = "h_enc";

const string HENCH_BIND_DET_PORT = "h_det_port";   // detail panel
const string HENCH_BIND_DET_NAME = "h_det_name";
const string HENCH_BIND_DET_CLS  = "h_det_cls";
const string HENCH_BIND_DET_STR  = "h_det_str";
const string HENCH_BIND_DET_DEX  = "h_det_dex";
const string HENCH_BIND_DET_CON  = "h_det_con";
const string HENCH_BIND_DET_INT  = "h_det_int";
const string HENCH_BIND_DET_WIS  = "h_det_wis";
const string HENCH_BIND_DET_CHA  = "h_det_cha";
const string HENCH_BIND_DET_HP   = "h_det_hp";
const string HENCH_BIND_DET_AC   = "h_det_ac";
const string HENCH_BIND_DET_DESC = "h_det_desc";

const string HENCH_BIND_HIRE_EN  = "h_hire_en";    // Hire button enabled state
const string HENCH_BIND_DET_VIS  = "h_det_vis";    // detail panel visibility (hire layout)

// Swap layout group ID
const string HENCH_GROUP_MAIN    = "h_main_grp";

// UI element IDs
const string HENCH_BTN_CLOSE     = "h_btn_x";
const string HENCH_BTN_ROW       = "h_btn_row";
const string HENCH_BTN_HIRE      = "h_btn_hire";
const string HENCH_BTN_FIRE      = "h_btn_fire";
const string HENCH_BTN_RESURRECT = "h_btn_res";

// FireDead layout binds (simplified: portrait + name + "Deceased")
const string HENCH_BIND_DEAD_PORT  = "h_dead_port";
const string HENCH_BIND_DEAD_NAME  = "h_dead_name";
const string HENCH_BIND_RES_LABEL  = "h_res_lbl";   // "Resurrect (X gp)"
const string HENCH_BIND_RES_EN     = "h_res_en";    // bool: player has enough gold

// Resurrection cost multiplier: cost = level * HENCH_RESURRECT_COST_PER_LEVEL
const int    HENCH_RESURRECT_COST_PER_LEVEL = 100;

// LVARs on PC
const string HENCH_LVAR_TOKEN    = "HENCH_TOKEN";
const string HENCH_LVAR_SEL_IDX  = "HENCH_SEL_IDX";   // selected roster index
const string HENCH_LVAR_SUPPRESS = "HENCH_SUPPRESS_CLEANUP";  // suppress NWNX_REMOVE_ASSOCIATE handler

// LVARs on henchman
const string HENCH_LVAR_HB_TIMER = "HB_TIMER";        // heartbeat tick counter (save every 10*6s)

// Module JSON - roster cache
const string HENCH_MOD_ROSTER    = "HENCH_ROSTER";

// Object tags in module (must be placed by builder)
const string HENCH_TAG_TRASHBIN    = "HENCH_TRASHBIN";       // waypoint for blueprint scanning
const string HENCH_TAG_NEUTRAL_NPC = "hench_neutral_np";     // neutral faction NPC (vanilla bug fix)

// Scripts
const string HENCH_SCRIPT_SUBSCRIBE = "hench_nwnx_sub";      // called from sys_on_load

// Base blueprint tags (6 OC henchmen)
const string HENCH_TAG_BOD = "nw_hen_bod";
const string HENCH_TAG_DAE = "nw_hen_dae";
const string HENCH_TAG_GRI = "nw_hen_gri";
const string HENCH_TAG_LIN = "nw_hen_lin";
const string HENCH_TAG_SHA = "nw_hen_sha";
const string HENCH_TAG_GAL = "nw_hen_gal";

// ============================================================
// Helpers
// ============================================================

// Builds class string: "Lvl 6: Fighter (4) / Rogue (2)"
string HenchClassString(object oHench)
{
    int nLevel = GetHitDice(oHench);
    string sResult = "Lvl " + IntToString(nLevel) + ": ";

    int i;
    int bFirst = TRUE;
    for(i = 0; i < 3; i++)
    {
        int nClass = GetClassByPosition(i + 1, oHench);
        if(nClass == CLASS_TYPE_INVALID) break;
        int nClassLevel = GetLevelByClass(nClass, oHench);
        if(nClassLevel <= 0) break;

        if(!bFirst) sResult += " / ";
        bFirst = FALSE;

        string sClassName = GetStringByStrRef(StringToInt(Get2DAString("classes", "Name", nClass)));
        sResult += sClassName + " (" + IntToString(nClassLevel) + ")";
    }
    return sResult;
}

int HenchGetIsHired(object oHench)
{
    return GetIsObjectValid(GetMaster(oHench));
}

// ============================================================
// HenchScanRoster - call from sys_on_load
// Scans blueprints _01.._11 for all 6 henchmen,
// collects data into JsonArray on the module.
// ============================================================
string HenchGetBaseTag(int nIdx)
{
    switch(nIdx)
    {
        case 0: return HENCH_TAG_BOD;
        case 1: return HENCH_TAG_DAE;
        case 2: return HENCH_TAG_GRI;
        case 3: return HENCH_TAG_LIN;
        case 4: return HENCH_TAG_SHA;
        case 5: return HENCH_TAG_GAL;
    }
    return "";
}

// Builds JsonObject describing a henchman - used by HenchScanRoster
// (and other places that need a snapshot of henchman data).
json HenchBuildRosterEntry(object oHench)
{
    json jEntry = JsonObject();
    jEntry = JsonObjectSet(jEntry, "resref",    JsonString(GetResRef(oHench)));
    jEntry = JsonObjectSet(jEntry, "name",      JsonString(GetName(oHench)));
    jEntry = JsonObjectSet(jEntry, "portrait",  JsonString(GetPortraitResRef(oHench) + "L"));
    jEntry = JsonObjectSet(jEntry, "level",     JsonInt(GetHitDice(oHench)));
    jEntry = JsonObjectSet(jEntry, "cost",      JsonInt(GetHitDice(oHench)));
    jEntry = JsonObjectSet(jEntry, "class_str", JsonString(HenchClassString(oHench)));
    jEntry = JsonObjectSet(jEntry, "str",       JsonInt(GetAbilityScore(oHench, ABILITY_STRENGTH,     TRUE)));
    jEntry = JsonObjectSet(jEntry, "dex",       JsonInt(GetAbilityScore(oHench, ABILITY_DEXTERITY,    TRUE)));
    jEntry = JsonObjectSet(jEntry, "con",       JsonInt(GetAbilityScore(oHench, ABILITY_CONSTITUTION, TRUE)));
    jEntry = JsonObjectSet(jEntry, "int",       JsonInt(GetAbilityScore(oHench, ABILITY_INTELLIGENCE, TRUE)));
    jEntry = JsonObjectSet(jEntry, "wis",       JsonInt(GetAbilityScore(oHench, ABILITY_WISDOM,       TRUE)));
    jEntry = JsonObjectSet(jEntry, "cha",       JsonInt(GetAbilityScore(oHench, ABILITY_CHARISMA,     TRUE)));
    jEntry = JsonObjectSet(jEntry, "hp",        JsonInt(GetMaxHitPoints(oHench)));
    jEntry = JsonObjectSet(jEntry, "ac",        JsonInt(GetAC(oHench)));
    jEntry = JsonObjectSet(jEntry, "desc",      JsonString(GetDescription(oHench)));
    return jEntry;
}

void HenchScanRoster()
{
    object oTrash = GetWaypointByTag(HENCH_TAG_TRASHBIN);
    if(!GetIsObjectValid(oTrash))
    {
        SendMessageToAllDMs("HENCH ERROR: missing waypoint " + HENCH_TAG_TRASHBIN + " - roster empty.");
        return;
    }
    location lTrash = GetLocation(oTrash);
    json jRoster = JsonArray();

    int t;
    for(t = 0; t < 6; t++)
    {
        int lvl;
        for(lvl = 1; lvl <= 11; lvl++)
        {
            string sLvl    = (lvl < 10 ? "0" : "") + IntToString(lvl);
            string sResRef = HenchGetBaseTag(t) + "_" + sLvl;

            object oHench = CreateObject(OBJECT_TYPE_CREATURE, sResRef, lTrash, FALSE);
            if(!GetIsObjectValid(oHench)) continue;

            jRoster = JsonArrayInsert(jRoster, HenchBuildRosterEntry(oHench));
            DestroyObject(oHench);
        }
    }

    SetLocalJson(GetModule(), HENCH_MOD_ROSTER, jRoster);
}

// Cleanup of henchman being removed from party (HenchFire + NWNX_REMOVE_ASSOCIATE handler).
// Requires an object tagged HENCH_TAG_NEUTRAL_NPC in the module - otherwise DM gets a warning.
// NOTE: caller must close the AI command window (DestroyHenchCmdWindow) BEFORE RemoveHenchman -
// once the engine drops the association GetMaster(oHench) returns INVALID.
void HenchCleanupCreature(object oHench)
{
    object oNeutral = GetObjectByTag(HENCH_TAG_NEUTRAL_NPC);
    if(GetIsObjectValid(oNeutral))
        ChangeFaction(oHench, oNeutral);
    else
        SendMessageToAllDMs("HENCH WARN: missing " + HENCH_TAG_NEUTRAL_NPC
            + " - vanilla faction bug not fixed, henchman may stay in the party UI.");

    AssignCommand(oHench, ClearAllActions());
    AssignCommand(oHench, SetIsDestroyable(TRUE, TRUE, TRUE));
    DelayCommand(0.5, DestroyObject(oHench));
}

// ============================================================
// Save / Load - full creature serialization via ObjectToJson
// ============================================================

// Setup for henchman after CreateObject + AddHenchman:
// forces events from set_xp2_henchmen.ini (BioWare official HotU set)
// + our custom hench_heartbeat (HP save) and hench_on_death (is_dead flag).
// Works for OC and custom blueprints - no blueprint editing required.
// Call from hire / HenchLoad / HenchResurrect.
void HenchSetupCreatedHench(object oPC, object oHench)
{
    // BioWare set_xp2_henchmen.ini (mostly x0_ch_hen_* from SoU + two x2_hen_* from HotU)
    SetEventScript(oHench, EVENT_SCRIPT_CREATURE_ON_BLOCKED_BY_DOOR,  "x0_ch_hen_block");
    SetEventScript(oHench, EVENT_SCRIPT_CREATURE_ON_END_COMBATROUND,  "x0_ch_hen_combat");
    SetEventScript(oHench, EVENT_SCRIPT_CREATURE_ON_DIALOGUE,         "x0_ch_hen_conv");
    SetEventScript(oHench, EVENT_SCRIPT_CREATURE_ON_DAMAGED,          "x0_ch_hen_damage");
    SetEventScript(oHench, EVENT_SCRIPT_CREATURE_ON_DISTURBED,        "x0_ch_hen_distrb");
    SetEventScript(oHench, EVENT_SCRIPT_CREATURE_ON_NOTICE,           "x0_ch_hen_percep");
    SetEventScript(oHench, EVENT_SCRIPT_CREATURE_ON_MELEE_ATTACKED,   "x0_ch_hen_attack");
    SetEventScript(oHench, EVENT_SCRIPT_CREATURE_ON_RESTED,           "x0_ch_hen_rest");
    SetEventScript(oHench, EVENT_SCRIPT_CREATURE_ON_USER_DEFINED_EVENT,"x0_ch_hen_usrdef");
    SetEventScript(oHench, EVENT_SCRIPT_CREATURE_ON_SPELLCASTAT,      "x2_hen_spell");

    // Our custom (override BioWare default)
    SetEventScript(oHench, EVENT_SCRIPT_CREATURE_ON_HEARTBEAT,        "hench_heartbeat");
    SetEventScript(oHench, EVENT_SCRIPT_CREATURE_ON_DEATH,            "hench_on_death");

    SetAssociateListenPatterns(oHench);
    AssignCommand(oHench, SetIsDestroyable(FALSE, TRUE, TRUE));

    // Open the AI control bar
    CreateHenchCmdWindow(oPC);
}

void HenchSave(object oPC)
{
    object oHench = GetHenchman(oPC);
    if(!GetIsObjectValid(oHench)) return;

    json jHench = ObjectToJson(oHench, TRUE);
    HenchSaveRecord(GetObjectUUID(oPC), GetResRef(oHench), JsonDump(jHench), 0);
}

void HenchLoad(object oPC)
{
    string sPcUuid = GetObjectUUID(oPC);
    json jRec = HenchLoadRecord(sPcUuid);
    if(JsonGetType(jRec) == JSON_TYPE_NULL) return;
    if(JsonGetInt(JsonObjectGet(jRec, "is_dead")) == 1) return;

    string sResRef = JsonGetString(JsonObjectGet(jRec, "resref"));
    string sJson   = JsonGetString(JsonObjectGet(jRec, "hench_json"));
    if(sJson == "") return;

    // Destroy any old object with this tag still on the map
    object oOld = GetObjectByTag(sResRef);
    if(GetIsObjectValid(oOld) && !HenchGetIsHired(oOld))
        DestroyObject(oOld);

    object oHench = JsonToObject(JsonParse(sJson), GetLocation(oPC), oPC, TRUE);
    if(!GetIsObjectValid(oHench)) return;

    // Defensive: AddHenchman may (rarely) eject an existing associate -> NWNX cleanup
    // would erase the SQL record we are loading from.
    SetLocalInt(oPC, HENCH_LVAR_SUPPRESS, 1);
    AddHenchman(oPC, oHench);
    HenchSetupCreatedHench(oPC, oHench);
}

void HenchFire(object oPC)
{
    object oHench = GetHenchman(oPC);
    if(!GetIsObjectValid(oHench)) return;

    DestroyHenchCmdWindow(oPC);
    HenchDeleteRecord(GetObjectUUID(oPC));
    SetLocalInt(oPC, HENCH_LVAR_SUPPRESS, 1);
    RemoveHenchman(oPC, oHench);
    HenchCleanupCreature(oHench);
}

// ============================================================
// Variant C - resurrection of a dead henchman
// ============================================================

// Finds a roster entry by resref. Returns JsonNull if not found.
json HenchGetRosterEntry(string sResRef)
{
    json jRoster = GetLocalJson(GetModule(), HENCH_MOD_ROSTER);
    if(JsonGetType(jRoster) != JSON_TYPE_ARRAY) return JsonNull();

    int i;
    int nCount = JsonGetLength(jRoster);
    for(i = 0; i < nCount; i++)
    {
        json jE = JsonArrayGet(jRoster, i);
        if(JsonGetString(JsonObjectGet(jE, "resref")) == sResRef)
            return jE;
    }
    return JsonNull();
}

// Resurrection cost in gp: level * HENCH_RESURRECT_COST_PER_LEVEL
int HenchGetResurrectCost(string sResRef)
{
    json jE = HenchGetRosterEntry(sResRef);
    if(JsonGetType(jE) == JSON_TYPE_NULL) return 0;
    return JsonGetInt(JsonObjectGet(jE, "level")) * HENCH_RESURRECT_COST_PER_LEVEL;
}

// Returns 1 if resurrection succeeded, 0 otherwise.
int HenchResurrect(object oPC)
{
    string sPcUuid = GetObjectUUID(oPC);
    json jRec = HenchLoadRecord(sPcUuid);
    if(JsonGetType(jRec) == JSON_TYPE_NULL) return 0;
    if(JsonGetInt(JsonObjectGet(jRec, "is_dead")) != 1) return 0;

    string sResRef = JsonGetString(JsonObjectGet(jRec, "resref"));
    int nCost = HenchGetResurrectCost(sResRef);

    if(GetGold(oPC) < nCost)
    {
        SendMessageToPC(oPC, "Not enough gold. Missing " + IntToString(nCost - GetGold(oPC)) + " gp.");
        return 0;
    }

    AssignCommand(oPC, TakeGoldFromCreature(nCost, oPC, TRUE));

    // Destroy any old object with this tag still on the map
    object oOld = GetObjectByTag(sResRef);
    if(GetIsObjectValid(oOld) && !HenchGetIsHired(oOld))
        DestroyObject(oOld);

    // Restore from saved JSON (preserves equipment + stats).
    // Fallback to CreateObject from blueprint if no hench_json available.
    string sJson = JsonGetString(JsonObjectGet(jRec, "hench_json"));
    object oHench;
    if(sJson != "")
        oHench = JsonToObject(JsonParse(sJson), GetLocation(oPC), oPC, TRUE);
    else
        oHench = CreateObject(OBJECT_TYPE_CREATURE, sResRef, GetLocation(oPC), FALSE);

    if(!GetIsObjectValid(oHench))
    {
        SendMessageToPC(oPC, "Failed to resurrect companion.");
        return 0;
    }

    // Resurrected henchman starts at full HP - heal up to max after retrieve
    int nMissing = GetMaxHitPoints(oHench) - GetCurrentHitPoints(oHench);
    if(nMissing > 0)
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(nMissing), oHench);

    // Defensive: AddHenchman may (rarely) eject an existing associate -> NWNX cleanup
    SetLocalInt(oPC, HENCH_LVAR_SUPPRESS, 1);
    AddHenchman(oPC, oHench);
    HenchSetupCreatedHench(oPC, oHench);

    HenchSetDeadFlag(sPcUuid, 0);
    HenchSave(oPC);  // persist the new state (alive, full HP)
    return 1;
}

// Dismissing a dead henchman - just removes the record (object already destroyed on death).
void HenchFireDead(object oPC)
{
    HenchDeleteRecord(GetObjectUUID(oPC));
}

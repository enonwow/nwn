// lib_tomb_def.nss — constants, bind IDs and forward declarations for Epitafium

#include "lib_nui"
#include "sql_tomb"

void TombCreateWriteWindow(object oPC);
void TombCreateReadWindow(object oPC, int nMemorialId);
void TombFinalizeMemorial(object oPC, int nToken);
void TombSpawnStone(int nId, json jMem);
void TombRespawnAll();

// ----------------------------------------------------------------
// Window identifiers
// ----------------------------------------------------------------

const string TOMB_WIN_WRITE   = "TOMB_WIN_WRITE";
const string TOMB_WIN_READ    = "TOMB_WIN_READ";
const string TOMB_EV_SCRIPT   = "lib_tomb_ev";

// ----------------------------------------------------------------
// Write-window bind IDs
// ----------------------------------------------------------------

const string TOMB_BIND_W_NAME    = "tomb_w_name";    // character name label
const string TOMB_BIND_W_CAUSE   = "tomb_w_cause";   // editable cause of death
const string TOMB_BIND_W_EPITAPH = "tomb_w_epitaph"; // epitaph text edit
const string TOMB_BIND_W_HINT    = "tomb_w_hint";    // remaining-chars hint

// ----------------------------------------------------------------
// Read-window bind IDs
// ----------------------------------------------------------------

const string TOMB_BIND_R_HEADER  = "tomb_r_header";  // "Tu spoczywa X"
const string TOMB_BIND_R_DATE    = "tomb_r_date";    // date of death
const string TOMB_BIND_R_CAUSE   = "tomb_r_cause";   // cause of death
const string TOMB_BIND_R_EPITAPH = "tomb_r_epitaph"; // epitaph body
const string TOMB_BIND_R_TRIBUTE = "tomb_r_tribute"; // tribute count label
const string TOMB_BIND_R_BTN_TRB = "tomb_r_trblbl";  // tribute button label
const string TOMB_BIND_R_BTN_ENA = "tomb_r_trbena";  // tribute button enabled

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string TOMB_BTN_ENGRAVE  = "tomb_btn_engrave"; // confirm epitaph
const string TOMB_BTN_SKIP     = "tomb_btn_skip";    // skip tombstone
const string TOMB_BTN_CLOSE    = "tomb_btn_close";   // close read window
const string TOMB_BTN_TRIBUTE  = "tomb_btn_tribute"; // pay tribute

// ----------------------------------------------------------------
// Local variables on PC
// ----------------------------------------------------------------

const string TOMB_LVAR_AREA    = "TOMB_AREA";    // area tag at death
const string TOMB_LVAR_POS_X   = "TOMB_POS_X";
const string TOMB_LVAR_POS_Y   = "TOMB_POS_Y";
const string TOMB_LVAR_POS_Z   = "TOMB_POS_Z";
const string TOMB_LVAR_CAUSE   = "TOMB_CAUSE";   // auto-detected cause
const string TOMB_LVAR_MEM_ID  = "TOMB_MEM_ID";  // id of the memorial last read

// ----------------------------------------------------------------
// Local variable on tombstone placeable
// ----------------------------------------------------------------

const string TOMB_LVAR_STONE_ID = "TOMB_MEM_ID"; // memorial id stored on the stone

// ----------------------------------------------------------------
// Layout
// ----------------------------------------------------------------

const float TOMB_WRITE_W    = 540.0;
const float TOMB_WRITE_H    = 400.0;
const float TOMB_READ_W     = 500.0;
const float TOMB_READ_H     = 360.0;
const int   TOMB_EPITAPH_MAX = 200;
const int   TOMB_CAUSE_MAX   = 80;

// ----------------------------------------------------------------
// Game constants
// ----------------------------------------------------------------

// Gold cost for paying tribute at a tombstone.
const int   TOMB_TRIBUTE_COST  = 50;

// Duration of the tribute buff in seconds (1 hour).
const int   TOMB_TRIBUTE_DUR   = 3600;

// Resref of the tombstone placeable (base NWN grave marker).
// Use "plc_grvmark1" or another stone marker from your hak.
const string TOMB_STONE_RESREF = "plc_grvmark1";

// OnUsed script placed on each dynamically spawned tombstone.
const string TOMB_STONE_SCRIPT = "tomb_use";

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------

// Builds the short stone description shown in the examine tooltip.
string TombBuildStoneDesc(json jMem)
{
    string sName    = JsonGetString(JsonObjectGet(jMem, "char_name"));
    string sCause   = JsonGetString(JsonObjectGet(jMem, "cause"));
    string sEpitaph = JsonGetString(JsonObjectGet(jMem, "epitaph"));
    int    nDiedAt  = JsonGetInt   (JsonObjectGet(jMem, "died_at"));
    int    nTribs   = JsonGetInt   (JsonObjectGet(jMem, "tribute_cnt"));

    string sDate = TombFormatDate(nDiedAt);

    string sDesc = "Tu spoczywa " + sName + ".\n"
                 + sCause + " (" + sDate + ").\n";
    if(sEpitaph != "")
        sDesc = sDesc + "\n\"" + sEpitaph + "\"\n";
    if(nTribs > 0)
        sDesc = sDesc + "\nHołd złożyli: " + IntToString(nTribs) + " pielgrzym"
                      + (nTribs == 1 ? "" : "ów") + ".";
    return sDesc;
}

// Cleans per-death local vars from the PC after the write window is done.
void TombClearDeathLvars(object oPC)
{
    DeleteLocalString(oPC, TOMB_LVAR_AREA);
    DeleteLocalFloat (oPC, TOMB_LVAR_POS_X);
    DeleteLocalFloat (oPC, TOMB_LVAR_POS_Y);
    DeleteLocalFloat (oPC, TOMB_LVAR_POS_Z);
    DeleteLocalString(oPC, TOMB_LVAR_CAUSE);
}

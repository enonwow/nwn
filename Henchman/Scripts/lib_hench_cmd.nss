// lib_hench_cmd.nss
// AI control bar for henchman - 6 horizontal buttons:
// Follow / Stand Ground / Defend Me / Attack Nearest / Summon / Save window position
//
// Window position persisted in SQL (henchman_ui table) per-PC.
// Active mode (Follow/Stand/Guard) stored in LVAR on henchman - persists via ObjectToJson.
#include "nw_inc_nui"
#include "sql_hench"

// ============================================================
// Window constants
// ============================================================
const string HCMD_WINDOW       = "HENCH_CMD_WIN";
const string HCMD_EVT_SCRIPT   = "lib_hench_cmd_ev";

const float  HCMD_BTN_W        = 50.0;
const float  HCMD_BTN_H        = 50.0;
const float  HCMD_PAD          = 6.0;
// 6 buttons + padding around each + room for title bar (~30px)
const float  HCMD_WIN_W        = HCMD_BTN_W * 6.0 + HCMD_PAD * 7.0;          // 342
const float  HCMD_WIN_H        = HCMD_BTN_H + HCMD_PAD * 2.0 + 50.0;         // 112 (with title + slack)

// Geometry bind
const string HCMD_BIND_GEOM    = "hcmd_geom";

// Button IDs
const string HCMD_BTN_FOLLOW   = "hcmd_btn_follow";
const string HCMD_BTN_STAND    = "hcmd_btn_stand";
const string HCMD_BTN_GUARD    = "hcmd_btn_guard";
const string HCMD_BTN_ATTACK   = "hcmd_btn_attack";
const string HCMD_BTN_SUMMON   = "hcmd_btn_summon";
const string HCMD_BTN_SAVE     = "hcmd_btn_save";

// LVAR on henchman - active AI mode (persists via ObjectToJson)
const string HENCH_LVAR_AI_MODE = "HENCH_AI_MODE";

const int HENCH_AI_FOLLOW = 1;
const int HENCH_AI_STAND  = 2;
const int HENCH_AI_GUARD  = 3;

// Delay reading geometry on Save - gives engine time to commit window position
// after drag (without it, the saved position is from a few seconds earlier).
const float HCMD_SAVE_DELAY = 0.5;

// Inline equivalent of SetAssociateState (from nw_i0_generic) - direct LVAR write
const string NW_ASC_TOGGLE_FLAGS_VAR = "NW_ASC_TOGGLE_FLAGS";
const int NW_ASC_FLAG_STAND_GROUND  = 0x00000040;  // NW_ASC_MODE_STAND_GROUND
const int NW_ASC_FLAG_DEFEND_MASTER = 0x00000080;  // NW_ASC_MODE_DEFEND_MASTER

void HenchAscSetFlag(object oHench, int nFlag, int bSet)
{
    int nFlags = GetLocalInt(oHench, NW_ASC_TOGGLE_FLAGS_VAR);
    if(bSet) nFlags = nFlags | nFlag;
    else     nFlags = nFlags & ~nFlag;
    SetLocalInt(oHench, NW_ASC_TOGGLE_FLAGS_VAR, nFlags);
}

// ============================================================
// AI command helpers - called from event handler
// ============================================================

void HenchCmdFollow(object oPC, object oHench)
{
    HenchAscSetFlag(oHench, NW_ASC_FLAG_STAND_GROUND,  FALSE);
    HenchAscSetFlag(oHench, NW_ASC_FLAG_DEFEND_MASTER, FALSE);
    AssignCommand(oHench, ClearAllActions(TRUE));
    AssignCommand(oHench, ActionForceFollowObject(oPC, 2.5));
    SetLocalInt(oHench, HENCH_LVAR_AI_MODE, HENCH_AI_FOLLOW);
}

void HenchCmdStand(object oHench)
{
    HenchAscSetFlag(oHench, NW_ASC_FLAG_STAND_GROUND,  TRUE);
    HenchAscSetFlag(oHench, NW_ASC_FLAG_DEFEND_MASTER, FALSE);
    AssignCommand(oHench, ClearAllActions(TRUE));
    SetLocalInt(oHench, HENCH_LVAR_AI_MODE, HENCH_AI_STAND);
}

void HenchCmdGuard(object oPC, object oHench)
{
    HenchAscSetFlag(oHench, NW_ASC_FLAG_DEFEND_MASTER, TRUE);
    HenchAscSetFlag(oHench, NW_ASC_FLAG_STAND_GROUND,  FALSE);
    AssignCommand(oHench, ClearAllActions(TRUE));
    AssignCommand(oHench, ActionForceFollowObject(oPC, 2.0));
    SetLocalInt(oHench, HENCH_LVAR_AI_MODE, HENCH_AI_GUARD);
}

void HenchCmdAttackNearest(object oPC, object oHench)
{
    object oTarget = GetNearestCreature(
        CREATURE_TYPE_REPUTATION, REPUTATION_TYPE_ENEMY, oHench);
    if(!GetIsObjectValid(oTarget))
    {
        SendMessageToPC(oPC, "No enemies nearby.");
        return;
    }
    AssignCommand(oHench, ClearAllActions(FALSE));
    AssignCommand(oHench, ActionAttack(oTarget));
}

void HenchCmdSummon(object oPC, object oHench)
{
    if(GetIsInCombat(oPC) || GetIsInCombat(oHench))
    {
        SendMessageToPC(oPC, "Cannot summon companion during combat.");
        return;
    }
    AssignCommand(oHench, ClearAllActions(TRUE));
    AssignCommand(oHench, JumpToObject(oPC));
}

// Called via DelayCommand from Save handler - after delay, reads current
// window position from bind and writes it to SQL.
void HenchCmdDoSavePosition(object oPC, int nToken)
{
    json jGeom = NuiGetBind(oPC, nToken, HCMD_BIND_GEOM);
    if(JsonGetType(jGeom) == JSON_TYPE_NULL) return;

    float fX = JsonGetFloat(JsonObjectGet(jGeom, "x"));
    float fY = JsonGetFloat(JsonObjectGet(jGeom, "y"));
    HenchUiSavePosition(GetObjectUUID(oPC), fX, fY);
    SendMessageToPC(oPC, "Window position saved.");
}

// ============================================================
// UI builder helper
// ============================================================
json HenchCmdBuildBtn(string sIcon, string sId, string sTooltip)
{
    json jBtn = NuiId(NuiButtonImage(JsonString(sIcon)), sId);
    jBtn = NuiTooltip(jBtn, JsonString(sTooltip));
    jBtn = NuiWidth (jBtn, HCMD_BTN_W);
    jBtn = NuiHeight(jBtn, HCMD_BTN_H);
    return jBtn;
}

// ============================================================
// Open window
// ============================================================
void CreateHenchCmdWindow(object oPC)
{
    if(NuiFindWindow(oPC, HCMD_WINDOW) != 0) return;
    if(!GetIsObjectValid(GetHenchman(oPC))) return;

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, HenchCmdBuildBtn("ir_follow",        HCMD_BTN_FOLLOW, "Follow"));
    jRow = JsonArrayInsert(jRow, HenchCmdBuildBtn("ir_standgrnd",     HCMD_BTN_STAND,  "Stand Ground"));
    jRow = JsonArrayInsert(jRow, HenchCmdBuildBtn("ir_guard",         HCMD_BTN_GUARD,  "Defend Me"));
    jRow = JsonArrayInsert(jRow, HenchCmdBuildBtn("ir_attacknearest", HCMD_BTN_ATTACK, "Attack Nearest"));
    jRow = JsonArrayInsert(jRow, HenchCmdBuildBtn("ir_emptyqs",       HCMD_BTN_SUMMON, "Summon"));
    jRow = JsonArrayInsert(jRow, HenchCmdBuildBtn("ir_assoc_action",  HCMD_BTN_SAVE,   "Save window position"));
    jRow = JsonArrayInsert(jRow, NuiSpacer());

    json jRoot = NuiCol(JsonArrayInsert(JsonArray(), NuiRow(jRow)));

    // Position: from SQL if saved, otherwise center of screen
    int   nW = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH);
    int   nH = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT);
    float fX, fY;

    json jPos = HenchUiLoadPosition(GetObjectUUID(oPC));
    if(JsonGetType(jPos) != JSON_TYPE_NULL)
    {
        fX = JsonGetFloat(JsonObjectGet(jPos, "x"));
        fY = JsonGetFloat(JsonObjectGet(jPos, "y"));
    }
    else
    {
        fX = (IntToFloat(nW) - HCMD_WIN_W) / 2.0;
        fY = (IntToFloat(nH) - HCMD_WIN_H) / 2.0;
    }

    int nToken = NuiCreate(oPC, NuiWindow(
        jRoot,
        JsonString("Commands"),
        NuiBind(HCMD_BIND_GEOM),
        JsonBool(FALSE),  // resizable
        JsonBool(FALSE),  // collapsed
        JsonBool(FALSE),  // closable
        JsonBool(FALSE),  // transparent (FALSE = solid background with draggable title bar)
        JsonBool(TRUE)    // border (TRUE = draggable title bar)
    ), HCMD_WINDOW, HCMD_EVT_SCRIPT);

    NuiSetBind(oPC, nToken, HCMD_BIND_GEOM, NuiRect(fX, fY, HCMD_WIN_W, HCMD_WIN_H));
    NuiSetBindWatch(oPC, nToken, HCMD_BIND_GEOM, TRUE);
}

// ============================================================
// Close window
// ============================================================
void DestroyHenchCmdWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, HCMD_WINDOW);
    if(nToken > 0) NuiDestroy(oPC, nToken);
}

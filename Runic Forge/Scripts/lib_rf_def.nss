#include "lib_nui"
#include "sql_rf"

// Forward declarations (implementations in lib_rf.nss)
void RFOpenForge(object oPC);
void RFFeedForge(object oPC, int nToken);
void RFMGDisplayHighlight(object oPC, int nStep);
void RFMGDisplayUnhighlight(object oPC, int nStep);
void RFMGEnableInput(object oPC);
void RFMinigameFail(object oPC);
void RFMinigameSuccess(object oPC);

// ---- Window IDs ----
const string RF_WIN_FORGE      = "RF_WIN_FORGE";
const string RF_WIN_MINIGAME   = "RF_WIN_MINIGAME";
const string RF_EV_SCRIPT      = "lib_rf_ev";

// ---- Forge window binds ----
const string RF_BIND_WIN_GEOM  = "rf_win_geom";
const string RF_BIND_WPN_NAME  = "rf_wpn_name";  // weapon name label or placeholder
const string RF_BIND_WPN_ENA   = "rf_wpn_ena";   // "Wybierz" button enabled
const string RF_BIND_ENCH_LBL  = "rf_ench_lbl";  // current enchant summary label
const string RF_BIND_COST_LBL  = "rf_cost_lbl";  // gold cost label
const string RF_BIND_FORGE_ENA = "rf_forge_ena"; // "Kuj!" button enabled
const string RF_BIND_RUNE_ENC  = "rf_rune_enc_"; // + IntToString(i), 6 binds

// ---- Minigame window binds ----
const string RF_BIND_MG_GEOM   = "rf_mg_geom";
const string RF_BIND_MG_STATUS = "rf_mg_status"; // phase description label
const string RF_BIND_MG_STEP   = "rf_mg_step";   // "Krok: 2/5"
const string RF_BIND_MG_ENC    = "rf_mg_enc_";   // + IntToString(i), 9 binds
const string RF_BIND_MG_ENA    = "rf_mg_ena_";   // + IntToString(i), 9 binds

// ---- Button element IDs ----
const string RF_BTN_CLOSE      = "rf_btn_close";
const string RF_BTN_WEAPON     = "rf_btn_weapon";
const string RF_BTN_RUNE       = "rf_btn_rune_"; // + IntToString(i)
const string RF_BTN_FORGE      = "rf_btn_forge";
const string RF_BTN_MG         = "rf_mg_btn_";   // + IntToString(i)

// ---- Local variables stored on PC object ----
const string RF_LVAR_WPN_UUID  = "RF_WPN_UUID";
const string RF_LVAR_WPN_NAME  = "RF_WPN_NAME";
const string RF_LVAR_SEL_RUNE  = "RF_SEL_RUNE";  // -1 = none
const string RF_LVAR_TARGETING = "RF_TARGETING"; // 1 = forge targeting active
const string RF_LVAR_MG_SEQ    = "RF_MG_SEQ";     // JsonArray<int> button sequence
const string RF_LVAR_MG_POS    = "RF_MG_POS";     // next expected index during input
const string RF_LVAR_MG_PHASE  = "RF_MG_PHASE";   // 0=display, 1=input
const string RF_LVAR_MG_DONE   = "RF_MG_DONE";    // 1 = minigame resolved (stops DelayCommands)
const string RF_LVAR_MG_COST   = "RF_MG_COST";    // gold paid for current attempt
// Copied from forge LVARs at minigame start; outlive the forge window close event.
const string RF_LVAR_MG_WPN    = "RF_MG_WPN";     // weapon UUID for active minigame attempt
const string RF_LVAR_MG_RUNE   = "RF_MG_RUNE";    // rune ID for active minigame attempt

// ---- Rune IDs ----
const int RF_RUNE_FIRE         = 0;
const int RF_RUNE_ICE          = 1;
const int RF_RUNE_STORM        = 2;
const int RF_RUNE_SHADOW       = 3;
const int RF_RUNE_RADIANCE     = 4;
const int RF_RUNE_BLOOD        = 5;
const int RF_RUNE_COUNT        = 6;

const int RF_MAX_LEVEL         = 5;
const int RF_BASE_COST         = 500;
const int RF_COST_PER_LEVEL    = 300;

// ---- Layout dimensions ----
const float RF_W               = 500.0;
const float RF_H               = 450.0;
const float RF_MG_W            = 380.0;
const float RF_MG_H            = 380.0;


// -----------------------------------------------------------------------
// Targeting callback — invoked from sys_on_target.nss
// -----------------------------------------------------------------------

void RFOnPlayerTarget(object oPC)
{
    if(!GetLocalInt(oPC, RF_LVAR_TARGETING)) return;
    DeleteLocalInt(oPC, RF_LVAR_TARGETING);

    int nToken = NuiFindWindow(oPC, RF_WIN_FORGE);
    if(nToken == 0) return;

    NuiSetBind(oPC, nToken, RF_BIND_WPN_ENA, JsonBool(TRUE));

    object oItem = GetTargetingModeSelectedObject();

    if(!GetIsObjectValid(oItem) || GetItemPossessor(oItem) != oPC)
    {
        SendMessageToPC(oPC, "[Kuźnia] Wybierz broń ze swojego ekwipunku.");
        return;
    }

    // Weapons have a non-zero die in baseitems.2da; armour/shields/misc do not.
    string sDie = Get2DAString("baseitems", "DieToRoll", GetBaseItemType(oItem));
    if(sDie == "****" || StringToInt(sDie) == 0)
    {
        SendMessageToPC(oPC, "[Kuźnia] Tylko bronie mogą być rytowane runami.");
        return;
    }

    string sUuid = GetObjectUUID(oItem);
    string sName = GetName(oItem);
    SetLocalString(oPC, RF_LVAR_WPN_UUID, sUuid);
    SetLocalString(oPC, RF_LVAR_WPN_NAME, sName);

    RFFeedForge(oPC, nToken);
}

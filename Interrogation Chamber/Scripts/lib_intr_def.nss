#include "lib_nui"
#include "sql_intr"

void IntrOpenWindow(object oPC, object oPrisoner);
void IntrFeedStatus(object oPC, int nToken);
void IntrApplyMethod(object oPC, int nMethod);
void IntrApplyMoralPenalty(object oPC);
void IntrAppendLog(object oPC, int nToken, string sLine);

// ----------------------------------------------------------------
// Window / event IDs
// ----------------------------------------------------------------

const string INTR_WINDOW    = "INTR_WINDOW";
const string INTR_EV_SCRIPT = "lib_intr_ev";
const string INTR_WIN_GEOM  = "intr_win_geom";

// ----------------------------------------------------------------
// Bind IDs
// ----------------------------------------------------------------

const string INTR_BIND_PRISONER_NAME = "intr_pris_name";
const string INTR_BIND_PRISONER_TYPE = "intr_pris_type";
const string INTR_BIND_RESISTANCE    = "intr_resistance";
const string INTR_BIND_RES_LABEL     = "intr_res_label";
const string INTR_BIND_RES_COLOR     = "intr_res_color";
const string INTR_BIND_MORAL_LABEL   = "intr_moral_lbl";
const string INTR_BIND_LOG           = "intr_log";
const string INTR_BIND_BTN_Q_ENA     = "intr_btn_q_ena";
const string INTR_BIND_BTN_I_ENA     = "intr_btn_i_ena";
const string INTR_BIND_BTN_T_ENA     = "intr_btn_t_ena";
const string INTR_BIND_BTN_D_ENA     = "intr_btn_d_ena";
const string INTR_BIND_STATUS        = "intr_status";
const string INTR_BIND_STATUS_COLOR  = "intr_status_color";
const string INTR_BIND_HD_LABEL      = "intr_hd_label";

// ----------------------------------------------------------------
// Button IDs
// ----------------------------------------------------------------

const string INTR_BTN_CLOSE      = "intr_btn_close";
const string INTR_BTN_QUESTION   = "intr_btn_q";
const string INTR_BTN_INTIMIDATE = "intr_btn_i";
const string INTR_BTN_TORTURE    = "intr_btn_t";
const string INTR_BTN_DECEIVE    = "intr_btn_d";

// ----------------------------------------------------------------
// Local variable keys on PC (all scoped by prisoner UUID suffix)
// ----------------------------------------------------------------

const string INTR_LVAR_PRISONER_UUID = "INTR_PRISONER_UUID";
const string INTR_LVAR_RESISTANCE    = "INTR_RES";      // + "_" + prisonerUUID
const string INTR_LVAR_MORAL_COST    = "INTR_MORAL";
const string INTR_LVAR_THRESHOLD_75  = "INTR_T75_";     // + prisonerUUID
const string INTR_LVAR_THRESHOLD_50  = "INTR_T50_";
const string INTR_LVAR_THRESHOLD_25  = "INTR_T25_";
const string INTR_LVAR_THRESHOLD_0   = "INTR_T0_";
const string INTR_LVAR_LOG           = "INTR_LOG";
const string INTR_LVAR_BROKEN        = "INTR_BROKEN_";  // + prisonerUUID

// ----------------------------------------------------------------
// Method constants
// ----------------------------------------------------------------

const int INTR_METHOD_QUESTION   = 0;
const int INTR_METHOD_INTIMIDATE = 1;
const int INTR_METHOD_TORTURE    = 2;
const int INTR_METHOD_DECEIVE    = 3;

// ----------------------------------------------------------------
// Mechanics constants
// ----------------------------------------------------------------

const int INTR_RES_BASE           = 50;   // base starting resistance
const int INTR_RES_MIN            = 20;
const int INTR_RES_MAX            = 100;
const int INTR_MORAL_THRESHOLD    = 10;   // points per alignment shift
const int INTR_TORTURE_DEATH_ROLL = 8;    // % chance of death when res <= 25

// Window dimensions
const float INTR_W = 540.0;
const float INTR_H = 490.0;

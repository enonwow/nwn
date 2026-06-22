// lib_lch_def.nss — constants, forward declarations, and non-UI helpers for Lichwiarz

#include "lib_nui"
#include "sql_lch"

// --- Forward declarations from lib_lch.nss ---
void LchOpenWindow(object oPC);
void FeedLchMain(object oPC, int nToken);
void LchCreateBorrowPopup(object oPC);
void LchCreateRepayPopup(object oPC);
void LchHandleBorrow(object oPC);
void LchHandleRepay(object oPC, int bFull);

// --- Window identifiers ---
const string LCH_WINDOW        = "LCH_WINDOW";
const string LCH_WIN_BORROW    = "LCH_WIN_BORROW";
const string LCH_WIN_REPAY     = "LCH_WIN_REPAY";
const string LCH_EV_SCRIPT     = "lib_lch_ev";

// --- Dimensions ---
const float  LCH_W             = 480.0;
const float  LCH_H             = 360.0;
const float  LCH_POPUP_W       = 400.0;
const float  LCH_POPUP_H       = 290.0;

// --- Main window binds ---
const string LCH_BIND_WIN_GEOM      = "lch_win_geom";
const string LCH_BIND_DEBT_LBL      = "lch_debt_lbl";
const string LCH_BIND_PRINCIPAL_LBL = "lch_principal_lbl";
const string LCH_BIND_REPAID_LBL    = "lch_repaid_lbl";
const string LCH_BIND_RATE_LBL      = "lch_rate_lbl";
const string LCH_BIND_TICK_LBL      = "lch_tick_lbl";
const string LCH_BIND_PENALTY_LBL   = "lch_penalty_lbl";
const string LCH_BIND_PENALTY_COL   = "lch_penalty_col";
const string LCH_BIND_BORROW_ENA    = "lch_borrow_ena";
const string LCH_BIND_REPAY_ENA     = "lch_repay_ena";

// --- Borrow popup binds ---
const string LCH_BIND_BORROW_AMT    = "lch_borrow_amt";
const string LCH_BIND_CONFIRM_ENA   = "lch_confirm_ena";

// --- Repay popup binds ---
const string LCH_BIND_REPAY_AMT     = "lch_repay_amt";
const string LCH_BIND_REPAY_DEBT    = "lch_repay_debt_lbl";
const string LCH_BIND_REPAY_GOLD    = "lch_repay_gold_lbl";
const string LCH_BIND_DO_REPAY_ENA  = "lch_do_repay_ena";
const string LCH_BIND_FULL_LBL      = "lch_full_lbl";
const string LCH_BIND_FULL_ENA      = "lch_full_ena";

// --- Buttons ---
const string LCH_BTN_CLOSE          = "lch_btn_close";
const string LCH_BTN_BORROW         = "lch_btn_borrow";
const string LCH_BTN_REPAY          = "lch_btn_repay";
const string LCH_BTN_BORROW_OK      = "lch_btn_borrow_ok";
const string LCH_BTN_BORROW_X       = "lch_btn_borrow_x";
const string LCH_BTN_REPAY_DO       = "lch_btn_repay_do";
const string LCH_BTN_REPAY_FULL     = "lch_btn_repay_full";
const string LCH_BTN_REPAY_X        = "lch_btn_repay_x";

// --- LVARs on PC object ---
const string LCH_LVAR_PENALTY       = "LCH_PENALTY_LEVEL";

// --- Loan limits ---
const int    LCH_MAX_LOAN           = 50000;
const int    LCH_MIN_LOAN           = 100;

// Debt-to-principal thresholds (%) that trigger each penalty level
const int    LCH_PENALTY_1_PCT      = 150;   // 150 % → Klątwa
const int    LCH_PENALTY_2_PCT      = 200;   // 200 % → Piętno
const int    LCH_PENALTY_3_PCT      = 300;   // 300 % → Egzekutor

// Resref of the enforcer creature (must exist in hak or module palette)
const string LCH_ENFORCER_RESREF    = "lch_enforcer";

// Tag applied to all managed effects so they can be batch-removed
const string LCH_EFFECT_TAG         = "LCH_DEBT_EFFECT";

// ----------------------------------------------------------------
// Display helpers
// ----------------------------------------------------------------

string LchFormatTime(int nSeconds)
{
    if(nSeconds <= 0)    return "teraz";
    if(nSeconds < 60)    return IntToString(nSeconds) + " sek.";
    if(nSeconds < 3600)  return IntToString(nSeconds / 60) + " min.";
    int nH = nSeconds / 3600;
    int nM = (nSeconds / 60) - nH * 60;
    return IntToString(nH) + " godz. " + IntToString(nM) + " min.";
}

string LchPenaltyName(int nLevel)
{
    if(nLevel <= 0) return "Brak";
    if(nLevel == 1) return "Klątwa Niespłaconego";
    if(nLevel == 2) return "Piętno Dłużnika";
    return "Egzekutor";
}

json LchPenaltyColor(int nLevel)
{
    if(nLevel <= 0) return NuiColor(150, 200, 150);
    if(nLevel == 1) return NuiColor(220, 190, 60);
    if(nLevel == 2) return NuiColor(220, 100, 30);
    return NuiColor(200, 30, 30);
}

// ----------------------------------------------------------------
// Effect management
// ----------------------------------------------------------------

void LchRemovePenaltyEffects(object oPC)
{
    RemoveTaggedEffects(oPC, LCH_EFFECT_TAG);
    DeleteLocalInt(oPC, LCH_LVAR_PENALTY);
}

void LchApplyPenalties(object oPC, int nPenaltyLevel)
{
    int nCurrent = GetLocalInt(oPC, LCH_LVAR_PENALTY);
    if(nCurrent == nPenaltyLevel) return;

    LchRemovePenaltyEffects(oPC);
    SetLocalInt(oPC, LCH_LVAR_PENALTY, nPenaltyLevel);

    if(nPenaltyLevel == 0) return;

    effect eCurse;
    effect eVFX;
    effect eLink;

    if(nPenaltyLevel == 1)
    {
        // Klątwa Niespłaconego — lekki debuff na wszystkie statystyki
        eCurse = EffectCurse(1, 1, 1, 0, 1, 0);
        eCurse = TagEffect(eCurse, LCH_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eCurse, oPC);
        SendMessageToPC(oPC, "[Lichwiarz] Pieczęć długu pulsuje słabo na twojej skórze… „Płać lub cierp."");
    }
    else if(nPenaltyLevel == 2)
    {
        // Piętno Dłużnika — silny debuff + mroczna aura
        eCurse = EffectCurse(2, 2, 2, 1, 2, 2);
        eVFX   = EffectVisualEffect(VFX_DUR_PROT_EVIL_10);
        eLink  = EffectLinkEffects(eCurse, eVFX);
        eLink  = TagEffect(eLink, LCH_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eLink, oPC);
        SendMessageToPC(oPC, "[Lichwiarz] Piętno dłużnika znaczy twoje oblicze. Każdy widzi twój wstyd.");
        FloatingTextStringOnCreature("Piętno Dłużnika!", oPC, FALSE);
    }
    else
    {
        // Egzekutor — silny debuff, mroczna aura, spawn wrogiego ścigającego
        eCurse = EffectCurse(3, 3, 3, 2, 3, 3);
        eVFX   = EffectVisualEffect(VFX_DUR_PROT_EVIL_10);
        eLink  = EffectLinkEffects(eCurse, eVFX);
        eLink  = TagEffect(eLink, LCH_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eLink, oPC);

        // Spawns once; unique tag per PC prevents duplicates
        string sEnfTag = "LCH_ENF_" + GetObjectUUID(oPC);
        object oEnf = GetObjectByTag(sEnfTag);
        if(!GetIsObjectValid(oEnf))
        {
            oEnf = CreateObject(OBJECT_TYPE_CREATURE, LCH_ENFORCER_RESREF, GetLocation(oPC), FALSE, sEnfTag);
            if(GetIsObjectValid(oEnf))
                AssignCommand(oEnf, ActionAttackObject(oPC));
        }
        SendMessageToPC(oPC, "[Lichwiarz] „Nie chciałeś płacić słowami. Zapłacisz krwią." Egzekutor wyłania się z cienia.");
        FloatingTextStringOnCreature("Egzekutor!", oPC, FALSE);
    }
}

// ----------------------------------------------------------------
// Debt lifecycle — call on login and when the window opens
// ----------------------------------------------------------------

void LchCheckAndApplyPenalties(object oPC)
{
    LchTickInterest(oPC);

    json jLoan = LchGetLoan(oPC);
    if(JsonGetType(jLoan) == JSON_TYPE_NULL)
    {
        LchRemovePenaltyEffects(oPC);
        return;
    }

    int nDebt      = JsonGetInt(JsonObjectGet(jLoan, "current_debt"));
    int nPrincipal = JsonGetInt(JsonObjectGet(jLoan, "principal"));

    if(nPrincipal <= 0)
    {
        LchRemovePenaltyEffects(oPC);
        return;
    }

    int nPct     = (nDebt * 100) / nPrincipal;
    int nNewLevel = 0;
    if     (nPct >= LCH_PENALTY_3_PCT) nNewLevel = 3;
    else if(nPct >= LCH_PENALTY_2_PCT) nNewLevel = 2;
    else if(nPct >= LCH_PENALTY_1_PCT) nNewLevel = 1;

    if(nNewLevel != JsonGetInt(JsonObjectGet(jLoan, "penalty_level")))
        LchSetPenaltyLevel(oPC, nNewLevel);

    LchApplyPenalties(oPC, nNewLevel);
}

// Called when debt reaches zero
void LchOnDebtCleared(object oPC)
{
    LchRemovePenaltyEffects(oPC);

    // Destroy any live enforcer assigned to this PC
    string sEnfTag = "LCH_ENF_" + GetObjectUUID(oPC);
    object oEnf = GetObjectByTag(sEnfTag);
    if(GetIsObjectValid(oEnf))
        DestroyObject(oEnf);

    SendMessageToPC(oPC, "[Lichwiarz] Dług spłacony w całości. Ciemność cofa się od twojej duszy… na razie.");
    FloatingTextStringOnCreature("Dług spłacony!", oPC, FALSE);
}

// sys_on_enter.nss — module OnClientEnter: tick interest and enforce debt penalties on login
#include "lib_lch"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    json jLoan = LchGetLoan(oPC);
    if(JsonGetType(jLoan) == JSON_TYPE_NULL) return;

    // Accumulate any missed ticks and (re-)apply penalty effects
    LchCheckAndApplyPenalties(oPC);

    // Reload after tick so values reflect interest accrued while offline
    jLoan = LchGetLoan(oPC);
    if(JsonGetType(jLoan) == JSON_TYPE_NULL) return;

    int nDebt    = JsonGetInt(JsonObjectGet(jLoan, "current_debt"));
    int nPenalty = JsonGetInt(JsonObjectGet(jLoan, "penalty_level"));

    string sMsg = "[Lichwiarz] Twój aktualny dług wynosi " + IntToString(nDebt) + " sz.";
    if(nPenalty > 0)
        sMsg = sMsg + " Aktywna kara: " + LchPenaltyName(nPenalty) + ".";

    DelayCommand(3.0, SendMessageToPC(oPC, sMsg));
    DelayCommand(3.0, FloatingTextStringOnCreature("Dług: " + IntToString(nDebt) + " sz.", oPC, FALSE));
}

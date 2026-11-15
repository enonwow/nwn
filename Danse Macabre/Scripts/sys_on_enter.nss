#include "lib_mac"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    MacRegisterPlayer(oPC);

    int nProx = MacGetProximity(oPC);

    // Re-apply the Marked by Death debuff if the player logs in with high proximity
    if(nProx >= MAC_TIER_STALKED && !GetLocalInt(oPC, "MAC_MARKED_BY_DEATH"))
    {
        SetLocalInt(oPC, "MAC_MARKED_BY_DEATH", 1);
        DelayCommand(3.0, ApplyEffectToObject(DURATION_TYPE_PERMANENT,
            EffectAttackDecrease(1, ATTACK_BONUS_MISC), oPC));
    }

    // Warn player of their current proximity
    if(nProx >= MAC_TIER_STALKED)
    {
        string sMsg = "[Danse Macabre] Bliskosc Smierci: " + IntToString(nProx) + "/100 — NIEUCHRONNA. "
            + "Smierc stoi za toba. Otwórz dziennik Danse Macabre (uzyjcie '/mac' lub placeabla).";
        DelayCommand(4.0, SendMessageToPC(oPC, sMsg));
        DelayCommand(4.0, FloatingTextStringOnCreature(sMsg, oPC, FALSE));
    }
    else if(nProx >= MAC_TIER_WATCHED)
    {
        string sMsg = "[Danse Macabre] Bliskosc Smierci: " + IntToString(nProx) + "/100 — Uwazaj.";
        DelayCommand(4.0, SendMessageToPC(oPC, sMsg));
    }

    // If proximity is at 100, open the bargain window shortly after entering
    if(nProx >= MAC_TIER_IMMINENT)
        DelayCommand(6.0, MacOpenWindow(oPC));
}

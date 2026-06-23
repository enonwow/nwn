#include "lib_exrc"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    int nLevel = ExrcGetLevel(oPC);
    if(nLevel == EXRC_LEVEL_CLEAN) return;

    ExrcApplyPossessionEffects(oPC, nLevel);

    json jRecord = ExrcGetRecord(oPC);
    string sEntity = JsonGetString(JsonObjectGet(jRecord, "entity_name"));
    if(sEntity == "") sEntity = "Nieznana Istota";

    string sMsg = "[Egzorcyzm] " + ExrcGetLevelName(nLevel)
        + " — " + sEntity + " wciąż przebywa w twojej duszy.";
    DelayCommand(3.0, SendMessageToPC(oPC, sMsg));
    DelayCommand(3.0, FloatingTextStringOnCreature(sMsg, oPC, FALSE));
}

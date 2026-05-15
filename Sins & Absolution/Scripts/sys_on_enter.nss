#include "lib_sin"

void main()
{
    object oPC = GetEnteringObject();
    if (!GetIsPC(oPC)) return;

    SinRegisterChar(oPC);
    SinApplyPenalties(oPC);

    if (SinIsEmbraced(oPC))
        SinApplyEmbraceEffects(oPC);

    int nScore = SinGetScore(oPC);
    if (nScore < SIN_LEVEL_TAINTED) return;

    string sMsg = "[Piętno] " + SinLevelName(nScore) +
        " — " + IntToString(nScore) + " pkt grzechu. " +
        "Kary: " + SinGetPenaltyDesc(nScore) + ". " +
        "Użyj ołtarza spowiedzi, by sprawdzić stan duszy.";
    DelayCommand(3.0, SendMessageToPC(oPC, sMsg));
}

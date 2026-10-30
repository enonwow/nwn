#include "lib_eff_app"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    EffRegisterPlayerDb(oPC);

    int nActive = JsonGetLength(EffGetEffigiesTargeting(GetObjectUUID(oPC)));
    if(nActive > 0)
    {
        // Re-apply stat-drain effects for Wither and Torpor curses
        EffApplyEffectsToPC(oPC);

        int nDetected = JsonGetLength(EffGetDetectedAffecting(GetObjectUUID(oPC)));
        int nHidden   = nActive - nDetected;

        if(nHidden > 0)
        {
            DelayCommand(5.0, SendMessageToPC(oPC,
                "[Figurka] Pieczęć krwi pulsuje słabo… Coś ciągnie cię ku ciemności."));
        }
        else if(nDetected > 0)
        {
            DelayCommand(5.0, SendMessageToPC(oPC,
                "[Figurka] Odczuwasz " + IntToString(nDetected) + " aktywną klątwę figurki."));
        }
    }
}

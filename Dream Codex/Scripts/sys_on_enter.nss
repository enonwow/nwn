#include "lib_drm"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    // Hint on login if cooldown is ready.
    if(DrmCooldownReady(oPC))
    {
        string sMsg = "[Kodeks Wizji] Pieczęć krwi pulsuje. Kamień Wizji czeka na twój dotyk.";
        DelayCommand(5.0, SendMessageToPC(oPC, sMsg));
    }
}

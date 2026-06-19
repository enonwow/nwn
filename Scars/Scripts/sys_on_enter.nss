#include "lib_scar"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    // Advance any wounds that finished healing while the player was offline
    ScarRefreshHealed(oPC);
    ScarApplyEffects(oPC);

    int nOpen = ScarDbCountOpen(oPC);
    if(nOpen > 0)
    {
        string sMsg = "[Rana] Masz " + IntToString(nOpen)
            + " niezaopatrzoną ranę. Kary do statystyk są aktywne. "
            + "Odwiedź chirurga lub użyj placeable \"Stół Medyczny\".";
        DelayCommand(3.0, SendMessageToPC(oPC, sMsg));
        DelayCommand(3.5, FloatingTextStringOnCreature(sMsg, oPC, FALSE));
    }
}

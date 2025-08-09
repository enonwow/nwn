#include "lib_app_panel"

void main()
{
    object oPC = GetEnteringObject();

    if(GetIsPC(oPC) && !GetIsDM(oPC))
    {
        DressingRoomDisableGuiPanel(oPC, TRUE);
        DelayCommand(0.1, FadeToBlack(oPC, 0.0));

        float fDelay = 1.0;
        DelayCommand(fDelay, DressingRoomCreateCopy(oPC));

        fDelay += 1.0;
        DelayCommand(fDelay, EnterDressingRoom(oPC));

        fDelay += 1.0;
        struct ButtonController ButtonController = AppReadButtonController(GetArea(oPC));
        DelayCommand(fDelay, CreateAppRightPanelWindow(oPC, ButtonController));
        DelayCommand(fDelay, FadeFromBlack(oPC, 0.0));
    }
}

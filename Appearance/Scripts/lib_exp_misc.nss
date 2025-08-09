#include "lib_app_panel"

void main()
{
    object oPC = GetLastUsedBy();

    struct ButtonController ButtonController;
    ButtonController.bMiscButton = TRUE;

    CreateAppRightPanelWindow(oPC, ButtonController);
}
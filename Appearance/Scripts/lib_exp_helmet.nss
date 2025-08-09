#include "lib_app_panel"

void main()
{
    object oPC = GetLastUsedBy();

    object oArea = CreateDressingRoom(oPC);

    SetLocalInt(oArea, APP_BUTTON_HELMET_ENABLED, TRUE);
}

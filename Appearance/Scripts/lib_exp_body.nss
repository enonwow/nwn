#include "lib_app_panel"

void main()
{
    object oPC = GetLastUsedBy();

    object oArea = CreateDressingRoom(oPC);

    SetLocalInt(oArea, APP_BUTTON_HEAD_ENABLED, TRUE);
    SetLocalInt(oArea, APP_BUTTON_BODY_ENABLED, TRUE);
    SetLocalInt(oArea, APP_BUTTON_TATOO_ENABLED, TRUE);
}

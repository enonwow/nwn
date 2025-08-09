#include "lib_app_panel"

void main()
{
    object oPC = GetLastUsedBy();

    object oArea = CreateDressingRoom(oPC);

    SetLocalInt(oArea, APP_BUTTON_HEAD_ENABLED, TRUE);
    SetLocalInt(oArea, APP_BUTTON_BODY_ENABLED, TRUE);
    SetLocalInt(oArea, APP_BUTTON_TATOO_ENABLED, TRUE);
    SetLocalInt(oArea, APP_BUTTON_HELMET_ENABLED, TRUE);
    SetLocalInt(oArea, APP_BUTTON_ARMOR_ENABLED, TRUE);
    SetLocalInt(oArea, APP_BUTTON_CLOAK_ENABLED, TRUE);
    SetLocalInt(oArea, APP_BUTTON_WEAPON_ENABLED, TRUE);
    SetLocalInt(oArea, APP_BUTTON_SHIELD_ENABLED, TRUE);
}
    
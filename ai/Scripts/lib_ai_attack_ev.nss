#include "lib_ai_attack"

void main()
{
    object oPC = OBJECT_SELF;

    if(JsonGetString(GetEventData().event) != EVENT_TYPE_CLICK)
    {
        return;
    }

    int nToken = NuiFindWindow(oPC, AI_ATTACK_WINDOW);
    if(nToken <= 0)
    {
        return;
    }

    string sElement = JsonGetString(GetEventData().element);

    if(sElement == AI_BTN_MAIN)
    {
        AIAttackApplyBinds(oPC, nToken, AI_HAND_MAIN);
        return;
    }

    if(sElement == AI_BTN_OFF)
    {
        if(JsonGetInt(NuiGetBind(oPC, nToken, AI_BIND_OFF_ENABLED)))
        {
            AIAttackApplyBinds(oPC, nToken, AI_HAND_OFF);
        }
    }
}

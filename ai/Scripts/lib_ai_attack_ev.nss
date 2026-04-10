#include "lib_ai_attack"

void main()
{
    object oPC = OBJECT_SELF;

    string sEventType = JsonGetString(GetEventData().event);
    if(sEventType != EVENT_TYPE_CLICK)
    {
        return;
    }

    string sElement = JsonGetString(GetEventData().element);

    int nToken = NuiFindWindow(oPC, AI_ATTACK_WINDOW);
    if(nToken <= 0)
    {
        return;
    }

    if(sElement == AI_BTN_MAIN)
    {
        AIAttackApplyBinds(oPC, nToken, AI_HAND_MAIN);
        return;
    }

    if(sElement == AI_BTN_OFF)
    {
        int bEnabled = JsonGetInt(NuiGetBind(oPC, nToken, AI_BIND_OFF_DISABLED));
        if(bEnabled)
        {
            AIAttackApplyBinds(oPC, nToken, AI_HAND_OFF);
        }
    }
}

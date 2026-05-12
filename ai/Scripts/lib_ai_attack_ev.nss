#include "lib_ai_attack"

object oPC         = NuiGetEventPlayer();
string sEventType  = NuiGetEventType();
int    nToken      = NuiGetEventWindow();
string sEventElem  = NuiGetEventElement();
string sWindowId   = NuiGetWindowId(oPC, nToken);

void main()
{
    if(sWindowId != AI_ATTACK_WINDOW)
    {
        return;
    }

    if(sEventType != EVENT_TYPE_CLICK)
    {
        return;
    }

    if(sEventElem == AI_BTN_MAIN)
    {
        AIAttackApplyBinds(oPC, nToken, AI_HAND_MAIN);
        return;
    }

    if(sEventElem == AI_BTN_OFF)
    {
        if(JsonGetInt(NuiGetBind(oPC, nToken, AI_BIND_OFF_ENABLED)))
        {
            AIAttackApplyBinds(oPC, nToken, AI_HAND_OFF);
        }
    }
}

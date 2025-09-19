#include "lib_g_lockpick"

object oPC         = NuiGetEventPlayer();
string sEventType  = NuiGetEventType();
int    nToken      = NuiGetEventWindow();
string sEventElem  = NuiGetEventElement();
int    nEnventIdx  = NuiGetEventArrayIndex();
string sWindowId   = NuiGetWindowId(oPC, nToken);

void main()
{
    if(sEventType == EVENT_TYPE_MOUSEDOWN)
    {
        if(sEventElem == GOTHIC_LOCKPICK_GROUP)
        {
            json jPayload = NuiGetEventPayload();
            json jKeys = JsonObjectKeys(jPayload);
            json jButton = JsonObjectGet(jPayload,"mouse_btn");
            json jCoords = JsonObjectGet(jPayload,"mouse_pos");

            int nButton = JsonGetInt(jButton);

            if(nButton == EVENT_BUTTON_RIGHT)
            {
                NuiDestroy(oPC, nToken);
            }
        }
    }
}

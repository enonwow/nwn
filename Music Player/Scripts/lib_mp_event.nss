#include "lib_mp"

object oPC         = NuiGetEventPlayer();
string sEventType  = NuiGetEventType();
int    nToken      = NuiGetEventWindow();
string sEventElem  = NuiGetEventElement();
int    nEnventIdx  = NuiGetEventArrayIndex();
string sWindowId   = NuiGetWindowId(oPC, nToken);

void main()
{
    if (sEventType == EVENT_TYPE_CLICK)
    {
        if(sEventElem == MP_BUTTON_CLOSE)
        {
            NuiDestroy(oPC, nToken);
        }
        else if(sEventElem == MP_BUTTON_PLAY)
        {
            MPPlay(oPC, nToken);
        }
    }
    else if(sEventType == EVENT_TYPE_MOUSEDOWN)
    {
        if (sEventElem == MP_MOUSEDOWN)
        {
            NuiSetBind(oPC, nToken, MP_BUTTON_PLAY_ENABLED, JsonBool(TRUE));

            NuiOffEncouragedData(oPC, nToken);
            NuiOnEncouragedData(oPC, nToken, nEnventIdx);
        }
    }
}

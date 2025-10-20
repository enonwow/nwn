#include "lib_running"

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
        if(sEventElem == RUNNING_BUTTON)
        {
            int bToogle = JsonGetInt(NuiGetBind(oPC, nToken, RUNNING_TOOGLE));
            SetToogle(oPC, nToken, !bToogle);
        }
    }
}

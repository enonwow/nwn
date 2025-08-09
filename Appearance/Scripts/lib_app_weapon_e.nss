#include "lib_app_weapon"

object oPC         = NuiGetEventPlayer();
string sEventType  = NuiGetEventType();
int    nToken      = NuiGetEventWindow();
string sEventElem  = NuiGetEventElement();
int    nEnventIdx  = NuiGetEventArrayIndex();
string sWindowId   = NuiGetWindowId(oPC, nToken);

void main()
{
    AppWeaponEvents(sEventType, sEventElem, oPC, nToken);
}

#include "lib_ribbon"

void main()
{
    object oPC = GetEnteringObject();
    string sText = GetLocalString(OBJECT_SELF, RIBBON_TEXT);
    CreateRibbonWindow(oPC, sText);
}

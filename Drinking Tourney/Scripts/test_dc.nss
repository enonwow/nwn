#include "lib_dc_ui"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    CreateDcWindow(oPC);
}

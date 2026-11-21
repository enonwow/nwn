#include "lib_ma"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    CreateMaWindow(oPC);
}

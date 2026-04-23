#include "lib_sm"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    CreateSmWindow(oPC);
}

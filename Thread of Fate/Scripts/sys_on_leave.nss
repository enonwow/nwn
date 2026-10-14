#include "lib_nit"

void main()
{
    object oPC = GetExitingObject();
    if(!GetIsPC(oPC)) return;
    NitOnClientLeave(oPC);
}

#include "lib_nit"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;
    NitOnClientEnter(oPC);
}

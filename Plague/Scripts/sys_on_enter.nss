#include "lib_plg"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    PlgOnClientEnter(oPC);
}

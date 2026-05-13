// sys_on_enter.nss — module OnClientEnter hook.
//   Registers the character, restores persistent effects, and gives a
//   sanity-status reminder when their mind is already troubled.

#include "lib_san"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    SanOnPlayerEnter(oPC);
}

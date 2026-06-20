// sys_on_enter.nss — module OnClientEnter: restore oath effects after login

#include "lib_oath"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    OathRestoreOnLogin(oPC);
}

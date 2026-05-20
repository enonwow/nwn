// sys_on_enter.nss — Trophy Hall: register player rows on module enter
// Hook: OnClientEnter (or append to existing OnClientEnter)

#include "sql_trph"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;
    TrphRegisterPlayer(oPC);
}

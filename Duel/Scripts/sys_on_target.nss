// sys_on_target.nss
// OnPlayerTarget - dispatches to the duel system only when WE initiated targeting.
// Other systems sharing OnPlayerTarget should add their own active-flag check.
#include "lib_duel"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetIsPC(oPC)) return;

    if(GetLocalInt(oPC, DUEL_LVAR_TARGETING_ACTIVE) == 1)
    {
        DuelOnPlayerTarget(oPC);
    }
}

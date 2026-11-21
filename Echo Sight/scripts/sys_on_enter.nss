// sys_on_enter.nss — Echo Sight: module OnClientEnter — reapply persistent bonuses

#include "lib_esi"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    // Reapply all consumed echo bonuses (permanent effects lost on relog)
    EsiReapplyAllBonuses(oPC);

    int nCount = EsiGetAbsorbedCount(oPC);
    if(nCount > 0)
    {
        SendMessageToPC(oPC, "[Echo Sight] Twój Kodeks zawiera " + IntToString(nCount) + " wizji.");
    }
}

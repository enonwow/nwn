#include "lib_lycan"

// Creature OnPhysicalAttacked event — set on PC creatures via SetEventScript
// in sys_on_enter.nss or by the server administrator.
//
// Handles:
//   • Silver weapon bonus damage against transformed lycanthropes.

void main()
{
    object oTarget   = OBJECT_SELF;
    object oAttacker = GetLastAttacker(oTarget);

    if(!GetIsPC(oTarget) && !GetIsPC(oAttacker)) return;

    // Silver damage to transformed PCs
    if(GetIsPC(oTarget))
        LycanCheckSilverDamage(oTarget, oAttacker);
}

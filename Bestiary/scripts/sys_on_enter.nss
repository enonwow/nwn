// sys_on_enter.nss — OnClientEnter: reapply Bestiary combat bonuses
// Hook: Module Properties -> Events -> OnClientEnter
#include "lib_bst"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    // Re-examine SQL to determine earned tiers and (re)apply effects.
    // SupernaturalEffect survives resting but NOT logout, so we reapply here.
    int nTier2Count = 0;
    int nTier3Count = 0;
    int i;
    for(i = 0; i < BST_RACE_COUNT; i++)
    {
        int nTier = BstGetTier(BstGetKills(oPC, i));
        if(nTier >= 2) nTier2Count++;
        if(nTier >= 3) nTier3Count++;
    }

    if(nTier2Count > 0 || nTier3Count > 0)
        BstApplyBonuses(oPC);
}

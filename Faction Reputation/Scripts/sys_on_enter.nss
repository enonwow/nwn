// sys_on_enter.nss - Faction Reputation: OnClientEnter hook
//
// Wire-up: Module Properties -> Events -> OnClientEnter -> sys_on_enter
// Reapplies all passive faction effects so they survive server restart.

#include "lib_fac"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    // Small delay so the PC object is fully initialised before effects fire.
    DelayCommand(2.0, FacApplyAllEffects(oPC));
}

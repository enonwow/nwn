// sys_on_target.nss — Soul Crystals: module OnPlayerTarget hook.
// Forwards targeting events to the soul-binding handler only when
// the player is in soul-capture mode (SOC_LVAR_BINDING == 1).

#include "lib_soc"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if (!GetIsPC(oPC)) return;

    if (!GetLocalInt(oPC, SOC_LVAR_BINDING)) return;

    object oTarget = GetTargetingModeSelectedObject();
    SocOnPlayerTarget(oPC, oTarget);
}

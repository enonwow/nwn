// sys_on_enter.nss — module OnClientEnter hook for Elemental Attunement
#include "lib_eatt"

void main()
{
    object oPC = GetEnteringObject();
    if (!GetIsPC(oPC)) return;

    // Chain any existing OnDamaged script so other modules keep working
    string sExisting = GetEventScript(oPC, EVENT_SCRIPT_CREATURE_ON_DAMAGE);
    if (sExisting != "" && sExisting != "sys_on_damaged")
        SetLocalString(oPC, EATT_PREV_SCRIPT, sExisting);

    SetEventScript(oPC, EVENT_SCRIPT_CREATURE_ON_DAMAGE, "sys_on_damaged");

    // Restore persistent attunement effects after login
    EattRestoreEffects(oPC);
}

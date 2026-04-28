// hench_on_death.nss
// OnDeath for henchman - is_dead=1 flag + removes the object from the party.
// Resurrection via UI ("Resurrect (X gp)" button in the FireDead layout).
#include "lib_hench_def"

void main()
{
    object oPC = GetMaster(OBJECT_SELF);
    if(!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;

    HenchSetDeadFlag(GetObjectUUID(oPC), 1);
    DestroyHenchCmdWindow(oPC);
    SetLocalInt(oPC, HENCH_LVAR_SUPPRESS, 1);
    RemoveHenchman(oPC, OBJECT_SELF);
    AssignCommand(OBJECT_SELF, SetIsDestroyable(TRUE, TRUE, TRUE));
    DestroyObject(OBJECT_SELF, 2.0);  // delay so the player sees the death animation
}

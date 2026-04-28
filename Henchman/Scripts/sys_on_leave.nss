// sys_on_leave.nss
// OnClientLeave - persists the henchman on player disconnect
#include "lib_hench_def"

void main()
{
    object oPC = GetExitingObject();
    if(!GetIsPC(oPC)) return;

    HenchSave(oPC);
    DestroyHenchCmdWindow(oPC);

    object oHench = GetHenchman(oPC);
    if(GetIsObjectValid(oHench))
    {
        SetLocalInt(oPC, HENCH_LVAR_SUPPRESS, 1);
        RemoveHenchman(oPC, oHench);
        AssignCommand(oHench, SetIsDestroyable(TRUE, TRUE, TRUE));
        DestroyObject(oHench);
    }
}

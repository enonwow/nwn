#include "lib_duel"

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    if(!GetIsPC(oPC)) return;

    if(NuiFindWindow(oPC, DUEL_WINDOW) != 0
       || GetLocalInt(oPC, DUEL_LVAR_DRAFT_TARGET) == 0)
    {
        DuelOnPlayerTarget(oPC);
    }
}

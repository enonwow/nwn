#include "lib_fwnd"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    int nCount = FwndCountWounds(oPC);
    if(nCount > 0)
    {
        string sMsg = "[Rany] Masz " + IntToString(nCount)
                    + (nCount == 1 ? " aktywną ranę gnijącą." : " aktywnych ran gnijących.")
                    + " Szukaj leczenia.";
        FloatingTextStringOnCreature(sMsg, oPC, FALSE);
        SendMessageToPC(oPC, sMsg);
        DelayCommand(2.0, FwndApplyWoundEffects(oPC));
    }

    SetLocalInt(oPC, FWND_LVAR_LOOP_RUN, 1);
    DelayCommand(5.0, FwndPCLoop(oPC));
}

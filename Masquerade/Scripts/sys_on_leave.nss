#include "lib_msk"

void main()
{
    object oPC = GetExitingObject();
    if(!GetIsPC(oPC)) return;

    // Zdejmij maske przy wyjsciu — nie pozwalamy na logout z aktywna tożsamoscia
    if(MskIsActive(oPC))
    {
        SetPCNameOverride(oPC, "", OBJECT_INVALID, PC_NAME_OVERRIDE_TYPE_REPLACE_ALWAYS);
        DeleteLocalInt   (oPC, MSK_LVAR_ACTIVE_ID);
        DeleteLocalString(oPC, MSK_LVAR_ACTIVE_NAME);
        MskSetSuspicion  (oPC, 0);
        DeleteLocalInt   (oPC, MSK_LVAR_HB_DELAY);
    }
}

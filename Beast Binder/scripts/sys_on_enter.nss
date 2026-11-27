#include "lib_bb"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    // Passive bonding decay on each area entry
    BbDecayBonding(oPC);

    // Validate active beast: if the stored object died/is gone, clear the DB flag
    object oBeast = GetLocalObject(oPC, BB_LVAR_BEAST_OBJ);
    if(!GetIsObjectValid(oBeast))
    {
        int nActiveId = BbGetActiveBeastId(oPC);
        if(nActiveId > 0)
        {
            // Beast died or was lost between transitions; clear flag
            BbSetActive(nActiveId, FALSE);
            DeleteLocalObject(oPC, BB_LVAR_BEAST_OBJ);
            SendMessageToPC(oPC, "[Pêtacz] Twoja bestia zginêła lub zaginêła podczas wędrówki.");
        }
        return;
    }

    // Beast object is valid but moved to a different area — respawn in the new area
    if(GetArea(oBeast) != GetArea(oPC))
    {
        int nId = GetLocalInt(oBeast, "BB_ID");
        RemoveHenchman(oPC, oBeast);
        DestroyObject(oBeast);
        DeleteLocalObject(oPC, BB_LVAR_BEAST_OBJ);

        if(nId > 0)
        {
            // Delay respawn slightly so the area loads fully
            DelayCommand(1.5, BbActivateBeast(oPC, nId));
        }
    }
}

// tomb_use.nss — OnUsed script placed on every dynamically spawned tombstone placeable.
// SetEventScript(oStone, EVENT_SCRIPT_PLACEABLE_ON_USED, "tomb_use") is called
// inside TombSpawnStone() whenever a new stone is created.

#include "lib_tomb"

void main()
{
    object oPC  = GetLastUsedBy();
    object oSelf = OBJECT_SELF;

    if(!GetIsObjectValid(oPC) || !GetIsPC(oPC) || GetIsDM(oPC))
        return;

    int nId = GetLocalInt(oSelf, TOMB_LVAR_STONE_ID);
    if(nId <= 0)
    {
        SendMessageToPC(oPC, "[Epitafium] Napis na kamieniu jest zbyt zatarty, by go odczytać.");
        return;
    }

    TombCreateReadWindow(oPC, nId);
}

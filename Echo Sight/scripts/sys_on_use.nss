// sys_on_use.nss — Echo Sight: placeable OnUsed event for echo objects
// Assign this script to any placeable's OnUsed event to make it an echo anchor.
// The placeable must have its local variables set (see ESI_VAR_* constants in lib_esi_def.nss).
// Alternatively, set the placeable's tag to ESI_OBJ_TAG and dispatch from a global OnUsed router.

#include "lib_esi"

void main()
{
    object oPC      = GetLastUsedBy();
    object oEchoObj = OBJECT_SELF;

    if(!GetIsPC(oPC)) return;

    EsiHandleEchoUse(oPC, oEchoObj);
}

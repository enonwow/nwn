// hench_nwnx_rm.nss
// Handler for NWNX_ON_REMOVE_ASSOCIATE_AFTER.
// OBJECT_SELF = PC. Fires when the engine removes an associate (radial menu,
// "leave party" dialog, AddHenchman replacing one, etc.). Cleans up our SQL
// record and destroys the henchman object.
#include "lib_hench_def"
#include "nwnx_events"

void main()
{
    object oPC = OBJECT_SELF;
    if(!GetIsPC(oPC)) return;

    // Skip cleanup when the system initiates RemoveHenchman (logout, death, fire button, hire/load).
    if(GetLocalInt(oPC, HENCH_LVAR_SUPPRESS) == 1)
    {
        DeleteLocalInt(oPC, HENCH_LVAR_SUPPRESS);
        return;
    }

    object oAssoc = StringToObject(NWNX_Events_GetEventData("ASSOCIATE_OBJECT_ID"));
    if(!GetIsObjectValid(oAssoc)) return;

    string sPcUuid = GetObjectUUID(oPC);
    json jRec = HenchLoadRecord(sPcUuid);
    if(JsonGetType(jRec) == JSON_TYPE_NULL) return;

    // Verify the removed associate is actually our henchman (compare resref)
    string sStoredResRef = JsonGetString(JsonObjectGet(jRec, "resref"));
    if(GetResRef(oAssoc) != sStoredResRef) return;

    DestroyHenchCmdWindow(oPC);
    HenchDeleteRecord(sPcUuid);
    HenchCleanupCreature(oAssoc);
}

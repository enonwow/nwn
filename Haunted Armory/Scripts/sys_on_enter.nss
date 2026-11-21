#include "lib_haunt"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    // Re-apply bonuses for any haunted weapon the PC has equipped.
    // This handles logging back in while wielding a haunted item.
    object oWeap = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
    if(!GetIsObjectValid(oWeap))
        oWeap = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oPC);

    if(GetIsObjectValid(oWeap))
    {
        json jData = HauntGetWeaponData(GetObjectUUID(oWeap));
        if(JsonGetType(jData) != JSON_TYPE_NULL
        && JsonGetInt(JsonObjectGet(jData, "haunt_level")) >= 2)
        {
            HauntApplyEffects(oPC, oWeap);

            int nLevel = JsonGetInt(JsonObjectGet(jData, "haunt_level"));
            if(nLevel >= 3)
                SendMessageToPC(oPC, "[Oręże] Pieczęć krwi na twej broni ożywa...");
        }
    }
}

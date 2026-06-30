#include "lib_bs_def"

void main()
{
    object oPC   = GetPCItemLastEquippedBy();
    object oItem = GetPCItemLastEquipped();

    if(!GetIsPC(oPC) || !GetIsObjectValid(oItem)) return;

    // Only care about right-hand slot — spirits require active wielding
    if(GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC) != oItem) return;

    string sUUID   = GetObjectUUID(oItem);
    json   jSpirit = BsGetSpirit(sUUID);
    if(JsonGetType(jSpirit) == JSON_TYPE_NULL) return;

    int nKills = JsonGetInt(JsonObjectGet(jSpirit, "kill_count"));
    int nTier  = BsGetTier(nKills);
    int nClass = JsonGetInt(JsonObjectGet(jSpirit, "spirit_class"));

    BsApplyBonuses(oPC, sUUID, nClass, nTier, BsIsAppeased(jSpirit));

    string sSpiritName = JsonGetString(JsonObjectGet(jSpirit, "spirit_name"));
    string sWhisper    = BsGetWhisper(nClass, nTier, nKills);
    FloatingTextStringOnCreature(
        "\"" + sWhisper + "\" — " + sSpiritName, oPC, FALSE);
}

#include "sql_eff"

// Shared helper: apply persistent stat-drain effects for all active
// Wither/Torpor effigies targeting oPC.  Called from sys_on_enter
// and anywhere else that needs to re-establish the effects after
// they have been wiped (e.g. death / area transition).

void EffApplyEffectsToPC(object oPC)
{
    string sUuid  = GetObjectUUID(oPC);
    json jEffigies = EffGetEffigiesTargeting(sUuid);
    int nCount    = JsonGetLength(jEffigies);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow = JsonArrayGet(jEffigies, i);
        int nId   = JsonGetInt(JsonObjectGet(jRow, "id"));
        int nType = JsonGetInt(JsonObjectGet(jRow, "curse_type"));
        string sTag = "EFF_CURSE_" + IntToString(nId);

        if(nType == EFF_CURSE_WITHER || nType == EFF_CURSE_TORPOR)
        {
            // Check if already applied
            effect eCheck = GetFirstEffect(oPC);
            int bHasIt = FALSE;
            while(GetIsEffectValid(eCheck))
            {
                if(GetEffectTag(eCheck) == sTag)
                {
                    bHasIt = TRUE;
                    break;
                }
                eCheck = GetNextEffect(oPC);
            }
            if(!bHasIt)
            {
                effect eDrain;
                if(nType == EFF_CURSE_WITHER)
                {
                    eDrain = EffectAbilityDecrease(ABILITY_STRENGTH, 2);
                    eDrain = EffectLinkEffects(eDrain,
                        EffectAbilityDecrease(ABILITY_CONSTITUTION, 2));
                }
                else
                {
                    eDrain = EffectAbilityDecrease(ABILITY_DEXTERITY, 2);
                }
                eDrain = TagEffect(eDrain, sTag);
                ApplyEffectToObject(DURATION_TYPE_PERMANENT, eDrain, oPC);
            }
        }
    }
}

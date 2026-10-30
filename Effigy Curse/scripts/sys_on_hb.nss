#include "sql_eff"

// Module OnHeartbeat — fires every 6 seconds.
// Iterates all PCs, applies active effigy curse effects.

void ApplyCurseEffects(object oPC, int nEffigyId, int nCurseType)
{
    string sTag = "EFF_CURSE_" + IntToString(nEffigyId);

    switch(nCurseType)
    {
        case EFF_CURSE_ANGUISH:
        {
            int nDmg = 1 + Random(4);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectDamage(nDmg, DAMAGE_TYPE_NEGATIVE), oPC);
            if(Random(5) == 0)
            {
                FloatingTextStringOnCreature(
                    "Igły niewidzialnej bólu przeszywają twoje ciało…", oPC, FALSE);
            }
            break;
        }
        case EFF_CURSE_WITHER:
        {
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
                effect eDrain = EffectAbilityDecrease(ABILITY_STRENGTH, 2);
                eDrain = EffectLinkEffects(eDrain,
                    EffectAbilityDecrease(ABILITY_CONSTITUTION, 2));
                eDrain = TagEffect(eDrain, sTag);
                ApplyEffectToObject(DURATION_TYPE_PERMANENT, eDrain, oPC);
            }
            if(Random(8) == 0)
            {
                FloatingTextStringOnCreature(
                    "Mięśnie słabną, krew staje się chłodna jak ziemia…", oPC, FALSE);
            }
            break;
        }
        case EFF_CURSE_BLINDNESS:
        {
            if(Random(4) == 0)
            {
                ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                    EffectBlindness(), oPC, 4.0);
                FloatingTextStringOnCreature(
                    "Ciemność połyka twoje oczy…", oPC, FALSE);
            }
            break;
        }
        case EFF_CURSE_TORPOR:
        {
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
                effect eDrain = EffectAbilityDecrease(ABILITY_DEXTERITY, 2);
                eDrain = TagEffect(eDrain, sTag);
                ApplyEffectToObject(DURATION_TYPE_PERMANENT, eDrain, oPC);
            }
            if(Random(5) == 0)
            {
                ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                    EffectSlow(), oPC, 3.0);
                FloatingTextStringOnCreature(
                    "Kończyny stają się ciężkie niczym kamień…", oPC, FALSE);
            }
            break;
        }
    }
}

void main()
{
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(GetIsPC(oPC) && !GetIsDMPossessed(oPC))
        {
            json jEffigies = EffGetEffigiesTargeting(GetObjectUUID(oPC));
            int nCount = JsonGetLength(jEffigies);
            int i;
            for(i = 0; i < nCount; i++)
            {
                json jRow = JsonArrayGet(jEffigies, i);
                int nId   = JsonGetInt(JsonObjectGet(jRow, "id"));
                int nType = JsonGetInt(JsonObjectGet(jRow, "curse_type"));
                ApplyCurseEffects(oPC, nId, nType);
            }
        }
        oPC = GetNextPC();
    }
}

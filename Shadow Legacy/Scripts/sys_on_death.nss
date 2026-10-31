#include "lib_sleg"

// Placed on OnPlayerDeath module event.
// Also set SLEG_CURSED if the dying PC is under a relevant curse effect.
void main()
{
    object oPC = GetLastPlayerDied();
    if(!GetIsObjectValid(oPC)) return;

    // Detect curse effects — if any active curse, mark the legacy type
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        int nType = GetEffectType(eEff);
        if(nType == EFFECT_TYPE_CURSE || nType == EFFECT_TYPE_ABILITY_DECREASE)
        {
            SetLocalInt(oPC, SLEG_LVAR_CURSED, 1);
            break;
        }
        eEff = GetNextEffect(oPC);
    }

    SlegRecordDeath(oPC);
}

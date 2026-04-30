// test_fountain.nss
// OnUsed (placeable) - fountain of healing.
// Removes all temporary effects (buffs and debuffs) and heals to full HP.

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsObjectValid(oPC) || !GetIsPC(oPC)) return;
    if(GetIsDead(oPC)) return;

    // Strip all temporary effects (spells, item-procs, etc).
    // Permanent effects from worn items stay.
    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        if(GetEffectDurationType(e) == DURATION_TYPE_TEMPORARY)
            RemoveEffect(oPC, e);
        e = GetNextEffect(oPC);
    }

    // Heal to full.
    int nMissing = GetMaxHitPoints(oPC) - GetCurrentHitPoints(oPC);
    if(nMissing > 0)
        ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(nMissing), oPC);

    // Visual flair on the PC.
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_HEALING_M), oPC);

    SendMessageToPC(oPC,
        "The fountain's water washes over you. You feel renewed.");
}

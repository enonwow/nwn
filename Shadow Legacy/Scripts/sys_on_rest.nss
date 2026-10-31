#include "lib_sleg"

// OnPlayerRest (finished) — re-apply effects so TemporaryHitpoints refresh.
void main()
{
    object oPC = GetLastPCRested();
    if(!GetIsObjectValid(oPC)) return;
    SlegApplyEffects(oPC);
}

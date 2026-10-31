#include "lib_sleg"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    // Track unique areas visited for legacy type determination
    string sAreaTag = GetTag(GetArea(oPC));
    string sKey     = "SLEG_SEEN_" + sAreaTag;
    if(!GetLocalInt(oPC, sKey))
    {
        SetLocalInt(oPC, sKey, 1);
        SetLocalInt(oPC, SLEG_LVAR_AREAS, GetLocalInt(oPC, SLEG_LVAR_AREAS) + 1);
    }

    // Re-apply legacy effects (handles relog and rest recovery)
    SlegApplyEffects(oPC);

    // Notify if unclaimed legacies exist
    SlegCheckOnEnter(oPC);
}

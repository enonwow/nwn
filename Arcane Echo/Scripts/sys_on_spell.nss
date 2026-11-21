#include "lib_echo"

// Attach to: OnSpellCastAt (on area/all objects) or module OnSpellCast hook
// OBJECT_SELF is the spell target when used as OnSpellCastAt;
// adapt based on your module hook wiring (see INTEGRATION.md).
//
// If wiring via module OnSpellCast, OBJECT_SELF is the caster — pass
// GetSpellId() directly.  If via a placeable/area OnSpellCastAt,
// the caster is GetLastSpellCaster().

void main()
{
    object oCaster = GetLastSpellCaster();
    if(!GetIsObjectValid(oCaster)) return;
    // Filter: only record spells from PCs and major named NPCs
    if(!GetIsPC(oCaster) && GetChallengeRating(oCaster) < 1.0) return;

    int nSpellId = GetLastSpell();
    EchoOnSpellCast(oCaster, nSpellId);
}

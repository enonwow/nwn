#include "lib_tarot"

// Called from the module's OnClientEnter event.
// Re-applies all card effects the entering PC has already drawn,
// so effects survive relog without being stored in the character file.

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    TarotApplyAllDrawnEffects(oPC);
}

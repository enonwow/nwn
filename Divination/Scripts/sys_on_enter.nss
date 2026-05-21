#include "lib_div"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    DivEnsureRow(oPC);
    // Remove any stale DIV_ effects from the saved .bic, then reapply
    // whatever is still live in the DB — this is the single source of truth.
    DivReapplyPersistentEffects(oPC);
}

#include "lib_rf_def"

// OnPlayerTarget event hook.
// If this module shares the hook with others, call this from the central dispatcher
// and guard with RF_LVAR_TARGETING so only active forge selections are processed.

void main()
{
    object oPC = GetLastPlayerToSelectTarget();
    RFOnPlayerTarget(oPC);
}

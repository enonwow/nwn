#include "lib_plg"

// OnUsed handler for the "Zwierciadło Diagnostyczne" (Diagnostic Mirror) placeable.
// Opens the test/debug window so QA can contract any disease and check the status UI.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    CreatePlgTestWindow(oPC);
}

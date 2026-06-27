#include "lib_sea"

// Assign as the OnUsed script of a placeable (e.g. a weather vane or stone pillar).
// DMs receive the full control panel; players receive the read-only weather report.
void main()
{
    object oPC = GetLastUsedBy();
    if (!GetIsPC(oPC) && !GetIsDM(oPC)) return;
    SeaOpenWindow(oPC);
}

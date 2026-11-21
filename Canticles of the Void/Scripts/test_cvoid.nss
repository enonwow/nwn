// test_cvoid.nss
// Place on an "Otchlaniony Oltarz" placeable (tag: void_altar) as OnUsed script.
// Also requires NUI event script = "lib_cvoid_ev" on the module.

#include "lib_cvoid"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    CvoidOpenWindow(oPC);
}

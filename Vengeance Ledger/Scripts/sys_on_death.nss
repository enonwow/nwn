#include "lib_vend"

void main()
{
    object oPC = OBJECT_SELF;
    if (!GetIsPC(oPC)) return;

    object oKiller = GetLastKiller();
    if (!GetIsObjectValid(oKiller)) return;
    if (!GetIsPC(oKiller))         return;
    if (oKiller == oPC)            return;   // suicide: no grudge

    // The dead PC earns a grudge against their killer
    VendAddGrudge(oPC, oKiller, VEND_WRONG_KILLED, "");

    // If the killer had an active grudge against the victim,
    // this kill fulfills it — vengeance answered with vengeance
    VendCheckFulfillment(oKiller, oPC);
}

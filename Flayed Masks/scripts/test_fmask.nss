#include "lib_fmask"

// OnUsed script for a placeable (e.g. "Grimuar Oblicz").
// Open the Flayed Masks window for the activating PC.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    CreateFmaskWindow(oPC);
}

#include "lib_stn"

// OnUsed script for the Stance Trainer / stance-selection placeable.
// Place this on any placeable to let PCs open the Stance Book.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    StnRegisterPlayer(oPC);
    CreateStanceWindow(oPC);
    CreateStanceWidget(oPC);
}

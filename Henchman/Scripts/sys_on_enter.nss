// sys_on_enter.nss
// OnClientEnter - loads the player's henchman
#include "lib_hench_def"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;
    DelayCommand(1.0, HenchLoad(oPC));
}

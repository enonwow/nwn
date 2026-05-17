// sys_on_enter.nss
// Module OnClientEnter — initialise per-PC recipe table and grant starter recipes.
#include "lib_alch_def"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    AlchInitTables(oPC);
    AlchGrantStarterRecipes(oPC);
}

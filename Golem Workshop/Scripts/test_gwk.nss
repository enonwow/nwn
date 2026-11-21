// OnUsed script for the Warsztat Golemisty placeable.
// Attach to any placeable (e.g. a forge or ritual altar) to open the workshop.
#include "lib_gwk"

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC))
    {
        SendMessageToPC(GetFirstPC(), "[Warsztat] test_gwk: no PC user");
        return;
    }
    GwkOpenWorkshop(oPC);
}

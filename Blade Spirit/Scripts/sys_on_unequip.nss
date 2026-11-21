#include "lib_bs_def"

void main()
{
    object oPC   = GetPCItemLastUnequippedBy();
    object oItem = GetPCItemLastUnequipped();

    if(!GetIsPC(oPC) || !GetIsObjectValid(oItem)) return;

    BsRemoveBonuses(oPC, GetObjectUUID(oItem));
}

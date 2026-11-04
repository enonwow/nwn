#include "lib_mmori"

void main()
{
    object oPC    = GetLastUsedBy();
    object oCairn = OBJECT_SELF;
    if(!GetIsPC(oPC)) return;
    MmoriOnCairnUsed(oPC, oCairn);
}

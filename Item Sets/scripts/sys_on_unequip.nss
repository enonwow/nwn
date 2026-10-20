#include "lib_sets"

// Module OnUnEquipItem – re-evaluate all set bonuses for the unequipping PC.
void main()
{
    object oPC = GetPCItemLastUnequippedBy();
    if(!GetIsPC(oPC)) return;

    SetsUpdateAll(oPC);

    object oItem = GetPCItemLastUnequipped();
    if(!GetIsObjectValid(oItem)) return;

    string sTag = GetTag(oItem);
    int i;
    for(i = 0; i < SETS_TOTAL; i++)
    {
        string sTags = SetsGetItemTags(i);
        int nTotal   = SetsGetItemCount(i);
        int j;
        for(j = 0; j < nTotal; j++)
        {
            if(SetsGetToken(sTags, j) != sTag) continue;

            int nCount = SetsGetEquippedCount(oPC, i);
            if(nCount >= 2)
                SendMessageToPC(oPC,
                    "[Zestawy] " + SetsGetName(i) + ": " + IntToString(nCount) +
                    "/" + IntToString(nTotal) + " elementów aktywnych.");
            else if(nCount == 1)
                SendMessageToPC(oPC,
                    "[Zestawy] " + SetsGetName(i) + " — premia utracona.");
            return;
        }
    }
}

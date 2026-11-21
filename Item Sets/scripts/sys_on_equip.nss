#include "lib_sets"

// Module OnEquipItem – re-evaluate all set bonuses for the equipping PC.
void main()
{
    object oPC = GetPCItemLastEquippedBy();
    if(!GetIsPC(oPC)) return;

    SetsUpdateAll(oPC);

    // Notify the player if a new bonus threshold was just reached
    object oItem = GetPCItemLastEquipped();
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

            // This item belongs to set i
            int nCount = SetsGetEquippedCount(oPC, i);
            string sBonus = "";
            int k;
            for(k = 0; k < 3; k++)
            {
                int nThresh = SetsGetBonusTierThreshold(i, k);
                if(nThresh == 0) break;
                if(nCount == nThresh)
                {
                    sBonus = SetsGetBonusAtTier(i, k);
                    break;
                }
            }
            if(sBonus != "")
                SendMessageToPC(oPC,
                    "[Zestawy] " + SetsGetName(i) + " — nowy bonus odblokowany: " + sBonus);
            else if(nCount >= 2)
                SendMessageToPC(oPC,
                    "[Zestawy] " + SetsGetName(i) + ": " + IntToString(nCount) +
                    "/" + IntToString(nTotal) + " elementów.");
            return;
        }
    }
}

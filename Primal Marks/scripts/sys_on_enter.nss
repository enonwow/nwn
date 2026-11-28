#include "lib_mrk"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    MrkEnsureData(oPC);
    MrkReapplyBrands(oPC);

    int nBrands = MrkGetBrands(oPC);
    if(nBrands > 0)
    {
        int nCount = 0;
        int i;
        for(i = 0; i < MRK_TYPE_COUNT; i++)
        {
            if(nBrands & (1 << i)) nCount++;
        }
        string sMsg = "[Piętna] Nosisz " + IntToString(nCount) + " trwał";
        if(nCount == 1) sMsg = sMsg + "e piętno.";
        else            sMsg = sMsg + "e piętna.";
        SendMessageToPC(oPC, sMsg);
    }
}

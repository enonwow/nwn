#include "lib_ins_def"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    // Run expiry cleanup once per enter to keep the DB lean
    InsExpireOld();

    // Notify the player if there's a stone tablet in this area
    object oTablet = GetNearestObjectByTag("ins_tablet", oPC, 1);
    if(!GetIsObjectValid(oTablet))
        oTablet = GetNearestObjectByTag("INS_TABLET", oPC, 1);

    if(GetIsObjectValid(oTablet) && GetArea(oTablet) == GetArea(oPC))
    {
        int nCount = InsGetCount(GetTag(oTablet));
        string sMsg = nCount > 0
            ? "[Glos Kamienia] Widzisz Kamienna Tablice. Zawiera " +
              IntToString(nCount) + " inskrypcj" +
              (nCount == 1 ? "e" : (nCount < 5 ? "e" : "i")) + "."
            : "[Glos Kamienia] Widzisz Kamienna Tablice. Jeszcze nikt tu nie pisał.";
        DelayCommand(2.0, SendMessageToPC(oPC, sMsg));
    }
}

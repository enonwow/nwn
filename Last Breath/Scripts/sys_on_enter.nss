#include "lib_lbr_def"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    // Purge decayed essences silently on each login
    LbrClearDecayed(oPC);

    int nCount = LbrGetEssenceCount(oPC);
    if(nCount > 0)
        SendMessageToPC(oPC,
            "[Ostatnie Tchnienie] Przechowujesz " + IntToString(nCount) + " fiolkę(-i) tchnień.");
}

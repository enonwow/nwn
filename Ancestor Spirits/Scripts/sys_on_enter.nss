// sys_on_enter.nss — Ancestor Spirits: OnClientEnter hook
#include "lib_anc_def"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    AncRegisterPC(oPC);

    int nLineage = AncGetLineage(oPC);
    if(nLineage == ANC_LINEAGE_NONE)
        return;

    int nFavor = AncGetFavor(oPC);
    SendMessageToPC(oPC,
        "[Przodkowie] Rod: " + AncGetLineageName(nLineage)
        + "  |  Laska: " + IntToString(nFavor) + "/" + IntToString(ANC_FAVOR_MAX));
}

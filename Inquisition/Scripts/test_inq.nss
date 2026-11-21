// test_inq.nss - OnUsed placeable: demonstrates Inquisition system.
// Place a "Tablica Inkwizycji" placeable in the module with this script as OnUsed.
// - Regular PCs: opens their personal dossier.
// - DMs: opens the DM management panel.
// - Console command variant: add "inq_charge <act_id>" as a local var on PC to test charge injection.

#include "lib_inq"

void main()
{
    object oUser = GetLastUsedBy();
    if(!GetIsObjectValid(oUser)) return;

    if(GetIsDM(oUser) || GetIsDMPossessed(oUser))
    {
        InqOpenDmWindow(oUser);
        return;
    }

    if(GetIsPC(oUser))
    {
        // Check for debug charge injection via local variable "inq_test_act"
        int nTestAct = GetLocalInt(oUser, "inq_test_act");
        if(nTestAct >= 0 && nTestAct < INQ_ACT_COUNT)
        {
            DeleteLocalInt(oUser, "inq_test_act");
            InqAddCharge(oUser, nTestAct);
            SendMessageToPC(oUser, "[INQ TEST] Dodano zarzut: " + InqGetActName(nTestAct));
        }

        InqOpenDossierWindow(oUser);
    }
}

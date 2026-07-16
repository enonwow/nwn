#include "lib_chim"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    // Reapply graft effects in case the server restarted since the last login.
    ChimReapplyEffects(oPC);

    json jAll  = ChimGetAllGrafts(GetObjectUUID(oPC));
    int nCount = JsonGetLength(jAll);
    if(nCount > 0)
    {
        string sMsg = "[Chimeryzacja] " + IntToString(nCount)
            + " przeszczep(y) aktywne. Pieczęć krwi pulsuje słabo...";
        DelayCommand(2.0f, SendMessageToPC(oPC, sMsg));
    }
}

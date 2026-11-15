#include "lib_mac"

// OnUsed: set on a placeable tagged "test_danse_macabre".
// Using it cycles through: open window, add +20 proximity, trigger bargain.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    int nProx = MacGetProximity(oPC);
    string sCmd = GetLocalString(OBJECT_SELF, "mac_test_cmd");

    if(sCmd == "add")
    {
        int nOld = nProx;
        MacAddProximity(oPC, 20);
        int nNew = MacGetProximity(oPC);
        MacApplyProximityEffects(oPC, nOld, nNew);
        MacSendOmen(oPC, nNew);
        SendMessageToPC(oPC,
            "[TEST] Bliskosc +20 -> " + IntToString(nNew) + "/100");
    }
    else if(sCmd == "reset")
    {
        int nOld = nProx;
        MacSetProximity(oPC, 0);
        MacApplyProximityEffects(oPC, nOld, 0);
        SendMessageToPC(oPC, "[TEST] Bliskosc zresetowana do 0.");
    }
    else if(sCmd == "max")
    {
        int nOld = nProx;
        MacSetProximity(oPC, 100);
        MacApplyProximityEffects(oPC, nOld, 100);
        SendMessageToPC(oPC, "[TEST] Bliskosc ustawiona na 100 — bargain za chwile.");
        DelayCommand(2.0, MacOpenWindow(oPC));
    }
    else
    {
        // Default: open the window
        MacOpenWindow(oPC);
    }
}

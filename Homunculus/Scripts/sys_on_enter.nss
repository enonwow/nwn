// sys_on_enter.nss — runs on ClientEnter; restores VFX presence and checks maintenance
#include "lib_hom"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    HomCheckMaintenance(oPC);

    if(HomExists(oPC))
    {
        // Small delay to let the client finish loading before we apply effects.
        DelayCommand(3.0, HomApplyPresenceVFX(oPC));

        int nBond = HomGetBondLevel(oPC);
        string sName = JsonGetString(JsonObjectGet(HomGetData(oPC), "name"));
        string sMsg  = "[Homunkulus] " + sName + " czeka na ciebie. Więź: "
                     + IntToString(nBond) + " / 10  •  " + HomTierName(nBond) + ".";
        DelayCommand(4.0, SendMessageToPC(oPC, sMsg));

        int nSecsFed = HomSecondsSinceFed(oPC);
        if(nSecsFed >= HOM_FEED_INTERVAL)
        {
            DelayCommand(5.0, SendMessageToPC(oPC,
                "[Homunkulus] Homunkulus jest głodny! Nakarm go, zanim więź osłabnie."));
            DelayCommand(5.0, FloatingTextStringOnCreature(
                "Homunkulus jest głodny!", oPC, FALSE));
        }
    }
}

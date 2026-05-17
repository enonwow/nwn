// sys_on_enter.nss — Soul Crystals: module OnClientEnter hook.
// Registers the player in the soul tracking table and notifies
// them if they have stored crystals waiting to be used.

#include "lib_soc"

void main()
{
    object oPC = GetEnteringObject();
    if (!GetIsPC(oPC)) return;

    SocRegisterPlayer(oPC);

    int nCount = SocGetCrystalCount(oPC);
    if (nCount > 0)
    {
        string sMsg = "[Kryształy Dusz] Posiadasz " + IntToString(nCount)
            + " schwytanych dusz. Odwiedź Kuźnię Dusz, by je wykorzystać.";
        DelayCommand(3.0, SendMessageToPC(oPC, sMsg));
    }
}

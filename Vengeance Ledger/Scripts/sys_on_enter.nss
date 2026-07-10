#include "lib_vend"

void main()
{
    object oPC = GetEnteringObject();
    if (!GetIsPC(oPC)) return;

    VendRegisterPlayer(oPC);
    ApplyVendEffects(oPC);

    int nActive  = VendGetActiveCount(oPC);
    if (nActive <= 0) return;

    int nOverdue = VendGetOverdueCount(oPC);
    int nFury    = nActive  < VEND_MAX_FURY  ? nActive  : VEND_MAX_FURY;
    int nResent  = nOverdue < VEND_MAX_RESENT ? nOverdue : VEND_MAX_RESENT;

    string sMsg = "[Księga Krzywd] Masz " + IntToString(nActive) + " aktywnych wpisów w Księdze. "
        + "Furia: +" + IntToString(nFury) + " AB/OBR";
    if (nResent > 0)
        sMsg = sMsg + ", Żal: -" + IntToString(nResent) + " PP";
    sMsg = sMsg + ".";

    SendMessageToPC(oPC, sMsg);
    if (nOverdue > 0)
        SendMessageToPC(oPC,
            "[Księga Krzywd] " + IntToString(nOverdue) +
            " wpisów przekroczyło termin — Pieczęć krwi pulsuje słabo, żal cię pochłania.");
    FloatingTextStringOnCreature("Krew woła o zemstę...", oPC, FALSE);
}

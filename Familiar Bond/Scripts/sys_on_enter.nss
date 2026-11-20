#include "lib_fam"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    // Restore mourning debuff if the player logs back in mid-mourning
    FamRestoreEffects(oPC);

    // Notify player about their familiar state
    if(!FamExists(oPC)) return;

    json jFam = FamGet(oPC);
    int nMournUntil = JsonGetInt(JsonObjectGet(jFam, "mourning_until"));

    if(nMournUntil > 0 && FamNowUnix() < nMournUntil)
    {
        int nLeft = nMournUntil - FamNowUnix();
        SendMessageToPC(oPC, "[Znamię] Nadal jesteś w żałobie po utracie towarzysza. "
            "Pozostało " + IntToString(nLeft / 3600) + " godzin.");
        return;
    }

    int nType = JsonGetInt(JsonObjectGet(jFam, "fam_type"));
    int bDismissed = JsonGetInt(JsonObjectGet(jFam, "dismissed"));
    int nVigilUntil = JsonGetInt(JsonObjectGet(jFam, "vigil_until"));
    int nNow = FamNowUnix();

    string sMsg = "[Znamię] " + FamTypeName(nType);
    if(bDismissed)
        sMsg += " odpoczywa z dala.";
    else if(nVigilUntil > 0 && nNow < nVigilUntil)
        sMsg += " czuwa w pobliżu.";
    else
        sMsg += " jest przy tobie.";

    SendMessageToPC(oPC, sMsg);
}

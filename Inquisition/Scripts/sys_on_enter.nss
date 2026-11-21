// sys_on_enter.nss - Inquisition: ClientEnter hook
// Restores rating effects and registers PC name on login.

#include "lib_inq"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    string sPcUuid = GetObjectUUID(oPC);
    string sPcName = GetName(oPC);

    // Keep name current in DB (handles renames)
    InqUpsertPcName(sPcUuid, sPcName);

    int nRating = InqGetRating(sPcUuid);
    if(nRating > 0)
    {
        // Re-apply effects after server restart
        DelayCommand(3.0, InqApplyRatingEffects(oPC, nRating));

        if(nRating >= INQ_THRESHOLD_CONDEMNED)
            DelayCommand(4.0, SendMessageToPC(oPC,
                "[Inkwizycja] Jesteś wyklęty. Inkwizycja aktywnie poluje na ciebie."));
        else if(nRating >= INQ_THRESHOLD_CONVICTED)
            DelayCommand(4.0, SendMessageToPC(oPC,
                "[Inkwizycja] Pieczęć heretyka nadal cię napiętnowuje."));
        else if(nRating >= INQ_THRESHOLD_ACCUSED)
            DelayCommand(4.0, SendMessageToPC(oPC,
                "[Inkwizycja] Nakaz aresztowania wciąż jest aktywny."));
        else
            DelayCommand(4.0, SendMessageToPC(oPC,
                "[Inkwizycja] Inkwizycja ma cię na oku."));
    }
}

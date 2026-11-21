#include "lib_grv"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    GrvRegisterPlayer(oPC);

    int nMarks = GrvGetDesecMarks(oPC);
    int nGrace = GrvGetBoneGrace(oPC);

    if(nMarks >= GRV_DESEC_CURSE_THRESHOLD)
    {
        // Re-apply curse on login (curses are permanent until cleansed)
        DelayCommand(3.0, GrvApplyCursePenalties(oPC, nMarks));

        string sWarn = nMarks >= GRV_DESEC_HEAVY_THRESHOLD
            ? "[Cmentarz] Ciężka klątwa zbezczeszczenia spoczywa na tobie. Poszukaj grabarza, by cię rozgrzeszył."
            : "[Cmentarz] Cień zbezczeszczenia spoczywa na tobie (" + IntToString(nMarks) + " Piętno). Odwiedź grabarza.";
        DelayCommand(4.0, SendMessageToPC(oPC, sWarn));
        DelayCommand(4.0, FloatingTextStringOnCreature(sWarn, oPC, FALSE));
    }

    if(nGrace > 0)
    {
        string sNotify = "[Cmentarz] Posiadasz " + IntToString(nGrace) + " Łaski Kości. Skorzystaj ze Sklepu Grabarza.";
        DelayCommand(5.0, SendMessageToPC(oPC, sNotify));
    }
}

#include "lib_herb_def"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    // Herb knowledge is accumulated on first harvest of each type;
    // no player registration needed. Trigger node regen lazily on open.
    int nKnown = JsonGetLength(HerbPlayerGetAll(oPC));
    if(nKnown > 0)
        SendMessageToPC(oPC,
            "[Zielarz] Twoja sakwa zawiera " + IntToString(nKnown)
            + " rodzaj(ów) ziół. Otwórz Dziennik Zielarza, aby sprawdzić zasoby.");
}

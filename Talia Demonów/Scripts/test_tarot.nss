#include "lib_tarot"

// OnUsed script for a placeable named "Zapieczętowana Talia Demonów".
// Drop a placeable in the toolset, set this as its OnUsed script.
// The placeable acts as the access point to the Infernal Tarot system.

void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC))
    {
        SendMessageToPC(oPC, "[Talia] Tylko istoty z duszą mogą sięgnąć po karty przeznaczenia.");
        return;
    }

    int nDrawn = TarotGetDrawnCount(oPC);

    // Opening flavor message on first use
    if(nDrawn == 0)
    {
        SendMessageToPC(oPC,
            "[Talia] Pudełko jest zimne w dotyku. Karty wewnątrz szepczą imiona, "
            "których jeszcze nie znacie. Czy jesteś gotów poznać swój los?");
        SendMessageToPC(oPC,
            "[Talia] Każda wylosowana karta zostawi na tobie trwały ślad — "
            "premię do twoich zdolności i ciężar, który będziesz dźwigał.");
    }

    TarotOpenWindow(oPC);
}

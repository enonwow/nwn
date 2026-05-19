#include "lib_poi"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    int nVials = 0;
    int i;
    for(i = 0; i < POI_VIAL_COUNT; i++)
        nVials += PoiGetStock(oPC, POI_POISON_OFFSET + i);

    if(nVials > 0)
        SendMessageToPC(oPC, "[Trucizny] Masz " + IntToString(nVials)
                        + " fiol(ki) trucizn w zasobach. Użyj stołu alchemicznego.");
}

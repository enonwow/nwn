// sys_on_use.nss — Blood Altar: OnUsed placeabla oltarza
// Ustaw ten skrypt jako OnUsed na obiektach z tagami ALTAR_BLOOD/BONE/EARTH/SHADOW
#include "lib_balt"

void main()
{
    object oPC    = GetLastUsedBy();
    object oAltar = OBJECT_SELF;

    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    string sTag = GetTag(oAltar);
    if(sTag != BALT_TAG_BLOOD  && sTag != BALT_TAG_BONE &&
       sTag != BALT_TAG_EARTH  && sTag != BALT_TAG_SHADOW)
    {
        SendMessageToPC(oPC, "[Oltarz] Ten oltarz nie jest skonfigurowany (nieprawidlowy tag).");
        return;
    }

    BaltOpenWindow(oPC, sTag);
}

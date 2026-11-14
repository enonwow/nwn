#include "lib_intr_def"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;

    // Count live prisoners in this area and notify the PC
    object oArea = GetArea(oPC);
    object oObj  = GetFirstObjectInArea(oArea);
    int    nCount = 0;

    while(GetIsObjectValid(oObj))
    {
        if(   GetObjectType(oObj) == OBJECT_TYPE_CREATURE
           && GetLocalInt(oObj, "INTR_IS_PRISONER")
           && !GetIsDead(oObj))
            nCount++;

        oObj = GetNextObjectInArea(oArea);
    }

    if(nCount > 0)
        SendMessageToPC(oPC,
            "[Przesluchanie] W tej okolicy przebywa "
            + IntToString(nCount)
            + " wiezien/wiezniow gotowych do przesluchania.");
}

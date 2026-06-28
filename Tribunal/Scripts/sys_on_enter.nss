#include "lib_trib_def"

void main()
{
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC) || GetIsDMPossessed(oPC)) return;

    TribRegisterPlayer(oPC);

    int nOpen = TribGetOpenCaseCountFor(GetObjectUUID(oPC));
    if(nOpen > 0)
        SendMessageToPC(oPC,
            "[Trybunał] Inkwizycja czeka. Masz " + IntToString(nOpen)
            + " otwartą sprawę sądową przeciwko tobie.");
}

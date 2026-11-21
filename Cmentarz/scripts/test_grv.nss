#include "lib_grv"

// OnUsed script for the "Cmentarny Głaz" (Graveyard Stone) placeable.
// Place this placeable in your area and assign this script to its OnUsed event.
// A second placeable with tag "GRV_TEST_GRAVE" and a local int "GRV_GRAVE_ID" set
// to a valid grave ID can be used to test the grave interaction window.

void main()
{
    object oPC   = GetLastUsedBy();
    object oSelf = OBJECT_SELF;

    if(!GetIsPC(oPC)) return;

    string sTag = GetTag(oSelf);

    if(sTag == "GRV_TEST_GRAVE")
    {
        int nId = GetLocalInt(oSelf, "GRV_GRAVE_ID");
        if(nId <= 0)
        {
            SendMessageToPC(oPC, "[Cmentarz] Ten grób nie ma rekordu w bazie.");
            return;
        }
        GrvCreateGraveWindow(oPC, nId);
    }
    else
    {
        GrvCreateBurialWindow(oPC);
    }
}

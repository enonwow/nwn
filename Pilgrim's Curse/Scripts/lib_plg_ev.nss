#include "lib_plg"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    // ---- Shrine info popup ----
    if(nToken == NuiFindWindow(oPC, PLG_WIN_SHRINE_INFO))
    {
        if(sEvent == EVENT_TYPE_CLICK && sElem == PLG_BTN_SINFO_CLOSE)
            NuiDestroy(oPC, nToken);
        return;
    }

    // ---- Main window ----
    if(nToken != NuiFindWindow(oPC, PLG_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, PLG_LVAR_TAB);
        DeleteLocalInt(oPC, PLG_LVAR_SEL_SHRINE);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == PLG_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == PLG_BTN_TAB_STATUS)
        {
            PlgSwapTab(oPC, nToken, 0);
            return;
        }

        if(sElem == PLG_BTN_TAB_SHRINES)
        {
            PlgSwapTab(oPC, nToken, 1);
            return;
        }

        if(sElem == PLG_BTN_TAB_BOARD)
        {
            PlgSwapTab(oPC, nToken, 2);
            return;
        }

        // Catharsis button — requires being near the catharsis placeable.
        if(sElem == PLG_BTN_CATHARSIS)
        {
            object oAltar = GetNearestObjectByTag(PLG_CATHARSIS_TAG, oPC);
            if(!GetIsObjectValid(oAltar) || GetDistanceBetween(oPC, oAltar) > 5.0)
            {
                SendMessageToPC(oPC, "[Pielgrzymka] Musisz stać przy Ołtarzu Pokuty, "
                    "by dokonać Katharsis.");
                return;
            }
            PlgHandleShrine(oPC, oAltar);
            return;
        }
    }

    // Shrine row click — show info popup for the clicked shrine.
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == PLG_BTN_SHRINE_ROW)
    {
        json jShrines = PlgGetAllShrines(oPC);
        if(nIdx < 0 || nIdx >= JsonGetLength(jShrines)) return;

        json jS      = JsonArrayGet(jShrines, nIdx);
        int nId      = JsonGetInt(JsonObjectGet(jS, "id"));
        int nVisited = JsonGetInt(JsonObjectGet(jS, "visited"));

        SetLocalInt(oPC, PLG_LVAR_SEL_SHRINE, nId);

        // Highlight selected row.
        int nCount = JsonGetLength(jShrines);
        json jEncs = JsonArray();
        int i;
        for(i = 0; i < nCount; i++)
            jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
        NuiSetBind(oPC, nToken, PLG_BIND_SHRINE_ENC, jEncs);

        PlgShowShrinePopup(oPC, nId, nVisited);
        return;
    }
}

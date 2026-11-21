#include "lib_bfire"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, BFIRE_WINDOW)) return;

    // ---- Window close ----
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalString(oPC, BFIRE_LVAR_TAG);
        DeleteLocalJson(oPC, BFIRE_LVAR_TRAV_LIST);
        return;
    }

    // ---- Watch: new message input → update Post button state ----
    if(sEvent == EVENT_TYPE_WATCH && sElem == BFIRE_BIND_NEW_MSG)
    {
        string sText = JsonGetString(NuiGetBind(oPC, nToken, BFIRE_BIND_NEW_MSG));
        NuiSetBind(oPC, nToken, BFIRE_BIND_POST_ENA, JsonBool(sText != ""));
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        // ---- Main view buttons ----
        if(sElem == BFIRE_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == BFIRE_BTN_REST)
        {
            BfireDoRest(oPC, nToken);
            return;
        }

        if(sElem == BFIRE_BTN_FLASK)
        {
            BfireDoUseFlask(oPC, nToken);
            return;
        }

        if(sElem == BFIRE_BTN_TRAVEL)
        {
            BfireSwapToTravel(oPC, nToken);
            return;
        }

        if(sElem == BFIRE_BTN_MESSAGES)
        {
            BfireSwapToMessages(oPC, nToken);
            return;
        }

        if(sElem == BFIRE_BTN_KINDLE)
        {
            BfireDoKindle(oPC, nToken);
            return;
        }

        // ---- Shared back button ----
        if(sElem == BFIRE_BTN_BACK)
        {
            BfireSwapToMain(oPC, nToken);
            return;
        }

        // ---- Messages view: post ----
        if(sElem == BFIRE_BTN_POST)
        {
            string sText = JsonGetString(NuiGetBind(oPC, nToken, BFIRE_BIND_NEW_MSG));
            if(sText == "") return;

            string sTag = BfireGetTag(oPC);
            BfireAddMessage(sTag, GetName(oPC), sText);

            NuiSetBind(oPC, nToken, BFIRE_BIND_NEW_MSG, JsonString(""));
            NuiSetBind(oPC, nToken, BFIRE_BIND_POST_ENA, JsonBool(FALSE));

            BfireFeedMessages(oPC, nToken);

            SendMessageToPC(oPC,
                "[Ognisko] Twoje słowa zostają przy ognisku, jak echa poległych...");
            return;
        }
    }

    // ---- Travel row click ----
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == BFIRE_BTN_TRAV_ROW)
    {
        BfireDoTravel(oPC, nToken, nIdx);
        return;
    }
}

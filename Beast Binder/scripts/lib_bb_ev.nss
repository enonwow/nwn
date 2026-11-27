#include "lib_bb"

// ----------------------------------------------------------------
// Main NUI event handler (set as script on NuiCreate)
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, BB_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, BB_LVAR_SEL_ID);
        DeleteLocalInt(oPC, BB_LVAR_CAPTURING);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == BB_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == BB_BTN_CAPTURE)
        {
            BbCaptureMode(oPC);
            return;
        }

        if(sElem == BB_BTN_ACTIVATE)
        {
            int nId = GetLocalInt(oPC, BB_LVAR_SEL_ID);
            if(nId <= 0)
            {
                SendMessageToPC(oPC, "[Pêtacz] Wybierz bestiê z listy.");
                return;
            }
            BbActivateBeast(oPC, nId);
            BbFeedBeastList(oPC, nToken);
            BbFeedBeastDetails(oPC, nToken, nId);
            return;
        }

        if(sElem == BB_BTN_DISMISS)
        {
            int nId = GetLocalInt(oPC, BB_LVAR_SEL_ID);
            BbDismissBeast(oPC);
            BbFeedBeastList(oPC, nToken);
            BbFeedBeastDetails(oPC, nToken, nId);
            return;
        }

        if(sElem == BB_BTN_FEED)
        {
            int nId = GetLocalInt(oPC, BB_LVAR_SEL_ID);
            if(nId <= 0)
            {
                SendMessageToPC(oPC, "[Pêtacz] Wybierz bestiê z listy.");
                return;
            }
            BbFeedBeast(oPC, nId);
            BbFeedBeastList(oPC, nToken);
            BbFeedBeastDetails(oPC, nToken, nId);
            return;
        }

        if(sElem == BB_BTN_RELEASE)
        {
            int nId = GetLocalInt(oPC, BB_LVAR_SEL_ID);
            if(nId <= 0) return;

            json jB = BbGetBeast(nId);
            if(JsonGetType(jB) == JSON_TYPE_NULL) return;

            int bActive = JsonGetInt(JsonObjectGet(jB, "is_active"));
            if(bActive)
            {
                SendMessageToPC(oPC, "[Pêtacz] Odwołaj bestiê przed jej uwolnieniem.");
                return;
            }
            BbDoRelease(oPC, nId);
            BbFeedBeastList(oPC, nToken);
            BbFeedBeastDetails(oPC, nToken, 0);
            return;
        }
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == BB_BTN_ROW)
    {
        json jBeasts = BbGetBeasts(oPC);
        if(nIdx < 0 || nIdx >= JsonGetLength(jBeasts)) return;

        json jE   = JsonArrayGet(jBeasts, nIdx);
        int  nId  = JsonGetInt(JsonObjectGet(jE, "id"));

        SetLocalInt(oPC, BB_LVAR_SEL_ID, nId);

        // Refresh enc highlighting
        int nCount = JsonGetLength(jBeasts);
        json jEncs = JsonArray();
        int i;
        for(i = 0; i < nCount; i++)
            jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
        NuiSetBind(oPC, nToken, BB_BIND_ROW_ENC, jEncs);

        BbFeedBeastDetails(oPC, nToken, nId);
        return;
    }
}

#include "lib_scry"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    // ---- Attune popup ----
    if(nToken == NuiFindWindow(oPC, SCRY_WIN_ATTUNE))
    {
        if(sEvent == EVENT_TYPE_WATCH && sElem == SCRY_BIND_ATT_NAME)
        {
            string sName = JsonGetString(NuiGetBind(oPC, nToken, SCRY_BIND_ATT_NAME));
            NuiSetBind(oPC, nToken, SCRY_BIND_ATT_SAVE, JsonBool(sName != ""));
            return;
        }
        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == SCRY_BTN_ATT_SAVE)
            {
                ScryHandleSaveAttunement(oPC);
                return;
            }
            if(sElem == SCRY_BTN_ATT_CANCEL)
            {
                NuiDestroy(oPC, nToken);
                return;
            }
        }
        return;
    }

    if(nToken != NuiFindWindow(oPC, SCRY_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt (oPC, SCRY_LVAR_SEL_ID);
        DeleteLocalJson(oPC, SCRY_LVAR_MIRRORS);
        if(NuiFindWindow(oPC, SCRY_WIN_ATTUNE) != 0)
            NuiDestroy(oPC, NuiFindWindow(oPC, SCRY_WIN_ATTUNE));
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == SCRY_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == SCRY_BTN_REFRESH)
        {
            SetLocalInt(oPC, SCRY_LVAR_SEL_ID, 0);
            ScryFeedMirrorList(oPC, nToken);
            ScryFeedDetail(oPC, nToken, 0);
            return;
        }

        if(sElem == SCRY_BTN_ATTUNE)
        {
            ScryCreateAttunePopup(oPC);
            return;
        }

        if(sElem == SCRY_BTN_GAZE)
        {
            int nSelId = GetLocalInt(oPC, SCRY_LVAR_SEL_ID);
            if(nSelId > 0)
                ScryPerformGaze(oPC, nToken, nSelId);
            return;
        }

        if(sElem == SCRY_BTN_DEACT)
        {
            int nSelId = GetLocalInt(oPC, SCRY_LVAR_SEL_ID);
            if(nSelId <= 0) return;

            json jMirror = ScryGetMirrorById(nSelId);
            if(JsonGetType(jMirror) == JSON_TYPE_NULL) return;

            if(!ScryCanDeactivate(oPC, jMirror))
            {
                SendMessageToPC(oPC, "[Zwierciadlo] Mozesz wygaszac tylko zwierciadla, ktore sam nastroiles.");
                return;
            }

            string sMirrorName = JsonGetString(JsonObjectGet(jMirror, "mirror_name"));
            ScryDeactivateMirror(nSelId);
            SetLocalInt(oPC, SCRY_LVAR_SEL_ID, 0);
            ScryFeedMirrorList(oPC, nToken);
            ScryFeedDetail(oPC, nToken, 0);
            SendMessageToPC(oPC, "[Zwierciadlo] Zwierciadlo \"" + sMirrorName + "\" zostalo zgaszone.");
            FloatingTextStringOnCreature("Pieczen krysztalu gasnie na zawsze.", oPC, FALSE);
            return;
        }
    }

    // List row click — select a mirror
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == SCRY_BTN_ROW)
    {
        json jMirrors = GetLocalJson(oPC, SCRY_LVAR_MIRRORS);
        if(nIdx < 0 || nIdx >= JsonGetLength(jMirrors)) return;

        json jRow = JsonArrayGet(jMirrors, nIdx);
        int  nId  = JsonGetInt(JsonObjectGet(jRow, "id"));

        SetLocalInt(oPC, SCRY_LVAR_SEL_ID, nId);

        // Rebuild encouraged array
        int  nCount = JsonGetLength(jMirrors);
        json jEncs  = JsonArray();
        int i;
        for(i = 0; i < nCount; i++)
            jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
        NuiSetBind(oPC, nToken, SCRY_BIND_ROW_ENC, jEncs);

        ScryFeedDetail(oPC, nToken, nId);
        return;
    }
}

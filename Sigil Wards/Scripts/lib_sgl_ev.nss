#include "lib_sgl"

// ----------------------------------------------------------------
// Main NUI event handler — assigned to SGL_EV_SCRIPT
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, SGL_WINDOW)) return;

    // ---- Window close: cleanup LVAR state ----
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt   (oPC, SGL_LVAR_SEL_ID);
        DeleteLocalInt   (oPC, SGL_LVAR_TYPE_IDX);
        DeleteLocalString(oPC, SGL_LVAR_SEL_ATT);
        DeleteLocalJson  (oPC, SGL_LVAR_SEARCH_RES);
        return;
    }

    // ----------------------------------------------------------------
    // Click events
    // ----------------------------------------------------------------

    if(sEvent == EVENT_TYPE_CLICK)
    {
        // ---- Global close button ----
        if(sElem == SGL_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        // ----------------------------------------------------------------
        // List view buttons
        // ----------------------------------------------------------------

        if(sElem == SGL_BTN_PLACE_OPEN)
        {
            if(SglGetPlayerSigilCount(oPC) >= SGL_MAX_SIGILS)
            {
                SendMessageToPC(oPC, "[Znak Ochronny] Masz już maksymalną liczbę aktywnych znaków ("
                    + IntToString(SGL_MAX_SIGILS) + ").");
                return;
            }
            SwapToPlaceView(oPC, nToken);
            return;
        }

        if(sElem == SGL_BTN_DISARM)
        {
            int nSelId = GetLocalInt(oPC, SGL_LVAR_SEL_ID);
            if(nSelId <= 0) return;

            json jSig = SglGetSigilById(nSelId);
            if(JsonGetType(jSig) == JSON_TYPE_NULL)
            {
                SendMessageToPC(oPC, "[Znak Ochronny] Znak już nie istnieje.");
                SetLocalInt(oPC, SGL_LVAR_SEL_ID, 0);
                FeedSglList(oPC, nToken);
                return;
            }
            // Verify ownership
            if(JsonGetString(JsonObjectGet(jSig, "owner_uuid")) != GetObjectUUID(oPC))
            {
                SendMessageToPC(oPC, "[Znak Ochronny] To nie jest twój znak.");
                return;
            }
            SglRemoveSigil(nSelId);
            SetLocalInt(oPC, SGL_LVAR_SEL_ID, 0);
            SendMessageToPC(oPC, "[Znak Ochronny] Znak rozbrojony.");
            FeedSglList(oPC, nToken);
            return;
        }

        if(sElem == SGL_BTN_ATT_OPEN)
        {
            int nSelId = GetLocalInt(oPC, SGL_LVAR_SEL_ID);
            if(nSelId <= 0) return;
            SwapToAttuneView(oPC, nToken);
            return;
        }

        // ----------------------------------------------------------------
        // Place view buttons
        // ----------------------------------------------------------------

        if(sElem == SGL_BTN_TYPE_PREV)
        {
            int nIdx2 = GetLocalInt(oPC, SGL_LVAR_TYPE_IDX);
            nIdx2--;
            if(nIdx2 < 0) nIdx2 = SGL_TYPE_COUNT - 1;
            SetLocalInt(oPC, SGL_LVAR_TYPE_IDX, nIdx2);
            FeedSglPlace(oPC, nToken);
            return;
        }

        if(sElem == SGL_BTN_TYPE_NEXT)
        {
            int nIdx2 = GetLocalInt(oPC, SGL_LVAR_TYPE_IDX);
            nIdx2 = (nIdx2 + 1) % SGL_TYPE_COUNT;
            SetLocalInt(oPC, SGL_LVAR_TYPE_IDX, nIdx2);
            FeedSglPlace(oPC, nToken);
            return;
        }

        if(sElem == SGL_BTN_PLACE_CONF)
        {
            int nType = GetLocalInt(oPC, SGL_LVAR_TYPE_IDX);
            SglPlaceAtLocation(oPC, nType);
            SwapToListView(oPC, nToken);
            return;
        }

        // ----------------------------------------------------------------
        // Attune view buttons
        // ----------------------------------------------------------------

        if(sElem == SGL_BTN_REVOKE)
        {
            int    nSelId   = GetLocalInt   (oPC, SGL_LVAR_SEL_ID);
            string sSelAtt  = GetLocalString(oPC, SGL_LVAR_SEL_ATT);
            if(nSelId <= 0 || sSelAtt == "") return;
            SglRevokeAttunement(nSelId, sSelAtt);
            DeleteLocalString(oPC, SGL_LVAR_SEL_ATT);
            FeedSglAttune(oPC, nToken);
            return;
        }

        // ---- Back button (shared between place and attune views) ----
        if(sElem == SGL_BTN_BACK)
        {
            SwapToListView(oPC, nToken);
            return;
        }
    }

    // ----------------------------------------------------------------
    // Mousedown events (list row selection)
    // ----------------------------------------------------------------

    if(sEvent == EVENT_TYPE_MOUSEDOWN)
    {
        // ---- Main sigil list row ----
        if(sElem == SGL_BTN_ROW)
        {
            json jSigils = SglGetPlayerSigils(oPC);
            if(nIdx < 0 || nIdx >= JsonGetLength(jSigils)) return;

            json   jSig  = JsonArrayGet(jSigils, nIdx);
            int    nId   = JsonGetInt(JsonObjectGet(jSig, "id"));
            int    nCount = JsonGetLength(jSigils);

            // Toggle selection: click same row to deselect
            int nPrev = GetLocalInt(oPC, SGL_LVAR_SEL_ID);
            SetLocalInt(oPC, SGL_LVAR_SEL_ID, (nPrev == nId) ? 0 : nId);
            FeedSglList(oPC, nToken);
            return;
        }

        // ---- Attuned player row (select for revoke) ----
        if(sElem == SGL_BTN_ATT_ROW)
        {
            int  nSigilId = GetLocalInt(oPC, SGL_LVAR_SEL_ID);
            json jAttuned = SglGetAttuned(nSigilId);
            if(nIdx < 0 || nIdx >= JsonGetLength(jAttuned)) return;

            json   jA       = JsonArrayGet(jAttuned, nIdx);
            string sUuid    = JsonGetString(JsonObjectGet(jA, "uuid"));
            string sPrevAtt = GetLocalString(oPC, SGL_LVAR_SEL_ATT);

            // Toggle selection
            SetLocalString(oPC, SGL_LVAR_SEL_ATT,
                (sPrevAtt == sUuid) ? "" : sUuid);
            FeedSglAttune(oPC, nToken);
            return;
        }

        // ---- Online player row (grant attunement) ----
        if(sElem == SGL_BTN_ONLINE_ROW)
        {
            int nSigilId = GetLocalInt(oPC, SGL_LVAR_SEL_ID);
            if(nSigilId <= 0) return;

            // Rebuild online list the same way FeedSglAttune does
            json jAttuned = SglGetAttuned(nSigilId);
            json jOnline  = JsonArray();
            object oOther = GetFirstPC();
            while(GetIsObjectValid(oOther))
            {
                if(oOther != oPC && !GetIsDMPossessed(oOther))
                {
                    string sOtherUuid = GetObjectUUID(oOther);
                    if(!SglIsAttuned(nSigilId, sOtherUuid))
                    {
                        json jEntry = JsonObject();
                        jEntry = JsonObjectSet(jEntry, "uuid", JsonString(sOtherUuid));
                        jEntry = JsonObjectSet(jEntry, "name", JsonString(GetName(oOther)));
                        jOnline = JsonArrayInsert(jOnline, jEntry);
                    }
                }
                oOther = GetNextPC();
            }

            if(nIdx < 0 || nIdx >= JsonGetLength(jOnline)) return;
            json   jTarget = JsonArrayGet(jOnline, nIdx);
            string sUuid   = JsonGetString(JsonObjectGet(jTarget, "uuid"));
            string sName   = JsonGetString(JsonObjectGet(jTarget, "name"));

            if(JsonGetLength(jAttuned) >= SGL_MAX_ATTUNED)
            {
                SendMessageToPC(oPC, "[Znak Ochronny] Osiągnięto limit dostępu ("
                    + IntToString(SGL_MAX_ATTUNED) + " graczy).");
                return;
            }

            SglAttunePlayer(nSigilId, sUuid, sName);
            SendMessageToPC(oPC, "[Znak Ochronny] " + sName + " ma teraz dostęp do znaku.");

            // Notify the newly attuned player if online
            object oGranted = GetFirstPC();
            while(GetIsObjectValid(oGranted))
            {
                if(GetObjectUUID(oGranted) == sUuid)
                {
                    SendMessageToPC(oGranted, "[Znak Ochronny] " + GetName(oPC)
                        + " nadał ci dostęp przez jeden ze swych znaków ochronnych.");
                    break;
                }
                oGranted = GetNextPC();
            }

            FeedSglAttune(oPC, nToken);
            return;
        }
    }
}

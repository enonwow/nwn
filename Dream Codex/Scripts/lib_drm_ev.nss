#include "lib_drm"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, DRM_WIN_MAIN)) return;

    // ---- Window opened ----
    if(sEvent == EVENT_TYPE_OPEN) return;

    // ---- Window closed ----
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalJson(oPC, DRM_LVAR_POOL);
        DeleteLocalJson(oPC, DRM_LVAR_ACCEPTED);
        DeleteLocalInt (oPC, DRM_LVAR_CURSOR);
        DeleteLocalInt (oPC, DRM_LVAR_JSEL);
        DeleteLocalInt (oPC, DRM_LVAR_SAVED);
        return;
    }

    // ---- Click events ----
    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == DRM_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == DRM_BTN_ACCEPT)
        {
            json jPool   = GetLocalJson(oPC, DRM_LVAR_POOL);
            int  nCursor = GetLocalInt (oPC, DRM_LVAR_CURSOR);
            int  nTotal  = JsonGetLength(jPool);

            if(nCursor >= nTotal) return;

            json jVision  = JsonArrayGet(jPool, nCursor);
            int  nVisionId = JsonGetInt (JsonObjectGet(jVision, "id"));
            int  nFxType   = JsonGetInt (JsonObjectGet(jVision, "fx_type"));
            int  nFxValue  = JsonGetInt (JsonObjectGet(jVision, "fx_value"));
            string sTitle  = JsonGetString(JsonObjectGet(jVision, "title"));

            DrmApplyVisionEffect(oPC, nFxType, nFxValue);

            json jAccepted = GetLocalJson(oPC, DRM_LVAR_ACCEPTED);
            jAccepted = JsonArrayInsert(jAccepted, JsonInt(nVisionId));
            SetLocalJson(oPC, DRM_LVAR_ACCEPTED, jAccepted);

            SendMessageToPC(oPC, "[Kodeks Wizji] Przyjąłeś wizję: "" + sTitle + "".");

            SetLocalInt(oPC, DRM_LVAR_CURSOR, nCursor + 1);
            DrmFeedTranceView(oPC, nToken);
            return;
        }

        if(sElem == DRM_BTN_REJECT)
        {
            json jPool   = GetLocalJson(oPC, DRM_LVAR_POOL);
            int  nCursor = GetLocalInt (oPC, DRM_LVAR_CURSOR);
            int  nTotal  = JsonGetLength(jPool);

            if(nCursor >= nTotal) return;

            json   jVision = JsonArrayGet(jPool, nCursor);
            string sTitle  = JsonGetString(JsonObjectGet(jVision, "title"));

            SendMessageToPC(oPC, "[Kodeks Wizji] Odrzuciłeś wizję: "" + sTitle + "".");

            SetLocalInt(oPC, DRM_LVAR_CURSOR, nCursor + 1);
            DrmFeedTranceView(oPC, nToken);
            return;
        }

        if(sElem == DRM_BTN_JOURNAL)
        {
            SetLocalInt(oPC, DRM_LVAR_JSEL, 0);
            NuiSetGroupLayout(oPC, nToken, DRM_GRP_SWAP, DrmBuildJournalView(oPC));
            DrmFeedJournalView(oPC, nToken);
            return;
        }

        if(sElem == DRM_BTN_BACK)
        {
            NuiSetGroupLayout(oPC, nToken, DRM_GRP_SWAP, DrmBuildTranceView(oPC));
            DrmFeedTranceView(oPC, nToken);
            return;
        }
    }

    // ---- Mouse-down on journal row ----
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == DRM_BTN_J_ROW)
    {
        json jJournal = DrmGetJournal(oPC);
        if(nIdx < 0 || nIdx >= JsonGetLength(jJournal)) return;

        int nCount   = JsonGetLength(jJournal);
        json jEncs   = JsonArray();
        int i;
        for(i = 0; i < nCount; i++)
            jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
        NuiSetBind(oPC, nToken, DRM_BIND_J_ENC, jEncs);

        SetLocalInt(oPC, DRM_LVAR_JSEL, nIdx);
        DrmFeedJournalView(oPC, nToken);
        return;
    }
}

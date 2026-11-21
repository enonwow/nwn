#include "lib_grim"

// ----------------------------------------------------------------
// Main NUI event handler
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    // ---- Codex popup ----
    if(nToken == NuiFindWindow(oPC, GRIM_WIN_CODEX))
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            // GRIM_BTN_COD_CAST has recipe_id baked into the ID via NuiList row index
            // The button element id is constant (GRIM_BTN_COD_CAST) and nIdx is the list row.
            // Rows are 0-indexed; recipe IDs are 1-indexed.
            if(sElem == GRIM_BTN_COD_CAST && nIdx >= 0 && nIdx < GRIM_RECIPE_COUNT)
                GrimDoMasteryCast(oPC, nIdx + 1);
        }
        return;
    }

    if(nToken != NuiFindWindow(oPC, GRIM_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalJson(oPC, GRIM_LVAR_SEL);
        DeleteLocalJson(oPC, GRIM_LVAR_FRAG_ROWS);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == GRIM_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == GRIM_BTN_CODEX)
        {
            GrimOpenCodexWindow(oPC);
            return;
        }

        if(sElem == GRIM_BTN_RESEARCH)
        {
            GrimDoResearch(oPC, nToken);
            return;
        }

        // Clear-slot buttons: GRIM_BTN_CLEAR_SLOT + "0" or "1"
        string sClearPfx = GRIM_BTN_CLEAR_SLOT;
        int    nClearPfxLen = GetStringLength(sClearPfx);
        if(GetStringLeft(sElem, nClearPfxLen) == sClearPfx)
        {
            int nSlot = StringToInt(GetStringRight(sElem, GetStringLength(sElem) - nClearPfxLen));

            json jSel = GetLocalJson(oPC, GRIM_LVAR_SEL);
            if(JsonGetType(jSel) != JSON_TYPE_ARRAY) jSel = JsonArray();
            int nSel = JsonGetLength(jSel);

            if(nSlot >= 0 && nSlot < nSel)
            {
                json jNew = JsonArray();
                int k;
                for(k = 0; k < nSel; k++)
                    if(k != nSlot) jNew = JsonArrayInsert(jNew, JsonArrayGet(jSel, k));
                SetLocalJson(oPC, GRIM_LVAR_SEL, jNew);
            }

            GrimFeedFragmentList(oPC, nToken);
            GrimFeedSlots(oPC, nToken);
            return;
        }
    }

    // Fragment row click — toggle selection
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == GRIM_BTN_FRAG_ROW)
    {
        json jRows = GetLocalJson(oPC, GRIM_LVAR_FRAG_ROWS);
        if(JsonGetType(jRows) != JSON_TYPE_ARRAY) return;
        if(nIdx < 0 || nIdx >= JsonGetLength(jRows)) return;

        json jRow  = JsonArrayGet(jRows, nIdx);
        int  nType = JsonGetInt(JsonObjectGet(jRow, "type"));
        int  nTier = JsonGetInt(JsonObjectGet(jRow, "tier"));
        int  nTot  = JsonGetInt(JsonObjectGet(jRow, "total"));

        json jSel = GetLocalJson(oPC, GRIM_LVAR_SEL);
        if(JsonGetType(jSel) != JSON_TYPE_ARRAY) jSel = JsonArray();
        int nSel   = JsonGetLength(jSel);
        int nSelCt = GrimSelectedCount(jSel, nType, nTier);
        int nAvail = nTot - nSelCt;

        if(nAvail <= 0)
        {
            SendMessageToPC(oPC, "[Grimuar] Brak dostępnych fragmentów tego rodzaju.");
            return;
        }
        if(nSel >= GRIM_SLOT_COUNT)
        {
            SendMessageToPC(oPC, "[Grimuar] Oba gniazda zapełnione. Usuń fragment, by zmienić wybór.");
            return;
        }

        json jEntry = JsonObject();
        jEntry = JsonObjectSet(jEntry, "type", JsonInt(nType));
        jEntry = JsonObjectSet(jEntry, "tier", JsonInt(nTier));
        jSel   = JsonArrayInsert(jSel, jEntry);
        SetLocalJson(oPC, GRIM_LVAR_SEL, jSel);

        GrimFeedFragmentList(oPC, nToken);
        GrimFeedSlots(oPC, nToken);
        return;
    }
}

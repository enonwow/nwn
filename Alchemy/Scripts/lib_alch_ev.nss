// lib_alch_ev.nss
// NUI event handler for the Alchemy Workshop window.
// Set as the module OnNuiEvent script (see sys_on_load.nss).
#include "lib_alch"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, ALCH_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, ALCH_LVAR_SEL_IDX);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == ALCH_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == ALCH_BTN_BREW)
        {
            int nSel = GetLocalInt(oPC, ALCH_LVAR_SEL_IDX);
            if(nSel >= 0)
                AlchBrew(oPC, nToken, nSel);
            return;
        }
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == ALCH_BTN_ROW)
    {
        if(nIdx < 0 || nIdx >= ALCH_RECIPE_COUNT) return;

        // De-encourage previously selected row
        int nPrev = GetLocalInt(oPC, ALCH_LVAR_SEL_IDX);
        if(nPrev >= 0)
        {
            json jEncs = NuiGetBind(oPC, nToken, ALCH_BIND_REC_ENC);
            if(JsonGetType(jEncs) == JSON_TYPE_ARRAY && nPrev < JsonGetLength(jEncs))
            {
                jEncs = JsonArraySet(jEncs, nPrev, JsonBool(FALSE));
                NuiSetBind(oPC, nToken, ALCH_BIND_REC_ENC, jEncs);
            }
        }

        // Encourage new row
        SetLocalInt(oPC, ALCH_LVAR_SEL_IDX, nIdx);
        json jEncs = NuiGetBind(oPC, nToken, ALCH_BIND_REC_ENC);
        if(JsonGetType(jEncs) == JSON_TYPE_ARRAY && nIdx < JsonGetLength(jEncs))
        {
            jEncs = JsonArraySet(jEncs, nIdx, JsonBool(TRUE));
            NuiSetBind(oPC, nToken, ALCH_BIND_REC_ENC, jEncs);
        }

        FeedDetailPanel(oPC, nToken, nIdx);
        return;
    }
}

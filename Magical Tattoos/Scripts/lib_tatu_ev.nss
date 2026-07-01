#include "lib_tatu"

// ----------------------------------------------------------------
// NUI event handler — called by NWN for all TATU_WINDOW events.
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, TATU_WINDOW)) return;

    // -- Window closed by system (ESC / title X if closable) --
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        SetLocalInt(oPC, TATU_LVAR_SEL_DESIGN, 0);
        SetLocalInt(oPC, TATU_LVAR_SEL_SLOT,   -1);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == TATU_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == TATU_BTN_APPLY)
        {
            TatuDoApply(oPC, nToken);
            return;
        }

        if(sElem == TATU_BTN_REMOVE)
        {
            TatuDoRemove(oPC, nToken);
            return;
        }
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN)
    {
        // Design list row clicked
        if(sElem == TATU_BTN_ROW)
        {
            json jDesigns = TatuGetAllDesigns();
            if(nIdx < 0 || nIdx >= JsonGetLength(jDesigns)) return;

            json jD   = JsonArrayGet(jDesigns, nIdx);
            int nId   = JsonGetInt(JsonObjectGet(jD, "id"));

            SetLocalInt(oPC, TATU_LVAR_SEL_DESIGN, nId);
            SetLocalInt(oPC, TATU_LVAR_SEL_SLOT,   -1);

            json jTattoos = TatuGetPCTattoos(oPC);
            FeedTatuDesignList(oPC, nToken, jDesigns, jTattoos);
            FeedTatuBodyMap(oPC, nToken, jTattoos);
            FeedTatuDetail(oPC, nToken, jDesigns, jTattoos);
            return;
        }

        // Body map slot button clicked: ID = TATU_BTN_SLOT + "_N"
        string sSlotPrefix = TATU_BTN_SLOT + "_";
        int nPrefixLen     = GetStringLength(sSlotPrefix);
        if(GetStringLeft(sElem, nPrefixLen) == sSlotPrefix)
        {
            int nSlotIdx = StringToInt(
                GetStringRight(sElem, GetStringLength(sElem) - nPrefixLen));

            if(nSlotIdx < 0 || nSlotIdx >= TATU_SLOT_COUNT) return;

            SetLocalInt(oPC, TATU_LVAR_SEL_SLOT,   nSlotIdx);
            SetLocalInt(oPC, TATU_LVAR_SEL_DESIGN, 0);

            json jDesigns = TatuGetAllDesigns();
            json jTattoos = TatuGetPCTattoos(oPC);
            FeedTatuDesignList(oPC, nToken, jDesigns, jTattoos);
            FeedTatuBodyMap(oPC, nToken, jTattoos);
            FeedTatuDetail(oPC, nToken, jDesigns, jTattoos);
            return;
        }
    }
}

// lib_fac_ev.nss - Faction Reputation: NUI event handler
//
// Set as the NUI event script for FAC_WINDOW.
// Module Properties -> Events -> OnNuiEvent -> lib_fac_ev

#include "lib_fac"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, FAC_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, FAC_LVAR_SEL_FACTION);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == FAC_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == FAC_BTN_ROW)
        {
            // nIdx is the list row index = faction ID
            if(nIdx < 0 || nIdx >= FAC_COUNT) return;

            SetLocalInt(oPC, FAC_LVAR_SEL_FACTION, nIdx);

            // Refresh highlight on all rows
            json jEncs = JsonArray();
            int i;
            for(i = 0; i < FAC_COUNT; i++)
                jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
            NuiSetBind(oPC, nToken, FAC_BIND_LST_ROW_ENC, jEncs);

            FacFeedDetail(oPC, nToken, nIdx);
            return;
        }
    }
}

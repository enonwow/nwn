#include "lib_chim"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, CHIM_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalString(oPC, CHIM_LVAR_SEL_SLOT);
        DeleteLocalInt   (oPC, CHIM_LVAR_SEL_GRAFT);
        DeleteLocalJson  (oPC, CHIM_LVAR_AVAIL);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == CHIM_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        // Slot selector buttons
        string sClickedSlot = "";
        if(sElem == CHIM_BTN_HEAD)  sClickedSlot = CHIM_SLOT_HEAD;
        if(sElem == CHIM_BTN_TORSO) sClickedSlot = CHIM_SLOT_TORSO;
        if(sElem == CHIM_BTN_ARMS)  sClickedSlot = CHIM_SLOT_ARMS;
        if(sElem == CHIM_BTN_LEGS)  sClickedSlot = CHIM_SLOT_LEGS;

        if(sClickedSlot != "")
        {
            SetLocalString(oPC, CHIM_LVAR_SEL_SLOT,  sClickedSlot);
            SetLocalInt   (oPC, CHIM_LVAR_SEL_GRAFT, 0);
            NuiSetBind(oPC, nToken, CHIM_BIND_SEL_LBL,
                JsonString("Slot: " + ChimSlotDisplayName(sClickedSlot)));
            NuiSetBind(oPC, nToken, CHIM_BIND_STATUS, JsonString(""));
            ChimFeedSlots    (oPC, nToken);
            ChimFeedGraftList(oPC, nToken, sClickedSlot);
            ChimFeedDetail   (oPC, nToken, JsonNull());
            return;
        }

        if(sElem == CHIM_BTN_GRAFT)
        {
            ChimHandleInstall(oPC, nToken);
            return;
        }

        if(sElem == CHIM_BTN_REMOVE)
        {
            ChimHandleRemove(oPC, nToken);
            return;
        }
    }

    // List row click
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == CHIM_BTN_ROW)
    {
        json jAvail = GetLocalJson(oPC, CHIM_LVAR_AVAIL);
        if(nIdx < 0 || nIdx >= JsonGetLength(jAvail)) return;

        json jGraft  = JsonArrayGet(jAvail, nIdx);
        int  nGraftId = JsonGetInt(JsonObjectGet(jGraft, "id"));
        SetLocalInt(oPC, CHIM_LVAR_SEL_GRAFT, nGraftId);
        NuiSetBind(oPC, nToken, CHIM_BIND_STATUS, JsonString(""));

        string sSlot = GetLocalString(oPC, CHIM_LVAR_SEL_SLOT);
        ChimFeedGraftList(oPC, nToken, sSlot);
        ChimFeedDetail   (oPC, nToken, jGraft);
        return;
    }
}

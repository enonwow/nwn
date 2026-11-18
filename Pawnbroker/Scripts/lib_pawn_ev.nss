#include "lib_pawn"

// ----------------------------------------------------------------
// Main NUI event handler for PAWN_WINDOW.
// Assigned as event script via PAWN_EV_SCRIPT.
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, PAWN_WINDOW)) return;

    // ---- Window closed ----
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        // Return any unsent slot items to inventory
        json jSlots = GetLocalJson(oPC, PAWN_LVAR_SLOTS);
        int  nCount = JsonGetLength(jSlots);
        int i;
        for(i = 0; i < nCount; i++)
        {
            json jSlot     = JsonArrayGet(jSlots, i);
            json jItemJson = JsonObjectGet(jSlot, "item_json");
            JsonToObject(jItemJson, GetLocation(oPC), oPC, TRUE);
        }
        DeleteLocalJson(oPC, PAWN_LVAR_SLOTS);
        DeleteLocalInt (oPC, PAWN_LVAR_SEL_ID);
        DeleteLocalInt (oPC, PAWN_LVAR_TARGET_IDX);
        return;
    }

    // ---- Click events ----
    if(sEvent == EVENT_TYPE_CLICK)
    {
        // Close button
        if(sElem == PAWN_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        // Switch to pawn view
        if(sElem == PAWN_BTN_TO_PAWN)
        {
            SwapToPawnView(oPC, nToken);
            return;
        }

        // Back to browse view (from pawn view)
        if(sElem == PAWN_BTN_BACK)
        {
            // Return items in slots to inventory
            json jSlots = GetLocalJson(oPC, PAWN_LVAR_SLOTS);
            int  nCount = JsonGetLength(jSlots);
            int i;
            for(i = 0; i < nCount; i++)
            {
                json jSlot     = JsonArrayGet(jSlots, i);
                json jItemJson = JsonObjectGet(jSlot, "item_json");
                JsonToObject(jItemJson, GetLocation(oPC), oPC, TRUE);
            }
            DeleteLocalJson(oPC, PAWN_LVAR_SLOTS);
            SwapToBrowseView(oPC, nToken);
            return;
        }

        // Redeem selected item
        if(sElem == PAWN_BTN_REDEEM)
        {
            int nId = GetLocalInt(oPC, PAWN_LVAR_SEL_ID);
            PawnHandleRedeem(oPC, nToken, nId);
            return;
        }

        // Confirm pawn
        if(sElem == PAWN_BTN_CONFIRM)
        {
            PawnExecute(oPC, nToken);
            return;
        }

        // Slot button: PAWN_BTN_SLOT + IntToString(i)
        int nPrefixLen = GetStringLength(PAWN_BTN_SLOT);
        if(GetStringLeft(sElem, nPrefixLen) == PAWN_BTN_SLOT)
        {
            int nSlotIdx = StringToInt(GetStringRight(sElem, GetStringLength(sElem) - nPrefixLen));
            PawnHandleSlotClick(oPC, nToken, nSlotIdx);
            return;
        }
    }

    // ---- Mouse-down on list row: select a pawn ----
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == PAWN_BTN_ROW)
    {
        json jRows = PawnGetActive(GetObjectUUID(oPC));
        if(nIdx < 0 || nIdx >= JsonGetLength(jRows)) return;

        json jRow = JsonArrayGet(jRows, nIdx);
        int  nId  = JsonGetInt(JsonObjectGet(jRow, "id"));
        FeedBrowseDetail(oPC, nToken, nId);
        return;
    }
}

#include "lib_tarot"

// ----------------------------------------------------------------
// Main NUI event handler — set as the event script on TarotOpenWindow
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, TAROT_WINDOW)) return;

    // ---- Window close ----
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, TAROT_LVAR_SEL_CARD);
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK && sEvent != EVENT_TYPE_MOUSEDOWN) return;

    // ---- Close button ----
    if(sElem == TAROT_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    // ---- Draw button ----
    if(sElem == TAROT_BTN_DRAW)
    {
        TarotExecuteDraw(oPC);
        return;
    }

    // ---- Reset button ----
    if(sElem == TAROT_BTN_RESET)
    {
        TarotExecuteReset(oPC);
        return;
    }

    // ---- Card button click (show detail) ----
    // Button IDs: TAROT_BTN_CARD + IntToString(i)  e.g. "tarot_btn_card_7"
    int nPrefixLen = GetStringLength(TAROT_BTN_CARD);
    if(GetStringLeft(sElem, nPrefixLen) == TAROT_BTN_CARD)
    {
        int nCardId = StringToInt(GetStringRight(sElem,
            GetStringLength(sElem) - nPrefixLen));

        if(nCardId < 0 || nCardId >= TAROT_CARD_COUNT) return;

        int nOldSel = GetLocalInt(oPC, TAROT_LVAR_SEL_CARD);
        SetLocalInt(oPC, TAROT_LVAR_SEL_CARD, nCardId);

        // Update encouragement: old card off, new card on
        if(nOldSel >= 0 && nOldSel != nCardId)
            NuiSetBind(oPC, nToken,
                TAROT_BIND_CARD_ENC + IntToString(nOldSel), JsonBool(FALSE));
        NuiSetBind(oPC, nToken,
            TAROT_BIND_CARD_ENC + IntToString(nCardId), JsonBool(TRUE));

        TarotFeedDetailPanel(oPC, nToken, nCardId);
        return;
    }
}

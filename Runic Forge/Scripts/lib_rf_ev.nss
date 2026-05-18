#include "lib_rf"

// NUI event handler script for Runic Forge.
// Set as the event script for both RF_WIN_FORGE and RF_WIN_MINIGAME.

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    // ---- Minigame window events ----
    if(nToken == NuiFindWindow(oPC, RF_WIN_MINIGAME))
    {
        if(sEvent == EVENT_TYPE_CLOSE)
        {
            // Player closed the window manually.
            // Refund gold only if still in display phase (never got to play).
            if(GetLocalInt(oPC, RF_LVAR_MG_PHASE) == 0 && !GetLocalInt(oPC, RF_LVAR_MG_DONE))
            {
                int nCost = GetLocalInt(oPC, RF_LVAR_MG_COST);
                if(nCost > 0)
                {
                    GiveGoldToCreature(oPC, nCost);
                    SendMessageToPC(oPC, "[Kuźnia] Przerwano przed próbą — złoto zwrócone.");
                }
            }
            SetLocalInt(oPC, RF_LVAR_MG_DONE, 1);
            return;
        }

        if(sEvent == EVENT_TYPE_CLICK)
        {
            int nBtnLen = GetStringLength(RF_BTN_MG);
            if(GetStringLeft(sElem, nBtnLen) == RF_BTN_MG)
            {
                int nBtn = StringToInt(GetStringRight(sElem, GetStringLength(sElem) - nBtnLen));
                RFHandleMGButton(oPC, nBtn);
                return;
            }
        }

        return;
    }

    // ---- Forge window events ----
    if(nToken != NuiFindWindow(oPC, RF_WIN_FORGE)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        // Clean up state on window close.
        DeleteLocalString(oPC, RF_LVAR_WPN_UUID);
        DeleteLocalString(oPC, RF_LVAR_WPN_NAME);
        SetLocalInt(oPC, RF_LVAR_SEL_RUNE, -1);
        DeleteLocalInt(oPC, RF_LVAR_TARGETING);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == RF_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == RF_BTN_WEAPON)
        {
            // Enter item-targeting mode; flag so sys_on_target.nss knows it's ours.
            SetLocalInt(oPC, RF_LVAR_TARGETING, 1);
            NuiSetBind(oPC, nToken, RF_BIND_WPN_ENA, JsonBool(FALSE));
            EnterTargetingMode(oPC, OBJECT_TYPE_ITEM);
            SendMessageToPC(oPC, "[Kuźnia] Kliknij broń w swoim ekwipunku.");
            return;
        }

        // Rune selection buttons
        int nBtnPfxLen = GetStringLength(RF_BTN_RUNE);
        if(GetStringLeft(sElem, nBtnPfxLen) == RF_BTN_RUNE)
        {
            int nRune = StringToInt(GetStringRight(sElem, GetStringLength(sElem) - nBtnPfxLen));
            if(nRune < 0 || nRune >= RF_RUNE_COUNT) return;
            SetLocalInt(oPC, RF_LVAR_SEL_RUNE, nRune);
            RFFeedForge(oPC, nToken);
            return;
        }

        if(sElem == RF_BTN_FORGE)
        {
            string sUuid = GetLocalString(oPC, RF_LVAR_WPN_UUID);
            int nRune    = GetLocalInt(oPC, RF_LVAR_SEL_RUNE);

            if(sUuid == "" || nRune < 0)
            {
                SendMessageToPC(oPC, "[Kuźnia] Wybierz najpierw broń i runę.");
                return;
            }

            // Close the forge before opening the minigame.
            NuiDestroy(oPC, nToken);
            RFMinigameStart(oPC);
            return;
        }
    }
}

// lib_wca_ev.nss — Witch Cauldron: NUI event handler
// Assigned to the window via WCA_EV_SCRIPT. Called from the module's OnNuiEvent script.
#include "lib_wca"

void WcaHandleEvent(object oPC)
{
    int nToken = NuiGetWindowToken();
    if(NuiGetWindowId() != WCA_WINDOW) return;

    string sEvent = NuiGetEventType();
    string sElemId = NuiGetElementId();

    // ---- window open ----
    if(sEvent == EVENT_TYPE_OPEN)
    {
        WcaFeedRecipeList(oPC, nToken);
        WcaFeedSelectedRecipe(oPC, nToken);
        WcaFeedSlots(oPC, nToken);
        return;
    }

    // ---- window close ----
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        // If brewing is active, abort it
        if(GetLocalInt(oPC, WCA_LVAR_BREWING))
        {
            SetLocalInt(oPC, WCA_LVAR_BREWING, 0);
            SendMessageToPC(oPC, "[Kocioł] Rytuał przerwany — składniki pochłonięte.");
            SetLocalJson(oPC, WCA_LVAR_SLOTS, WcaInitSlots());
        }
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK) return;
    if(GetLocalInt(oPC, WCA_LVAR_BREWING)) return;

    // ---- close button ----
    if(sElemId == WCA_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    // ---- brew button ----
    if(sElemId == WCA_BTN_BREW)
    {
        int nSel = GetLocalInt(oPC, WCA_LVAR_SEL_REC);
        if(nSel < 0)
        {
            NuiSetBind(oPC, nToken, WCA_BIND_STATUS, JsonString("Najpierw wybierz recepturę."));
            return;
        }

        json jSlots = WcaGetSlots(oPC);
        int nFilled = WcaCountFilledSlots(jSlots);
        int nReq    = WcaGetRecipeIngredientCount(nSel);

        if(nFilled != nReq)
        {
            NuiSetBind(oPC, nToken, WCA_BIND_STATUS,
                JsonString("Wymagane składniki: " + IntToString(nReq) + ". Umieszczono: " + IntToString(nFilled) + "."));
            return;
        }

        WcaStartBrewing(oPC, nToken);
        return;
    }

    // ---- recipe row click (list) ----
    if(sElemId == WCA_BTN_REC_ROW)
    {
        int nRow = NuiGetEventArrayIndex();
        json jKnown = WcaGetKnownRecipes(oPC);
        if(nRow < 0 || nRow >= JsonGetLength(jKnown)) return;

        int nRecipeId = JsonGetInt(JsonArrayGet(jKnown, nRow));
        SetLocalInt(oPC, WCA_LVAR_SEL_REC, nRecipeId);

        // Reset slots when switching recipes
        json jSlots = WcaGetSlots(oPC);
        int nFilled = WcaCountFilledSlots(jSlots);
        if(nFilled > 0)
        {
            // Return ingredients to inventory before resetting
            int i;
            for(i = 0; i < WCA_SLOTS; i++)
            {
                json jEntry = JsonArrayGet(jSlots, i);
                if(JsonGetType(jEntry) == JSON_TYPE_NULL) continue;
                string sTag  = JsonGetString(JsonObjectGet(jEntry, "tag"));
                string sName = JsonGetString(JsonObjectGet(jEntry, "name"));
                object oItem = CreateItemOnObject(sTag, oPC, 1);
                if(!GetIsObjectValid(oItem))
                {
                    oItem = CreateItemOnObject("nw_it_novel001", oPC, 1);
                    if(GetIsObjectValid(oItem)) SetName(oItem, sName);
                }
            }
            SetLocalJson(oPC, WCA_LVAR_SLOTS, WcaInitSlots());
            SendMessageToPC(oPC, "[Kocioł] Składniki zwrócone do ekwipunku.");
        }

        WcaFeedSelectedRecipe(oPC, nToken);
        WcaFeedSlots(oPC, nToken);
        NuiSetBind(oPC, nToken, WCA_BIND_STATUS,
            JsonString("Wybrano: " + WcaGetRecipeName(nRecipeId) + "."));
        return;
    }

    // ---- add ingredient button (slot 0-3) ----
    int i;
    for(i = 0; i < WCA_SLOTS; i++)
    {
        if(sElemId == WCA_BTN_SLOT_ADD + IntToString(i))
        {
            WcaEnterTargetMode(oPC, i);
            return;
        }
    }

    // ---- remove ingredient button (slot 0-3) ----
    for(i = 0; i < WCA_SLOTS; i++)
    {
        if(sElemId == WCA_BTN_SLOT_REMOVE + IntToString(i))
        {
            WcaRemoveSlotIngredient(oPC, nToken, i);
            return;
        }
    }
}

void main()
{
    object oPC = NuiGetEventPlayer();
    WcaHandleEvent(oPC);
}

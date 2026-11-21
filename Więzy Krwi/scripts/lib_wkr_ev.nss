#include "lib_wkr"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, WKR_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        // No pending state to clean up except transient targeting vars.
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK && sEvent != EVENT_TYPE_MOUSEDOWN) return;

    // ---- Tab navigation ----
    if(sElem == WKR_BTN_TAB_LIST)
    {
        WkrShowListView(oPC, nToken);
        return;
    }
    if(sElem == WKR_BTN_TAB_INV)
    {
        WkrShowInviteView(oPC, nToken);
        return;
    }

    // ---- Close ----
    if(sElem == WKR_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    // ---- List row click ----
    if(sElem == WKR_BTN_ROW)
    {
        json jBonds = GetLocalJson(oPC, WKR_LVAR_BONDS_JSON);
        if(nIdx < 0 || nIdx >= JsonGetLength(jBonds)) return;

        json jBond = JsonArrayGet(jBonds, nIdx);
        int  nId   = JsonGetInt(JsonObjectGet(jBond, "id"));

        int nPrev = GetLocalInt(oPC, WKR_LVAR_SEL_ID);
        if(nPrev == nId)
        {
            // Toggle off
            SetLocalInt(oPC, WKR_LVAR_SEL_ID, 0);
            WkrFeedList(oPC, nToken);
            WkrFeedDetail(oPC, nToken, 0);
            return;
        }

        SetLocalInt(oPC, WKR_LVAR_SEL_ID, nId);
        WkrFeedList(oPC, nToken);
        WkrFeedDetail(oPC, nToken, nId);
        return;
    }

    // ---- Detail actions ----
    if(sElem == WKR_BTN_PAY)
    {
        WkrHandlePay(oPC, nToken);
        return;
    }
    if(sElem == WKR_BTN_DISSOLVE)
    {
        WkrHandleDissolve(oPC, nToken);
        return;
    }

    // ---- Invite form: type selectors ----
    if(sElem == WKR_BTN_TYPE_DEBT)
    {
        SetLocalInt(oPC, WKR_LVAR_INV_TYPE, WKR_TYPE_DEBT);
        WkrShowInviteView(oPC, nToken);
        return;
    }
    if(sElem == WKR_BTN_TYPE_OATH)
    {
        SetLocalInt(oPC, WKR_LVAR_INV_TYPE, WKR_TYPE_OATH);
        WkrShowInviteView(oPC, nToken);
        return;
    }
    if(sElem == WKR_BTN_TYPE_GUARD)
    {
        SetLocalInt(oPC, WKR_LVAR_INV_TYPE, WKR_TYPE_GUARD);
        WkrShowInviteView(oPC, nToken);
        return;
    }

    // ---- Guard role selectors ----
    if(sElem == WKR_BTN_ROLE_GUARD)
    {
        SetLocalInt(oPC, WKR_LVAR_IS_GUARD, 1);
        NuiSetBind(oPC, nToken, WKR_BIND_ROLE_G, JsonBool(TRUE));
        NuiSetBind(oPC, nToken, WKR_BIND_ROLE_W, JsonBool(FALSE));
        return;
    }
    if(sElem == WKR_BTN_ROLE_WARD)
    {
        SetLocalInt(oPC, WKR_LVAR_IS_GUARD, 0);
        NuiSetBind(oPC, nToken, WKR_BIND_ROLE_G, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, WKR_BIND_ROLE_W, JsonBool(TRUE));
        return;
    }

    // ---- Partner picker ----
    if(sElem == WKR_BTN_PICK)
    {
        NuiSetBind(oPC, nToken, WKR_BIND_SEAL_ENA, JsonBool(FALSE));
        EnterTargetingMode(oPC, OBJECT_TYPE_CREATURE);
        SendMessageToPC(oPC, "[Więzy Krwi] Kliknij na gracza, którego chcesz zaprosić do więzi.");
        return;
    }

    // ---- Seal (create bond invite) ----
    if(sElem == WKR_BTN_SEAL)
    {
        WkrHandleSeal(oPC, nToken);
        return;
    }

    // ---- Accept pending invite ----
    if(sElem == WKR_BTN_ACCEPT)
    {
        WkrHandleAccept(oPC, nToken);
        return;
    }
}

// lib_syn_ev.nss — Szynkarz: NUI event handler
// Hook: NuiCreate(..., "lib_syn_ev")

#include "lib_syn"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, SYN_WINDOW)) return;

    // ---- Window opened ----
    if(sEvent == EVENT_TYPE_OPEN)
    {
        int nLevel = SynGetIntox(oPC);
        SynUpdateIntoxBar(oPC, nToken, nLevel);
        return;
    }

    // ---- Window closed ----
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, SYN_LVAR_SEL_REC);
        DeleteLocalInt(oPC, SYN_LVAR_SEL_CEL_ID);
        DeleteLocalInt(oPC, SYN_LVAR_SEL_CEL_RI);
        DeleteLocalInt(oPC, SYN_LVAR_ACTIVE_TAB);
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK && sEvent != EVENT_TYPE_MOUSEDOWN) return;

    // ---- Tab strip ----
    if(sElem == SYN_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    if(sElem == SYN_BTN_TAB_REC)
    {
        SetLocalInt(oPC, SYN_LVAR_ACTIVE_TAB, 0);
        SynFeedRecipesGroup(oPC, nToken);
        int nLevel = SynGetIntox(oPC);
        SynUpdateIntoxBar(oPC, nToken, nLevel);
        return;
    }

    if(sElem == SYN_BTN_TAB_BREW)
    {
        SetLocalInt(oPC, SYN_LVAR_ACTIVE_TAB, 1);
        SynFeedBrewGroup(oPC, nToken);
        int nLevel = SynGetIntox(oPC);
        SynUpdateIntoxBar(oPC, nToken, nLevel);
        return;
    }

    if(sElem == SYN_BTN_TAB_CEL)
    {
        SetLocalInt(oPC, SYN_LVAR_ACTIVE_TAB, 2);
        SynFeedCellarGroup(oPC, nToken);
        int nLevel = SynGetIntox(oPC);
        SynUpdateIntoxBar(oPC, nToken, nLevel);
        return;
    }

    // ---- Recipes tab: row click ----
    if(sElem == SYN_BTN_REC_ROW)
    {
        if(nIdx < 0 || nIdx >= SYN_REC_COUNT) return;
        SetLocalInt(oPC, SYN_LVAR_SEL_REC, nIdx);
        // Refresh detail panel without rebuilding the entire group
        NuiSetBind(oPC, nToken, SYN_BIND_DET_NAME,  JsonString(SynRecipeName(nIdx)));
        NuiSetBind(oPC, nToken, SYN_BIND_DET_FLAV,  JsonString(SynRecipeFlavor(nIdx)));
        NuiSetBind(oPC, nToken, SYN_BIND_DET_INGS,  JsonString(SynIngListText(nIdx)));
        NuiSetBind(oPC, nToken, SYN_BIND_DET_EFFS,  JsonString(SynRecipeEffects(nIdx)));
        NuiSetBind(oPC, nToken, SYN_BIND_DET_INTOX,
            JsonString("Upojenie: +" + IntToString(SynRecipeIntox(nIdx)) + " pkt"));
        // Update selection highlight
        json jEnc = JsonArray();
        int i;
        for(i = 0; i < SYN_REC_COUNT; i++)
            jEnc = JsonArrayInsert(jEnc, JsonBool(i == nIdx));
        NuiSetBind(oPC, nToken, SYN_BIND_REC_ENC, jEnc);
        return;
    }

    // ---- Brew tab: brew button ----
    if(sElem == SYN_BTN_BREW)
    {
        SynBrew(oPC, nToken);
        return;
    }

    // ---- Cellar tab: row click ----
    if(sElem == SYN_BTN_CEL_ROW)
    {
        json jCellar = SynGetCellar(oPC);
        if(nIdx < 0 || nIdx >= JsonGetLength(jCellar)) return;

        json jRow = JsonArrayGet(jCellar, nIdx);
        int  nId  = JsonGetInt(JsonObjectGet(jRow, "id"));
        int  nRec = JsonGetInt(JsonObjectGet(jRow, "recipe_id"));

        SetLocalInt(oPC, SYN_LVAR_SEL_CEL_ID, nId);
        SetLocalInt(oPC, SYN_LVAR_SEL_CEL_RI, nRec);

        // Update selection highlight
        int  nCount = JsonGetLength(jCellar);
        json jEnc   = JsonArray();
        int i;
        for(i = 0; i < nCount; i++)
        {
            int nRowId = JsonGetInt(JsonObjectGet(JsonArrayGet(jCellar, i), "id"));
            jEnc = JsonArrayInsert(jEnc, JsonBool(nRowId == nId));
        }
        NuiSetBind(oPC, nToken, SYN_BIND_CEL_ENC,   jEnc);
        NuiSetBind(oPC, nToken, SYN_BIND_DRINK_ENA,  JsonBool(TRUE));
        return;
    }

    // ---- Cellar tab: drink button ----
    if(sElem == SYN_BTN_DRINK)
    {
        int nSelId = GetLocalInt(oPC, SYN_LVAR_SEL_CEL_ID);
        int nSelRi = GetLocalInt(oPC, SYN_LVAR_SEL_CEL_RI);
        if(nSelId == 0)
        {
            SendMessageToPC(oPC, "[Warzelnia] Zaznacz trunek, który chcesz wypić.");
            return;
        }
        SynDrink(oPC, nToken, nSelId, nSelRi);
        return;
    }
}

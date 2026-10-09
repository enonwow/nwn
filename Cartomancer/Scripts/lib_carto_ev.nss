#include "lib_carto"

// ----------------------------------------------------------------
// NUI event handler  —  assign to the module's OnNUIEvent script
// or include a call to main() from an existing dispatcher.
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, CARTO_WIN)) return;

    // ---- Window closed by the engine ----
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalString(oPC, CARTO_LVAR_EDIT_TAG);
        DeleteLocalInt   (oPC, CARTO_LVAR_DANGER);
        DeleteLocalInt   (oPC, CARTO_LVAR_TARGETING);
        DeleteLocalString(oPC, CARTO_LVAR_XFER_TAG);
        DeleteLocalJson  (oPC, CARTO_LVAR_MAPS_CACHE);
        return;
    }

    // ---- Button clicks ----
    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == CARTO_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        // ---- List view actions ----
        if(sElem == CARTO_BTN_NEWMAP)
        {
            object oArea = GetArea(oPC);
            string sTag  = GetTag(oArea);
            if(sTag == "")
            {
                NuiSetBind(oPC, nToken, CARTO_BIND_STATUS,
                    JsonString("Nie mozna szkicowac — obszar nie ma tagu."));
                return;
            }
            SetLocalString(oPC, CARTO_LVAR_EDIT_TAG, sTag);
            SetLocalInt   (oPC, CARTO_LVAR_DANGER,   1);
            CartoSwapToEdit(oPC, nToken);
            return;
        }

        if(sElem == CARTO_BTN_SELLALL)
        {
            CartoHandleSellAll(oPC, nToken);
            return;
        }

        // ---- Edit view actions ----
        if(sElem == CARTO_BTN_BACK)
        {
            DeleteLocalString(oPC, CARTO_LVAR_EDIT_TAG);
            DeleteLocalInt   (oPC, CARTO_LVAR_DANGER);
            CartoSwapToList(oPC, nToken);
            return;
        }

        if(sElem == CARTO_BTN_SAVE)
        {
            CartoHandleSave(oPC, nToken);
            return;
        }

        if(sElem == CARTO_BTN_DEL)
        {
            CartoHandleDelete(oPC, nToken);
            return;
        }

        if(sElem == CARTO_BTN_SELL)
        {
            CartoHandleSell(oPC, nToken);
            return;
        }

        if(sElem == CARTO_BTN_XFER)
        {
            CartoHandleTransfer(oPC, nToken);
            return;
        }

        // ---- Danger level selection ----
        if(sElem == CARTO_BTN_D1) { CartoUpdateDangerDisplay(oPC, nToken, 1); return; }
        if(sElem == CARTO_BTN_D2) { CartoUpdateDangerDisplay(oPC, nToken, 2); return; }
        if(sElem == CARTO_BTN_D3) { CartoUpdateDangerDisplay(oPC, nToken, 3); return; }
        if(sElem == CARTO_BTN_D4) { CartoUpdateDangerDisplay(oPC, nToken, 4); return; }
        if(sElem == CARTO_BTN_D5) { CartoUpdateDangerDisplay(oPC, nToken, 5); return; }
    }

    // ---- List row click — open edit view for chosen map ----
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == CARTO_BTN_ROW)
    {
        json jMaps = GetLocalJson(oPC, CARTO_LVAR_MAPS_CACHE);
        if(nIdx < 0 || nIdx >= JsonGetLength(jMaps)) return;

        json jRow    = JsonArrayGet(jMaps, nIdx);
        string sTag  = JsonGetString(JsonObjectGet(jRow, "area_tag"));
        int    nDang = JsonGetInt   (JsonObjectGet(jRow, "danger"));

        // Highlight selected row briefly
        int nCount = JsonGetLength(jMaps);
        json jEncs = JsonArray();
        int i;
        for(i = 0; i < nCount; i++)
            jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
        NuiSetBind(oPC, nToken, CARTO_BIND_ROW_ENC, jEncs);

        SetLocalString(oPC, CARTO_LVAR_EDIT_TAG, sTag);
        SetLocalInt   (oPC, CARTO_LVAR_DANGER,   nDang);
        CartoSwapToEdit(oPC, nToken);
        return;
    }

    // ---- Watch: notes length counter (optional UX) ----
    if(sEvent == EVENT_TYPE_WATCH && sElem == CARTO_BIND_NOTES)
    {
        string sNotes = JsonGetString(NuiGetBind(oPC, nToken, CARTO_BIND_NOTES));
        int nLen = GetStringLength(sNotes);
        if(nLen >= CARTO_NOTES_MAX - 20)
            NuiSetBind(oPC, nToken, CARTO_BIND_STATUS,
                JsonString("Notatki: " + IntToString(nLen) + " / "
                           + IntToString(CARTO_NOTES_MAX) + " znakow."));
        return;
    }
}

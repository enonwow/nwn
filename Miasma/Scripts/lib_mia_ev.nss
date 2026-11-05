#include "lib_mia"

// ================================================================
// NUI event handler — referenced as WINDOW_EVENT_SCRIPT
// Handles both the gauge HUD and the DM panel.
// ================================================================

void HandleGaugeEvent(object oPC, int nToken, string sEvType, string sBtnId)
{
    if(sEvType == "click")
    {
        if(sBtnId == MIA_BTN_CLEANSE)
        {
            if(!MiaTryCleanseWithHerb(oPC))
                SendMessageToPC(oPC, "[Opar] Nie masz ziół oczyszczających ("
                    + MIA_ITEM_HERB + ") w ekwipunku.");
        }
    }
}

void HandleDmPanelEvent(object oPC, int nToken, string sEvType, string sBtnId)
{
    if(sEvType == "click")
    {
        if(sBtnId == MIA_BTN_DM_CURAREA)
        {
            // Fill tag field with the area the DM currently stands in
            string sTag = GetTag(GetArea(oPC));
            NuiSetBind(oPC, nToken, MIA_BIND_DM_AREA, JsonString(sTag));
            NuiSetBind(oPC, nToken, MIA_BIND_DM_SETENA, JsonBool(sTag != ""));
        }
        else if(sBtnId == MIA_BTN_DM_SET)
        {
            string sTag  = JsonGetString(NuiGetBind(oPC, nToken, MIA_BIND_DM_AREA));
            int nIntens  = JsonGetInt(NuiGetBind(oPC, nToken, MIA_BIND_DM_INTENS));
            int nTypeIdx = JsonGetInt(NuiGetBind(oPC, nToken, MIA_BIND_DM_TYPE));

            if(sTag == "")
            {
                NuiSetBind(oPC, nToken, MIA_BIND_DM_MSG, JsonString("Błąd: podaj tag obszaru."));
                return;
            }

            // Combo index 0=Nekrotyczny(1), 1=Bagnienny(2), 2=Demoniczny(3)
            int nType = nTypeIdx + 1;
            if(nIntens < 1) nIntens = 1;
            if(nIntens > 10) nIntens = 10;

            MiaSetArea(sTag, nIntens, nType);

            string sMsg = "Skażono: [" + sTag + "] — " + MiaTypeName(nType)
                + ", poz. " + IntToString(nIntens);
            NuiSetBind(oPC, nToken, MIA_BIND_DM_MSG, JsonString(sMsg));
            SendMessageToAllDMs("[Opar] " + sMsg + " (MG: " + GetName(oPC) + ")");

            MiaFeedDmPanel(oPC, nToken);
        }
        else if(sBtnId == MIA_BTN_DM_CLEAR)
        {
            string sTag = JsonGetString(NuiGetBind(oPC, nToken, MIA_BIND_DM_AREA));
            if(sTag == "")
            {
                NuiSetBind(oPC, nToken, MIA_BIND_DM_MSG, JsonString("Błąd: podaj tag obszaru."));
                return;
            }

            MiaClearArea(sTag);

            string sMsg = "Oczyszczono obszar: [" + sTag + "]";
            NuiSetBind(oPC, nToken, MIA_BIND_DM_MSG, JsonString(sMsg));
            SendMessageToAllDMs("[Opar] " + sMsg + " (MG: " + GetName(oPC) + ")");

            MiaFeedDmPanel(oPC, nToken);
        }
        else if(sBtnId == MIA_BTN_DM_ROW)
        {
            int nRow = NuiGetEventArrayIndex();
            json jAreas = MiaGetAllAreas();
            if(nRow < JsonGetLength(jAreas))
            {
                json jRow = JsonArrayGet(jAreas, nRow);
                string sTag  = JsonGetString(JsonObjectGet(jRow, "area_tag"));
                int    nInt  = JsonGetInt(JsonObjectGet(jRow, "intensity"));
                int    nTyp  = JsonGetInt(JsonObjectGet(jRow, "mia_type"));

                // Fill input fields from the selected row
                NuiSetBind(oPC, nToken, MIA_BIND_DM_AREA,   JsonString(sTag));
                NuiSetBind(oPC, nToken, MIA_BIND_DM_INTENS, JsonInt(nInt));
                NuiSetBind(oPC, nToken, MIA_BIND_DM_TYPE,   JsonInt(nTyp - 1));
                NuiSetBind(oPC, nToken, MIA_BIND_DM_SETENA, JsonBool(TRUE));
                SetLocalString(oPC, MIA_LVAR_DM_SEL, sTag);
                MiaFeedDmPanel(oPC, nToken);
            }
        }
    }

    if(sEvType == "watch")
    {
        // Enable Set/Clear buttons when area tag is non-empty
        string sTag = JsonGetString(NuiGetBind(oPC, nToken, MIA_BIND_DM_AREA));
        NuiSetBind(oPC, nToken, MIA_BIND_DM_SETENA, JsonBool(sTag != ""));
    }
}

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sWinId = NuiGetWindowId(oPC, nToken);
    string sEvType = NuiGetEventType();
    string sBtnId  = NuiGetEventElement();

    if(sWinId == MIA_WINDOW)
        HandleGaugeEvent(oPC, nToken, sEvType, sBtnId);
    else if(sWinId == MIA_WIN_DM)
        HandleDmPanelEvent(oPC, nToken, sEvType, sBtnId);
}

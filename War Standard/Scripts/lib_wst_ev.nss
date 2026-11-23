// =============================================================================
// lib_wst_ev.nss
// =============================================================================
// NUI event router for the War Standard system.
//
// Handles both windows:
//   WST_WIN_OVR (overview)   — row click, plant button, close, drag
//   WST_WIN_PLT (plant dlg)  — type combo watch, confirm plant, cancel
// =============================================================================

#include "lib_wst"

void main()
{
    object oPC      = NuiGetEventPlayer();
    int    nToken   = NuiGetEventWindow();
    string sEvent   = NuiGetEventType();
    string sElement = NuiGetEventElement();
    int    nIdx     = NuiGetEventArrayIndex();

    // --- Overview window ---
    if(NuiGetWindowId(oPC, nToken) == WST_WIN_OVR)
    {
        if(sEvent == EVENT_TYPE_CLOSE)
        {
            DeleteLocalInt(oPC, WST_LVAR_OVR_TOKEN);
            DeleteLocalInt(oPC, WST_LVAR_GEOM_DELAY);
            return;
        }

        if(sEvent == EVENT_TYPE_WATCH && sElement == WST_BIND_OVR_GEOM)
        {
            if(GetLocalInt(oPC, WST_LVAR_GEOM_DELAY)) return;
            SetLocalInt(oPC, WST_LVAR_GEOM_DELAY, 1);
            DelayCommand(0.5, WstSaveOverviewPos(oPC));
            return;
        }

        if(sEvent == EVENT_TYPE_CLICK && sElement == WST_BTN_OVR_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            DeleteLocalInt(oPC, WST_LVAR_OVR_TOKEN);
            return;
        }

        if(sEvent == EVENT_TYPE_CLICK && sElement == WST_BTN_OVR_PLANT)
        {
            WstOpenPlantDialog(oPC);
            return;
        }

        if(sEvent == EVENT_TYPE_CLICK && sElement == WST_BTN_OVR_ROW && nIdx >= 0)
        {
            // Collect the nth standard from the query and show details in floating text.
            int nCur = 0;
            sqlquery q = WstQueryAllIds();
            int nSelId = 0;
            while(SqlStep(q))
            {
                if(nCur == nIdx) { nSelId = SqlGetInt(q, 0); break; }
                nCur++;
            }
            if(nSelId == 0) return;

            struct WstRow s = WstGetStandard(nSelId);
            if(s.id == 0) return;

            int nRemain = s.expiresAt - WstNowUnix();
            if(nRemain < 0) nRemain = 0;
            string sMsg = "[" + WstGetTypeName(s.nType) + "] "
                        + "Właściciel: " + s.ownerName
                        + " — HP: " + IntToString(s.hp) + "/" + IntToString(WST_MAX_HP)
                        + " — Pozostało: " + IntToString(nRemain / 60) + " min";
            if(GetStringLength(s.inscription) > 0)
                sMsg += " | "" + s.inscription + """;
            FloatingTextStringOnCreature(sMsg, oPC, FALSE);
            return;
        }
    }

    // --- Plant dialog ---
    if(NuiGetWindowId(oPC, nToken) == WST_WIN_PLT)
    {
        if(sEvent == EVENT_TYPE_CLOSE)
        {
            DeleteLocalInt(oPC, WST_LVAR_PLT_TOKEN);
            return;
        }

        if(sEvent == EVENT_TYPE_WATCH && sElement == WST_BIND_PLT_TYPE)
        {
            int nType = JsonGetInt(NuiGetBind(oPC, nToken, WST_BIND_PLT_TYPE));
            WstFeedPlantDesc(oPC, nToken, nType);
            return;
        }

        if(sEvent == EVENT_TYPE_CLICK && sElement == WST_BTN_PLT_CANCEL)
        {
            NuiDestroy(oPC, nToken);
            DeleteLocalInt(oPC, WST_LVAR_PLT_TOKEN);
            return;
        }

        if(sEvent == EVENT_TYPE_CLICK && sElement == WST_BTN_PLT_CONFIRM)
        {
            int nType = JsonGetInt(NuiGetBind(oPC, nToken, WST_BIND_PLT_TYPE));
            string sInscription = JsonGetString(NuiGetBind(oPC, nToken, WST_BIND_PLT_INSCR));

            // Clamp inscription to max length (belt-and-suspenders; NuiInputEdit limits too).
            if(GetStringLength(sInscription) > WST_MAX_INSCRIPTION)
                sInscription = GetStringLeft(sInscription, WST_MAX_INSCRIPTION);

            NuiDestroy(oPC, nToken);
            DeleteLocalInt(oPC, WST_LVAR_PLT_TOKEN);

            int nId = WstPlantStandard(oPC, nType, sInscription);
            if(nId > 0)
            {
                // Refresh the overview if it's open.
                int nOvrToken = GetLocalInt(oPC, WST_LVAR_OVR_TOKEN);
                if(nOvrToken != 0)
                    WstFeedOverview(oPC, nOvrToken);
            }
            return;
        }
    }
}

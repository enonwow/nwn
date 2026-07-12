// lib_inq_ev.nss - Inquisition: NUI event handler
// Registered via NuiCreate(..., INQ_EV_SCRIPT) for all three Inquisition windows.

#include "lib_inq"

void main()
{
    object oPlayer = NuiGetEventPlayer();
    int    nToken  = NuiGetEventWindow();
    string sEvent  = NuiGetEventType();
    string sElem   = NuiGetEventElement();
    int    nIdx    = NuiGetEventArrayIndex();
    string sWinId  = NuiGetWindowId(oPlayer, nToken);

    // ---- Act picker popup ----
    if(sWinId == INQ_WINDOW_DM_ACT)
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == INQ_BTN_DM_ACT_CLOSE)
            {
                NuiDestroy(oPlayer, nToken);
                return;
            }

            string sPrefix = INQ_BTN_DM_ACT_ROW;
            int    nPLen   = GetStringLength(sPrefix);
            if(GetStringLeft(sElem, nPLen) == sPrefix)
            {
                int nActId = StringToInt(GetStringRight(sElem, GetStringLength(sElem) - nPLen));
                NuiDestroy(oPlayer, nToken);
                InqDmApplyCharge(oPlayer, nActId);
                return;
            }
        }
        return;
    }

    // ---- DM panel ----
    if(sWinId == INQ_WINDOW_DM)
    {
        if(sEvent == EVENT_TYPE_CLOSE)
        {
            DeleteLocalString(oPlayer, INQ_LVAR_DM_SEL_UUID);
            DeleteLocalString(oPlayer, INQ_LVAR_DM_SEL_NAME);
            return;
        }

        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == INQ_BTN_DM_CLOSE)
            {
                NuiDestroy(oPlayer, nToken);
                return;
            }

            if(sElem == INQ_BTN_DM_ROW)
            {
                json jSuspects = InqGetAllSuspects();
                if(nIdx < 0 || nIdx >= JsonGetLength(jSuspects)) return;

                json   jRow  = JsonArrayGet(jSuspects, nIdx);
                string sUuid = JsonGetString(JsonObjectGet(jRow, "uuid"));
                string sName = JsonGetString(JsonObjectGet(jRow, "name"));

                SetLocalString(oPlayer, INQ_LVAR_DM_SEL_UUID, sUuid);
                SetLocalString(oPlayer, INQ_LVAR_DM_SEL_NAME, sName);
                InqFeedDmPanel(oPlayer, nToken);
                return;
            }

            if(sElem == INQ_BTN_DM_ADD_ACT)
            {
                if(GetLocalString(oPlayer, INQ_LVAR_DM_SEL_UUID) == "")
                {
                    SendMessageToPC(oPlayer, "[Inkwizycja] Wybierz najpierw postać z listy.");
                    return;
                }
                InqOpenActPicker(oPlayer);
                return;
            }

            if(sElem == INQ_BTN_DM_PARDON)
            {
                InqDmPardon(oPlayer);
                return;
            }

            if(sElem == INQ_BTN_DM_CLEAR)
            {
                string sUuid = GetLocalString(oPlayer, INQ_LVAR_DM_SEL_UUID);
                string sName = GetLocalString(oPlayer, INQ_LVAR_DM_SEL_NAME);
                if(sUuid == "")
                {
                    SendMessageToPC(oPlayer, "[Inkwizycja] Wybierz najpierw postać.");
                    return;
                }

                InqClearAll(sUuid, sName);

                object oPC = GetFirstPC();
                while(GetIsObjectValid(oPC))
                {
                    if(GetObjectUUID(oPC) == sUuid)
                    {
                        InqRemoveRatingEffects(oPC);
                        int nPcToken = NuiFindWindow(oPC, INQ_WINDOW_DOSSIER);
                        if(nPcToken) InqFeedDossier(oPC, nPcToken);
                        break;
                    }
                    oPC = GetNextPC();
                }

                SendMessageToPC(oPlayer,
                    "[Inkwizycja] Wymazano zarzuty dla " + sName + ".");
                InqFeedDmPanel(oPlayer, nToken);
                return;
            }
        }
        return;
    }

    // ---- Player dossier ----
    if(sWinId != INQ_WINDOW_DOSSIER) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPlayer, INQ_LVAR_TOKEN);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == INQ_BTN_CLOSE)
        {
            NuiDestroy(oPlayer, nToken);
            return;
        }

        if(sElem == INQ_BTN_CONFESS)
        {
            InqHandleConfess(oPlayer, nToken);
            return;
        }

        if(sElem == INQ_BTN_RECANT)
        {
            InqHandleRecant(oPlayer, nToken);
            return;
        }
    }
}

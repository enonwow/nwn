// lib_esi_ev.nss — Echo Sight: NUI event handler

#include "lib_esi"

void main()
{
    object oPC     = NuiGetEventPlayer();
    string sWindow = NuiGetWindowId();
    string sEvent  = NuiGetEventType();
    string sElemId = NuiGetEventElement();
    int    nToken  = NuiGetEventWindow();
    int    nIndex  = NuiGetEventArrayIndex();

    // ----------------------------------------------------------------
    // Vision window events
    // ----------------------------------------------------------------
    if(sWindow == ESI_WIN_VISION)
    {
        if(sEvent == EVENT_TYPE_CLOSE)
        {
            DeleteLocalJson(oPC, ESI_LVAR_PENDING);
            return;
        }

        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElemId == ESI_BTN_ABSORB)
            {
                json jPending = GetLocalJson(oPC, ESI_LVAR_PENDING);
                if(JsonGetType(jPending) != JSON_TYPE_NULL)
                    EsiDoAbsorb(oPC, jPending);
                DeleteLocalJson(oPC, ESI_LVAR_PENDING);
                NuiDestroy(oPC, nToken);
                return;
            }

            if(sElemId == ESI_BTN_REJECT)
            {
                DeleteLocalJson(oPC, ESI_LVAR_PENDING);
                NuiDestroy(oPC, nToken);
                SendMessageToPC(oPC, "[Echo] Odpychasz wizję. Przeszłość pozostaje ciemnością.");
                return;
            }
        }
        return;
    }

    // ----------------------------------------------------------------
    // Codex window events
    // ----------------------------------------------------------------
    if(sWindow == ESI_WIN_CODEX)
    {
        if(sEvent == EVENT_TYPE_CLOSE)
            return;

        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElemId == ESI_BTN_CLOSE)
            {
                EsiCloseCodex(oPC);
                return;
            }

            // Row click: select echo and populate detail panel
            if(sElemId == ESI_BTN_ROW)
            {
                // Turn off previous highlight
                json jEncs = NuiGetBind(oPC, nToken, ESI_BIND_ROW_ENC);
                if(JsonGetType(jEncs) == JSON_TYPE_ARRAY)
                {
                    int nLen = JsonGetLength(jEncs);
                    int k;
                    for(k = 0; k < nLen; k++)
                        jEncs = JsonArraySet(jEncs, k, JsonBool(FALSE));
                    jEncs = JsonArraySet(jEncs, nIndex, JsonBool(TRUE));
                    NuiSetBind(oPC, nToken, ESI_BIND_ROW_ENC, jEncs);
                }

                // Retrieve echo_uuid from codex at nIndex and feed detail panel
                json jCodex = EsiGetCodex(oPC);
                if(nIndex >= 0 && nIndex < JsonGetLength(jCodex))
                {
                    json jEntry  = JsonArrayGet(jCodex, nIndex);
                    string sUuid = JsonGetString(JsonObjectGet(jEntry, "echo_uuid"));
                    SetLocalString(oPC, ESI_LVAR_SEL_UUID, sUuid);
                    EsiFeedDetail(oPC, nToken, sUuid);
                }
                return;
            }

            // Consume selected echo
            if(sElemId == ESI_BTN_CONSUME)
            {
                string sSelUuid = GetLocalString(oPC, ESI_LVAR_SEL_UUID);
                if(sSelUuid != "")
                    EsiDoConsume(oPC, nToken, sSelUuid);
                return;
            }
        }
        return;
    }
}

#include "lib_ins"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, INS_WINDOW)) return;

    // ---- Window closed (native X or NuiDestroy) ----
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalString(oPC, INS_LVAR_TABLET);
        DeleteLocalInt   (oPC, INS_LVAR_PAGE);
        DeleteLocalInt   (oPC, INS_LVAR_SEL_ID);
        DeleteLocalInt   (oPC, INS_LVAR_SEL_TYPE);
        DeleteLocalJson  (oPC, INS_LVAR_LIST_JSON);
        return;
    }

    // ---- Watch: text field changes ----
    if(sEvent == EVENT_TYPE_WATCH && sElem == INS_BIND_WRITE_TXT)
    {
        string sTxt = JsonGetString(NuiGetBind(oPC, nToken, INS_BIND_WRITE_TXT));
        int    nLen = GetStringLength(sTxt);
        int    nLeft = INS_TEXT_MAX - nLen;
        NuiSetBind(oPC, nToken, INS_BIND_CHARS_LBL,
            JsonString(IntToString(nLeft < 0 ? 0 : nLeft) + "/" +
                       IntToString(INS_TEXT_MAX) + " znaków"));
        NuiSetBind(oPC, nToken, INS_BIND_WRITE_ENA,
            JsonBool(nLen >= 3 && nLen <= INS_TEXT_MAX));
        return;
    }

    // ---- Click: top-bar and detail buttons ----
    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == INS_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }
        if(sElem == INS_BTN_TAB_READ)
        {
            SwapToReadView(oPC, nToken);
            return;
        }
        if(sElem == INS_BTN_TAB_WRITE)
        {
            SwapToWriteView(oPC, nToken);
            return;
        }

        // Pagination
        if(sElem == INS_BTN_PREV_PAGE)
        {
            int nPage = GetLocalInt(oPC, INS_LVAR_PAGE);
            if(nPage > 0)
            {
                SetLocalInt(oPC, INS_LVAR_PAGE, nPage - 1);
                SetLocalInt(oPC, INS_LVAR_SEL_ID, 0);
                FeedInsList  (oPC, nToken);
                FeedInsDetail(oPC, nToken, 0);
            }
            return;
        }
        if(sElem == INS_BTN_NEXT_PAGE)
        {
            SetLocalInt(oPC, INS_LVAR_PAGE, GetLocalInt(oPC, INS_LVAR_PAGE) + 1);
            SetLocalInt(oPC, INS_LVAR_SEL_ID, 0);
            FeedInsList  (oPC, nToken);
            FeedInsDetail(oPC, nToken, 0);
            return;
        }

        // Detail actions
        if(sElem == INS_BTN_BLESS)
        {
            InsDoBless(oPC, nToken);
            return;
        }
        if(sElem == INS_BTN_BACK_LIST)
        {
            SetLocalInt(oPC, INS_LVAR_SEL_ID, 0);
            FeedInsList  (oPC, nToken);
            FeedInsDetail(oPC, nToken, 0);
            return;
        }

        // Write: type selector buttons (ins_type_0 … ins_type_4)
        if(GetStringLeft(sElem, GetStringLength(INS_BTN_TYPE_PFX)) == INS_BTN_TYPE_PFX)
        {
            string sSuffix = GetStringRight(sElem,
                GetStringLength(sElem) - GetStringLength(INS_BTN_TYPE_PFX));
            int nType = StringToInt(sSuffix);
            if(nType >= 0 && nType < INS_TYPE_COUNT)
            {
                SetLocalInt(oPC, INS_LVAR_SEL_TYPE, nType);
                int i;
                for(i = 0; i < INS_TYPE_COUNT; i++)
                    NuiSetBind(oPC, nToken,
                        INS_BIND_TYPE_ENC + IntToString(i), JsonBool(i == nType));
            }
            return;
        }

        // Write: inscribe
        if(sElem == INS_BTN_INSCRIBE)
        {
            InsDoInscribe(oPC, nToken);
            return;
        }
    }

    // ---- MouseDown: list row click ----
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == INS_BTN_ROW)
    {
        json jList = GetLocalJson(oPC, INS_LVAR_LIST_JSON);
        if(nIdx < 0 || nIdx >= JsonGetLength(jList)) return;
        json jRow = JsonArrayGet(jList, nIdx);
        int  nId  = JsonGetInt(JsonObjectGet(jRow, "id"));
        SetLocalInt(oPC, INS_LVAR_SEL_ID, nId);
        FeedInsList  (oPC, nToken);
        FeedInsDetail(oPC, nToken, nId);
    }
}

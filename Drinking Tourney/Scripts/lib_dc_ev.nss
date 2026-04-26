#include "lib_dc_ui"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    int nMain   = NuiFindWindow(oPC, DC_WINDOW);
    int nCreate = NuiFindWindow(oPC, DC_WIN_CREATE);

    // ---- Create-tournament popup ----
    if(nToken == nCreate && nCreate != 0)
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == DC_BTN_CREATE_SIZE_4)  { DcSelectSize(oPC, nToken, 4);  return; }
            if(sElem == DC_BTN_CREATE_SIZE_8)  { DcSelectSize(oPC, nToken, 8);  return; }
            if(sElem == DC_BTN_CREATE_SIZE_16) { DcSelectSize(oPC, nToken, 16); return; }
            if(sElem == DC_BTN_CREATE_OK)      { DcSubmitCreate(oPC, nToken);   return; }
            if(sElem == DC_BTN_CREATE_CANCEL)  { NuiDestroy(oPC, nToken);       return; }
        }
        if(sEvent == EVENT_TYPE_WATCH)
        {
            // Radio behavior — sync the LVAR with whichever box was just toggled.
            if(sElem == DC_BIND_CREATE_SIZE_4
            || sElem == DC_BIND_CREATE_SIZE_8
            || sElem == DC_BIND_CREATE_SIZE_16)
            {
                int b4  = JsonGetInt(NuiGetBind(oPC, nToken, DC_BIND_CREATE_SIZE_4));
                int b8  = JsonGetInt(NuiGetBind(oPC, nToken, DC_BIND_CREATE_SIZE_8));
                int b16 = JsonGetInt(NuiGetBind(oPC, nToken, DC_BIND_CREATE_SIZE_16));
                int nSize = GetLocalInt(oPC, DC_LVAR_CREATE_SIZE);
                if(sElem == DC_BIND_CREATE_SIZE_4  && b4)  nSize = 4;
                if(sElem == DC_BIND_CREATE_SIZE_8  && b8)  nSize = 8;
                if(sElem == DC_BIND_CREATE_SIZE_16 && b16) nSize = 16;
                DcSelectSize(oPC, nToken, nSize);
            }
        }
        return;
    }

    // ---- Main window ----
    if(nToken != nMain || nMain == 0) return;

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == DC_BTN_CLOSE)       { NuiDestroy(oPC, nToken); return; }
        if(sElem == DC_BTN_TAB_ACTIVE)  { SetLocalInt(oPC, DC_LVAR_VIEW, DC_VIEW_ACTIVE);
                                          FeedDcMain(oPC, nToken); return; }
        if(sElem == DC_BTN_TAB_OPEN)    { SetLocalInt(oPC, DC_LVAR_VIEW, DC_VIEW_OPEN);
                                          FeedDcMain(oPC, nToken); return; }
        if(sElem == DC_BTN_TAB_HISTORY) { SetLocalInt(oPC, DC_LVAR_VIEW, DC_VIEW_HISTORY);
                                          FeedDcMain(oPC, nToken); return; }
        if(sElem == DC_BTN_PRIMARY)
        {
            DcShowCreatePopup(oPC);
            return;
        }
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == DC_BTN_ROW)
    {
        // In Open tab a row click joins that tournament.
        int nView = GetLocalInt(oPC, DC_LVAR_VIEW);
        if(nView != DC_VIEW_OPEN) return;
        json jRows = DcListByStatus(DC_STATUS_OPEN, 20);
        if(nIdx < 0 || nIdx >= JsonGetLength(jRows)) return;
        json jR = JsonArrayGet(jRows, nIdx);
        int nId = JsonGetInt(JsonObjectGet(jR, "id"));
        DcJoinTournament(oPC, nId);
        FeedDcMain(oPC, nToken);
    }
}

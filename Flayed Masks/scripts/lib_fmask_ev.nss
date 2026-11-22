#include "lib_fmask"

void FmaskCreateConfirmPopup(object oPC);

// ----------------------------------------------------------------
// Confirm popup (replace worn mask?)
// ----------------------------------------------------------------

void FmaskCreateConfirmPopup(object oPC)
{
    if(NuiFindWindow(oPC, FMASK_WIN_CONFIRM) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, FMASK_WIN_CONFIRM));

    float fW = GetNuiScaleDimension(oPC, 400.0);
    float fH = GetNuiScaleDimension(oPC, 160.0);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    json jMsg = NuiLabel(
        JsonString("Już nosisz maskę.\nZdjąć ją i założyć nową?"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jMsg = NuiHeight(jMsg, GetNuiScaleDimension(oPC, 50.0));

    float fBtnH = GetNuiScaleDimension(oPC, 32.0);
    float fBtnW = GetNuiScaleDimension(oPC, 120.0);

    json jYes = NuiButton(JsonString("Zamień"));
    jYes = NuiId(jYes, FMASK_BTN_CONF_YES);
    jYes = NuiWidth(jYes, fBtnW);
    jYes = NuiHeight(jYes, fBtnH);

    json jNo = NuiButton(JsonString("Anuluj"));
    jNo = NuiId(jNo, FMASK_BTN_CONF_NO);
    jNo = NuiWidth(jNo, fBtnW);
    jNo = NuiHeight(jNo, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jYes);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jNo);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jMsg);
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jWin = NuiWindow(NuiCol(jCol),
        JsonString("Zmiana maski"),
        NuiRect(fX, fY, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    NuiCreate(oPC, jWin, FMASK_WIN_CONFIRM, FMASK_EV_SCRIPT);
}

// ----------------------------------------------------------------
// Main event handler
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    // ---- Confirm popup ----
    if(nToken == NuiFindWindow(oPC, FMASK_WIN_CONFIRM))
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == FMASK_BTN_CONF_YES)
            {
                int nNewId = GetLocalInt(oPC, FMASK_LVAR_CONFIRM);
                NuiDestroy(oPC, nToken);
                FmaskRemoveMask(oPC);
                if(nNewId > 0)
                {
                    FmaskWearMask(oPC, nNewId);
                    SetLocalInt(oPC, FMASK_LVAR_SEL_ID, nNewId);
                }
                DeleteLocalInt(oPC, FMASK_LVAR_CONFIRM);
                int nMainToken = NuiFindWindow(oPC, FMASK_WINDOW);
                if(nMainToken != 0)
                {
                    FeedFmaskList(oPC, nMainToken);
                    FeedFmaskDetail(oPC, nMainToken, nNewId);
                }
            }
            else if(sElem == FMASK_BTN_CONF_NO)
            {
                NuiDestroy(oPC, nToken);
                DeleteLocalInt(oPC, FMASK_LVAR_CONFIRM);
            }
        }
        return;
    }

    if(nToken != NuiFindWindow(oPC, FMASK_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, FMASK_LVAR_SEL_ID);
        DeleteLocalInt(oPC, FMASK_LVAR_CONFIRM);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == FMASK_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == FMASK_BTN_FLAY)
        {
            SetLocalInt(oPC, FMASK_LVAR_TARGETING, 1);
            EnterTargetingMode(oPC, OBJECT_TYPE_CREATURE);
            SendMessageToPC(oPC, "[Zdarty Oblicze] Wskaż martwego humanoida, by zedrzeć jego twarz.");
            return;
        }

        if(sElem == FMASK_BTN_WEAR)
        {
            int nSelId  = GetLocalInt(oPC, FMASK_LVAR_SEL_ID);
            int nWornId = GetLocalInt(oPC, FMASK_LVAR_WORN_ID);

            if(nSelId <= 0) return;

            if(nSelId == nWornId)
            {
                FmaskRemoveMask(oPC);
                FeedFmaskList(oPC, nToken);
                FeedFmaskDetail(oPC, nToken, nSelId);
            }
            else if(nWornId > 0)
            {
                SetLocalInt(oPC, FMASK_LVAR_CONFIRM, nSelId);
                FmaskCreateConfirmPopup(oPC);
            }
            else
            {
                FmaskWearMask(oPC, nSelId);
                FeedFmaskList(oPC, nToken);
                FeedFmaskDetail(oPC, nToken, nSelId);
            }
            return;
        }
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == FMASK_BTN_ROW)
    {
        json jMasks = FmaskGetCollection(oPC);
        if(nIdx < 0 || nIdx >= JsonGetLength(jMasks)) return;

        json jRow = JsonArrayGet(jMasks, nIdx);
        int nId   = JsonGetInt(JsonObjectGet(jRow, "id"));

        SetLocalInt(oPC, FMASK_LVAR_SEL_ID, nId);

        int nCount = JsonGetLength(jMasks);
        json jEncs = JsonArray();
        int i;
        for(i = 0; i < nCount; i++)
            jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
        NuiSetBind(oPC, nToken, FMASK_BIND_ROW_ENC, jEncs);

        FeedFmaskDetail(oPC, nToken, nId);
        return;
    }
}

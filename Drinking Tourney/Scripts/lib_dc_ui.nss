#include "lib_dc"

// ----------------------------------------------------------------
// Drinking Tournament — UI
// ----------------------------------------------------------------

json BuildDcRowCell(object oPC)
{
    float fH = GetNuiScaleDimension(oPC, 26.0);

    json jPrim = NuiLabel(NuiBind(DC_BIND_ROW_PRIM),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jPrim = NuiStyleForegroundColor(jPrim, NuiBind(DC_BIND_ROW_COLOR));

    json jSec = NuiLabel(NuiBind(DC_BIND_ROW_SEC),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSec = NuiStyleForegroundColor(jSec, NuiBind(DC_BIND_ROW_COLOR));

    json jRight = NuiLabel(NuiBind(DC_BIND_ROW_RIGHT),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jRight = NuiWidth(jRight, GetNuiScaleDimension(oPC, 130.0));
    jRight = NuiStyleForegroundColor(jRight, NuiBind(DC_BIND_ROW_COLOR));

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jPrim);
    jRow = JsonArrayInsert(jRow, jSec);
    jRow = JsonArrayInsert(jRow, jRight);
    json jCell = NuiGroup(NuiRow(jRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, DC_BTN_ROW);
    jCell = NuiHeight(jCell, fH);
    return jCell;
}

void CreateDcWindow(object oPC)
{
    int nExisting = NuiFindWindow(oPC, DC_WINDOW);
    if(nExisting != 0) { FeedDcMain(oPC, nExisting); return; }

    SetLocalInt(oPC, DC_LVAR_VIEW, DC_VIEW_ACTIVE);

    float fW = GetNuiScaleDimension(oPC, DC_W);
    float fH = GetNuiScaleDimension(oPC, DC_H);
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fLblH = GetNuiScaleDimension(oPC, 22.0);

    json jTitle = NuiLabel(NuiBind(DC_BIND_TITLE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);
    json jClose = NuiId(NuiButton(JsonString("Close")), DC_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 90.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitle);
    jTopRow = JsonArrayInsert(jTopRow, jClose);

    json jHdr = NuiLabel(NuiBind(DC_BIND_HEADER),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHdr = NuiStyleForegroundColor(jHdr, GetNuiColorNwnGold());
    jHdr = NuiHeight(jHdr, fLblH);

    json jTabAct = NuiId(NuiButton(JsonString("Active / bracket")), DC_BTN_TAB_ACTIVE);
    jTabAct = NuiEncouraged(jTabAct, NuiBind(DC_BIND_TAB_ACTIVE_ENC));
    jTabAct = NuiHeight(jTabAct, fBtnH);
    json jTabOpen = NuiId(NuiButton(JsonString("Open tournaments")), DC_BTN_TAB_OPEN);
    jTabOpen = NuiEncouraged(jTabOpen, NuiBind(DC_BIND_TAB_OPEN_ENC));
    jTabOpen = NuiHeight(jTabOpen, fBtnH);
    json jTabHis = NuiId(NuiButton(JsonString("History")), DC_BTN_TAB_HISTORY);
    jTabHis = NuiEncouraged(jTabHis, NuiBind(DC_BIND_TAB_HISTORY_ENC));
    jTabHis = NuiHeight(jTabHis, fBtnH);

    json jTabRow = JsonArray();
    jTabRow = JsonArrayInsert(jTabRow, jTabAct);
    jTabRow = JsonArrayInsert(jTabRow, jTabOpen);
    jTabRow = JsonArrayInsert(jTabRow, jTabHis);

    json jPrimary = NuiId(NuiButton(NuiBind(DC_BIND_BTN_LBL)), DC_BTN_PRIMARY);
    jPrimary = NuiEnabled(jPrimary, NuiBind(DC_BIND_BTN_ENA));
    jPrimary = NuiHeight(jPrimary, fBtnH);

    json jEmpty = NuiLabel(NuiBind(DC_BIND_EMPTY_TXT),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jEmpty = NuiVisible(jEmpty, NuiBind(DC_BIND_EMPTY_VIS));
    jEmpty = NuiHeight(jEmpty, GetNuiScaleDimension(oPC, 50.0));

    json jList = NuiList(JsonArrayInsert(JsonArray(), BuildDcRowCell(oPC)),
        GetNuiScaleDimension(oPC, 28.0));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTopRow));
    jCol = JsonArrayInsert(jCol, jHdr);
    jCol = JsonArrayInsert(jCol, NuiRow(jTabRow));
    jCol = JsonArrayInsert(jCol, jPrimary);
    jCol = JsonArrayInsert(jCol, jEmpty);
    jCol = JsonArrayInsert(jCol, jList);

    json jNui = NuiWindow(NuiCol(jCol),
        NuiBind(WINDOW_TITLE), NuiBind(WINDOW_GEOMETRY),
        JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE), JsonBool(TRUE));

    int nTk = NuiCreate(oPC, jNui, DC_WINDOW, DC_EV_SCRIPT);
    NuiSetBind(oPC, nTk, WINDOW_TITLE, JsonString("Drinking Tournament"));
    NuiSetBind(oPC, nTk, WINDOW_GEOMETRY, NuiRect(-1.0, -1.0, fW, fH));
    NuiSetBind(oPC, nTk, DC_BIND_TITLE, JsonString("Tavern Brackets"));

    FeedDcMain(oPC, nTk);
}

// ----------------------------------------------------------------
// Feeds per tab
// ----------------------------------------------------------------

void DcFeedRows(object oPC, int nToken,
                json jPrim, json jSec, json jRight, json jColors)
{
    NuiSetBind(oPC, nToken, DC_BIND_ROW_PRIM,  jPrim);
    NuiSetBind(oPC, nToken, DC_BIND_ROW_SEC,   jSec);
    NuiSetBind(oPC, nToken, DC_BIND_ROW_RIGHT, jRight);
    NuiSetBind(oPC, nToken, DC_BIND_ROW_COLOR, jColors);
}

void FeedDcActive(object oPC, int nToken)
{
    string sUuid = GetObjectUUID(oPC);
    int nT = DcGetActiveTournamentForPC(sUuid);

    if(nT == 0)
    {
        DcFeedRows(oPC, nToken, JsonArray(), JsonArray(), JsonArray(), JsonArray());
        NuiSetBind(oPC, nToken, DC_BIND_HEADER,
            JsonString("You are not entered in any active tournament."));
        NuiSetBind(oPC, nToken, DC_BIND_BTN_LBL, JsonString("Create tournament"));
        NuiSetBind(oPC, nToken, DC_BIND_BTN_ENA, JsonBool(TRUE));
        NuiSetBind(oPC, nToken, DC_BIND_EMPTY_VIS, JsonBool(TRUE));
        NuiSetBind(oPC, nToken, DC_BIND_EMPTY_TXT,
            JsonString("Open the Open tournaments tab to join an existing one."));
        return;
    }

    json jD = DcGetTournament(nT);
    int nSize   = JsonGetInt   (JsonObjectGet(jD, "size"));
    int nFee    = JsonGetInt   (JsonObjectGet(jD, "entry_fee"));
    int nStatus = JsonGetInt   (JsonObjectGet(jD, "status"));
    string sCr  = JsonGetString(JsonObjectGet(jD, "creator_name"));

    NuiSetBind(oPC, nToken, DC_BIND_HEADER,
        JsonString("Tournament #" + IntToString(nT) + " — " + IntToString(nSize)
            + " seats, fee " + IntToString(nFee) + " gp, host: " + sCr
            + " (" + DcStatusToString(nStatus) + ")"));

    json jPrim  = JsonArray();
    json jSec   = JsonArray();
    json jRight = JsonArray();
    json jCol   = JsonArray();

    if(nStatus == DC_STATUS_OPEN)
    {
        json jEntries = DcGetEntries(nT);
        int nCnt = JsonGetLength(jEntries);
        int i;
        for(i = 0; i < nSize; i++)
        {
            string sLine, sName, sRight;
            json jColor;
            if(i < nCnt)
            {
                json jE = JsonArrayGet(jEntries, i);
                sName  = JsonGetString(JsonObjectGet(jE, "name"));
                sLine  = "Seat " + IntToString(i + 1) + ": " + sName;
                sRight = "ready";
                jColor = NuiColor(220, 200, 120);
            }
            else
            {
                sLine  = "Seat " + IntToString(i + 1) + ": —";
                sName  = "";
                sRight = "empty";
                jColor = NuiColor(140, 140, 140);
            }
            jPrim  = JsonArrayInsert(jPrim,  JsonString(sLine));
            jSec   = JsonArrayInsert(jSec,   JsonString(""));
            jRight = JsonArrayInsert(jRight, JsonString(sRight));
            jCol   = JsonArrayInsert(jCol,   jColor);
        }

        NuiSetBind(oPC, nToken, DC_BIND_BTN_LBL, JsonString(
            DcIsEntered(nT, sUuid) ? "Already entered" : "Withdraw / no action"));
        NuiSetBind(oPC, nToken, DC_BIND_BTN_ENA, JsonBool(FALSE));
    }
    else
    {
        // Running or finished — show full bracket round by round.
        int nRounds = DcRoundsForSize(nSize);
        int r;
        for(r = 0; r < nRounds; r++)
        {
            json jMatches = DcGetMatchesForRound(nT, r);
            int nMc = JsonGetLength(jMatches);
            if(nMc == 0) continue;

            jPrim  = JsonArrayInsert(jPrim,  JsonString("— Round " + IntToString(r + 1) + " —"));
            jSec   = JsonArrayInsert(jSec,   JsonString(""));
            jRight = JsonArrayInsert(jRight, JsonString(""));
            jCol   = JsonArrayInsert(jCol,   GetNuiColorNwnGold());

            int m;
            for(m = 0; m < nMc; m++)
            {
                json jM = JsonArrayGet(jMatches, m);
                string sAName = JsonGetString(JsonObjectGet(jM, "a_name"));
                string sBName = JsonGetString(JsonObjectGet(jM, "b_name"));
                int nMSt      = JsonGetInt   (JsonObjectGet(jM, "status"));
                string sWin   = JsonGetString(JsonObjectGet(jM, "winner_name"));
                int nShots    = JsonGetInt   (JsonObjectGet(jM, "shots_played"));

                string sLine = "  M" + IntToString(m + 1) + ": "
                    + (sAName == "" ? "?" : sAName)
                    + " vs "
                    + (sBName == "" ? "?" : sBName);
                string sR = (nMSt == DC_MATCH_DONE)
                    ? sWin + " (" + IntToString(nShots) + " shots)"
                    : "pending";

                jPrim  = JsonArrayInsert(jPrim,  JsonString(sLine));
                jSec   = JsonArrayInsert(jSec,   JsonString(""));
                jRight = JsonArrayInsert(jRight, JsonString(sR));
                jCol   = JsonArrayInsert(jCol,
                    nMSt == DC_MATCH_DONE ? NuiColor(180, 220, 180) : NuiColor(200, 200, 200));
            }
        }

        NuiSetBind(oPC, nToken, DC_BIND_BTN_LBL,
            JsonString(nStatus == DC_STATUS_FINISHED
                ? "Tournament finished"
                : "Bracket in progress"));
        NuiSetBind(oPC, nToken, DC_BIND_BTN_ENA, JsonBool(FALSE));
    }

    DcFeedRows(oPC, nToken, jPrim, jSec, jRight, jCol);
    NuiSetBind(oPC, nToken, DC_BIND_EMPTY_VIS,
        JsonBool(JsonGetLength(jPrim) == 0));
    NuiSetBind(oPC, nToken, DC_BIND_EMPTY_TXT,
        JsonString("Nothing to show."));
}

void FeedDcOpen(object oPC, int nToken)
{
    string sUuid = GetObjectUUID(oPC);
    json jRows = DcListByStatus(DC_STATUS_OPEN, 20);
    int nCnt = JsonGetLength(jRows);

    NuiSetBind(oPC, nToken, DC_BIND_HEADER,
        JsonString("Open tournaments — click a row to join."));

    json jPrim  = JsonArray();
    json jSec   = JsonArray();
    json jRight = JsonArray();
    json jCol   = JsonArray();
    int i;
    for(i = 0; i < nCnt; i++)
    {
        json jR = JsonArrayGet(jRows, i);
        int nId  = JsonGetInt   (JsonObjectGet(jR, "id"));
        int nSz  = JsonGetInt   (JsonObjectGet(jR, "size"));
        int nFe  = JsonGetInt   (JsonObjectGet(jR, "entry_fee"));
        string sCr = JsonGetString(JsonObjectGet(jR, "creator_name"));
        int nE = DcCountEntries(nId);

        jPrim  = JsonArrayInsert(jPrim,
            JsonString("#" + IntToString(nId) + " — host: " + sCr));
        jSec   = JsonArrayInsert(jSec,
            JsonString("Bracket " + IntToString(nSz)
                + ", fee " + IntToString(nFe) + " gp"));
        jRight = JsonArrayInsert(jRight,
            JsonString(IntToString(nE) + "/" + IntToString(nSz)));
        jCol   = JsonArrayInsert(jCol,
            DcIsEntered(nId, sUuid) ? NuiColor(120, 220, 120) : NuiColor(220, 200, 120));
    }
    DcFeedRows(oPC, nToken, jPrim, jSec, jRight, jCol);

    NuiSetBind(oPC, nToken, DC_BIND_BTN_LBL, JsonString("Create tournament"));
    NuiSetBind(oPC, nToken, DC_BIND_BTN_ENA, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, DC_BIND_EMPTY_VIS, JsonBool(nCnt == 0));
    NuiSetBind(oPC, nToken, DC_BIND_EMPTY_TXT,
        JsonString("No open tournaments. Be the host."));
}

void FeedDcHistory(object oPC, int nToken)
{
    json jRows = DcListByStatus(DC_STATUS_FINISHED, DC_HISTORY_LIMIT);
    int nCnt = JsonGetLength(jRows);

    NuiSetBind(oPC, nToken, DC_BIND_HEADER,
        JsonString("Past champions of the tavern."));

    json jPrim  = JsonArray();
    json jSec   = JsonArray();
    json jRight = JsonArray();
    json jCol   = JsonArray();
    int i;
    for(i = 0; i < nCnt; i++)
    {
        json jR = JsonArrayGet(jRows, i);
        int nId      = JsonGetInt   (JsonObjectGet(jR, "id"));
        int nSz      = JsonGetInt   (JsonObjectGet(jR, "size"));
        int nPrize   = JsonGetInt   (JsonObjectGet(jR, "prize_pool"));
        string sWin  = JsonGetString(JsonObjectGet(jR, "winner_name"));
        string sCr   = JsonGetString(JsonObjectGet(jR, "creator_name"));

        jPrim  = JsonArrayInsert(jPrim,
            JsonString("#" + IntToString(nId) + " — " + sWin));
        jSec   = JsonArrayInsert(jSec,
            JsonString("Bracket " + IntToString(nSz) + ", host: " + sCr));
        jRight = JsonArrayInsert(jRight,
            JsonString(IntToString(nPrize) + " gp"));
        jCol   = JsonArrayInsert(jCol, GetNuiColorNwnGold());
    }
    DcFeedRows(oPC, nToken, jPrim, jSec, jRight, jCol);

    NuiSetBind(oPC, nToken, DC_BIND_BTN_LBL, JsonString("Create tournament"));
    NuiSetBind(oPC, nToken, DC_BIND_BTN_ENA, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, DC_BIND_EMPTY_VIS, JsonBool(nCnt == 0));
    NuiSetBind(oPC, nToken, DC_BIND_EMPTY_TXT,
        JsonString("No champions yet. The mug awaits."));
}

void FeedDcMain(object oPC, int nToken)
{
    int nView = GetLocalInt(oPC, DC_LVAR_VIEW);
    NuiSetBind(oPC, nToken, DC_BIND_TAB_ACTIVE_ENC,  JsonBool(nView == DC_VIEW_ACTIVE));
    NuiSetBind(oPC, nToken, DC_BIND_TAB_OPEN_ENC,    JsonBool(nView == DC_VIEW_OPEN));
    NuiSetBind(oPC, nToken, DC_BIND_TAB_HISTORY_ENC, JsonBool(nView == DC_VIEW_HISTORY));

    if(nView == DC_VIEW_ACTIVE)       FeedDcActive (oPC, nToken);
    else if(nView == DC_VIEW_OPEN)    FeedDcOpen   (oPC, nToken);
    else                              FeedDcHistory(oPC, nToken);
}

// ----------------------------------------------------------------
// Create-tournament popup
// ----------------------------------------------------------------

void DcShowCreatePopup(object oPC)
{
    int nExisting = NuiFindWindow(oPC, DC_WIN_CREATE);
    if(nExisting != 0) NuiDestroy(oPC, nExisting);

    SetLocalInt(oPC, DC_LVAR_CREATE_SIZE, 8);
    SetLocalInt(oPC, DC_LVAR_CREATE_FEE,  0);

    float fW = GetNuiScaleDimension(oPC, DC_CR_W);
    float fH = GetNuiScaleDimension(oPC, DC_CR_H);
    float fLblH = GetNuiScaleDimension(oPC, 22.0);
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);

    json jHdr = NuiLabel(JsonString("Create a drinking tournament:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHdr = NuiHeight(jHdr, fLblH);

    json jSizeLbl = NuiLabel(NuiBind(DC_BIND_CREATE_SIZE_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSizeLbl = NuiHeight(jSizeLbl, fLblH);

    json jB4  = NuiCheck(JsonString("4"),  NuiBind(DC_BIND_CREATE_SIZE_4));
    jB4  = NuiId(jB4,  DC_BTN_CREATE_SIZE_4);
    json jB8  = NuiCheck(JsonString("8"),  NuiBind(DC_BIND_CREATE_SIZE_8));
    jB8  = NuiId(jB8,  DC_BTN_CREATE_SIZE_8);
    json jB16 = NuiCheck(JsonString("16"), NuiBind(DC_BIND_CREATE_SIZE_16));
    jB16 = NuiId(jB16, DC_BTN_CREATE_SIZE_16);

    json jSizeRow = JsonArray();
    jSizeRow = JsonArrayInsert(jSizeRow, jB4);
    jSizeRow = JsonArrayInsert(jSizeRow, jB8);
    jSizeRow = JsonArrayInsert(jSizeRow, jB16);

    json jFeeLbl = NuiLabel(JsonString("Entry fee (gold):"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jFeeLbl = NuiHeight(jFeeLbl, fLblH);

    json jFee = NuiTextEdit(JsonString("0"), NuiBind(DC_BIND_CREATE_FEE_TXT), 8, FALSE);
    jFee = NuiHeight(jFee, fLblH);

    json jOk     = NuiHeight(NuiId(NuiButton(JsonString("Create & enter")),
        DC_BTN_CREATE_OK), fBtnH);
    json jCancel = NuiHeight(NuiId(NuiButton(JsonString("Cancel")),
        DC_BTN_CREATE_CANCEL), fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jOk);
    jBtnRow = JsonArrayInsert(jBtnRow, jCancel);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHdr);
    jCol = JsonArrayInsert(jCol, jSizeLbl);
    jCol = JsonArrayInsert(jCol, NuiRow(jSizeRow));
    jCol = JsonArrayInsert(jCol, jFeeLbl);
    jCol = JsonArrayInsert(jCol, jFee);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jNui = NuiWindow(NuiCol(jCol),
        JsonString("New Tournament"),
        NuiRect(-1.0, -1.0, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE), JsonBool(TRUE));
    int nTk = NuiCreate(oPC, jNui, DC_WIN_CREATE, DC_EV_SCRIPT);

    NuiSetBind(oPC, nTk, DC_BIND_CREATE_SIZE_LBL, JsonString("Bracket size:"));
    NuiSetBind(oPC, nTk, DC_BIND_CREATE_SIZE_4,   JsonBool(FALSE));
    NuiSetBind(oPC, nTk, DC_BIND_CREATE_SIZE_8,   JsonBool(TRUE));
    NuiSetBind(oPC, nTk, DC_BIND_CREATE_SIZE_16,  JsonBool(FALSE));
    NuiSetBind(oPC, nTk, DC_BIND_CREATE_FEE_TXT,  JsonString("0"));
}

void DcSelectSize(object oPC, int nToken, int nSize)
{
    SetLocalInt(oPC, DC_LVAR_CREATE_SIZE, nSize);
    NuiSetBind(oPC, nToken, DC_BIND_CREATE_SIZE_4,  JsonBool(nSize == 4));
    NuiSetBind(oPC, nToken, DC_BIND_CREATE_SIZE_8,  JsonBool(nSize == 8));
    NuiSetBind(oPC, nToken, DC_BIND_CREATE_SIZE_16, JsonBool(nSize == 16));
}

void DcSubmitCreate(object oPC, int nToken)
{
    int nSize = GetLocalInt(oPC, DC_LVAR_CREATE_SIZE);
    if(nSize != 4 && nSize != 8 && nSize != 16) nSize = 8;
    string sFee = JsonGetString(NuiGetBind(oPC, nToken, DC_BIND_CREATE_FEE_TXT));
    int nFee = StringToInt(sFee);
    if(nFee < 0) nFee = 0;

    int nId = DcCreateAndOpen(oPC, nSize, nFee);
    if(nId > 0)
    {
        NuiDestroy(oPC, nToken);
        SetLocalInt(oPC, DC_LVAR_VIEW, DC_VIEW_ACTIVE);
        int nMain = NuiFindWindow(oPC, DC_WINDOW);
        if(nMain != 0) FeedDcMain(oPC, nMain);
    }
}

#include "lib_duel_def"

void FeedDuelMain(object oPC, int nToken);

// ----------------------------------------------------------------
// Honor Duels — main window (challenge + tabs: incoming/history/ranking)
// ----------------------------------------------------------------

json BuildDuelRowCell(object oPC)
{
    float fH = GetNuiScaleDimension(oPC, 26.0);
    float fRightW = GetNuiScaleDimension(oPC, 110.0);

    json jPrim = NuiLabel(NuiBind(DUEL_BIND_ROW_PRIMARY),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jPrim = NuiStyleForegroundColor(jPrim, NuiBind(DUEL_BIND_ROW_COLOR));

    json jSec = NuiLabel(NuiBind(DUEL_BIND_ROW_SECONDARY),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSec = NuiStyleForegroundColor(jSec, NuiBind(DUEL_BIND_ROW_COLOR));

    json jRight = NuiLabel(NuiBind(DUEL_BIND_ROW_RIGHT),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jRight = NuiWidth(jRight, fRightW);
    jRight = NuiStyleForegroundColor(jRight, NuiBind(DUEL_BIND_ROW_COLOR));

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jPrim);
    jRow = JsonArrayInsert(jRow, jSec);
    jRow = JsonArrayInsert(jRow, jRight);

    json jCell = NuiGroup(NuiRow(jRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, DUEL_BTN_ROW);
    jCell = NuiHeight(jCell, fH);
    return jCell;
}

void CreateDuelMainWindow(object oPC)
{
    int nExisting = NuiFindWindow(oPC, DUEL_WINDOW);
    if(nExisting != 0)
    {
        FeedDuelMain(oPC, nExisting);
        return;
    }

    SetLocalInt(oPC, DUEL_LVAR_VIEW, DUEL_VIEW_INCOMING);

    float fW = GetNuiScaleDimension(oPC, DUEL_W);
    float fH = GetNuiScaleDimension(oPC, DUEL_H);
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fLblH = GetNuiScaleDimension(oPC, 22.0);

    // -- Top: title + close --
    json jTitle = NuiLabel(NuiBind(DUEL_BIND_TITLE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);

    json jClose = NuiButton(JsonString("Zamknij"));
    jClose = NuiId(jClose, DUEL_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 90.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitle);
    jTopRow = JsonArrayInsert(jTopRow, jClose);

    // -- Honor / record line --
    json jHonor = NuiLabel(NuiBind(DUEL_BIND_HONOR_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHonor = NuiStyleForegroundColor(jHonor, GetNuiColorNwnGold());
    jHonor = NuiHeight(jHonor, fLblH);

    json jRecord = NuiLabel(NuiBind(DUEL_BIND_RECORD_LBL),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jRecord = NuiHeight(jRecord, fLblH);

    json jStatRow = JsonArray();
    jStatRow = JsonArrayInsert(jStatRow, jHonor);
    jStatRow = JsonArrayInsert(jStatRow, jRecord);

    // -- Challenge button --
    json jChallenge = NuiButton(JsonString("Rzuc rekawice (wybierz cel)"));
    jChallenge = NuiId(jChallenge, DUEL_BTN_CHALLENGE);
    jChallenge = NuiHeight(jChallenge, fBtnH);

    // -- Tabs --
    json jTabInc = NuiButton(JsonString("Wyzwania"));
    jTabInc = NuiId(jTabInc, DUEL_BTN_TAB_INCOMING);
    jTabInc = NuiEncouraged(jTabInc, NuiBind(DUEL_BIND_TAB_INCOMING_ENC));
    jTabInc = NuiHeight(jTabInc, fBtnH);

    json jTabHis = NuiButton(JsonString("Historia"));
    jTabHis = NuiId(jTabHis, DUEL_BTN_TAB_HISTORY);
    jTabHis = NuiEncouraged(jTabHis, NuiBind(DUEL_BIND_TAB_HISTORY_ENC));
    jTabHis = NuiHeight(jTabHis, fBtnH);

    json jTabRnk = NuiButton(JsonString("Ranking honoru"));
    jTabRnk = NuiId(jTabRnk, DUEL_BTN_TAB_RANKING);
    jTabRnk = NuiEncouraged(jTabRnk, NuiBind(DUEL_BIND_TAB_RANKING_ENC));
    jTabRnk = NuiHeight(jTabRnk, fBtnH);

    json jTabRow = JsonArray();
    jTabRow = JsonArrayInsert(jTabRow, jTabInc);
    jTabRow = JsonArrayInsert(jTabRow, jTabHis);
    jTabRow = JsonArrayInsert(jTabRow, jTabRnk);

    // -- List --
    json jList = NuiList(JsonArrayInsert(JsonArray(), BuildDuelRowCell(oPC)),
        GetNuiScaleDimension(oPC, 28.0));

    // -- Empty placeholder (only visible when list empty) --
    json jEmpty = NuiLabel(NuiBind(DUEL_BIND_EMPTY_TXT),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jEmpty = NuiVisible(jEmpty, NuiBind(DUEL_BIND_EMPTY_VIS));
    jEmpty = NuiHeight(jEmpty, GetNuiScaleDimension(oPC, 60.0));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTopRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jStatRow));
    jCol = JsonArrayInsert(jCol, jChallenge);
    jCol = JsonArrayInsert(jCol, NuiRow(jTabRow));
    jCol = JsonArrayInsert(jCol, jEmpty);
    jCol = JsonArrayInsert(jCol, jList);

    json jRoot = NuiCol(jCol);

    json jNui = NuiWindow(jRoot,
        NuiBind(WINDOW_TITLE),
        NuiBind(WINDOW_GEOMETRY),
        JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE), JsonBool(TRUE));

    int nTk = NuiCreate(oPC, jNui, DUEL_WINDOW, DUEL_EV_SCRIPT);

    NuiSetBind(oPC, nTk, WINDOW_TITLE,
        JsonString("Honorowe Pojedynki"));
    NuiSetBind(oPC, nTk, WINDOW_GEOMETRY,
        NuiRect(-1.0, -1.0, fW, fH));
    NuiSetBind(oPC, nTk, DUEL_BIND_TITLE,
        JsonString("Honorowe Pojedynki"));

    FeedDuelMain(oPC, nTk);
}

// ----------------------------------------------------------------
// Feed: re-populates the list bindings based on selected view
// ----------------------------------------------------------------

void DuelFeedRows(object oPC, int nToken,
                  json jPrimary, json jSecondary, json jRight, json jColors)
{
    NuiSetBind(oPC, nToken, DUEL_BIND_ROW_PRIMARY,   jPrimary);
    NuiSetBind(oPC, nToken, DUEL_BIND_ROW_SECONDARY, jSecondary);
    NuiSetBind(oPC, nToken, DUEL_BIND_ROW_RIGHT,     jRight);
    NuiSetBind(oPC, nToken, DUEL_BIND_ROW_COLOR,     jColors);
}

void FeedDuelIncoming(object oPC, int nToken)
{
    json jRows = DuelGetIncoming(GetObjectUUID(oPC));
    int nCnt = JsonGetLength(jRows);

    json jPrim = JsonArray();
    json jSec  = JsonArray();
    json jRight= JsonArray();
    json jCol  = JsonArray();

    int i;
    for(i = 0; i < nCnt; i++)
    {
        json jR = JsonArrayGet(jRows, i);
        string sDir   = JsonGetString(JsonObjectGet(jR, "direction"));
        string sName  = JsonGetString(JsonObjectGet(jR, "challenger_name"));
        int nWin      = JsonGetInt   (JsonObjectGet(jR, "win_cond"));
        int nRules    = JsonGetInt   (JsonObjectGet(jR, "rules_mask"));
        int nStake    = JsonGetInt   (JsonObjectGet(jR, "stake_gold"));
        int nStatus   = JsonGetInt   (JsonObjectGet(jR, "status"));

        string sPrefix = (sDir == "in") ? "Od: " : "Do: ";
        string sStatus = (nStatus == DUEL_STATUS_PENDING) ? "[oczekuje]" : "[przyjete]";

        jPrim  = JsonArrayInsert(jPrim, JsonString(sPrefix + sName + " " + sStatus));
        jSec   = JsonArrayInsert(jSec,
            JsonString(DuelWinConditionToString(nWin) + " | " + DuelRulesToString(nRules)));
        jRight = JsonArrayInsert(jRight,
            JsonString(nStake > 0 ? IntToString(nStake) + " zl" : "—"));

        json jColor = (sDir == "in") ? NuiColor(220, 200, 120) : NuiColor(150, 150, 200);
        jCol   = JsonArrayInsert(jCol, jColor);
    }

    DuelFeedRows(oPC, nToken, jPrim, jSec, jRight, jCol);

    NuiSetBind(oPC, nToken, DUEL_BIND_EMPTY_VIS, JsonBool(nCnt == 0));
    NuiSetBind(oPC, nToken, DUEL_BIND_EMPTY_TXT,
        JsonString("Zadnych aktywnych wyzwan. Rzuc rekawice komus z dobrych dlonia mieczem."));
}

void FeedDuelHistory(object oPC, int nToken)
{
    string sUuid = GetObjectUUID(oPC);
    json jRows = DuelGetHistory(sUuid, DUEL_HISTORY_LIMIT);
    int nCnt = JsonGetLength(jRows);

    json jPrim = JsonArray();
    json jSec  = JsonArray();
    json jRight= JsonArray();
    json jCol  = JsonArray();

    int i;
    for(i = 0; i < nCnt; i++)
    {
        json jR = JsonArrayGet(jRows, i);
        string sCu = JsonGetString(JsonObjectGet(jR, "challenger_uuid"));
        string sCn = JsonGetString(JsonObjectGet(jR, "challenger_name"));
        string sDn = JsonGetString(JsonObjectGet(jR, "challenged_name"));
        string sWn = JsonGetString(JsonObjectGet(jR, "winner_uuid"));
        int nStatus = JsonGetInt(JsonObjectGet(jR, "status"));
        int nWinC   = JsonGetInt(JsonObjectGet(jR, "win_cond"));
        int nDate   = JsonGetInt(JsonObjectGet(jR, "completed_at"));
        string sNote= JsonGetString(JsonObjectGet(jR, "outcome_note"));

        string sOpp = (sCu == sUuid) ? sDn : sCn;
        string sLine = "";
        json jColor;
        if(nStatus == DUEL_STATUS_COMPLETED && sWn == sUuid)
        {
            sLine = "Zwyciestwo nad " + sOpp;
            jColor = NuiColor(120, 220, 120);
        }
        else if(nStatus == DUEL_STATUS_COMPLETED)
        {
            sLine = "Porazka z " + sOpp;
            jColor = NuiColor(220, 120, 120);
        }
        else if(nStatus == DUEL_STATUS_DECLINED)
        {
            sLine = "Odrzucone z " + sOpp;
            jColor = NuiColor(170, 170, 170);
        }
        else if(nStatus == DUEL_STATUS_CANCELED)
        {
            sLine = "Anulowane z " + sOpp;
            jColor = NuiColor(170, 170, 170);
        }
        else
        {
            sLine = "Wygaslo z " + sOpp;
            jColor = NuiColor(170, 170, 170);
        }

        jPrim  = JsonArrayInsert(jPrim, JsonString(sLine));
        jSec   = JsonArrayInsert(jSec,
            JsonString(DuelWinConditionToString(nWinC) + (sNote != "" ? " | " + sNote : "")));
        jRight = JsonArrayInsert(jRight,
            JsonString(DuelFormatDateSQL(nDate)));
        jCol   = JsonArrayInsert(jCol, jColor);
    }

    DuelFeedRows(oPC, nToken, jPrim, jSec, jRight, jCol);

    NuiSetBind(oPC, nToken, DUEL_BIND_EMPTY_VIS, JsonBool(nCnt == 0));
    NuiSetBind(oPC, nToken, DUEL_BIND_EMPTY_TXT,
        JsonString("Brak zapisanych pojedynkow. Twoja karta honoru jest jeszcze pusta."));
}

void FeedDuelRanking(object oPC, int nToken)
{
    json jRows = DuelGetRanking(DUEL_RANKING_LIMIT);
    int nCnt = JsonGetLength(jRows);

    json jPrim = JsonArray();
    json jSec  = JsonArray();
    json jRight= JsonArray();
    json jCol  = JsonArray();

    int i;
    for(i = 0; i < nCnt; i++)
    {
        json jR = JsonArrayGet(jRows, i);
        string sName = JsonGetString(JsonObjectGet(jR, "char_name"));
        int nHonor   = JsonGetInt   (JsonObjectGet(jR, "honor"));
        int nWins    = JsonGetInt   (JsonObjectGet(jR, "wins"));
        int nLosses  = JsonGetInt   (JsonObjectGet(jR, "losses"));
        int nKills   = JsonGetInt   (JsonObjectGet(jR, "kills"));

        jPrim = JsonArrayInsert(jPrim,
            JsonString(IntToString(i + 1) + ". " + sName));
        jSec  = JsonArrayInsert(jSec,
            JsonString("W: " + IntToString(nWins) + " | P: " + IntToString(nLosses)
                + " | Glowy: " + IntToString(nKills)));
        jRight= JsonArrayInsert(jRight,
            JsonString("Honor " + IntToString(nHonor)));

        json jColor;
        if(i == 0)      jColor = NuiColor(255, 215, 0);
        else if(i == 1) jColor = NuiColor(192, 192, 192);
        else if(i == 2) jColor = NuiColor(205, 127, 50);
        else            jColor = NuiColor(220, 220, 220);
        jCol  = JsonArrayInsert(jCol, jColor);
    }

    DuelFeedRows(oPC, nToken, jPrim, jSec, jRight, jCol);

    NuiSetBind(oPC, nToken, DUEL_BIND_EMPTY_VIS, JsonBool(nCnt == 0));
    NuiSetBind(oPC, nToken, DUEL_BIND_EMPTY_TXT,
        JsonString("Nikt jeszcze nie skrzyzowal mieczy."));
}

void FeedDuelMain(object oPC, int nToken)
{
    string sUuid = GetObjectUUID(oPC);
    json jH = DuelGetHonorRow(sUuid);
    int nHonor = 0, nWins = 0, nLosses = 0, nKills = 0;
    if(JsonGetType(jH) != JSON_TYPE_NULL)
    {
        nHonor  = JsonGetInt(JsonObjectGet(jH, "honor"));
        nWins   = JsonGetInt(JsonObjectGet(jH, "wins"));
        nLosses = JsonGetInt(JsonObjectGet(jH, "losses"));
        nKills  = JsonGetInt(JsonObjectGet(jH, "kills"));
    }

    NuiSetBind(oPC, nToken, DUEL_BIND_HONOR_LBL,
        JsonString("Honor: " + IntToString(nHonor)));
    NuiSetBind(oPC, nToken, DUEL_BIND_RECORD_LBL,
        JsonString("W: " + IntToString(nWins) + " / P: " + IntToString(nLosses)
            + " / Glowy: " + IntToString(nKills)));

    int nView = GetLocalInt(oPC, DUEL_LVAR_VIEW);
    NuiSetBind(oPC, nToken, DUEL_BIND_TAB_INCOMING_ENC, JsonBool(nView == DUEL_VIEW_INCOMING));
    NuiSetBind(oPC, nToken, DUEL_BIND_TAB_HISTORY_ENC,  JsonBool(nView == DUEL_VIEW_HISTORY));
    NuiSetBind(oPC, nToken, DUEL_BIND_TAB_RANKING_ENC,  JsonBool(nView == DUEL_VIEW_RANKING));

    if(nView == DUEL_VIEW_INCOMING)      FeedDuelIncoming(oPC, nToken);
    else if(nView == DUEL_VIEW_HISTORY)  FeedDuelHistory (oPC, nToken);
    else                                 FeedDuelRanking (oPC, nToken);
}

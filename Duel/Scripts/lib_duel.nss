// lib_duel.nss
// Honor Duels - all NUI window builders + feed functions:
//  - main window: Honor + W/L stats, sword (challenge) icon, History tab
//    icon, Ranking tab icon, list of rows, X close
//  - challenge confirm popup: shown to challenger after they pick a target
//  - incoming popup: shown to the challenged player when a challenge arrives
// Both popups share CreateDuelPopup() helper - single source of truth for
// popup geometry, label height, button height.
// HUD overlay window lives in lib_duel_hud, info/rules window in lib_duel_inf.
#include "lib_duel_def"

// ============================================================
// Shared row cell for the main list (3 labels + color bind)
// ============================================================
json BuildDuelRowCell(object oPC)
{
    float fH      = GetNuiScaleDimension(oPC, 28.0);
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

// ============================================================
// Main window
// ============================================================
void CreateDuelMainWindow(object oPC)
{
    int nExisting = NuiFindWindow(oPC, DUEL_WINDOW);
    if(nExisting != 0)
    {
        FeedDuelMain(oPC, nExisting);
        return;
    }

    SetLocalInt(oPC, DUEL_LVAR_VIEW, DUEL_VIEW_HISTORY);

    float fW       = GetNuiScaleDimension(oPC, DUEL_W);
    float fH       = GetNuiScaleDimension(oPC, DUEL_H);
    float fLblH    = GetNuiScaleDimension(oPC, 22.0);
    float fIconSz  = GetNuiScaleDimension(oPC, 40.0);
    float fIconGap = GetNuiScaleDimension(oPC, 8.0);
    float fSidePad = GetNuiScaleDimension(oPC, 110.0);

    // ============================================================
    // X close (placed in top-right of stat row to save vertical space)
    // ============================================================
    json jXClose = NuiButton(JsonString("X"));
    jXClose = NuiId(jXClose, DUEL_BTN_CLOSE);
    jXClose = NuiWidth(jXClose, GetNuiScaleDimension(oPC, 30.0));
    jXClose = NuiHeight(jXClose, GetNuiScaleDimension(oPC, 30.0));

    // ============================================================
    // Plaque content: stat row (Honor + W:L + X) above icon row
    // ============================================================
    json jHonor = NuiLabel(NuiBind(DUEL_BIND_HONOR_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHonor = NuiHeight(jHonor, fLblH);
    jHonor = NuiWidth(jHonor, GetNuiScaleDimension(oPC, 100.0));

    json jRecord = NuiLabel(NuiBind(DUEL_BIND_RECORD_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jRecord = NuiHeight(jRecord, fLblH);
    jRecord = NuiWidth(jRecord, GetNuiScaleDimension(oPC, 110.0));

    // Icon: Challenge a player (action - opens targeting mode)
    json jIcoSword = NuiButtonImage(JsonString("duel_ico_sword"));
    jIcoSword = NuiId(jIcoSword, DUEL_BTN_CHALLENGE);
    jIcoSword = NuiWidth(jIcoSword, fIconSz);
    jIcoSword = NuiHeight(jIcoSword, fIconSz);
    jIcoSword = NuiTooltip(jIcoSword, JsonString("Challenge a player"));

    // Icon: History tab
    json jIcoBook = NuiButtonImage(JsonString("duel_ico_book"));
    jIcoBook = NuiId(jIcoBook, DUEL_BTN_TAB_HISTORY);
    jIcoBook = NuiWidth(jIcoBook, fIconSz);
    jIcoBook = NuiHeight(jIcoBook, fIconSz);
    jIcoBook = NuiEncouraged(jIcoBook, NuiBind(DUEL_BIND_TAB_HIS_ENC));
    jIcoBook = NuiTooltip(jIcoBook, JsonString("History"));

    // Icon: Ranking tab
    json jIcoCup = NuiButtonImage(JsonString("duel_ico_cup"));
    jIcoCup = NuiId(jIcoCup, DUEL_BTN_TAB_RANKING);
    jIcoCup = NuiWidth(jIcoCup, fIconSz);
    jIcoCup = NuiHeight(jIcoCup, fIconSz);
    jIcoCup = NuiEncouraged(jIcoCup, NuiBind(DUEL_BIND_TAB_RNK_ENC));
    jIcoCup = NuiTooltip(jIcoCup, JsonString("Ranking"));

    // YELLOW row: just X close button at top-right (positioned freely, NO bg here)
    json jXRow = JsonArray();
    jXRow = JsonArrayInsert(jXRow, NuiSpacer());
    jXRow = JsonArrayInsert(jXRow, jXClose);

    // Stat row: fixed left spacer pushes Honor toward center; elastic right absorbs rest.
    json jStatRow = JsonArray();
    jStatRow = JsonArrayInsert(jStatRow, NuiWidth(NuiSpacer(), GetNuiScaleDimension(oPC, 310.0)));
    jStatRow = JsonArrayInsert(jStatRow, jHonor);
    jStatRow = JsonArrayInsert(jStatRow, NuiWidth(NuiSpacer(), GetNuiScaleDimension(oPC, 70.0)));
    jStatRow = JsonArrayInsert(jStatRow, jRecord);
    jStatRow = JsonArrayInsert(jStatRow, NuiSpacer());

    // Icon row (separate, below pink) - 4 icons spread evenly within plaque area.
    // Wide side margins constrain icons to plaque width; elastic spacers between
    // distribute the icons equally across that area.
    float fIconSidePad = GetNuiScaleDimension(oPC, 280.0);

    json jIconRow = JsonArray();
    jIconRow = JsonArrayInsert(jIconRow, NuiWidth(NuiSpacer(), fIconSidePad));
    jIconRow = JsonArrayInsert(jIconRow, jIcoSword);
    jIconRow = JsonArrayInsert(jIconRow, NuiSpacer());
    jIconRow = JsonArrayInsert(jIconRow, jIcoBook);
    jIconRow = JsonArrayInsert(jIconRow, NuiSpacer());
    jIconRow = JsonArrayInsert(jIconRow, jIcoCup);
    jIconRow = JsonArrayInsert(jIconRow, NuiWidth(NuiSpacer(), fIconSidePad));

    // ============================================================
    // List (with side padding so it stays inside inner frame)
    // ============================================================
    json jList = NuiList(
        JsonArrayInsert(JsonArray(), NuiListTemplateCell(BuildDuelRowCell(oPC), 0.0, TRUE)),
        NuiBind(DUEL_BIND_ROW_COUNT),
        GetNuiScaleDimension(oPC, 28.0));
    // Explicit list height - DUEL_H minus other vertical elements (X row + paddings + stat + icons + bottom).
    jList = NuiHeight(jList, fH - GetNuiScaleDimension(oPC, 300.0));

    json jListRow = JsonArray();
    jListRow = JsonArrayInsert(jListRow, NuiWidth(NuiSpacer(), fSidePad + GetNuiScaleDimension(oPC, 13.0)));
    jListRow = JsonArrayInsert(jListRow, jList);
    jListRow = JsonArrayInsert(jListRow, NuiWidth(NuiSpacer(), fSidePad));

    // ============================================================
    // PINK GROUP: all content (stats, icons, list) wrapped in a col
    // with the bg image as DrawList overlay. This isolates the bg from
    // the X close row so X can be positioned freely.
    // ============================================================
    json jPinkContent = JsonArray();
    jPinkContent = JsonArrayInsert(jPinkContent, NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, 25.0)));
    jPinkContent = JsonArrayInsert(jPinkContent, NuiRow(jStatRow));
    jPinkContent = JsonArrayInsert(jPinkContent, NuiRow(jIconRow));
    jPinkContent = JsonArrayInsert(jPinkContent, NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, 25.0)));
    jPinkContent = JsonArrayInsert(jPinkContent, NuiRow(jListRow));
    // jPinkContent = JsonArrayInsert(jPinkContent, NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, 50.0)));
    jPinkContent = JsonArrayInsert(jPinkContent, NuiSpacer());

    // BG image overlay - applied to pink group only, NOT root.
    json jBgImage = NuiDrawListImage(
        JsonBool(TRUE),
        JsonString("duel_bg"),
        NuiRect(0.0, 0.0, fW, fH - GetNuiScaleDimension(oPC, 100.0)),
        JsonInt(NUI_ASPECT_STRETCH),        // fill pink area (may crop sides)
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_TOP),
        NUI_DRAW_LIST_ITEM_ORDER_BEFORE,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);
    json jPinkDrawList = JsonArrayInsert(JsonArray(), jBgImage);

    json jPinkGroup = NuiCol(jPinkContent);
    jPinkGroup = NuiDrawList(jPinkGroup, JsonBool(FALSE), jPinkDrawList);

    // ============================================================
    // ROOT = [Yellow X row] + [Pink group with bg]
    // ============================================================
    json jInner = JsonArray();
    jInner = JsonArrayInsert(jInner, NuiRow(jXRow));    // YELLOW: just X, no bg
    jInner = JsonArrayInsert(jInner, jPinkGroup);       // PINK: everything else with bg overlay

    json jRoot = NuiCol(jInner);

    json jNui = NuiWindow(jRoot,
        JsonString(""),                // empty title - background art has its own plaque
        NuiRect(-1.0, -1.0, fW, fH),
        JsonBool(FALSE),  // resizable
        JsonBool(FALSE),  // collapsed
        JsonBool(FALSE),  // closable - off, hides engine title bar entirely
        JsonBool(TRUE),   // transparent - background art shows through
        JsonBool(FALSE)); // border - off, art has its own

    int nTk = NuiCreate(oPC, jNui, DUEL_WINDOW, DUEL_EV_SCRIPT);
    FeedDuelMain(oPC, nTk);
}

// ============================================================
// Feed list helpers
// ============================================================
void DuelFeedRows(object oPC, int nToken,
                  json jPrimary, json jSecondary, json jRight, json jColors)
{
    NuiSetBind(oPC, nToken, DUEL_BIND_ROW_PRIMARY,   jPrimary);
    NuiSetBind(oPC, nToken, DUEL_BIND_ROW_SECONDARY, jSecondary);
    NuiSetBind(oPC, nToken, DUEL_BIND_ROW_RIGHT,     jRight);
    NuiSetBind(oPC, nToken, DUEL_BIND_ROW_COLOR,     jColors);
    NuiSetBind(oPC, nToken, DUEL_BIND_ROW_COUNT,
               JsonInt(JsonGetLength(jPrimary)));
}

// Single-row "no entries" message inside the list (avoids dual-widget waste).
void DuelFeedEmptyRow(object oPC, int nToken, string sMessage)
{
    json jPrim  = JsonArrayInsert(JsonArray(), JsonString(sMessage));
    json jSec   = JsonArrayInsert(JsonArray(), JsonString(""));
    json jRight = JsonArrayInsert(JsonArray(), JsonString(""));
    json jCol   = JsonArrayInsert(JsonArray(), NuiColor(150, 150, 150));
    DuelFeedRows(oPC, nToken, jPrim, jSec, jRight, jCol);
}

void FeedDuelHistory(object oPC, int nToken)
{
    string sUuid = GetObjectUUID(oPC);
    json jRows = DuelGetHistory(sUuid, DUEL_HISTORY_LIMIT);
    int nCnt = JsonGetLength(jRows);

    if(nCnt == 0)
    {
        DuelFeedEmptyRow(oPC, nToken,
            "No recorded duels. Your honor ledger is still blank.");
        return;
    }

    json jPrim  = JsonArray();
    json jSec   = JsonArray();
    json jRight = JsonArray();
    json jCol   = JsonArray();

    int i;
    for(i = 0; i < nCnt; i++)
    {
        json jR = JsonArrayGet(jRows, i);
        string sCu = JsonGetString(JsonObjectGet(jR, "challenger_uuid"));
        string sCn = JsonGetString(JsonObjectGet(jR, "challenger_name"));
        string sDn = JsonGetString(JsonObjectGet(jR, "challenged_name"));
        string sWn = JsonGetString(JsonObjectGet(jR, "winner_uuid"));
        int nStatus  = JsonGetInt(JsonObjectGet(jR, "status"));
        int nOutcome = JsonGetInt(JsonObjectGet(jR, "outcome_type"));
        int nDate    = JsonGetInt(JsonObjectGet(jR, "completed_at"));

        string sOpp = (sCu == sUuid) ? sDn : sCn;
        string sLine = "";
        json jColor;

        if(nStatus == DUEL_STATUS_COMPLETED && sWn == sUuid)
        {
            sLine = "Victory over " + sOpp;
            jColor = (nOutcome == DUEL_OUTCOME_KILL)
                ? NuiColor(120, 220, 120)   // bright green = kill win
                : NuiColor( 80, 180,  80);  // dim green = flee win
        }
        else if(nStatus == DUEL_STATUS_COMPLETED)
        {
            sLine = "Defeat by " + sOpp;
            jColor = (nOutcome == DUEL_OUTCOME_FLEE)
                ? NuiColor(220,  60,  60)   // bright red = forfeit
                : NuiColor(180,  90,  90);  // dim red = killed
        }
        else if(nStatus == DUEL_STATUS_DECLINED)
        {
            sLine = "Declined with " + sOpp;
            jColor = NuiColor(170, 170, 170);
        }
        else if(nStatus == DUEL_STATUS_CANCELED)
        {
            sLine = "Canceled with " + sOpp;
            jColor = NuiColor(170, 170, 170);
        }
        else
        {
            sLine = "Expired with " + sOpp;
            jColor = NuiColor(170, 170, 170);
        }

        jPrim  = JsonArrayInsert(jPrim, JsonString(sLine));
        jSec   = JsonArrayInsert(jSec,
            JsonString("By " + DuelOutcomeToString(nOutcome)));
        jRight = JsonArrayInsert(jRight, JsonString(DuelFormatDateSQL(nDate)));
        jCol   = JsonArrayInsert(jCol, jColor);
    }

    DuelFeedRows(oPC, nToken, jPrim, jSec, jRight, jCol);
}

void FeedDuelRanking(object oPC, int nToken)
{
    json jRows = DuelGetRanking(DUEL_RANKING_LIMIT);
    int nCnt = JsonGetLength(jRows);

    if(nCnt == 0)
    {
        DuelFeedEmptyRow(oPC, nToken, "No one has yet crossed swords.");
        return;
    }

    json jPrim  = JsonArray();
    json jSec   = JsonArray();
    json jRight = JsonArray();
    json jCol   = JsonArray();

    int i;
    for(i = 0; i < nCnt; i++)
    {
        json jR = JsonArrayGet(jRows, i);
        string sName = JsonGetString(JsonObjectGet(jR, "char_name"));
        int nHonor   = JsonGetInt   (JsonObjectGet(jR, "honor"));
        int nWk      = JsonGetInt   (JsonObjectGet(jR, "wins_by_kill"));
        int nWf      = JsonGetInt   (JsonObjectGet(jR, "wins_by_flee"));
        int nLk      = JsonGetInt   (JsonObjectGet(jR, "losses_by_kill"));
        int nLf      = JsonGetInt   (JsonObjectGet(jR, "losses_by_flee"));

        jPrim = JsonArrayInsert(jPrim,
            JsonString(IntToString(i + 1) + ". " + sName));
        jSec  = JsonArrayInsert(jSec,
            JsonString("W: " + IntToString(nWk + nWf)
                + " (" + IntToString(nWk) + "K/" + IntToString(nWf) + "F)"
                + " | L: " + IntToString(nLk + nLf)
                + " (" + IntToString(nLk) + "K/" + IntToString(nLf) + "F)"));
        jRight = JsonArrayInsert(jRight,
            JsonString("Honor " + IntToString(nHonor)));

        json jColor;
        if(i == 0)      jColor = NuiColor(255, 215,   0);  // gold
        else if(i == 1) jColor = NuiColor(192, 192, 192);  // silver
        else if(i == 2) jColor = NuiColor(205, 127,  50);  // bronze
        else            jColor = NuiColor(220, 220, 220);
        jCol  = JsonArrayInsert(jCol, jColor);
    }

    DuelFeedRows(oPC, nToken, jPrim, jSec, jRight, jCol);
}

void FeedDuelMain(object oPC, int nToken)
{
    string sUuid = GetObjectUUID(oPC);
    json jH = DuelGetHonorRow(sUuid);
    int nHonor = 0, nWins = 0, nLosses = 0;
    if(JsonGetType(jH) != JSON_TYPE_NULL)
    {
        nHonor  = JsonGetInt(JsonObjectGet(jH, "honor"));
        nWins   = JsonGetInt(JsonObjectGet(jH, "wins"));
        nLosses = JsonGetInt(JsonObjectGet(jH, "losses"));
    }

    NuiSetBind(oPC, nToken, DUEL_BIND_HONOR_LBL,
        JsonString("Honor: " + IntToString(nHonor)));
    NuiSetBind(oPC, nToken, DUEL_BIND_RECORD_LBL,
        JsonString("W: " + IntToString(nWins) + " / L: " + IntToString(nLosses)));

    int nView = GetLocalInt(oPC, DUEL_LVAR_VIEW);

    // Active tab indicator (project standard) - encouraged on the active icon.
    NuiSetBind(oPC, nToken, DUEL_BIND_TAB_HIS_ENC,
        JsonBool(nView == DUEL_VIEW_HISTORY));
    NuiSetBind(oPC, nToken, DUEL_BIND_TAB_RNK_ENC,
        JsonBool(nView == DUEL_VIEW_RANKING));

    if(nView == DUEL_VIEW_RANKING) FeedDuelRanking(oPC, nToken);
    else                           FeedDuelHistory(oPC, nToken);
}

// ============================================================
// Challenge confirm popup (asks once before sending)
// ============================================================
// Shared two-button popup (challenge confirm + incoming popup)
// ============================================================
// All popups in this system share identical geometry, label height, and
// button height. Differences are only the title bar string, the dynamic
// label bind, the two button IDs/labels, and the window ID.
// Returns the NUI token so callers can set their dynamic label bind.
int CreateDuelPopup(object oPC, string sWinId, string sTitle, string sLblBind,
                    string sBtnLeftId,  string sBtnLeftLbl,
                    string sBtnRightId, string sBtnRightLbl)
{
    int nExisting = NuiFindWindow(oPC, sWinId);
    if(nExisting != 0) NuiDestroy(oPC, nExisting);

    float fW    = GetNuiScaleDimension(oPC, DUEL_POPUP_W);
    float fH    = GetNuiScaleDimension(oPC, DUEL_POPUP_H);
    float fLblH = GetNuiScaleDimension(oPC, 22.0);
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);

    json jLbl = NuiLabel(NuiBind(sLblBind),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLbl = NuiHeight(jLbl, fLblH);

    json jLeft = NuiButton(JsonString(sBtnLeftLbl));
    jLeft = NuiId(jLeft, sBtnLeftId);
    jLeft = NuiHeight(jLeft, fBtnH);

    json jRight = NuiButton(JsonString(sBtnRightLbl));
    jRight = NuiId(jRight, sBtnRightId);
    jRight = NuiHeight(jRight, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jLeft);
    jBtnRow = JsonArrayInsert(jBtnRow, jRight);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jLbl);
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jNui = NuiWindow(NuiCol(jCol),
        JsonString(sTitle),
        NuiRect(-1.0, -1.0, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE), JsonBool(TRUE));

    return NuiCreate(oPC, jNui, sWinId, DUEL_EV_SCRIPT);
}

// ============================================================
// Challenge confirm popup
// ============================================================
void DuelShowChallengeConfig(object oPC, string sTargetUuid, string sTargetName)
{
    SetLocalString(oPC, DUEL_LVAR_DRAFT_TARGET, sTargetUuid);
    SetLocalString(oPC, DUEL_LVAR_DRAFT_NAME,   sTargetName);

    int nTk = CreateDuelPopup(oPC, DUEL_WIN_CHALLENGE,
        "Challenge to a duel", DUEL_BIND_CH_TARGET_LBL,
        DUEL_BTN_CH_SEND,   "Challenge",
        DUEL_BTN_CH_CANCEL, "Cancel");

    NuiSetBind(oPC, nTk, DUEL_BIND_CH_TARGET_LBL,
        JsonString("Challenging: " + sTargetName));
}

// ============================================================
// Incoming challenge popup
// ============================================================
void DuelShowIncomingPopup(object oPC, int nDuelId)
{
    json jD = DuelGetById(nDuelId);
    if(JsonGetType(jD) == JSON_TYPE_NULL) return;

    SetLocalInt(oPC, DUEL_LVAR_INCOMING_ID, nDuelId);
    string sName = JsonGetString(JsonObjectGet(jD, "challenger_name"));

    int nTk = CreateDuelPopup(oPC, DUEL_WIN_INCOMING,
        "Challenge", DUEL_BIND_INC_TITLE,
        DUEL_BTN_INC_ACCEPT,  "Accept",
        DUEL_BTN_INC_DECLINE, "Decline");

    NuiSetBind(oPC, nTk, DUEL_BIND_INC_TITLE,
        JsonString(sName + " challenges you."));
}

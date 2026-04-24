#include "lib_mail_def"

void CreateMailWindow(object oPC);
void SwapToInboxView(object oPC, int nToken);
void SwapToComposeView(object oPC, int nToken);
void FeedMailInboxList(object oPC, int nToken);
void FeedMailInbox(object oPC, int nToken);
void FeedMailBody(object oPC, int nToken, int nMailId);
void FeedMailCompose(object oPC, int nToken);
void FeedMailSearchResults(object oPC, int nToken);
void FeedMailSlots(object oPC, int nToken);
void MailShowNotification(object oPC);
void CreateMailSearchPopup(object oPC, json jResults);


// ----------------------------------------------------------------
// Background DrawList
// ----------------------------------------------------------------

json MailBuildBackground(object oPC)
{
    json jDl = JsonArray();
    float fW = GetNuiScaleDimension(oPC, MAIL_W);
    float fH = GetNuiScaleDimension(oPC, MAIL_H);
    jDl = JsonArrayInsert(jDl, NuiDrawListImage(
        JsonBool(TRUE),
        JsonString("mail_bg"),
        NuiRect(0.0, 0.0, fW, fH),
        JsonInt(NUI_ASPECT_FILL),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE),
        NUI_DRAW_LIST_ITEM_ORDER_BEFORE,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
    return jDl;
}

// ----------------------------------------------------------------
// Inbox view
// ----------------------------------------------------------------

json BuildMailInboxView(object oPC)
{
    float fW    = GetNuiScaleDimension(oPC, MAIL_W);
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fRowH = GetNuiScaleDimension(oPC, 28.0);
    float fBodyH= GetNuiScaleDimension(oPC, 175.0);

    // -- Top bar: title + Compose + Close --
    json jTitleLbl = NuiLabel(NuiBind(MAIL_BIND_TITLE), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, fBtnH);

    json jComposeBtn = NuiButton(JsonString("Compose"));
    jComposeBtn = NuiId(jComposeBtn, MAIL_BTN_COMPOSE);
    jComposeBtn = NuiWidth(jComposeBtn, GetNuiScaleDimension(oPC, 90.0));
    jComposeBtn = NuiHeight(jComposeBtn, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitleLbl);
    jTopRow = JsonArrayInsert(jTopRow, jComposeBtn);

    // -- Mail list --
    // Columns: sender(140), subject(elastic), date(50), gold-icon(22), item-icon(22)
    float fSenderW = GetNuiScaleDimension(oPC, 130.0);
    float fDateW   = GetNuiScaleDimension(oPC, 50.0);
    float fIconW   = GetNuiScaleDimension(oPC, 22.0);

    json jSenderLbl = NuiLabel(NuiBind(MAIL_BIND_ROW_SENDER), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSenderLbl = NuiStyleForegroundColor(jSenderLbl, NuiBind(MAIL_BIND_ROW_COLOR));

    json jSubjLbl = NuiLabel(NuiBind(MAIL_BIND_ROW_SUBJECT), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSubjLbl = NuiStyleForegroundColor(jSubjLbl, NuiBind(MAIL_BIND_ROW_COLOR));

    json jStatusLbl = NuiLabel(NuiBind(MAIL_BIND_ROW_STATUS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiWidth(jStatusLbl, GetNuiScaleDimension(oPC, 36.0));
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiBind(MAIL_BIND_ROW_COLOR));

    json jDateLbl = NuiLabel(NuiBind(MAIL_BIND_ROW_DATE), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDateLbl = NuiWidth(jDateLbl, fDateW);
    jDateLbl = NuiStyleForegroundColor(jDateLbl, NuiBind(MAIL_BIND_ROW_COLOR));

    json jGoldLbl = NuiLabel(NuiBind(MAIL_BIND_ROW_HAS_GOLD), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jGoldLbl = NuiWidth(jGoldLbl, fIconW);
    jGoldLbl = NuiStyleForegroundColor(jGoldLbl, NuiBind(MAIL_BIND_ROW_ATT_COLOR));

    json jItemLbl = NuiLabel(NuiBind(MAIL_BIND_ROW_HAS_ITEM), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jItemLbl = NuiWidth(jItemLbl, fIconW);
    jItemLbl = NuiStyleForegroundColor(jItemLbl, NuiBind(MAIL_BIND_ROW_ATT_COLOR));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jSenderLbl)), fSenderW));
    jCellRow = JsonArrayInsert(jCellRow, jSubjLbl);
    jCellRow = JsonArrayInsert(jCellRow, jStatusLbl);
    jCellRow = JsonArrayInsert(jCellRow, jDateLbl);
    jCellRow = JsonArrayInsert(jCellRow, jGoldLbl);
    jCellRow = JsonArrayInsert(jCellRow, jItemLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, MAIL_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(MAIL_BIND_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));

    float fListH = GetNuiScaleDimension(oPC, 240.0);
    json jList = NuiList(jTmpl, NuiBind("mail_rowcount_inbox"), fRowH);
    jList = NuiHeight(jList, fListH);

    // -- Body preview --
    json jBodyTxt = NuiGroup(NuiText(NuiBind(MAIL_BIND_BODY), FALSE), TRUE, NUI_SCROLLBARS_NONE);
    jBodyTxt = NuiHeight(jBodyTxt, fBodyH);

    // -- Bottom bar: Claim + Delete --
    json jClaimBtn = NuiButton(NuiBind(MAIL_BIND_CLAIM_LBL));
    jClaimBtn = NuiId(jClaimBtn, MAIL_BTN_CLAIM);
    jClaimBtn = NuiEnabled(jClaimBtn, NuiBind(MAIL_BIND_CLAIM_ENA));
    jClaimBtn = NuiWidth(jClaimBtn, GetNuiScaleDimension(oPC, 200.0));
    jClaimBtn = NuiHeight(jClaimBtn, fBtnH);

    json jDelBtn = NuiButton(JsonString("Delete"));
    jDelBtn = NuiId(jDelBtn, MAIL_BTN_DELETE);
    jDelBtn = NuiEnabled(jDelBtn, NuiBind(MAIL_BIND_DEL_ENA));
    jDelBtn = NuiWidth(jDelBtn, GetNuiScaleDimension(oPC, 80.0));
    jDelBtn = NuiHeight(jDelBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jClaimBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jDelBtn);

    // -- Assemble column --
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTopRow));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, jBodyTxt);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    // -- Side columns for centering (LFG pattern) --
    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 760.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Compose view
// ----------------------------------------------------------------

json BuildMailComposeView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fBodyH = GetNuiScaleDimension(oPC, 250.0);
    float fSlotSz= GetNuiScaleDimension(oPC, 54.0);

    // -- Recipient search row --
    json jSearchField = NuiTextEdit(JsonString("Type name..."), NuiBind(MAIL_BIND_SEARCH_TXT), 40, FALSE);
    jSearchField = NuiWidth(jSearchField, GetNuiScaleDimension(oPC, 240.0));
    jSearchField = NuiHeight(jSearchField, fBtnH);

    json jSearchBtn = NuiButton(JsonString("Search"));
    jSearchBtn = NuiId(jSearchBtn, MAIL_BTN_SEARCH);
    jSearchBtn = NuiWidth(jSearchBtn, GetNuiScaleDimension(oPC, 70.0));
    jSearchBtn = NuiHeight(jSearchBtn, fBtnH);

    json jRecipLbl = NuiLabel(NuiBind(MAIL_BIND_RECIP_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRecipLbl = NuiWidth(jRecipLbl, GetNuiScaleDimension(oPC, 200.0));

    json jSearchRow = JsonArray();
    jSearchRow = JsonArrayInsert(jSearchRow, jRecipLbl);
    jSearchRow = JsonArrayInsert(jSearchRow, NuiSpacer());
    jSearchRow = JsonArrayInsert(jSearchRow, jSearchField);
    jSearchRow = JsonArrayInsert(jSearchRow, jSearchBtn);

    // -- Subject --
    json jSubjRow = JsonArray();
    json jSubjLbl = NuiLabel(JsonString("Subject:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSubjLbl = NuiWidth(jSubjLbl, GetNuiScaleDimension(oPC, 60.0));
    json jSubjField = NuiTextEdit(JsonString(""), NuiBind(MAIL_BIND_SUBJ_TXT), MAIL_SUBJECT_MAX, FALSE);
    jSubjField = NuiHeight(jSubjField, fBtnH);
    jSubjRow = JsonArrayInsert(jSubjRow, jSubjLbl);
    jSubjRow = JsonArrayInsert(jSubjRow, jSubjField);

    // -- Body --
    json jBodyEdit = NuiTextEdit(JsonString(""), NuiBind(MAIL_BIND_BODY_TXT), MAIL_BODY_MAX, TRUE);
    jBodyEdit = NuiHeight(jBodyEdit, fBodyH);

    // -- Gold row --
    json jGoldRow = JsonArray();
    json jGoldLbl = NuiLabel(JsonString("Gold:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jGoldLbl = NuiWidth(jGoldLbl, GetNuiScaleDimension(oPC, 50.0));
    json jGoldField = NuiTextEdit(JsonString("0"), NuiBind(MAIL_BIND_GOLD_TXT), 10, FALSE);
    jGoldField = NuiWidth(jGoldField, GetNuiScaleDimension(oPC, 100.0));
    jGoldField = NuiHeight(jGoldField, fBtnH);
    jGoldRow = JsonArrayInsert(jGoldRow, jGoldLbl);
    jGoldRow = JsonArrayInsert(jGoldRow, jGoldField);

    // -- Attachments label --
    json jAttLbl = NuiLabel(NuiBind(MAIL_BIND_ATT_CNT), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jAttLbl = NuiHeight(jAttLbl, GetNuiScaleDimension(oPC, 20.0));

    // -- Slot grid --
    json jSlotCols1 = JsonArray();
    int i;
    for(i = 0; i < MAIL_MAX_ITEMS; i++)
    {
        string sId = MAIL_BTN_SLOT + IntToString(i);
        string sImg = MAIL_BIND_SLOT_IMG + IntToString(i);
        string sLbl = MAIL_BIND_SLOT_LBL + IntToString(i);

        json jSlotImg = NuiButtonImage(NuiBind(sImg));
        jSlotImg = NuiId(jSlotImg, sId);
        jSlotImg = NuiWidth(jSlotImg, fSlotSz);
        jSlotImg = NuiHeight(jSlotImg, fSlotSz);
        jSlotImg = NuiTooltip(jSlotImg, NuiBind(sLbl));

        jSlotCols1 = JsonArrayInsert(jSlotCols1, jSlotImg);
    }

    // -- Bottom bar: Send + Back --
    json jSendBtn = NuiButton(JsonString("Send"));
    jSendBtn = NuiId(jSendBtn, MAIL_BTN_SEND);
    jSendBtn = NuiEnabled(jSendBtn, NuiBind(MAIL_BIND_SEND_ENA));
    jSendBtn = NuiWidth(jSendBtn, GetNuiScaleDimension(oPC, 80.0));
    jSendBtn = NuiHeight(jSendBtn, fBtnH);

    json jBackBtn = NuiButton(JsonString("Back"));
    jBackBtn = NuiId(jBackBtn, MAIL_BTN_BACK);
    jBackBtn = NuiWidth(jBackBtn, GetNuiScaleDimension(oPC, 80.0));
    jBackBtn = NuiHeight(jBackBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jBackBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jSendBtn);

    // -- Assemble column --
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jSearchRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jSubjRow));
    jCol = JsonArrayInsert(jCol, jBodyEdit);
    jCol = JsonArrayInsert(jCol, NuiRow(jGoldRow));
    jCol = JsonArrayInsert(jCol, jAttLbl);
    jCol = JsonArrayInsert(jCol, NuiRow(jSlotCols1));
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    // -- Side columns for centering --
    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 760.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Window create / swap
// ----------------------------------------------------------------

void CreateMailWindow(object oPC)
{
    if(NuiFindWindow(oPC, MAIL_WIN_NOTIFY) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, MAIL_WIN_NOTIFY));

    if(NuiFindWindow(oPC, MAIL_WINDOW) != 0)
    {
        NuiSetGroupLayout(oPC, NuiFindWindow(oPC, MAIL_WINDOW), MAIL_GRP_SWAP, BuildMailInboxView(oPC));
        SwapToInboxView(oPC, NuiFindWindow(oPC, MAIL_WINDOW));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - GetNuiScaleDimension(oPC, MAIL_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - GetNuiScaleDimension(oPC, MAIL_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, MAIL_W), GetNuiScaleDimension(oPC, MAIL_H));

    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, MAIL_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);
    json jTopBarRow = JsonArray();
    jTopBarRow = JsonArrayInsert(jTopBarRow, NuiSpacer());
    jTopBarRow = JsonArrayInsert(jTopBarRow, jCloseBtn);

    json jSwapGrp = NuiGroup(BuildMailInboxView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, MAIL_GRP_SWAP);

    json jRootChildren = JsonArray();
    jRootChildren = JsonArrayInsert(jRootChildren, NuiRow(jTopBarRow));
    jRootChildren = JsonArrayInsert(jRootChildren, jSwapGrp);
    json jRoot = NuiCol(jRootChildren);

    json jDl = MailBuildBackground(oPC);
    jRoot = NuiDrawList(jRoot, JsonBool(FALSE), jDl);

    json jWin = NuiWindow(jRoot,
        JsonBool(FALSE),
        NuiBind(MAIL_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, MAIL_WINDOW, MAIL_EV_SCRIPT);
    NuiSetBind(oPC, nToken, MAIL_WIN_GEOM, jGeom);

    SwapToInboxView(oPC, nToken);
}

void SwapToInboxView(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, MAIL_GRP_SWAP, BuildMailInboxView(oPC));
    SetLocalInt(oPC, MAIL_LVAR_SEL_ID, 0);
    FeedMailInbox(oPC, nToken);
}

void SwapToComposeView(object oPC, int nToken)
{
    // Reset compose state
    DeleteLocalString(oPC, MAIL_LVAR_RECIP_UUID);
    DeleteLocalString(oPC, MAIL_LVAR_RECIP_NAME);
    SetLocalJson(oPC, MAIL_LVAR_SLOTS, JsonArray());

    NuiSetGroupLayout(oPC, nToken, MAIL_GRP_SWAP, BuildMailComposeView(oPC));
    FeedMailCompose(oPC, nToken);
    NuiSetBindWatch(oPC, nToken, MAIL_BIND_GOLD_TXT,  TRUE);
    NuiSetBindWatch(oPC, nToken, MAIL_BIND_SUBJ_TXT,  TRUE);
    NuiSetBindWatch(oPC, nToken, MAIL_BIND_BODY_TXT,  TRUE);
}

// ----------------------------------------------------------------
// Feed ? Inbox
// ----------------------------------------------------------------

void FeedMailInboxList(object oPC, int nToken)
{
    json jInbox = MailGetInbox(oPC);
    int nCount  = JsonGetLength(jInbox);
    int nUnread = MailGetUnreadCount(oPC);

    string sTitle = "Inbox";
    if(nUnread > 0) sTitle = "Inbox (" + IntToString(nUnread) + " new)";
    NuiSetBind(oPC, nToken, MAIL_BIND_TITLE, JsonString(sTitle));

    json jSenders   = JsonArray();
    json jSubjects  = JsonArray();
    json jDates     = JsonArray();
    json jStatuses  = JsonArray();
    json jHasGolds  = JsonArray();
    json jHasItems  = JsonArray();
    json jColors    = JsonArray();
    json jAttColors = JsonArray();
    json jEncs      = JsonArray();

    int nSelId  = GetLocalInt(oPC, MAIL_LVAR_SEL_ID);
    json jWhite     = NuiColor(255, 255, 255);
    json jAttActive = NuiColor(255, 255, 255);  // white? unclaimed
    json jAttDone   = NuiColor(100, 100, 100);  // gray  ? claimed

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow     = JsonArrayGet(jInbox, i);
        int nId       = JsonGetInt(JsonObjectGet(jRow, "id"));
        int nRead     = JsonGetInt(JsonObjectGet(jRow, "is_read"));
        int nGold     = JsonGetInt(JsonObjectGet(jRow, "gold"));
        int nClaimed  = JsonGetInt(JsonObjectGet(jRow, "is_claimed"));
        string sItems = JsonGetString(JsonObjectGet(jRow, "items_json"));
        int nSentAt   = JsonGetInt(JsonObjectGet(jRow, "sent_at"));
        int bHasAtt   = (nGold > 0 || sItems != "[]");

        jSenders   = JsonArrayInsert(jSenders,   JsonString(JsonGetString(JsonObjectGet(jRow, "sender_name"))));
        jSubjects  = JsonArrayInsert(jSubjects,  JsonString(JsonGetString(JsonObjectGet(jRow, "subject"))));
        jDates     = JsonArrayInsert(jDates,     JsonString(MailFormatDateSQL(nSentAt)));
        jStatuses  = JsonArrayInsert(jStatuses,  JsonString(!nRead ? "new" : ""));
        jHasGolds  = JsonArrayInsert(jHasGolds,  JsonString(nGold > 0 ? "g" : ""));
        jHasItems  = JsonArrayInsert(jHasItems,  JsonString(sItems != "[]" ? "p" : ""));
        jColors    = JsonArrayInsert(jColors,    jWhite);
        jAttColors = JsonArrayInsert(jAttColors, bHasAtt ? (nClaimed ? jAttDone : jAttActive) : jAttActive);
        jEncs      = JsonArrayInsert(jEncs,      JsonBool(nSelId > 0 && nId == nSelId));
    }

    NuiSetBind(oPC, nToken, MAIL_BIND_ROW_SENDER,    jSenders);
    NuiSetBind(oPC, nToken, MAIL_BIND_ROW_SUBJECT,   jSubjects);
    NuiSetBind(oPC, nToken, MAIL_BIND_ROW_DATE,      jDates);
    NuiSetBind(oPC, nToken, MAIL_BIND_ROW_STATUS,    jStatuses);
    NuiSetBind(oPC, nToken, MAIL_BIND_ROW_HAS_GOLD,  jHasGolds);
    NuiSetBind(oPC, nToken, MAIL_BIND_ROW_HAS_ITEM,  jHasItems);
    NuiSetBind(oPC, nToken, MAIL_BIND_ROW_COLOR,     jColors);
    NuiSetBind(oPC, nToken, MAIL_BIND_ROW_ATT_COLOR, jAttColors);
    NuiSetBind(oPC, nToken, MAIL_BIND_ROW_ENC,       jEncs);
    NuiSetBind(oPC, nToken, "mail_rowcount_inbox",   JsonInt(nCount));
}

void FeedMailInbox(object oPC, int nToken)
{
    FeedMailInboxList(oPC, nToken);
    NuiSetBind(oPC, nToken, MAIL_BIND_BODY,      JsonString(""));
    NuiSetBind(oPC, nToken, MAIL_BIND_CLAIM_LBL, JsonString("Claim"));
    NuiSetBind(oPC, nToken, MAIL_BIND_CLAIM_ENA, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, MAIL_BIND_DEL_ENA,   JsonBool(FALSE));
}

void FeedMailBody(object oPC, int nToken, int nMailId)
{
    json jMsg = MailGetMessage(nMailId);
    if(JsonGetType(jMsg) == JSON_TYPE_NULL) return;

    MailMarkRead(nMailId);

    string sBody    = JsonGetString(JsonObjectGet(jMsg, "body"));
    int nGold       = JsonGetInt   (JsonObjectGet(jMsg, "gold"));
    string sItems   = JsonGetString(JsonObjectGet(jMsg, "items_json"));
    int nClaimed    = JsonGetInt   (JsonObjectGet(jMsg, "is_claimed"));

    // Body prefix: sender + subject header
    string sSender  = JsonGetString(JsonObjectGet(jMsg, "sender_name"));
    string sSubject = JsonGetString(JsonObjectGet(jMsg, "subject"));
    string sDate    = MailFormatDateSQL(JsonGetInt(JsonObjectGet(jMsg, "sent_at")));
    string sHeader  = "From: " + sSender + "  |  " + sSubject + "  |  " + sDate + "\n\n";

    // Claim button
    int bHasAtt = (nGold > 0 || sItems != "[]");
    int bCanClaim = !nClaimed && bHasAtt;
    string sClaimLbl = "Claim";
    if(bCanClaim)
    {
        sClaimLbl = "Claim";
        if(nGold > 0) sClaimLbl = sClaimLbl + " (" + IntToString(nGold) + " gp";
        json jItems = JsonParse(sItems);
        int nItemCount = JsonGetLength(jItems);
        if(nItemCount > 0)
        {
            if(nGold > 0) sClaimLbl = sClaimLbl + " + " + IntToString(nItemCount) + " item(s))";
            else          sClaimLbl = sClaimLbl + " (" + IntToString(nItemCount) + " item(s))";
        }
        else if(nGold > 0) sClaimLbl = sClaimLbl + ")";
    }

    SetLocalInt(oPC, MAIL_LVAR_SEL_ID,      nMailId);
    SetLocalInt(oPC, MAIL_LVAR_SEL_CLAIMED, nClaimed);
    SetLocalInt(oPC, MAIL_LVAR_SEL_HAS_ATT, bHasAtt);

    FeedMailInboxList(oPC, nToken);
    NuiSetBind(oPC, nToken, MAIL_BIND_BODY,      JsonString(sHeader + sBody));
    NuiSetBind(oPC, nToken, MAIL_BIND_CLAIM_LBL, JsonString(sClaimLbl));
    NuiSetBind(oPC, nToken, MAIL_BIND_CLAIM_ENA, JsonBool(bCanClaim));
    NuiSetBind(oPC, nToken, MAIL_BIND_DEL_ENA,   JsonBool(TRUE));
}

// ----------------------------------------------------------------
// Feed ? Compose
// ----------------------------------------------------------------

void FeedMailCompose(object oPC, int nToken)
{
    string sRecipName = GetLocalString(oPC, MAIL_LVAR_RECIP_NAME);
    int bHasRecip = (sRecipName != "");

    NuiSetBind(oPC, nToken, MAIL_BIND_SEARCH_TXT, JsonString(""));
    NuiSetBind(oPC, nToken, MAIL_BIND_RECIP_LBL,  JsonString(bHasRecip ? "To: " + sRecipName : "To:"));
    NuiSetBind(oPC, nToken, MAIL_BIND_SUBJ_TXT,   JsonString(""));
    NuiSetBind(oPC, nToken, MAIL_BIND_BODY_TXT,   JsonString(""));
    NuiSetBind(oPC, nToken, MAIL_BIND_GOLD_TXT,   JsonString("0"));
    NuiSetBind(oPC, nToken, MAIL_BIND_SEND_ENA,   JsonBool(FALSE));

    FeedMailSlots(oPC, nToken);
}

void CreateMailSearchPopup(object oPC, json jResults)
{
    if(NuiFindWindow(oPC, MAIL_WIN_SEARCH) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, MAIL_WIN_SEARCH));

    int nCount   = JsonGetLength(jResults);
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fW     = GetNuiScaleDimension(oPC, 420.0);
    float fListH = GetNuiScaleDimension(oPC, 160.0);
    float fH     = GetNuiScaleDimension(oPC, 220.0);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    json jResNameLbl = NuiLabel(NuiBind(MAIL_BIND_RESULT_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jResCell = NuiGroup(NuiRow(JsonArrayInsert(JsonArray(), jResNameLbl)), TRUE, NUI_SCROLLBARS_NONE);
    jResCell = NuiId(jResCell, MAIL_BTN_RESULT_ROW);
    jResCell = NuiEncouraged(jResCell, NuiBind(MAIL_BIND_RESULT_ENC));

    json jResTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jResCell, 0.0, TRUE));
    json jResList = NuiList(jResTmpl, NuiBind("mail_rowcount_search"), fRowH);
    jResList = NuiHeight(jResList, fListH);

    json jWin = NuiWindow(NuiCol(JsonArrayInsert(JsonArray(), jResList)),
        JsonString("Select Recipient"),
        NuiRect(fX, fY, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    int nPopToken = NuiCreate(oPC, jWin, MAIL_WIN_SEARCH, MAIL_EV_SCRIPT);

    json jNames = JsonArray();
    json jEncs  = JsonArray();
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jEntry = JsonArrayGet(jResults, i);
        jNames = JsonArrayInsert(jNames, JsonString(JsonGetString(JsonObjectGet(jEntry, "char_name"))));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(FALSE));
    }
    NuiSetBind(oPC, nPopToken, MAIL_BIND_RESULT_NAME,  jNames);
    NuiSetBind(oPC, nPopToken, MAIL_BIND_RESULT_ENC,   jEncs);
    NuiSetBind(oPC, nPopToken, "mail_rowcount_search", JsonInt(nCount));
}

void FeedMailSlots(object oPC, int nToken)
{
    json jSlots = GetLocalJson(oPC, MAIL_LVAR_SLOTS);
    int nCount  = JsonGetLength(jSlots);

    string sAttLbl = "Attachments (" + IntToString(nCount) + "/" + IntToString(MAIL_MAX_ITEMS) + ")";
    NuiSetBind(oPC, nToken, MAIL_BIND_ATT_CNT, JsonString(sAttLbl));

    int i;
    for(i = 0; i < MAIL_MAX_ITEMS; i++)
    {
        string sImg = MAIL_BIND_SLOT_IMG + IntToString(i);
        string sLbl = MAIL_BIND_SLOT_LBL + IntToString(i);

        if(i < nCount)
        {
            json jSlot = JsonArrayGet(jSlots, i);
            string sIcon   = JsonGetString(JsonObjectGet(jSlot, "icon"));
            string sName   = JsonGetString(JsonObjectGet(jSlot, "name"));
            int nStack     = JsonGetInt   (JsonObjectGet(jSlot, "stack"));
            string sTip    = sName + (nStack > 1 ? " x" + IntToString(nStack) : "");
            NuiSetBind(oPC, nToken, sImg, JsonString(sIcon));
            NuiSetBind(oPC, nToken, sLbl, JsonString(sTip));
        }
        else
        {
            NuiSetBind(oPC, nToken, sImg, JsonString("ir_barter"));
            NuiSetBind(oPC, nToken, sLbl, JsonString("Empty slot"));
        }
    }
}

// ----------------------------------------------------------------
// New mail notification (top-left icon)
// ----------------------------------------------------------------

void MailShowNotification(object oPC)
{
    if(NuiFindWindow(oPC, MAIL_WIN_NOTIFY) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, MAIL_WIN_NOTIFY));

    int nUnread  = MailGetUnreadCount(oPC);
    float fBtnSz = GetNuiScaleDimension(oPC, 40.0);
    float fWinSz = GetNuiScaleDimension(oPC, 56.0);

    json jBtn = NuiButtonImage(JsonString(MAIL_NOTIFY_ICON));
    jBtn = NuiId(jBtn, MAIL_BTN_NOTIFY);
    jBtn = NuiWidth(jBtn, fBtnSz);
    jBtn = NuiHeight(jBtn, fBtnSz);
    jBtn = NuiTooltip(jBtn, NuiBind(MAIL_BIND_NOTIFY_TIP));

    json jWin = NuiWindow(
        NuiCol(JsonArrayInsert(JsonArray(), jBtn)),
        JsonBool(FALSE),
        NuiBind(MAIL_BIND_NOTIFY_GEOM),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, MAIL_WIN_NOTIFY, MAIL_EV_SCRIPT);
    NuiSetBind(oPC, nToken, MAIL_BIND_NOTIFY_GEOM, NuiRect(10.0, 10.0, fWinSz, fWinSz));

    string sTip = "New mail! Inbox: " + IntToString(nUnread) + " unread";
    NuiSetBind(oPC, nToken, MAIL_BIND_NOTIFY_TIP, JsonString(sTip));
}

// ----------------------------------------------------------------
// Delete confirmation popup
// ----------------------------------------------------------------

void CreateMailDeletePopup(object oPC, int nMailId)
{
    SetLocalInt(oPC, MAIL_LVAR_PENDING_DEL, nMailId);

    if(NuiFindWindow(oPC, MAIL_WIN_DEL_CONFIRM) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, MAIL_WIN_DEL_CONFIRM));

    float fW = GetNuiScaleDimension(oPC, 380.0);
    float fH = GetNuiScaleDimension(oPC, 160.0);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    json jMsg = NuiLabel(
        JsonString("This mail has unclaimed items or gold.\nDelete anyway? They will be lost."),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));

    json jYes = NuiButton(JsonString("Delete"));
    jYes = NuiId(jYes, MAIL_BTN_DEL_CONFIRM);
    jYes = NuiWidth(jYes, GetNuiScaleDimension(oPC, 100.0));

    json jNo = NuiButton(JsonString("Cancel"));
    jNo = NuiId(jNo, MAIL_BTN_DEL_CANCEL);
    jNo = NuiWidth(jNo, GetNuiScaleDimension(oPC, 100.0));

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jYes);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jNo);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jMsg);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 10.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jWin = NuiWindow(NuiCol(jCol),
        JsonString("Confirm Delete"),
        NuiRect(fX, fY, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(TRUE));

    NuiCreate(oPC, jWin, MAIL_WIN_DEL_CONFIRM, MAIL_EV_SCRIPT);
}

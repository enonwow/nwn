#include "lib_bfire_def"

// ----------------------------------------------------------------
// Internal helper — centered button row
// ----------------------------------------------------------------

json BfireCenteredBtn(json jBtn)
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jBtn);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    return NuiRow(jRow);
}

// ----------------------------------------------------------------
// Main view layout
// ----------------------------------------------------------------

json BuildBfireMainView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 32.0);
    float fBtnW  = GetNuiScaleDimension(oPC, 220.0);
    float fLblH  = GetNuiScaleDimension(oPC, 26.0);

    // Bonfire name (large, amber)
    json jName = NuiLabel(NuiBind(BFIRE_BIND_NAME),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiHeight(jName, GetNuiScaleDimension(oPC, 36.0));
    jName = NuiStyleForegroundColor(jName, NuiColor(220, 140, 60));

    // Lit status line
    json jStatus = NuiLabel(NuiBind(BFIRE_BIND_STATUS),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatus = NuiHeight(jStatus, fLblH);
    jStatus = NuiStyleForegroundColor(jStatus, NuiBind(BFIRE_BIND_STATUS_CLR));

    // Flask count line (blue-white)
    json jFlaskLbl = NuiLabel(NuiBind(BFIRE_BIND_FLASK_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jFlaskLbl = NuiHeight(jFlaskLbl, fLblH);
    jFlaskLbl = NuiStyleForegroundColor(jFlaskLbl, NuiColor(160, 200, 255));

    // Rest button
    json jRestBtn = NuiButton(NuiBind(BFIRE_BIND_REST_LBL));
    jRestBtn = NuiId(jRestBtn, BFIRE_BTN_REST);
    jRestBtn = NuiEnabled(jRestBtn, NuiBind(BFIRE_BIND_REST_ENA));
    jRestBtn = NuiWidth(jRestBtn, fBtnW);
    jRestBtn = NuiHeight(jRestBtn, fBtnH);

    // Use flask button
    json jFlaskBtn = NuiButton(JsonString("Wypij Flaszkę"));
    jFlaskBtn = NuiId(jFlaskBtn, BFIRE_BTN_FLASK);
    jFlaskBtn = NuiEnabled(jFlaskBtn, NuiBind(BFIRE_BIND_FLASK_ENA));
    jFlaskBtn = NuiWidth(jFlaskBtn, fBtnW);
    jFlaskBtn = NuiHeight(jFlaskBtn, fBtnH);

    // Travel button (requires lit)
    json jTravBtn = NuiButton(JsonString("Podróżuj"));
    jTravBtn = NuiId(jTravBtn, BFIRE_BTN_TRAVEL);
    jTravBtn = NuiEnabled(jTravBtn, NuiBind(BFIRE_BIND_REST_ENA));
    jTravBtn = NuiWidth(jTravBtn, fBtnW);
    jTravBtn = NuiHeight(jTravBtn, fBtnH);

    // Messages button (requires lit)
    json jMsgBtn = NuiButton(JsonString("Echa Poległych"));
    jMsgBtn = NuiId(jMsgBtn, BFIRE_BTN_MESSAGES);
    jMsgBtn = NuiEnabled(jMsgBtn, NuiBind(BFIRE_BIND_REST_ENA));
    jMsgBtn = NuiWidth(jMsgBtn, fBtnW);
    jMsgBtn = NuiHeight(jMsgBtn, fBtnH);

    // Kindle button (requires unlit + tinder in inventory)
    json jKindleBtn = NuiButton(JsonString("Zapal Ognisko"));
    jKindleBtn = NuiId(jKindleBtn, BFIRE_BTN_KINDLE);
    jKindleBtn = NuiEnabled(jKindleBtn, NuiBind(BFIRE_BIND_KINDLE_ENA));
    jKindleBtn = NuiWidth(jKindleBtn, fBtnW);
    jKindleBtn = NuiHeight(jKindleBtn, fBtnH);

    // Close button
    json jCloseBtn = NuiButton(JsonString("Odejdź"));
    jCloseBtn = NuiId(jCloseBtn, BFIRE_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 100.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    float fContentW = GetNuiScaleDimension(oPC, 460.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jName);
    jCol = JsonArrayInsert(jCol, jStatus);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 10.0));
    jCol = JsonArrayInsert(jCol, BfireCenteredBtn(jRestBtn));
    jCol = JsonArrayInsert(jCol, BfireCenteredBtn(jFlaskBtn));
    jCol = JsonArrayInsert(jCol, BfireCenteredBtn(jTravBtn));
    jCol = JsonArrayInsert(jCol, BfireCenteredBtn(jMsgBtn));
    jCol = JsonArrayInsert(jCol, BfireCenteredBtn(jKindleBtn));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jFlaskLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 10.0));
    jCol = JsonArrayInsert(jCol, BfireCenteredBtn(jCloseBtn));

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Travel view layout
// ----------------------------------------------------------------

json BuildBfireTravelView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fRowH  = GetNuiScaleDimension(oPC, 28.0);
    float fListH = GetNuiScaleDimension(oPC, 270.0);

    json jHeader = NuiLabel(JsonString("Wybierz cel podróży"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHeader = NuiHeight(jHeader, GetNuiScaleDimension(oPC, 30.0));
    jHeader = NuiStyleForegroundColor(jHeader, NuiColor(220, 140, 60));

    // List: name (left, elastic) | area (right, fixed)
    json jNameLbl = NuiLabel(NuiBind(BFIRE_BIND_TRAV_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jAreaLbl = NuiLabel(NuiBind(BFIRE_BIND_TRAV_AREA),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jAreaLbl = NuiWidth(jAreaLbl, GetNuiScaleDimension(oPC, 180.0));
    jAreaLbl = NuiStyleForegroundColor(jAreaLbl, NuiColor(160, 160, 160));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, jNameLbl);
    jCellRow = JsonArrayInsert(jCellRow, jAreaLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, BFIRE_BTN_TRAV_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(BFIRE_BIND_TRAV_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(BFIRE_BIND_TRAV_CNT), fRowH);
    jList = NuiHeight(jList, fListH);

    json jBackBtn = NuiButton(JsonString("Powrót"));
    jBackBtn = NuiId(jBackBtn, BFIRE_BTN_BACK);
    jBackBtn = NuiWidth(jBackBtn, GetNuiScaleDimension(oPC, 100.0));
    jBackBtn = NuiHeight(jBackBtn, fBtnH);

    float fContentW = GetNuiScaleDimension(oPC, 460.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHeader);
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, BfireCenteredBtn(jBackBtn));

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Messages view layout
// ----------------------------------------------------------------

json BuildBfireMessagesView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fRowH  = GetNuiScaleDimension(oPC, 44.0);
    float fListH = GetNuiScaleDimension(oPC, 200.0);

    json jHeader = NuiLabel(JsonString("Echa Poległych"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHeader = NuiHeight(jHeader, GetNuiScaleDimension(oPC, 30.0));
    jHeader = NuiStyleForegroundColor(jHeader, NuiColor(220, 140, 60));

    json jSubHdr = NuiLabel(
        JsonString("Duchy poległych wciąż szepcą przy ognisku..."),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jSubHdr = NuiHeight(jSubHdr, GetNuiScaleDimension(oPC, 22.0));
    jSubHdr = NuiStyleForegroundColor(jSubHdr, NuiColor(140, 140, 140));

    // List cell: [author (amber, top-left) + message (white, bottom)] + [date (gray, right)]
    json jAuthorLbl = NuiLabel(NuiBind(BFIRE_BIND_MSG_AUTHOR),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jAuthorLbl = NuiStyleForegroundColor(jAuthorLbl, NuiColor(200, 160, 90));
    jAuthorLbl = NuiHeight(jAuthorLbl, GetNuiScaleDimension(oPC, 18.0));

    json jMsgLbl = NuiLabel(NuiBind(BFIRE_BIND_MSG_TEXT),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_BOTTOM));
    jMsgLbl = NuiStyleForegroundColor(jMsgLbl, NuiColor(220, 220, 210));
    jMsgLbl = NuiHeight(jMsgLbl, GetNuiScaleDimension(oPC, 22.0));

    json jDateLbl = NuiLabel(NuiBind(BFIRE_BIND_MSG_DATE),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_TOP));
    jDateLbl = NuiStyleForegroundColor(jDateLbl, NuiColor(110, 110, 110));
    jDateLbl = NuiWidth(jDateLbl, GetNuiScaleDimension(oPC, 80.0));
    jDateLbl = NuiHeight(jDateLbl, GetNuiScaleDimension(oPC, 18.0));

    json jLeftCol = JsonArray();
    jLeftCol = JsonArrayInsert(jLeftCol, jAuthorLbl);
    jLeftCol = JsonArrayInsert(jLeftCol, jMsgLbl);

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, NuiCol(jLeftCol));
    jCellRow = JsonArrayInsert(jCellRow,
        NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jDateLbl)),
        GetNuiScaleDimension(oPC, 80.0)));

    json jCell = NuiGroup(NuiRow(jCellRow), FALSE, NUI_SCROLLBARS_NONE);

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(BFIRE_BIND_MSG_CNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // New message input + Post
    json jInputField = NuiTextEdit(
        JsonString("Zostaw wiadomość dla poległych..."),
        NuiBind(BFIRE_BIND_NEW_MSG), BFIRE_MSG_MAX_LEN, FALSE);
    jInputField = NuiHeight(jInputField, fBtnH);

    json jPostBtn = NuiButton(JsonString("Zapisz"));
    jPostBtn = NuiId(jPostBtn, BFIRE_BTN_POST);
    jPostBtn = NuiEnabled(jPostBtn, NuiBind(BFIRE_BIND_POST_ENA));
    jPostBtn = NuiWidth(jPostBtn, GetNuiScaleDimension(oPC, 80.0));
    jPostBtn = NuiHeight(jPostBtn, fBtnH);

    json jInputRow = JsonArray();
    jInputRow = JsonArrayInsert(jInputRow, jInputField);
    jInputRow = JsonArrayInsert(jInputRow, jPostBtn);

    json jBackBtn = NuiButton(JsonString("Powrót"));
    jBackBtn = NuiId(jBackBtn, BFIRE_BTN_BACK);
    jBackBtn = NuiWidth(jBackBtn, GetNuiScaleDimension(oPC, 100.0));
    jBackBtn = NuiHeight(jBackBtn, fBtnH);

    float fContentW = GetNuiScaleDimension(oPC, 460.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHeader);
    jCol = JsonArrayInsert(jCol, jSubHdr);
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, NuiRow(jInputRow));
    jCol = JsonArrayInsert(jCol, BfireCenteredBtn(jBackBtn));

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Window create / swap
// ----------------------------------------------------------------

void BfireOpenWindow(object oPC, object oBonfire)
{
    SetLocalString(oPC, BFIRE_LVAR_TAG, GetTag(oBonfire));

    if(NuiFindWindow(oPC, BFIRE_WINDOW) != 0)
    {
        BfireSwapToMain(oPC, NuiFindWindow(oPC, BFIRE_WINDOW));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, BFIRE_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, BFIRE_H)) / 2.0;

    json jGeom = NuiRect(fCX, fCY,
        GetNuiScaleDimension(oPC, BFIRE_W),
        GetNuiScaleDimension(oPC, BFIRE_H));

    json jSwapGrp = NuiGroup(BuildBfireMainView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, BFIRE_GRP_SWAP);

    json jRoot = NuiCol(JsonArrayInsert(JsonArray(), jSwapGrp));

    json jWin = NuiWindow(jRoot,
        JsonBool(FALSE),
        NuiBind(BFIRE_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, BFIRE_WINDOW, BFIRE_EV_SCRIPT);
    NuiSetBind(oPC, nToken, BFIRE_WIN_GEOM, jGeom);

    BfireFeedMain(oPC, nToken);
}

void BfireSwapToMain(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, BFIRE_GRP_SWAP, BuildBfireMainView(oPC));
    BfireFeedMain(oPC, nToken);
}

void BfireSwapToTravel(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, BFIRE_GRP_SWAP, BuildBfireTravelView(oPC));
    BfireFeedTravel(oPC, nToken);
}

void BfireSwapToMessages(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, BFIRE_GRP_SWAP, BuildBfireMessagesView(oPC));
    BfireFeedMessages(oPC, nToken);
    NuiSetBindWatch(oPC, nToken, BFIRE_BIND_NEW_MSG, TRUE);
}

// ----------------------------------------------------------------
// Feed — main view
// ----------------------------------------------------------------

void BfireFeedMain(object oPC, int nToken)
{
    string sTag  = BfireGetTag(oPC);
    int    bLit  = BfireIsLit(sTag);
    string sUUID = GetObjectUUID(oPC);

    object oBonfire   = GetObjectByTag(sTag);
    string sDisplay   = GetIsObjectValid(oBonfire)
        ? BfireGetDisplayName(oBonfire)
        : sTag;

    NuiSetBind(oPC, nToken, BFIRE_BIND_NAME, JsonString(sDisplay));

    if(bLit)
    {
        NuiSetBind(oPC, nToken, BFIRE_BIND_STATUS,     JsonString("~ Ognisko płonie ~"));
        NuiSetBind(oPC, nToken, BFIRE_BIND_STATUS_CLR, NuiColor(220, 120, 40));
    }
    else
    {
        NuiSetBind(oPC, nToken, BFIRE_BIND_STATUS,     JsonString("Ognisko wygasłe"));
        NuiSetBind(oPC, nToken, BFIRE_BIND_STATUS_CLR, NuiColor(100, 100, 100));
    }

    // Rest: enabled if lit and cooldown passed
    int bCanRest  = FALSE;
    string sRestLbl = "Odpoczni przy ognisku";
    if(bLit)
    {
        int nLastRest = BfireGetLastRest(sUUID);
        int nNow      = BfireNow();
        int nElapsed  = nNow - nLastRest;
        if(nElapsed >= BFIRE_REST_COOLDOWN)
        {
            bCanRest = TRUE;
        }
        else
        {
            int nWait = BFIRE_REST_COOLDOWN - nElapsed;
            sRestLbl = "Odpoczni (za " + IntToString(nWait / 60) + "m "
                      + IntToString(nWait % 60) + "s)";
        }
    }
    NuiSetBind(oPC, nToken, BFIRE_BIND_REST_ENA, JsonBool(bCanRest));
    NuiSetBind(oPC, nToken, BFIRE_BIND_REST_LBL, JsonString(sRestLbl));

    // Kindle: enabled when unlit and player carries tinder
    int bHasTinder = GetIsObjectValid(GetItemPossessedBy(oPC, BFIRE_TINDER_TAG));
    NuiSetBind(oPC, nToken, BFIRE_BIND_KINDLE_ENA, JsonBool(!bLit && bHasTinder));

    // Flasks
    int    nFlasks   = BfireGetFlasks(sUUID);
    string sFlaskLbl = "Flaszki Ocalenia: " + IntToString(nFlasks)
                      + " / " + IntToString(BFIRE_MAX_FLASKS);
    NuiSetBind(oPC, nToken, BFIRE_BIND_FLASK_LBL, JsonString(sFlaskLbl));
    NuiSetBind(oPC, nToken, BFIRE_BIND_FLASK_ENA, JsonBool(nFlasks > 0));
}

// ----------------------------------------------------------------
// Feed — travel view
// ----------------------------------------------------------------

void BfireFeedTravel(object oPC, int nToken)
{
    json jLit = BfireGetLitList();
    SetLocalJson(oPC, BFIRE_LVAR_TRAV_LIST, jLit);

    int nCount = JsonGetLength(jLit);

    json jNames = JsonArray();
    json jAreas = JsonArray();
    json jEncs  = JsonArray();

    string sCurTag = BfireGetTag(oPC);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jEntry  = JsonArrayGet(jLit, i);
        string sTag  = JsonGetString(JsonObjectGet(jEntry, "tag"));
        string sArea = JsonGetString(JsonObjectGet(jEntry, "area_name"));

        object oBonfire = GetObjectByTag(sTag);
        string sName = GetIsObjectValid(oBonfire)
            ? BfireGetDisplayName(oBonfire)
            : sTag;

        jNames = JsonArrayInsert(jNames, JsonString(sName));
        jAreas = JsonArrayInsert(jAreas, JsonString(sArea));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(sTag == sCurTag));
    }

    NuiSetBind(oPC, nToken, BFIRE_BIND_TRAV_NAME, jNames);
    NuiSetBind(oPC, nToken, BFIRE_BIND_TRAV_AREA, jAreas);
    NuiSetBind(oPC, nToken, BFIRE_BIND_TRAV_ENC,  jEncs);
    NuiSetBind(oPC, nToken, BFIRE_BIND_TRAV_CNT,  JsonInt(nCount));
}

// ----------------------------------------------------------------
// Feed — messages view
// ----------------------------------------------------------------

void BfireFeedMessages(object oPC, int nToken)
{
    string sTag = BfireGetTag(oPC);
    json jMsgs  = BfireGetMessages(sTag, BFIRE_MAX_MSGS_SHOWN);
    int  nCount = JsonGetLength(jMsgs);

    json jAuthors = JsonArray();
    json jTexts   = JsonArray();
    json jDates   = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jEntry = JsonArrayGet(jMsgs, i);
        jAuthors = JsonArrayInsert(jAuthors,
            JsonString(JsonGetString(JsonObjectGet(jEntry, "author_name"))));
        jTexts = JsonArrayInsert(jTexts,
            JsonString(JsonGetString(JsonObjectGet(jEntry, "message"))));
        jDates = JsonArrayInsert(jDates,
            JsonString(BfireFormatDate(JsonGetInt(JsonObjectGet(jEntry, "posted_at")))));
    }

    NuiSetBind(oPC, nToken, BFIRE_BIND_MSG_AUTHOR, jAuthors);
    NuiSetBind(oPC, nToken, BFIRE_BIND_MSG_TEXT,   jTexts);
    NuiSetBind(oPC, nToken, BFIRE_BIND_MSG_DATE,   jDates);
    NuiSetBind(oPC, nToken, BFIRE_BIND_MSG_CNT,    JsonInt(nCount));
    NuiSetBind(oPC, nToken, BFIRE_BIND_NEW_MSG,    JsonString(""));
    NuiSetBind(oPC, nToken, BFIRE_BIND_POST_ENA,   JsonBool(FALSE));
}

// ----------------------------------------------------------------
// Actions
// ----------------------------------------------------------------

void BfireDoRest(object oPC, int nToken)
{
    string sUUID = GetObjectUUID(oPC);

    // Full HP restore
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectHeal(GetMaxHitPoints(oPC)), oPC);

    // Remove negative persistent effects
    effect eCheck = GetFirstEffect(oPC);
    while(GetIsEffectValid(eCheck))
    {
        int nType = GetEffectType(eCheck);
        if(nType == EFFECT_TYPE_ABILITY_DECREASE
        || nType == EFFECT_TYPE_AC_DECREASE
        || nType == EFFECT_TYPE_ATTACK_DECREASE
        || nType == EFFECT_TYPE_DAMAGE_DECREASE
        || nType == EFFECT_TYPE_SKILL_DECREASE
        || nType == EFFECT_TYPE_NEGATIVELEVEL
        || nType == EFFECT_TYPE_POISON
        || nType == EFFECT_TYPE_DISEASE)
        {
            RemoveEffect(oPC, eCheck);
        }
        eCheck = GetNextEffect(oPC);
    }

    // Refill flasks and record rest time
    BfireSetFlasks(sUUID, BFIRE_MAX_FLASKS);
    BfireSetLastRest(sUUID);

    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_RESTORATION), oPC);

    SendMessageToPC(oPC,
        "[Ognisko] Odpoczywasz przy ognisku. Ciemność zdaje się cofać. "
        "Flaszki uzupełnione do " + IntToString(BFIRE_MAX_FLASKS) + ".");
    FloatingTextStringOnCreature("Odpoczynek przy ognisku...", oPC, FALSE);

    BfireFeedMain(oPC, nToken);
}

void BfireDoKindle(object oPC, int nToken)
{
    string sTag = BfireGetTag(oPC);

    object oTinder = GetItemPossessedBy(oPC, BFIRE_TINDER_TAG);
    if(!GetIsObjectValid(oTinder))
    {
        SendMessageToPC(oPC, "[Ognisko] Potrzebujesz Łuczywa, by zapalić ognisko.");
        return;
    }

    // Consume one unit of tinder
    int nStack = GetItemStackSize(oTinder);
    if(nStack <= 1)
        DestroyObject(oTinder);
    else
        SetItemStackSize(oTinder, nStack - 1);

    string sAreaName = GetName(GetArea(oPC));
    BfireLightBonfire(sTag, sAreaName, GetName(oPC));

    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_FLAME_M), oPC);

    SendMessageToPC(oPC,
        "[Ognisko] Łuczywo płonie... ognisko zajmuje ogień! "
        "Ciepło rozchodzi się wokół.");
    FloatingTextStringOnCreature("Ognisko zapalone!", oPC, FALSE);

    BfireSwapToMain(oPC, nToken);
}

void BfireDoUseFlask(object oPC, int nToken)
{
    string sUUID = GetObjectUUID(oPC);
    int nFlasks  = BfireGetFlasks(sUUID);

    if(nFlasks <= 0)
    {
        SendMessageToPC(oPC, "[Ognisko] Wszystkie flaszki są puste. "
            "Odpocznij przy ognisku, by uzupełnić zapasy.");
        return;
    }

    int nHeal = GetMaxHitPoints(oPC) / 2;
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(nHeal), oPC);
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_HEALING_M), oPC);

    BfireSetFlasks(sUUID, nFlasks - 1);

    SendMessageToPC(oPC,
        "[Ognisko] Flaszka opróżniona. Ciepło rozchodzi się po ciele. ("
        + IntToString(nFlasks - 1) + " pozostało)");

    BfireFeedMain(oPC, nToken);
}

void BfireDoTravel(object oPC, int nToken, int nIdx)
{
    json jLit = GetLocalJson(oPC, BFIRE_LVAR_TRAV_LIST);
    if(nIdx < 0 || nIdx >= JsonGetLength(jLit)) return;

    json jEntry  = JsonArrayGet(jLit, nIdx);
    string sTag  = JsonGetString(JsonObjectGet(jEntry, "tag"));

    object oDest = GetObjectByTag(sTag);
    if(!GetIsObjectValid(oDest))
    {
        SendMessageToPC(oPC,
            "[Ognisko] Nie można zlokalizować celu podróży — "
            "ognisko mogło zostać zniszczone.");
        BfireSwapToTravel(oPC, nToken);
        return;
    }

    NuiDestroy(oPC, nToken);
    SetLocalString(oPC, BFIRE_LVAR_TAG, sTag);

    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_MAGICAL_NORMAL), oPC);

    DelayCommand(0.5f, JumpToObject(oPC, oDest));
    DelayCommand(0.8f, ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_RESTORATION), oPC));

    SendMessageToPC(oPC,
        "[Ognisko] Podróżujesz do: " + BfireGetDisplayName(oDest) + ".");
}

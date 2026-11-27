#include "lib_bb_def"

// ----------------------------------------------------------------
// NUI layout builders
// ----------------------------------------------------------------

json BbBuildListPanel(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fRowH = GetNuiScaleDimension(oPC, 32.0);

    // Header
    json jHdr = NuiLabel(JsonString("Schwytane bestie"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHdr = NuiHeight(jHdr, fBtnH);

    // List template: name + bonding bar + status indicator
    float fNameW   = GetNuiScaleDimension(oPC, 100.0);
    float fBondW   = GetNuiScaleDimension(oPC, 80.0);
    float fStatW   = GetNuiScaleDimension(oPC, 36.0);

    json jNameLbl = NuiLabel(NuiBind(BB_BIND_ROW_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(BB_BIND_ROW_COLOR));

    json jBondLbl = NuiLabel(NuiBind(BB_BIND_ROW_BOND), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBondLbl = NuiWidth(jBondLbl, fBondW);
    jBondLbl = NuiStyleForegroundColor(jBondLbl, NuiBind(BB_BIND_ROW_COLOR));

    json jStatLbl = NuiLabel(NuiBind(BB_BIND_ROW_STATUS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatLbl = NuiWidth(jStatLbl, fStatW);
    jStatLbl = NuiStyleForegroundColor(jStatLbl, NuiBind(BB_BIND_ROW_COLOR));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jNameLbl)), fNameW));
    jCellRow = JsonArrayInsert(jCellRow, jBondLbl);
    jCellRow = JsonArrayInsert(jCellRow, jStatLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, BB_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(BB_BIND_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));

    float fListH = GetNuiScaleDimension(oPC, 350.0);
    json jList = NuiList(jTmpl, NuiBind(BB_BIND_ROW_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // Capture button at bottom
    json jCapBtn = NuiButton(JsonString("Schwytaj bestiê"));
    jCapBtn = NuiId(jCapBtn, BB_BTN_CAPTURE);
    jCapBtn = NuiEnabled(jCapBtn, NuiBind(BB_BIND_BTN_CAP_ENA));
    jCapBtn = NuiHeight(jCapBtn, fBtnH);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jHdr)));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jCapBtn)));

    float fLeftW = GetNuiScaleDimension(oPC, BB_LEFT_W);
    return NuiWidth(NuiCol(jCol), fLeftW);
}

json BbBuildDetailPanel(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fFlvH  = GetNuiScaleDimension(oPC, 70.0);
    float fLblW  = GetNuiScaleDimension(oPC, 70.0);

    // Name row
    json jNameLbl = NuiLabel(NuiBind(BB_BIND_DET_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiHeight(jNameLbl, fBtnH);

    // Status row
    json jStatLbl = NuiLabel(NuiBind(BB_BIND_DET_STATUS),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatLbl = NuiHeight(jStatLbl, GetNuiScaleDimension(oPC, 22.0));

    // Bonding row
    json jBondHdr = NuiLabel(JsonString("Wiêz:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBondHdr = NuiWidth(jBondHdr, fLblW);
    json jBondVal = NuiLabel(NuiBind(BB_BIND_DET_BOND_L), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jBondRow = JsonArray();
    jBondRow = JsonArrayInsert(jBondRow, jBondHdr);
    jBondRow = JsonArrayInsert(jBondRow, jBondVal);

    // Kills row
    json jKillsHdr = NuiLabel(JsonString("Zabjstwa:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jKillsHdr = NuiWidth(jKillsHdr, fLblW);
    json jKillsVal = NuiLabel(NuiBind(BB_BIND_DET_KILLS), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jKillsRow = JsonArray();
    jKillsRow = JsonArrayInsert(jKillsRow, jKillsHdr);
    jKillsRow = JsonArrayInsert(jKillsRow, jKillsVal);

    // Progress bar
    json jProgress = NuiProgressBar(NuiBind(BB_BIND_DET_BOND_P));
    jProgress = NuiHeight(jProgress, GetNuiScaleDimension(oPC, 16.0));

    // Flavor text box
    json jFlavor = NuiGroup(NuiText(NuiBind(BB_BIND_DET_FLAVOR), FALSE), TRUE, NUI_SCROLLBARS_NONE);
    jFlavor = NuiHeight(jFlavor, fFlvH);

    // Action buttons: Activate / Dismiss
    json jActBtn = NuiButton(JsonString("Aktywuj"));
    jActBtn = NuiId(jActBtn, BB_BTN_ACTIVATE);
    jActBtn = NuiEnabled(jActBtn, NuiBind(BB_BIND_BTN_ACT_ENA));
    jActBtn = NuiHeight(jActBtn, fBtnH);

    json jDisBtn = NuiButton(JsonString("Odwolaj"));
    jDisBtn = NuiId(jDisBtn, BB_BTN_DISMISS);
    jDisBtn = NuiEnabled(jDisBtn, NuiBind(BB_BIND_BTN_DIS_ENA));
    jDisBtn = NuiHeight(jDisBtn, fBtnH);

    json jActRow = JsonArray();
    jActRow = JsonArrayInsert(jActRow, jActBtn);
    jActRow = JsonArrayInsert(jActRow, jDisBtn);

    // Feed button
    json jFeedBtn = NuiButton(JsonString("Nakarm (mièso)"));
    jFeedBtn = NuiId(jFeedBtn, BB_BTN_FEED);
    jFeedBtn = NuiEnabled(jFeedBtn, NuiBind(BB_BIND_BTN_FEED_ENA));
    jFeedBtn = NuiHeight(jFeedBtn, fBtnH);

    // Release button
    json jRelBtn = NuiButton(JsonString("Uwolnij"));
    jRelBtn = NuiId(jRelBtn, BB_BTN_RELEASE);
    jRelBtn = NuiEnabled(jRelBtn, NuiBind(BB_BIND_BTN_REL_ENA));
    jRelBtn = NuiHeight(jRelBtn, fBtnH);

    json jRelRow = JsonArray();
    jRelRow = JsonArrayInsert(jRelRow, jFeedBtn);
    jRelRow = JsonArrayInsert(jRelRow, NuiSpacer());
    jRelRow = JsonArrayInsert(jRelRow, jRelBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jNameLbl)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jStatLbl)));
    jCol = JsonArrayInsert(jCol, NuiRow(jBondRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jKillsRow));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jProgress)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jFlavor)));
    jCol = JsonArrayInsert(jCol, NuiRow(jActRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jRelRow));

    return NuiCol(jCol);
}

void BbOpenWindow(object oPC)
{
    if(NuiFindWindow(oPC, BB_WINDOW) != 0)
    {
        BbFeedBeastList(oPC, NuiFindWindow(oPC, BB_WINDOW));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                - GetNuiScaleDimension(oPC, BB_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                - GetNuiScaleDimension(oPC, BB_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, BB_W), GetNuiScaleDimension(oPC, BB_H));

    float fBtnH = GetNuiScaleDimension(oPC, 30.0);

    // Top bar
    json jTitle = NuiLabel(JsonString("PETACZ BESTII"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);

    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, BB_BTN_CLOSE);
    jClose = NuiWidth(jClose,  GetNuiScaleDimension(oPC, 30.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitle);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jClose);

    // Main two-panel content row
    json jSep = NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer())),
                         GetNuiScaleDimension(oPC, 8.0));
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, BbBuildListPanel(oPC));
    jMainRow = JsonArrayInsert(jMainRow, jSep);
    jMainRow = JsonArrayInsert(jMainRow, BbBuildDetailPanel(oPC));

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jTopRow));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jMainRow));

    json jWin = NuiWindow(
        NuiCol(jRoot),
        JsonBool(FALSE),
        NuiBind(BB_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    int nToken = NuiCreate(oPC, jWin, BB_WINDOW, BB_EV_SCRIPT);
    NuiSetBind(oPC, nToken, BB_WIN_GEOM, jGeom);

    BbFeedBeastList(oPC, nToken);
    BbFeedBeastDetails(oPC, nToken, 0);
}

// ----------------------------------------------------------------
// Data feed functions
// ----------------------------------------------------------------

void BbFeedBeastList(object oPC, int nToken)
{
    json jBeasts = BbGetBeasts(oPC);
    int nCount   = JsonGetLength(jBeasts);

    json jNames   = JsonArray();
    json jBonds   = JsonArray();
    json jStats   = JsonArray();
    json jEncs    = JsonArray();
    json jColors  = JsonArray();

    int nSelId = GetLocalInt(oPC, BB_LVAR_SEL_ID);
    json jWhite  = NuiColor(220, 200, 160);
    json jGold   = NuiColor(255, 200, 80);
    json jGreen  = NuiColor(100, 220, 100);

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jE        = JsonArrayGet(jBeasts, i);
        int  nId       = JsonGetInt(JsonObjectGet(jE, "id"));
        string sName   = JsonGetString(JsonObjectGet(jE, "name"));
        int  nBonding  = JsonGetInt(JsonObjectGet(jE, "bonding"));
        int  bActive   = JsonGetInt(JsonObjectGet(jE, "is_active"));

        jNames  = JsonArrayInsert(jNames,  JsonString(sName));
        jBonds  = JsonArrayInsert(jBonds,  JsonString(IntToString(nBonding) + "%"));
        jStats  = JsonArrayInsert(jStats,  JsonString(bActive ? "[A]" : ""));
        jEncs   = JsonArrayInsert(jEncs,   JsonBool(nSelId > 0 && nId == nSelId));
        jColors = JsonArrayInsert(jColors, bActive ? jGreen : jWhite);
    }

    NuiSetBind(oPC, nToken, BB_BIND_ROW_NAME,   jNames);
    NuiSetBind(oPC, nToken, BB_BIND_ROW_BOND,   jBonds);
    NuiSetBind(oPC, nToken, BB_BIND_ROW_STATUS, jStats);
    NuiSetBind(oPC, nToken, BB_BIND_ROW_ENC,    jEncs);
    NuiSetBind(oPC, nToken, BB_BIND_ROW_COLOR,  jColors);
    NuiSetBind(oPC, nToken, BB_BIND_ROW_COUNT,  JsonInt(nCount));

    int bCapOk = (nCount < BB_MAX_BEASTS);
    NuiSetBind(oPC, nToken, BB_BIND_BTN_CAP_ENA, JsonBool(bCapOk));
}

void BbFeedBeastDetails(object oPC, int nToken, int nBeastId)
{
    if(nBeastId <= 0)
    {
        NuiSetBind(oPC, nToken, BB_BIND_DET_NAME,   JsonString("— (nie wybrano) —"));
        NuiSetBind(oPC, nToken, BB_BIND_DET_STATUS, JsonString(""));
        NuiSetBind(oPC, nToken, BB_BIND_DET_BOND_L, JsonString(""));
        NuiSetBind(oPC, nToken, BB_BIND_DET_BOND_P, JsonFloat(0.0));
        NuiSetBind(oPC, nToken, BB_BIND_DET_KILLS,  JsonString(""));
        NuiSetBind(oPC, nToken, BB_BIND_DET_FLAVOR, JsonString(""));
        NuiSetBind(oPC, nToken, BB_BIND_BTN_ACT_ENA,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, BB_BIND_BTN_FEED_ENA, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, BB_BIND_BTN_REL_ENA,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, BB_BIND_BTN_DIS_ENA,  JsonBool(FALSE));
        return;
    }

    json jB = BbGetBeast(nBeastId);
    if(JsonGetType(jB) == JSON_TYPE_NULL) return;

    int nBonding = JsonGetInt(JsonObjectGet(jB, "bonding"));
    int bActive  = JsonGetInt(JsonObjectGet(jB, "is_active"));
    int nKills   = JsonGetInt(JsonObjectGet(jB, "kills"));

    string sStatus = bActive ? "STATUS: AKTYWNA" : "Status: schwytana";
    if(nBonding >= BB_BOND_TIER_FULL) sStatus = sStatus + " [OSWOJONA]";

    NuiSetBind(oPC, nToken, BB_BIND_DET_NAME,   JsonString(JsonGetString(JsonObjectGet(jB, "name"))));
    NuiSetBind(oPC, nToken, BB_BIND_DET_STATUS, JsonString(sStatus));
    NuiSetBind(oPC, nToken, BB_BIND_DET_BOND_L, JsonString(BbBondingToBar(nBonding)));
    NuiSetBind(oPC, nToken, BB_BIND_DET_BOND_P, JsonFloat(IntToFloat(nBonding) / 100.0));
    NuiSetBind(oPC, nToken, BB_BIND_DET_KILLS,  JsonString(IntToString(nKills)));
    NuiSetBind(oPC, nToken, BB_BIND_DET_FLAVOR, JsonString(BbGetFlavorText(nBonding)));

    NuiSetBind(oPC, nToken, BB_BIND_BTN_ACT_ENA,  JsonBool(!bActive));
    NuiSetBind(oPC, nToken, BB_BIND_BTN_DIS_ENA,  JsonBool(bActive));
    NuiSetBind(oPC, nToken, BB_BIND_BTN_FEED_ENA, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, BB_BIND_BTN_REL_ENA,  JsonBool(!bActive));
}

// ----------------------------------------------------------------
// Core gameplay actions
// ----------------------------------------------------------------

void BbCaptureMode(object oPC)
{
    if(BbGetBeastCount(oPC) >= BB_MAX_BEASTS)
    {
        SendMessageToPC(oPC, "[Pêtacz] Masz już maksymalną liczbę bestii (" + IntToString(BB_MAX_BEASTS) + ").");
        return;
    }
    SetLocalInt(oPC, BB_LVAR_CAPTURING, 1);
    EnterTargetingMode(oPC, OBJECT_TYPE_CREATURE);
    SendMessageToPC(oPC, "[Pêtacz] Wybierz osłabioną bestiê, którą chcesz schwytać...");
}

void BbActivateBeast(object oPC, int nBeastId)
{
    // If another beast is already active, dismiss it first
    object oOld = GetLocalObject(oPC, BB_LVAR_BEAST_OBJ);
    if(GetIsObjectValid(oOld))
    {
        RemoveHenchman(oPC, oOld);
        DestroyObject(oOld);
        DeleteLocalObject(oPC, BB_LVAR_BEAST_OBJ);
    }
    BbClearActiveForPC(oPC);

    json jB = BbGetBeast(nBeastId);
    if(JsonGetType(jB) == JSON_TYPE_NULL) return;

    string sResRef = JsonGetString(JsonObjectGet(jB, "resref"));
    string sName   = JsonGetString(JsonObjectGet(jB, "name"));
    int nBonding   = JsonGetInt(JsonObjectGet(jB, "bonding"));

    location lSpawn = GetLocation(oPC);
    object oBeast = CreateObject(OBJECT_TYPE_CREATURE, sResRef, lSpawn, FALSE, sName);
    if(!GetIsObjectValid(oBeast))
    {
        SendMessageToPC(oPC, "[Pêtacz] Nie można przywołać bestii — nieprawidłowy resref.");
        return;
    }

    // Make the beast friendly and add as henchman
    ChangeToStandardFaction(oBeast, STANDARD_FACTION_DEFENDER);
    AddHenchman(oPC, oBeast);

    // Bonus HP for high bonding
    if(nBonding >= BB_BOND_TIER_HP)
    {
        effect eHP = EffectTemporaryHitpoints(20);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eHP, oBeast);
    }

    SetLocalInt(oBeast,    "BB_ID",    nBeastId);
    SetLocalObject(oBeast, "BB_OWNER", oPC);
    SetLocalObject(oPC, BB_LVAR_BEAST_OBJ, oBeast);

    BbSetActive(nBeastId, TRUE);

    string sFlavor = (nBonding >= 50)
        ? " Bestia podchodzi do ciebie spokojnie."
        : " Bestia szarpie têtnicê z niepokojêm.";
    SendMessageToPC(oPC, "[Pêtacz] " + sName + " została przywołana." + sFlavor);
}

void BbDismissBeast(object oPC)
{
    object oBeast = GetLocalObject(oPC, BB_LVAR_BEAST_OBJ);
    int nId = BbGetActiveBeastId(oPC);

    if(GetIsObjectValid(oBeast))
    {
        RemoveHenchman(oPC, oBeast);
        DestroyObject(oBeast);
    }
    DeleteLocalObject(oPC, BB_LVAR_BEAST_OBJ);

    if(nId > 0) BbSetActive(nId, FALSE);

    SendMessageToPC(oPC, "[Pêtacz] Bestia została odwołana.");
}

void BbDoRelease(object oPC, int nBeastId)
{
    json jB = BbGetBeast(nBeastId);
    if(JsonGetType(jB) == JSON_TYPE_NULL) return;

    string sName = JsonGetString(JsonObjectGet(jB, "name"));
    BbDeleteBeast(nBeastId);

    SetLocalInt(oPC, BB_LVAR_SEL_ID, 0);

    SendMessageToPC(oPC, "[Pêtacz] " + sName + " ucieka w ciemność — wolna.");
}

void BbFeedBeast(object oPC, int nBeastId)
{
    // Consume one bb_meat item from inventory
    object oFood = GetItemPossessedBy(oPC, BB_FOOD_TAG);
    if(!GetIsObjectValid(oFood))
    {
        SendMessageToPC(oPC, "[Pêtacz] Nie masz mi\êsa (" + BB_FOOD_TAG + ") w ekwipunku.");
        return;
    }

    int nStack = GetItemStackSize(oFood);
    if(nStack > 1)
        SetItemStackSize(oFood, nStack - 1);
    else
        DestroyObject(oFood);

    BbUpdateBonding(nBeastId, BB_BOND_FEED);
    BbMarkFed(nBeastId);

    json jB = BbGetBeast(nBeastId);
    int nNew = JsonGetInt(JsonObjectGet(jB, "bonding"));

    SendMessageToPC(oPC, "[Pêtacz] Wi\êz wzrosła do " + IntToString(nNew) + ".");

    if(nNew >= BB_BOND_TIER_FULL)
        SendMessageToPC(oPC, "[Pêtacz] Bestia jest całkowicie oswojona. Piećząta mrocznej więzi zacisnêła si\ê na wieki.");
}

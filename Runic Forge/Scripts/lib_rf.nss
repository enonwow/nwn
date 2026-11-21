#include "lib_rf_def"

// -----------------------------------------------------------------------
// Data helpers
// -----------------------------------------------------------------------

string RFRuneName(int nRune)
{
    if(nRune == RF_RUNE_FIRE)     return "Runa Ognia";
    if(nRune == RF_RUNE_ICE)      return "Runa Lodu";
    if(nRune == RF_RUNE_STORM)    return "Runa Burzy";
    if(nRune == RF_RUNE_SHADOW)   return "Runa Mroku";
    if(nRune == RF_RUNE_RADIANCE) return "Runa Blasku";
    if(nRune == RF_RUNE_BLOOD)    return "Runa Krwi";
    return "Nieznana";
}

// IP_CONST_DAMAGEBONUS_TYPE_ for each element rune.
int RFDamageType(int nRune)
{
    if(nRune == RF_RUNE_FIRE)     return IP_CONST_DAMAGEBONUS_TYPE_FIRE;
    if(nRune == RF_RUNE_ICE)      return IP_CONST_DAMAGEBONUS_TYPE_COLD;
    if(nRune == RF_RUNE_STORM)    return IP_CONST_DAMAGEBONUS_TYPE_ELECTRICAL;
    if(nRune == RF_RUNE_SHADOW)   return IP_CONST_DAMAGEBONUS_TYPE_NEGATIVE;
    if(nRune == RF_RUNE_RADIANCE) return IP_CONST_DAMAGEBONUS_TYPE_DIVINE;
    return IP_CONST_DAMAGEBONUS_TYPE_FIRE; // RF_RUNE_BLOOD handled separately
}

// Returns IP_CONST_DAMAGEBONUS_ die constant for the given enchant level (1-5).
int RFDiceConst(int nLevel)
{
    if(nLevel <= 1) return IP_CONST_DAMAGEBONUS_1d4;
    if(nLevel == 2) return IP_CONST_DAMAGEBONUS_1d6;
    if(nLevel == 3) return IP_CONST_DAMAGEBONUS_1d8;
    if(nLevel == 4) return IP_CONST_DAMAGEBONUS_1d10;
    return IP_CONST_DAMAGEBONUS_2d6; // level 5
}

string RFDiceLabel(int nLevel)
{
    if(nLevel <= 1) return "1k4";
    if(nLevel == 2) return "1k6";
    if(nLevel == 3) return "1k8";
    if(nLevel == 4) return "1k10";
    return "2k6";
}

int RFGetCost(int nCurrentLevel)
{
    return RF_BASE_COST + nCurrentLevel * RF_COST_PER_LEVEL;
}

// Sequence length grows with each upgrade attempt.
int RFSequenceLength(int nCurrentLevel)
{
    int nLen = 4 + nCurrentLevel; // 4 at level 0, 9 at level 5
    if(nLen > 9) nLen = 9;
    return nLen;
}

// Human-readable summary of all runes on an item for the forge panel.
string RFEnchantSummary(string sItemUuid)
{
    if(sItemUuid == "") return "brak";
    json jEnchs = RFGetItemEnchants(sItemUuid);
    int nCount = JsonGetLength(jEnchs);
    if(nCount == 0) return "brak run";
    string sResult = "";
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jE    = JsonArrayGet(jEnchs, i);
        int nRune  = JsonGetInt(JsonObjectGet(jE, "rune_id"));
        int nLevel = JsonGetInt(JsonObjectGet(jE, "level"));
        if(sResult != "") sResult = sResult + ", ";
        sResult = sResult + RFRuneName(nRune) + " " + IntToString(nLevel);
    }
    return sResult;
}


// -----------------------------------------------------------------------
// Enchant application
// -----------------------------------------------------------------------

// Removes any existing ItemProperty on the weapon that matches this rune's type.
// Blood rune uses ITEM_PROPERTY_VAMPIRIC_REGENERATION; others use ITEM_PROPERTY_DAMAGE_BONUS.
void RFRemoveRuneProperty(object oItem, int nRune)
{
    int nTargetPropType = (nRune == RF_RUNE_BLOOD)
        ? ITEM_PROPERTY_VAMPIRIC_REGENERATION
        : ITEM_PROPERTY_DAMAGE_BONUS;
    int nTargetSubType  = (nRune == RF_RUNE_BLOOD) ? -1 : RFDamageType(nRune);

    itemproperty ip = GetFirstItemProperty(oItem);
    while(GetIsItemPropertyValid(ip))
    {
        if(GetItemPropertyType(ip) == nTargetPropType)
        {
            if(nRune == RF_RUNE_BLOOD || GetItemPropertySubType(ip) == nTargetSubType)
                RemoveItemProperty(oItem, ip);
        }
        ip = GetNextItemProperty(oItem);
    }
}

void RFApplyEnchant(object oItem, int nRune, int nLevel)
{
    RFRemoveRuneProperty(oItem, nRune);

    itemproperty ipNew;
    if(nRune == RF_RUNE_BLOOD)
        ipNew = ItemPropertyVampiricRegeneration(nLevel);
    else
        ipNew = ItemPropertyDamageBonus(RFDamageType(nRune), RFDiceConst(nLevel));

    AddItemProperty(DURATION_TYPE_PERMANENT, ipNew, oItem);
}


// -----------------------------------------------------------------------
// NUI: Forge window
// -----------------------------------------------------------------------

json RFBuildRuneRow(object oPC, int nStart)
{
    float fBtnH = GetNuiScaleDimension(oPC, 34.0);
    json jRow = JsonArray();
    int i;
    for(i = nStart; i < nStart + 3 && i < RF_RUNE_COUNT; i++)
    {
        json jBtn = NuiButton(JsonString(RFRuneName(i)));
        jBtn = NuiId(jBtn, RF_BTN_RUNE + IntToString(i));
        jBtn = NuiEncouraged(jBtn, NuiBind(RF_BIND_RUNE_ENC + IntToString(i)));
        jBtn = NuiHeight(jBtn, fBtnH);
        jRow = JsonArrayInsert(jRow, jBtn);
    }
    return NuiRow(jRow);
}

json RFBuildForgeContent(object oPC)
{
    float fLblH  = GetNuiScaleDimension(oPC, 26.0);
    float fBtnH  = GetNuiScaleDimension(oPC, 32.0);
    float fWpnBW = GetNuiScaleDimension(oPC, 140.0);

    // -- Weapon selector row --
    json jWpnBtn = NuiButton(JsonString("Wybierz bron"));
    jWpnBtn = NuiId(jWpnBtn, RF_BTN_WEAPON);
    jWpnBtn = NuiEnabled(jWpnBtn, NuiBind(RF_BIND_WPN_ENA));
    jWpnBtn = NuiWidth(jWpnBtn, fWpnBW);
    jWpnBtn = NuiHeight(jWpnBtn, fBtnH);
    jWpnBtn = NuiTooltip(jWpnBtn, JsonString("Wskaż broń w swoim ekwipunku"));

    json jWpnLbl = NuiLabel(NuiBind(RF_BIND_WPN_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jWpnLbl = NuiHeight(jWpnLbl, fBtnH);

    json jWpnRow = JsonArray();
    jWpnRow = JsonArrayInsert(jWpnRow, jWpnBtn);
    jWpnRow = JsonArrayInsert(jWpnRow, NuiWidth(NuiSpacer(), GetNuiScaleDimension(oPC, 8.0)));
    jWpnRow = JsonArrayInsert(jWpnRow, jWpnLbl);

    // -- Rune header --
    json jRuneHdr = NuiLabel(JsonString("Wybierz rune:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRuneHdr = NuiHeight(jRuneHdr, fLblH);
    jRuneHdr = NuiStyleForegroundColor(jRuneHdr, NuiColor(185, 150, 100, 255));

    // -- Enchant info --
    json jEnchHdr = NuiLabel(JsonString("Aktualny enchant:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEnchHdr = NuiHeight(jEnchHdr, fLblH);
    jEnchHdr = NuiStyleForegroundColor(jEnchHdr, NuiColor(185, 150, 100, 255));

    json jEnchLbl = NuiLabel(NuiBind(RF_BIND_ENCH_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEnchLbl = NuiHeight(jEnchLbl, fLblH);

    // -- Cost info --
    json jCostLbl = NuiLabel(NuiBind(RF_BIND_COST_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCostLbl = NuiHeight(jCostLbl, fLblH);

    // -- Forge button --
    float fForgeBW = GetNuiScaleDimension(oPC, 140.0);
    float fForgeBH = GetNuiScaleDimension(oPC, 38.0);
    json jForgeBtn = NuiButton(JsonString("KUJ!"));
    jForgeBtn = NuiId(jForgeBtn, RF_BTN_FORGE);
    jForgeBtn = NuiEnabled(jForgeBtn, NuiBind(RF_BIND_FORGE_ENA));
    jForgeBtn = NuiWidth(jForgeBtn, fForgeBW);
    jForgeBtn = NuiHeight(jForgeBtn, fForgeBH);
    jForgeBtn = NuiTooltip(jForgeBtn, JsonString("Rozpocznij próbę rytowania — zapłać i uruchom minigrę"));

    json jForgeRow = JsonArray();
    jForgeRow = JsonArrayInsert(jForgeRow, NuiSpacer());
    jForgeRow = JsonArrayInsert(jForgeRow, jForgeBtn);
    jForgeRow = JsonArrayInsert(jForgeRow, NuiSpacer());

    // -- Assemble column --
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jWpnRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jRuneHdr)));
    jCol = JsonArrayInsert(jCol, RFBuildRuneRow(oPC, 0)); // Ogień, Lód, Burza
    jCol = JsonArrayInsert(jCol, RFBuildRuneRow(oPC, 3)); // Mrok, Blask, Krew
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jEnchHdr)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jEnchLbl)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jCostLbl)));
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jForgeRow));

    return NuiCol(jCol);
}

void RFOpenForge(object oPC)
{
    // If already open, just re-feed it.
    int nToken = NuiFindWindow(oPC, RF_WIN_FORGE);
    if(nToken != 0)
    {
        RFFeedForge(oPC, nToken);
        return;
    }

    // Clear any leftover state from previous session.
    SetLocalInt(oPC, RF_LVAR_SEL_RUNE, -1);
    DeleteLocalString(oPC, RF_LVAR_WPN_UUID);
    DeleteLocalString(oPC, RF_LVAR_WPN_NAME);

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - GetNuiScaleDimension(oPC, RF_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - GetNuiScaleDimension(oPC, RF_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, RF_W), GetNuiScaleDimension(oPC, RF_H));

    // Close button in manual title row (window itself has no OS chrome)
    float fBtnH = GetNuiScaleDimension(oPC, 28.0);
    json jTitleLbl = NuiLabel(JsonString("KUZNIA RUNICZNA"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, fBtnH);
    jTitleLbl = NuiStyleForegroundColor(jTitleLbl, NuiColor(185, 150, 100, 255));

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, RF_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 28.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTitleRow = JsonArray();
    jTitleRow = JsonArrayInsert(jTitleRow, jTitleLbl);
    jTitleRow = JsonArrayInsert(jTitleRow, NuiSpacer());
    jTitleRow = JsonArrayInsert(jTitleRow, jCloseBtn);

    json jPadRow = JsonArray();
    jPadRow = JsonArrayInsert(jPadRow, NuiWidth(NuiSpacer(), GetNuiScaleDimension(oPC, 12.0)));
    jPadRow = JsonArrayInsert(jPadRow, RFBuildForgeContent(oPC));
    jPadRow = JsonArrayInsert(jPadRow, NuiWidth(NuiSpacer(), GetNuiScaleDimension(oPC, 12.0)));

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jTitleRow));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jPadRow));
    jRoot = JsonArrayInsert(jRoot, CreateEmptyRow(oPC, 10.0));

    json jWin = NuiWindow(NuiCol(jRoot),
        JsonBool(FALSE),
        NuiBind(RF_BIND_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, RF_WIN_FORGE, RF_EV_SCRIPT);
    NuiSetBind(oPC, nToken, RF_BIND_WIN_GEOM, jGeom);

    RFFeedForge(oPC, nToken);
}

// Refreshes all dynamic binds in the forge window.
void RFFeedForge(object oPC, int nToken)
{
    string sUuid = GetLocalString(oPC, RF_LVAR_WPN_UUID);
    string sName = GetLocalString(oPC, RF_LVAR_WPN_NAME);
    int nSelRune = GetLocalInt(oPC, RF_LVAR_SEL_RUNE); // -1 = none

    // Weapon name / placeholder
    string sWpnLabel = (sUuid == "") ? "(kliknij Wybierz bron)" : sName;
    NuiSetBind(oPC, nToken, RF_BIND_WPN_NAME, JsonString(sWpnLabel));
    NuiSetBind(oPC, nToken, RF_BIND_WPN_ENA,  JsonBool(TRUE));

    // Rune enc states
    int i;
    for(i = 0; i < RF_RUNE_COUNT; i++)
        NuiSetBind(oPC, nToken, RF_BIND_RUNE_ENC + IntToString(i), JsonBool(i == nSelRune));

    // Enchant summary
    NuiSetBind(oPC, nToken, RF_BIND_ENCH_LBL, JsonString(RFEnchantSummary(sUuid)));

    // Cost + forge button
    int bReady = (sUuid != "" && nSelRune >= 0);
    if(bReady)
    {
        int nCurLevel = RFGetEnchantLevel(sUuid, nSelRune);
        if(nCurLevel >= RF_MAX_LEVEL)
        {
            NuiSetBind(oPC, nToken, RF_BIND_COST_LBL,  JsonString("Maksymalny poziom osiagniety (V)"));
            NuiSetBind(oPC, nToken, RF_BIND_FORGE_ENA,  JsonBool(FALSE));
        }
        else
        {
            int nCost = RFGetCost(nCurLevel);
            string sCostLbl = "Koszt: " + IntToString(nCost) + " sztuk zlota"
                + "  |  poziom: " + IntToString(nCurLevel) + " -> " + IntToString(nCurLevel + 1)
                + "  (" + RFDiceLabel(nCurLevel + 1) + ")";
            NuiSetBind(oPC, nToken, RF_BIND_COST_LBL,  JsonString(sCostLbl));
            NuiSetBind(oPC, nToken, RF_BIND_FORGE_ENA,  JsonBool(TRUE));
        }
    }
    else
    {
        NuiSetBind(oPC, nToken, RF_BIND_COST_LBL,  JsonString("Wybierz bron i rune"));
        NuiSetBind(oPC, nToken, RF_BIND_FORGE_ENA,  JsonBool(FALSE));
    }
}


// -----------------------------------------------------------------------
// NUI: Minigame window
// -----------------------------------------------------------------------

json RFBuildMinigameButton(object oPC, int nIdx)
{
    float fBtnSz = GetNuiScaleDimension(oPC, 80.0);
    json jBtn = NuiButton(JsonString(IntToString(nIdx + 1)));
    jBtn = NuiId(jBtn, RF_BTN_MG + IntToString(nIdx));
    jBtn = NuiEnabled(jBtn, NuiBind(RF_BIND_MG_ENA + IntToString(nIdx)));
    jBtn = NuiEncouraged(jBtn, NuiBind(RF_BIND_MG_ENC + IntToString(nIdx)));
    jBtn = NuiWidth(jBtn, fBtnSz);
    jBtn = NuiHeight(jBtn, fBtnSz);
    return jBtn;
}

json RFBuildMGRow(object oPC, int nStart)
{
    json jRow = JsonArray();
    int i;
    for(i = nStart; i < nStart + 3; i++)
        jRow = JsonArrayInsert(jRow, RFBuildMinigameButton(oPC, i));
    return NuiRow(jRow);
}

void RFOpenMinigame(object oPC)
{
    int nToken = NuiFindWindow(oPC, RF_WIN_MINIGAME);
    if(nToken != 0) NuiDestroy(oPC, nToken);

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - GetNuiScaleDimension(oPC, RF_MG_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - GetNuiScaleDimension(oPC, RF_MG_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, RF_MG_W), GetNuiScaleDimension(oPC, RF_MG_H));

    float fLblH = GetNuiScaleDimension(oPC, 28.0);

    json jTitle = NuiLabel(JsonString("PROBA KUZNI"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fLblH);
    jTitle = NuiStyleForegroundColor(jTitle, NuiColor(185, 150, 100, 255));

    json jStatus = NuiLabel(NuiBind(RF_BIND_MG_STATUS),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatus = NuiHeight(jStatus, fLblH);

    json jStep = NuiLabel(NuiBind(RF_BIND_MG_STEP),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStep = NuiHeight(jStep, fLblH);

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(JsonArrayInsert(JsonArray(), jTitle)));
    jRoot = JsonArrayInsert(jRoot, NuiRow(JsonArrayInsert(JsonArray(), jStatus)));
    jRoot = JsonArrayInsert(jRoot, CreateEmptyRow(oPC, 8.0));
    jRoot = JsonArrayInsert(jRoot, RFBuildMGRow(oPC, 0)); // 1 2 3
    jRoot = JsonArrayInsert(jRoot, RFBuildMGRow(oPC, 3)); // 4 5 6
    jRoot = JsonArrayInsert(jRoot, RFBuildMGRow(oPC, 6)); // 7 8 9
    jRoot = JsonArrayInsert(jRoot, CreateEmptyRow(oPC, 8.0));
    jRoot = JsonArrayInsert(jRoot, NuiRow(JsonArrayInsert(JsonArray(), jStep)));

    json jWin = NuiWindow(NuiCol(jRoot),
        JsonBool(FALSE),
        NuiBind(RF_BIND_MG_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),  // closable — closing is treated as abort
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, RF_WIN_MINIGAME, RF_EV_SCRIPT);
    NuiSetBind(oPC, nToken, RF_BIND_MG_GEOM, jGeom);

    // All buttons start disabled and unhighlighted.
    int i;
    for(i = 0; i < 9; i++)
    {
        NuiSetBind(oPC, nToken, RF_BIND_MG_ENA + IntToString(i), JsonBool(FALSE));
        NuiSetBind(oPC, nToken, RF_BIND_MG_ENC + IntToString(i), JsonBool(FALSE));
    }
    NuiSetBind(oPC, nToken, RF_BIND_MG_STATUS, JsonString("Zapamiętaj sekwencję run..."));
    NuiSetBind(oPC, nToken, RF_BIND_MG_STEP,   JsonString(""));
}


// -----------------------------------------------------------------------
// Minigame logic
// -----------------------------------------------------------------------

// Generates a random button sequence of the given length (each 0-8).
json RFGenerateSequence(int nLen)
{
    json jSeq = JsonArray();
    int i;
    for(i = 0; i < nLen; i++)
        jSeq = JsonArrayInsert(jSeq, JsonInt(Random(9)));
    return jSeq;
}

// Sets enc on only the given button index; clears all others.
void RFSetOnlyEnc(object oPC, int nToken, int nBtn)
{
    int i;
    for(i = 0; i < 9; i++)
        NuiSetBind(oPC, nToken, RF_BIND_MG_ENC + IntToString(i), JsonBool(i == nBtn));
}

void RFClearAllEnc(object oPC, int nToken)
{
    int i;
    for(i = 0; i < 9; i++)
        NuiSetBind(oPC, nToken, RF_BIND_MG_ENC + IntToString(i), JsonBool(FALSE));
}

// Starts the minigame: deducts gold, generates sequence, opens window, begins display.
void RFMinigameStart(object oPC)
{
    string sUuid  = GetLocalString(oPC, RF_LVAR_WPN_UUID);
    int nRune     = GetLocalInt(oPC, RF_LVAR_SEL_RUNE);
    int nCurLevel = RFGetEnchantLevel(sUuid, nRune);

    if(nCurLevel >= RF_MAX_LEVEL)
    {
        SendMessageToPC(oPC, "[Kuźnia] Ta runa osiągnęła już maksymalny poziom na tej broni.");
        return;
    }

    // Verify weapon still in inventory.
    object oItem = GetObjectByUUID(sUuid);
    if(!GetIsObjectValid(oItem) || GetItemPossessor(oItem) != oPC)
    {
        SendMessageToPC(oPC, "[Kuźnia] Nie masz już tej broni w ekwipunku.");
        return;
    }

    int nCost = RFGetCost(nCurLevel);
    if(GetGold(oPC) < nCost)
    {
        SendMessageToPC(oPC, "[Kuźnia] Brakuje ci " + IntToString(nCost) + " sztuk złota.");
        return;
    }

    // Deduct gold upfront — attempt costs regardless of outcome.
    AssignCommand(oPC, TakeGoldFromCreature(nCost, oPC, TRUE));
    SetLocalInt(oPC, RF_LVAR_MG_COST, nCost);

    int nLen = RFSequenceLength(nCurLevel);
    json jSeq = RFGenerateSequence(nLen);
    SetLocalJson(oPC, RF_LVAR_MG_SEQ,  jSeq);
    SetLocalInt(oPC,  RF_LVAR_MG_PHASE, 0);  // display phase
    SetLocalInt(oPC,  RF_LVAR_MG_POS,   0);
    SetLocalInt(oPC,  RF_LVAR_MG_DONE,  0);
    // Snapshot these now — the forge CLOSE event fires asynchronously and resets the originals.
    SetLocalString(oPC, RF_LVAR_MG_WPN,  sUuid);
    SetLocalInt(oPC,    RF_LVAR_MG_RUNE, nRune);

    RFOpenMinigame(oPC);

    // Schedule display start after brief pause, and a global timeout.
    float fTimeout = IntToFloat(nLen) * 1.5 + 8.0;
    DelayCommand(0.6, RFMGDisplayHighlight(oPC, 0));
    DelayCommand(fTimeout, RFMinigameFail(oPC));
}

// Highlights button at sequence step nStep, then schedules unhighlight.
void RFMGDisplayHighlight(object oPC, int nStep)
{
    if(GetLocalInt(oPC, RF_LVAR_MG_DONE)) return;

    int nToken = NuiFindWindow(oPC, RF_WIN_MINIGAME);
    if(nToken == 0) return;

    json jSeq = GetLocalJson(oPC, RF_LVAR_MG_SEQ);
    int nLen  = JsonGetLength(jSeq);
    int nBtn  = JsonGetInt(JsonArrayGet(jSeq, nStep));

    RFSetOnlyEnc(oPC, nToken, nBtn);
    NuiSetBind(oPC, nToken, RF_BIND_MG_STATUS,
        JsonString("Zapamiętaj: " + IntToString(nStep + 1) + "/" + IntToString(nLen)));

    DelayCommand(0.65, RFMGDisplayUnhighlight(oPC, nStep));
}

// Clears highlight after showing one step, then advances to next.
void RFMGDisplayUnhighlight(object oPC, int nStep)
{
    if(GetLocalInt(oPC, RF_LVAR_MG_DONE)) return;

    int nToken = NuiFindWindow(oPC, RF_WIN_MINIGAME);
    if(nToken == 0) return;

    RFClearAllEnc(oPC, nToken);

    json jSeq = GetLocalJson(oPC, RF_LVAR_MG_SEQ);
    int nLen  = JsonGetLength(jSeq);

    if(nStep + 1 < nLen)
        DelayCommand(0.25, RFMGDisplayHighlight(oPC, nStep + 1));
    else
        DelayCommand(0.4, RFMGEnableInput(oPC));
}

// Switches from display phase to input phase — enables all buttons.
void RFMGEnableInput(object oPC)
{
    if(GetLocalInt(oPC, RF_LVAR_MG_DONE)) return;

    int nToken = NuiFindWindow(oPC, RF_WIN_MINIGAME);
    if(nToken == 0) return;

    SetLocalInt(oPC, RF_LVAR_MG_PHASE, 1);
    SetLocalInt(oPC, RF_LVAR_MG_POS,   0);

    int i;
    for(i = 0; i < 9; i++)
        NuiSetBind(oPC, nToken, RF_BIND_MG_ENA + IntToString(i), JsonBool(TRUE));

    json jSeq = GetLocalJson(oPC, RF_LVAR_MG_SEQ);
    NuiSetBind(oPC, nToken, RF_BIND_MG_STATUS,
        JsonString("Powtórz sekwencję!"));
    NuiSetBind(oPC, nToken, RF_BIND_MG_STEP,
        JsonString("Krok: 0/" + IntToString(JsonGetLength(jSeq))));
}

// Called on wrong button, timeout, or window close during input.
void RFMinigameFail(object oPC)
{
    if(GetLocalInt(oPC, RF_LVAR_MG_DONE)) return;
    SetLocalInt(oPC, RF_LVAR_MG_DONE, 1);

    int nToken = NuiFindWindow(oPC, RF_WIN_MINIGAME);
    if(nToken != 0) NuiDestroy(oPC, nToken);

    SendMessageToPC(oPC, "[Kuźnia] Rytowanie nie powiodło się. Złoto przepadło w ogniu pieca.");
    FloatingTextStringOnCreature("Pieczęć krwi pulsuje słabo... i gaśnie.", oPC, FALSE);
}

// Called when player correctly repeats the full sequence.
void RFMinigameSuccess(object oPC)
{
    if(GetLocalInt(oPC, RF_LVAR_MG_DONE)) return;
    SetLocalInt(oPC, RF_LVAR_MG_DONE, 1);

    int nToken = NuiFindWindow(oPC, RF_WIN_MINIGAME);
    if(nToken != 0) NuiDestroy(oPC, nToken);

    // Read from snapshot LVARs — the forge window may have already closed and reset the originals.
    string sUuid  = GetLocalString(oPC, RF_LVAR_MG_WPN);
    int nRune     = GetLocalInt(oPC, RF_LVAR_MG_RUNE);
    int nCurLevel = RFGetEnchantLevel(sUuid, nRune);
    int nNewLevel = nCurLevel + 1;

    object oItem = GetObjectByUUID(sUuid);
    if(!GetIsObjectValid(oItem))
    {
        SendMessageToPC(oPC, "[Kuźnia] Broń nie została znaleziona — runa nie może zostać osadzona.");
        return;
    }

    RFApplyEnchant(oItem, nRune, nNewLevel);
    RFUpsertEnchant(GetObjectUUID(oPC), sUuid, nRune, nNewLevel);

    string sMsg = "[Kuźnia] " + RFRuneName(nRune) + " poziom " + IntToString(nNewLevel)
        + " wypalona na " + GetName(oItem) + "!";
    SendMessageToPC(oPC, sMsg);
    FloatingTextStringOnCreature("Runa jarzy się blaskiem mocy!", oPC, FALSE);

    // Re-open forge so player sees updated enchant summary.
    DelayCommand(0.5, RFOpenForge(oPC));
}

// Called from lib_rf_ev.nss when a minigame button is clicked during input phase.
void RFHandleMGButton(object oPC, int nBtn)
{
    if(GetLocalInt(oPC, RF_LVAR_MG_PHASE) != 1) return; // still in display
    if(GetLocalInt(oPC, RF_LVAR_MG_DONE))       return;

    json jSeq  = GetLocalJson(oPC, RF_LVAR_MG_SEQ);
    int nLen   = JsonGetLength(jSeq);
    int nPos   = GetLocalInt(oPC, RF_LVAR_MG_POS);
    int nExpected = JsonGetInt(JsonArrayGet(jSeq, nPos));

    if(nBtn != nExpected)
    {
        RFMinigameFail(oPC);
        return;
    }

    nPos++;
    SetLocalInt(oPC, RF_LVAR_MG_POS, nPos);

    int nToken = NuiFindWindow(oPC, RF_WIN_MINIGAME);
    if(nToken != 0)
    {
        // Brief enc flash on correct button.
        RFSetOnlyEnc(oPC, nToken, nBtn);
        NuiSetBind(oPC, nToken, RF_BIND_MG_STEP,
            JsonString("Krok: " + IntToString(nPos) + "/" + IntToString(nLen)));
        DelayCommand(0.2, RFClearAllEnc(oPC, nToken));
    }

    if(nPos >= nLen)
        RFMinigameSuccess(oPC);
}

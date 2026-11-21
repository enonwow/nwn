#include "lib_alch_def"
#include "sql_alch"

// ----------------------------------------------------------------
// Internal helpers
// ----------------------------------------------------------------

json _AlchColorNormal()  { return NuiColor(220, 200, 160, 255); }
json _AlchColorKnown()   { return NuiColor(160, 220, 160, 255); }
json _AlchColorUnknown() { return NuiColor(120, 120, 120, 255); }
json _AlchColorSelected(){ return NuiColor(255, 210,  80, 255); }
json _AlchColorSuccess()  { return NuiColor(100, 220, 100, 255); }
json _AlchColorFail()     { return NuiColor(220,  80,  80, 255); }
json _AlchColorDiscover() { return NuiColor(180, 140, 255, 255); }

int AlchAnySlotFilled(object oPC)
{
    return (GetLocalString(oPC, ALCH_LVAR_SLOT1) != ""
         || GetLocalString(oPC, ALCH_LVAR_SLOT2) != ""
         || GetLocalString(oPC, ALCH_LVAR_SLOT3) != "");
}

void AlchClearAllSlots(object oPC)
{
    DeleteLocalString(oPC, ALCH_LVAR_SLOT1);
    DeleteLocalString(oPC, ALCH_LVAR_SLOT2);
    DeleteLocalString(oPC, ALCH_LVAR_SLOT3);
    DeleteLocalObject(oPC, ALCH_LVAR_SLOT1_OBJ);
    DeleteLocalObject(oPC, ALCH_LVAR_SLOT2_OBJ);
    DeleteLocalObject(oPC, ALCH_LVAR_SLOT3_OBJ);
}

// ----------------------------------------------------------------
// NUI layout builders
// ----------------------------------------------------------------

// Left panel: recipe list with 10 scrollable rows + brief ingredient preview
json _AlchBuildRecipePanel(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fDescH = GetNuiScaleDimension(oPC, 80.0);
    float fPanW  = GetNuiScaleDimension(oPC, 300.0);

    // Header label
    json jHeader = NuiLabel(JsonString("Znane Przepisy"),
                            JsonInt(NUI_HALIGN_CENTER),
                            JsonInt(NUI_VALIGN_MIDDLE));
    jHeader = NuiHeight(jHeader, GetNuiScaleDimension(oPC, 26.0));

    // Recipe list rows
    json jRows = JsonArray();
    int i;
    for(i = 0; i < ALCH_RCP_ROWS; i++)
    {
        json jBtn = NuiButton(NuiBind(ALCH_BIND_RCP_LABEL + IntToString(i)));
        jBtn = NuiId(jBtn, ALCH_BTN_RCP_ROW + IntToString(i));
        jBtn = NuiEnabled(jBtn, NuiBind(ALCH_BIND_RCP_ENA + IntToString(i)));
        jBtn = NuiHeight(jBtn, fBtnH);
        jBtn = NuiStyleForegroundColor(jBtn, NuiBind(ALCH_BIND_RCP_COLOR + IntToString(i)));
        jRows = JsonArrayInsert(jRows, jBtn);
    }

    json jList = NuiColumn(jRows);
    json jListScroll = NuiScrollbars(jList, JsonInt(NUI_SCROLLBARS_Y));

    // Selected recipe detail
    json jDescLbl = NuiLabel(NuiBind(ALCH_BIND_RCP_DESC),
                             JsonInt(NUI_HALIGN_LEFT),
                             JsonInt(NUI_VALIGN_TOP));
    jDescLbl = NuiHeight(jDescLbl, fDescH);

    json jColItems = JsonArray();
    jColItems = JsonArrayInsert(jColItems, jHeader);
    jColItems = JsonArrayInsert(jColItems, jListScroll);
    jColItems = JsonArrayInsert(jColItems, NuiSpacer());
    jColItems = JsonArrayInsert(jColItems, jDescLbl);

    json jCol = NuiColumn(jColItems);
    jCol = NuiWidth(jCol, fPanW);
    return jCol;
}

// Right panel: recipe details + 3 ingredient slots + brew button + result log
json _AlchBuildWorkbenchPanel(object oPC)
{
    float fBtnH   = GetNuiScaleDimension(oPC, 34.0);
    float fSlotH  = GetNuiScaleDimension(oPC, 36.0);
    float fResH   = GetNuiScaleDimension(oPC, 50.0);

    // Selected recipe name + difficulty
    json jRcpName = NuiLabel(NuiBind(ALCH_BIND_RCP_NAME),
                              JsonInt(NUI_HALIGN_LEFT),
                              JsonInt(NUI_VALIGN_MIDDLE));
    jRcpName = NuiHeight(jRcpName, GetNuiScaleDimension(oPC, 26.0));

    json jDiffLbl = NuiLabel(NuiBind(ALCH_BIND_RCP_DIFF),
                              JsonInt(NUI_HALIGN_RIGHT),
                              JsonInt(NUI_VALIGN_MIDDLE));
    jDiffLbl = NuiHeight(jDiffLbl, GetNuiScaleDimension(oPC, 26.0));
    jDiffLbl = NuiWidth(jDiffLbl, GetNuiScaleDimension(oPC, 120.0));

    json jNameRow = JsonArray();
    jNameRow = JsonArrayInsert(jNameRow, jRcpName);
    jNameRow = JsonArrayInsert(jNameRow, jDiffLbl);

    // Ingredient labels for selected recipe
    json jIngrHeader = NuiLabel(JsonString("Wymagane składniki:"),
                                 JsonInt(NUI_HALIGN_LEFT),
                                 JsonInt(NUI_VALIGN_MIDDLE));
    jIngrHeader = NuiHeight(jIngrHeader, GetNuiScaleDimension(oPC, 20.0));

    json jIngr1 = NuiLabel(NuiBind(ALCH_BIND_RCP_INGR1),
                            JsonInt(NUI_HALIGN_LEFT),
                            JsonInt(NUI_VALIGN_MIDDLE));
    jIngr1 = NuiHeight(jIngr1, GetNuiScaleDimension(oPC, 18.0));

    json jIngr2 = NuiLabel(NuiBind(ALCH_BIND_RCP_INGR2),
                            JsonInt(NUI_HALIGN_LEFT),
                            JsonInt(NUI_VALIGN_MIDDLE));
    jIngr2 = NuiHeight(jIngr2, GetNuiScaleDimension(oPC, 18.0));

    json jIngr3 = NuiLabel(NuiBind(ALCH_BIND_RCP_INGR3),
                            JsonInt(NUI_HALIGN_LEFT),
                            JsonInt(NUI_VALIGN_MIDDLE));
    jIngr3 = NuiHeight(jIngr3, GetNuiScaleDimension(oPC, 18.0));

    // Separator label
    json jSlotHeader = NuiLabel(JsonString("Warzelnia — wrzuć składniki:"),
                                 JsonInt(NUI_HALIGN_LEFT),
                                 JsonInt(NUI_VALIGN_MIDDLE));
    jSlotHeader = NuiHeight(jSlotHeader, GetNuiScaleDimension(oPC, 22.0));

    // 3 ingredient slots, each: [pick button] [clear button]
    float fClearW = GetNuiScaleDimension(oPC, 28.0);
    json jSlots = JsonArray();
    int s;
    for(s = 1; s <= 3; s++)
    {
        string sSuf = IntToString(s);

        json jPickBtn = NuiButton(NuiBind(ALCH_BIND_SLOT_LBL + sSuf));
        jPickBtn = NuiId(jPickBtn, ALCH_BTN_SLOT + sSuf);
        jPickBtn = NuiHeight(jPickBtn, fSlotH);
        jPickBtn = NuiStyleForegroundColor(jPickBtn, NuiBind(ALCH_BIND_SLOT_CLR + sSuf));

        json jClearBtn = NuiButton(JsonString("X"));
        jClearBtn = NuiId(jClearBtn, ALCH_BTN_SLOT_CLR + sSuf);
        jClearBtn = NuiWidth(jClearBtn, fClearW);
        jClearBtn = NuiHeight(jClearBtn, fSlotH);

        json jSlotRow = JsonArray();
        jSlotRow = JsonArrayInsert(jSlotRow, jPickBtn);
        jSlotRow = JsonArrayInsert(jSlotRow, jClearBtn);

        jSlots = JsonArrayInsert(jSlots, NuiRow(jSlotRow));
    }

    json jSlotCol = NuiColumn(jSlots);

    // Brew button
    json jBrewBtn = NuiButton(JsonString("Warzyć"));
    jBrewBtn = NuiId(jBrewBtn, ALCH_BTN_BREW);
    jBrewBtn = NuiEnabled(jBrewBtn, NuiBind(ALCH_BIND_BREW_ENA));
    jBrewBtn = NuiHeight(jBrewBtn, fBtnH);

    // Result label
    json jResultLbl = NuiLabel(NuiBind(ALCH_BIND_RESULT_LBL),
                                JsonInt(NUI_HALIGN_LEFT),
                                JsonInt(NUI_VALIGN_TOP));
    jResultLbl = NuiHeight(jResultLbl, fResH);
    jResultLbl = NuiStyleForegroundColor(jResultLbl, NuiBind(ALCH_BIND_RESULT_COL));

    json jColItems = JsonArray();
    jColItems = JsonArrayInsert(jColItems, NuiRow(jNameRow));
    jColItems = JsonArrayInsert(jColItems, jIngrHeader);
    jColItems = JsonArrayInsert(jColItems, jIngr1);
    jColItems = JsonArrayInsert(jColItems, jIngr2);
    jColItems = JsonArrayInsert(jColItems, jIngr3);
    jColItems = JsonArrayInsert(jColItems, NuiSpacer());
    jColItems = JsonArrayInsert(jColItems, jSlotHeader);
    jColItems = JsonArrayInsert(jColItems, jSlotCol);
    jColItems = JsonArrayInsert(jColItems, NuiSpacer());
    jColItems = JsonArrayInsert(jColItems, jBrewBtn);
    jColItems = JsonArrayInsert(jColItems, jResultLbl);

    return NuiColumn(jColItems);
}

// Full window layout
json _AlchBuildLayout(object oPC)
{
    json jLeft  = _AlchBuildRecipePanel(oPC);
    json jRight = _AlchBuildWorkbenchPanel(oPC);

    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jLeft);
    jMainRow = JsonArrayInsert(jMainRow, NuiSpacer());
    jMainRow = JsonArrayInsert(jMainRow, jRight);

    // Close button in a top bar
    json jCloseBtn = NuiButton(JsonString("Zamknij"));
    jCloseBtn = NuiId(jCloseBtn, ALCH_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 80.0));
    jCloseBtn = NuiHeight(jCloseBtn, GetNuiScaleDimension(oPC, 26.0));

    json jTitleLbl = NuiLabel(JsonString("Stół Alchemiczny"),
                               JsonInt(NUI_HALIGN_LEFT),
                               JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, GetNuiScaleDimension(oPC, 26.0));

    json jTopBar = JsonArray();
    jTopBar = JsonArrayInsert(jTopBar, jTitleLbl);
    jTopBar = JsonArrayInsert(jTopBar, jCloseBtn);

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jTopBar));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jMainRow));

    return NuiColumn(jRoot);
}

// ----------------------------------------------------------------
// Open window
// ----------------------------------------------------------------

void AlchOpenWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, ALCH_WINDOW);
    if(nToken != 0)
    {
        // Window already open — just refresh binds (layout is immutable without NuiGroup swap)
        AlchFeedRecipeList(oPC, nToken);
        AlchFeedSlotLabels(oPC, nToken);
        return;
    }

    float fW = GetNuiScaleDimension(oPC, ALCH_W);
    float fH = GetNuiScaleDimension(oPC, ALCH_H);

    json jGeom = NuiRect(
        (GetNuiScaleDimension(oPC, 1920.0) - fW) / 2.0,
        (GetNuiScaleDimension(oPC, 1080.0) - fH) / 2.0,
        fW, fH);

    json jWin = NuiWindow(
        _AlchBuildLayout(oPC),
        JsonString("Stół Alchemiczny"),
        NuiBind(ALCH_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    nToken = NuiCreate(oPC, jWin, ALCH_WINDOW);
    NuiSetEventScript(oPC, nToken, ALCH_EV_SCRIPT);
    NuiSetBind(oPC, nToken, ALCH_WIN_GEOM, jGeom);

    SetLocalInt(oPC, ALCH_LVAR_SEL_RCP, -1);
    AlchClearAllSlots(oPC);
    AlchFeedRecipeList(oPC, nToken);
    AlchFeedSlotLabels(oPC, nToken);
    AlchFeedRecipeInfo(oPC, nToken, -1);
}

// ----------------------------------------------------------------
// Feed functions
// ----------------------------------------------------------------

void AlchFeedRecipeList(object oPC, int nToken)
{
    int nSel = GetLocalInt(oPC, ALCH_LVAR_SEL_RCP);
    int i;
    for(i = 0; i < ALCH_RCP_ROWS; i++)
    {
        string sSuf = IntToString(i);
        if(i >= ALCH_RECIPE_COUNT)
        {
            NuiSetBind(oPC, nToken, ALCH_BIND_RCP_LABEL + sSuf, JsonString(""));
            NuiSetBind(oPC, nToken, ALCH_BIND_RCP_ENA   + sSuf, JsonBool(FALSE));
            NuiSetBind(oPC, nToken, ALCH_BIND_RCP_COLOR + sSuf, _AlchColorUnknown());
            continue;
        }

        int nKnown = AlchIsRecipeKnown(oPC, i);
        string sLabel = nKnown ? AlchGetRecipeName(i) : "??? (nieznany)";
        json jColor   = (i == nSel)
                            ? _AlchColorSelected()
                            : (nKnown ? _AlchColorKnown() : _AlchColorUnknown());

        NuiSetBind(oPC, nToken, ALCH_BIND_RCP_LABEL + sSuf, JsonString(sLabel));
        NuiSetBind(oPC, nToken, ALCH_BIND_RCP_ENA   + sSuf, JsonBool(nKnown));
        NuiSetBind(oPC, nToken, ALCH_BIND_RCP_COLOR + sSuf, jColor);
    }
}

void AlchFeedSlotLabels(object oPC, int nToken)
{
    string sTag;
    string sLbl;
    json jColor;

    sTag   = GetLocalString(oPC, ALCH_LVAR_SLOT1);
    sLbl   = (sTag != "") ? sTag : "[ Pusty slot 1 ]";
    jColor = (sTag != "") ? _AlchColorKnown() : _AlchColorNormal();
    NuiSetBind(oPC, nToken, ALCH_BIND_SLOT_LBL + "1", JsonString(sLbl));
    NuiSetBind(oPC, nToken, ALCH_BIND_SLOT_CLR + "1", jColor);

    sTag   = GetLocalString(oPC, ALCH_LVAR_SLOT2);
    sLbl   = (sTag != "") ? sTag : "[ Pusty slot 2 ]";
    jColor = (sTag != "") ? _AlchColorKnown() : _AlchColorNormal();
    NuiSetBind(oPC, nToken, ALCH_BIND_SLOT_LBL + "2", JsonString(sLbl));
    NuiSetBind(oPC, nToken, ALCH_BIND_SLOT_CLR + "2", jColor);

    sTag   = GetLocalString(oPC, ALCH_LVAR_SLOT3);
    sLbl   = (sTag != "") ? sTag : "[ Pusty slot 3 ]";
    jColor = (sTag != "") ? _AlchColorKnown() : _AlchColorNormal();
    NuiSetBind(oPC, nToken, ALCH_BIND_SLOT_LBL + "3", JsonString(sLbl));
    NuiSetBind(oPC, nToken, ALCH_BIND_SLOT_CLR + "3", jColor);

    NuiSetBind(oPC, nToken, ALCH_BIND_BREW_ENA, JsonBool(AlchAnySlotFilled(oPC)));
}

void AlchFeedRecipeInfo(object oPC, int nToken, int nRecipeId)
{
    if(nRecipeId < 0)
    {
        NuiSetBind(oPC, nToken, ALCH_BIND_RCP_NAME,  JsonString("— wybierz przepis —"));
        NuiSetBind(oPC, nToken, ALCH_BIND_RCP_DESC,  JsonString(""));
        NuiSetBind(oPC, nToken, ALCH_BIND_RCP_INGR1, JsonString(""));
        NuiSetBind(oPC, nToken, ALCH_BIND_RCP_INGR2, JsonString(""));
        NuiSetBind(oPC, nToken, ALCH_BIND_RCP_INGR3, JsonString(""));
        NuiSetBind(oPC, nToken, ALCH_BIND_RCP_DIFF,  JsonString(""));
        return;
    }

    NuiSetBind(oPC, nToken, ALCH_BIND_RCP_NAME,
        JsonString(AlchGetRecipeName(nRecipeId)));
    NuiSetBind(oPC, nToken, ALCH_BIND_RCP_DESC,
        JsonString(AlchGetRecipeDesc(nRecipeId)));
    NuiSetBind(oPC, nToken, ALCH_BIND_RCP_INGR1,
        JsonString("  1. " + AlchGetRecipeIngrLabel(nRecipeId, 1)));
    NuiSetBind(oPC, nToken, ALCH_BIND_RCP_INGR2,
        JsonString("  2. " + AlchGetRecipeIngrLabel(nRecipeId, 2)));
    NuiSetBind(oPC, nToken, ALCH_BIND_RCP_INGR3,
        JsonString("  3. " + AlchGetRecipeIngrLabel(nRecipeId, 3)));
    NuiSetBind(oPC, nToken, ALCH_BIND_RCP_DIFF,
        JsonString("Trudność: " + AlchDifficultyLabel(AlchGetRecipeDifficulty(nRecipeId))));

    NuiSetBind(oPC, nToken, ALCH_BIND_RESULT_LBL, JsonString(""));
}

// ----------------------------------------------------------------
// Brewing
// ----------------------------------------------------------------

void AlchBrew(object oPC, int nToken)
{
    string sTag1 = GetLocalString(oPC, ALCH_LVAR_SLOT1);
    string sTag2 = GetLocalString(oPC, ALCH_LVAR_SLOT2);
    string sTag3 = GetLocalString(oPC, ALCH_LVAR_SLOT3);

    if(sTag1 == "" && sTag2 == "" && sTag3 == "")
    {
        NuiSetBind(oPC, nToken, ALCH_BIND_RESULT_LBL,
            JsonString("Warzelnia jest pusta. Wrzuć składniki."));
        NuiSetBind(oPC, nToken, ALCH_BIND_RESULT_COL, _AlchColorFail());
        return;
    }

    string sSig = AlchBuildSignature(sTag1, sTag2, sTag3);
    int nRecipeId = AlchFindRecipeBySignature(sSig);

    // Consume slot items from inventory
    object oItem1 = GetLocalObject(oPC, ALCH_LVAR_SLOT1_OBJ);
    object oItem2 = GetLocalObject(oPC, ALCH_LVAR_SLOT2_OBJ);
    object oItem3 = GetLocalObject(oPC, ALCH_LVAR_SLOT3_OBJ);

    if(sTag1 != "" && !GetIsObjectValid(oItem1))
    {
        NuiSetBind(oPC, nToken, ALCH_BIND_RESULT_LBL,
            JsonString("Nie znaleziono składnika w ekwipunku. Odśwież sloty."));
        NuiSetBind(oPC, nToken, ALCH_BIND_RESULT_COL, _AlchColorFail());
        return;
    }
    if(sTag2 != "" && !GetIsObjectValid(oItem2))
    {
        NuiSetBind(oPC, nToken, ALCH_BIND_RESULT_LBL,
            JsonString("Nie znaleziono składnika w ekwipunku. Odśwież sloty."));
        NuiSetBind(oPC, nToken, ALCH_BIND_RESULT_COL, _AlchColorFail());
        return;
    }
    if(sTag3 != "" && !GetIsObjectValid(oItem3))
    {
        NuiSetBind(oPC, nToken, ALCH_BIND_RESULT_LBL,
            JsonString("Nie znaleziono składnika w ekwipunku. Odśwież sloty."));
        NuiSetBind(oPC, nToken, ALCH_BIND_RESULT_COL, _AlchColorFail());
        return;
    }

    // Destroy ingredients regardless of outcome
    if(GetIsObjectValid(oItem1)) DestroyObject(oItem1);
    if(GetIsObjectValid(oItem2)) DestroyObject(oItem2);
    if(GetIsObjectValid(oItem3)) DestroyObject(oItem3);
    AlchClearAllSlots(oPC);
    AlchFeedSlotLabels(oPC, nToken);

    if(nRecipeId < 0)
    {
        // Unknown combination — 30% chance of acid splash
        int nExplode = (Random(100) < 30);
        if(nExplode)
        {
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectDamage(d6(2), DAMAGE_TYPE_ACID), oPC);
            NuiSetBind(oPC, nToken, ALCH_BIND_RESULT_LBL,
                JsonString("BUCH! Niestabilna mieszanina wybuchła kwasem. Składniki zniszczone."));
            NuiSetBind(oPC, nToken, ALCH_BIND_RESULT_COL, _AlchColorFail());
            FloatingTextStringOnCreature(
                "Niestabilna mieszanina wybucha kwasem!", oPC, FALSE);
        }
        else
        {
            NuiSetBind(oPC, nToken, ALCH_BIND_RESULT_LBL,
                JsonString("Połączenie nic nie dało. Składniki uległy rozkładowi."));
            NuiSetBind(oPC, nToken, ALCH_BIND_RESULT_COL, _AlchColorFail());
        }
        return;
    }

    int nKnewBefore = AlchIsRecipeKnown(oPC, nRecipeId);

    if(!nKnewBefore)
    {
        // Discovery: learn recipe, bonus XP
        AlchLearnRecipe(oPC, nRecipeId);
        GiveXPToCreature(oPC, ALCH_XP_DISCOVER);
        NuiSetBind(oPC, nToken, ALCH_BIND_RESULT_LBL,
            JsonString("Odkryto nowy przepis: " + AlchGetRecipeName(nRecipeId)
                     + "! Zdobyto " + IntToString(ALCH_XP_DISCOVER) + " PD."));
        NuiSetBind(oPC, nToken, ALCH_BIND_RESULT_COL, _AlchColorDiscover());
        FloatingTextStringOnCreature(
            "Odkryto przepis: " + AlchGetRecipeName(nRecipeId) + "!", oPC, FALSE);
        AlchFeedRecipeList(oPC, nToken);
    }

    // Create result item
    string sResref = AlchGetRecipeResultResref(nRecipeId);
    object oResult = CreateItemOnObject(sResref, oPC);

    if(!GetIsObjectValid(oResult))
    {
        // Resref not found — still award discovery, notify DM
        SendMessageToAllDMs("[Alchemy] Brak resref: " + sResref
                          + " dla przepisu " + IntToString(nRecipeId));
        if(!nKnewBefore) return;
        NuiSetBind(oPC, nToken, ALCH_BIND_RESULT_LBL,
            JsonString("Warzenie zakończone, lecz rezultat wyparował. Skontaktuj się z DM."));
        NuiSetBind(oPC, nToken, ALCH_BIND_RESULT_COL, _AlchColorFail());
        return;
    }

    AlchIncrementBrewCount(oPC, nRecipeId);
    GiveXPToCreature(oPC, ALCH_XP_BREW_BASE * AlchGetRecipeDifficulty(nRecipeId));

    if(nKnewBefore)
    {
        NuiSetBind(oPC, nToken, ALCH_BIND_RESULT_LBL,
            JsonString("Uwarzono: " + GetName(oResult)
                     + ". Zdobyto "
                     + IntToString(ALCH_XP_BREW_BASE * AlchGetRecipeDifficulty(nRecipeId))
                     + " PD."));
        NuiSetBind(oPC, nToken, ALCH_BIND_RESULT_COL, _AlchColorSuccess());
    }
}

// ----------------------------------------------------------------
// Targeting — called from sys_on_target
// ----------------------------------------------------------------

void AlchHandleTargeting(object oPC)
{
    int nSlot = GetLocalInt(oPC, ALCH_LVAR_TARGETING);
    DeleteLocalInt(oPC, ALCH_LVAR_TARGETING);

    if(nSlot < 1 || nSlot > 3) return;

    int nToken = NuiFindWindow(oPC, ALCH_WINDOW);
    if(nToken == 0) return;

    object oItem = GetTargetingModeSelectedObject();
    if(!GetIsObjectValid(oItem) || GetItemPossessor(oItem) != oPC)
    {
        SendMessageToPC(oPC, "[Alchemia] Musisz wybrać przedmiot ze swojego ekwipunku.");
        return;
    }

    string sSlotVar     = (nSlot == 1) ? ALCH_LVAR_SLOT1
                        : (nSlot == 2) ? ALCH_LVAR_SLOT2 : ALCH_LVAR_SLOT3;
    string sSlotObjVar  = (nSlot == 1) ? ALCH_LVAR_SLOT1_OBJ
                        : (nSlot == 2) ? ALCH_LVAR_SLOT2_OBJ : ALCH_LVAR_SLOT3_OBJ;

    // Check the item isn't already in another slot
    if(oItem == GetLocalObject(oPC, ALCH_LVAR_SLOT1_OBJ)
    || oItem == GetLocalObject(oPC, ALCH_LVAR_SLOT2_OBJ)
    || oItem == GetLocalObject(oPC, ALCH_LVAR_SLOT3_OBJ))
    {
        SendMessageToPC(oPC, "[Alchemia] Ten składnik jest już w warzelni.");
        return;
    }

    SetLocalString(oPC, sSlotVar, GetTag(oItem));
    SetLocalObject(oPC, sSlotObjVar, oItem);

    AlchFeedSlotLabels(oPC, nToken);
}

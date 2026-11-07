// lib_wca.nss — Witch Cauldron: NUI layout, brewing logic, event helpers
#include "lib_wca_def"

// ================================================================
// NUI layout builders
// ================================================================

json WcaBuildRecipeListPanel(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fHdrH  = GetNuiScaleDimension(oPC, 24.0);
    float fListH = GetNuiScaleDimension(oPC, 160.0);

    // Header label
    json jHdr = NuiLabel(JsonString("Receptury"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdr = NuiHeight(jHdr, fHdrH);

    // List template: single button column filling full width
    json jCell = NuiListTemplateCell(
        NuiId(
            NuiEnabled(
                NuiButton(NuiBind(WCA_BIND_REC_NAMES)),
                NuiBind(WCA_BIND_REC_ENC)),
            WCA_BTN_REC_ROW),
        -1.0, TRUE);
    json jTemplate = JsonArray();
    jTemplate = JsonArrayInsert(jTemplate, jCell);
    json jList = NuiList(jTemplate, NuiBind(WCA_BIND_REC_ENC), fBtnH);
    jList = NuiHeight(jList, fListH);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jHdr)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jList)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), NuiSpacer())));

    return NuiCol(jCol);
}

json WcaBuildSlotRow(object oPC, int nSlot)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fLblW  = GetNuiScaleDimension(oPC, 160.0);
    float fBtnW  = GetNuiScaleDimension(oPC, 55.0);

    // Slot label
    json jLbl = NuiLabel(NuiBind(WCA_BIND_SLOT_LBL + IntToString(nSlot)),
                         JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLbl = NuiWidth(jLbl, fLblW);
    jLbl = NuiHeight(jLbl, fBtnH);

    // Add button
    json jAdd = NuiId(
        NuiEnabled(
            NuiButton(JsonString("Dodaj")),
            NuiBind(WCA_BIND_ADD_ENA + IntToString(nSlot))),
        WCA_BTN_SLOT_ADD + IntToString(nSlot));
    jAdd = NuiWidth(jAdd, fBtnW);
    jAdd = NuiHeight(jAdd, fBtnH);
    jAdd = NuiTooltip(jAdd, JsonString("Wybierz składnik z ekwipunku"));

    // Remove button
    json jRmv = NuiId(
        NuiEnabled(
            NuiButton(JsonString("Usuń")),
            NuiBind(WCA_BIND_SLOT_ENA + IntToString(nSlot))),
        WCA_BTN_SLOT_REMOVE + IntToString(nSlot));
    jRmv = NuiWidth(jRmv, fBtnW);
    jRmv = NuiHeight(jRmv, fBtnH);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jLbl);
    jRow = JsonArrayInsert(jRow, jAdd);
    jRow = JsonArrayInsert(jRow, jRmv);

    return NuiRow(jRow);
}

json WcaBuildDetailPanel(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fDescH = GetNuiScaleDimension(oPC, 50.0);
    float fReqH  = GetNuiScaleDimension(oPC, 36.0);
    float fProgH = GetNuiScaleDimension(oPC, 20.0);
    float fSpH   = GetNuiScaleDimension(oPC, 6.0);

    // Recipe name
    json jName = NuiLabel(NuiBind(WCA_BIND_REC_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiHeight(jName, fBtnH);

    // Recipe description (multi-line via taller label)
    json jDesc = NuiLabel(NuiBind(WCA_BIND_REC_DESC), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jDesc = NuiHeight(jDesc, fDescH);

    // Required ingredients label
    json jReqLbl = NuiLabel(NuiBind(WCA_BIND_REQ_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jReqLbl = NuiHeight(jReqLbl, fReqH);

    // Separator label
    json jSepLbl = NuiLabel(JsonString("— Kocioł —"), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jSepLbl = NuiHeight(jSepLbl, fBtnH);

    // 4 slot rows
    json jSlot0 = WcaBuildSlotRow(oPC, 0);
    json jSlot1 = WcaBuildSlotRow(oPC, 1);
    json jSlot2 = WcaBuildSlotRow(oPC, 2);
    json jSlot3 = WcaBuildSlotRow(oPC, 3);

    // Status label
    json jStatus = NuiLabel(NuiBind(WCA_BIND_STATUS), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatus = NuiHeight(jStatus, fBtnH);

    // Progress bar (visible during brewing)
    json jProg = NuiProgress(NuiBind(WCA_BIND_PROGRESS));
    jProg = NuiHeight(jProg, fProgH);
    jProg = NuiVisible(jProg, NuiBind(WCA_BIND_PROG_VIS));

    // Brew button
    json jBrew = NuiId(
        NuiEnabled(NuiButton(JsonString("Parz!")), NuiBind(WCA_BIND_BREW_ENA)),
        WCA_BTN_BREW);
    jBrew = NuiHeight(jBrew, fBtnH);
    jBrew = NuiTooltip(jBrew, JsonString("Rozpocznij rytuał warzenia"));

    json jBottomRow = JsonArray();
    jBottomRow = JsonArrayInsert(jBottomRow, jStatus);
    jBottomRow = JsonArrayInsert(jBottomRow, jBrew);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jName)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jDesc)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jReqLbl)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jSepLbl)));
    jCol = JsonArrayInsert(jCol, jSlot0);
    jCol = JsonArrayInsert(jCol, jSlot1);
    jCol = JsonArrayInsert(jCol, jSlot2);
    jCol = JsonArrayInsert(jCol, jSlot3);
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jProg)));
    jCol = JsonArrayInsert(jCol, NuiRow(jBottomRow));

    return NuiCol(jCol);
}

json WcaBuildLayout(object oPC)
{
    float fW     = GetNuiScaleDimension(oPC, WCA_W);
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fLPanW = GetNuiScaleDimension(oPC, 180.0);

    // Title bar
    json jTitle = NuiLabel(JsonString("Wiedźmi Kocioł"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);

    json jClose = NuiId(NuiButton(JsonString("Zamknij")), WCA_BTN_CLOSE);
    jClose = NuiHeight(jClose, fBtnH);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 70.0));

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitle);
    jTopRow = JsonArrayInsert(jTopRow, jClose);

    // Left panel (recipe list) with fixed width
    json jLeftPanel = WcaBuildRecipeListPanel(oPC);
    jLeftPanel = NuiWidth(jLeftPanel, fLPanW);

    // Spacer between panels
    json jSep = NuiWidth(NuiSpacer(), GetNuiScaleDimension(oPC, 8.0));

    // Right panel (details + slots)
    json jRightPanel = WcaBuildDetailPanel(oPC);

    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jLeftPanel);
    jMainRow = JsonArrayInsert(jMainRow, jSep);
    jMainRow = JsonArrayInsert(jMainRow, jRightPanel);

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jTopRow));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jMainRow));

    return NuiCol(jRoot);
}

// ================================================================
// Window open / data feed
// ================================================================

void WcaOpenWindow(object oPC, object oCauldron)
{
    int nToken = NuiFindWindow(oPC, WCA_WINDOW);
    if(nToken != 0)
    {
        NuiSetGroupLayout(oPC, nToken, "root", WcaBuildLayout(oPC));
    }
    else
    {
        float fW = GetNuiScaleDimension(oPC, WCA_W);
        float fH = GetNuiScaleDimension(oPC, WCA_H);
        json jGeom = NuiRect(100.0, 100.0, fW, fH);

        nToken = NuiCreate(oPC, WcaBuildLayout(oPC), WCA_WINDOW);
        NuiSetBind(oPC, nToken, WCA_WIN_GEOM, jGeom);
    }

    SetLocalString(oPC, WCA_LVAR_CAULDRON, GetObjectUUID(oCauldron));
    SetLocalInt(oPC, WCA_LVAR_SEL_REC, -1);
    SetLocalInt(oPC, WCA_LVAR_BREWING, 0);

    // Reset slots if none stored yet
    json jSlots = GetLocalJson(oPC, WCA_LVAR_SLOTS);
    if(JsonGetType(jSlots) != JSON_TYPE_ARRAY)
        SetLocalJson(oPC, WCA_LVAR_SLOTS, WcaInitSlots());

    WcaFeedRecipeList(oPC, nToken);
    WcaFeedSelectedRecipe(oPC, nToken);
    WcaFeedSlots(oPC, nToken);

    NuiSetBind(oPC, nToken, WCA_BIND_STATUS,   JsonString("Wybierz recepturę, by zacząć."));
    NuiSetBind(oPC, nToken, WCA_BIND_PROGRESS, JsonFloat(0.0));
    NuiSetBind(oPC, nToken, WCA_BIND_PROG_VIS, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WCA_BIND_BREW_ENA, JsonBool(FALSE));
}

void WcaFeedRecipeList(object oPC, int nToken)
{
    json jKnown = WcaGetKnownRecipes(oPC);
    int  nCount = JsonGetLength(jKnown);

    json jNames = JsonArray();
    json jEnc   = JsonArray();
    int i;
    for(i = 0; i < nCount; i++)
    {
        int nId = JsonGetInt(JsonArrayGet(jKnown, i));
        jNames = JsonArrayInsert(jNames, JsonString(WcaGetRecipeName(nId)));
        jEnc   = JsonArrayInsert(jEnc,   JsonBool(TRUE));
    }

    if(nCount == 0)
    {
        jNames = JsonArrayInsert(jNames, JsonString("— brak —"));
        jEnc   = JsonArrayInsert(jEnc,   JsonBool(FALSE));
    }

    NuiSetBind(oPC, nToken, WCA_BIND_REC_NAMES, jNames);
    NuiSetBind(oPC, nToken, WCA_BIND_REC_ENC,   jEnc);
}

void WcaFeedSelectedRecipe(object oPC, int nToken)
{
    int nSel = GetLocalInt(oPC, WCA_LVAR_SEL_REC);

    if(nSel < 0)
    {
        NuiSetBind(oPC, nToken, WCA_BIND_REC_NAME, JsonString(""));
        NuiSetBind(oPC, nToken, WCA_BIND_REC_DESC, JsonString("Wybierz recepturę z listy."));
        NuiSetBind(oPC, nToken, WCA_BIND_REQ_LBL,  JsonString(""));
        return;
    }

    NuiSetBind(oPC, nToken, WCA_BIND_REC_NAME, JsonString(WcaGetRecipeName(nSel)));
    NuiSetBind(oPC, nToken, WCA_BIND_REC_DESC, JsonString(WcaGetRecipeDesc(nSel)));

    // Build required ingredients text
    json jIng = WcaGetRecipeIngredients(nSel);
    string sReq = "Wymagane: ";
    int nFirst = TRUE;
    int i;
    for(i = 0; i < WCA_SLOTS; i++)
    {
        string sTag = JsonGetString(JsonArrayGet(jIng, i));
        if(sTag != "")
        {
            if(!nFirst) sReq += ", ";
            sReq += WcaGetIngredientName(sTag);
            nFirst = FALSE;
        }
    }
    NuiSetBind(oPC, nToken, WCA_BIND_REQ_LBL, JsonString(sReq));
}

void WcaFeedSlots(object oPC, int nToken)
{
    json jSlots  = WcaGetSlots(oPC);
    int  nSelRec = GetLocalInt(oPC, WCA_LVAR_SEL_REC);
    int  nBrewing = GetLocalInt(oPC, WCA_LVAR_BREWING);

    // Get required ingredient count for currently selected recipe
    int nReqCount = 0;
    if(nSelRec >= 0)
        nReqCount = WcaGetRecipeIngredientCount(nSelRec);

    int nFilled = WcaCountFilledSlots(jSlots);
    int i;
    for(i = 0; i < WCA_SLOTS; i++)
    {
        json jSlot = JsonArrayGet(jSlots, i);
        int bFilled = (JsonGetType(jSlot) != JSON_TYPE_NULL);

        string sLbl;
        if(bFilled)
            sLbl = IntToString(i + 1) + ": " + JsonGetString(JsonObjectGet(jSlot, "name"));
        else
            sLbl = IntToString(i + 1) + ": — pustka —";

        NuiSetBind(oPC, nToken, WCA_BIND_SLOT_LBL + IntToString(i), JsonString(sLbl));

        // Remove enabled only if slot is filled and not brewing
        NuiSetBind(oPC, nToken, WCA_BIND_SLOT_ENA + IntToString(i),
                   JsonBool(bFilled && !nBrewing));

        // Add enabled only if slot is empty, a recipe is selected, slot index < required count, and not brewing
        int bAddEna = (!bFilled && nSelRec >= 0 && i < nReqCount && !nBrewing);
        NuiSetBind(oPC, nToken, WCA_BIND_ADD_ENA + IntToString(i), JsonBool(bAddEna));
    }

    // Brew button: enabled when recipe selected, correct number of ingredients placed, not brewing
    int bBrewEna = (nSelRec >= 0 && nFilled == nReqCount && nReqCount > 0 && !nBrewing);
    NuiSetBind(oPC, nToken, WCA_BIND_BREW_ENA, JsonBool(bBrewEna));
}

// ================================================================
// Ingredient targeting
// ================================================================

// Called when player clicks "Dodaj" on slot i — enters targeting mode
void WcaEnterTargetMode(object oPC, int nSlotIndex)
{
    SetLocalInt(oPC, WCA_LVAR_TARG_SLOT, nSlotIndex);
    EnterTargetingMode(oPC, OBJECT_TYPE_ITEM);
    SendMessageToPC(oPC, "[Kocioł] Kliknij składnik w ekwipunku...");
}

// Called from sys_on_target.nss — OBJECT_SELF = PC (or MODULE, check convention)
void WcaOnPlayerTarget(object oPC)
{
    int nToken = NuiFindWindow(oPC, WCA_WINDOW);
    if(nToken == 0) return;

    if(GetLocalInt(oPC, WCA_LVAR_BREWING)) return;

    int nSlot = GetLocalInt(oPC, WCA_LVAR_TARG_SLOT);

    object oItem = GetTargetingModeSelectedObject();
    if(!GetIsObjectValid(oItem) || GetItemPossessor(oItem) != oPC)
    {
        SendMessageToPC(oPC, "[Kocioł] Możesz dodać tylko przedmiot z własnego ekwipunku.");
        WcaFeedSlots(oPC, nToken);
        return;
    }

    string sTag = GetTag(oItem);
    if(!WcaIsKnownIngredient(sTag))
    {
        SendMessageToPC(oPC, "[Kocioł] Ten przedmiot nie jest składnikiem żadnej receptury.");
        WcaFeedSlots(oPC, nToken);
        return;
    }

    // Check slot not already filled
    json jSlots = WcaGetSlots(oPC);
    if(JsonGetType(JsonArrayGet(jSlots, nSlot)) != JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Kocioł] Slot już zajęty.");
        WcaFeedSlots(oPC, nToken);
        return;
    }

    // Store ingredient and destroy item
    json jEntry = JsonObject();
    jEntry = JsonObjectSet(jEntry, "tag",  JsonString(sTag));
    jEntry = JsonObjectSet(jEntry, "name", JsonString(WcaGetIngredientName(sTag)));
    jSlots = JsonArraySet(jSlots, nSlot, jEntry);
    SetLocalJson(oPC, WCA_LVAR_SLOTS, jSlots);
    DestroyObject(oItem);

    NuiSetBind(oPC, nToken, WCA_BIND_STATUS, JsonString("Dodano: " + WcaGetIngredientName(sTag) + "."));
    WcaFeedSlots(oPC, nToken);
}

// Removes an ingredient from a slot, recreating the item in PC inventory
void WcaRemoveSlotIngredient(object oPC, int nToken, int nSlot)
{
    json jSlots = WcaGetSlots(oPC);
    json jEntry = JsonArrayGet(jSlots, nSlot);
    if(JsonGetType(jEntry) == JSON_TYPE_NULL) return;

    string sTag  = JsonGetString(JsonObjectGet(jEntry, "tag"));
    string sName = JsonGetString(JsonObjectGet(jEntry, "name"));

    // Recreate item by tag (requires item blueprint in module)
    object oItem = CreateItemOnObject(sTag, oPC, 1);
    if(!GetIsObjectValid(oItem))
    {
        // Blueprint not found — create a placeholder miscellaneous item
        oItem = CreateItemOnObject("nw_it_novel001", oPC, 1);
        if(GetIsObjectValid(oItem))
            SetName(oItem, sName);
    }

    jSlots = JsonArraySet(jSlots, nSlot, JsonNull());
    SetLocalJson(oPC, WCA_LVAR_SLOTS, jSlots);

    NuiSetBind(oPC, nToken, WCA_BIND_STATUS, JsonString("Usunięto: " + sName + "."));
    WcaFeedSlots(oPC, nToken);
}

// ================================================================
// Brewing ritual
// ================================================================

// Forward declarations for mutual recursion
void WcaBrewComplete(object oPC, int nToken);
void WcaBrewBackfire(object oPC, int nToken);

// Recursive progress updater — runs every WCA_BREW_TICK seconds
void WcaBrewTick(object oPC, int nToken, float fProgress)
{
    if(!GetIsObjectValid(oPC)) return;
    if(NuiFindWindow(oPC, WCA_WINDOW) != nToken) return;
    if(!GetLocalInt(oPC, WCA_LVAR_BREWING)) return;

    float fNext = fProgress + (WCA_BREW_TICK / WCA_BREW_TIME);
    if(fNext >= 1.0) fNext = 1.0;

    NuiSetBind(oPC, nToken, WCA_BIND_PROGRESS, JsonFloat(fNext));

    if(fNext >= 1.0)
    {
        WcaBrewComplete(oPC, nToken);
        return;
    }

    DelayCommand(WCA_BREW_TICK, WcaBrewTick(oPC, nToken, fNext));
}

void WcaStartBrewing(object oPC, int nToken)
{
    SetLocalInt(oPC, WCA_LVAR_BREWING, 1);
    NuiSetBind(oPC, nToken, WCA_BIND_PROG_VIS, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, WCA_BIND_PROGRESS, JsonFloat(0.0));
    NuiSetBind(oPC, nToken, WCA_BIND_STATUS,   JsonString("Rytuał trwa... Nie ruszaj się."));
    NuiSetBind(oPC, nToken, WCA_BIND_BREW_ENA, JsonBool(FALSE));
    WcaFeedSlots(oPC, nToken);

    // Atmospheric effect
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                        EffectVisualEffect(VFX_DUR_SPELLTURNING), oPC, WCA_BREW_TIME);

    DelayCommand(WCA_BREW_TICK, WcaBrewTick(oPC, nToken, 0.0));
}

void WcaBrewComplete(object oPC, int nToken)
{
    SetLocalInt(oPC, WCA_LVAR_BREWING, 0);
    NuiSetBind(oPC, nToken, WCA_BIND_PROG_VIS, JsonBool(FALSE));

    int nSelRec  = GetLocalInt(oPC, WCA_LVAR_SEL_REC);
    json jSlots  = WcaGetSlots(oPC);

    if(!WcaIngredientsMatch(jSlots, nSelRec))
    {
        WcaBrewBackfire(oPC, nToken);
        return;
    }

    // Success — create result item
    string sResref = WcaGetRecipeResultResref(nSelRec);
    object oResult = CreateItemOnObject(sResref, oPC, 1);
    if(!GetIsObjectValid(oResult))
    {
        // Module lacks the blueprint; use a named placeholder
        oResult = CreateItemOnObject("nw_it_novel001", oPC, 1);
        if(GetIsObjectValid(oResult))
            SetName(oResult, WcaGetRecipeName(nSelRec));
    }

    WcaLogBrew(oPC, nSelRec, TRUE);

    // Clear slots after success
    SetLocalJson(oPC, WCA_LVAR_SLOTS, WcaInitSlots());
    SetLocalInt(oPC, WCA_LVAR_SEL_REC, -1);

    string sMsg = "Kocioł bulgocze i wydaje z siebie: " + WcaGetRecipeName(nSelRec) + "!";
    FloatingTextStringOnCreature(sMsg, oPC, FALSE);
    SendMessageToPC(oPC, "[Kocioł] " + sMsg);

    ApplyEffectToObject(DURATION_TYPE_INSTANT,
                        EffectVisualEffect(VFX_IMP_MAGIC_PROTECTION), oPC);

    WcaFeedRecipeList(oPC, nToken);
    WcaFeedSelectedRecipe(oPC, nToken);
    WcaFeedSlots(oPC, nToken);
    NuiSetBind(oPC, nToken, WCA_BIND_STATUS, JsonString("Gotowe! Sprawdź ekwipunek."));
}

void WcaBrewBackfire(object oPC, int nToken)
{
    // Ingredients already consumed — punish the mistake
    WcaLogBrew(oPC, GetLocalInt(oPC, WCA_LVAR_SEL_REC), FALSE);

    // Clear slots
    SetLocalJson(oPC, WCA_LVAR_SLOTS, WcaInitSlots());
    SetLocalInt(oPC, WCA_LVAR_SEL_REC, -1);

    // Random backfire effect
    int nRoll = d4(1);
    effect eHarm;
    string sMsg;
    switch(nRoll)
    {
        case 1:
            eHarm = EffectDaze();
            sMsg  = "Mikstura eksploduje! Odurzająca woń obezwładnia twój umysł...";
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eHarm, oPC, 8.0);
            break;
        case 2:
            eHarm = EffectBlindness();
            sMsg  = "Czarny dym wypełnia twoje oczy — chwilowa ślepota!";
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eHarm, oPC, 6.0);
            break;
        case 3:
            eHarm = EffectDamage(d6(2), DAMAGE_TYPE_MAGICAL, DAMAGE_POWER_NORMAL);
            sMsg  = "Kocioł wybucha ciemną energią — odrzuca cię z bólem!";
            ApplyEffectToObject(DURATION_TYPE_INSTANT, eHarm, oPC);
            break;
        default:
            eHarm = EffectCurse(2, 2, 2, 2, 2, 2);
            sMsg  = "Zepsuta mikstura przeklina twoje dłonie — czujesz słabość.";
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eHarm, oPC, 60.0);
            break;
    }

    ApplyEffectToObject(DURATION_TYPE_INSTANT,
                        EffectVisualEffect(VFX_IMP_EVIL_HELP), oPC);
    FloatingTextStringOnCreature(sMsg, oPC, FALSE);
    SendMessageToPC(oPC, "[Kocioł] " + sMsg);

    WcaFeedRecipeList(oPC, nToken);
    WcaFeedSelectedRecipe(oPC, nToken);
    WcaFeedSlots(oPC, nToken);
    NuiSetBind(oPC, nToken, WCA_BIND_STATUS, JsonString("Niepowodzenie! Składniki pochłonięte."));
}

// ================================================================
// Tome / Recipe learning
// ================================================================

void WcaLearnRecipe(object oPC, int nRecipeId)
{
    if(nRecipeId < 0 || nRecipeId >= WCA_RECIPE_COUNT) return;

    if(WcaHasRecipe(oPC, nRecipeId))
    {
        SendMessageToPC(oPC, "[Kocioł] Znasz już tę recepturę: " + WcaGetRecipeName(nRecipeId) + ".");
        return;
    }

    WcaLearnRecipeDB(oPC, nRecipeId);
    string sMsg = "Poznajesz recepturę: " + WcaGetRecipeName(nRecipeId) + "!";
    FloatingTextStringOnCreature(sMsg, oPC, FALSE);
    SendMessageToPC(oPC, "[Kocioł] " + sMsg);

    // If window is open, refresh recipe list
    int nToken = NuiFindWindow(oPC, WCA_WINDOW);
    if(nToken != 0)
        WcaFeedRecipeList(oPC, nToken);
}

// Called from OnActivateItem when PC reads a tome with tag wca_tome_X
void WcaOnReadTome(object oPC, object oTome)
{
    string sTag  = GetTag(oTome);
    int nRecipeId = WcaGetRecipeIdByTomeTag(sTag);

    if(nRecipeId < 0)
    {
        SendMessageToPC(oPC, "[Kocioł] Ten zapis nie jest recepturą.");
        return;
    }

    WcaLearnRecipe(oPC, nRecipeId);
    DestroyObject(oTome);
}

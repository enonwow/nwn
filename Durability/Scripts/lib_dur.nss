#include "lib_dur_def"

// ----------------------------------------------------------------
// Penalty effect management
// Uses SUBTYPE_SUPERNATURAL to distinguish from spell/ability effects.
// Removes all supernatural ATTACK_DECREASE / AC_DECREASE, then
// re-applies our totals. May conflict if another system also places
// permanent supernatural decreases on PCs — see INTEGRATION.md.
// ----------------------------------------------------------------

void DurClearPenaltyEffects(object oPC)
{
    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        effect eNext = GetNextEffect(oPC);
        int nType = GetEffectType(e);
        if(GetEffectSubType(e) == SUBTYPE_SUPERNATURAL &&
           (nType == EFFECT_TYPE_ATTACK_DECREASE ||
            nType == EFFECT_TYPE_AC_DECREASE))
            RemoveEffect(oPC, e);
        e = eNext;
    }
}

void DurApplyPenaltyEffects(object oPC, int nAttPen, int nACPen)
{
    DurClearPenaltyEffects(oPC);
    if(nAttPen > 0)
    {
        effect eAtt = SupernaturalEffect(EffectAttackDecrease(nAttPen));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eAtt, oPC);
    }
    if(nACPen > 0)
    {
        effect eAC = SupernaturalEffect(EffectACDecrease(nACPen));
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eAC, oPC);
    }
}

void DurRecalcPenalties(object oPC)
{
    int nAttPen = 0;
    int nACPen  = 0;
    int i;
    for(i = 0; i < DUR_SLOT_COUNT; i++)
    {
        object oItem = GetItemInSlot(DurGetInventorySlot(i), oPC);
        if(!GetIsObjectValid(oItem)) continue;

        int nDur = DurGetDurability(oItem);
        int nPen = DurGetPenalty(nDur);
        if(nPen <= 0) continue;

        if(DurIsWeaponSlot(i, oItem) && nPen > nAttPen)
            nAttPen = nPen;

        if(DurIsArmorSlot(i, oItem))
            nACPen += nPen;
    }

    DurApplyPenaltyEffects(oPC, nAttPen, nACPen);
}

// ----------------------------------------------------------------
// Decay — one call per ~60-second combat cycle from module HB
// ----------------------------------------------------------------

void DurDecayCombatPC(object oPC)
{
    int nChanged = FALSE;
    int i;
    for(i = 0; i < DUR_SLOT_COUNT; i++)
    {
        object oItem = GetItemInSlot(DurGetInventorySlot(i), oPC);
        if(!GetIsObjectValid(oItem)) continue;

        DurEnsureItem(oItem, oPC, i);
        if(DurGetDurability(oItem) <= 0) continue;

        // Weapons decay faster; each call is ~60 s of combat
        int nAmt = (i == 0 || i == 1) ? 2 : 1;
        DurDecayItem(oItem, nAmt);
        nChanged = TRUE;

        // Warn player at key thresholds
        int nDur = DurGetDurability(oItem);
        if(nDur == DUR_THR_WORN - 1 || nDur == DUR_THR_DAMAGED - 1 ||
           nDur == DUR_THR_BROKEN - 1 || nDur == 0)
        {
            SendMessageToPC(oPC,
                "[Wytrzymałość] " + GetName(oItem) + ": " +
                DurGetStatusText(nDur) + "! (" + IntToString(nDur) + "/100)");
        }
    }

    if(nChanged)
    {
        DurRecalcPenalties(oPC);
        int nToken = NuiFindWindow(oPC, DUR_WINDOW);
        if(nToken != 0)
            DurFeedWindow(oPC, nToken);
    }
}

void DurCheckAllSlots(object oPC)
{
    int i;
    for(i = 0; i < DUR_SLOT_COUNT; i++)
    {
        object oItem = GetItemInSlot(DurGetInventorySlot(i), oPC);
        if(GetIsObjectValid(oItem))
            DurEnsureItem(oItem, oPC, i);
    }
    DurRecalcPenalties(oPC);
}

// ----------------------------------------------------------------
// NUI layout builders
// ----------------------------------------------------------------

json DurBuildSlotList(object oPC)
{
    float fRowH  = GetNuiScaleDimension(oPC, 30.0);
    float fSlotW = GetNuiScaleDimension(oPC, 110.0);
    float fBarW  = GetNuiScaleDimension(oPC, 110.0);
    float fStatW = GetNuiScaleDimension(oPC, 90.0);
    float fListH = GetNuiScaleDimension(oPC, 224.0);

    json jSlotLbl = NuiLabel(NuiBind(DUR_BIND_SLOT_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jSlotCol = NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jSlotLbl)), fSlotW);

    json jItemLbl = NuiLabel(NuiBind(DUR_BIND_ITEM_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jItemLbl = NuiStyleForegroundColor(jItemLbl, NuiBind(DUR_BIND_STAT_COLOR));

    json jBar = NuiProgressBar(NuiBind(DUR_BIND_SLOT_PCT));
    jBar = NuiStyleForegroundColor(jBar, NuiBind(DUR_BIND_BAR_COLOR));
    json jBarCol = NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jBar)), fBarW);

    json jStatLbl = NuiLabel(NuiBind(DUR_BIND_SLOT_STATUS),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatLbl = NuiStyleForegroundColor(jStatLbl, NuiBind(DUR_BIND_STAT_COLOR));
    json jStatCol = NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jStatLbl)), fStatW);

    json jCols = JsonArray();
    jCols = JsonArrayInsert(jCols, jSlotCol);
    jCols = JsonArrayInsert(jCols, jItemLbl);
    jCols = JsonArrayInsert(jCols, jBarCol);
    jCols = JsonArrayInsert(jCols, jStatCol);

    json jRowCell = NuiGroup(NuiRow(jCols), FALSE, NUI_SCROLLBARS_NONE);
    jRowCell = NuiId(jRowCell, DUR_BTN_ROW);
    jRowCell = NuiEncouraged(jRowCell, NuiBind(DUR_BIND_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jRowCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(DUR_BIND_ROWCOUNT), fRowH);
    jList = NuiHeight(jList, fListH);
    return jList;
}

json DurBuildDetailPanel(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 32.0);
    float fBtnW  = GetNuiScaleDimension(oPC, 200.0);
    float fInfoH = GetNuiScaleDimension(oPC, 130.0);

    json jNameLbl = NuiLabel(NuiBind(DUR_BIND_DETAIL_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiHeight(jNameLbl, GetNuiScaleDimension(oPC, 24.0));

    json jInfoTxt = NuiGroup(NuiText(NuiBind(DUR_BIND_DETAIL_INFO), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jInfoTxt = NuiHeight(jInfoTxt, fInfoH);

    json jRepairBtn = NuiButton(JsonString("Napraw (Kuźnia)"));
    jRepairBtn = NuiId(jRepairBtn, DUR_BTN_REPAIR);
    jRepairBtn = NuiEnabled(jRepairBtn, NuiBind(DUR_BIND_REPAIR_ENA));
    jRepairBtn = NuiWidth(jRepairBtn, fBtnW);
    jRepairBtn = NuiHeight(jRepairBtn, fBtnH);
    jRepairBtn = NuiTooltip(jRepairBtn,
        JsonString("Naprawa przy kowalskim ogniu — pełna restauracja."));

    json jFieldBtn = NuiButton(JsonString("Napraw w Polu"));
    jFieldBtn = NuiId(jFieldBtn, DUR_BTN_FIELD);
    jFieldBtn = NuiEnabled(jFieldBtn, NuiBind(DUR_BIND_FIELD_ENA));
    jFieldBtn = NuiWidth(jFieldBtn, fBtnW);
    jFieldBtn = NuiHeight(jFieldBtn, fBtnH);
    jFieldBtn = NuiTooltip(jFieldBtn,
        JsonString("Zużywa zestaw naprawczy (dur_repair_kit) + 3× cena złota."));

    json jBtnCol = JsonArray();
    jBtnCol = JsonArrayInsert(jBtnCol, jRepairBtn);
    jBtnCol = JsonArrayInsert(jBtnCol, CreateEmptyRow(oPC, 4.0));
    jBtnCol = JsonArrayInsert(jBtnCol, jFieldBtn);

    json jPanel = JsonArray();
    jPanel = JsonArrayInsert(jPanel, jNameLbl);
    jPanel = JsonArrayInsert(jPanel, jInfoTxt);
    jPanel = JsonArrayInsert(jPanel, NuiCol(jBtnCol));

    return NuiCol(jPanel);
}

json DurBuildWindow(object oPC)
{
    float fBtnH   = GetNuiScaleDimension(oPC, 32.0);
    float fListW  = GetNuiScaleDimension(oPC, 390.0);
    float fPanelW = GetNuiScaleDimension(oPC, 230.0);

    json jTitle = NuiLabel(
        JsonString("Kuźnia — Stan Ekwipunku"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, GetNuiScaleDimension(oPC, 26.0));

    // Column headers above the list
    json jHdrSlot = NuiLabel(JsonString("Slot"),
        JsonInt(NUI_HALIGN_LEFT),   JsonInt(NUI_VALIGN_MIDDLE));
    jHdrSlot = NuiWidth(jHdrSlot, GetNuiScaleDimension(oPC, 110.0));

    json jHdrItem = NuiLabel(JsonString("Przedmiot"),
        JsonInt(NUI_HALIGN_LEFT),   JsonInt(NUI_VALIGN_MIDDLE));

    json jHdrBar = NuiLabel(JsonString("Wytrzymałość"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrBar = NuiWidth(jHdrBar, GetNuiScaleDimension(oPC, 110.0));

    json jHdrStat = NuiLabel(JsonString("Stan"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHdrStat = NuiWidth(jHdrStat, GetNuiScaleDimension(oPC, 90.0));

    json jHdrRow = JsonArray();
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrSlot);
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrItem);
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrBar);
    jHdrRow = JsonArrayInsert(jHdrRow, jHdrStat);

    // Left column: headers + list
    json jLeft = JsonArray();
    jLeft = JsonArrayInsert(jLeft, NuiRow(jHdrRow));
    jLeft = JsonArrayInsert(jLeft, DurBuildSlotList(oPC));
    json jLeftCol = NuiWidth(NuiCol(jLeft), fListW);

    // Right column: detail panel
    json jRightCol = NuiWidth(DurBuildDetailPanel(oPC), fPanelW);

    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jLeftCol);
    jMainRow = JsonArrayInsert(jMainRow, NuiSpacer());
    jMainRow = JsonArrayInsert(jMainRow, jRightCol);

    // Bottom bar
    json jRepAllBtn = NuiButton(JsonString("Napraw Wszystko"));
    jRepAllBtn = NuiId(jRepAllBtn, DUR_BTN_REPALL);
    jRepAllBtn = NuiEnabled(jRepAllBtn, NuiBind(DUR_BIND_REPALL_ENA));
    jRepAllBtn = NuiWidth(jRepAllBtn, GetNuiScaleDimension(oPC, 150.0));
    jRepAllBtn = NuiHeight(jRepAllBtn, fBtnH);
    jRepAllBtn = NuiTooltip(jRepAllBtn,
        JsonString("Naprawia wszystkie uszkodzone przedmioty (wymaga kuźni)."));

    json jStatusLbl = NuiLabel(NuiBind(DUR_BIND_STATUS_MSG),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiColor(220, 200, 80));

    json jCloseBtn = NuiButton(JsonString("Zamknij"));
    jCloseBtn = NuiId(jCloseBtn, DUR_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 80.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jRepAllBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jStatusLbl);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jCloseBtn);

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, jTitle);
    jRoot = JsonArrayInsert(jRoot, CreateEmptyRow(oPC, 4.0));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jMainRow));
    jRoot = JsonArrayInsert(jRoot, CreateEmptyRow(oPC, 6.0));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jBotRow));

    return NuiCol(jRoot);
}

// ----------------------------------------------------------------
// Window lifecycle
// ----------------------------------------------------------------

void DurCreateWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, DUR_WINDOW);
    if(nToken != 0)
    {
        DurFeedWindow(oPC, nToken);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  -
                 GetNuiScaleDimension(oPC, DUR_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) -
                 GetNuiScaleDimension(oPC, DUR_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
        GetNuiScaleDimension(oPC, DUR_W),
        GetNuiScaleDimension(oPC, DUR_H));

    json jWin = NuiWindow(
        DurBuildWindow(oPC),
        JsonString("Wytrzymałość Ekwipunku"),
        NuiBind(DUR_WIN_GEOM),
        JsonBool(TRUE),   // resizable
        JsonBool(FALSE),
        JsonBool(TRUE),   // closable
        JsonBool(FALSE),
        JsonBool(TRUE));  // border

    nToken = NuiCreate(oPC, jWin, DUR_WINDOW, DUR_EV_SCRIPT);
    NuiSetBind(oPC, nToken, DUR_WIN_GEOM, jGeom);

    SetLocalInt(oPC, DUR_LVAR_SEL, -1);
    DurFeedWindow(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed — populate NuiList binds and detail panel
// ----------------------------------------------------------------

void DurFeedDetail(object oPC, int nToken, int nSlotIdx)
{
    if(nSlotIdx < 0 || nSlotIdx >= DUR_SLOT_COUNT)
    {
        NuiSetBind(oPC, nToken, DUR_BIND_DETAIL_NAME,
            JsonString("Wybierz slot z listy powyżej."));
        NuiSetBind(oPC, nToken, DUR_BIND_DETAIL_INFO, JsonString(""));
        NuiSetBind(oPC, nToken, DUR_BIND_REPAIR_ENA,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, DUR_BIND_FIELD_ENA,   JsonBool(FALSE));
        return;
    }

    object oItem = GetItemInSlot(DurGetInventorySlot(nSlotIdx), oPC);
    if(!GetIsObjectValid(oItem))
    {
        NuiSetBind(oPC, nToken, DUR_BIND_DETAIL_NAME,
            JsonString(DurGetSlotLabel(nSlotIdx) + ": (pusty slot)"));
        NuiSetBind(oPC, nToken, DUR_BIND_DETAIL_INFO, JsonString(""));
        NuiSetBind(oPC, nToken, DUR_BIND_REPAIR_ENA,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, DUR_BIND_FIELD_ENA,   JsonBool(FALSE));
        return;
    }

    DurEnsureItem(oItem, oPC, nSlotIdx);
    int nDur     = DurGetDurability(oItem);
    int nMaxDur  = DurGetMaxDurability(oItem);
    int nMissing = nMaxDur - nDur;
    int nPen     = DurGetPenalty(nDur);

    string sHeader = DurGetSlotLabel(nSlotIdx) + ": " + GetName(oItem);

    string sInfo = "Wytrzymałość: " + IntToString(nDur) + " / " + IntToString(nMaxDur) + "\n";
    sInfo = sInfo + "Stan: " + DurGetStatusText(nDur) + "\n";

    if(nPen > 0)
    {
        string sPenType = DurIsWeaponSlot(nSlotIdx, oItem) ? " do ataku" : " do KP";
        sInfo = sInfo + "Kara: -" + IntToString(nPen) + sPenType + "\n";
    }

    int bNeedsRepair = (nMissing > 0);
    if(bNeedsRepair)
    {
        int nForgeCost = DurRepairCost(nMissing, FALSE);
        int nFieldCost = DurRepairCost(nMissing, TRUE);
        sInfo = sInfo + "\nKuźnia: " + IntToString(nForgeCost) + " sz\n";
        sInfo = sInfo + "Polowa: "  + IntToString(nFieldCost) + " sz + zestaw";
    }
    else
        sInfo = sInfo + "\nStan idealny — naprawa zbędna.";

    int bAtForge    = GetLocalInt(oPC, DUR_LVAR_FORGE);
    int bHasKit     = GetIsObjectValid(GetItemPossessedBy(oPC, DUR_TAG_KIT));
    int nPlayerGold = GetGold(oPC);

    int bCanForge = bAtForge && bNeedsRepair &&
                    (nPlayerGold >= DurRepairCost(nMissing, FALSE));
    int bCanField = bNeedsRepair && bHasKit &&
                    (nPlayerGold >= DurRepairCost(nMissing, TRUE));

    NuiSetBind(oPC, nToken, DUR_BIND_DETAIL_NAME, JsonString(sHeader));
    NuiSetBind(oPC, nToken, DUR_BIND_DETAIL_INFO, JsonString(sInfo));
    NuiSetBind(oPC, nToken, DUR_BIND_REPAIR_ENA,  JsonBool(bCanForge));
    NuiSetBind(oPC, nToken, DUR_BIND_FIELD_ENA,   JsonBool(bCanField));
}

void DurFeedWindow(object oPC, int nToken)
{
    json jSlotNames  = JsonArray();
    json jItemNames  = JsonArray();
    json jPcts       = JsonArray();
    json jBarColors  = JsonArray();
    json jStatTexts  = JsonArray();
    json jStatColors = JsonArray();
    json jEncs       = JsonArray();

    int nSelIdx = GetLocalInt(oPC, DUR_LVAR_SEL);
    int nAnyDmg = FALSE;

    int i;
    for(i = 0; i < DUR_SLOT_COUNT; i++)
    {
        object oItem = GetItemInSlot(DurGetInventorySlot(i), oPC);
        int bHasItem = GetIsObjectValid(oItem);

        int nDur = 100;
        if(bHasItem)
        {
            DurEnsureItem(oItem, oPC, i);
            nDur = DurGetDurability(oItem);
        }

        float fPct    = bHasItem ? IntToFloat(nDur) / 100.0 : 1.0;
        string sStatus = bHasItem ? DurGetStatusText(nDur) : "";
        json jColor   = bHasItem ? DurGetStatusColor(nDur) : NuiColor(100, 100, 100);

        if(bHasItem && nDur < DUR_THR_WORN)
            nAnyDmg = TRUE;

        jSlotNames  = JsonArrayInsert(jSlotNames,  JsonString(DurGetSlotLabel(i)));
        jItemNames  = JsonArrayInsert(jItemNames,  JsonString(bHasItem ? GetName(oItem) : "(brak)"));
        jPcts       = JsonArrayInsert(jPcts,       JsonFloat(fPct));
        jBarColors  = JsonArrayInsert(jBarColors,  jColor);
        jStatTexts  = JsonArrayInsert(jStatTexts,  JsonString(sStatus));
        jStatColors = JsonArrayInsert(jStatColors, jColor);
        jEncs       = JsonArrayInsert(jEncs,       JsonBool(i == nSelIdx));
    }

    NuiSetBind(oPC, nToken, DUR_BIND_SLOT_NAME,   jSlotNames);
    NuiSetBind(oPC, nToken, DUR_BIND_ITEM_NAME,   jItemNames);
    NuiSetBind(oPC, nToken, DUR_BIND_SLOT_PCT,    jPcts);
    NuiSetBind(oPC, nToken, DUR_BIND_BAR_COLOR,   jBarColors);
    NuiSetBind(oPC, nToken, DUR_BIND_SLOT_STATUS, jStatTexts);
    NuiSetBind(oPC, nToken, DUR_BIND_STAT_COLOR,  jStatColors);
    NuiSetBind(oPC, nToken, DUR_BIND_ROW_ENC,     jEncs);
    NuiSetBind(oPC, nToken, DUR_BIND_ROWCOUNT,    JsonInt(DUR_SLOT_COUNT));
    NuiSetBind(oPC, nToken, DUR_BIND_REPALL_ENA,  JsonBool(nAnyDmg && GetLocalInt(oPC, DUR_LVAR_FORGE)));
    NuiSetBind(oPC, nToken, DUR_BIND_STATUS_MSG,  JsonString(""));

    DurFeedDetail(oPC, nToken, nSelIdx);
}

// ----------------------------------------------------------------
// Repair actions (called from event handler)
// ----------------------------------------------------------------

void DurDoRepair(object oPC, int nToken, int nSlotIdx, int bField)
{
    if(nSlotIdx < 0 || nSlotIdx >= DUR_SLOT_COUNT) return;

    object oItem = GetItemInSlot(DurGetInventorySlot(nSlotIdx), oPC);
    if(!GetIsObjectValid(oItem)) return;

    int nDur     = DurGetDurability(oItem);
    int nMaxDur  = DurGetMaxDurability(oItem);
    int nMissing = nMaxDur - nDur;

    if(nMissing <= 0)
    {
        NuiSetBind(oPC, nToken, DUR_BIND_STATUS_MSG,
            JsonString("Przedmiot nie wymaga naprawy."));
        return;
    }

    int nCost = DurRepairCost(nMissing, bField);
    if(GetGold(oPC) < nCost)
    {
        NuiSetBind(oPC, nToken, DUR_BIND_STATUS_MSG,
            JsonString("Za mało złota! Potrzebujesz " + IntToString(nCost) + " sz."));
        return;
    }

    if(bField)
    {
        object oKit = GetItemPossessedBy(oPC, DUR_TAG_KIT);
        if(!GetIsObjectValid(oKit))
        {
            NuiSetBind(oPC, nToken, DUR_BIND_STATUS_MSG,
                JsonString("Brak zestawu naprawczego (dur_repair_kit) w ekwipunku."));
            return;
        }
        DestroyObject(oKit);
    }

    AssignCommand(oPC, TakeGoldFromCreature(nCost, oPC, TRUE));
    DurFullRepair(oItem);
    DurRecalcPenalties(oPC);

    string sHow = bField ? "w polu" : "przy kuźni";
    NuiSetBind(oPC, nToken, DUR_BIND_STATUS_MSG,
        JsonString("Naprawiono " + GetName(oItem) + " " + sHow +
                   ". Koszt: " + IntToString(nCost) + " sz."));

    DurFeedWindow(oPC, nToken);
}

void DurDoRepairAll(object oPC, int nToken)
{
    if(!GetLocalInt(oPC, DUR_LVAR_FORGE))
    {
        NuiSetBind(oPC, nToken, DUR_BIND_STATUS_MSG,
            JsonString("Naprawa wszystkich wymaga kuźni."));
        return;
    }

    int nTotalCost = 0;
    int i;
    for(i = 0; i < DUR_SLOT_COUNT; i++)
    {
        object oItem = GetItemInSlot(DurGetInventorySlot(i), oPC);
        if(!GetIsObjectValid(oItem)) continue;
        DurEnsureItem(oItem, oPC, i);
        int nMissing = DurGetMaxDurability(oItem) - DurGetDurability(oItem);
        nTotalCost += DurRepairCost(nMissing, FALSE);
    }

    if(nTotalCost <= 0)
    {
        NuiSetBind(oPC, nToken, DUR_BIND_STATUS_MSG,
            JsonString("Cały ekwipunek w doskonałym stanie."));
        return;
    }

    if(GetGold(oPC) < nTotalCost)
    {
        NuiSetBind(oPC, nToken, DUR_BIND_STATUS_MSG,
            JsonString("Za mało złota! Potrzebujesz " + IntToString(nTotalCost) + " sz."));
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(nTotalCost, oPC, TRUE));

    for(i = 0; i < DUR_SLOT_COUNT; i++)
    {
        object oItem = GetItemInSlot(DurGetInventorySlot(i), oPC);
        if(GetIsObjectValid(oItem))
            DurFullRepair(oItem);
    }

    DurRecalcPenalties(oPC);
    NuiSetBind(oPC, nToken, DUR_BIND_STATUS_MSG,
        JsonString("Cały ekwipunek naprawiony. Koszt: " + IntToString(nTotalCost) + " sz."));
    DurFeedWindow(oPC, nToken);
}

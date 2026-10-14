#include "lib_nit_def"

// ----------------------------------------------------------------
// PC-object value cache
// ----------------------------------------------------------------

int NitGetValue(object oPC)
{
    return GetLocalInt(oPC, NIT_LVAR_VALUE);
}

// bPersist: write through to SQL campaign db immediately
void NitSetValue(object oPC, int nVal, int bPersist)
{
    if(nVal < 0)       nVal = 0;
    if(nVal > NIT_MAX) nVal = NIT_MAX;
    SetLocalInt(oPC, NIT_LVAR_VALUE, nVal);
    if(bPersist) NitPersist(oPC, nVal);
}

// ----------------------------------------------------------------
// Effect management
// ----------------------------------------------------------------

void NitRemoveEffects(object oPC)
{
    effect e     = GetFirstEffect(oPC);
    effect eNext;
    while(GetIsEffectValid(e))
    {
        eNext = GetNextEffect(oPC);
        string sTag = GetEffectTag(e);
        if(sTag == NIT_ETAG_SAVES || sTag == NIT_ETAG_AC ||
           sTag == NIT_ETAG_STR   || sTag == NIT_ETAG_TOUCH)
            RemoveEffect(oPC, e);
        e = eNext;
    }
}

void NitApplyTierEffects(object oPC, int nTier)
{
    NitRemoveEffects(oPC);

    // Death-Touched flag checked externally by healing/spell scripts
    if(nTier == 0)
        SetLocalInt(oPC, "NIT_DEATH_TOUCHED", 1);
    else
        DeleteLocalInt(oPC, "NIT_DEATH_TOUCHED");

    if(nTier >= 5) return;

    int nSavePen = 0;
    int nACPen   = 0;
    int nStrPen  = 0;

    switch(nTier)
    {
        case 4: nSavePen = 1;                        break;
        case 3: nSavePen = 2; nACPen = 1;            break;
        case 2: nSavePen = 3; nACPen = 2;            break;
        case 1: /* falls through */
        case 0: nSavePen = 5; nACPen = 3; nStrPen = 2; break;
    }

    if(nSavePen > 0)
    {
        effect eSave = EffectSavingThrowDecrease(SAVING_THROW_ALL, nSavePen);
        eSave = TagEffect(eSave, NIT_ETAG_SAVES);
        eSave = ExtraordinaryEffect(eSave);
        eSave = HideEffectIcon(eSave);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eSave, oPC);
    }
    if(nACPen > 0)
    {
        effect eAC = EffectACDecrease(nACPen, AC_DODGE_BONUS);
        eAC = TagEffect(eAC, NIT_ETAG_AC);
        eAC = ExtraordinaryEffect(eAC);
        eAC = HideEffectIcon(eAC);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eAC, oPC);
    }
    if(nStrPen > 0)
    {
        effect eStr = EffectAbilityDecrease(ABILITY_STRENGTH, nStrPen);
        eStr = TagEffect(eStr, NIT_ETAG_STR);
        eStr = ExtraordinaryEffect(eStr);
        eStr = HideEffectIcon(eStr);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eStr, oPC);
    }

    // Death-Touched: dazed icon repurposed as ghostly-presence visual
    if(nTier == 0)
    {
        effect eTouch = EffectIcon(EFFECT_ICON_DAZED);
        eTouch = TagEffect(eTouch, NIT_ETAG_TOUCH);
        eTouch = ExtraordinaryEffect(eTouch);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eTouch, oPC);
    }
}

// ----------------------------------------------------------------
// Drain / Restore
// ----------------------------------------------------------------

void NitDrainThread(object oPC, int nAmount, string sSource)
{
    int nCurrent = NitGetValue(oPC);
    if(nCurrent <= 0) return;

    int nOldTier = NitGetTier(nCurrent);
    int nNew     = nCurrent - nAmount;
    if(nNew < 0) nNew = 0;
    int nNewTier = NitGetTier(nNew);

    NitSetValue(oPC, nNew, TRUE);

    if(nOldTier != nNewTier)
    {
        NitApplyTierEffects(oPC, nNewTier);
        string sMsg = NitDropMessage(nNewTier);
        if(sMsg != "") SendMessageToPC(oPC, sMsg);
    }

    int nToken = NuiFindWindow(oPC, NIT_WINDOW);
    if(nToken != 0) FeedNitWindow(oPC, nToken, nNew);
}

void NitRestoreThread(object oPC, int nAmount)
{
    int nCurrent = NitGetValue(oPC);
    if(nCurrent >= NIT_MAX) return;

    int nOldTier = NitGetTier(nCurrent);
    int nNew     = nCurrent + nAmount;
    if(nNew > NIT_MAX) nNew = NIT_MAX;
    int nNewTier = NitGetTier(nNew);

    NitSetValue(oPC, nNew, TRUE);

    if(nOldTier != nNewTier)
    {
        NitApplyTierEffects(oPC, nNewTier);
        string sMsg = NitRiseMessage(nNewTier);
        if(sMsg != "") SendMessageToPC(oPC, sMsg);
    }

    int nToken = NuiFindWindow(oPC, NIT_WINDOW);
    if(nToken != 0) FeedNitWindow(oPC, nToken, nNew);
}

// ----------------------------------------------------------------
// NUI window construction
// ----------------------------------------------------------------

json NitBuildWindow(object oPC)
{
    float fW       = GetNuiScaleDimension(oPC, 400.0);
    float fH       = GetNuiScaleDimension(oPC, 350.0);
    float fBtnH    = GetNuiScaleDimension(oPC, 30.0);
    float fBarH    = GetNuiScaleDimension(oPC, 22.0);
    float fTierH   = GetNuiScaleDimension(oPC, 26.0);
    float fFlavorH = GetNuiScaleDimension(oPC, 100.0);
    float fEffH    = GetNuiScaleDimension(oPC, 22.0);
    float fValW    = GetNuiScaleDimension(oPC, 80.0);
    float fCleanseW= GetNuiScaleDimension(oPC, 130.0);
    float fCloseW  = GetNuiScaleDimension(oPC, 90.0);

    // --- Progress bar ---
    json jBar = NuiProgressBar(NuiBind(NIT_BIND_PROGRESS));
    jBar = NuiStyleForegroundColor(jBar, NuiBind(NIT_BIND_COLOR));
    jBar = NuiHeight(jBar, fBarH);

    // --- Tier name label + value (same row) ---
    json jTierLbl = NuiLabel(NuiBind(NIT_BIND_TIER_NAME),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTierLbl = NuiStyleForegroundColor(jTierLbl, NuiBind(NIT_BIND_COLOR));
    jTierLbl = NuiHeight(jTierLbl, fTierH);

    json jValLbl = NuiLabel(NuiBind(NIT_BIND_VALUE),
                            JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jValLbl = NuiWidth (jValLbl, fValW);
    jValLbl = NuiHeight(jValLbl, fTierH);

    json jTierRowArr = JsonArray();
    jTierRowArr = JsonArrayInsert(jTierRowArr, jTierLbl);
    jTierRowArr = JsonArrayInsert(jTierRowArr, jValLbl);
    json jTierRow = NuiRow(jTierRowArr);

    // --- Flavor text ---
    json jFlavor = NuiLabel(NuiBind(NIT_BIND_FLAVOR),
                            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jFlavor = NuiHeight(jFlavor, fFlavorH);

    // --- Effects header ---
    json jEffHeader = NuiLabel(JsonString("Aktywne kary:"),
                               JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEffHeader = NuiHeight(jEffHeader, fEffH);

    // --- Effects value ---
    json jEffLbl = NuiLabel(NuiBind(NIT_BIND_EFFECTS),
                            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEffLbl = NuiStyleForegroundColor(jEffLbl, NuiBind(NIT_BIND_COLOR));
    jEffLbl = NuiHeight(jEffLbl, fEffH);

    // --- Buttons ---
    json jCleanse = NuiButton(JsonString("Oczyszczenie"));
    jCleanse = NuiId     (jCleanse, NIT_BTN_CLEANSE);
    jCleanse = NuiEnabled(jCleanse, NuiBind(NIT_BIND_CLEANSE_ENA));
    jCleanse = NuiTooltip(jCleanse, NuiBind(NIT_BIND_CLEANSE_TIP));
    jCleanse = NuiWidth  (jCleanse, fCleanseW);
    jCleanse = NuiHeight (jCleanse, fBtnH);

    json jClose = NuiButton(JsonString("Zamknij"));
    jClose = NuiId    (jClose, NIT_BTN_CLOSE);
    jClose = NuiWidth (jClose, fCloseW);
    jClose = NuiHeight(jClose, fBtnH);

    json jBtnArr = JsonArray();
    jBtnArr = JsonArrayInsert(jBtnArr, jCleanse);
    jBtnArr = JsonArrayInsert(jBtnArr, NuiSpacer());
    jBtnArr = JsonArrayInsert(jBtnArr, jClose);
    json jBtnRow = NuiRow(jBtnArr);

    // --- Assemble root column ---
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jBar)));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jTierRow);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jFlavor)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jEffHeader)));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jEffLbl)));
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, jBtnRow);

    json jRoot = NuiCol(jCol);

    return NuiWindow(jRoot,
                     JsonString("Nić Przeznaczenia"),
                     NuiBind(NIT_WIN_GEOM),
                     JsonBool(FALSE),
                     JsonBool(FALSE),
                     JsonBool(TRUE),
                     JsonBool(FALSE),
                     JsonBool(TRUE));
}

void FeedNitWindow(object oPC, int nToken, int nVal)
{
    int   nTier    = NitGetTier(nVal);
    json  jColor   = NitTierColor(nTier);
    float fProgress = IntToFloat(nVal) / IntToFloat(NIT_MAX);

    NuiSetBind(oPC, nToken, NIT_BIND_TIER_NAME, JsonString(NitTierName(nTier)));
    NuiSetBind(oPC, nToken, NIT_BIND_VALUE,     JsonString(IntToString(nVal) + " / " + IntToString(NIT_MAX)));
    NuiSetBind(oPC, nToken, NIT_BIND_FLAVOR,    JsonString(NitTierFlavor(nTier)));
    NuiSetBind(oPC, nToken, NIT_BIND_EFFECTS,   JsonString(NitTierEffects(nTier)));
    NuiSetBind(oPC, nToken, NIT_BIND_PROGRESS,  JsonFloat(fProgress));
    NuiSetBind(oPC, nToken, NIT_BIND_COLOR,     jColor);

    // Cleanse button availability
    int bHasItem  = GetIsObjectValid(GetItemPossessedBy(oPC, NIT_ITEM_CLEANSE));
    int bHolyArea = (GetLocalInt(GetArea(oPC), NIT_AVAR_RESTORE) > 0);
    int bCanClean = (nVal < NIT_MAX) && (bHasItem || bHolyArea);
    NuiSetBind(oPC, nToken, NIT_BIND_CLEANSE_ENA, JsonBool(bCanClean));

    string sTip;
    if(nVal >= NIT_MAX)
        sTip = "Nić jest w pełni żywa.";
    else if(bHasItem)
        sTip = "Użyj przedmiotu oczyszczającego. Doda +" + IntToString(NIT_CLEANSE_RESTORE) + " punktów.";
    else if(bHolyArea)
        sTip = "Jesteś na świętym terenie — oczyszczenie jest możliwe.";
    else
        sTip = "Brak przedmiotu oczyszczającego. Szukaj kapłana lub świętego miejsca.";
    NuiSetBind(oPC, nToken, NIT_BIND_CLEANSE_TIP, JsonString(sTip));
}

void NitOpenWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, NIT_WINDOW);
    if(nToken != 0)
    {
        FeedNitWindow(oPC, nToken, NitGetValue(oPC));
        return;
    }

    json jWin  = NitBuildWindow(oPC);
    nToken = NuiCreate(oPC, jWin, NIT_WINDOW, NIT_EV_SCRIPT);

    float fW = GetNuiScaleDimension(oPC, 400.0);
    float fH = GetNuiScaleDimension(oPC, 350.0);
    NuiSetBind(oPC, nToken, NIT_WIN_GEOM, NuiRect(80.0, 80.0, fW, fH));
    FeedNitWindow(oPC, nToken, NitGetValue(oPC));
}

// ----------------------------------------------------------------
// Cleanse action (called from NUI event handler)
// ----------------------------------------------------------------

void NitTryCleanse(object oPC, int nToken)
{
    int nVal = NitGetValue(oPC);
    if(nVal >= NIT_MAX)
    {
        SendMessageToPC(oPC, "[Nić] Twoja dusza jest już w pełni żywa.");
        return;
    }

    object oItem = GetItemPossessedBy(oPC, NIT_ITEM_CLEANSE);
    if(GetIsObjectValid(oItem))
    {
        SendMessageToPC(oPC, "[Nić] Zużywasz przedmiot oczyszczający — pieczęć krwi blaknie…");
        DestroyObject(oItem);
        NitRestoreThread(oPC, NIT_CLEANSE_RESTORE);
        return;
    }

    int nAreaRestore = GetLocalInt(GetArea(oPC), NIT_AVAR_RESTORE);
    if(nAreaRestore > 0)
    {
        SendMessageToPC(oPC, "[Nić] Moc świętego miejsca przenika twoją duszę…");
        NitRestoreThread(oPC, nAreaRestore * NIT_HOLY_CLEANSE_BONUS);
        return;
    }

    SendMessageToPC(oPC, "[Nić] Nie masz niczego, czym mógłbyś oczyścić duszę. Szukaj kapłana lub świętego miejsca.");
    NuiSetBind(oPC, nToken, NIT_BIND_CLEANSE_ENA, JsonBool(FALSE));
}

// ----------------------------------------------------------------
// Lifecycle hooks (called from sys_on_*.nss)
// ----------------------------------------------------------------

void NitOnClientEnter(object oPC)
{
    int nVal = NitLoad(oPC);
    NitSetValue(oPC, nVal, FALSE);
    NitApplyTierEffects(oPC, NitGetTier(nVal));

    if(nVal <= 0)
        DelayCommand(5.0, SendMessageToPC(oPC,
            "[Nić] Jesteś Dotknięty Śmiercią. Twoja nić jest zerwana (0/100)."));
    else if(nVal < 60)
        DelayCommand(5.0, SendMessageToPC(oPC,
            "[Nić] Twoja dusza nosi ślady ciemności (Nić: " + IntToString(nVal) + "/100). Szukaj oczyszczenia."));
}

void NitOnClientLeave(object oPC)
{
    NitPersist(oPC, NitGetValue(oPC));
    NitRemoveEffects(oPC);
    DeleteLocalInt(oPC, "NIT_DEATH_TOUCHED");
}

// ----------------------------------------------------------------
// Heartbeat (called from sys_module_hb.nss for each PC)
// ----------------------------------------------------------------

void NitHeartbeatTick(object oPC)
{
    int nDrainCtr = GetLocalInt(oPC, NIT_LVAR_HB_CTR) + 1;
    int nRstCtr   = GetLocalInt(oPC, NIT_LVAR_RST_CTR) + 1;
    SetLocalInt(oPC, NIT_LVAR_HB_CTR, nDrainCtr);
    SetLocalInt(oPC, NIT_LVAR_RST_CTR, nRstCtr);

    object oArea  = GetArea(oPC);
    int nDrain    = GetLocalInt(oArea, NIT_AVAR_DRAIN);
    int nRestore  = GetLocalInt(oArea, NIT_AVAR_RESTORE);

    if(nDrainCtr >= NIT_DRAIN_INTERVAL)
    {
        SetLocalInt(oPC, NIT_LVAR_HB_CTR, 0);
        if(nDrain > 0)
            NitDrainThread(oPC, nDrain, "Mroczna aura obszaru");
    }

    if(nRstCtr >= NIT_RST_INTERVAL)
    {
        SetLocalInt(oPC, NIT_LVAR_RST_CTR, 0);
        // Passive restore only in holy areas without concurrent drain
        if(nRestore > 0 && nDrain == 0)
            NitRestoreThread(oPC, 1);
    }
}

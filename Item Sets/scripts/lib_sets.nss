#include "lib_sets_def"

void FeedSetsDetail(object oPC, int nToken);

// ----------------------------------------------------------------
// Effect helpers
// ----------------------------------------------------------------

void SetsRemoveEffects(object oPC, int nSetId)
{
    string sTag = SETS_FX_PREFIX + IntToString(nSetId);
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        if(GetEffectTag(eEff) == sTag)
            RemoveEffect(oPC, eEff);
        eEff = GetNextEffect(oPC);
    }
}

// Applies the incremental effects for a single bonus tier.
// Called once per tier where nCount >= threshold; all tiers are cumulative.
void SetsApplyTierEffects(object oPC, int nSetId, int nTier, string sTag)
{
    if(nSetId == SETS_ID_DARK_KNIGHT)
    {
        if(nTier == 0)
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAttackIncrease(2, ATTACK_BONUS_MISC), sTag), oPC);
        else if(nTier == 1)
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectImmunity(IMMUNITY_TYPE_FEAR), sTag), oPC);
    }
    else if(nSetId == SETS_ID_DEAD_MAGE)
    {
        if(nTier == 0)
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_INTELLIGENCE, 2), sTag), oPC);
        else if(nTier == 1)
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_CHARISMA, 2), sTag), oPC);
    }
    else if(nSetId == SETS_ID_CORSAIR)
    {
        if(nTier == 0)
        {
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_DEXTERITY, 2), sTag), oPC);
        }
        else if(nTier == 1)
        {
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSkillIncrease(SKILL_HIDE, 4), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSkillIncrease(SKILL_MOVE_SILENTLY, 4), sTag), oPC);
        }
        else if(nTier == 2)
        {
            // Additional DEX+2 (total DEX+4) and AB+2
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_DEXTERITY, 2), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAttackIncrease(2, ATTACK_BONUS_MISC), sTag), oPC);
        }
    }
    else if(nSetId == SETS_ID_DAMNED_RINGS)
    {
        if(nTier == 0)
        {
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSavingThrowIncrease(SAVING_THROW_WILL, 4,
                    SAVING_THROW_TYPE_ALL), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectDamageVulnerability(DAMAGE_TYPE_DIVINE, 25), sTag), oPC);
        }
    }
    else if(nSetId == SETS_ID_DEATH_MADNESS)
    {
        if(nTier == 0)
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectDamageReduction(5, DAMAGE_POWER_PLUS_ONE, 0), sTag), oPC);
        else if(nTier == 1)
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectRegenerate(1, 6.0), sTag), oPC);
        else if(nTier == 2)
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_CONSTITUTION, 2), sTag), oPC);
    }
}

// Removes all set effects then re-applies all tiers up to nCount.
void SetsApplyEffects(object oPC, int nSetId, int nCount)
{
    SetsRemoveEffects(oPC, nSetId);
    if(nCount < 2) return;

    string sTag = SETS_FX_PREFIX + IntToString(nSetId);
    int i;
    for(i = 0; i < 3; i++)
    {
        int nThresh = SetsGetBonusTierThreshold(nSetId, i);
        if(nThresh == 0) break;
        if(nCount >= nThresh)
            SetsApplyTierEffects(oPC, nSetId, i, sTag);
    }
}

// ----------------------------------------------------------------
// Set detection
// ----------------------------------------------------------------

// Returns TRUE if any equip slot on oPC holds an item with sTag.
int SetsIsTagEquipped(object oPC, string sTag)
{
    int nSlot;
    for(nSlot = 0; nSlot <= INVENTORY_SLOT_CARMOUR; nSlot++)
    {
        object oItem = GetItemInSlot(nSlot, oPC);
        if(GetIsObjectValid(oItem) && GetTag(oItem) == sTag)
            return TRUE;
    }
    return FALSE;
}

// Counts how many items from set nSetId the PC currently has equipped.
int SetsGetEquippedCount(object oPC, int nSetId)
{
    string sTags = SetsGetItemTags(nSetId);
    int nTotal   = SetsGetItemCount(nSetId);
    int nFound   = 0;
    int i;
    for(i = 0; i < nTotal; i++)
    {
        string sTag = SetsGetToken(sTags, i);
        if(sTag != "" && SetsIsTagEquipped(oPC, sTag))
            nFound++;
    }
    return nFound;
}

// ----------------------------------------------------------------
// Master update – call on equip / unequip
// ----------------------------------------------------------------

void SetsUpdateAll(object oPC)
{
    int i;
    for(i = 0; i < SETS_TOTAL; i++)
        SetsApplyEffects(oPC, i, SetsGetEquippedCount(oPC, i));

    int nToken = NuiFindWindow(oPC, SETS_WINDOW);
    if(nToken != 0)
        FeedSetsPanel(oPC, nToken);
}

// ----------------------------------------------------------------
// NUI – roster list row template
// ----------------------------------------------------------------

json BuildSetsListRow(object oPC)
{
    float fH      = GetNuiScaleDimension(oPC, 52.0);
    float fCntW   = GetNuiScaleDimension(oPC, 68.0);

    json jName = NuiLabel(NuiBind(SETS_BIND_NAME),
                    JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiStyleForegroundColor(jName, NuiBind(SETS_BIND_COLOR));

    json jCnt = NuiLabel(NuiBind(SETS_BIND_COUNT),
                    JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jCnt = NuiWidth(jCnt, fCntW);
    jCnt = NuiStyleForegroundColor(jCnt, NuiBind(SETS_BIND_COLOR));

    json jInner = JsonArray();
    jInner = JsonArrayInsert(jInner, jName);
    jInner = JsonArrayInsert(jInner, jCnt);

    json jCell = NuiGroup(NuiRow(jInner), FALSE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, SETS_BTN_ROW);
    jCell = NuiHeight(jCell, fH);
    jCell = NuiEncouraged(jCell, NuiBind(SETS_BIND_ENC));
    return jCell;
}

// ----------------------------------------------------------------
// NUI – item detail list row template
// ----------------------------------------------------------------

json BuildSetsItemRow(object oPC)
{
    float fH     = GetNuiScaleDimension(oPC, 26.0);
    float fSymW  = GetNuiScaleDimension(oPC, 22.0);

    json jSym = NuiLabel(NuiBind(SETS_BIND_ITEM_SYM),
                    JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jSym = NuiWidth(jSym, fSymW);
    jSym = NuiStyleForegroundColor(jSym, NuiBind(SETS_BIND_ITEM_COL));

    json jIname = NuiLabel(NuiBind(SETS_BIND_ITEM_NAME),
                    JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jIname = NuiStyleForegroundColor(jIname, NuiBind(SETS_BIND_ITEM_COL));

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSym);
    jRow = JsonArrayInsert(jRow, jIname);

    json jCell = NuiHeight(NuiRow(jRow), fH);
    return jCell;
}

// ----------------------------------------------------------------
// NUI – window layout
// ----------------------------------------------------------------

void CreateSetsWindow(object oPC)
{
    float fW      = GetNuiScaleDimension(oPC, SETS_W);
    float fH      = GetNuiScaleDimension(oPC, SETS_H);
    float fBtnH   = GetNuiScaleDimension(oPC, 28.0);
    float fListH  = GetNuiScaleDimension(oPC, 52.0);   // row height for NuiList
    float fItemH  = GetNuiScaleDimension(oPC, 26.0);
    float fBonusH = GetNuiScaleDimension(oPC, 72.0);
    float fDetH   = GetNuiScaleDimension(oPC, 25.0);
    float fCloseW = GetNuiScaleDimension(oPC, 80.0);

    // Header
    json jTitle = NuiLabel(JsonString("Zestawy Przedmiotów"),
                    JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiStyleForegroundColor(jTitle, GetNuiColorNwnGold());
    json jClose = NuiButton(JsonString("Zamknij"));
    jClose = NuiId(jClose, SETS_BTN_CLOSE);
    jClose = NuiWidth(jClose, fCloseW);
    jClose = NuiHeight(jClose, fBtnH);

    json jHeader = JsonArray();
    jHeader = JsonArrayInsert(jHeader, jTitle);
    jHeader = JsonArrayInsert(jHeader, jClose);
    json jHeaderRow = NuiHeight(NuiRow(jHeader), fBtnH);

    // Set roster list
    json jListRow  = BuildSetsListRow(oPC);
    json jListGrp  = NuiList(jListRow, JsonInt(SETS_TOTAL), fListH);

    // Detail – selected set title
    json jDetTitle = NuiLabel(NuiBind(SETS_BIND_DET_TITLE),
                        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDetTitle = NuiHeight(jDetTitle, fDetH);
    jDetTitle = NuiStyleForegroundColor(jDetTitle, GetNuiColorNwnGold());

    // Detail – item list
    json jItemRow  = BuildSetsItemRow(oPC);
    json jItemList = NuiList(jItemRow, NuiBind(SETS_BIND_ITEM_CNT), fItemH);

    // Detail – active bonus
    json jBonus = NuiLabel(NuiBind(SETS_BIND_DET_BONUS),
                    JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jBonus = NuiHeight(jBonus, fBonusH);

    // Assemble
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHeaderRow);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, jListGrp);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jDetTitle);
    jCol = JsonArrayInsert(jCol, jItemList);
    jCol = JsonArrayInsert(jCol, jBonus);

    json jGeom = NuiRect(100.0, 80.0, fW, fH);
    int nToken = NuiCreate(oPC, NuiWindow(NuiCol(jCol),
        JsonNull(), NuiBind(SETS_WIN_GEOM),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE), JsonBool(TRUE), JsonBool(TRUE)),
        SETS_WINDOW, SETS_EV_SCRIPT);

    NuiSetBind(oPC, nToken, SETS_WIN_GEOM, jGeom);
    SetLocalInt(oPC, SETS_LVAR_SEL, -1);
    FeedSetsPanel(oPC, nToken);
}

// ----------------------------------------------------------------
// NUI – bind feeding
// ----------------------------------------------------------------

void FeedSetsPanel(object oPC, int nToken)
{
    json jNames  = JsonArray();
    json jCounts = JsonArray();
    json jEncs   = JsonArray();
    json jColors = JsonArray();

    json cGold  = GetNuiColorNwnGold();
    json cWhite = NuiColor(220, 220, 220);
    json cGray  = NuiColor(120, 120, 120);
    json cGreen = NuiColor(100, 210, 100);

    int nSel = GetLocalInt(oPC, SETS_LVAR_SEL);
    int i;
    for(i = 0; i < SETS_TOTAL; i++)
    {
        int nEquipped = SetsGetEquippedCount(oPC, i);
        int nTotal    = SetsGetItemCount(i);

        jNames  = JsonArrayInsert(jNames,  JsonString(SetsGetName(i)));
        jCounts = JsonArrayInsert(jCounts, JsonString(IntToString(nEquipped) + " / " + IntToString(nTotal)));
        jEncs   = JsonArrayInsert(jEncs,   JsonBool(i == nSel));

        json jColor;
        if(nEquipped == nTotal)      jColor = cGreen;
        else if(nEquipped >= 2)      jColor = cGold;
        else if(nEquipped == 1)      jColor = cWhite;
        else                         jColor = cGray;
        jColors = JsonArrayInsert(jColors, jColor);
    }

    NuiSetBind(oPC, nToken, SETS_BIND_NAME,  jNames);
    NuiSetBind(oPC, nToken, SETS_BIND_COUNT, jCounts);
    NuiSetBind(oPC, nToken, SETS_BIND_ENC,   jEncs);
    NuiSetBind(oPC, nToken, SETS_BIND_COLOR, jColors);

    FeedSetsDetail(oPC, nToken);
}

void FeedSetsDetail(object oPC, int nToken)
{
    int nSel = GetLocalInt(oPC, SETS_LVAR_SEL);

    if(nSel < 0 || nSel >= SETS_TOTAL)
    {
        NuiSetBind(oPC, nToken, SETS_BIND_DET_TITLE,
            JsonString("Kliknij zestaw, aby zobaczyć szczegóły."));
        NuiSetBind(oPC, nToken, SETS_BIND_DET_BONUS, JsonString(""));
        NuiSetBind(oPC, nToken, SETS_BIND_ITEM_CNT,  JsonInt(0));
        return;
    }

    int nEquipped = SetsGetEquippedCount(oPC, nSel);
    int nTotal    = SetsGetItemCount(nSel);
    string sTags  = SetsGetItemTags(nSel);
    string sNames = SetsGetItemNames(nSel);

    NuiSetBind(oPC, nToken, SETS_BIND_DET_TITLE,
        JsonString(SetsGetName(nSel) + "  (" + IntToString(nEquipped) + "/" + IntToString(nTotal) + ")"));
    NuiSetBind(oPC, nToken, SETS_BIND_DET_BONUS,
        JsonString(SetsGetActiveBonusDesc(nSel, nEquipped)));
    NuiSetBind(oPC, nToken, SETS_BIND_ITEM_CNT, JsonInt(nTotal));

    json jSyms   = JsonArray();
    json jINames = JsonArray();
    json jICols  = JsonArray();

    json cEquipped = NuiColor(100, 220, 100);
    json cMissing  = NuiColor(130, 130, 130);

    int i;
    for(i = 0; i < nTotal; i++)
    {
        string sTag  = SetsGetToken(sTags,  i);
        string sName = SetsGetToken(sNames, i);
        int bEquip   = SetsIsTagEquipped(oPC, sTag);

        jSyms   = JsonArrayInsert(jSyms,   JsonString(bEquip ? "●" : "○"));
        jINames = JsonArrayInsert(jINames, JsonString(sName));
        jICols  = JsonArrayInsert(jICols,  bEquip ? cEquipped : cMissing);
    }

    NuiSetBind(oPC, nToken, SETS_BIND_ITEM_SYM,  jSyms);
    NuiSetBind(oPC, nToken, SETS_BIND_ITEM_NAME, jINames);
    NuiSetBind(oPC, nToken, SETS_BIND_ITEM_COL,  jICols);
}

// ----------------------------------------------------------------
// Public – open the window for oPC
// ----------------------------------------------------------------

void SetsOpenWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, SETS_WINDOW);
    if(nToken != 0)
    {
        FeedSetsPanel(oPC, nToken);
        return;
    }
    CreateSetsWindow(oPC);
}

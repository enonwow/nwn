#include "lib_chim_def"

// ================================================================
// Effect helpers
// ================================================================

// Removes all graft effects tagged for a specific slot.
void ChimRemoveSlotEffects(object oPC, string sSlot)
{
    string sTag  = CHIM_EFFECT_TAG_PFX + sSlot;
    effect eCurr = GetFirstEffect(oPC);
    while(GetIsEffectValid(eCurr))
    {
        effect eNext = GetNextEffect(oPC);
        if(GetEffectTag(eCurr) == sTag)
            RemoveEffect(oPC, eCurr);
        eCurr = eNext;
    }
}

// Applies the mechanical bonus and penalty effects for one graft.
// Each effect is tagged so ChimRemoveSlotEffects can strip them cleanly.
void ChimApplySlotEffect(object oPC, int nGraftId, string sSlot)
{
    string sTag = CHIM_EFFECT_TAG_PFX + sSlot;
    effect e;

    switch(nGraftId)
    {
        case 1: // Oko Bazyliszka — paralysis immunity / -2 CHA
            e = SetEffectTag(EffectImmunity(IMMUNITY_TYPE_PARALYSIS), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            e = SetEffectTag(EffectAbilityDecrease(ABILITY_CHARISMA, 2), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            break;

        case 2: // Koreks Umysłożercy — +2 INT / -2 STR
            e = SetEffectTag(EffectAbilityIncrease(ABILITY_INTELLIGENCE, 2), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            e = SetEffectTag(EffectAbilityDecrease(ABILITY_STRENGTH, 2), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            break;

        case 3: // Ciało Trolla — regen 1 HP/6s / -50% fire immunity
            e = SetEffectTag(EffectRegenerate(1, 6.0f), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            e = SetEffectTag(EffectDamageImmunityDecrease(DAMAGE_TYPE_FIRE, 50), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            break;

        case 4: // Łuski Smoka — +2 natural AC / -1 STR
            e = SetEffectTag(EffectACIncrease(2, AC_NATURAL_BONUS), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            e = SetEffectTag(EffectAbilityDecrease(ABILITY_STRENGTH, 1), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            break;

        case 5: // Szpony Ghula — +2 attack / -1 CON
            e = SetEffectTag(EffectAttackIncrease(2), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            e = SetEffectTag(EffectAbilityDecrease(ABILITY_CONSTITUTION, 1), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            break;

        case 6: // Jadowity Gruczoł Wiwerna — +1d6 acid on hit / -1 DEX
            e = SetEffectTag(EffectDamageBonus(DAMAGE_BONUS_1d6, DAMAGE_TYPE_ACID), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            e = SetEffectTag(EffectAbilityDecrease(ABILITY_DEXTERITY, 1), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            break;

        case 7: // Mięśnie Ogra — +2 STR / -1 INT
            e = SetEffectTag(EffectAbilityIncrease(ABILITY_STRENGTH, 2), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            e = SetEffectTag(EffectAbilityDecrease(ABILITY_INTELLIGENCE, 1), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            break;

        case 8: // Ścięgna Pająka Fazowego — +2 Spot/Search / -1 WIS
            e = SetEffectTag(EffectSkillIncrease(SKILL_SPOT, 2), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            e = SetEffectTag(EffectSkillIncrease(SKILL_SEARCH, 2), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            e = SetEffectTag(EffectAbilityDecrease(ABILITY_WISDOM, 1), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            break;

        case 9: // Kości Lodowego Giganta — cold resist 10 / -2 DEX
            e = SetEffectTag(EffectDamageResistance(DAMAGE_TYPE_COLD, 10, 0), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            e = SetEffectTag(EffectAbilityDecrease(ABILITY_DEXTERITY, 2), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            break;

        case 10: // Esencja Cienia — +4 Hide/MS / -2 Will
            e = SetEffectTag(EffectSkillIncrease(SKILL_HIDE, 4), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            e = SetEffectTag(EffectSkillIncrease(SKILL_MOVE_SILENTLY, 4), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            e = SetEffectTag(EffectSavingThrowDecrease(SAVING_THROW_WILL, 2), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            break;
    }
}

// Reads all installed grafts from the DB and reapplies their effects.
// Called on client enter to survive server restarts.
void ChimReapplyEffects(object oPC)
{
    ChimRemoveSlotEffects(oPC, CHIM_SLOT_HEAD);
    ChimRemoveSlotEffects(oPC, CHIM_SLOT_TORSO);
    ChimRemoveSlotEffects(oPC, CHIM_SLOT_ARMS);
    ChimRemoveSlotEffects(oPC, CHIM_SLOT_LEGS);

    json jAll  = ChimGetAllGrafts(GetObjectUUID(oPC));
    int nCount = JsonGetLength(jAll);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow   = JsonArrayGet(jAll, i);
        string sSlot = JsonGetString(JsonObjectGet(jRow, "slot"));
        int nGraftId = JsonGetInt   (JsonObjectGet(jRow, "graft_id"));
        ChimApplySlotEffect(oPC, nGraftId, sSlot);
    }
}

// ================================================================
// NUI layout
// ================================================================

json ChimBuildLayout(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fRowH  = GetNuiScaleDimension(oPC, 28.0);
    float fListH = GetNuiScaleDimension(oPC, 130.0);
    float fDetH  = GetNuiScaleDimension(oPC, 140.0);
    float fLeftW = GetNuiScaleDimension(oPC, 195.0);

    // ---- Header: title + close ----
    json jTitle = NuiLabel(JsonString("WARSZTAT CHIMERYSTY"),
                           JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiStyleForegroundColor(jTitle, GetNuiColorNwnGold());

    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, CHIM_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 30.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jHdr = JsonArray();
    jHdr = JsonArrayInsert(jHdr, jTitle);
    jHdr = JsonArrayInsert(jHdr, NuiSpacer());
    jHdr = JsonArrayInsert(jHdr, jClose);

    // ---- Left column: 4 slot buttons ----
    json jHead = NuiButton(NuiBind(CHIM_BIND_HEAD_LBL));
    jHead = NuiId(jHead, CHIM_BTN_HEAD);
    jHead = NuiEncouraged(jHead, NuiBind(CHIM_BIND_HEAD_ENC));
    jHead = NuiHeight(jHead, fBtnH);

    json jTorso = NuiButton(NuiBind(CHIM_BIND_TORSO_LBL));
    jTorso = NuiId(jTorso, CHIM_BTN_TORSO);
    jTorso = NuiEncouraged(jTorso, NuiBind(CHIM_BIND_TORSO_ENC));
    jTorso = NuiHeight(jTorso, fBtnH);

    json jArms = NuiButton(NuiBind(CHIM_BIND_ARMS_LBL));
    jArms = NuiId(jArms, CHIM_BTN_ARMS);
    jArms = NuiEncouraged(jArms, NuiBind(CHIM_BIND_ARMS_ENC));
    jArms = NuiHeight(jArms, fBtnH);

    json jLegs = NuiButton(NuiBind(CHIM_BIND_LEGS_LBL));
    jLegs = NuiId(jLegs, CHIM_BTN_LEGS);
    jLegs = NuiEncouraged(jLegs, NuiBind(CHIM_BIND_LEGS_ENC));
    jLegs = NuiHeight(jLegs, fBtnH);

    json jSlotHdr = NuiLabel(JsonString("Sloty przeszczepu:"),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSlotHdr = NuiHeight(jSlotHdr, GetNuiScaleDimension(oPC, 22.0));

    json jLeftCol = JsonArray();
    jLeftCol = JsonArrayInsert(jLeftCol, NuiRow(JsonArrayInsert(JsonArray(), jSlotHdr)));
    jLeftCol = JsonArrayInsert(jLeftCol, NuiRow(JsonArrayInsert(JsonArray(), jHead)));
    jLeftCol = JsonArrayInsert(jLeftCol, NuiRow(JsonArrayInsert(JsonArray(), jTorso)));
    jLeftCol = JsonArrayInsert(jLeftCol, NuiRow(JsonArrayInsert(JsonArray(), jArms)));
    jLeftCol = JsonArrayInsert(jLeftCol, NuiRow(JsonArrayInsert(JsonArray(), jLegs)));
    jLeftCol = JsonArrayInsert(jLeftCol, NuiSpacer());

    json jLeftGrp = NuiGroup(NuiCol(jLeftCol), TRUE, NUI_SCROLLBARS_NONE);
    jLeftGrp = NuiWidth(jLeftGrp, fLeftW);

    // ---- Right column ----

    // Selected-slot header label
    json jSelLbl = NuiLabel(NuiBind(CHIM_BIND_SEL_LBL),
                            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSelLbl = NuiHeight(jSelLbl, GetNuiScaleDimension(oPC, 22.0));

    // Scrollable graft list
    json jListCell = NuiGroup(
        NuiRow(JsonArrayInsert(JsonArray(),
            NuiLabel(NuiBind(CHIM_BIND_LST_NAME),
                     JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)))),
        TRUE, NUI_SCROLLBARS_NONE);
    jListCell = NuiId(jListCell, CHIM_BTN_ROW);
    jListCell = NuiEncouraged(jListCell, NuiBind(CHIM_BIND_LST_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jListCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(CHIM_BIND_LST_CNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // Detail area: name / flavor / effects / requirement
    json jInfoName = NuiLabel(NuiBind(CHIM_BIND_INFO_NAME),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jInfoName = NuiStyleForegroundColor(jInfoName, GetNuiColorNwnGold());
    jInfoName = NuiHeight(jInfoName, GetNuiScaleDimension(oPC, 22.0));

    json jInfoFlavor = NuiGroup(NuiText(NuiBind(CHIM_BIND_INFO_FLAVOR), FALSE),
                                FALSE, NUI_SCROLLBARS_NONE);
    jInfoFlavor = NuiHeight(jInfoFlavor, GetNuiScaleDimension(oPC, 50.0));

    json jInfoFx = NuiLabel(NuiBind(CHIM_BIND_INFO_FX),
                            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jInfoFx = NuiHeight(jInfoFx, GetNuiScaleDimension(oPC, 22.0));

    json jInfoReq = NuiLabel(NuiBind(CHIM_BIND_INFO_REQ),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jInfoReq = NuiHeight(jInfoReq, GetNuiScaleDimension(oPC, 22.0));

    json jDetCol = JsonArray();
    jDetCol = JsonArrayInsert(jDetCol, NuiRow(JsonArrayInsert(JsonArray(), jInfoName)));
    jDetCol = JsonArrayInsert(jDetCol, jInfoFlavor);
    jDetCol = JsonArrayInsert(jDetCol, NuiRow(JsonArrayInsert(JsonArray(), jInfoFx)));
    jDetCol = JsonArrayInsert(jDetCol, NuiRow(JsonArrayInsert(JsonArray(), jInfoReq)));

    json jDetGrp = NuiGroup(NuiCol(jDetCol), TRUE, NUI_SCROLLBARS_NONE);
    jDetGrp = NuiHeight(jDetGrp, fDetH);

    // Action buttons
    json jGraftBtn = NuiButton(JsonString("Zainstaluj"));
    jGraftBtn = NuiId(jGraftBtn, CHIM_BTN_GRAFT);
    jGraftBtn = NuiEnabled(jGraftBtn, NuiBind(CHIM_BIND_GRAFT_ENA));
    jGraftBtn = NuiHeight(jGraftBtn, fBtnH);

    string sRemoveLbl = "Usuń (−" + IntToString(CHIM_REMOVE_COST) + " zp / −" + IntToString(CHIM_REMOVE_HP) + " HP)";
    json jRemoveBtn = NuiButton(JsonString(sRemoveLbl));
    jRemoveBtn = NuiId(jRemoveBtn, CHIM_BTN_REMOVE);
    jRemoveBtn = NuiEnabled(jRemoveBtn, NuiBind(CHIM_BIND_REMOVE_ENA));
    jRemoveBtn = NuiHeight(jRemoveBtn, fBtnH);

    json jActRow = JsonArray();
    jActRow = JsonArrayInsert(jActRow, jGraftBtn);
    jActRow = JsonArrayInsert(jActRow, NuiSpacer());
    jActRow = JsonArrayInsert(jActRow, jRemoveBtn);

    // Status line
    json jStatus = NuiLabel(NuiBind(CHIM_BIND_STATUS),
                            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatus = NuiHeight(jStatus, GetNuiScaleDimension(oPC, 22.0));

    json jRightCol = JsonArray();
    jRightCol = JsonArrayInsert(jRightCol, NuiRow(JsonArrayInsert(JsonArray(), jSelLbl)));
    jRightCol = JsonArrayInsert(jRightCol, jList);
    jRightCol = JsonArrayInsert(jRightCol, jDetGrp);
    jRightCol = JsonArrayInsert(jRightCol, NuiRow(jActRow));
    jRightCol = JsonArrayInsert(jRightCol, NuiRow(JsonArrayInsert(JsonArray(), jStatus)));

    // ---- Assemble: header + two columns ----
    json jBodyRow = JsonArray();
    jBodyRow = JsonArrayInsert(jBodyRow, jLeftGrp);
    jBodyRow = JsonArrayInsert(jBodyRow, NuiCol(jRightCol));

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jHdr));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jBodyRow));

    return NuiCol(jRoot);
}

// ================================================================
// Feed functions
// ================================================================

void ChimFeedSlots(object oPC, int nToken)
{
    string sSel = GetLocalString(oPC, CHIM_LVAR_SEL_SLOT);
    NuiSetBind(oPC, nToken, CHIM_BIND_HEAD_LBL,  JsonString(ChimSlotButtonLabel(oPC, CHIM_SLOT_HEAD)));
    NuiSetBind(oPC, nToken, CHIM_BIND_TORSO_LBL, JsonString(ChimSlotButtonLabel(oPC, CHIM_SLOT_TORSO)));
    NuiSetBind(oPC, nToken, CHIM_BIND_ARMS_LBL,  JsonString(ChimSlotButtonLabel(oPC, CHIM_SLOT_ARMS)));
    NuiSetBind(oPC, nToken, CHIM_BIND_LEGS_LBL,  JsonString(ChimSlotButtonLabel(oPC, CHIM_SLOT_LEGS)));
    NuiSetBind(oPC, nToken, CHIM_BIND_HEAD_ENC,  JsonBool(sSel == CHIM_SLOT_HEAD));
    NuiSetBind(oPC, nToken, CHIM_BIND_TORSO_ENC, JsonBool(sSel == CHIM_SLOT_TORSO));
    NuiSetBind(oPC, nToken, CHIM_BIND_ARMS_ENC,  JsonBool(sSel == CHIM_SLOT_ARMS));
    NuiSetBind(oPC, nToken, CHIM_BIND_LEGS_ENC,  JsonBool(sSel == CHIM_SLOT_LEGS));
}

void ChimFeedGraftList(object oPC, int nToken, string sSlot)
{
    json jGrafts = ChimGetGraftsForSlot(sSlot);
    SetLocalJson(oPC, CHIM_LVAR_AVAIL, jGrafts);
    int nCount  = JsonGetLength(jGrafts);
    int nSelId  = GetLocalInt(oPC, CHIM_LVAR_SEL_GRAFT);
    int nInstId = ChimGetInstalledGraft(GetObjectUUID(oPC), sSlot);

    json jNames = JsonArray();
    json jEncs  = JsonArray();
    int i;
    for(i = 0; i < nCount; i++)
    {
        json g    = JsonArrayGet(jGrafts, i);
        int nId   = JsonGetInt   (JsonObjectGet(g, "id"));
        string sN = JsonGetString(JsonObjectGet(g, "name"));
        // Prefix asterisk for the currently installed graft
        if(nId == nInstId) sN = "[*] " + sN;
        jNames = JsonArrayInsert(jNames, JsonString(sN));
        jEncs  = JsonArrayInsert(jEncs, JsonBool(nId == nSelId));
    }

    NuiSetBind(oPC, nToken, CHIM_BIND_LST_NAME, jNames);
    NuiSetBind(oPC, nToken, CHIM_BIND_LST_ENC,  jEncs);
    NuiSetBind(oPC, nToken, CHIM_BIND_LST_CNT,  JsonInt(nCount));
}

void ChimFeedDetail(object oPC, int nToken, json jGraft)
{
    if(JsonGetType(jGraft) == JSON_TYPE_NULL)
    {
        NuiSetBind(oPC, nToken, CHIM_BIND_INFO_NAME,   JsonString(""));
        NuiSetBind(oPC, nToken, CHIM_BIND_INFO_FLAVOR, JsonString("Wybierz przeszczep z listy."));
        NuiSetBind(oPC, nToken, CHIM_BIND_INFO_FX,     JsonString(""));
        NuiSetBind(oPC, nToken, CHIM_BIND_INFO_REQ,    JsonString(""));
        NuiSetBind(oPC, nToken, CHIM_BIND_GRAFT_ENA,   JsonBool(FALSE));
        NuiSetBind(oPC, nToken, CHIM_BIND_REMOVE_ENA,  JsonBool(FALSE));
        return;
    }

    int    nId      = JsonGetInt   (JsonObjectGet(jGraft, "id"));
    string sName    = JsonGetString(JsonObjectGet(jGraft, "name"));
    string sFlavor  = JsonGetString(JsonObjectGet(jGraft, "flavor"));
    string sFxDesc  = JsonGetString(JsonObjectGet(jGraft, "fx_desc"));
    string sTrophy  = JsonGetString(JsonObjectGet(jGraft, "trophy"));
    string sTrophyN = JsonGetString(JsonObjectGet(jGraft, "trophy_n"));
    string sSlot    = JsonGetString(JsonObjectGet(jGraft, "slot"));

    NuiSetBind(oPC, nToken, CHIM_BIND_INFO_NAME,   JsonString(sName));
    NuiSetBind(oPC, nToken, CHIM_BIND_INFO_FLAVOR,  JsonString(sFlavor));
    NuiSetBind(oPC, nToken, CHIM_BIND_INFO_FX,      JsonString("Efekty: " + sFxDesc));
    NuiSetBind(oPC, nToken, CHIM_BIND_INFO_REQ,
        JsonString("Trofeum: " + sTrophyN + "   |   Koszt: " + IntToString(CHIM_GRAFT_COST) + " zp"));

    int nInstalled  = ChimGetInstalledGraft(GetObjectUUID(oPC), sSlot);
    int bHasTrophy  = GetIsObjectValid(GetItemPossessedBy(oPC, sTrophy));
    // Can install if a different (or no) graft is in the slot and we own the trophy
    int bCanInstall = (nInstalled != nId) && bHasTrophy;
    int bCanRemove  = (nInstalled == nId);

    NuiSetBind(oPC, nToken, CHIM_BIND_GRAFT_ENA,  JsonBool(bCanInstall));
    NuiSetBind(oPC, nToken, CHIM_BIND_REMOVE_ENA, JsonBool(bCanRemove));
}

// ================================================================
// Window management
// ================================================================

void ChimOpenWindow(object oPC)
{
    // Toggle: close if already open
    int nToken = NuiFindWindow(oPC, CHIM_WINDOW);
    if(nToken != 0)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, CHIM_WIN_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, CHIM_WIN_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
                         GetNuiScaleDimension(oPC, CHIM_WIN_W),
                         GetNuiScaleDimension(oPC, CHIM_WIN_H));

    json jRoot = ChimBuildLayout(oPC);
    json jWin  = NuiWindow(jRoot,
        JsonBool(FALSE),          // no system title bar
        NuiBind(CHIM_BIND_GEOM),
        JsonBool(FALSE),          // not resizable
        JsonBool(FALSE),          // not collapsed
        JsonBool(FALSE),          // no system close button
        JsonBool(FALSE),          // not transparent
        JsonBool(TRUE));          // show border

    nToken = NuiCreate(oPC, jWin, CHIM_WINDOW, CHIM_EV_SCRIPT);
    NuiSetBind(oPC, nToken, CHIM_BIND_GEOM, jGeom);

    // Reset PC state
    DeleteLocalString(oPC, CHIM_LVAR_SEL_SLOT);
    DeleteLocalInt   (oPC, CHIM_LVAR_SEL_GRAFT);
    SetLocalJson     (oPC, CHIM_LVAR_AVAIL, JsonArray());

    // Initial binds
    ChimFeedSlots(oPC, nToken);
    NuiSetBind(oPC, nToken, CHIM_BIND_SEL_LBL,
        JsonString("Wybierz slot ciała, by zobaczyć dostępne przeszczepy."));
    NuiSetBind(oPC, nToken, CHIM_BIND_LST_CNT,   JsonInt(0));
    NuiSetBind(oPC, nToken, CHIM_BIND_LST_NAME,  JsonArray());
    NuiSetBind(oPC, nToken, CHIM_BIND_LST_ENC,   JsonArray());
    NuiSetBind(oPC, nToken, CHIM_BIND_INFO_NAME,  JsonString(""));
    NuiSetBind(oPC, nToken, CHIM_BIND_INFO_FLAVOR,
        JsonString("Przeszczepy łączą twoją biologię z materią potworów.\nKażdy niesie moc — i cenę."));
    NuiSetBind(oPC, nToken, CHIM_BIND_INFO_FX,    JsonString(""));
    NuiSetBind(oPC, nToken, CHIM_BIND_INFO_REQ,   JsonString(""));
    NuiSetBind(oPC, nToken, CHIM_BIND_GRAFT_ENA,  JsonBool(FALSE));
    NuiSetBind(oPC, nToken, CHIM_BIND_REMOVE_ENA, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, CHIM_BIND_STATUS,      JsonString(""));
}

// ================================================================
// Install handler
// ================================================================

void ChimHandleInstall(object oPC, int nToken)
{
    int nGraftId = GetLocalInt(oPC, CHIM_LVAR_SEL_GRAFT);
    if(nGraftId == 0)
    {
        NuiSetBind(oPC, nToken, CHIM_BIND_STATUS,
            JsonString("Najpierw wybierz przeszczep z listy."));
        return;
    }

    json jGraft = ChimGetGraftById(nGraftId);
    if(JsonGetType(jGraft) == JSON_TYPE_NULL) return;

    string sSlot    = JsonGetString(JsonObjectGet(jGraft, "slot"));
    string sTrophy  = JsonGetString(JsonObjectGet(jGraft, "trophy"));
    string sTrophyN = JsonGetString(JsonObjectGet(jGraft, "trophy_n"));
    string sName    = JsonGetString(JsonObjectGet(jGraft, "name"));

    if(GetGold(oPC) < CHIM_GRAFT_COST)
    {
        NuiSetBind(oPC, nToken, CHIM_BIND_STATUS,
            JsonString("Potrzebujesz co najmniej " + IntToString(CHIM_GRAFT_COST) + " zp."));
        return;
    }

    object oTrophy = GetItemPossessedBy(oPC, sTrophy);
    if(!GetIsObjectValid(oTrophy))
    {
        NuiSetBind(oPC, nToken, CHIM_BIND_STATUS,
            JsonString("Brak trofeum: " + sTrophyN + "."));
        return;
    }

    // Remove any existing graft in this slot before installing the new one
    int nOldGraft = ChimGetInstalledGraft(GetObjectUUID(oPC), sSlot);
    if(nOldGraft != 0)
    {
        ChimRemoveSlotEffects(oPC, sSlot);
        ChimRemoveGraft(GetObjectUUID(oPC), sSlot);
    }

    DestroyObject(oTrophy);
    AssignCommand(oPC, TakeGoldFromCreature(CHIM_GRAFT_COST, oPC, TRUE));

    ChimInstallGraft(GetObjectUUID(oPC), sSlot, nGraftId);
    ChimApplySlotEffect(oPC, nGraftId, sSlot);

    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
        EffectVisualEffect(VFX_COM_BLOOD_CRT_RED), oPC, 2.0f);

    NuiSetBind(oPC, nToken, CHIM_BIND_STATUS,
        JsonString("Przeszczep zainstalowany: " + sName + ". Pieczęć krwi pulsuje słabo..."));

    ChimFeedSlots(oPC, nToken);
    ChimFeedGraftList(oPC, nToken, sSlot);
    ChimFeedDetail(oPC, nToken, jGraft);
}

// ================================================================
// Remove handler
// ================================================================

void ChimHandleRemove(object oPC, int nToken)
{
    int nGraftId = GetLocalInt(oPC, CHIM_LVAR_SEL_GRAFT);
    if(nGraftId == 0) return;

    json jGraft = ChimGetGraftById(nGraftId);
    if(JsonGetType(jGraft) == JSON_TYPE_NULL) return;

    string sSlot = JsonGetString(JsonObjectGet(jGraft, "slot"));
    string sName = JsonGetString(JsonObjectGet(jGraft, "name"));

    if(GetGold(oPC) < CHIM_REMOVE_COST)
    {
        NuiSetBind(oPC, nToken, CHIM_BIND_STATUS,
            JsonString("Usunięcie kosztuje " + IntToString(CHIM_REMOVE_COST) + " zp."));
        return;
    }

    if(GetCurrentHitPoints(oPC) <= CHIM_REMOVE_HP)
    {
        NuiSetBind(oPC, nToken, CHIM_BIND_STATUS,
            JsonString("Za mało HP, by przeżyć zabieg usunięcia."));
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(CHIM_REMOVE_COST, oPC, TRUE));
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectDamage(CHIM_REMOVE_HP, DAMAGE_TYPE_SLASHING), oPC);

    ChimRemoveSlotEffects(oPC, sSlot);
    ChimRemoveGraft(GetObjectUUID(oPC), sSlot);

    NuiSetBind(oPC, nToken, CHIM_BIND_STATUS,
        JsonString("Przeszczep usunięty: " + sName + ". Rana zaczyna krwawić."));

    SetLocalInt(oPC, CHIM_LVAR_SEL_GRAFT, 0);
    ChimFeedSlots(oPC, nToken);
    ChimFeedGraftList(oPC, nToken, sSlot);
    ChimFeedDetail(oPC, nToken, JsonNull());
}

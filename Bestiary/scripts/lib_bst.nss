// lib_bst.nss — Codex Bestiarum: NUI layout, feed functions, bonus management
#include "lib_bst_def"

// ----------------------------------------------------------------
// Effect management
// ----------------------------------------------------------------

void BstRemoveBonuses(object oPC)
{
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        effect eNext = GetNextEffect(oPC);
        if(GetEffectTag(eEff) == BST_EFFECT_TAG)
            RemoveEffect(oPC, eEff);
        eEff = eNext;
    }
}

void BstApplyBonuses(object oPC)
{
    int nTier2Count = 0;
    int nTier3Count = 0;
    int i;
    for(i = 0; i < BST_RACE_COUNT; i++)
    {
        int nTier = BstGetTier(BstGetKills(oPC, i));
        if(nTier >= 2) nTier2Count++;
        if(nTier >= 3) nTier3Count++;
    }

    int nAB  = nTier2Count < BST_MAX_BONUS_AB  ? nTier2Count  : BST_MAX_BONUS_AB;
    int nDmg = nTier3Count < BST_MAX_BONUS_DMG ? nTier3Count  : BST_MAX_BONUS_DMG;

    BstRemoveBonuses(oPC);

    if(nAB > 0)
    {
        effect eAB = TagEffect(
            SupernaturalEffect(EffectAttackIncrease(nAB, ATTACK_BONUS_MISC)),
            BST_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eAB, oPC);
    }
    if(nDmg > 0)
    {
        effect eDmg = TagEffect(
            SupernaturalEffect(EffectDamageIncrease(nDmg, DAMAGE_TYPE_MAGICAL)),
            BST_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eDmg, oPC);
    }

}

// ----------------------------------------------------------------
// NUI — detail panel layout (swappable group)
// ----------------------------------------------------------------

json BstBuildDetailEmpty(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 28.0);

    json jHint = NuiLabel(
        JsonString("Wybierz kategorię po lewej, aby zobaczyć szczegóły."),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));

    json jStudyBtn = NuiButton(JsonString("Zbadaj stworzenie [+]"));
    jStudyBtn = NuiId(jStudyBtn, BST_BTN_STUDY);
    jStudyBtn = NuiEnabled(jStudyBtn, NuiBind(BST_BIND_STUDY_ENA));
    jStudyBtn = NuiHeight(jStudyBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jStudyBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, jHint);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    return NuiCol(jCol);
}

json BstBuildDetailPanel(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fLoreH = GetNuiScaleDimension(oPC, 280.0);

    json jTitle = NuiLabel(NuiBind(BST_BIND_DET_TITLE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);

    json jKillsLbl = NuiLabel(NuiBind(BST_BIND_DET_KILLS),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jKillsLbl = NuiHeight(jKillsLbl, GetNuiScaleDimension(oPC, 22.0));

    json jLore = NuiGroup(NuiText(NuiBind(BST_BIND_DET_LORE), FALSE), TRUE, NUI_SCROLLBARS_AUTO);
    jLore = NuiHeight(jLore, fLoreH);

    json jBonus = NuiLabel(NuiBind(BST_BIND_DET_BONUS),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jBonus = NuiHeight(jBonus, GetNuiScaleDimension(oPC, 56.0));

    json jStudyBtn = NuiButton(JsonString("Zbadaj stworzenie [+]"));
    jStudyBtn = NuiId(jStudyBtn, BST_BTN_STUDY);
    jStudyBtn = NuiEnabled(jStudyBtn, NuiBind(BST_BIND_STUDY_ENA));
    jStudyBtn = NuiHeight(jStudyBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jStudyBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jTitle);
    jCol = JsonArrayInsert(jCol, jKillsLbl);
    jCol = JsonArrayInsert(jCol, jLore);
    jCol = JsonArrayInsert(jCol, jBonus);
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    return NuiCol(jCol);
}

// ----------------------------------------------------------------
// NUI — full window layout
// ----------------------------------------------------------------

json BstBuildWindow(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);
    float fListW = GetNuiScaleDimension(oPC, BST_LIST_W);

    // ---- top bar ----
    json jTitle = NuiLabel(JsonString("Codex Bestiarum"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);

    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, BST_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 28.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitle);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jClose);

    // ---- list column ----
    json jNameLbl = NuiLabel(NuiBind(BST_BIND_ROW_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(BST_BIND_ROW_COLOR));

    json jKillsLbl = NuiLabel(NuiBind(BST_BIND_ROW_KILLS),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jKillsLbl = NuiWidth(jKillsLbl, GetNuiScaleDimension(oPC, 36.0));
    jKillsLbl = NuiStyleForegroundColor(jKillsLbl, NuiBind(BST_BIND_ROW_COLOR));

    json jTierLbl = NuiLabel(NuiBind(BST_BIND_ROW_TIER),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTierLbl = NuiWidth(jTierLbl, GetNuiScaleDimension(oPC, 58.0));
    jTierLbl = NuiStyleForegroundColor(jTierLbl, NuiBind(BST_BIND_ROW_COLOR));

    json jCells = JsonArray();
    jCells = JsonArrayInsert(jCells, jNameLbl);
    jCells = JsonArrayInsert(jCells, jKillsLbl);
    jCells = JsonArrayInsert(jCells, jTierLbl);

    json jRowGroup = NuiGroup(NuiRow(jCells), TRUE, NUI_SCROLLBARS_NONE);
    jRowGroup = NuiId(jRowGroup, BST_BTN_ROW);
    jRowGroup = NuiEncouraged(jRowGroup, NuiBind(BST_BIND_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(),
        NuiListTemplateCell(jRowGroup, 0.0, TRUE));

    float fListH = GetNuiScaleDimension(oPC, (BST_RACE_COUNT * 26) + 4.0);
    json jList = NuiList(jTmpl, JsonInt(BST_RACE_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    json jListCol = NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jList)), fListW);

    // ---- detail group (swappable) ----
    json jDetailGrp = NuiGroup(BstBuildDetailEmpty(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jDetailGrp = NuiId(jDetailGrp, BST_GRP_DETAIL);

    // ---- horizontal split ----
    json jSplitRow = JsonArray();
    jSplitRow = JsonArrayInsert(jSplitRow, jListCol);
    jSplitRow = JsonArrayInsert(jSplitRow, jDetailGrp);

    // ---- root column ----
    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jTopRow));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jSplitRow));

    return NuiCol(jRoot);
}

// ----------------------------------------------------------------
// Window open
// ----------------------------------------------------------------

void BstOpenCodex(object oPC)
{
    int nToken = NuiFindWindow(oPC, BST_WIN_CODEX);
    if(nToken != 0)
    {
        NuiSetGroupLayout(oPC, nToken, BST_GRP_DETAIL, BstBuildDetailEmpty(oPC));
        BstFeedList(oPC, nToken);
        NuiSetBind(oPC, nToken, BST_BIND_STUDY_ENA, JsonBool(TRUE));
        DeleteLocalInt(oPC, BST_LVAR_SEL_IDX);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, BST_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, BST_H)) / 2.0;

    json jGeom = NuiRect(fCX, fCY,
        GetNuiScaleDimension(oPC, BST_W),
        GetNuiScaleDimension(oPC, BST_H));

    json jWin = NuiWindow(BstBuildWindow(oPC),
        JsonBool(FALSE),
        NuiBind(BST_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, BST_WIN_CODEX, BST_EV_SCRIPT);
    NuiSetBind(oPC, nToken, BST_WIN_GEOM, jGeom);
    BstFeedList(oPC, nToken);
    NuiSetBind(oPC, nToken, BST_BIND_STUDY_ENA, JsonBool(TRUE));
}

// ----------------------------------------------------------------
// Feed — list panel
// ----------------------------------------------------------------

void BstFeedList(object oPC, int nToken)
{
    json jNames  = JsonArray();
    json jKills  = JsonArray();
    json jTiers  = JsonArray();
    json jColors = JsonArray();
    json jEncs   = JsonArray();

    int nSelIdx = GetLocalInt(oPC, BST_LVAR_SEL_IDX) - 1;
    // -1 == none selected (we store idx+1 so 0 means unset)

    int i;
    for(i = 0; i < BST_RACE_COUNT; i++)
    {
        int nKills = BstGetKills(oPC, i);
        int nTier  = BstGetTier(nKills);

        jNames  = JsonArrayInsert(jNames,  JsonString(BstRaceIndexToName(i)));
        jKills  = JsonArrayInsert(jKills,  JsonString(IntToString(nKills)));
        jTiers  = JsonArrayInsert(jTiers,  JsonString(BstGetTierLabel(nTier)));
        jColors = JsonArrayInsert(jColors, BstGetTierColor(nTier));
        jEncs   = JsonArrayInsert(jEncs,   JsonBool(nSelIdx == i));
    }

    NuiSetBind(oPC, nToken, BST_BIND_ROW_NAME,  jNames);
    NuiSetBind(oPC, nToken, BST_BIND_ROW_KILLS, jKills);
    NuiSetBind(oPC, nToken, BST_BIND_ROW_TIER,  jTiers);
    NuiSetBind(oPC, nToken, BST_BIND_ROW_COLOR, jColors);
    NuiSetBind(oPC, nToken, BST_BIND_ROW_ENC,   jEncs);
}

// ----------------------------------------------------------------
// Feed — detail panel for selected race
// ----------------------------------------------------------------

void BstFeedDetail(object oPC, int nToken, int nRaceIdx)
{
    NuiSetGroupLayout(oPC, nToken, BST_GRP_DETAIL, BstBuildDetailPanel(oPC));

    int nKills = BstGetKills(oPC, nRaceIdx);
    int nTier  = BstGetTier(nKills);

    // Title shows race name + tier badge
    string sTierBadge = nTier > 0 ? "  [" + BstGetTierLabel(nTier) + "]" : "";
    NuiSetBind(oPC, nToken, BST_BIND_DET_TITLE,
        JsonString(BstRaceIndexToName(nRaceIdx) + sTierBadge));

    // Kill/progress line
    string sKillsLine;
    if(nTier == 3)
    {
        sKillsLine = "Zbadano: " + IntToString(nKills) + "  (Mistrzostwo osiągnięte)";
    }
    else
    {
        int nNextThreshold = (nTier == 0) ? BST_TIER1_KILLS
                           : (nTier == 1) ? BST_TIER2_KILLS
                                          : BST_TIER3_KILLS;
        string sNextTier = (nTier == 0) ? "Poznany"
                         : (nTier == 1) ? "Zbadany"
                                        : "Mistrz";
        sKillsLine = "Zbadano: " + IntToString(nKills) + " / " + IntToString(nNextThreshold)
                   + "  (do: " + sNextTier + ")";
    }
    NuiSetBind(oPC, nToken, BST_BIND_DET_KILLS, JsonString(sKillsLine));

    // Lore text
    NuiSetBind(oPC, nToken, BST_BIND_DET_LORE, JsonString(BstGetLoreText(nRaceIdx, nTier)));

    // Global bonus summary
    int nTier2Count = 0;
    int nTier3Count = 0;
    int j;
    for(j = 0; j < BST_RACE_COUNT; j++)
    {
        int t = BstGetTier(BstGetKills(oPC, j));
        if(t >= 2) nTier2Count++;
        if(t >= 3) nTier3Count++;
    }
    NuiSetBind(oPC, nToken, BST_BIND_DET_BONUS,
        JsonString(BstGetBonusText(nTier2Count, nTier3Count)));

    NuiSetBind(oPC, nToken, BST_BIND_STUDY_ENA, JsonBool(TRUE));
}

// ----------------------------------------------------------------
// Target handler — called from sys_on_target.nss
// ----------------------------------------------------------------

void BstHandleTarget(object oPC)
{
    if(!GetLocalInt(oPC, BST_LVAR_STUDYING)) return;
    DeleteLocalInt(oPC, BST_LVAR_STUDYING);

    object oTarget = GetTargetingModeSelectedObject();

    if(!GetIsObjectValid(oTarget)
       || GetObjectType(oTarget) != OBJECT_TYPE_CREATURE)
    {
        SendMessageToPC(oPC, "[Codex] Możesz badać tylko stworzenia.");
        return;
    }

    if(GetIsPC(oTarget))
    {
        SendMessageToPC(oPC, "[Codex] Nie możesz badać innych graczy.");
        return;
    }

    if(GetLocalInt(oTarget, BST_LVAR_STUDIED))
    {
        SendMessageToPC(oPC, "[Codex] To stworzenie zostało już przez ciebie zbadane.");
        return;
    }

    int nType    = GetRacialType(oTarget);
    int nRaceIdx = BstTypeToRaceIndex(nType);

    if(nRaceIdx < 0)
    {
        SendMessageToPC(oPC, "[Codex] Ten typ stworzenia nie jest ujęty w kodeksie.");
        return;
    }

    // Mark this creature instance as studied — prevents repeated study of same body
    SetLocalInt(oTarget, BST_LVAR_STUDIED, 1);

    int nOldKills = BstGetKills(oPC, nRaceIdx);
    BstAddStudy(oPC, nRaceIdx);
    int nNewKills = nOldKills + 1;

    string sRace    = BstRaceIndexToName(nRaceIdx);
    int    nOldTier = BstGetTier(nOldKills);
    int    nNewTier = BstGetTier(nNewKills);

    SendMessageToPC(oPC, "[Codex] Zbadano: " + GetName(oTarget) + " (" + sRace + ")."
                       + "  Obserwacje: " + IntToString(nNewKills) + ".");

    if(nNewTier > nOldTier)
    {
        string sMsg;
        switch(nNewTier)
        {
            case 1: sMsg = "Pierwsze obserwacje dotyczące " + sRace
                          + " zostały zanotowane. Ich słabości zaczynają być widoczne."; break;
            case 2: sMsg = "Twoje studium " + sRace + " przynosi pierwsze premie bojowe."
                          + " Wiedza ta jest już częścią twoich instynktów."; break;
            case 3: sMsg = "Osiągnąłeś mistrzostwo w konfrontacji z " + sRace + "."
                          + " Żadna z ich sztuczek cię już nie zaskoczy."; break;
            default: sMsg = ""; break;
        }
        if(sMsg != "")
        {
            FloatingTextStringOnCreature("[Codex] " + sMsg, oPC, FALSE);
            SendMessageToPC(oPC, "[Codex] " + sMsg);
        }

        if(nNewTier >= 2)
            BstApplyBonuses(oPC);
    }

    // Refresh open codex window
    int nToken = NuiFindWindow(oPC, BST_WIN_CODEX);
    if(nToken != 0)
    {
        // Update selection so the studied race is highlighted
        SetLocalInt(oPC, BST_LVAR_SEL_IDX, nRaceIdx + 1);
        BstFeedList(oPC, nToken);
        BstFeedDetail(oPC, nToken, nRaceIdx);
    }
}

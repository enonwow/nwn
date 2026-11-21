#include "lib_ma_def"

void FeedMaWindow(object oPC, int nToken);
void MaShowProposal(object oPC, string sFromUuid, string sFromName);
void MaApplyApprenticeBonuses(object oApprentice);
void MaRemoveApprenticeBonuses(object oApprentice);

// ----------------------------------------------------------------
// Skill bonus application
// ----------------------------------------------------------------

void MaRemoveApprenticeBonuses(object oPC)
{
    if(!GetIsObjectValid(oPC)) return;
    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        if(GetEffectTag(e) == MA_EFFECT_TAG)
            RemoveEffect(oPC, e);
        e = GetNextEffect(oPC);
    }
}

void MaApplyApprenticeBonuses(object oApprentice)
{
    MaRemoveApprenticeBonuses(oApprentice);
    string sMasterUuid = MaGetMasterUuid(GetObjectUUID(oApprentice));
    if(sMasterUuid == "") return;
    object oMaster = MaGetPCByUUID(sMasterUuid);
    if(!GetIsObjectValid(oMaster)) return; // applied next time both are online together

    int nSkill;
    int nGranted = 0;
    for(nSkill = 0; nSkill <= MA_MAX_SKILL_INDEX; nSkill++)
    {
        int nMasterRank = GetSkillRank(nSkill, oMaster, TRUE);
        if(nMasterRank >= MA_SKILL_THRESHOLD)
        {
            effect eBonus = EffectSkillIncrease(nSkill, MA_SKILL_BONUS);
            eBonus = TagEffect(eBonus, MA_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eBonus, oApprentice);
            nGranted++;
        }
    }

    if(nGranted > 0)
        SendMessageToPC(oApprentice, "[Mentor] Bond with " + GetName(oMaster)
            + " grants +" + IntToString(MA_SKILL_BONUS) + " to "
            + IntToString(nGranted) + " skill(s).");
}

// ----------------------------------------------------------------
// Bond lifecycle
// ----------------------------------------------------------------

int MaProposeApprenticeship(object oMaster, object oCandidate)
{
    if(oMaster == oCandidate)
    {
        SendMessageToPC(oMaster, "[Mentor] You cannot apprentice yourself.");
        return 0;
    }
    if(!GetIsPC(oCandidate))
    {
        SendMessageToPC(oMaster, "[Mentor] Only living players can be apprenticed.");
        return 0;
    }
    if(GetDistanceBetween(oMaster, oCandidate) > MA_PROPOSAL_DISTANCE)
    {
        SendMessageToPC(oMaster, "[Mentor] Stand closer to the candidate.");
        return 0;
    }
    if(MaCountActiveApprentices(GetObjectUUID(oMaster)) >= MA_MAX_APPRENTICES)
    {
        SendMessageToPC(oMaster, "[Mentor] You already mentor the maximum number of apprentices.");
        return 0;
    }
    if(MaHasMaster(GetObjectUUID(oCandidate)))
    {
        SendMessageToPC(oMaster, "[Mentor] " + GetName(oCandidate) + " is already bound to a master.");
        return 0;
    }
    if(GetHitDice(oCandidate) >= GetHitDice(oMaster))
    {
        SendMessageToPC(oMaster, "[Mentor] Master must be of higher level than apprentice.");
        return 0;
    }

    SetLocalString(oCandidate, MA_LVAR_PROPOSAL_FROM, GetObjectUUID(oMaster));
    SetLocalString(oCandidate, MA_LVAR_PROPOSAL_NAME, GetName(oMaster));
    MaShowProposal(oCandidate, GetObjectUUID(oMaster), GetName(oMaster));
    SendMessageToPC(oMaster, "[Mentor] Offer extended to " + GetName(oCandidate) + ".");
    return 1;
}

void MaAcceptProposal(object oApprentice)
{
    string sMasterUuid = GetLocalString(oApprentice, MA_LVAR_PROPOSAL_FROM);
    if(sMasterUuid == "") return;

    object oMaster = MaGetPCByUUID(sMasterUuid);
    if(!GetIsObjectValid(oMaster))
    {
        SendMessageToPC(oApprentice, "[Mentor] The master is no longer here.");
        DeleteLocalString(oApprentice, MA_LVAR_PROPOSAL_FROM);
        DeleteLocalString(oApprentice, MA_LVAR_PROPOSAL_NAME);
        return;
    }
    // Re-validate (state could have changed during the popup).
    if(MaCountActiveApprentices(sMasterUuid) >= MA_MAX_APPRENTICES
       || MaHasMaster(GetObjectUUID(oApprentice)))
    {
        SendMessageToPC(oApprentice, "[Mentor] The bond can no longer be formed.");
        return;
    }

    int nId = MaCreateBond(oMaster, oApprentice);
    if(nId <= 0) return;

    DeleteLocalString(oApprentice, MA_LVAR_PROPOSAL_FROM);
    DeleteLocalString(oApprentice, MA_LVAR_PROPOSAL_NAME);

    FloatingTextStringOnCreature(GetName(oMaster) + " takes "
        + GetName(oApprentice) + " as apprentice.", oMaster, FALSE);
    FloatingTextStringOnCreature(GetName(oApprentice) + " accepts "
        + GetName(oMaster) + " as master.", oApprentice, FALSE);
    SendMessageToPC(oMaster,     "[Mentor] " + GetName(oApprentice) + " is now your apprentice.");
    SendMessageToPC(oApprentice, "[Mentor] " + GetName(oMaster)     + " is now your master.");

    MaApplyApprenticeBonuses(oApprentice);

    int nMTk = NuiFindWindow(oMaster, MA_WINDOW);
    if(nMTk != 0) FeedMaWindow(oMaster, nMTk);
    int nATk = NuiFindWindow(oApprentice, MA_WINDOW);
    if(nATk != 0) FeedMaWindow(oApprentice, nATk);
}

void MaDeclineProposal(object oApprentice)
{
    string sMasterUuid = GetLocalString(oApprentice, MA_LVAR_PROPOSAL_FROM);
    string sMasterName = GetLocalString(oApprentice, MA_LVAR_PROPOSAL_NAME);
    DeleteLocalString(oApprentice, MA_LVAR_PROPOSAL_FROM);
    DeleteLocalString(oApprentice, MA_LVAR_PROPOSAL_NAME);
    object oMaster = MaGetPCByUUID(sMasterUuid);
    if(GetIsObjectValid(oMaster))
        SendMessageToPC(oMaster, "[Mentor] " + GetName(oApprentice)
            + " refuses your offer.");
    SendMessageToPC(oApprentice, "[Mentor] You declined " + sMasterName + "'s offer.");
}

void MaDismissApprentice(object oMaster, int nBondId, string sReason)
{
    MaBreakBond(nBondId, sReason);

    SendMessageToPC(oMaster, "[Mentor] Bond dissolved.");

    // If apprentice is online, clean up bonuses.
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(MaGetActiveBondIdForApprentice(GetObjectUUID(oPC)) == 0)
            MaRemoveApprenticeBonuses(oPC);
        oPC = GetNextPC();
    }

    int nTk = NuiFindWindow(oMaster, MA_WINDOW);
    if(nTk != 0) FeedMaWindow(oMaster, nTk);
}

void MaLeaveMaster(object oApprentice)
{
    string sMasterUuid = MaGetMasterUuid(GetObjectUUID(oApprentice));
    if(sMasterUuid == "") return;

    MaBreakBondByApprentice(GetObjectUUID(oApprentice), "Apprentice left the bond.");
    MaRemoveApprenticeBonuses(oApprentice);

    object oMaster = MaGetPCByUUID(sMasterUuid);
    if(GetIsObjectValid(oMaster))
    {
        SendMessageToPC(oMaster, "[Mentor] " + GetName(oApprentice)
            + " has left the bond.");
        int nMTk = NuiFindWindow(oMaster, MA_WINDOW);
        if(nMTk != 0) FeedMaWindow(oMaster, nMTk);
    }
    SendMessageToPC(oApprentice, "[Mentor] You walk your own path now.");

    int nATk = NuiFindWindow(oApprentice, MA_WINDOW);
    if(nATk != 0) FeedMaWindow(oApprentice, nATk);
}

// ----------------------------------------------------------------
// Level-up XP transfer (called from sys_on_levelup)
// ----------------------------------------------------------------

void MaOnApprenticeLevelUp(object oApprentice, int nNewLevel)
{
    int nBondId = MaGetActiveBondIdForApprentice(GetObjectUUID(oApprentice));
    if(nBondId <= 0) return;

    string sMasterUuid = MaGetMasterUuid(GetObjectUUID(oApprentice));
    object oMaster = MaGetPCByUUID(sMasterUuid);
    if(!GetIsObjectValid(oMaster)) return;

    // Reaching the master's level breaks the bond automatically.
    if(nNewLevel >= GetHitDice(oMaster))
    {
        MaBreakBond(nBondId, "Apprentice reached master's level.");
        MaRemoveApprenticeBonuses(oApprentice);
        SendMessageToPC(oMaster,
            "[Mentor] Apprentice " + GetName(oApprentice) + " has matched your level. The bond is dissolved.");
        SendMessageToPC(oApprentice,
            "[Mentor] You have matched your master's level. The bond is dissolved.");
        return;
    }

    int nXpGain = MA_MASTER_XP_PER_LEVEL * nNewLevel;
    GiveXPToCreature(oMaster, nXpGain);
    MaAddSharedXp(nBondId, nXpGain);
    SendMessageToPC(oMaster,
        "[Mentor] " + GetName(oApprentice) + " advanced to level "
        + IntToString(nNewLevel) + ". You receive " + IntToString(nXpGain) + " XP.");
}

// ----------------------------------------------------------------
// UI
// ----------------------------------------------------------------

json BuildMaRowCell(object oPC)
{
    float fH = GetNuiScaleDimension(oPC, 26.0);
    json jName = NuiLabel(NuiBind(MA_BIND_ROW_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiStyleForegroundColor(jName, NuiBind(MA_BIND_ROW_COLOR));

    json jInfo = NuiLabel(NuiBind(MA_BIND_ROW_INFO),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jInfo = NuiWidth(jInfo, GetNuiScaleDimension(oPC, 220.0));
    jInfo = NuiStyleForegroundColor(jInfo, NuiBind(MA_BIND_ROW_COLOR));

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jName);
    jRow = JsonArrayInsert(jRow, jInfo);
    json jCell = NuiGroup(NuiRow(jRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, MA_BTN_ROW);
    jCell = NuiHeight(jCell, fH);
    return jCell;
}

void CreateMaWindow(object oPC)
{
    int nExisting = NuiFindWindow(oPC, MA_WINDOW);
    if(nExisting != 0) { FeedMaWindow(oPC, nExisting); return; }

    float fW = GetNuiScaleDimension(oPC, MA_W);
    float fH = GetNuiScaleDimension(oPC, MA_H);
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fLblH = GetNuiScaleDimension(oPC, 22.0);

    json jTitle = NuiLabel(NuiBind(MA_BIND_TITLE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);
    json jClose = NuiId(NuiButton(JsonString("Close")), MA_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 90.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitle);
    jTopRow = JsonArrayInsert(jTopRow, jClose);

    json jMaster = NuiLabel(NuiBind(MA_BIND_MASTER_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jMaster = NuiStyleForegroundColor(jMaster, GetNuiColorNwnGold());
    jMaster = NuiHeight(jMaster, fLblH);

    json jBonus = NuiLabel(NuiBind(MA_BIND_BONUS_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBonus = NuiHeight(jBonus, fLblH);

    json jLeave = NuiId(NuiButton(JsonString("Leave master")), MA_BTN_LEAVE);
    jLeave = NuiVisible(jLeave, NuiBind(MA_BIND_LEAVE_VIS));
    jLeave = NuiHeight(jLeave, fBtnH);

    json jSection = NuiLabel(NuiBind(MA_BIND_SECTION_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSection = NuiStyleForegroundColor(jSection, GetNuiColorNwnGold());
    jSection = NuiHeight(jSection, fLblH);

    json jTake = NuiId(NuiButton(JsonString("Take apprentice (select target)")), MA_BTN_TAKE_APPRENTICE);
    jTake = NuiEnabled(jTake, NuiBind(MA_BIND_TAKE_ENA));
    jTake = NuiHeight(jTake, fBtnH);

    json jEmpty = NuiLabel(NuiBind(MA_BIND_EMPTY_TXT),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jEmpty = NuiVisible(jEmpty, NuiBind(MA_BIND_EMPTY_VIS));
    jEmpty = NuiHeight(jEmpty, GetNuiScaleDimension(oPC, 50.0));

    json jList = NuiList(JsonArrayInsert(JsonArray(), BuildMaRowCell(oPC)),
        GetNuiScaleDimension(oPC, 28.0));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTopRow));
    jCol = JsonArrayInsert(jCol, jMaster);
    jCol = JsonArrayInsert(jCol, jBonus);
    jCol = JsonArrayInsert(jCol, jLeave);
    jCol = JsonArrayInsert(jCol, jSection);
    jCol = JsonArrayInsert(jCol, jTake);
    jCol = JsonArrayInsert(jCol, jEmpty);
    jCol = JsonArrayInsert(jCol, jList);

    json jRoot = NuiCol(jCol);

    json jNui = NuiWindow(jRoot,
        NuiBind(WINDOW_TITLE), NuiBind(WINDOW_GEOMETRY),
        JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE), JsonBool(TRUE));

    int nTk = NuiCreate(oPC, jNui, MA_WINDOW, MA_EV_SCRIPT);
    NuiSetBind(oPC, nTk, WINDOW_TITLE, JsonString("Master & Apprentice"));
    NuiSetBind(oPC, nTk, WINDOW_GEOMETRY, NuiRect(-1.0, -1.0, fW, fH));
    NuiSetBind(oPC, nTk, MA_BIND_TITLE,   JsonString("Bonds of Mentorship"));

    FeedMaWindow(oPC, nTk);
}

void FeedMaWindow(object oPC, int nToken)
{
    string sUuid = GetObjectUUID(oPC);

    // -- "I am apprentice" section --
    int nHasMaster = MaHasMaster(sUuid);
    if(nHasMaster)
    {
        string sMasterName = MaGetMasterName(sUuid);
        NuiSetBind(oPC, nToken, MA_BIND_MASTER_LBL,
            JsonString("Your master: " + sMasterName));

        // Count bonus skills currently active.
        int nBonusCount = 0;
        effect e = GetFirstEffect(oPC);
        while(GetIsEffectValid(e))
        {
            if(GetEffectTag(e) == MA_EFFECT_TAG) nBonusCount++;
            e = GetNextEffect(oPC);
        }
        NuiSetBind(oPC, nToken, MA_BIND_BONUS_LBL,
            JsonString("Skill bonuses inherited: " + IntToString(nBonusCount)));
        NuiSetBind(oPC, nToken, MA_BIND_LEAVE_VIS, JsonBool(TRUE));
    }
    else
    {
        NuiSetBind(oPC, nToken, MA_BIND_MASTER_LBL, JsonString("You have no master."));
        NuiSetBind(oPC, nToken, MA_BIND_BONUS_LBL,  JsonString(""));
        NuiSetBind(oPC, nToken, MA_BIND_LEAVE_VIS,  JsonBool(FALSE));
    }

    // -- "I am master" section --
    int nApprenticeCount = MaCountActiveApprentices(sUuid);
    NuiSetBind(oPC, nToken, MA_BIND_SECTION_LBL,
        JsonString("Your apprentices (" + IntToString(nApprenticeCount)
        + "/" + IntToString(MA_MAX_APPRENTICES) + ")"));
    NuiSetBind(oPC, nToken, MA_BIND_TAKE_ENA,
        JsonBool(nApprenticeCount < MA_MAX_APPRENTICES));

    json jApps = MaGetApprentices(sUuid);
    int nCnt = JsonGetLength(jApps);

    json jNames = JsonArray();
    json jInfos = JsonArray();
    json jColors = JsonArray();
    int i;
    for(i = 0; i < nCnt; i++)
    {
        json jR = JsonArrayGet(jApps, i);
        string sName = JsonGetString(JsonObjectGet(jR, "name"));
        int nXp = JsonGetInt(JsonObjectGet(jR, "xp_shared_total"));
        jNames  = JsonArrayInsert(jNames,  JsonString(sName));
        jInfos  = JsonArrayInsert(jInfos,  JsonString("Shared XP: "
            + IntToString(nXp) + " (click to dismiss)"));
        jColors = JsonArrayInsert(jColors, NuiColor(220, 200, 120));
    }
    NuiSetBind(oPC, nToken, MA_BIND_ROW_NAME,  jNames);
    NuiSetBind(oPC, nToken, MA_BIND_ROW_INFO,  jInfos);
    NuiSetBind(oPC, nToken, MA_BIND_ROW_COLOR, jColors);

    NuiSetBind(oPC, nToken, MA_BIND_EMPTY_VIS, JsonBool(nCnt == 0));
    NuiSetBind(oPC, nToken, MA_BIND_EMPTY_TXT,
        JsonString("No apprentices. Stand near a candidate and offer the bond."));
}

// ----------------------------------------------------------------
// Proposal popup (target sees this)
// ----------------------------------------------------------------

void MaShowProposal(object oPC, string sFromUuid, string sFromName)
{
    int nExisting = NuiFindWindow(oPC, MA_WIN_PROPOSAL);
    if(nExisting != 0) NuiDestroy(oPC, nExisting);

    float fW = GetNuiScaleDimension(oPC, MA_PROP_W);
    float fH = GetNuiScaleDimension(oPC, MA_PROP_H);
    float fLblH = GetNuiScaleDimension(oPC, 24.0);
    float fBtnH = GetNuiScaleDimension(oPC, 32.0);

    json jTitle = NuiLabel(NuiBind(MA_BIND_PROP_TITLE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fLblH);
    json jDetail = NuiLabel(NuiBind(MA_BIND_PROP_DETAIL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDetail = NuiHeight(jDetail, fLblH);

    json jAccept  = NuiHeight(NuiId(NuiButton(JsonString("Accept")),  MA_BTN_PROP_ACCEPT),  fBtnH);
    json jDecline = NuiHeight(NuiId(NuiButton(JsonString("Decline")), MA_BTN_PROP_DECLINE), fBtnH);
    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jAccept);
    jBtnRow = JsonArrayInsert(jBtnRow, jDecline);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jTitle);
    jCol = JsonArrayInsert(jCol, jDetail);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jNui = NuiWindow(NuiCol(jCol),
        JsonString("Master's Offer"),
        NuiRect(-1.0, -1.0, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE), JsonBool(TRUE));
    int nTk = NuiCreate(oPC, jNui, MA_WIN_PROPOSAL, MA_EV_SCRIPT);

    NuiSetBind(oPC, nTk, MA_BIND_PROP_TITLE,
        JsonString(sFromName + " offers to take you as apprentice."));
    NuiSetBind(oPC, nTk, MA_BIND_PROP_DETAIL,
        JsonString("Bond grants +" + IntToString(MA_SKILL_BONUS)
            + " to skills your master excels at; "
            + "your level-ups feed XP back to your master."));
}

// ----------------------------------------------------------------
// Targeting helper (called from sys_on_target)
// ----------------------------------------------------------------

void MaStartTakeApprentice(object oMaster)
{
    if(MaCountActiveApprentices(GetObjectUUID(oMaster)) >= MA_MAX_APPRENTICES)
    {
        SendMessageToPC(oMaster, "[Mentor] Already at apprentice limit.");
        return;
    }
    SendMessageToPC(oMaster, "[Mentor] Select a player to apprentice.");
    EnterTargetingMode(oMaster, OBJECT_TYPE_CREATURE);
}

void MaOnPlayerTarget(object oMaster)
{
    object oCandidate = GetTargetingModeSelectedObject();
    if(!GetIsObjectValid(oCandidate))
    {
        SendMessageToPC(oMaster, "[Mentor] Selection canceled.");
        return;
    }
    MaProposeApprenticeship(oMaster, oCandidate);
}

#include "lib_pr_def"

void FeedPrWindow(object oPC, int nToken);
void PrShowDeitySelector(object oPC);

// ----------------------------------------------------------------
// Cooldown helpers
// ----------------------------------------------------------------

int PrCooldownRemaining(object oPC, int nMiracle)
{
    int nReady = GetLocalInt(oPC, PR_LVAR_CD_PREFIX + IntToString(nMiracle));
    int nNow   = PrGetNowSeconds();
    if(nNow >= nReady) return 0;
    return nReady - nNow;
}

void PrSetCooldown(object oPC, int nMiracle)
{
    int nNow = PrGetNowSeconds();
    SetLocalInt(oPC, PR_LVAR_CD_PREFIX + IntToString(nMiracle),
                nNow + PrMiracleCooldownS(nMiracle));
}

string PrFormatCooldown(int nSecs)
{
    if(nSecs <= 0) return "";
    int nMin = nSecs / 60;
    int nSec = nSecs % 60;
    if(nMin > 0) return IntToString(nMin) + "m " + IntToString(nSec) + "s";
    return IntToString(nSec) + "s";
}

// ----------------------------------------------------------------
// Pray
// ----------------------------------------------------------------

void PrPray(object oPC)
{
    string sUuid = GetObjectUUID(oPC);
    if(PrGetDeity(sUuid) == PR_DEITY_NONE)
    {
        SendMessageToPC(oPC, "[Prayer] Choose a deity before you pray.");
        return;
    }

    int nNow  = PrGetNowSeconds();
    int nLast = PrGetLastPrayedAt(sUuid);
    if(nLast > 0 && nNow - nLast < PR_PRAY_COOLDOWN_S)
    {
        int nLeft = PR_PRAY_COOLDOWN_S - (nNow - nLast);
        SendMessageToPC(oPC, "[Prayer] Your prayer is too fresh. Wait "
            + PrFormatCooldown(nLeft) + ".");
        return;
    }

    PrAdjustFavor(sUuid, PR_PRAY_FAVOR_GAIN, PR_FAVOR_MIN, PR_FAVOR_MAX);
    PrMarkPrayed(sUuid);

    int nDeity = PrGetDeity(sUuid);
    string sName = PrDeityName(nDeity);
    FloatingTextStringOnCreature("You whisper a prayer to " + sName + ".",
        oPC, FALSE);
    SendMessageToPC(oPC, "[Prayer] Favor with " + sName + " grows by "
        + IntToString(PR_PRAY_FAVOR_GAIN) + ".");

    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_DIVINE_STRIKE_HOLY), oPC);

    int nTk = NuiFindWindow(oPC, PR_WINDOW);
    if(nTk != 0) FeedPrWindow(oPC, nTk);
}

// ----------------------------------------------------------------
// Miracle effects
// ----------------------------------------------------------------

void PrApplyHeal(object oPC)
{
    effect eHeal = EffectHeal(25);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, eHeal, oPC);
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_HEALING_M), oPC);
}

void PrApplyBless(object oPC)
{
    location lLoc = GetLocation(oPC);
    object oTarget = GetFirstObjectInShape(SHAPE_SPHERE, 10.0, lLoc);
    while(GetIsObjectValid(oTarget))
    {
        if(GetIsPC(oTarget) && !GetIsEnemy(oTarget, oPC))
        {
            effect eAtk = EffectAttackIncrease(2);
            effect eSav = EffectSavingThrowIncrease(SAVING_THROW_ALL, 2);
            effect eLink = EffectLinkEffects(eAtk, eSav);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eLink, oTarget, 60.0);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_IMP_HEAD_HOLY), oTarget);
        }
        oTarget = GetNextObjectInShape(SHAPE_SPHERE, 10.0, lLoc);
    }
}

void PrApplySmite(object oPC, object oEnemy)
{
    if(!GetIsObjectValid(oEnemy) || oEnemy == oPC) return;
    int nDmg = d6(3);
    effect eDmg = EffectDamage(nDmg, DAMAGE_TYPE_DIVINE);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, eDmg, oEnemy);
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_DIVINE_STRIKE_HOLY), oEnemy);
    SendMessageToPC(oPC, "[Prayer] Smite strikes for " + IntToString(nDmg) + ".");
}

void PrApplySanctuary(object oPC)
{
    effect eSanc = EffectSanctuary(20);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eSanc, oPC, 18.0);
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_SANCTUARY), oPC);
}

void PrApplyRaise(object oPC, object oTarget)
{
    if(!GetIsObjectValid(oTarget) || !GetIsPC(oTarget) || !GetIsDead(oTarget))
    {
        SendMessageToPC(oPC, "[Prayer] Target must be a slain ally.");
        return;
    }
    effect eRaise = EffectResurrection();
    ApplyEffectToObject(DURATION_TYPE_INSTANT, eRaise, oTarget);
    int nQuarter = GetMaxHitPoints(oTarget) / 4;
    if(nQuarter < 1) nQuarter = 1;
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(nQuarter), oTarget);
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_RAISE_DEAD), oTarget);
}

// ----------------------------------------------------------------
// Cast a miracle (validation + effect application)
// ----------------------------------------------------------------

int PrTryCastMiracle(object oPC, int nMiracle, object oTarget)
{
    string sUuid = GetObjectUUID(oPC);
    int nDeity   = PrGetDeity(sUuid);
    if(nDeity == PR_DEITY_NONE)
    {
        SendMessageToPC(oPC, "[Prayer] You serve no deity.");
        return FALSE;
    }
    int nFavor = PrGetFavor(sUuid);
    if(nFavor < PrMiracleFavorReq(nMiracle))
    {
        SendMessageToPC(oPC, "[Prayer] Insufficient favor for "
            + PrMiracleName(nMiracle) + " (need "
            + IntToString(PrMiracleFavorReq(nMiracle)) + ").");
        return FALSE;
    }
    int nCd = PrCooldownRemaining(oPC, nMiracle);
    if(nCd > 0)
    {
        SendMessageToPC(oPC, "[Prayer] " + PrMiracleName(nMiracle)
            + " is on cooldown (" + PrFormatCooldown(nCd) + ").");
        return FALSE;
    }

    switch(nMiracle)
    {
        case PR_MIRACLE_HEAL:      PrApplyHeal(oPC);                 break;
        case PR_MIRACLE_BLESS:     PrApplyBless(oPC);                break;
        case PR_MIRACLE_SMITE:     PrApplySmite(oPC, oTarget);       break;
        case PR_MIRACLE_SANCTUARY: PrApplySanctuary(oPC);            break;
        case PR_MIRACLE_RAISE:     PrApplyRaise(oPC, oTarget);       break;
        default: return FALSE;
    }

    PrAdjustFavor(sUuid, -PrMiracleFavorCost(nMiracle), PR_FAVOR_MIN, PR_FAVOR_MAX);
    PrSetCooldown(oPC, nMiracle);
    PrIncMiraclesCast(sUuid);

    SendMessageToPC(oPC, "[Prayer] " + PrMiracleName(nMiracle) + " invoked.");

    int nTk = NuiFindWindow(oPC, PR_WINDOW);
    if(nTk != 0) FeedPrWindow(oPC, nTk);
    return TRUE;
}

void PrStartMiracleTargeting(object oPC, int nMiracle)
{
    SetLocalInt(oPC, PR_LVAR_PENDING_TARGET, nMiracle + 1);  // +1 so 0 means "none"
    SendMessageToPC(oPC, "[Prayer] Select a target for "
        + PrMiracleName(nMiracle) + ".");
    EnterTargetingMode(oPC, OBJECT_TYPE_CREATURE);
}

void PrOnPlayerTarget(object oPC)
{
    int nMir = GetLocalInt(oPC, PR_LVAR_PENDING_TARGET) - 1;
    DeleteLocalInt(oPC, PR_LVAR_PENDING_TARGET);
    if(nMir < 0) return;

    object oTarget = GetTargetingModeSelectedObject();
    if(!GetIsObjectValid(oTarget))
    {
        SendMessageToPC(oPC, "[Prayer] Targeting canceled.");
        return;
    }
    PrTryCastMiracle(oPC, nMir, oTarget);
}

// ----------------------------------------------------------------
// UI — main window
// ----------------------------------------------------------------

json BuildPrMiracleRow(object oPC)
{
    float fH = GetNuiScaleDimension(oPC, 32.0);

    json jName = NuiLabel(NuiBind(PR_BIND_MIR_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiWidth(jName, GetNuiScaleDimension(oPC, 160.0));
    jName = NuiStyleForegroundColor(jName, NuiBind(PR_BIND_MIR_COLOR));

    json jDesc = NuiLabel(NuiBind(PR_BIND_MIR_DESC),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDesc = NuiStyleForegroundColor(jDesc, NuiBind(PR_BIND_MIR_COLOR));

    json jBtn = NuiButton(NuiBind(PR_BIND_MIR_BTN));
    jBtn = NuiId(jBtn, PR_BTN_MIRACLE);
    jBtn = NuiEnabled(jBtn, NuiBind(PR_BIND_MIR_BTN_ENA));
    jBtn = NuiWidth(jBtn, GetNuiScaleDimension(oPC, 110.0));

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jName);
    jRow = JsonArrayInsert(jRow, jDesc);
    jRow = JsonArrayInsert(jRow, jBtn);
    json jCell = NuiGroup(NuiRow(jRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiHeight(jCell, fH);
    return jCell;
}

void CreatePrWindow(object oPC)
{
    int nExisting = NuiFindWindow(oPC, PR_WINDOW);
    if(nExisting != 0) { FeedPrWindow(oPC, nExisting); return; }

    PrEnsureRow(oPC);

    float fW = GetNuiScaleDimension(oPC, PR_W);
    float fH = GetNuiScaleDimension(oPC, PR_H);
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fLblH = GetNuiScaleDimension(oPC, 22.0);

    json jTitle = NuiLabel(NuiBind(PR_BIND_TITLE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);
    json jClose = NuiId(NuiButton(JsonString("Close")), PR_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 90.0));
    jClose = NuiHeight(jClose, fBtnH);
    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitle);
    jTopRow = JsonArrayInsert(jTopRow, jClose);

    json jDeity = NuiLabel(NuiBind(PR_BIND_DEITY_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDeity = NuiStyleForegroundColor(jDeity, GetNuiColorNwnGold());
    jDeity = NuiHeight(jDeity, fLblH);

    json jFavor = NuiLabel(NuiBind(PR_BIND_FAVOR_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jFavor = NuiHeight(jFavor, fLblH);

    json jRank = NuiLabel(NuiBind(PR_BIND_RANK_LBL),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jRank = NuiHeight(jRank, fLblH);

    json jStatRow = JsonArray();
    jStatRow = JsonArrayInsert(jStatRow, jFavor);
    jStatRow = JsonArrayInsert(jStatRow, jRank);

    json jPray = NuiId(NuiButton(JsonString("Pray (gain favor)")), PR_BTN_PRAY);
    jPray = NuiEnabled(jPray, NuiBind(PR_BIND_PRAY_ENA));
    jPray = NuiTooltip(jPray, NuiBind(PR_BIND_PRAY_TIP));
    jPray = NuiHeight(jPray, fBtnH);

    json jChange = NuiId(NuiButton(JsonString("Choose / change deity")), PR_BTN_CHANGE_DEITY);
    jChange = NuiHeight(jChange, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jPray);
    jBtnRow = JsonArrayInsert(jBtnRow, jChange);

    json jList = NuiList(JsonArrayInsert(JsonArray(), BuildPrMiracleRow(oPC)),
        GetNuiScaleDimension(oPC, 36.0));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTopRow));
    jCol = JsonArrayInsert(jCol, jDeity);
    jCol = JsonArrayInsert(jCol, NuiRow(jStatRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));
    jCol = JsonArrayInsert(jCol, jList);

    json jNui = NuiWindow(NuiCol(jCol),
        NuiBind(WINDOW_TITLE), NuiBind(WINDOW_GEOMETRY),
        JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE), JsonBool(TRUE));

    int nTk = NuiCreate(oPC, jNui, PR_WINDOW, PR_EV_SCRIPT);
    NuiSetBind(oPC, nTk, WINDOW_TITLE, JsonString("Prayer & Miracles"));
    NuiSetBind(oPC, nTk, WINDOW_GEOMETRY, NuiRect(-1.0, -1.0, fW, fH));
    NuiSetBind(oPC, nTk, PR_BIND_TITLE, JsonString("Altar of Devotion"));

    FeedPrWindow(oPC, nTk);
}

void FeedPrWindow(object oPC, int nToken)
{
    string sUuid = GetObjectUUID(oPC);
    int nDeity = PrGetDeity(sUuid);
    int nFavor = PrGetFavor(sUuid);

    if(nDeity == PR_DEITY_NONE)
    {
        NuiSetBind(oPC, nToken, PR_BIND_DEITY_LBL,
            JsonString("Devoted to: nobody yet"));
    }
    else
    {
        NuiSetBind(oPC, nToken, PR_BIND_DEITY_LBL,
            JsonString("Devoted to: " + PrDeityName(nDeity)
                + " — " + PrDeityDomain(nDeity)));
    }

    NuiSetBind(oPC, nToken, PR_BIND_FAVOR_LBL,
        JsonString("Favor: " + IntToString(nFavor)));
    NuiSetBind(oPC, nToken, PR_BIND_RANK_LBL,
        JsonString(PrFavorRank(nFavor)));

    int nNow = PrGetNowSeconds();
    int nLast = PrGetLastPrayedAt(sUuid);
    int nWait = (nLast == 0) ? 0
        : (nNow - nLast >= PR_PRAY_COOLDOWN_S ? 0 : PR_PRAY_COOLDOWN_S - (nNow - nLast));
    int bCanPray = (nDeity != PR_DEITY_NONE) && (nWait == 0);
    NuiSetBind(oPC, nToken, PR_BIND_PRAY_ENA, JsonBool(bCanPray));
    NuiSetBind(oPC, nToken, PR_BIND_PRAY_TIP,
        JsonString(nWait > 0
            ? "Available in " + PrFormatCooldown(nWait)
            : "Speak the words and gain " + IntToString(PR_PRAY_FAVOR_GAIN) + " favor."));

    json jName = JsonArray();
    json jDesc = JsonArray();
    json jBtn  = JsonArray();
    json jEna  = JsonArray();
    json jColor= JsonArray();

    int i;
    for(i = 0; i < PR_MIRACLE_COUNT; i++)
    {
        int nReq  = PrMiracleFavorReq(i);
        int nCost = PrMiracleFavorCost(i);
        int nCd   = PrCooldownRemaining(oPC, i);
        int bUnlocked = (nFavor >= nReq) && (nDeity != PR_DEITY_NONE);
        int bReady    = bUnlocked && (nCd == 0);

        jName = JsonArrayInsert(jName, JsonString(PrMiracleName(i)));
        jDesc = JsonArrayInsert(jDesc,
            JsonString(PrMiracleDescription(i) + " [need " + IntToString(nReq)
                + ", -" + IntToString(nCost) + " favor]"));

        string sBtn;
        if(!bUnlocked)      sBtn = "Locked";
        else if(nCd > 0)    sBtn = PrFormatCooldown(nCd);
        else                sBtn = "Invoke";
        jBtn  = JsonArrayInsert(jBtn,  JsonString(sBtn));
        jEna  = JsonArrayInsert(jEna,  JsonBool(bReady));
        jColor= JsonArrayInsert(jColor,
            bUnlocked ? NuiColor(220, 200, 120) : NuiColor(140, 140, 140));
    }
    NuiSetBind(oPC, nToken, PR_BIND_MIR_NAME,    jName);
    NuiSetBind(oPC, nToken, PR_BIND_MIR_DESC,    jDesc);
    NuiSetBind(oPC, nToken, PR_BIND_MIR_BTN,     jBtn);
    NuiSetBind(oPC, nToken, PR_BIND_MIR_BTN_ENA, jEna);
    NuiSetBind(oPC, nToken, PR_BIND_MIR_COLOR,   jColor);
}

// ----------------------------------------------------------------
// Deity selector popup
// ----------------------------------------------------------------

void PrShowDeitySelector(object oPC)
{
    int nExisting = NuiFindWindow(oPC, PR_WIN_DEITY);
    if(nExisting != 0) NuiDestroy(oPC, nExisting);

    float fW = GetNuiScaleDimension(oPC, PR_DEITY_W);
    float fH = GetNuiScaleDimension(oPC, PR_DEITY_H);
    float fRowH = GetNuiScaleDimension(oPC, 28.0);

    json jLbl = NuiLabel(NuiBind(PR_BIND_DEITY_ROW_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLbl = NuiWidth(jLbl, GetNuiScaleDimension(oPC, 130.0));

    json jDesc = NuiLabel(NuiBind(PR_BIND_DEITY_ROW_DESC),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jRowCell = NuiGroup(NuiRow(JsonArrayInsert(JsonArrayInsert(JsonArray(),
        jLbl), jDesc)), TRUE, NUI_SCROLLBARS_NONE);
    jRowCell = NuiId(jRowCell, PR_BTN_DEITY_ROW);
    jRowCell = NuiHeight(jRowCell, fRowH);

    json jList = NuiList(JsonArrayInsert(JsonArray(), jRowCell), fRowH);

    json jHdr = NuiLabel(JsonString("Choose your deity (click a row):"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHdr = NuiHeight(jHdr, GetNuiScaleDimension(oPC, 24.0));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHdr);
    jCol = JsonArrayInsert(jCol, jList);

    json jNui = NuiWindow(NuiCol(jCol),
        JsonString("Pantheon"),
        NuiRect(-1.0, -1.0, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE), JsonBool(TRUE));
    int nTk = NuiCreate(oPC, jNui, PR_WIN_DEITY, PR_EV_SCRIPT);

    json jLabels = JsonArray();
    json jDescs  = JsonArray();
    int i;
    for(i = 0; i < PR_DEITY_COUNT; i++)
    {
        jLabels = JsonArrayInsert(jLabels, JsonString(PrDeityName(i)));
        jDescs  = JsonArrayInsert(jDescs,  JsonString(PrDeityDomain(i)));
    }
    NuiSetBind(oPC, nTk, PR_BIND_DEITY_ROW_LBL,  jLabels);
    NuiSetBind(oPC, nTk, PR_BIND_DEITY_ROW_DESC, jDescs);
}

void PrSelectDeity(object oPC, int nDeityId)
{
    if(nDeityId < 0 || nDeityId >= PR_DEITY_COUNT) return;
    string sUuid = GetObjectUUID(oPC);
    int nCurrent = PrGetDeity(sUuid);
    if(nCurrent == nDeityId)
    {
        SendMessageToPC(oPC, "[Prayer] You already serve " + PrDeityName(nDeityId) + ".");
        return;
    }
    if(nCurrent != PR_DEITY_NONE)
    {
        // Switching gods costs all favor and applies disfavor.
        PrAdjustFavor(sUuid, -PrGetFavor(sUuid) - 25, PR_FAVOR_MIN, PR_FAVOR_MAX);
        SendMessageToPC(oPC, "[Prayer] Forsaking " + PrDeityName(nCurrent)
            + " — favor lost, disfavor incurred.");
    }
    PrSetDeity(sUuid, nDeityId);
    SendMessageToPC(oPC, "[Prayer] You devote yourself to " + PrDeityName(nDeityId) + ".");

    int nMain = NuiFindWindow(oPC, PR_WINDOW);
    if(nMain != 0) FeedPrWindow(oPC, nMain);
    int nSel = NuiFindWindow(oPC, PR_WIN_DEITY);
    if(nSel != 0) NuiDestroy(oPC, nSel);
}

#include "lib_pan_def"

void FeedPanWindow(object oPC, int nToken);
void PanTickWindow(object oPC, int nToken);

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------

void PanFloat(object oPC, string sMsg)
{
    string sFull = "[Pantheon] " + sMsg;
    FloatingTextStringOnCreature(sFull, oPC, FALSE, FALSE);
    SendMessageToPC(oPC, sFull);
}

string PanFormatCooldown(int nSecs)
{
    if(nSecs <= 0) return "";
    int nMin = nSecs / 60;
    int nSec = nSecs % 60;
    if(nMin > 0) return IntToString(nMin) + "m " + IntToString(nSec) + "s";
    return IntToString(nSec) + "s";
}

int PanCooldownRemaining(object oPC, int nMir)
{
    int nReady = PanGetCooldownReadyAt(GetObjectUUID(oPC), nMir);
    int nNow   = PanGetNowSeconds();
    if(nNow >= nReady) return 0;
    return nReady - nNow;
}

void PanStartCooldown(object oPC, int nMir)
{
    int nCd = PanMiracleCooldownS(nMir);
    int nRank = PanGetRankId(PanGetFavor(GetObjectUUID(oPC)));
    if(nRank == PAN_RANK_CHOSEN)
    {
        nCd = (nCd * 3) / 4;  // -25% cooldown for Chosen
    }
    int nReady = PanGetNowSeconds() + nCd;
    PanSetCooldown(GetObjectUUID(oPC), nMir, nReady);
}

void PanAdjustFavor(string sUuid, int nDelta)
{
    int nFav = PanGetFavor(sUuid) + nDelta;
    if(nFav < PAN_FAVOR_MIN)      nFav = PAN_FAVOR_MIN;
    else if(nFav > PAN_FAVOR_MAX) nFav = PAN_FAVOR_MAX;
    PanSetFavor(sUuid, nFav);
}

// One-shot SQL fetch -> LVAR cache. Called on window open and after every
// state-changing action (pray, cast, deity change). Tick reads the cache.
void PanRefreshState(object oPC)
{
    string sUuid = GetObjectUUID(oPC);
    SetLocalInt(oPC, PAN_LVAR_LOAD_NOW,    PanGetNowSeconds());
    SetLocalInt(oPC, PAN_LVAR_TICK_OFFSET, 0);
    SetLocalInt(oPC, PAN_LVAR_DEITY,       PanGetDeity(sUuid));
    SetLocalInt(oPC, PAN_LVAR_FAVOR,       PanGetFavor(sUuid));
    SetLocalInt(oPC, PAN_LVAR_LAST_PRAYED, PanGetLastPrayedAt(sUuid));
    int i;
    for(i = 0; i < PAN_MIRACLE_COUNT; i++)
    {
        SetLocalInt(oPC, PAN_LVAR_CD_PREFIX + IntToString(i),
            PanGetCooldownReadyAt(sUuid, i));
    }
}

void PanClearState(object oPC)
{
    DeleteLocalInt(oPC, PAN_LVAR_LOAD_NOW);
    DeleteLocalInt(oPC, PAN_LVAR_TICK_OFFSET);
    DeleteLocalInt(oPC, PAN_LVAR_DEITY);
    DeleteLocalInt(oPC, PAN_LVAR_FAVOR);
    DeleteLocalInt(oPC, PAN_LVAR_LAST_PRAYED);
    int i;
    for(i = 0; i < PAN_MIRACLE_COUNT; i++)
    {
        DeleteLocalInt(oPC, PAN_LVAR_CD_PREFIX + IntToString(i));
    }
}

// ----------------------------------------------------------------
// Pray
// ----------------------------------------------------------------

void PanPray(object oPC)
{
    string sUuid = GetObjectUUID(oPC);
    int nDeity = PanGetDeity(sUuid);
    if(nDeity == PAN_DEITY_NONE)
    {
        PanFloat(oPC, "Choose a deity before you pray.");
        return;
    }

    int nNow  = PanGetNowSeconds();
    int nLast = PanGetLastPrayedAt(sUuid);
    if(nLast > 0 && nNow - nLast < PAN_PRAY_COOLDOWN_S)
    {
        int nLeft = PAN_PRAY_COOLDOWN_S - (nNow - nLast);
        PanFloat(oPC, "Your prayer is too fresh. Wait " + PanFormatCooldown(nLeft) + ".");
        return;
    }

    int nRank = PanGetRankId(PanGetFavor(sUuid));
    int nGain = PanGetPrayGain(nRank);

    PanAdjustFavor(sUuid, nGain);
    PanMarkPrayed(sUuid);

    PanFloat(oPC, "You whisper a prayer to " + PanDeityName(nDeity)
        + ". (+" + IntToString(nGain) + " favor)");
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_HEAD_HOLY), oPC);

    int nTk = NuiFindWindow(oPC, PAN_WINDOW);
    if(nTk != 0)
    {
        PanRefreshState(oPC);
        FeedPanWindow(oPC, nTk);
    }
}

// ----------------------------------------------------------------
// Miracle effects
// ----------------------------------------------------------------

void PanApplyHeal(object oPC)
{
    int nRank = PanGetRankId(PanGetFavor(GetObjectUUID(oPC)));
    int nPercent = (nRank >= PAN_RANK_BLESSED) ? 35 : 25;
    int nHeal = (GetMaxHitPoints(oPC) * nPercent) / 100;
    if(nHeal < 1) nHeal = 1;
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(nHeal), oPC);
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_HEALING_M), oPC);
    PanFloat(oPC, "Heal Wounds restores " + IntToString(nHeal) + " HP.");
}

void PanApplyBless(object oPC)
{
    int   nRank = PanGetRankId(PanGetFavor(GetObjectUUID(oPC)));
    float fDur  = 60.0;
    if(nRank == PAN_RANK_DEVOTED)        fDur = 75.0;
    else if(nRank >= PAN_RANK_BLESSED)   fDur = 90.0;

    object oArea  = GetArea(oPC);
    int    nCount = 0;
    object oMember = GetFirstFactionMember(oPC, TRUE);
    while(GetIsObjectValid(oMember))
    {
        if(GetArea(oMember) == oArea && GetDistanceBetween(oPC, oMember) <= 10.0)
        {
            effect eAtk  = EffectAttackIncrease(2);
            effect eSav  = EffectSavingThrowIncrease(SAVING_THROW_ALL, 2);
            effect eLink = EffectLinkEffects(eAtk, eSav);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eLink, oMember, fDur);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_IMP_HEAD_HOLY), oMember);
            nCount++;
        }
        oMember = GetNextFactionMember(oPC, TRUE);
    }
    PanFloat(oPC, "Bless applied to " + IntToString(nCount) + " companion(s) for "
        + IntToString(FloatToInt(fDur)) + "s.");
}

void PanApplySmite(object oPC, object oTarget)
{
    int    nRank = PanGetRankId(PanGetFavor(GetObjectUUID(oPC)));
    int    nDice = (nRank >= PAN_RANK_BLESSED) ? 4 : 3;
    int    nDmg  = d6(nDice);
    effect eDmg  = EffectDamage(nDmg, DAMAGE_TYPE_DIVINE);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, eDmg, oTarget);
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_DIVINE_STRIKE_HOLY), oTarget);
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_COM_HIT_DIVINE), oTarget);
    PanFloat(oPC, "Divine Smite strikes " + GetName(oTarget)
        + " for " + IntToString(nDmg) + " divine damage.");
}

void PanApplySanctuary(object oPC)
{
    int   nRank = PanGetRankId(PanGetFavor(GetObjectUUID(oPC)));
    float fDur  = 18.0;
    if(nRank == PAN_RANK_DEVOTED)        fDur = 22.0;
    else if(nRank >= PAN_RANK_BLESSED)   fDur = 28.0;

    effect eSanc = EffectSanctuary(20);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eSanc, oPC, fDur);
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_HEAD_HOLY), oPC);
    PanFloat(oPC, "Sanctuary surrounds you for "
        + IntToString(FloatToInt(fDur)) + " seconds.");
}

// ----------------------------------------------------------------
// Cast a miracle (validation + effect)
// ----------------------------------------------------------------

int PanTryCastMiracle(object oPC, int nMir, object oTarget)
{
    string sUuid = GetObjectUUID(oPC);
    int nDeity = PanGetDeity(sUuid);
    if(nDeity == PAN_DEITY_NONE)
    {
        PanFloat(oPC, "You serve no deity.");
        return FALSE;
    }

    if(!PanDeityHasMiracle(nDeity, nMir))
    {
        PanFloat(oPC, PanDeityName(nDeity) + " does not grant "
            + PanMiracleName(nMir) + ".");
        return FALSE;
    }

    int nFavor = PanGetFavor(sUuid);
    if(nFavor < PanMiracleFavorReq(nMir))
    {
        PanFloat(oPC, "Insufficient favor for " + PanMiracleName(nMir)
            + " (need " + IntToString(PanMiracleFavorReq(nMir)) + ").");
        return FALSE;
    }

    int nCd = PanCooldownRemaining(oPC, nMir);
    if(nCd > 0)
    {
        PanFloat(oPC, PanMiracleName(nMir) + " is on cooldown ("
            + PanFormatCooldown(nCd) + ").");
        return FALSE;
    }

    // Target validation (Smite only in v1)
    if(nMir == PAN_MIRACLE_SMITE)
    {
        if(!GetIsObjectValid(oTarget) || oTarget == oPC)
        {
            PanFloat(oPC, "Targeting canceled.");
            return FALSE;
        }
        if(GetIsReactionTypeFriendly(oTarget, oPC))
        {
            PanFloat(oPC, "You cannot smite an ally.");
            return FALSE;
        }
    }

    switch(nMir)
    {
        case PAN_MIRACLE_HEAL:      PanApplyHeal(oPC);             break;
        case PAN_MIRACLE_BLESS:     PanApplyBless(oPC);            break;
        case PAN_MIRACLE_SMITE:     PanApplySmite(oPC, oTarget);   break;
        case PAN_MIRACLE_SANCTUARY: PanApplySanctuary(oPC);        break;
        default: return FALSE;
    }

    PanAdjustFavor(sUuid, -PanMiracleFavorCost(nMir));
    PanStartCooldown(oPC, nMir);
    PanIncMiraclesCast(sUuid);

    int nTk = NuiFindWindow(oPC, PAN_WINDOW);
    if(nTk != 0)
    {
        PanRefreshState(oPC);
        FeedPanWindow(oPC, nTk);
    }
    return TRUE;
}

// ----------------------------------------------------------------
// Targeting (Smite)
// ----------------------------------------------------------------

void PanStartMiracleTargeting(object oPC, int nMir)
{
    SetLocalInt(oPC, PAN_LVAR_PENDING_TARGET, nMir + 1);
    PanFloat(oPC, "Select a target for " + PanMiracleName(nMir) + ".");
    EnterTargetingMode(oPC, OBJECT_TYPE_CREATURE);
}

void PanOnPlayerTarget(object oPC)
{
    int nMir = GetLocalInt(oPC, PAN_LVAR_PENDING_TARGET) - 1;
    DeleteLocalInt(oPC, PAN_LVAR_PENDING_TARGET);
    if(nMir < 0) return;

    object oTarget = GetTargetingModeSelectedObject();
    if(!GetIsObjectValid(oTarget))
    {
        PanFloat(oPC, "Targeting canceled.");
        return;
    }
    PanTryCastMiracle(oPC, nMir, oTarget);
}

// ----------------------------------------------------------------
// UI - main window
// ----------------------------------------------------------------

json BuildPanMiracleRow(object oPC)
{
    json jName = NuiLabel(NuiBind(PAN_BIND_MIR_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiWidth(jName, GetNuiScaleDimension(oPC, 110.0));
    jName = NuiStyleForegroundColor(jName, NuiBind(PAN_BIND_MIR_COLOR));

    json jDesc = NuiLabel(NuiBind(PAN_BIND_MIR_DESC),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDesc = NuiStyleForegroundColor(jDesc, NuiBind(PAN_BIND_MIR_COLOR));

    json jCost = NuiLabel(NuiBind(PAN_BIND_MIR_COST),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCost = NuiStyleForegroundColor(jCost, NuiBind(PAN_BIND_MIR_COLOR));

    json jMidCol = JsonArray();
    jMidCol = JsonArrayInsert(jMidCol, jDesc);
    jMidCol = JsonArrayInsert(jMidCol, jCost);

    json jBtn = NuiButton(NuiBind(PAN_BIND_MIR_BTN));
    jBtn = NuiId(jBtn, PAN_BTN_MIRACLE);
    jBtn = NuiEnabled(jBtn, NuiBind(PAN_BIND_MIR_BTN_ENA));
    jBtn = NuiWidth(jBtn, GetNuiScaleDimension(oPC, 85.0));

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jName);
    jRow = JsonArrayInsert(jRow, NuiCol(jMidCol));
    jRow = JsonArrayInsert(jRow, jBtn);
    return NuiGroup(NuiRow(jRow), TRUE, NUI_SCROLLBARS_NONE);
}

void CreatePanWindow(object oPC)
{
    int nExisting = NuiFindWindow(oPC, PAN_WINDOW);
    if(nExisting != 0)
    {
        FeedPanWindow(oPC, nExisting);
        return;
    }

    PanEnsureRow(oPC);

    if(PanGetDeity(GetObjectUUID(oPC)) == PAN_DEITY_NONE)
    {
        PanFloat(oPC, "You must devote yourself to a deity at a shrine "
            + "before approaching this altar.");
        return;
    }

    float fW    = GetNuiScaleDimension(oPC, PAN_W);
    float fH    = GetNuiScaleDimension(oPC, PAN_H);
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fLblH = GetNuiScaleDimension(oPC, 22.0);

    json jTitle = NuiLabel(NuiBind(PAN_BIND_TITLE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);

    json jClose = NuiId(NuiButton(JsonString("X")), PAN_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 35.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitle);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jClose);

    json jDeity = NuiLabel(NuiBind(PAN_BIND_DEITY_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDeity = NuiStyleForegroundColor(jDeity, NuiColor(255, 255, 255));
    jDeity = NuiHeight(jDeity, fLblH);

    json jFavor = NuiLabel(NuiBind(PAN_BIND_FAVOR_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jFavor = NuiHeight(jFavor, fLblH);

    json jRank = NuiLabel(NuiBind(PAN_BIND_RANK_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRank = NuiWidth(jRank, GetNuiScaleDimension(oPC, 100.0));
    jRank = NuiHeight(jRank, fLblH);

    json jStatRow = JsonArray();
    jStatRow = JsonArrayInsert(jStatRow, jFavor);
    jStatRow = JsonArrayInsert(jStatRow, NuiSpacer());

    // Progress bar row: rank label + progress bar + "+X to NextRank"
    json jProg = NuiProgress(NuiBind(PAN_BIND_RANK_PROG));
    jProg = NuiStyleForegroundColor(jProg, NuiBind(PAN_BIND_RANK_COLOR));
    jProg = NuiTooltip(jProg, NuiBind(PAN_BIND_RANK_TIP));
    jProg = NuiWidth(jProg, GetNuiScaleDimension(oPC, 240.0));
    jProg = NuiHeight(jProg, fLblH);

    json jNextLbl = NuiLabel(NuiBind(PAN_BIND_RANK_NEXT),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNextLbl = NuiWidth(jNextLbl, GetNuiScaleDimension(oPC, 160.0));
    jNextLbl = NuiHeight(jNextLbl, fLblH);

    json jProgRow = JsonArray();
    jProgRow = JsonArrayInsert(jProgRow, jRank);
    jProgRow = JsonArrayInsert(jProgRow, jProg);
    jProgRow = JsonArrayInsert(jProgRow, jNextLbl);

    json jPray = NuiId(NuiButton(NuiBind(PAN_BIND_PRAY_LBL)), PAN_BTN_PRAY);
    jPray = NuiEnabled(jPray, NuiBind(PAN_BIND_PRAY_ENA));
    jPray = NuiTooltip(jPray, NuiBind(PAN_BIND_PRAY_TIP));
    jPray = NuiWidth(jPray, GetNuiScaleDimension(oPC, 180.0));
    jPray = NuiHeight(jPray, fBtnH);

    json jOffer = NuiId(NuiButton(JsonString("Offer gold")), PAN_BTN_OFFER);
    jOffer = NuiWidth(jOffer, GetNuiScaleDimension(oPC, 130.0));
    jOffer = NuiHeight(jOffer, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jPray);
    jBtnRow = JsonArrayInsert(jBtnRow, jOffer);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    json jTmpl = JsonArrayInsert(JsonArray(),
        NuiListTemplateCell(BuildPanMiracleRow(oPC), 0.0, TRUE));
    // List stretches to ~25px before bottom of window.
    // Top stack ~220 (title + altar row + deity + favor + prog + buttons),
    // so list height = PAN_H - 220 - 25 buffer.
    json jList = NuiList(jTmpl, NuiBind(PAN_BIND_MIR_LEN),
        GetNuiScaleDimension(oPC, 60.0), TRUE, NUI_SCROLLBARS_Y);
    jList = NuiHeight(jList, GetNuiScaleDimension(oPC, PAN_H - 180.0));
    jList = NuiWidth(jList,  GetNuiScaleDimension(oPC, PAN_W - 20.0));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTopRow));
    jCol = JsonArrayInsert(jCol, jDeity);
    jCol = JsonArrayInsert(jCol, NuiRow(jStatRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jProgRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));
    jCol = JsonArrayInsert(jCol, jList);

    json jRoot = NuiCol(jCol);

    // Background overlay: deity art rendered behind all content (DrawList ORDER_BEFORE).
    // Aspect FILL crops the portrait to fit landscape window (centers on the figure).
    json jBgImg = NuiDrawListImage(
        JsonBool(TRUE),
        NuiBind(PAN_BIND_BG_IMAGE),
        NuiRect(GetNuiScaleDimension(oPC, -20.0), 0.0,
            GetNuiScaleDimension(oPC, PAN_W + 40.0),
            GetNuiScaleDimension(oPC, PAN_H)),
        JsonInt(NUI_ASPECT_FILL),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE),
        NUI_DRAW_LIST_ITEM_ORDER_BEFORE,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);
    json jDl = JsonArrayInsert(JsonArray(), jBgImg);
    jRoot = NuiDrawList(jRoot, JsonBool(FALSE), jDl);

    json jNui = NuiWindow(jRoot,
        JsonBool(FALSE), NuiBind(WINDOW_GEOMETRY),
        JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(FALSE), JsonBool(TRUE), JsonBool(FALSE));

    int nTk = NuiCreate(oPC, jNui, PAN_WINDOW, PAN_EV_SCRIPT);
    NuiSetBind(oPC, nTk, WINDOW_GEOMETRY, NuiRect(-1.0, -1.0, fW, fH));
    NuiSetBind(oPC, nTk, PAN_BIND_TITLE,  JsonString("Altar of Devotion"));

    PanRefreshState(oPC);
    FeedPanWindow(oPC, nTk);
    DelayCommand(1.0, PanTickWindow(oPC, nTk));
}

void FeedPanWindow(object oPC, int nToken)
{
    // Read from cached LVAR state, not SQL.
    int nNow   = GetLocalInt(oPC, PAN_LVAR_LOAD_NOW)
               + GetLocalInt(oPC, PAN_LVAR_TICK_OFFSET);
    int nDeity = GetLocalInt(oPC, PAN_LVAR_DEITY);
    int nFavor = GetLocalInt(oPC, PAN_LVAR_FAVOR);
    int nLast  = GetLocalInt(oPC, PAN_LVAR_LAST_PRAYED);

    if(nDeity == PAN_DEITY_NONE)
    {
        NuiSetBind(oPC, nToken, PAN_BIND_DEITY_LBL,
            JsonString("Devoted to: nobody yet"));
    }
    else
    {
        NuiSetBind(oPC, nToken, PAN_BIND_DEITY_LBL,
            JsonString("Devoted to: " + PanDeityName(nDeity)
                + " - " + PanDeityDomain(nDeity)));
    }

    NuiSetBind(oPC, nToken, PAN_BIND_FAVOR_LBL,
        JsonString("Favor: " + IntToString(nFavor)));

    NuiSetBind(oPC, nToken, PAN_BIND_BG_IMAGE,
        JsonString(PanDeityImage(nDeity)));

    if(nDeity == PAN_DEITY_NONE)
    {
        NuiSetBind(oPC, nToken, PAN_BIND_RANK_LBL,   JsonString(""));
        NuiSetBind(oPC, nToken, PAN_BIND_RANK_PROG,  JsonFloat(0.0));
        NuiSetBind(oPC, nToken, PAN_BIND_RANK_NEXT,  JsonString(""));
        NuiSetBind(oPC, nToken, PAN_BIND_RANK_COLOR, NuiColor(140, 140, 140));
        NuiSetBind(oPC, nToken, PAN_BIND_RANK_TIP,   JsonString(""));
    }
    else
    {
        int nRankNow = PanGetRankId(nFavor);
        NuiSetBind(oPC, nToken, PAN_BIND_RANK_LBL,
            JsonString(PanFavorRank(nFavor)));
        NuiSetBind(oPC, nToken, PAN_BIND_RANK_PROG,
            JsonFloat(PanGetRankProgress(nFavor)));
        NuiSetBind(oPC, nToken, PAN_BIND_RANK_COLOR, PanDeityColor(nDeity));

        string sNextRank = PanGetNextRankName(nRankNow);
        string sNextLbl;
        string sTip;
        string sRankNow = PanFavorRank(nFavor);
        int nRankMin = PanRankMinFavor(nRankNow);
        int nRankMax = PanRankMaxFavor(nRankNow);
        if(sNextRank == "")
        {
            sNextLbl = "Maxed";
            sTip = sRankNow + " rank (max). Current favor: "
                + IntToString(nFavor) + ".";
        }
        else
        {
            int nToNext = PanGetFavorToNextRank(nFavor);
            sNextLbl = "+" + IntToString(nToNext) + " to " + sNextRank;
            sTip = sRankNow + " range: " + IntToString(nRankMin)
                + " to " + IntToString(nRankMax)
                + ". Current favor: " + IntToString(nFavor)
                + ". Need +" + IntToString(nToNext)
                + " for " + sNextRank + ".";
        }
        NuiSetBind(oPC, nToken, PAN_BIND_RANK_NEXT, JsonString(sNextLbl));
        NuiSetBind(oPC, nToken, PAN_BIND_RANK_TIP,  JsonString(sTip));
    }

    int nWait;
    if(nLast == 0 || nNow - nLast >= PAN_PRAY_COOLDOWN_S)
    {
        nWait = 0;
    }
    else
    {
        nWait = PAN_PRAY_COOLDOWN_S - (nNow - nLast);
    }
    int bCanPray = (nDeity != PAN_DEITY_NONE) && (nWait == 0);
    NuiSetBind(oPC, nToken, PAN_BIND_PRAY_ENA, JsonBool(bCanPray));

    int nPrayGain = PanGetPrayGain(PanGetRankId(nFavor));
    string sTip;
    string sPrayLbl;
    if(nWait > 0)
    {
        sTip = "Available in " + PanFormatCooldown(nWait);
        sPrayLbl = "Pray (" + PanFormatCooldown(nWait) + ")";
    }
    else
    {
        sTip = "Speak the words and gain " + IntToString(nPrayGain) + " favor.";
        sPrayLbl = "Pray (+" + IntToString(nPrayGain) + " favor)";
    }
    NuiSetBind(oPC, nToken, PAN_BIND_PRAY_TIP, JsonString(sTip));
    NuiSetBind(oPC, nToken, PAN_BIND_PRAY_LBL, JsonString(sPrayLbl));

    json jName  = JsonArray();
    json jDesc  = JsonArray();
    json jCost  = JsonArray();
    json jBtn   = JsonArray();
    json jEna   = JsonArray();
    json jColor = JsonArray();

    int nRankForDesc = (nDeity == PAN_DEITY_NONE)
        ? PAN_RANK_ACOLYTE
        : PanGetRankId(nFavor);

    int i;
    for(i = 0; i < PAN_MIRACLE_COUNT; i++)
    {
        int nReq  = PanMiracleFavorReq(i);
        int nCost = PanMiracleFavorCost(i);
        // Read cached ready_at, derive remaining locally.
        int nReady = GetLocalInt(oPC, PAN_LVAR_CD_PREFIX + IntToString(i));
        int nCd    = (nNow >= nReady) ? 0 : nReady - nNow;
        int bGranted = (nDeity != PAN_DEITY_NONE) && PanDeityHasMiracle(nDeity, i);
        int bUnlocked = bGranted && (nFavor >= nReq);
        int bReady    = bUnlocked && (nCd == 0);

        jName = JsonArrayInsert(jName, JsonString(PanMiracleName(i)));
        jDesc = JsonArrayInsert(jDesc,
            JsonString(PanMiracleDescriptionRank(i, nRankForDesc)));
        if(nDeity != PAN_DEITY_NONE && !bGranted)
        {
            jCost = JsonArrayInsert(jCost,
                JsonString("Not granted by " + PanDeityName(nDeity)));
        }
        else
        {
            jCost = JsonArrayInsert(jCost,
                JsonString("Cost: " + IntToString(nCost)
                    + " favor / requires " + IntToString(nReq)));
        }

        string sBtn;
        if(nCd > 0)
        {
            sBtn = PanFormatCooldown(nCd);
        }
        else
        {
            sBtn = "Invoke";
        }
        jBtn = JsonArrayInsert(jBtn, JsonString(sBtn));
        jEna = JsonArrayInsert(jEna, JsonBool(bReady));

        // Always white text in cells for readability against the dark bg image.
        jColor = JsonArrayInsert(jColor, NuiColor(255, 255, 255));
    }

    NuiSetBind(oPC, nToken, PAN_BIND_MIR_NAME,    jName);
    NuiSetBind(oPC, nToken, PAN_BIND_MIR_DESC,    jDesc);
    NuiSetBind(oPC, nToken, PAN_BIND_MIR_COST,    jCost);
    NuiSetBind(oPC, nToken, PAN_BIND_MIR_BTN,     jBtn);
    NuiSetBind(oPC, nToken, PAN_BIND_MIR_BTN_ENA, jEna);
    NuiSetBind(oPC, nToken, PAN_BIND_MIR_COLOR,   jColor);
    NuiSetBind(oPC, nToken, PAN_BIND_MIR_LEN,     JsonInt(PAN_MIRACLE_COUNT));
}

// Local-clock tick. No SQL - just bumps PAN_LVAR_TICK_OFFSET so derived
// timer values in FeedPanWindow shrink by 1s. Resync via PanRefreshState
// happens on user actions (pray / cast / deity change).
void PanTickWindow(object oPC, int nToken)
{
    if(!GetIsObjectValid(oPC)) return;
    int nCurrent = NuiFindWindow(oPC, PAN_WINDOW);
    if(nCurrent != nToken)
    {
        PanClearState(oPC);  // window gone -> drop cache
        return;
    }
    SetLocalInt(oPC, PAN_LVAR_TICK_OFFSET,
        GetLocalInt(oPC, PAN_LVAR_TICK_OFFSET) + 1);
    FeedPanWindow(oPC, nToken);
    DelayCommand(1.0, PanTickWindow(oPC, nToken));
}

// ----------------------------------------------------------------
// Deity selector popup
// ----------------------------------------------------------------

void PanShowDeitySelector(object oPC)
{
    int nExisting = NuiFindWindow(oPC, PAN_WIN_DEITY);
    if(nExisting != 0)
    {
        NuiDestroy(oPC, nExisting);
    }

    float fW    = GetNuiScaleDimension(oPC, PAN_DEITY_W);
    float fH    = GetNuiScaleDimension(oPC, PAN_DEITY_H);
    float fRowH = GetNuiScaleDimension(oPC, 36.0);

    json jLbl = NuiLabel(NuiBind(PAN_BIND_DEITY_ROW_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLbl = NuiWidth(jLbl, GetNuiScaleDimension(oPC, 130.0));

    json jDesc = NuiLabel(NuiBind(PAN_BIND_DEITY_ROW_DESC),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jRowArr = JsonArray();
    jRowArr = JsonArrayInsert(jRowArr, jLbl);
    jRowArr = JsonArrayInsert(jRowArr, jDesc);
    json jRowCell = NuiGroup(NuiRow(jRowArr), TRUE, NUI_SCROLLBARS_NONE);
    jRowCell = NuiId(jRowCell, PAN_BTN_DEITY_ROW);

    json jTmpl = JsonArrayInsert(JsonArray(),
        NuiListTemplateCell(jRowCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(PAN_BIND_DEITY_LEN),
        fRowH, TRUE, NUI_SCROLLBARS_NONE);
    jList = NuiHeight(jList, GetNuiScaleDimension(oPC, PAN_DEITY_H - 80.0));
    jList = NuiWidth(jList,  GetNuiScaleDimension(oPC, PAN_DEITY_W - 20.0));

    json jHdr = NuiLabel(JsonString("Choose your deity (click a row):"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHdr = NuiHeight(jHdr, GetNuiScaleDimension(oPC, 24.0));

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jHdr);
    jCol = JsonArrayInsert(jCol, jList);

    json jNui = NuiWindow(NuiCol(jCol),
        JsonString("Pantheon - Deity Selection"),
        NuiRect(-1.0, -1.0, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE), JsonBool(TRUE));
    int nTk = NuiCreate(oPC, jNui, PAN_WIN_DEITY, PAN_EV_SCRIPT);

    json jLabels = JsonArray();
    json jDescs  = JsonArray();
    int i;
    for(i = 0; i < PAN_DEITY_COUNT; i++)
    {
        jLabels = JsonArrayInsert(jLabels, JsonString(PanDeityName(i)));
        jDescs  = JsonArrayInsert(jDescs,  JsonString(PanDeityDomain(i)));
    }
    NuiSetBind(oPC, nTk, PAN_BIND_DEITY_ROW_LBL,  jLabels);
    NuiSetBind(oPC, nTk, PAN_BIND_DEITY_ROW_DESC, jDescs);
    NuiSetBind(oPC, nTk, PAN_BIND_DEITY_LEN,      JsonInt(PAN_DEITY_COUNT));
}

void PanSelectDeity(object oPC, int nDeityId)
{
    if(nDeityId < 0 || nDeityId >= PAN_DEITY_COUNT) return;

    string sUuid    = GetObjectUUID(oPC);
    int    nCurrent = PanGetDeity(sUuid);

    if(nCurrent == nDeityId)
    {
        PanFloat(oPC, "You already serve " + PanDeityName(nDeityId) + ".");
        return;
    }

    if(nCurrent != PAN_DEITY_NONE)
    {
        // Switching gods costs all favor and applies disfavor.
        PanAdjustFavor(sUuid, -PanGetFavor(sUuid) - PAN_DEITY_SWITCH_DISFAVOR);
        PanFloat(oPC, "Forsaking " + PanDeityName(nCurrent)
            + " - favor lost, disfavor incurred.");
    }

    PanSetDeity(sUuid, nDeityId);
    SetDeity(oPC, PanDeityName(nDeityId));
    PanFloat(oPC, "You devote yourself to " + PanDeityName(nDeityId) + ".");

    int nMain = NuiFindWindow(oPC, PAN_WINDOW);
    if(nMain != 0)
    {
        PanRefreshState(oPC);
        FeedPanWindow(oPC, nMain);
    }
    int nSel = NuiFindWindow(oPC, PAN_WIN_DEITY);
    if(nSel != 0)
    {
        NuiDestroy(oPC, nSel);
    }
}

// ----------------------------------------------------------------
// Gold offer popup
// ----------------------------------------------------------------

void PanShowOfferWindow(object oPC)
{
    string sUuid = GetObjectUUID(oPC);
    int nDeity = PanGetDeity(sUuid);
    if(nDeity == PAN_DEITY_NONE)
    {
        PanFloat(oPC, "Choose a deity before you offer gold.");
        return;
    }

    int nExisting = NuiFindWindow(oPC, PAN_WIN_OFFER);
    if(nExisting != 0)
    {
        NuiDestroy(oPC, nExisting);
    }

    float fW    = GetNuiScaleDimension(oPC, PAN_OFFER_W);
    float fH    = GetNuiScaleDimension(oPC, PAN_OFFER_H);
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);

    float fLineW = GetNuiScaleDimension(oPC, PAN_OFFER_W - 20.0);

    json jInfoStatic = NuiLabel(JsonString("Each "
            + IntToString(PAN_OFFER_GOLD_PER_FAVOR)
            + " gold grants +1 favor (minimum "
            + IntToString(PAN_OFFER_MIN_GOLD) + " gold)."),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jInfoStatic = NuiWidth(jInfoStatic, fLineW);
    jInfoStatic = NuiHeight(jInfoStatic, GetNuiScaleDimension(oPC, 24.0));

    json jInfoGold = NuiLabel(NuiBind(PAN_BIND_OFFER_INFO),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jInfoGold = NuiWidth(jInfoGold, fLineW);
    jInfoGold = NuiHeight(jInfoGold, GetNuiScaleDimension(oPC, 24.0));

    json jAmt = NuiTextEdit(JsonString("Gold amount"),
        NuiBind(PAN_BIND_OFFER_AMT), 12, FALSE);
    jAmt = NuiWidth(jAmt, GetNuiScaleDimension(oPC, 200.0));
    jAmt = NuiHeight(jAmt, fBtnH);

    json jOk = NuiId(NuiButton(JsonString("Confirm")), PAN_BTN_OFFER_OK);
    jOk = NuiWidth(jOk, GetNuiScaleDimension(oPC, 110.0));
    jOk = NuiHeight(jOk, fBtnH);

    json jNo = NuiId(NuiButton(JsonString("Cancel")), PAN_BTN_OFFER_NO);
    jNo = NuiWidth(jNo, GetNuiScaleDimension(oPC, 110.0));
    jNo = NuiHeight(jNo, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jOk);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jNo);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jInfoStatic);
    jCol = JsonArrayInsert(jCol, jInfoGold);
    jCol = JsonArrayInsert(jCol, jAmt);
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jNui = NuiWindow(NuiCol(jCol),
        JsonString("Offer to " + PanDeityName(nDeity)),
        NuiRect(-1.0, -1.0, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE), JsonBool(TRUE));
    int nTk = NuiCreate(oPC, jNui, PAN_WIN_OFFER, PAN_EV_SCRIPT);

    NuiSetBind(oPC, nTk, PAN_BIND_OFFER_INFO,
        JsonString("Your gold: " + IntToString(GetGold(oPC))));
    NuiSetBind(oPC, nTk, PAN_BIND_OFFER_AMT, JsonString(""));
}

void PanProcessOffer(object oPC, int nGold)
{
    string sUuid = GetObjectUUID(oPC);
    int nDeity = PanGetDeity(sUuid);
    if(nDeity == PAN_DEITY_NONE)
    {
        PanFloat(oPC, "You serve no deity.");
        return;
    }
    if(nGold < PAN_OFFER_MIN_GOLD)
    {
        PanFloat(oPC, "Minimum offering is "
            + IntToString(PAN_OFFER_MIN_GOLD) + " gold.");
        return;
    }
    if(GetGold(oPC) < nGold)
    {
        PanFloat(oPC, "You don't have " + IntToString(nGold) + " gold.");
        return;
    }

    int nFavorGain = nGold / PAN_OFFER_GOLD_PER_FAVOR;
    AssignCommand(oPC, TakeGoldFromCreature(nGold, oPC, TRUE));
    PanAdjustFavor(sUuid, nFavorGain);

    PanFloat(oPC, "You offered " + IntToString(nGold) + " gold to "
        + PanDeityName(nDeity) + ". (+" + IntToString(nFavorGain) + " favor)");
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_HEAD_HOLY), oPC);

    int nMain = NuiFindWindow(oPC, PAN_WINDOW);
    if(nMain != 0)
    {
        PanRefreshState(oPC);
        FeedPanWindow(oPC, nMain);
    }
    int nOff = NuiFindWindow(oPC, PAN_WIN_OFFER);
    if(nOff != 0)
    {
        NuiDestroy(oPC, nOff);
    }
}

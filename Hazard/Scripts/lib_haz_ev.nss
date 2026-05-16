// lib_haz_ev.nss — NUI event handler for Hazard module
#include "lib_haz"

// ----------------------------------------------------------------
// Roll handler — validates bet, rolls 3d6, transitions to ROLLED phase
// ----------------------------------------------------------------

void HazHandleRoll(object oPC, int nToken)
{
    string sBet = JsonGetString(NuiGetBind(oPC, nToken, HAZ_BIND_BET));
    int nBet    = StringToInt(sBet);

    if(nBet < HAZ_BET_MIN)
    {
        SendMessageToPC(oPC, "[Hazard] Minimalny zakład to " + IntToString(HAZ_BET_MIN) + " szt.");
        return;
    }
    if(nBet > HAZ_BET_MAX)
    {
        SendMessageToPC(oPC, "[Hazard] Maksymalny zakład to " + IntToString(HAZ_BET_MAX) + " szt.");
        return;
    }
    if(GetGold(oPC) < nBet)
    {
        SendMessageToPC(oPC, "[Hazard] Nie masz wystarczająco złota.");
        return;
    }

    int bBlood = JsonGetInt(NuiGetBind(oPC, nToken, HAZ_BIND_BLOOD));

    SetLocalInt(oPC, HAZ_LVAR_BET,      nBet);
    SetLocalInt(oPC, HAZ_LVAR_BLOOD,    bBlood);
    SetLocalInt(oPC, HAZ_LVAR_REROLLED, 0);
    SetLocalInt(oPC, HAZ_LVAR_H1, 0);
    SetLocalInt(oPC, HAZ_LVAR_H2, 0);
    SetLocalInt(oPC, HAZ_LVAR_H3, 0);
    SetLocalInt(oPC, HAZ_LVAR_D1, Random(6) + 1);
    SetLocalInt(oPC, HAZ_LVAR_D2, Random(6) + 1);
    SetLocalInt(oPC, HAZ_LVAR_D3, Random(6) + 1);
    SetLocalInt(oPC, HAZ_LVAR_PHASE, HAZ_PHASE_ROLLED);

    HazFeedRolledPhase(oPC, nToken);

    if(bBlood)
        SendMessageToPC(oPC, "[Hazard] Pieczęć krwi pulsuje słabo... Rzucasz kości.");
    else
        SendMessageToPC(oPC, "[Hazard] Kości toczą się po stole...");
}

// ----------------------------------------------------------------
// Reroll handler — rolls only the un-held dice (once per round)
// ----------------------------------------------------------------

void HazHandleReroll(object oPC, int nToken)
{
    if(GetLocalInt(oPC, HAZ_LVAR_REROLLED)) return;

    int h1 = GetLocalInt(oPC, HAZ_LVAR_H1);
    int h2 = GetLocalInt(oPC, HAZ_LVAR_H2);
    int h3 = GetLocalInt(oPC, HAZ_LVAR_H3);

    if(!h1) SetLocalInt(oPC, HAZ_LVAR_D1, Random(6) + 1);
    if(!h2) SetLocalInt(oPC, HAZ_LVAR_D2, Random(6) + 1);
    if(!h3) SetLocalInt(oPC, HAZ_LVAR_D3, Random(6) + 1);

    SetLocalInt(oPC, HAZ_LVAR_REROLLED, 1);
    HazFeedRolledPhase(oPC, nToken);
    SendMessageToPC(oPC, "[Hazard] Wolne kości przerzucone.");
}

// ----------------------------------------------------------------
// Stand handler — dealer plays, scores compared, gold settled
// ----------------------------------------------------------------

void HazHandleStand(object oPC, int nToken)
{
    int d1 = GetLocalInt(oPC, HAZ_LVAR_D1);
    int d2 = GetLocalInt(oPC, HAZ_LVAR_D2);
    int d3 = GetLocalInt(oPC, HAZ_LVAR_D3);
    int nPlayerScore = HazScore(d1, d2, d3);

    // Dealer initial roll
    int dd1 = Random(6) + 1;
    int dd2 = Random(6) + 1;
    int dd3 = Random(6) + 1;
    int nDealerScore = HazDealerPlayFull(oPC, dd1, dd2, dd3);

    int nBet   = GetLocalInt(oPC, HAZ_LVAR_BET);
    int bBlood = GetLocalInt(oPC, HAZ_LVAR_BLOOD);
    int nPayout = HazCalcPayout(nPlayerScore, nDealerScore, nBet, bBlood);

    if(nPayout > 0)
    {
        GiveGoldToCreature(oPC, nPayout);
        HazRecordWin(oPC, nPayout);
    }
    else if(nPayout < 0)
    {
        int nLoss = -nPayout;
        AssignCommand(oPC, TakeGoldFromCreature(nLoss, oPC, TRUE));

        if(bBlood)
        {
            int nDmg = GetMaxHitPoints(oPC) / 10;
            if(nDmg < 1) nDmg = 1;
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectDamage(nDmg, DAMAGE_TYPE_NEGATIVE), oPC);
            SendMessageToPC(oPC,
                "[Hazard] Cena Krwi — pieczęć pęka: " + IntToString(nDmg) + " obrażeń.");
        }

        HazRecordLoss(oPC, nLoss);
    }
    else
    {
        HazRecordPush(oPC);
    }

    SetLocalInt(oPC, HAZ_LVAR_PHASE, HAZ_PHASE_RESULT);
    HazFeedResult(oPC, nToken, nPlayerScore, nDealerScore, nPayout);
}

// ----------------------------------------------------------------
// Toggle hold on a player die (only in ROLLED phase)
// ----------------------------------------------------------------

void HazToggleHold(object oPC, int nToken, string sLvar)
{
    if(GetLocalInt(oPC, HAZ_LVAR_PHASE) != HAZ_PHASE_ROLLED) return;
    SetLocalInt(oPC, sLvar, !GetLocalInt(oPC, sLvar));
    HazFeedRolledPhase(oPC, nToken);
}

// ----------------------------------------------------------------
// Reset to bet phase for a new round
// ----------------------------------------------------------------

void HazHandleNewRound(object oPC, int nToken)
{
    DeleteLocalInt(oPC, HAZ_LVAR_D1);
    DeleteLocalInt(oPC, HAZ_LVAR_D2);
    DeleteLocalInt(oPC, HAZ_LVAR_D3);
    DeleteLocalInt(oPC, HAZ_LVAR_H1);
    DeleteLocalInt(oPC, HAZ_LVAR_H2);
    DeleteLocalInt(oPC, HAZ_LVAR_H3);
    DeleteLocalInt(oPC, HAZ_LVAR_REROLLED);
    DeleteLocalInt(oPC, HAZ_LVAR_BLOOD);
    DeleteLocalInt(oPC, HAZ_LVAR_DD1);
    DeleteLocalInt(oPC, HAZ_LVAR_DD2);
    DeleteLocalInt(oPC, HAZ_LVAR_DD3);
    SetLocalInt(oPC, HAZ_LVAR_PHASE, HAZ_PHASE_BET);
    HazFeedBetPhase(oPC, nToken);
}

// ----------------------------------------------------------------
// Main event dispatcher
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    // Stats window events
    if(nToken == NuiFindWindow(oPC, HAZ_WIN_STATS))
    {
        if(sEvent == EVENT_TYPE_CLICK && sElem == HAZ_BTN_CLOSE)
            NuiDestroy(oPC, nToken);
        return;
    }

    if(nToken != NuiFindWindow(oPC, HAZ_WINDOW)) return;

    // Window closed via OS chrome
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        HazCleanupLvars(oPC);
        int nStats = NuiFindWindow(oPC, HAZ_WIN_STATS);
        if(nStats != 0) NuiDestroy(oPC, nStats);
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK) return;

    if(sElem == HAZ_BTN_CLOSE)
    {
        HazCleanupLvars(oPC);
        int nStats = NuiFindWindow(oPC, HAZ_WIN_STATS);
        if(nStats != 0) NuiDestroy(oPC, nStats);
        NuiDestroy(oPC, nToken);
        return;
    }

    if(sElem == HAZ_BTN_ROLL)
    {
        HazHandleRoll(oPC, nToken);
        return;
    }

    if(sElem == HAZ_BTN_REROLL)
    {
        HazHandleReroll(oPC, nToken);
        return;
    }

    if(sElem == HAZ_BTN_STAND)
    {
        HazHandleStand(oPC, nToken);
        return;
    }

    if(sElem == HAZ_BTN_NEW)
    {
        HazHandleNewRound(oPC, nToken);
        return;
    }

    if(sElem == HAZ_BTN_STATS)
    {
        HazOpenStatsWindow(oPC);
        return;
    }

    if(sElem == HAZ_BTN_D1)
    {
        HazToggleHold(oPC, nToken, HAZ_LVAR_H1);
        return;
    }
    if(sElem == HAZ_BTN_D2)
    {
        HazToggleHold(oPC, nToken, HAZ_LVAR_H2);
        return;
    }
    if(sElem == HAZ_BTN_D3)
    {
        HazToggleHold(oPC, nToken, HAZ_LVAR_H3);
        return;
    }
}

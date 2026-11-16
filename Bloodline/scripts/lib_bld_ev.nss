#include "lib_bld"

// ----------------------------------------------------------------
// Ritual logic
// ----------------------------------------------------------------

void BldPerformRitual(object oPC, int nToken)
{
    int nType   = BldGetBloodlineType(oPC);
    int nPurity = BldGetPurity(oPC);
    int nTier   = BldGetCurrentTier(nPurity);

    if(nType < 0)
    {
        SendMessageToPC(oPC, "[Krew] Wybierz najpierw linie krwi.");
        return;
    }
    if(nTier >= BLD_TIER_ASCENDANT)
    {
        SendMessageToPC(oPC, "[Krew] Twoja krew jest juz w pelni przebudzona.");
        return;
    }

    // Cooldown check
    int nNow     = BldGetCurrentTimestamp();
    int nLastRit = BldGetLastRitual(oPC);
    if(nNow - nLastRit < BLD_RITUAL_COOLDOWN)
    {
        int nRemain    = (nLastRit + BLD_RITUAL_COOLDOWN) - nNow;
        int nHoursLeft = nRemain / 3600;
        int nMinsLeft  = (nRemain % 3600) / 60;
        SendMessageToPC(oPC, "[Krew] Krew jeszcze nie odpoczela. Pozostalo: "
            + IntToString(nHoursLeft) + "h " + IntToString(nMinsLeft) + "m.");
        return;
    }

    int nHPPct    = BldGetRitualHPPct(nTier);
    int nGoldCost = BldGetRitualGoldCost(nTier);
    int nMaxHP    = GetMaxHitPoints(oPC);
    int nHPDmg    = (nMaxHP * nHPPct) / 100;
    if(nHPDmg < 1) nHPDmg = 1;

    // Validate gold
    if(GetGold(oPC) < nGoldCost)
    {
        SendMessageToPC(oPC, "[Krew] Nie masz wystarczajaco zlota. Potrzebujesz "
            + IntToString(nGoldCost) + " sztuk.");
        return;
    }

    // Validate HP — must survive the ritual
    if(GetCurrentHitPoints(oPC) <= nHPDmg)
    {
        SendMessageToPC(oPC, "[Krew] Zbyt slaby, by przezyl rytual. Potrzebujesz wiecej niz "
            + IntToString(nHPDmg) + " punktow zycia.");
        return;
    }

    // Deduct gold
    AssignCommand(oPC, TakeGoldFromCreature(nGoldCost, oPC, TRUE));

    // Ritual wound — magical blood loss
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectDamage(nHPDmg, DAMAGE_TYPE_MAGICAL), oPC);

    // Advance purity to the next tier threshold
    int nNextPurity = BldGetNextTierPurityThreshold(nTier);
    BldSetPurity(oPC, nNextPurity);
    BldSetLastRitual(oPC);

    // Visual feedback
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_COM_BLOOD_REG_RED), oPC);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
        EffectVisualEffect(VFX_DUR_AURA_RED), oPC, 4.0);

    // Apply new passive effects
    BldApplyEffects(oPC);

    int nNewTier = BldGetCurrentTier(nNextPurity);
    string sNewTierName = BldGetTierName(nNewTier);

    SendMessageToPC(oPC, "[Krew] Przebudzenie. Krew plonie. Nowy poziom: " + sNewTierName + ".");
    FloatingTextStringOnCreature("Krew sie przebudzila!", oPC, FALSE);

    BldFeedWindow(oPC, nToken);
}

// ----------------------------------------------------------------
// Main NUI event handler
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, BLD_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, BLD_LVAR_PENDING_TYPE);
        DeleteLocalInt(oPC, BLD_LVAR_HAS_PENDING);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == BLD_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == BLD_BTN_RITUAL)
        {
            BldPerformRitual(oPC, nToken);
            return;
        }

        if(sElem == BLD_BTN_CHOOSE_CONFIRM)
        {
            if(!GetLocalInt(oPC, BLD_LVAR_HAS_PENDING))
            {
                SendMessageToPC(oPC, "[Krew] Wybierz linie krwi z listy, zanim potwierdzisz.");
                return;
            }
            int nChosenType = GetLocalInt(oPC, BLD_LVAR_PENDING_TYPE);
            if(nChosenType < 0 || nChosenType >= BLD_TYPE_COUNT)
            {
                SendMessageToPC(oPC, "[Krew] Nieprawidlowy wybor.");
                return;
            }

            BldSetBloodlineType(oPC, nChosenType);
            DeleteLocalInt(oPC, BLD_LVAR_PENDING_TYPE);
            DeleteLocalInt(oPC, BLD_LVAR_HAS_PENDING);

            SendMessageToPC(oPC, "[Krew] Dziedzictwo wybrane: " + BldGetName(nChosenType)
                + ". Krew drzemie w oczekiwaniu na rytual.");
            BldFeedWindow(oPC, nToken);
            return;
        }

        if(sElem == BLD_BTN_CHOOSE_CANCEL)
        {
            NuiDestroy(oPC, nToken);
            return;
        }
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN)
    {
        if(sElem == BLD_BTN_CHOICE_ROW)
        {
            if(nIdx < 0 || nIdx >= BLD_TYPE_COUNT) return;

            SetLocalInt(oPC, BLD_LVAR_PENDING_TYPE, nIdx);
            SetLocalInt(oPC, BLD_LVAR_HAS_PENDING, 1);

            json jEncs = JsonArray();
            int i;
            for(i = 0; i < BLD_TYPE_COUNT; i++)
                jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
            NuiSetBind(oPC, nToken, BLD_BIND_CHOICE_ROW_ENC, jEncs);
            return;
        }
    }
}

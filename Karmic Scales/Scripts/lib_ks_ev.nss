#include "lib_ks"

// ----------------------------------------------------------------
// Ritual handlers
// ----------------------------------------------------------------

void KsHandleRitual(object oPC, int nToken)
{
    if(KsGetRitualCooldownRemaining(oPC) > 0)
    {
        SendMessageToPC(oPC, "[Szale] Bogowie nie odpowiedzą na twoją modlitwę tak szybko.");
        return;
    }
    if(GetGold(oPC) < KS_RITUAL_GOLD_COST)
    {
        SendMessageToPC(oPC, "[Szale] Nie masz wystarczająco złota na ofiarę.");
        return;
    }
    int nKarma = KsGetKarma(oPC);
    if(abs(nKarma) < KS_RITUAL_SHIFT)
    {
        SendMessageToPC(oPC, "[Szale] Szale są wystarczająco zrównoważone.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(KS_RITUAL_GOLD_COST, oPC, TRUE));
    KsSetRitualAt(oPC);

    // Shift karma toward 0 by KS_RITUAL_SHIFT
    int nShift = (nKarma > 0 ? -KS_RITUAL_SHIFT : KS_RITUAL_SHIFT);
    KsAddKarma(oPC, nShift);
    KsLogEvent(oPC, nShift, "Rytuał Równowagi przy ołtarzu");

    int nNew = KsGetKarma(oPC);
    KsApplyPassiveEffects(oPC, nNew);

    SendMessageToPC(oPC,
        "[Szale] Złoto spłonęło na ołtarzu. Szale przesunęły się ku równowadze. ("
        + IntToString(nKarma) + " → " + IntToString(nNew) + ")");
    FloatingTextStringOnCreature("[Szale] Równowaga przesuwa się...", oPC, FALSE);

    // Rebuild window to reflect new karma visual
    CreateKsWindow(oPC);
}

void KsHandleShadowSurge(object oPC, int nToken)
{
    int nKarma = KsGetKarma(oPC);
    if(nKarma > -KS_SURGE_COST)
    {
        SendMessageToPC(oPC, "[Szale] Niewystarczający mrok. Potrzeba co najmniej "
            + IntToString(KS_SURGE_COST) + " punktów Mroku.");
        return;
    }

    KsAddKarma(oPC, KS_SURGE_COST); // consume dark karma (adds positive = less dark)
    KsLogEvent(oPC, KS_SURGE_COST, "Uwolniony Cień — chwilowa moc bojowa");
    KsApplyShadowSurge(oPC);

    SendMessageToPC(oPC,
        "[Szale] Ciemność przepływa przez twoje żyły... +2 do ataku przez 60 sekund.");
    FloatingTextStringOnCreature("Cień uwolniony!", oPC, FALSE);

    int nNew = KsGetKarma(oPC);
    KsApplyPassiveEffects(oPC, nNew);
    CreateKsWindow(oPC);
}

void KsHandleLightGrace(object oPC, int nToken)
{
    int nKarma = KsGetKarma(oPC);
    if(nKarma < KS_GRACE_COST)
    {
        SendMessageToPC(oPC, "[Szale] Niewystarczający blask. Potrzeba co najmniej "
            + IntToString(KS_GRACE_COST) + " punktów Światła.");
        return;
    }

    KsAddKarma(oPC, -KS_GRACE_COST); // consume light karma
    KsLogEvent(oPC, -KS_GRACE_COST, "Uwolniona Łaska — chwilowa regeneracja");
    KsApplyLightGrace(oPC);

    SendMessageToPC(oPC,
        "[Szale] Ciepło błogosławieństwa przepełnia twoje ciało. Regeneracja 2 PŻ/6s przez 60 sek.");
    FloatingTextStringOnCreature("Łaska uwolniona!", oPC, FALSE);

    int nNew = KsGetKarma(oPC);
    KsApplyPassiveEffects(oPC, nNew);
    CreateKsWindow(oPC);
}

// ----------------------------------------------------------------
// NUI event handler (this script is set as event script for KS_WINDOW)
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(nToken != NuiFindWindow(oPC, KS_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, KS_LVAR_DRAWN_KARMA);
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK) return;

    if(sElem == KS_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    if(sElem == KS_BTN_RITUAL)
    {
        KsHandleRitual(oPC, nToken);
        return;
    }

    if(sElem == KS_BTN_SHADOW_SURGE)
    {
        KsHandleShadowSurge(oPC, nToken);
        return;
    }

    if(sElem == KS_BTN_LIGHT_GRACE)
    {
        KsHandleLightGrace(oPC, nToken);
        return;
    }
}

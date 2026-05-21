#include "lib_pact"

void PactHandleSign(object oPC, int nToken)
{
    string sDemonId = GetLocalString(oPC, PACT_LVAR_SEL);
    if(sDemonId == "") return;

    json jActive = PactGetActive(oPC);
    if(JsonGetType(jActive) != JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Pakt] Masz juz aktywny pakt. Najpierw go zerwij przy oltarzu.");
        return;
    }

    PactSign(oPC, sDemonId);
    PactApplyEffects(oPC, sDemonId);

    FloatingTextStringOnCreature("Pieczen krwi plonie czerwienia. Pakt zawarty.", oPC, FALSE);
    SendMessageToPC(oPC, "[Pakt] Pakt z " + PactGetDemonName(sDemonId) + " zawarty.");

    FeedPactList(oPC, nToken);
    FeedPactDetail(oPC, nToken, sDemonId);
    FeedPactStatus(oPC, nToken);
}

void PactHandleBreak(object oPC, int nToken)
{
    json jActive = PactGetActive(oPC);
    if(JsonGetType(jActive) == JSON_TYPE_NULL) return;

    string sDemonId = JsonGetString(JsonObjectGet(jActive, "demon_id"));

    PactBreak(oPC);
    PactRemoveEffects(oPC);

    // Penalty: immediate HP damage.
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectDamage(PACT_BREAK_HP_COST, DAMAGE_TYPE_NEGATIVE, DAMAGE_POWER_NORMAL), oPC);

    // Penalty: timed curse on STR, DEX, CON for PACT_BREAK_CURSE_SECS.
    effect eCurse = EffectLinkEffects(
        EffectAbilityDecrease(ABILITY_STRENGTH,     2),
        EffectLinkEffects(
            EffectAbilityDecrease(ABILITY_DEXTERITY,    2),
            EffectLinkEffects(
                EffectAbilityDecrease(ABILITY_CONSTITUTION, 2),
                EffectVisualEffect(VFX_DUR_AURA_EVIL_OPPONENT)
            )
        )
    );
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eCurse, oPC, IntToFloat(PACT_BREAK_CURSE_SECS));

    FloatingTextStringOnCreature("Pieczen kruszy sie. Klatwa spada!", oPC, FALSE);
    SendMessageToPC(oPC, "[Pakt] Pakt z " + PactGetDemonName(sDemonId)
        + " zerwany. Klatwa trwa " + IntToString(PACT_BREAK_CURSE_SECS / 60) + " minut.");

    string sSelId = GetLocalString(oPC, PACT_LVAR_SEL);
    FeedPactList(oPC, nToken);
    if(sSelId != "")
        FeedPactDetail(oPC, nToken, sSelId);
    FeedPactStatus(oPC, nToken);
}

// ---- Main NUI event handler ----

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, PACT_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalString(oPC, PACT_LVAR_SEL);
        return;
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == PACT_BTN_ROW)
    {
        if(nIdx < 0 || nIdx >= PACT_DEMON_COUNT) return;
        string sDemonId = PactGetDemonId(nIdx);
        SetLocalString(oPC, PACT_LVAR_SEL, sDemonId);

        json jEncs = JsonArray();
        int i;
        for(i = 0; i < PACT_DEMON_COUNT; i++)
            jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
        NuiSetBind(oPC, nToken, PACT_BIND_LIST_ENC, jEncs);

        FeedPactDetail(oPC, nToken, sDemonId);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == PACT_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }
        if(sElem == PACT_BTN_SIGN)
        {
            PactHandleSign(oPC, nToken);
            return;
        }
        if(sElem == PACT_BTN_BREAK)
        {
            PactHandleBreak(oPC, nToken);
            return;
        }
    }
}

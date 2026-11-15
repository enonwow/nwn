#include "lib_mac"

// ----------------------------------------------------------------
// Bargain resolution helpers
// ----------------------------------------------------------------

void MacResolveBargainHP(object oPC, int nToken)
{
    int nBefore = MacGetProximity(oPC);
    int nAfter  = 25;

    // Permanently reduce Constitution — each point lowers max HP by roughly 1 per level.
    // Tagged so the bargain log can reference it; not removed on rest.
    effect eHP = TagEffect(
        EffectAbilityDecrease(ABILITY_CONSTITUTION, MAC_BARGAIN_HP_COST),
        "MAC_HP_DEBT");
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eHP, oPC);

    MacLogContract(oPC, MAC_CONTRACT_HP,
        "-" + IntToString(MAC_BARGAIN_HP_COST) + " Kondycja (max HP)",
        nBefore, nAfter);
    MacSetProximity(oPC, nAfter);
    MacApplyProximityEffects(oPC, nBefore, nAfter);

    SendMessageToPC(oPC,
        "[Danse Macabre] Zaciskasz pakt. Cos z ciebie odpada — sila zyciowa, krew, iskra.\n"
        "Smierc cofa sie. Na razie.");

    MacShowMainView(oPC, nToken);
}

void MacResolveBargainGold(object oPC, int nToken)
{
    int nGold = GetGold(oPC);
    if(nGold < MAC_BARGAIN_GOLD_COST)
    {
        SendMessageToPC(oPC,
            "[Danse Macabre] Smierc podnosi reke. \"Nie masz czym zaplacic.\"");
        return;
    }

    int nBefore = MacGetProximity(oPC);
    int nAfter  = 15;

    AssignCommand(oPC, TakeGoldFromCreature(MAC_BARGAIN_GOLD_COST, oPC, TRUE));
    MacLogContract(oPC, MAC_CONTRACT_GOLD,
        "-" + IntToString(MAC_BARGAIN_GOLD_COST) + " zlota",
        nBefore, nAfter);
    MacSetProximity(oPC, nAfter);
    MacApplyProximityEffects(oPC, nBefore, nAfter);

    SendMessageToPC(oPC,
        "[Danse Macabre] Zloto znika z sakwy. Smierc milczy i odchodzi.");

    MacShowMainView(oPC, nToken);
}

void MacResolveBargainXP(object oPC, int nToken)
{
    int nXP    = GetXP(oPC);
    int nXPCut = nXP * MAC_BARGAIN_XP_PCT / 100;
    if(nXPCut < 1) nXPCut = 1;

    int nNewXP  = nXP - nXPCut;
    if(nNewXP < 0) nNewXP = 0;

    int nBefore = MacGetProximity(oPC);
    int nAfter  = 20;

    SetXP(oPC, nNewXP);
    MacLogContract(oPC, MAC_CONTRACT_XP,
        "-" + IntToString(nXPCut) + " PD",
        nBefore, nAfter);
    MacSetProximity(oPC, nAfter);
    MacApplyProximityEffects(oPC, nBefore, nAfter);

    SendMessageToPC(oPC,
        "[Danse Macabre] Lata doswiadczen bladna. Cos, czego juz nie odzyskasz.\n"
        "Smierc skinela glowa i znikla.");

    MacShowMainView(oPC, nToken);
}

void MacResolveBargainMemory(object oPC, int nToken, string sMemory)
{
    if(sMemory == "") return;

    int nBefore = MacGetProximity(oPC);
    int nAfter  = 40;

    MacLogContract(oPC, MAC_CONTRACT_MEMORY, sMemory, nBefore, nAfter);
    MacSetProximity(oPC, nAfter);
    MacApplyProximityEffects(oPC, nBefore, nAfter);

    SendMessageToPC(oPC,
        "[Danse Macabre] Wspomnienie unosi sie z ciebie jak dym. Juz go nie czujesz.\n"
        "Smierc bierze je i odchodzi bez slowa.");

    MacShowMainView(oPC, nToken);
}

void MacResolveBargainRefuse(object oPC, int nToken)
{
    int nBefore = MacGetProximity(oPC);
    int nAfter  = 70;

    // Painful necrotic burst (2d8 + 2d8 delayed)
    effect eDmg1 = EffectDamage(d8(2), DAMAGE_TYPE_NEGATIVE);
    effect eDmg2 = EffectDamage(d8(2), DAMAGE_TYPE_NEGATIVE);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, eDmg1, oPC);
    DelayCommand(1.5, ApplyEffectToObject(DURATION_TYPE_INSTANT, eDmg2, oPC));

    MacLogContract(oPC, MAC_CONTRACT_REFUSED, "Odmowa", nBefore, nAfter);
    MacSetProximity(oPC, nAfter);
    MacApplyProximityEffects(oPC, nBefore, nAfter);

    SendMessageToPC(oPC,
        "[Danse Macabre] \"Jeszcze wroce\" — slyszysz za soba, zanim ciemnosc sie rozprasza.");

    MacShowMainView(oPC, nToken);
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

    if(nToken != NuiFindWindow(oPC, MAC_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, MAC_LVAR_IN_BARGAIN);
        return;
    }

    if(sEvent == EVENT_TYPE_WATCH && sElem == MAC_BIND_BARG_MEM_TXT)
    {
        string sVal = JsonGetString(NuiGetBind(oPC, nToken, MAC_BIND_BARG_MEM_TXT));
        NuiSetBind(oPC, nToken, MAC_BIND_BARG_MEM_ENA, JsonBool(sVal != ""));
        SetLocalString(oPC, MAC_LVAR_MEM_DRAFT, sVal);
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK) return;

    if(sElem == MAC_BTN_CLOSE)
    {
        // Disallow closing during bargain — force a choice
        if(GetLocalInt(oPC, MAC_LVAR_IN_BARGAIN))
        {
            SendMessageToPC(oPC,
                "[Danse Macabre] Smierc nie pozwala ci uciesc. Musisz zdecydowac.");
            return;
        }
        NuiDestroy(oPC, nToken);
        return;
    }

    if(sElem == MAC_BTN_OFFER_HP)
    {
        MacResolveBargainHP(oPC, nToken);
        return;
    }
    if(sElem == MAC_BTN_OFFER_GOLD)
    {
        MacResolveBargainGold(oPC, nToken);
        return;
    }
    if(sElem == MAC_BTN_OFFER_XP)
    {
        MacResolveBargainXP(oPC, nToken);
        return;
    }
    if(sElem == MAC_BTN_OFFER_MEMORY)
    {
        string sMem = GetLocalString(oPC, MAC_LVAR_MEM_DRAFT);
        if(sMem == "")
            sMem = JsonGetString(NuiGetBind(oPC, nToken, MAC_BIND_BARG_MEM_TXT));
        MacResolveBargainMemory(oPC, nToken, sMem);
        return;
    }
    if(sElem == MAC_BTN_REFUSE)
    {
        MacResolveBargainRefuse(oPC, nToken);
        return;
    }
}

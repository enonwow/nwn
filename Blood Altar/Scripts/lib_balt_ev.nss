// lib_balt_ev.nss — Blood Altar: glowny handler eventow NUI
#include "lib_balt"

// ---------------------------------------------------------------
// Obsluga klikniecia "Zloz ofiare" dla danego indeksu
// ---------------------------------------------------------------

void BaltHandleSacrificeClick(object oPC, int nToken, int nIdx)
{
    string sAltarTag = GetLocalString(oPC, BALT_LVAR_ALTAR_TAG);
    if(sAltarTag == "") return;

    json jSacs = BaltGetSacrifices(sAltarTag);
    if(nIdx < 0 || nIdx >= JsonGetLength(jSacs)) return;
    json jSac = JsonArrayGet(jSacs, nIdx);

    int nCostType = JsonGetInt(JsonObjectGet(jSac, "cost_type"));
    int nCostVal  = JsonGetInt(JsonObjectGet(jSac, "cost_val"));
    int nCorrupt  = JsonGetInt(JsonObjectGet(jSac, "corrupt"));

    if(nCostType == 0)
    {
        // --- Ofiara zlotem ---
        if(GetGold(oPC) < nCostVal)
        {
            SendMessageToPC(oPC, "[Oltarz] Nie masz wystarczajaco zlota.");
            return;
        }
        AssignCommand(oPC, TakeGoldFromCreature(nCostVal, oPC, TRUE));

        BaltApplyBoon(oPC, jSac);
        int nNewCorr = BaltAddCorruption(oPC, nCorrupt);
        BaltLogSacrifice(oPC, sAltarTag, nIdx);
        BaltApplyCorruptionVFX(oPC, nNewCorr);
        BaltFeedWindow(oPC, nToken, sAltarTag);

        SendMessageToPC(oPC, "[Oltarz] Ofiara przyjeta. "
                      + JsonGetString(JsonObjectGet(jSac, "eff_desc")));

        if(nCorrupt > 0 && nNewCorr >= BALT_CORRUPT_HIGH)
            FloatingTextStringOnCreature(
                "Pieczen krwi pulsuje slabo... Mroczna moc sie budzi.", oPC, FALSE);
    }
    else if(nCostType == 1)
    {
        // --- Ofiara z przedmiotu: wejdz w tryb celowania ---
        // -1 = nieaktywny; sys_on_target.nss sprawdza ta wartosc
        SetLocalInt(oPC, BALT_LVAR_ITEM_IDX, nIdx);
        EnterTargetingMode(oPC, OBJECT_TYPE_ITEM);
        SendMessageToPC(oPC, "[Oltarz] Wybierz przedmiot z ekwipunku, ktory zostanie poswiecony.");
    }
    else if(nCostType == 2)
    {
        // --- Ofiara z krwi: sprawdz HP i pokaz potwierdzenie ---
        int nMaxHP  = GetMaxHitPoints(oPC);
        int nHPCost = nMaxHP * nCostVal / 100;
        if(nHPCost < 1) nHPCost = 1;

        if(GetCurrentHitPoints(oPC) <= nHPCost + 5)
        {
            SendMessageToPC(oPC, "[Oltarz] Zbyt malo zywotnosci. Smierc to nie ofiara.");
            return;
        }

        SetLocalInt(oPC, BALT_LVAR_PENDING_IDX, nIdx);
        SetLocalInt(oPC, BALT_LVAR_PENDING_HP,  nHPCost);
        BaltShowBloodConfirm(oPC, nHPCost, BaltGetAltarName(sAltarTag));
    }
}

// ---------------------------------------------------------------
// Wykonanie zatwierdzonej ofiary z krwi
// ---------------------------------------------------------------

void BaltHandleBloodConfirm(object oPC)
{
    int nIdx    = GetLocalInt(oPC, BALT_LVAR_PENDING_IDX);
    int nHPCost = GetLocalInt(oPC, BALT_LVAR_PENDING_HP);

    DeleteLocalInt(oPC, BALT_LVAR_PENDING_IDX);
    DeleteLocalInt(oPC, BALT_LVAR_PENDING_HP);

    string sAltarTag = GetLocalString(oPC, BALT_LVAR_ALTAR_TAG);
    json jSacs = BaltGetSacrifices(sAltarTag);
    if(nIdx < 0 || nIdx >= JsonGetLength(jSacs)) return;
    json jSac = JsonArrayGet(jSacs, nIdx);

    if(GetCurrentHitPoints(oPC) <= nHPCost + 5)
    {
        SendMessageToPC(oPC, "[Oltarz] Zbyt malo zywotnosci — ofiara niemozliwa.");
        return;
    }

    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectDamage(nHPCost, DAMAGE_TYPE_MAGICAL), oPC);

    BaltApplyBoon(oPC, jSac);

    int nCorrupt = JsonGetInt(JsonObjectGet(jSac, "corrupt"));
    int nNewCorr = BaltAddCorruption(oPC, nCorrupt);
    BaltLogSacrifice(oPC, sAltarTag, nIdx);
    BaltApplyCorruptionVFX(oPC, nNewCorr);

    int nToken = NuiFindWindow(oPC, BALT_WINDOW);
    if(nToken != 0)
        BaltFeedWindow(oPC, nToken, sAltarTag);

    SendMessageToPC(oPC, "[Oltarz] Krew zlożona. "
                  + JsonGetString(JsonObjectGet(jSac, "eff_desc")));

    if(nNewCorr >= BALT_CORRUPT_MAX)
        FloatingTextStringOnCreature(
            "Twoja dusza peka... Jestes narzedziem mroku.", oPC, FALSE);
    else if(nNewCorr >= BALT_CORRUPT_HIGH)
        FloatingTextStringOnCreature(
            "Pieczen krwi pulsuje mroczna moca...", oPC, FALSE);
}

// ---------------------------------------------------------------
// Glowny handler (skrypt NUI event)
// ---------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    // --- Popup potwierdzenia krwi ---
    if(nToken == NuiFindWindow(oPC, BALT_WIN_CONFIRM))
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == BALT_BTN_CONFIRM)
            {
                NuiDestroy(oPC, nToken);
                BaltHandleBloodConfirm(oPC);
            }
            else if(sElem == BALT_BTN_CANCEL)
            {
                DeleteLocalInt(oPC, BALT_LVAR_PENDING_IDX);
                DeleteLocalInt(oPC, BALT_LVAR_PENDING_HP);
                NuiDestroy(oPC, nToken);
            }
        }
        return;
    }

    if(nToken != NuiFindWindow(oPC, BALT_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalString(oPC, BALT_LVAR_ALTAR_TAG);
        SetLocalInt(oPC, BALT_LVAR_ITEM_IDX, -1);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == BALT_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }
        if(sElem == BALT_BTN_SACRIFICE)
        {
            BaltHandleSacrificeClick(oPC, nToken, nIdx);
            return;
        }
    }
}

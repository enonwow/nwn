#include "lib_slm_def"

void OpenSlmWindow(object oPC);
void SwapToForgeView(object oPC, int nToken);
void SwapToIncanView(object oPC, int nToken);
void FeedSlmForge(object oPC, int nToken);
void FeedSlmIncan(object oPC, int nToken);

// ----------------------------------------------------------------
// Effect helpers
// ----------------------------------------------------------------

int SlmGetDamageType(int nElem)
{
    switch(nElem)
    {
        case SLM_ELEM_FIRE:    return DAMAGE_TYPE_FIRE;
        case SLM_ELEM_ICE:     return DAMAGE_TYPE_COLD;
        case SLM_ELEM_SHADOW:  return DAMAGE_TYPE_NEGATIVE;
        case SLM_ELEM_LIGHT:   return DAMAGE_TYPE_POSITIVE;
        case SLM_ELEM_THUNDER: return DAMAGE_TYPE_ELECTRICAL;
        case SLM_ELEM_VOID:    return DAMAGE_TYPE_MAGICAL;
    }
    return DAMAGE_TYPE_MAGICAL;
}

int SlmGetImpactVFX(int nElem)
{
    switch(nElem)
    {
        case SLM_ELEM_FIRE:    return VFX_IMP_FLAME_M;
        case SLM_ELEM_ICE:     return VFX_IMP_FROST_S;
        case SLM_ELEM_SHADOW:  return VFX_IMP_NEGATIVE_ENERGY;
        case SLM_ELEM_LIGHT:   return VFX_IMP_HOLY_AID;
        case SLM_ELEM_THUNDER: return VFX_IMP_LIGHTNING_M;
        case SLM_ELEM_VOID:    return VFX_IMP_DOOM;
    }
    return VFX_IMP_MAGICAL_VISION;
}

// Rolls nTier d8s, adds extra d6s at tier 3
int SlmRollDamage(int nTier)
{
    int nDmg = 0;
    int i;
    for(i = 0; i < nTier; i++)
        nDmg += d8();
    if(nTier >= 3)
        nDmg += d6() + d6();
    return nDmg < 1 ? 1 : nDmg;
}

// ----------------------------------------------------------------
// Effect descriptions (Polish flavor)
// ----------------------------------------------------------------

string SlmGetEffectDescription(int nElem, int nTarget, int nPower)
{
    if(nElem == 0 || nTarget == 0 || nPower == 0)
        return "Wybierz słowo Żywiołu, Celu i Mocy, by ujrzeć naturę inkantacji.";

    int nTier  = SlmGetTier(nPower);
    string sCost  = "[ Koszt: " + IntToString(SlmGetHPCost(nPower)) + " PŻ ]";
    string sEffect = "";

    if(nTarget == SLM_TARGET_SELF)
    {
        switch(nElem)
        {
            case SLM_ELEM_FIRE:
                sEffect = "Płomień opasuje ciało jak wierne psisko. Każdy, kto uderzy, spali się o " + IntToString(nTier) + "k4 punktów ognia.";
                break;
            case SLM_ELEM_ICE:
                sEffect = "Kora lodu chroni skórę. Redukujesz obrażenia od zimna o " + IntToString(nTier * 5) + " pkt przez " + IntToString(nTier * 30) + " sekund.";
                break;
            case SLM_ELEM_SHADOW:
                sEffect = "Mrok nocy pochłania sylwetkę. Stajesz się niewidzialny na " + IntToString(nTier * 12) + " sekund.";
                break;
            case SLM_ELEM_LIGHT:
                sEffect = "Ciepło świętego ognia przenika rany. Odzyskujesz " + IntToString(nTier) + "k8 punktów życia.";
                break;
            case SLM_ELEM_THUNDER:
                sEffect = "Błyskawica przepływa przez kości. Prędkość wzrasta o " + IntToString(nTier * 30 > 99 ? 99 : nTier * 30) + "% na " + IntToString(nTier * 20) + " sekund.";
                break;
            case SLM_ELEM_VOID:
                sEffect = "Dłoń czernieje jak smoła. Następny cios wysysa połowę zadanych obrażeń jako własne życie. Znika po " + IntToString(nTier * 15) + " sekundach.";
                break;
        }
    }
    else if(nTarget == SLM_TARGET_ENEMY)
    {
        string sDice = IntToString(nTier) + "k8";
        switch(nElem)
        {
            case SLM_ELEM_FIRE:    sEffect = "Kula ognia trawi wroga — " + sDice + " obrażeń ogniem."; break;
            case SLM_ELEM_ICE:     sEffect = "Lodowe ostrza szczypią ciało — " + sDice + " obrażeń zimnem i spowolnienie na " + IntToString(nTier * 6) + " sekund."; break;
            case SLM_ELEM_SHADOW:  sEffect = "Cień kradnie wzrok — " + sDice + " obrażeń ujemną energią i ślepota na " + IntToString(nTier * 6) + " sekund."; break;
            case SLM_ELEM_LIGHT:   sEffect = "Święte światło spala duszę — " + sDice + " obrażeń; podwójne przeciwko nieumarłym."; break;
            case SLM_ELEM_THUNDER: sEffect = "Grom miażdży kości — " + sDice + " obrażeń elektrycznych" + (nTier >= 2 ? " i knockdown." : "."); break;
            case SLM_ELEM_VOID:    sEffect = "Próżnia pije żywotność — " + sDice + " obrażeń; leczysz się połową zadanych."; break;
        }
    }
    else if(nTarget == SLM_TARGET_ALLY)
    {
        switch(nElem)
        {
            case SLM_ELEM_FIRE:    sEffect = "Ognista krew pompuje się w żyłach — sojusznik zyskuje +" + IntToString(nTier) + " do rzutów na trafienie na " + IntToString(nTier * 20) + " sekund."; break;
            case SLM_ELEM_ICE:     sEffect = "Pancerz z lodu chroni sojusznika — +" + IntToString(nTier * 2) + " do KP na " + IntToString(nTier * 20) + " sekund."; break;
            case SLM_ELEM_SHADOW:  sEffect = "Płaszcz nocy owija sprzymierzeńca — " + IntToString(nTier * 10) + "% ukrycia na " + IntToString(nTier * 20) + " sekund."; break;
            case SLM_ELEM_LIGHT:   sEffect = "Ręka bożego błogosławieństwa — leczy " + IntToString(nTier * 2) + "k8 PŻ."; break;
            case SLM_ELEM_THUNDER: sEffect = "Piorunowe nogi niosą sojusznika naprzód — prędkość wzrasta o " + IntToString(nTier * 30 > 99 ? 99 : nTier * 30) + "% na " + IntToString(nTier * 20) + " sekund."; break;
            case SLM_ELEM_VOID:    sEffect = "Kradziona żywotność wzmacnia sojusznika — " + IntToString(nTier * 10) + " tymczasowych PŻ na " + IntToString(nTier * 20) + " sekund."; break;
        }
    }
    else if(nTarget == SLM_TARGET_AREA)
    {
        int nAoETier = nTier > 1 ? nTier - 1 : 1;
        float fRad   = 3.0 + IntToFloat(nTier) * 2.0;
        string sDice = IntToString(nAoETier) + "k8";
        string sRad  = "w promieniu " + IntToString(FloatToInt(fRad)) + "m";
        switch(nElem)
        {
            case SLM_ELEM_FIRE:    sEffect = "Ognisty wybuch niszczy wszystkich wrogów " + sRad + " — " + sDice + " obrażeń."; break;
            case SLM_ELEM_ICE:     sEffect = "Lodowa burza zamraża " + sRad + " — " + sDice + " obrażeń i spowolnienie wrogów."; break;
            case SLM_ELEM_SHADOW:  sEffect = "Fala mroku gasi wzrok " + sRad + " — " + sDice + " obrażeń i ślepota."; break;
            case SLM_ELEM_LIGHT:   sEffect = "Błysk świętości oślepia mroczne dusze " + sRad + " — " + sDice + " obrażeń (podwójne vs nieumarłych)."; break;
            case SLM_ELEM_THUNDER: sEffect = "Burzowy grzmot przewraca wszystkich " + sRad + " — " + sDice + " obrażeń i knockdown."; break;
            case SLM_ELEM_VOID:    sEffect = "Wybuch pustki pochłania żywotność " + sRad + " — " + sDice + " obrażeń magicznych."; break;
        }
    }

    return sCost + "\n\n" + sEffect;
}

string SlmGetCastFlavorText(int nElem, int nPower)
{
    string sPfx;
    switch(nPower)
    {
        case SLM_POWER_WHISPER: sPfx = "*usta ledwo poruszają się*"; break;
        case SLM_POWER_VOICE:   sPfx = "*głos drżący od skupienia*"; break;
        case SLM_POWER_SCREAM:  sPfx = "*krzyk rozrywa powietrze*"; break;
        default: sPfx = "*słowo mocy*";
    }
    switch(nElem)
    {
        case SLM_ELEM_FIRE:    return sPfx + " — Ogień! Pochłoń to, co widzę!";
        case SLM_ELEM_ICE:     return sPfx + " — Lód! Zetni i skuj!";
        case SLM_ELEM_SHADOW:  return sPfx + " — Cień... opada. Pochłoń.";
        case SLM_ELEM_LIGHT:   return sPfx + " — Światło! Objaw moc swoją!";
        case SLM_ELEM_THUNDER: return sPfx + " — Piorun! Rozniesie cię w proch!";
        case SLM_ELEM_VOID:    return sPfx + " — ...Mrok. Przejdź przeze mnie.";
    }
    return sPfx;
}

// ----------------------------------------------------------------
// Spell application
// ----------------------------------------------------------------

void SlmApplySelfEffect(object oPC, int nElem, int nTier)
{
    float fDur = IntToFloat(nTier * 20);
    switch(nElem)
    {
        case SLM_ELEM_FIRE:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectDamageShield(nTier * 2, DAMAGE_BONUS_1d4, DAMAGE_TYPE_FIRE), oPC, fDur);
            break;
        case SLM_ELEM_ICE:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectDamageResistance(DAMAGE_TYPE_COLD, nTier * 5, 0), oPC, fDur + 10.0);
            break;
        case SLM_ELEM_SHADOW:
        {
            float fInvDur = IntToFloat(nTier * 12);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectInvisibility(INVISIBILITY_TYPE_NORMAL), oPC, fInvDur);
            break;
        }
        case SLM_ELEM_LIGHT:
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectHeal(d8() * nTier), oPC);
            break;
        case SLM_ELEM_THUNDER:
        {
            int nSpd = nTier * 30;
            if(nSpd > 99) nSpd = 99;
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectMovementSpeedIncrease(nSpd), oPC, fDur);
            break;
        }
        case SLM_ELEM_VOID:
            // Mark for drain-on-hit (checked in OnPhysicalAttacked if wired)
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectAttackIncrease(nTier * 2, ATTACK_BONUS_MISC), oPC, fDur * 0.75);
            SetLocalInt(oPC, "SLM_VOID_DRAIN", nTier);
            SendMessageToPC(oPC, "[Słowa Mocy] Dłoń spowita jest mrokiem — następny cios wysysa żywotność.");
            break;
    }
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(SlmGetImpactVFX(nElem)), oPC);
}

void SlmApplyEnemyEffect(object oPC, int nElem, int nTier, object oTarget)
{
    if(!GetIsObjectValid(oTarget) || !GetIsEnemy(oTarget, oPC))
    {
        SendMessageToPC(oPC, "[Słowa Mocy] Cel musi być wrogiem.");
        return;
    }

    float fDur = IntToFloat(nTier * 6);
    int nDmg   = SlmRollDamage(nTier);
    int nDmgT  = SlmGetDamageType(nElem);

    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(SlmGetImpactVFX(nElem)), oTarget);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDamage(nDmg, nDmgT), oTarget);

    switch(nElem)
    {
        case SLM_ELEM_ICE:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectMovementSpeedDecrease(50), oTarget, fDur);
            break;
        case SLM_ELEM_SHADOW:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectBlindness(), oTarget, fDur);
            break;
        case SLM_ELEM_LIGHT:
            if(GetRacialType(oTarget) == RACIAL_TYPE_UNDEAD)
                ApplyEffectToObject(DURATION_TYPE_INSTANT,
                    EffectDamage(nDmg, DAMAGE_TYPE_POSITIVE), oTarget);
            break;
        case SLM_ELEM_THUNDER:
            if(nTier >= 2)
                ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                    EffectKnockdown(), oTarget, fDur * 0.5);
            break;
        case SLM_ELEM_VOID:
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectHeal(nDmg / 2), oPC);
            break;
    }
}

void SlmApplyAllyEffect(object oPC, int nElem, int nTier, object oTarget)
{
    if(!GetIsObjectValid(oTarget))
    {
        SendMessageToPC(oPC, "[Słowa Mocy] Cel jest nieprawidłowy.");
        return;
    }

    float fDur = IntToFloat(nTier * 20);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(SlmGetImpactVFX(nElem)), oTarget);

    switch(nElem)
    {
        case SLM_ELEM_FIRE:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectAttackIncrease(nTier, ATTACK_BONUS_ONHAND), oTarget, fDur);
            break;
        case SLM_ELEM_ICE:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectACIncrease(nTier * 2, AC_DODGE_BONUS, AC_VS_DAMAGE_TYPE_ALL), oTarget, fDur);
            break;
        case SLM_ELEM_SHADOW:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectConcealment(nTier * 10), oTarget, fDur);
            break;
        case SLM_ELEM_LIGHT:
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectHeal(d8() * nTier * 2), oTarget);
            break;
        case SLM_ELEM_THUNDER:
        {
            int nSpd = nTier * 30;
            if(nSpd > 99) nSpd = 99;
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectMovementSpeedIncrease(nSpd), oTarget, fDur);
            break;
        }
        case SLM_ELEM_VOID:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectTemporaryHitpoints(nTier * 10), oTarget, fDur);
            break;
    }
}

void SlmApplyAreaEffect(object oPC, int nElem, int nTier)
{
    float fRad = 3.0 + IntToFloat(nTier) * 2.0;
    float fDur = IntToFloat(nTier * 6);
    int nAoETier = nTier > 1 ? nTier - 1 : 1;
    int nDmgT  = SlmGetDamageType(nElem);
    location lLoc = GetLocation(oPC);

    object oTarget = GetFirstObjectInShape(SHAPE_SPHERE, fRad, lLoc, TRUE, OBJECT_TYPE_CREATURE);
    while(GetIsObjectValid(oTarget))
    {
        if(GetIsEnemy(oTarget, oPC))
        {
            int nDmg = SlmRollDamage(nAoETier);
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectVisualEffect(SlmGetImpactVFX(nElem)), oTarget);
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectDamage(nDmg, nDmgT), oTarget);

            switch(nElem)
            {
                case SLM_ELEM_ICE:
                    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                        EffectMovementSpeedDecrease(30), oTarget, fDur);
                    break;
                case SLM_ELEM_SHADOW:
                    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                        EffectBlindness(), oTarget, fDur * 0.5);
                    break;
                case SLM_ELEM_LIGHT:
                    if(GetRacialType(oTarget) == RACIAL_TYPE_UNDEAD)
                        ApplyEffectToObject(DURATION_TYPE_INSTANT,
                            EffectDamage(nDmg, DAMAGE_TYPE_POSITIVE), oTarget);
                    break;
                case SLM_ELEM_THUNDER:
                    if(nTier >= 2)
                        ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                            EffectKnockdown(), oTarget, 3.0);
                    break;
            }
        }
        oTarget = GetNextObjectInShape(SHAPE_SPHERE, fRad, lLoc, TRUE, OBJECT_TYPE_CREATURE);
    }
}

void SlmApplyEffect(object oPC, int nElem, int nTarget, int nPower, object oSelectedTarget)
{
    int nHPCost = SlmGetHPCost(nPower);
    int nHP     = GetCurrentHitPoints(oPC);

    if(nHP <= nHPCost + 1)
    {
        SendMessageToPC(oPC, "[Słowa Mocy] Zbyt mało sił życiowych, by wygłosić tę inkantację.");
        return;
    }

    // Check that the character knows all three words
    if(!SlmKnowsWord(oPC, nElem) || !SlmKnowsWord(oPC, nTarget) || !SlmKnowsWord(oPC, nPower))
    {
        SendMessageToPC(oPC, "[Słowa Mocy] Nie znasz wszystkich słów tej inkantacji.");
        return;
    }

    int nTier = SlmGetTier(nPower);

    // Deduct HP cost
    effect eHurt = EffectDamage(nHPCost, DAMAGE_TYPE_MAGICAL);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, eHurt, oPC);

    // Floating cast message
    FloatingTextStringOnCreature(SlmGetCastFlavorText(nElem, nPower), oPC, FALSE);

    switch(nTarget)
    {
        case SLM_TARGET_SELF:  SlmApplySelfEffect(oPC, nElem, nTier);                          break;
        case SLM_TARGET_ENEMY: SlmApplyEnemyEffect(oPC, nElem, nTier, oSelectedTarget);        break;
        case SLM_TARGET_ALLY:  SlmApplyAllyEffect(oPC, nElem, nTier, oSelectedTarget);         break;
        case SLM_TARGET_AREA:  SlmApplyAreaEffect(oPC, nElem, nTier);                          break;
    }
}

// ----------------------------------------------------------------
// NUI — Forge view layout
// ----------------------------------------------------------------

json BuildSlmForgeView(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 32.0);
    float fLblH = GetNuiScaleDimension(oPC, 22.0);
    float fPreH = GetNuiScaleDimension(oPC, 150.0);
    float fComW = GetNuiScaleDimension(oPC, 220.0);
    float fComH = GetNuiScaleDimension(oPC, 30.0);
    float fSlotW = GetNuiScaleDimension(oPC, 60.0);

    // -- Element combo --
    json jElemLbl = NuiLabel(JsonString("ŻYWIOŁ:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jElemLbl = NuiHeight(jElemLbl, fLblH);

    json jElemEntries = JsonArray();
    jElemEntries = JsonArrayInsert(jElemEntries, NuiComboEntry("— wybierz —", 0));
    jElemEntries = JsonArrayInsert(jElemEntries, NuiComboEntry("Ogień",       SLM_ELEM_FIRE));
    jElemEntries = JsonArrayInsert(jElemEntries, NuiComboEntry("Lód",         SLM_ELEM_ICE));
    jElemEntries = JsonArrayInsert(jElemEntries, NuiComboEntry("Cień",        SLM_ELEM_SHADOW));
    jElemEntries = JsonArrayInsert(jElemEntries, NuiComboEntry("Światło",     SLM_ELEM_LIGHT));
    jElemEntries = JsonArrayInsert(jElemEntries, NuiComboEntry("Piorun",      SLM_ELEM_THUNDER));
    jElemEntries = JsonArrayInsert(jElemEntries, NuiComboEntry("Mrok",        SLM_ELEM_VOID));
    json jElemCombo = NuiCombo(jElemEntries, NuiBind(SLM_BIND_ELEM_SEL));
    jElemCombo = NuiWidth(jElemCombo, fComW);
    jElemCombo = NuiHeight(jElemCombo, fComH);

    json jElemRow = JsonArray();
    jElemRow = JsonArrayInsert(jElemRow, jElemLbl);
    jElemRow = JsonArrayInsert(jElemRow, jElemCombo);
    jElemRow = JsonArrayInsert(jElemRow, NuiSpacer());

    // -- Target combo --
    json jTgtLbl = NuiLabel(JsonString("CEL:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTgtLbl = NuiWidth(jTgtLbl, GetNuiScaleDimension(oPC, 80.0));
    jTgtLbl = NuiHeight(jTgtLbl, fLblH);

    json jTgtEntries = JsonArray();
    jTgtEntries = JsonArrayInsert(jTgtEntries, NuiComboEntry("— wybierz —", 0));
    jTgtEntries = JsonArrayInsert(jTgtEntries, NuiComboEntry("Wróg",         SLM_TARGET_ENEMY));
    jTgtEntries = JsonArrayInsert(jTgtEntries, NuiComboEntry("Sojusznik",    SLM_TARGET_ALLY));
    jTgtEntries = JsonArrayInsert(jTgtEntries, NuiComboEntry("Siebie",       SLM_TARGET_SELF));
    jTgtEntries = JsonArrayInsert(jTgtEntries, NuiComboEntry("Przestrzeń",   SLM_TARGET_AREA));
    json jTgtCombo = NuiCombo(jTgtEntries, NuiBind(SLM_BIND_TGT_SEL));
    jTgtCombo = NuiWidth(jTgtCombo, fComW);
    jTgtCombo = NuiHeight(jTgtCombo, fComH);

    json jTgtRow = JsonArray();
    jTgtRow = JsonArrayInsert(jTgtRow, jTgtLbl);
    jTgtRow = JsonArrayInsert(jTgtRow, jTgtCombo);
    jTgtRow = JsonArrayInsert(jTgtRow, NuiSpacer());

    // -- Power combo --
    json jPowLbl = NuiLabel(JsonString("MOC:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jPowLbl = NuiWidth(jPowLbl, GetNuiScaleDimension(oPC, 80.0));
    jPowLbl = NuiHeight(jPowLbl, fLblH);

    json jPowEntries = JsonArray();
    jPowEntries = JsonArrayInsert(jPowEntries, NuiComboEntry("— wybierz —", 0));
    jPowEntries = JsonArrayInsert(jPowEntries, NuiComboEntry("Szept",  SLM_POWER_WHISPER));
    jPowEntries = JsonArrayInsert(jPowEntries, NuiComboEntry("Głos",   SLM_POWER_VOICE));
    jPowEntries = JsonArrayInsert(jPowEntries, NuiComboEntry("Krzyk",  SLM_POWER_SCREAM));
    json jPowCombo = NuiCombo(jPowEntries, NuiBind(SLM_BIND_POW_SEL));
    jPowCombo = NuiWidth(jPowCombo, fComW);
    jPowCombo = NuiHeight(jPowCombo, fComH);

    json jPowRow = JsonArray();
    jPowRow = JsonArrayInsert(jPowRow, jPowLbl);
    jPowRow = JsonArrayInsert(jPowRow, jPowCombo);
    jPowRow = JsonArrayInsert(jPowRow, NuiSpacer());

    // -- Preview text --
    json jPreview = NuiGroup(
        NuiText(NuiBind(SLM_BIND_PREVIEW), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jPreview = NuiHeight(jPreview, fPreH);

    // -- Cost label --
    json jCostLbl = NuiLabel(NuiBind(SLM_BIND_COST_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCostLbl = NuiHeight(jCostLbl, fLblH);

    // -- Save-slot buttons (numbered 1..SLM_MAX_SLOTS) + Forge button --
    json jSlotRow = JsonArray();
    json jSlotsLbl = NuiLabel(JsonString("Slot:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSlotsLbl = NuiWidth(jSlotsLbl, GetNuiScaleDimension(oPC, 40.0));
    jSlotRow = JsonArrayInsert(jSlotRow, jSlotsLbl);

    int i;
    for(i = 0; i < SLM_MAX_SLOTS; i++)
    {
        string sSlotId = SLM_BTN_SLOT + IntToString(i);
        json jSlotBtn = NuiButton(NuiBind(SLM_BIND_SLOT_LBL + IntToString(i)));
        jSlotBtn = NuiId(jSlotBtn, sSlotId);
        jSlotBtn = NuiWidth(jSlotBtn, fSlotW);
        jSlotBtn = NuiHeight(jSlotBtn, fBtnH);
        jSlotBtn = NuiEncouraged(jSlotBtn, NuiBind(SLM_BIND_SLOT_ENC + IntToString(i)));
        jSlotRow = JsonArrayInsert(jSlotRow, jSlotBtn);
    }

    json jForgeBtn = NuiButton(JsonString("Zakuć Inkantację"));
    jForgeBtn = NuiId(jForgeBtn, SLM_BTN_FORGE);
    jForgeBtn = NuiEnabled(jForgeBtn, NuiBind(SLM_BIND_FORGE_ENA));
    jForgeBtn = NuiHeight(jForgeBtn, fBtnH);
    jSlotRow = JsonArrayInsert(jSlotRow, NuiSpacer());
    jSlotRow = JsonArrayInsert(jSlotRow, jForgeBtn);

    // -- Assemble column --
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jElemRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jTgtRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jPowRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jPreview);
    jCol = JsonArrayInsert(jCol, jCostLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jSlotRow));

    return NuiCol(jCol);
}

// ----------------------------------------------------------------
// NUI — Incantations list view
// ----------------------------------------------------------------

json BuildSlmIncanView(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 32.0);
    float fRowH = GetNuiScaleDimension(oPC, 30.0);
    float fListH= GetNuiScaleDimension(oPC, 320.0);
    float fNameW= GetNuiScaleDimension(oPC, 260.0);
    float fCostW= GetNuiScaleDimension(oPC, 80.0);

    // List template: name | cost | desc
    json jNameLbl = NuiLabel(NuiBind(SLM_BIND_INCAN_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiWidth(jNameLbl, fNameW);
    json jCostLbl = NuiLabel(NuiBind(SLM_BIND_INCAN_COST), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jCostLbl = NuiWidth(jCostLbl, fCostW);
    json jDescLbl = NuiLabel(NuiBind(SLM_BIND_INCAN_DESC), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jCellCols = JsonArray();
    jCellCols = JsonArrayInsert(jCellCols, jNameLbl);
    jCellCols = JsonArrayInsert(jCellCols, jCostLbl);
    jCellCols = JsonArrayInsert(jCellCols, jDescLbl);

    json jCell = NuiGroup(NuiRow(jCellCols), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, SLM_BTN_INCAN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(SLM_BIND_INCAN_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(SLM_BIND_INCAN_CNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // Bottom button row
    json jInvokeBtn = NuiButton(JsonString("Przywołaj"));
    jInvokeBtn = NuiId(jInvokeBtn, SLM_BTN_INVOKE);
    jInvokeBtn = NuiEnabled(jInvokeBtn, NuiBind(SLM_BIND_INVOKE_ENA));
    jInvokeBtn = NuiWidth(jInvokeBtn, GetNuiScaleDimension(oPC, 140.0));
    jInvokeBtn = NuiHeight(jInvokeBtn, fBtnH);

    json jEraseBtn = NuiButton(JsonString("Wymaż"));
    jEraseBtn = NuiId(jEraseBtn, SLM_BTN_ERASE);
    jEraseBtn = NuiEnabled(jEraseBtn, NuiBind(SLM_BIND_ERASE_ENA));
    jEraseBtn = NuiWidth(jEraseBtn, GetNuiScaleDimension(oPC, 100.0));
    jEraseBtn = NuiHeight(jEraseBtn, fBtnH);

    json jBackBtn = NuiButton(JsonString("Kuźnia Słów"));
    jBackBtn = NuiId(jBackBtn, SLM_BTN_BACK_FORGE);
    jBackBtn = NuiWidth(jBackBtn, GetNuiScaleDimension(oPC, 140.0));
    jBackBtn = NuiHeight(jBackBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jInvokeBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jEraseBtn);
    jBotRow = JsonArrayInsert(jBotRow, jBackBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    return NuiCol(jCol);
}

// ----------------------------------------------------------------
// Window create / open / swap
// ----------------------------------------------------------------

void OpenSlmWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, SLM_WINDOW);
    if(nToken != 0)
    {
        SwapToForgeView(oPC, nToken);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - GetNuiScaleDimension(oPC, SLM_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - GetNuiScaleDimension(oPC, SLM_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, SLM_W), GetNuiScaleDimension(oPC, SLM_H));

    float fBtnH = GetNuiScaleDimension(oPC, 30.0);

    // Top bar: title | [Inkantacje] tab | [X] close
    json jTitle = NuiLabel(JsonString("Słowa Mocy"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jTabIncan = NuiButton(JsonString("Inkantacje"));
    jTabIncan = NuiId(jTabIncan, SLM_BTN_TAB_INCAN);
    jTabIncan = NuiWidth(jTabIncan, GetNuiScaleDimension(oPC, 120.0));
    jTabIncan = NuiHeight(jTabIncan, fBtnH);

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, SLM_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitle);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jTabIncan);
    jTopRow = JsonArrayInsert(jTopRow, jCloseBtn);

    json jSwapGrp = NuiGroup(BuildSlmForgeView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, SLM_GRP_SWAP);

    json jRootChildren = JsonArray();
    jRootChildren = JsonArrayInsert(jRootChildren, NuiRow(jTopRow));
    jRootChildren = JsonArrayInsert(jRootChildren, jSwapGrp);

    json jWin = NuiWindow(
        NuiCol(jRootChildren),
        JsonBool(FALSE),
        NuiBind(SLM_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, SLM_WINDOW, SLM_EV_SCRIPT);
    NuiSetBind(oPC, nToken, SLM_WIN_GEOM, jGeom);

    SetLocalInt(oPC, SLM_LVAR_VIEW, 0);
    SetLocalInt(oPC, SLM_LVAR_SEL_SLOT, 0);
    SetLocalInt(oPC, SLM_LVAR_SEL_INCAN, -1);

    SwapToForgeView(oPC, nToken);
}

void SwapToForgeView(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, SLM_GRP_SWAP, BuildSlmForgeView(oPC));
    SetLocalInt(oPC, SLM_LVAR_VIEW, 0);

    NuiSetBind(oPC, nToken, SLM_BIND_ELEM_SEL, JsonInt(0));
    NuiSetBind(oPC, nToken, SLM_BIND_TGT_SEL,  JsonInt(0));
    NuiSetBind(oPC, nToken, SLM_BIND_POW_SEL,  JsonInt(0));

    NuiSetBindWatch(oPC, nToken, SLM_BIND_ELEM_SEL, TRUE);
    NuiSetBindWatch(oPC, nToken, SLM_BIND_TGT_SEL,  TRUE);
    NuiSetBindWatch(oPC, nToken, SLM_BIND_POW_SEL,  TRUE);

    FeedSlmForge(oPC, nToken);
}

void SwapToIncanView(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, SLM_GRP_SWAP, BuildSlmIncanView(oPC));
    SetLocalInt(oPC, SLM_LVAR_VIEW, 1);
    SetLocalInt(oPC, SLM_LVAR_SEL_INCAN, -1);
    FeedSlmIncan(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed functions
// ----------------------------------------------------------------

void FeedSlmForge(object oPC, int nToken)
{
    int nElem   = JsonGetInt(NuiGetBind(oPC, nToken, SLM_BIND_ELEM_SEL));
    int nTarget = JsonGetInt(NuiGetBind(oPC, nToken, SLM_BIND_TGT_SEL));
    int nPower  = JsonGetInt(NuiGetBind(oPC, nToken, SLM_BIND_POW_SEL));

    NuiSetBind(oPC, nToken, SLM_BIND_PREVIEW,   JsonString(SlmGetEffectDescription(nElem, nTarget, nPower)));
    NuiSetBind(oPC, nToken, SLM_BIND_FORGE_ENA, JsonBool(nElem != 0 && nTarget != 0 && nPower != 0));

    string sCostLbl = nPower != 0
        ? "Koszt przywołania: " + IntToString(SlmGetHPCost(nPower)) + " PŻ"
        : "";
    NuiSetBind(oPC, nToken, SLM_BIND_COST_LBL, JsonString(sCostLbl));

    // Refresh slot buttons
    int nSelSlot = GetLocalInt(oPC, SLM_LVAR_SEL_SLOT);
    int i;
    for(i = 0; i < SLM_MAX_SLOTS; i++)
    {
        json jEntry = SlmGetIncantationBySlot(oPC, i);
        int bFilled = (JsonGetType(jEntry) != JSON_TYPE_NULL);
        NuiSetBind(oPC, nToken, SLM_BIND_SLOT_LBL + IntToString(i),
            JsonString(bFilled ? ("*" + IntToString(i + 1)) : IntToString(i + 1)));
        NuiSetBind(oPC, nToken, SLM_BIND_SLOT_ENC + IntToString(i), JsonBool(i == nSelSlot));
    }
}

void FeedSlmIncan(object oPC, int nToken)
{
    json jList   = SlmGetIncantations(oPC);
    int nCount   = JsonGetLength(jList);
    int nSelIdx  = GetLocalInt(oPC, SLM_LVAR_SEL_INCAN);

    json jNames = JsonArray();
    json jCosts = JsonArray();
    json jDescs = JsonArray();
    json jEncs  = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jEntry  = JsonArrayGet(jList, i);
        int nSlot    = JsonGetInt(JsonObjectGet(jEntry, "slot"));
        int nElem    = JsonGetInt(JsonObjectGet(jEntry, "elem"));
        int nTarget  = JsonGetInt(JsonObjectGet(jEntry, "target"));
        int nPower   = JsonGetInt(JsonObjectGet(jEntry, "power"));

        string sName = "[" + IntToString(nSlot + 1) + "] " + SlmGetIncantationName(nElem, nTarget, nPower);
        string sCost = IntToString(SlmGetHPCost(nPower)) + " PŻ";
        string sDesc = SlmGetTargetName(nTarget) + " — " + SlmGetElemName(nElem);

        jNames = JsonArrayInsert(jNames, JsonString(sName));
        jCosts = JsonArrayInsert(jCosts, JsonString(sCost));
        jDescs = JsonArrayInsert(jDescs, JsonString(sDesc));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(i == nSelIdx));
    }

    NuiSetBind(oPC, nToken, SLM_BIND_INCAN_NAME,  jNames);
    NuiSetBind(oPC, nToken, SLM_BIND_INCAN_COST,  jCosts);
    NuiSetBind(oPC, nToken, SLM_BIND_INCAN_DESC,  jDescs);
    NuiSetBind(oPC, nToken, SLM_BIND_INCAN_ENC,   jEncs);
    NuiSetBind(oPC, nToken, SLM_BIND_INCAN_CNT,   JsonInt(nCount));
    NuiSetBind(oPC, nToken, SLM_BIND_INVOKE_ENA,  JsonBool(nSelIdx >= 0 && nSelIdx < nCount));
    NuiSetBind(oPC, nToken, SLM_BIND_ERASE_ENA,   JsonBool(nSelIdx >= 0 && nSelIdx < nCount));
}

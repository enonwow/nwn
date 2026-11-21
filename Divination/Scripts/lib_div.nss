#include "lib_div_def"

// ================================================================
// Effect management
// ================================================================

void DivRemoveAllDivEffects(object oPC)
{
    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        effect eNext = GetNextEffect(oPC);
        if(GetStringLeft(GetEffectTag(e), 4) == "DIV_")
            RemoveEffect(oPC, e);
        e = eNext;
    }
}

void DivRemoveNegativeDivEffects(object oPC)
{
    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        effect eNext = GetNextEffect(oPC);
        string sTag = GetEffectTag(e);
        if(GetStringLeft(sTag, 4) == "DIV_")
        {
            int nId = StringToInt(GetStringRight(sTag,
                GetStringLength(sTag) - 4));
            if(DivCardIsNegative(nId))
                RemoveEffect(oPC, e);
        }
        e = eNext;
    }
}

// ================================================================
// Apply a single card's effects to oPC
// ================================================================

void DivApplySingleCardEffect(object oPC, int nCardId)
{
    string sTag = "DIV_" + IntToString(nCardId);
    effect eVFX = EffectVisualEffect(VFX_IMP_MAGIC_PROTECTION);

    switch(nCardId)
    {
        case DIV_CARD_FOOL:
        {
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAttackDecrease(1), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectACDecrease(1, AC_DODGE_BONUS), sTag), oPC);
            eVFX = EffectVisualEffect(VFX_IMP_DOOM);
            break;
        }
        case DIV_CARD_MAGICIAN:
        {
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAttackIncrease(1, ATTACK_BONUS_MISC), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSavingThrowIncrease(SAVING_THROW_ALL, 1), sTag), oPC);
            break;
        }
        case DIV_CARD_PRIESTESS:
        {
            int nHeal = GetMaxHitPoints(oPC) / 5;
            if(nHeal < 1) nHeal = 1;
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(nHeal), oPC);
            eVFX = EffectVisualEffect(VFX_IMP_HEALING_S);
            break;
        }
        case DIV_CARD_EMPRESS:
        {
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_CONSTITUTION, 2), sTag), oPC);
            break;
        }
        case DIV_CARD_EMPEROR:
        {
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_STRENGTH, 2), sTag), oPC);
            break;
        }
        case DIV_CARD_HIEROPHANT:
        {
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSavingThrowIncrease(SAVING_THROW_WILL, 2), sTag), oPC);
            break;
        }
        case DIV_CARD_LOVERS:
        {
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_CHARISMA, 2), sTag), oPC);
            break;
        }
        case DIV_CARD_CHARIOT:
        {
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSavingThrowIncrease(SAVING_THROW_REFLEX, 2), sTag), oPC);
            break;
        }
        case DIV_CARD_STRENGTH:
        {
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAttackIncrease(1, ATTACK_BONUS_MISC), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectDamageIncrease(1, DAMAGE_TYPE_BLUDGEONING), sTag), oPC);
            eVFX = EffectVisualEffect(VFX_IMP_MAGICAL_VISION);
            break;
        }
        case DIV_CARD_HERMIT:
        {
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSkillIncrease(SKILL_HIDE, 4), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSkillIncrease(SKILL_MOVE_SILENTLY, 4), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectUltravision(), sTag), oPC);
            eVFX = EffectVisualEffect(VFX_DUR_GHOSTLY_VISAGE);
            break;
        }
        case DIV_CARD_WHEEL:
        {
            int nRoll = d3();
            if(nRoll == 1)
            {
                GiveGoldToCreature(oPC, 100);
                FloatingTextStringOnCreature(
                    "Koło Fortuny daje ci 100 złotych monet!", oPC, FALSE);
            }
            else if(nRoll == 2)
            {
                int nHave = GetGold(oPC);
                int nTake = (nHave < 75) ? nHave : 75;
                AssignCommand(oPC, TakeGoldFromCreature(nTake, oPC, TRUE));
                FloatingTextStringOnCreature(
                    "Koło Fortuny bierze " + IntToString(nTake) + " złotych...",
                    oPC, FALSE);
            }
            else
            {
                FloatingTextStringOnCreature(
                    "Koło kręci się... i nic nie przynosi.", oPC, FALSE);
            }
            eVFX = EffectVisualEffect(VFX_IMP_PULSE_WIND);
            break;
        }
        case DIV_CARD_JUSTICE:
        {
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSkillIncrease(SKILL_DISCIPLINE, 2), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSkillIncrease(SKILL_PERSUADE, 2), sTag), oPC);
            break;
        }
        case DIV_CARD_HANGED:
        {
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAttackDecrease(1), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSavingThrowDecrease(SAVING_THROW_ALL, 1), sTag), oPC);
            eVFX = EffectVisualEffect(VFX_IMP_DOOM);
            break;
        }
        case DIV_CARD_DEATH:
        {
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectStunned(), oPC, 3.0);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityDecrease(ABILITY_CONSTITUTION, 2), sTag), oPC);
            eVFX = EffectVisualEffect(VFX_IMP_DOOM);
            break;
        }
        case DIV_CARD_TEMPERANCE:
        {
            // Remove negative curses first (effects + SQL)
            DivRemoveNegativeDivEffects(oPC);

            string sRaw = DivGetEffectsJson(oPC);
            json jOld   = JsonParse(sRaw);
            json jClean = JsonArray();
            int nC = JsonGetLength(jOld);
            int i;
            for(i = 0; i < nC; i++)
            {
                json jE = JsonArrayGet(jOld, i);
                int nCId = JsonGetInt(JsonObjectGet(jE, "card_id"));
                if(!DivCardIsNegative(nCId))
                    jClean = JsonArrayInsert(jClean, jE);
            }
            // Add Temperance's AC bonus and persist it
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectACIncrease(2, AC_DODGE_BONUS), sTag), oPC);

            int nExp = DivGetNow() + DivCardDurationS(DIV_CARD_TEMPERANCE);
            json jMe = JsonObject();
            jMe = JsonObjectSet(jMe, "card_id",    JsonInt(DIV_CARD_TEMPERANCE));
            jMe = JsonObjectSet(jMe, "expires_at", JsonInt(nExp));
            jClean = JsonArrayInsert(jClean, jMe);
            DivSetEffectsJson(oPC, JsonDump(jClean));

            eVFX = EffectVisualEffect(VFX_IMP_HOLY_AID);
            FloatingTextStringOnCreature(
                "Pieczęcie klątw zostały oczyszczone.", oPC, FALSE);
            break;
        }
        case DIV_CARD_DEVIL:
        {
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSkillIncrease(SKILL_INTIMIDATE, 4), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityDecrease(ABILITY_CHARISMA, 2), sTag), oPC);
            eVFX = EffectVisualEffect(VFX_IMP_NEGATIVE_ENERGY);
            break;
        }
        case DIV_CARD_TOWER:
        {
            int nDmg = d8() + d8() + d8();
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectDamage(nDmg, DAMAGE_TYPE_MAGICAL, DAMAGE_POWER_NORMAL), oPC);
            FloatingTextStringOnCreature(
                "Wieża spada. Otrzymujesz " + IntToString(nDmg) + " obrażeń.",
                oPC, FALSE);
            eVFX = EffectVisualEffect(VFX_IMP_LIGHTNING_S);
            break;
        }
        case DIV_CARD_STAR:
        {
            int nHeal = GetMaxHitPoints(oPC) * 2 / 5;
            if(nHeal < 1) nHeal = 1;
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(nHeal), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectRegenerate(2, 6.0), sTag), oPC);
            eVFX = EffectVisualEffect(VFX_IMP_HEALING_L);
            break;
        }
        case DIV_CARD_MOON:
        {
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSeeInvisible(), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAttackDecrease(1), sTag), oPC);
            eVFX = EffectVisualEffect(VFX_DUR_GHOSTLY_VISAGE);
            break;
        }
        case DIV_CARD_SUN:
        {
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_STRENGTH, 2), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_DEXTERITY, 2), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_CONSTITUTION, 2), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_INTELLIGENCE, 2), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_WISDOM, 2), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_CHARISMA, 2), sTag), oPC);
            eVFX = EffectVisualEffect(VFX_IMP_SUNSTRIKE);
            break;
        }
        case DIV_CARD_JUDGEMENT:
        {
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectSavingThrowIncrease(SAVING_THROW_ALL, 2), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectImmunity(IMMUNITY_TYPE_FEAR), sTag), oPC);
            eVFX = EffectVisualEffect(VFX_IMP_HOLY_AID);
            break;
        }
        case DIV_CARD_WORLD:
        {
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_STRENGTH, 1), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_DEXTERITY, 1), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_CONSTITUTION, 1), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_INTELLIGENCE, 1), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_WISDOM, 1), sTag), oPC);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT,
                TagEffect(EffectAbilityIncrease(ABILITY_CHARISMA, 1), sTag), oPC);
            break;
        }
    }
    ApplyEffectToObject(DURATION_TYPE_INSTANT, eVFX, oPC);
}

// ================================================================
// SQL active-effect helpers
// ================================================================

void DivAddActiveEffect(object oPC, int nCardId)
{
    if(!DivCardIsPersistent(nCardId)) return;
    // TEMPERANCE writes its own entry in DivApplySingleCardEffect
    if(nCardId == DIV_CARD_TEMPERANCE) return;

    int nExpAt  = DivGetNow() + DivCardDurationS(nCardId);
    json jArr   = JsonParse(DivGetEffectsJson(oPC));
    json jNew   = JsonArray();
    int nCount  = JsonGetLength(jArr);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jE = JsonArrayGet(jArr, i);
        if(JsonGetInt(JsonObjectGet(jE, "card_id")) != nCardId)
            jNew = JsonArrayInsert(jNew, jE);
    }
    json jEntry = JsonObject();
    jEntry = JsonObjectSet(jEntry, "card_id",    JsonInt(nCardId));
    jEntry = JsonObjectSet(jEntry, "expires_at", JsonInt(nExpAt));
    jNew = JsonArrayInsert(jNew, jEntry);
    DivSetEffectsJson(oPC, JsonDump(jNew));
}

// Prune expired entries and return the surviving list.
json DivPruneGetActive(object oPC)
{
    int nNow   = DivGetNow();
    json jArr  = JsonParse(DivGetEffectsJson(oPC));
    json jLive = JsonArray();
    int nCount = JsonGetLength(jArr);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jE = JsonArrayGet(jArr, i);
        if(JsonGetInt(JsonObjectGet(jE, "expires_at")) > nNow)
            jLive = JsonArrayInsert(jLive, jE);
    }
    if(JsonGetLength(jLive) != nCount)
        DivSetEffectsJson(oPC, JsonDump(jLive));
    return jLive;
}

void DivReapplyPersistentEffects(object oPC)
{
    DivRemoveAllDivEffects(oPC);
    json jLive = DivPruneGetActive(oPC);
    int nCount = JsonGetLength(jLive);
    int i;
    for(i = 0; i < nCount; i++)
    {
        int nId = JsonGetInt(JsonObjectGet(JsonArrayGet(jLive, i), "card_id"));
        DivApplySingleCardEffect(oPC, nId);
    }
}

// ================================================================
// Cooldown helpers
// ================================================================

int DivGetSecondsUntilRead(object oPC)
{
    int nLast = DivGetLastReadingAt(oPC);
    if(nLast == 0) return 0;
    int nRem  = nLast + DIV_COOLDOWN_S - DivGetNow();
    return (nRem > 0) ? nRem : 0;
}

int DivCanRead(object oPC)
{
    return (DivGetSecondsUntilRead(oPC) == 0);
}

// ================================================================
// Utility
// ================================================================

string DivFormatSeconds(int nSec)
{
    if(nSec <= 0) return "";
    int nH = nSec / 3600;
    int nM = (nSec % 3600) / 60;
    string s = "";
    if(nH > 0) s = IntToString(nH) + " godz. ";
    if(nM > 0) s += IntToString(nM) + " min.";
    if(s == "") s = "< 1 min.";
    return s;
}

// Pick nCount unique random card IDs, store as LVAR json array.
void DivDrawCards(object oPC, int nCount)
{
    json jDeck = JsonArray();
    int i;
    for(i = 0; i < DIV_CARD_COUNT; i++)
        jDeck = JsonArrayInsert(jDeck, JsonInt(i));

    json jHand = JsonArray();
    int nLeft = DIV_CARD_COUNT;
    while(JsonGetLength(jHand) < nCount && nLeft > 0)
    {
        int nIdx = Random(nLeft);
        json jCard = JsonArrayGet(jDeck, nIdx);
        jHand = JsonArrayInsert(jHand, jCard);
        // remove drawn card from deck
        json jTmp = JsonArray();
        int j;
        for(j = 0; j < nLeft; j++)
        {
            if(j != nIdx)
                jTmp = JsonArrayInsert(jTmp, JsonArrayGet(jDeck, j));
        }
        jDeck = jTmp;
        nLeft--;
    }
    SetLocalJson(oPC, DIV_LVAR_CARDS, jHand);
}

// ================================================================
// NUI layout builders
// ================================================================

json BuildDivMainView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 32.0);
    float fRowH  = GetNuiScaleDimension(oPC, 24.0);
    float fListH = GetNuiScaleDimension(oPC, 132.0);
    float fSpcS  = GetNuiScaleDimension(oPC, 6.0);

    // Title row
    json jTitle = NuiLabel(JsonString("Tafle Losu"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);

    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, DIV_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 30.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jTRow = JsonArray();
    jTRow = JsonArrayInsert(jTRow, jTitle);
    jTRow = JsonArrayInsert(jTRow, jClose);

    // Flavor label
    json jFlv = NuiLabel(
        JsonString("Stara wróżbitka muskała palcami tafle kart..."),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jFlv = NuiHeight(jFlv, fRowH);
    jFlv = NuiStyleForegroundColor(jFlv, NuiColor(165, 145, 100));

    // Active effects header
    json jEffHdr = NuiLabel(JsonString("Aktywne pieczęcie losu:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEffHdr = NuiHeight(jEffHdr, fRowH);

    // No-effects placeholder
    json jNoEff = NuiLabel(NuiBind(DIV_BIND_NOEFF_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jNoEff = NuiHeight(jNoEff, fRowH);
    jNoEff = NuiVisible(jNoEff, NuiBind(DIV_BIND_NOEFF_VIS));
    jNoEff = NuiStyleForegroundColor(jNoEff, NuiColor(120, 110, 90));

    // Effect list template row
    json jEffName = NuiLabel(NuiBind(DIV_BIND_EFF_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEffName = NuiStyleForegroundColor(jEffName, NuiBind(DIV_BIND_EFF_COLOR));

    json jEffTime = NuiLabel(NuiBind(DIV_BIND_EFF_TIME),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jEffTime = NuiWidth(jEffTime, GetNuiScaleDimension(oPC, 88.0));
    jEffTime = NuiStyleForegroundColor(jEffTime, NuiColor(150, 135, 100));

    json jEffRow = JsonArray();
    jEffRow = JsonArrayInsert(jEffRow, jEffName);
    jEffRow = JsonArrayInsert(jEffRow, jEffTime);
    json jEffList = NuiList(NuiRow(jEffRow), NuiBind(DIV_BIND_EFF_LEN), fRowH);
    jEffList = NuiHeight(jEffList, fListH);
    jEffList = NuiVisible(jEffList, NuiBind(DIV_BIND_EFFLIST_VIS));

    json jSpc = NuiHeight(NuiSpacer(), fSpcS);

    // Small reading info + button
    json jSmInfo = NuiLabel(
        JsonString("Małe Odczytanie (" + IntToString(DIV_SMALL_CARDS) +
                   " karty) — " + IntToString(DIV_SMALL_COST) + " złota"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSmInfo = NuiHeight(jSmInfo, fRowH);
    jSmInfo = NuiStyleForegroundColor(jSmInfo, NuiColor(155, 145, 110));

    json jSmBtn = NuiButton(JsonString("Losuj: Małe Odczytanie"));
    jSmBtn = NuiId(jSmBtn, DIV_BTN_SMALL);
    jSmBtn = NuiEnabled(jSmBtn, NuiBind(DIV_BIND_BTN_READ_ENA));
    jSmBtn = NuiHeight(jSmBtn, fBtnH);

    // Grand reading info + button
    json jGrInfo = NuiLabel(
        JsonString("Wielkie Odczytanie (" + IntToString(DIV_GRAND_CARDS) +
                   " kart) — " + IntToString(DIV_GRAND_COST) + " złota"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jGrInfo = NuiHeight(jGrInfo, fRowH);
    jGrInfo = NuiStyleForegroundColor(jGrInfo, NuiColor(155, 145, 110));

    json jGrBtn = NuiButton(JsonString("Losuj: Wielkie Odczytanie"));
    jGrBtn = NuiId(jGrBtn, DIV_BTN_GRAND);
    jGrBtn = NuiEnabled(jGrBtn, NuiBind(DIV_BIND_BTN_READ_ENA));
    jGrBtn = NuiHeight(jGrBtn, fBtnH);

    // Cooldown status label
    json jCdLbl = NuiLabel(NuiBind(DIV_BIND_COOLDOWN_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jCdLbl = NuiHeight(jCdLbl, fRowH);
    jCdLbl = NuiStyleForegroundColor(jCdLbl, NuiColor(130, 115, 80));

    // Assemble column
    json jA = JsonArray();
    jA = JsonArrayInsert(jA, NuiRow(jTRow));
    jA = JsonArrayInsert(jA, CreateEmptyRow(oPC, 4.0));
    jA = JsonArrayInsert(jA, NuiRow(JsonArrayInsert(JsonArray(), jFlv)));
    jA = JsonArrayInsert(jA, CreateEmptyRow(oPC, 4.0));
    jA = JsonArrayInsert(jA, NuiRow(JsonArrayInsert(JsonArray(), jEffHdr)));
    jA = JsonArrayInsert(jA, jNoEff);
    jA = JsonArrayInsert(jA, jEffList);
    jA = JsonArrayInsert(jA, jSpc);
    jA = JsonArrayInsert(jA, NuiRow(JsonArrayInsert(JsonArray(), jSmInfo)));
    jA = JsonArrayInsert(jA, NuiRow(JsonArrayInsert(JsonArray(), jSmBtn)));
    jA = JsonArrayInsert(jA, jSpc);
    jA = JsonArrayInsert(jA, NuiRow(JsonArrayInsert(JsonArray(), jGrInfo)));
    jA = JsonArrayInsert(jA, NuiRow(JsonArrayInsert(JsonArray(), jGrBtn)));
    jA = JsonArrayInsert(jA, jSpc);
    jA = JsonArrayInsert(jA, NuiRow(JsonArrayInsert(JsonArray(), jCdLbl)));
    jA = JsonArrayInsert(jA, NuiSpacer());

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fCW  = GetNuiScaleDimension(oPC, DIV_CONTENT_W);
    json jMR   = JsonArray();
    jMR = JsonArrayInsert(jMR, jSide);
    jMR = JsonArrayInsert(jMR, NuiWidth(NuiCol(jA), fCW));
    jMR = JsonArrayInsert(jMR, jSide);
    return NuiRow(jMR);
}

json BuildDivReadingView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 32.0);
    float fRowH  = GetNuiScaleDimension(oPC, 24.0);
    float fCardW = GetNuiScaleDimension(oPC, DIV_CARD_W);
    float fCardH = GetNuiScaleDimension(oPC, DIV_CARD_H);
    float fSpcS  = GetNuiScaleDimension(oPC, 6.0);

    // Title row
    json jTitle = NuiLabel(NuiBind(DIV_BIND_RD_TITLE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);

    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, DIV_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 30.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jTRow = JsonArray();
    jTRow = JsonArrayInsert(jTRow, jTitle);
    jTRow = JsonArrayInsert(jTRow, jClose);

    // Instruction label
    json jInstr = NuiLabel(
        JsonString("Dotknij karty, by ujawnić jej znaczenie..."),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jInstr = NuiHeight(jInstr, fRowH);
    jInstr = NuiStyleForegroundColor(jInstr, NuiColor(165, 145, 100));

    // Card slot buttons (always 5, unused ones are hidden)
    json jCardRow = JsonArray();
    int i;
    for(i = 0; i < DIV_MAX_SLOTS; i++)
    {
        string sId  = DIV_BTN_CARD + IntToString(i);
        string sLbl = DIV_BIND_SLOT_LBL + IntToString(i);
        string sEna = DIV_BIND_SLOT_ENA + IntToString(i);
        string sCol = DIV_BIND_SLOT_COL + IntToString(i);
        string sVis = DIV_BIND_SLOT_VIS + IntToString(i);
        string sTip = DIV_BIND_SLOT_TIP + IntToString(i);

        json jBtn = NuiButton(NuiBind(sLbl));
        jBtn = NuiId(jBtn, sId);
        jBtn = NuiEnabled(jBtn, NuiBind(sEna));
        jBtn = NuiVisible(jBtn, NuiBind(sVis));
        jBtn = NuiWidth(jBtn, fCardW);
        jBtn = NuiHeight(jBtn, fCardH);
        jBtn = NuiTooltip(jBtn, NuiBind(sTip));
        jBtn = NuiStyleForegroundColor(jBtn, NuiBind(sCol));
        jCardRow = JsonArrayInsert(jCardRow, jBtn);
    }

    // Detail panel — shown after first card revealed
    json jDetName = NuiLabel(NuiBind(DIV_BIND_DETAIL_NAME),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDetName = NuiHeight(jDetName, GetNuiScaleDimension(oPC, 28.0));
    jDetName = NuiStyleForegroundColor(jDetName, NuiColor(230, 210, 160));

    json jDetFlv = NuiLabel(NuiBind(DIV_BIND_DETAIL_FLAV),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDetFlv = NuiHeight(jDetFlv, GetNuiScaleDimension(oPC, 38.0));
    jDetFlv = NuiStyleForegroundColor(jDetFlv, NuiColor(155, 140, 105));

    json jDetEff = NuiLabel(NuiBind(DIV_BIND_DETAIL_EFF),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDetEff = NuiHeight(jDetEff, fRowH);
    jDetEff = NuiStyleForegroundColor(jDetEff, NuiColor(200, 185, 140));

    json jDetPanel = JsonArray();
    jDetPanel = JsonArrayInsert(jDetPanel, NuiRow(JsonArrayInsert(JsonArray(), jDetName)));
    jDetPanel = JsonArrayInsert(jDetPanel, NuiRow(JsonArrayInsert(JsonArray(), jDetFlv)));
    jDetPanel = JsonArrayInsert(jDetPanel, NuiRow(JsonArrayInsert(JsonArray(), jDetEff)));
    json jDetGrp = NuiGroup(NuiCol(jDetPanel), FALSE, NUI_SCROLLBARS_NONE);
    jDetGrp = NuiHeight(jDetGrp, GetNuiScaleDimension(oPC, 100.0));
    jDetGrp = NuiVisible(jDetGrp, NuiBind(DIV_BIND_DETAIL_VIS));

    // Accept / Back buttons
    json jAccept = NuiButton(JsonString("Przyjmij Los"));
    jAccept = NuiId(jAccept, DIV_BTN_ACCEPT);
    jAccept = NuiEnabled(jAccept, NuiBind(DIV_BIND_ACCEPT_ENA));
    jAccept = NuiHeight(jAccept, fBtnH);

    json jBack = NuiButton(JsonString("Anuluj"));
    jBack = NuiId(jBack, DIV_BTN_BACK);
    jBack = NuiHeight(jBack, fBtnH);
    jBack = NuiWidth(jBack, GetNuiScaleDimension(oPC, 90.0));

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jBack);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jAccept);

    // Assemble column
    json jA = JsonArray();
    jA = JsonArrayInsert(jA, NuiRow(jTRow));
    jA = JsonArrayInsert(jA, CreateEmptyRow(oPC, 4.0));
    jA = JsonArrayInsert(jA, NuiRow(JsonArrayInsert(JsonArray(), jInstr)));
    jA = JsonArrayInsert(jA, NuiHeight(NuiSpacer(), fSpcS));
    jA = JsonArrayInsert(jA, NuiRow(jCardRow));
    jA = JsonArrayInsert(jA, NuiHeight(NuiSpacer(), fSpcS));
    jA = JsonArrayInsert(jA, jDetGrp);
    jA = JsonArrayInsert(jA, NuiSpacer());
    jA = JsonArrayInsert(jA, NuiRow(jBotRow));

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fCW  = GetNuiScaleDimension(oPC, DIV_CONTENT_W);
    json jMR   = JsonArray();
    jMR = JsonArrayInsert(jMR, jSide);
    jMR = JsonArrayInsert(jMR, NuiWidth(NuiCol(jA), fCW));
    jMR = JsonArrayInsert(jMR, jSide);
    return NuiRow(jMR);
}

// ================================================================
// Window lifecycle
// ================================================================

void DivShowWindow(object oPC)
{
    if(NuiFindWindow(oPC, DIV_WINDOW) != 0)
    {
        NuiSetGroupLayout(oPC, NuiFindWindow(oPC, DIV_WINDOW),
            DIV_GRP_SWAP, BuildDivMainView(oPC));
        DivFeedMain(oPC, NuiFindWindow(oPC, DIV_WINDOW));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC,
                    PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                - GetNuiScaleDimension(oPC, DIV_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC,
                    PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                - GetNuiScaleDimension(oPC, DIV_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
        GetNuiScaleDimension(oPC, DIV_W),
        GetNuiScaleDimension(oPC, DIV_H));

    json jSwap = NuiGroup(BuildDivMainView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwap = NuiId(jSwap, DIV_GRP_SWAP);

    json jRoot = NuiCol(JsonArrayInsert(JsonArray(), jSwap));
    json jWin  = NuiWindow(jRoot,
        JsonBool(FALSE),
        NuiBind(DIV_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, DIV_WINDOW, DIV_EV_SCRIPT);
    NuiSetBind(oPC, nToken, DIV_WIN_GEOM, jGeom);
    DivFeedMain(oPC, nToken);
}

// ================================================================
// Feed functions
// ================================================================

void DivFeedMain(object oPC, int nToken)
{
    json jLive = DivPruneGetActive(oPC);
    int  nLive = JsonGetLength(jLive);
    int  nNow  = DivGetNow();

    json jNames  = JsonArray();
    json jTimes  = JsonArray();
    json jColors = JsonArray();
    int i;
    for(i = 0; i < nLive; i++)
    {
        json jE     = JsonArrayGet(jLive, i);
        int  nId    = JsonGetInt(JsonObjectGet(jE, "card_id"));
        int  nExpAt = JsonGetInt(JsonObjectGet(jE, "expires_at"));
        int  nRem   = nExpAt - nNow;

        string sShort = DivCardEffectDesc(nId);
        // Truncate long descriptions for list display
        if(GetStringLength(sShort) > 48)
            sShort = GetStringLeft(sShort, 45) + "...";

        jNames  = JsonArrayInsert(jNames,  JsonString(DivCardName(nId) + " — " + sShort));
        jTimes  = JsonArrayInsert(jTimes,  JsonString(DivFormatSeconds(nRem)));
        jColors = JsonArrayInsert(jColors, DivCardColor(nId));
    }

    NuiSetBind(oPC, nToken, DIV_BIND_EFF_NAME,    jNames);
    NuiSetBind(oPC, nToken, DIV_BIND_EFF_TIME,    jTimes);
    NuiSetBind(oPC, nToken, DIV_BIND_EFF_COLOR,   jColors);
    NuiSetBind(oPC, nToken, DIV_BIND_EFF_LEN,     JsonInt(nLive));
    NuiSetBind(oPC, nToken, DIV_BIND_EFFLIST_VIS, JsonBool(nLive > 0));
    NuiSetBind(oPC, nToken, DIV_BIND_NOEFF_VIS,   JsonBool(nLive == 0));
    NuiSetBind(oPC, nToken, DIV_BIND_NOEFF_LBL,
        JsonString("— żadnych aktywnych pieczęci —"));

    int nCdSec = DivGetSecondsUntilRead(oPC);
    int bCanRead = (nCdSec == 0);
    NuiSetBind(oPC, nToken, DIV_BIND_BTN_READ_ENA, JsonBool(bCanRead));
    NuiSetBind(oPC, nToken, DIV_BIND_COOLDOWN_LBL,
        JsonString(bCanRead
            ? "Wróżbitka jest gotowa przyjąć cię."
            : "Następne odczytanie za: " + DivFormatSeconds(nCdSec)));
}

void DivFeedCards(object oPC, int nToken)
{
    json jCards  = GetLocalJson(oPC, DIV_LVAR_CARDS);
    int  nCnt    = GetLocalInt(oPC, DIV_LVAR_CARDCNT);
    int  nMask   = GetLocalInt(oPC, DIV_LVAR_REVEALED);
    int  nLast   = GetLocalInt(oPC, DIV_LVAR_LASTCARD);
    int  nRevealed = 0;
    int  i;

    for(i = 0; i < nCnt; i++)
        if(nMask & (1 << i)) nRevealed++;

    int bAll = (nRevealed == nCnt);

    for(i = 0; i < DIV_MAX_SLOTS; i++)
    {
        string sLbl = DIV_BIND_SLOT_LBL + IntToString(i);
        string sEna = DIV_BIND_SLOT_ENA + IntToString(i);
        string sCol = DIV_BIND_SLOT_COL + IntToString(i);
        string sVis = DIV_BIND_SLOT_VIS + IntToString(i);
        string sTip = DIV_BIND_SLOT_TIP + IntToString(i);

        int bInUse    = (i < nCnt);
        int bRevealed = bInUse && (nMask & (1 << i));

        NuiSetBind(oPC, nToken, sVis, JsonBool(bInUse));

        if(!bInUse)
        {
            NuiSetBind(oPC, nToken, sLbl, JsonString(""));
            NuiSetBind(oPC, nToken, sEna, JsonBool(FALSE));
            NuiSetBind(oPC, nToken, sCol, NuiColor(80, 80, 80));
            NuiSetBind(oPC, nToken, sTip, JsonString(""));
            continue;
        }

        if(bRevealed)
        {
            int nId = JsonGetInt(JsonArrayGet(jCards, i));
            NuiSetBind(oPC, nToken, sLbl, JsonString(DivCardName(nId)));
            NuiSetBind(oPC, nToken, sEna, JsonBool(FALSE));
            NuiSetBind(oPC, nToken, sCol, DivCardColor(nId));
            NuiSetBind(oPC, nToken, sTip, JsonString(DivCardEffectDesc(nId)));
        }
        else
        {
            NuiSetBind(oPC, nToken, sLbl, JsonString("?"));
            NuiSetBind(oPC, nToken, sEna, JsonBool(TRUE));
            NuiSetBind(oPC, nToken, sCol, NuiColor(140, 120, 80));
            NuiSetBind(oPC, nToken, sTip, JsonString("Kliknij, by ujawnić kartę."));
        }
    }

    // Detail panel for last revealed card
    int bShowDetail = (nRevealed > 0);
    NuiSetBind(oPC, nToken, DIV_BIND_DETAIL_VIS, JsonBool(bShowDetail));
    if(bShowDetail)
    {
        NuiSetBind(oPC, nToken, DIV_BIND_DETAIL_NAME,
            JsonString("— " + DivCardName(nLast) + " —"));
        NuiSetBind(oPC, nToken, DIV_BIND_DETAIL_FLAV,
            JsonString(DivCardFlavor(nLast)));
        NuiSetBind(oPC, nToken, DIV_BIND_DETAIL_EFF,
            JsonString(DivCardEffectDesc(nLast)));
    }
    else
    {
        NuiSetBind(oPC, nToken, DIV_BIND_DETAIL_NAME, JsonString(""));
        NuiSetBind(oPC, nToken, DIV_BIND_DETAIL_FLAV, JsonString(""));
        NuiSetBind(oPC, nToken, DIV_BIND_DETAIL_EFF,  JsonString(""));
    }

    NuiSetBind(oPC, nToken, DIV_BIND_ACCEPT_ENA, JsonBool(bAll));
}

// ================================================================
// Reading flow
// ================================================================

void DivStartReading(object oPC, int nToken, int nCardCount)
{
    int nCost = (nCardCount == DIV_SMALL_CARDS) ? DIV_SMALL_COST : DIV_GRAND_COST;

    if(!DivCanRead(oPC))
    {
        SendMessageToPC(oPC,
            "[Wróżbiarstwo] Karty pamiętają jeszcze poprzednie odczytanie.");
        return;
    }
    if(GetGold(oPC) < nCost)
    {
        SendMessageToPC(oPC,
            "[Wróżbiarstwo] Nie masz " + IntToString(nCost) + " złota.");
        return;
    }

    AssignCommand(oPC, TakeGoldFromCreature(nCost, oPC, TRUE));

    SetLocalInt(oPC, DIV_LVAR_CARDCNT,  nCardCount);
    SetLocalInt(oPC, DIV_LVAR_REVEALED, 0);
    SetLocalInt(oPC, DIV_LVAR_LASTCARD, -1);
    DivDrawCards(oPC, nCardCount);

    string sTitle = (nCardCount == DIV_SMALL_CARDS)
        ? "Małe Odczytanie — Ujawnij karty"
        : "Wielkie Odczytanie — Ujawnij karty";

    NuiSetGroupLayout(oPC, nToken, DIV_GRP_SWAP, BuildDivReadingView(oPC));
    NuiSetBind(oPC, nToken, DIV_BIND_RD_TITLE, JsonString(sTitle));
    NuiSetBind(oPC, nToken, DIV_BIND_DETAIL_VIS, JsonBool(FALSE));
    DivFeedCards(oPC, nToken);
}

void DivRevealCard(object oPC, int nToken, int nSlot)
{
    int nCnt  = GetLocalInt(oPC, DIV_LVAR_CARDCNT);
    if(nSlot < 0 || nSlot >= nCnt) return;

    int nMask = GetLocalInt(oPC, DIV_LVAR_REVEALED);
    if(nMask & (1 << nSlot)) return;  // already revealed

    nMask |= (1 << nSlot);
    SetLocalInt(oPC, DIV_LVAR_REVEALED, nMask);

    json jCards = GetLocalJson(oPC, DIV_LVAR_CARDS);
    int  nId    = JsonGetInt(JsonArrayGet(jCards, nSlot));
    SetLocalInt(oPC, DIV_LVAR_LASTCARD, nId);

    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_PULSE_WIND), oPC);
    DivFeedCards(oPC, nToken);
}

void DivAcceptFate(object oPC, int nToken)
{
    json jCards = GetLocalJson(oPC, DIV_LVAR_CARDS);
    int  nCnt   = GetLocalInt(oPC, DIV_LVAR_CARDCNT);
    int  nMask  = GetLocalInt(oPC, DIV_LVAR_REVEALED);

    int i;
    for(i = 0; i < nCnt; i++)
    {
        if(!(nMask & (1 << i))) continue;
        int nId = JsonGetInt(JsonArrayGet(jCards, i));
        DivApplySingleCardEffect(oPC, nId);
        DivAddActiveEffect(oPC, nId);
    }

    DivSetLastReadingAt(oPC, DivGetNow());

    DeleteLocalJson(oPC, DIV_LVAR_CARDS);
    DeleteLocalInt(oPC, DIV_LVAR_REVEALED);
    DeleteLocalInt(oPC, DIV_LVAR_CARDCNT);
    DeleteLocalInt(oPC, DIV_LVAR_LASTCARD);

    NuiSetGroupLayout(oPC, nToken, DIV_GRP_SWAP, BuildDivMainView(oPC));
    DivFeedMain(oPC, nToken);
    SendMessageToPC(oPC, "[Wróżbiarstwo] Pieczęcie losu zostały odciśnięte.");
}

void DivCancelReading(object oPC, int nToken)
{
    // Gold already spent; no refund — fate does not reverse.
    DeleteLocalJson(oPC, DIV_LVAR_CARDS);
    DeleteLocalInt(oPC, DIV_LVAR_REVEALED);
    DeleteLocalInt(oPC, DIV_LVAR_CARDCNT);
    DeleteLocalInt(oPC, DIV_LVAR_LASTCARD);

    NuiSetGroupLayout(oPC, nToken, DIV_GRP_SWAP, BuildDivMainView(oPC));
    DivFeedMain(oPC, nToken);
}

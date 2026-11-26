#include "lib_lbr_def"

// ----------------------------------------------------------------
// Essence type helpers
// ----------------------------------------------------------------

string LbrGetTypeName(int nType)
{
    switch(nType)
    {
        case LBR_ESSENCE_WARRIOR: return "Wojownik";
        case LBR_ESSENCE_BEAST:   return "Bestia";
        case LBR_ESSENCE_UNDEAD:  return "Nieumarły";
        case LBR_ESSENCE_DEMON:   return "Demon";
        case LBR_ESSENCE_DIVINE:  return "Boskie";
        case LBR_ESSENCE_ARCANE:  return "Arkaniczne";
    }
    return "Nieznane";
}

string LbrGetFlavorText(int nType)
{
    switch(nType)
    {
        case LBR_ESSENCE_WARRIOR:
            return "Fiolka drży od stłumionej wściekłości. Krew smakuje żelazem i potem bitwy.";
        case LBR_ESSENCE_BEAST:
            return "Drapieżny instynkt spiętrza się w gardle — ciało pragnie polować.";
        case LBR_ESSENCE_UNDEAD:
            return "Zimna pustka rozlewa się po żyłach. Serce bije wolniej, lecz pewniej.";
        case LBR_ESSENCE_DEMON:
            return "Piekielny żar wznosi się pod skórą. Coś ciemnego uśmiecha się od środka.";
        case LBR_ESSENCE_DIVINE:
            return "Święte światło parzy podniebienie, lecz rany zarastają szybciej.";
        case LBR_ESSENCE_ARCANE:
            return "Myśl staje się ostra jak obsydian. Każdy zaklęty symbol nabiera sensu.";
    }
    return "Istota nie pozostawiła po sobie niczego wartego zapamiętania.";
}

json LbrGetTypeColor(int nType)
{
    switch(nType)
    {
        case LBR_ESSENCE_WARRIOR: return NuiColor(220, 60,  60);
        case LBR_ESSENCE_BEAST:   return NuiColor(100, 200, 80);
        case LBR_ESSENCE_UNDEAD:  return NuiColor(140, 180, 220);
        case LBR_ESSENCE_DEMON:   return NuiColor(200, 80,  240);
        case LBR_ESSENCE_DIVINE:  return NuiColor(255, 230, 80);
        case LBR_ESSENCE_ARCANE:  return NuiColor(80,  180, 255);
    }
    return NuiColor(170, 170, 170);
}

// ----------------------------------------------------------------
// Classify creature into an essence type
// ----------------------------------------------------------------

int LbrGetEssenceTypeFromCreature(object oCreature)
{
    int nRace = GetRacialType(oCreature);

    if(nRace == RACIAL_TYPE_UNDEAD)
        return LBR_ESSENCE_UNDEAD;

    if(nRace == RACIAL_TYPE_OUTSIDER)
        return (GetAlignmentGoodEvil(oCreature) == ALIGNMENT_EVIL)
            ? LBR_ESSENCE_DEMON
            : LBR_ESSENCE_DIVINE;

    if(nRace == RACIAL_TYPE_ELEMENTAL)
        return LBR_ESSENCE_ARCANE;

    if(nRace == RACIAL_TYPE_ANIMAL   ||
       nRace == RACIAL_TYPE_BEAST    ||
       nRace == RACIAL_TYPE_VERMIN   ||
       nRace == RACIAL_TYPE_DRAGON)
        return LBR_ESSENCE_BEAST;

    // For humanoids and constructs, classify by primary class
    int i;
    for(i = 1; i <= 3; i++)
    {
        int nClass = GetClassByPosition(i, oCreature);
        if(nClass == CLASS_TYPE_INVALID) break;

        switch(nClass)
        {
            case CLASS_TYPE_WIZARD:
            case CLASS_TYPE_SORCERER:
            case CLASS_TYPE_BARD:
                return LBR_ESSENCE_ARCANE;

            case CLASS_TYPE_CLERIC:
            case CLASS_TYPE_PALADIN:
                return LBR_ESSENCE_DIVINE;

            case CLASS_TYPE_DRUID:
                return LBR_ESSENCE_BEAST;

            case CLASS_TYPE_FIGHTER:
            case CLASS_TYPE_BARBARIAN:
            case CLASS_TYPE_RANGER:
            case CLASS_TYPE_MONK:
            case CLASS_TYPE_ROGUE:
                return LBR_ESSENCE_WARRIOR;
        }
    }

    return LBR_ESSENCE_WARRIOR;
}

// ----------------------------------------------------------------
// Apply essence effects (session-only, not persisted)
// ----------------------------------------------------------------

void LbrApplyEffects(object oPC, int nType)
{
    float fDur = IntToFloat(LBR_EFFECT_DURATION);
    switch(nType)
    {
        case LBR_ESSENCE_WARRIOR:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectAbilityIncrease(ABILITY_STRENGTH, 4), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectTemporaryHitpoints(20), oPC, fDur);
            break;

        case LBR_ESSENCE_BEAST:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectAbilityIncrease(ABILITY_CONSTITUTION, 4), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectMovementSpeedIncrease(30), oPC, fDur);
            break;

        case LBR_ESSENCE_UNDEAD:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectImmunity(IMMUNITY_TYPE_FEAR), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectImmunity(IMMUNITY_TYPE_DISEASE), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectDamageImmunityIncrease(DAMAGE_TYPE_NEGATIVE, 50), oPC, fDur);
            break;

        case LBR_ESSENCE_DEMON:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectDamageImmunityIncrease(DAMAGE_TYPE_FIRE, 50), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectAttackIncrease(3, ATTACK_BONUS_ONHAND), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectDamageIncrease(2, DAMAGE_TYPE_FIRE), oPC, fDur);
            break;

        case LBR_ESSENCE_DIVINE:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectRegenerate(2, 6.0), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectACIncrease(3, AC_DEFLECTION_BONUS), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectImmunity(IMMUNITY_TYPE_POISON), oPC, fDur);
            break;

        case LBR_ESSENCE_ARCANE:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectAbilityIncrease(ABILITY_INTELLIGENCE, 4), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectAbilityIncrease(ABILITY_WISDOM, 2), oPC, fDur);
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectSavingThrowIncrease(SAVING_THROW_WILL, 3), oPC, fDur);
            break;
    }
}

// ----------------------------------------------------------------
// Harvest
// ----------------------------------------------------------------

void LbrHarvestEssence(object oPC, object oCorpse)
{
    DeleteLocalInt(oPC, LBR_LVAR_TARGETING);

    if(!GetIsObjectValid(oCorpse))
    {
        SendMessageToPC(oPC, "[Ostatnie Tchnienie] Cel jest nieprawidłowy.");
        return;
    }

    // Must be the PC's current area, within reach
    float fDist = GetDistanceBetween(oPC, oCorpse);
    if(fDist < 0.0 || fDist > 5.0)
    {
        SendMessageToPC(oPC, "[Ostatnie Tchnienie] Zbyt daleko — musisz być przy ciele.");
        return;
    }

    if(!GetIsDead(oCorpse))
    {
        SendMessageToPC(oPC, "[Ostatnie Tchnienie] Cel nie jest martwy.");
        return;
    }

    int nCR = FloatToInt(GetChallengeRating(oCorpse));
    if(nCR < LBR_MIN_CR)
    {
        SendMessageToPC(oPC, "[Ostatnie Tchnienie] Ta istota była zbyt słaba — jej tchnienie już wystygło.");
        return;
    }

    // Vial is consumed on harvest
    object oVial = GetItemPossessedBy(oPC, LBR_VIAL_TAG);
    if(!GetIsObjectValid(oVial))
    {
        SendMessageToPC(oPC, "[Ostatnie Tchnienie] Potrzebujesz Fiolki Ostatniego Tchnienia.");
        return;
    }

    LbrClearDecayed(oPC);
    if(LbrGetEssenceCount(oPC) >= LBR_MAX_ESSENCES)
    {
        SendMessageToPC(oPC, "[Ostatnie Tchnienie] Nosisz już " + IntToString(LBR_MAX_ESSENCES) + " fiolek. Opróżnij jedną.");
        return;
    }

    int nType    = LbrGetEssenceTypeFromCreature(oCorpse);
    string sName = GetName(oCorpse);

    if(GetItemStackSize(oVial) > 1)
        SetItemStackSize(oVial, GetItemStackSize(oVial) - 1);
    else
        DestroyObject(oVial);

    LbrAddEssence(oPC, nType, sName);

    FloatingTextStringOnCreature("Pochłaniasz ostatnie tchnienie " + sName + "...", oPC, FALSE);
    SendMessageToPC(oPC, "[Ostatnie Tchnienie] Zbiór: " + sName + " (" + LbrGetTypeName(nType) + ").");

    ApplyEffectAtLocation(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_FNF_SUMMON_UNDEAD), GetLocation(oCorpse));
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_COM_BLOOD_REG_RED), oPC);

    int nToken = NuiFindWindow(oPC, LBR_WINDOW);
    if(nToken != 0) LbrFeedWindow(oPC, nToken);
}

// ----------------------------------------------------------------
// Consume
// ----------------------------------------------------------------

void LbrConsumeEssence(object oPC, int nId)
{
    if(nId <= 0) return;

    json jEssences = LbrGetEssences(oPC);
    int  nCount    = JsonGetLength(jEssences);
    int  nType     = 0;
    string sName   = "";
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow = JsonArrayGet(jEssences, i);
        if(JsonGetInt(JsonObjectGet(jRow, "id")) == nId)
        {
            nType = JsonGetInt   (JsonObjectGet(jRow, "essence_type"));
            sName = JsonGetString(JsonObjectGet(jRow, "creature_name"));
            break;
        }
    }
    if(nType == 0)
    {
        SendMessageToPC(oPC, "[Ostatnie Tchnienie] Nie znaleziono esencji.");
        return;
    }

    LbrDeleteEssence(nId);
    LbrApplyEffects(oPC, nType);

    FloatingTextStringOnCreature("Wypijasz tchnienie " + sName + "...", oPC, FALSE);
    SendMessageToPC(oPC, "[Ostatnie Tchnienie] " + LbrGetFlavorText(nType));

    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_DUR_CESSATE_POSITIVE), oPC);
}

// ----------------------------------------------------------------
// NUI window layout
// ----------------------------------------------------------------

json LbrBuildLayout(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fRowH  = GetNuiScaleDimension(oPC, 32.0);
    float fListH = GetNuiScaleDimension(oPC, 210.0);
    float fFlvH  = GetNuiScaleDimension(oPC, 80.0);
    float fTypeW = GetNuiScaleDimension(oPC, 95.0);
    float fAgeW  = GetNuiScaleDimension(oPC, 50.0);

    // ---- Title row ----
    json jTitleLbl = NuiLabel(JsonString("Fiolki Tchnień"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, fBtnH);

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, LBR_BTN_CLOSE);
    jCloseBtn = NuiWidth (jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTitleRow = JsonArray();
    jTitleRow = JsonArrayInsert(jTitleRow, jTitleLbl);
    jTitleRow = JsonArrayInsert(jTitleRow, jCloseBtn);

    // ---- List template: Type | Name | Age ----
    json jTypeLbl = NuiLabel(NuiBind(LBR_BIND_ROW_TYPE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTypeLbl = NuiStyleForegroundColor(jTypeLbl, NuiBind(LBR_BIND_ROW_COLOR));

    json jNameLbl = NuiLabel(NuiBind(LBR_BIND_ROW_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(LBR_BIND_ROW_COLOR));

    json jAgeLbl = NuiLabel(NuiBind(LBR_BIND_ROW_AGE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jAgeLbl = NuiWidth(jAgeLbl, fAgeW);

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow,
        NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jTypeLbl)), fTypeW));
    jCellRow = JsonArrayInsert(jCellRow, jNameLbl);
    jCellRow = JsonArrayInsert(jCellRow, jAgeLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, LBR_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(LBR_BIND_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(LBR_BIND_ROWCOUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // ---- Flavor text ----
    json jFlavor = NuiGroup(NuiText(NuiBind(LBR_BIND_FLAVOR), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jFlavor = NuiHeight(jFlavor, fFlvH);

    // ---- Status label ----
    json jStatus = NuiLabel(NuiBind(LBR_BIND_STATUS),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatus = NuiHeight(jStatus, GetNuiScaleDimension(oPC, 22.0));

    // ---- Bottom buttons ----
    json jHarvestBtn = NuiButton(JsonString("Pochłoń Tchnienie"));
    jHarvestBtn = NuiId     (jHarvestBtn, LBR_BTN_HARVEST);
    jHarvestBtn = NuiWidth  (jHarvestBtn, GetNuiScaleDimension(oPC, 160.0));
    jHarvestBtn = NuiHeight (jHarvestBtn, fBtnH);
    jHarvestBtn = NuiTooltip(jHarvestBtn,
        JsonString("Pochłoń tchnienie martwej istoty (CR " + IntToString(LBR_MIN_CR) + "+, wymaga Fiolki)."));

    json jDiscardBtn = NuiButton(JsonString("Wyrzuć"));
    jDiscardBtn = NuiId     (jDiscardBtn, LBR_BTN_DISCARD);
    jDiscardBtn = NuiEnabled(jDiscardBtn, NuiBind(LBR_BIND_DISC_ENA));
    jDiscardBtn = NuiWidth  (jDiscardBtn, GetNuiScaleDimension(oPC, 80.0));
    jDiscardBtn = NuiHeight (jDiscardBtn, fBtnH);
    jDiscardBtn = NuiTooltip(jDiscardBtn, JsonString("Wyrzuć esencję bez korzystania z jej mocy."));

    json jDrinkBtn = NuiButton(JsonString("Wypij"));
    jDrinkBtn = NuiId     (jDrinkBtn, LBR_BTN_DRINK);
    jDrinkBtn = NuiEnabled(jDrinkBtn, NuiBind(LBR_BIND_DRINK_ENA));
    jDrinkBtn = NuiWidth  (jDrinkBtn, GetNuiScaleDimension(oPC, 80.0));
    jDrinkBtn = NuiHeight (jDrinkBtn, fBtnH);
    jDrinkBtn = NuiTooltip(jDrinkBtn, JsonString("Wypij zaznaczoną esencję aby zyskać jej moc na 5 minut."));

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jHarvestBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jDiscardBtn);
    jBotRow = JsonArrayInsert(jBotRow, jDrinkBtn);

    // ---- Assemble ----
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTitleRow));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, jFlavor);
    jCol = JsonArrayInsert(jCol, jStatus);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    return NuiCol(jCol);
}

// ----------------------------------------------------------------
// Window lifecycle
// ----------------------------------------------------------------

void LbrOpenWindow(object oPC)
{
    LbrClearDecayed(oPC);

    int nToken = NuiFindWindow(oPC, LBR_WINDOW);
    if(nToken != 0)
    {
        LbrFeedWindow(oPC, nToken);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
        - GetNuiScaleDimension(oPC, LBR_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
        - GetNuiScaleDimension(oPC, LBR_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
        GetNuiScaleDimension(oPC, LBR_W),
        GetNuiScaleDimension(oPC, LBR_H));

    json jWin = NuiWindow(LbrBuildLayout(oPC),
        JsonBool(FALSE),
        NuiBind(LBR_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, LBR_WINDOW, LBR_EV_SCRIPT);
    NuiSetBind(oPC, nToken, LBR_WIN_GEOM, jGeom);
    SetLocalInt(oPC, LBR_LVAR_SEL_ID, 0);
    LbrFeedWindow(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed
// ----------------------------------------------------------------

string LbrFormatAge(int nHarvestedAt)
{
    int nAge = GetUnixTimeStamp() - nHarvestedAt;
    if(nAge < 0)    return "0m";
    if(nAge < 3600) return IntToString(nAge / 60) + "m";
    if(nAge < 86400)return IntToString(nAge / 3600) + "h";
    return IntToString(nAge / 86400) + "d";
}

void LbrFeedWindow(object oPC, int nToken)
{
    json jEssences = LbrGetEssences(oPC);
    int  nCount    = JsonGetLength(jEssences);
    int  nSelId    = GetLocalInt(oPC, LBR_LVAR_SEL_ID);

    json jNames  = JsonArray();
    json jTypes  = JsonArray();
    json jAges   = JsonArray();
    json jColors = JsonArray();
    json jEncs   = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow    = JsonArrayGet(jEssences, i);
        int  nId     = JsonGetInt   (JsonObjectGet(jRow, "id"));
        int  nType   = JsonGetInt   (JsonObjectGet(jRow, "essence_type"));
        string sName = JsonGetString(JsonObjectGet(jRow, "creature_name"));
        int  nHarv   = JsonGetInt   (JsonObjectGet(jRow, "harvested_at"));

        jNames  = JsonArrayInsert(jNames,  JsonString(sName));
        jTypes  = JsonArrayInsert(jTypes,  JsonString(LbrGetTypeName(nType)));
        jAges   = JsonArrayInsert(jAges,   JsonString(LbrFormatAge(nHarv)));
        jColors = JsonArrayInsert(jColors, LbrGetTypeColor(nType));
        jEncs   = JsonArrayInsert(jEncs,   JsonBool(nSelId > 0 && nId == nSelId));
    }

    NuiSetBind(oPC, nToken, LBR_BIND_ROW_NAME,  jNames);
    NuiSetBind(oPC, nToken, LBR_BIND_ROW_TYPE,  jTypes);
    NuiSetBind(oPC, nToken, LBR_BIND_ROW_AGE,   jAges);
    NuiSetBind(oPC, nToken, LBR_BIND_ROW_COLOR, jColors);
    NuiSetBind(oPC, nToken, LBR_BIND_ROW_ENC,   jEncs);
    NuiSetBind(oPC, nToken, LBR_BIND_ROWCOUNT,  JsonInt(nCount));

    string sStatus = "Tchnień: " + IntToString(nCount) + " / " + IntToString(LBR_MAX_ESSENCES)
        + "   (gniją po " + IntToString(LBR_DECAY_DAYS) + " dniach)";
    NuiSetBind(oPC, nToken, LBR_BIND_STATUS, JsonString(sStatus));

    int bSel = (nSelId > 0);
    NuiSetBind(oPC, nToken, LBR_BIND_DRINK_ENA, JsonBool(bSel));
    NuiSetBind(oPC, nToken, LBR_BIND_DISC_ENA,  JsonBool(bSel));

    string sFlavor = "";
    if(bSel)
    {
        for(i = 0; i < nCount; i++)
        {
            json jRow = JsonArrayGet(jEssences, i);
            if(JsonGetInt(JsonObjectGet(jRow, "id")) == nSelId)
            {
                sFlavor = LbrGetFlavorText(JsonGetInt(JsonObjectGet(jRow, "essence_type")));
                break;
            }
        }
    }
    NuiSetBind(oPC, nToken, LBR_BIND_FLAVOR, JsonString(sFlavor));
}

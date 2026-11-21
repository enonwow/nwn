// lib_balt.nss — Blood Altar: dane oltarzy, UI NUI, aplikacja boonow, VFX korupcji
#include "lib_balt_def"

// ================================================================
// Pomocnicy do budowania danych ofiar (JSON)
// ================================================================

json BaltMakeSac(string sName, string sCostDesc, string sEffDesc,
                  int nCostType, int nCostVal,
                  int nCorrupt, float fDuration, json jEffs)
{
    json j = JsonObject();
    j = JsonObjectSet(j, "name",      JsonString(sName));
    j = JsonObjectSet(j, "cost_desc", JsonString(sCostDesc));
    j = JsonObjectSet(j, "eff_desc",  JsonString(sEffDesc));
    j = JsonObjectSet(j, "cost_type", JsonInt(nCostType));
    j = JsonObjectSet(j, "cost_val",  JsonInt(nCostVal));
    j = JsonObjectSet(j, "corrupt",   JsonInt(nCorrupt));
    j = JsonObjectSet(j, "duration",  JsonFloat(fDuration));
    j = JsonObjectSet(j, "eff",       jEffs);
    return j;
}

json BaltEffAbility(int nAbility, int nVal)
{
    json e = JsonObject();
    e = JsonObjectSet(e, "t",   JsonInt(BALT_EFF_ABILITY));
    e = JsonObjectSet(e, "sub", JsonInt(nAbility));
    e = JsonObjectSet(e, "val", JsonInt(nVal));
    return e;
}

json BaltEffVal(int nType, int nVal)
{
    json e = JsonObject();
    e = JsonObjectSet(e, "t",   JsonInt(nType));
    e = JsonObjectSet(e, "val", JsonInt(nVal));
    return e;
}

json BaltEffNoParam(int nType)
{
    json e = JsonObject();
    e = JsonObjectSet(e, "t", JsonInt(nType));
    return e;
}

// ================================================================
// Dane statyczne: nazwa i klimatyczny opis oltarza
// ================================================================

string BaltGetAltarName(string sAltarTag)
{
    if(sAltarTag == BALT_TAG_BLOOD)  return "Oltarz Krwi";
    if(sAltarTag == BALT_TAG_BONE)   return "Oltarz Kosci";
    if(sAltarTag == BALT_TAG_EARTH)  return "Oltarz Ziemi";
    if(sAltarTag == BALT_TAG_SHADOW) return "Oltarz Cienia";
    return "Oltarz";
}

string BaltGetAltarLore(string sAltarTag)
{
    if(sAltarTag == BALT_TAG_BLOOD)
        return "Kamien pulsuje ciemna czerwienia. Krew i moc ida w parze — "
             + "lecz kazda ofiara zostawia slad na duszy skladajacego. "
             + "Tych, co składaja tu zbyt wiele, mroczna moc poślębia.";

    if(sAltarTag == BALT_TAG_BONE)
        return "Kosci układają się w starożytny wzor. Pochłaniający patron "
             + "tego miejsca czeka na należną mu daninę. Martwa magia "
             + "wzmacnia ciało — kosztem duszy.";

    if(sAltarTag == BALT_TAG_EARTH)
        return "Zielony mech okrywa kamien. Duch lasu i gor nie zada duszy — "
             + "jedynie holdu. Natura daje i bierze, lecz nie kazi. "
             + "Tu mozna czynic ofiary bez ryzyka skalania.";

    if(sAltarTag == BALT_TAG_SHADOW)
        return "Ciemnosc przy oltarzu nie znika nawet w poludnie. Pan Cieni "
             + "nagradza skrytosc — lecz cena jest wyzsza niz sie zdaje. "
             + "Kazda ofiara przybiza do zatracenia.";

    return "";
}

// ================================================================
// Definicje ofiar per typ oltarza
// ================================================================

json BaltGetSacrifices(string sAltarTag)
{
    json jList = JsonArray();

    if(sAltarTag == BALT_TAG_BLOOD)
    {
        // --- Minor: zloto -> Sila +2 na 1h ---
        json jE0 = JsonArrayInsert(JsonArray(), BaltEffAbility(ABILITY_STRENGTH, 2));
        jList = JsonArrayInsert(jList, BaltMakeSac(
            "Drobna danica krwi",
            "300 zlota",
            "Sila +2 na 1 godzine",
            0, 300, 8, 3600.0, jE0));

        // --- Flesh: przedmiot -> Przyspieszenie na 15 min ---
        json jE1 = JsonArrayInsert(JsonArray(), BaltEffNoParam(BALT_EFF_HASTE));
        jList = JsonArrayInsert(jList, BaltMakeSac(
            "Ofiara z ciala",
            "Przedmiot z ekwipunku",
            "Przyspieszenie na 15 minut",
            1, 0, 15, 900.0, jE1));

        // --- Blood: 25% maks. PW -> Sila +4 + 20 PW tymczasowych na 3h ---
        json jE2 = JsonArray();
        jE2 = JsonArrayInsert(jE2, BaltEffAbility(ABILITY_STRENGTH, 4));
        jE2 = JsonArrayInsert(jE2, BaltEffVal(BALT_EFF_TEMP_HP, 20));
        jList = JsonArrayInsert(jList, BaltMakeSac(
            "Wielka danica krwi",
            "25% maks. PW",
            "Sila +4, +20 PW tymcz. na 3 godziny",
            2, 25, 25, 10800.0, jE2));
    }
    else if(sAltarTag == BALT_TAG_BONE)
    {
        // --- Minor: zloto -> Kondycja +2 na 1h ---
        json jE0 = JsonArrayInsert(JsonArray(), BaltEffAbility(ABILITY_CONSTITUTION, 2));
        jList = JsonArrayInsert(jList, BaltMakeSac(
            "Proszek z kosci",
            "250 zlota",
            "Kondycja +2 na 1 godzine",
            0, 250, 5, 3600.0, jE0));

        // --- Flesh: przedmiot -> Odpornosc na Czary +10 na 1h ---
        json jE1 = JsonArrayInsert(JsonArray(), BaltEffVal(BALT_EFF_SPELL_RES, 10));
        jList = JsonArrayInsert(jList, BaltMakeSac(
            "Ofiara ze schronienia",
            "Przedmiot z ekwipunku",
            "Odpornosc na czary +10 na 1 godzine",
            1, 0, 12, 3600.0, jE1));

        // --- Blood: 20% maks. PW -> Rzuty obronne +3 na 3h ---
        json jE2 = JsonArrayInsert(JsonArray(), BaltEffVal(BALT_EFF_SAVES, 3));
        jList = JsonArrayInsert(jList, BaltMakeSac(
            "Danica kosci i krwi",
            "20% maks. PW",
            "Rzuty obronne +3 na 3 godziny",
            2, 20, 20, 10800.0, jE2));
    }
    else if(sAltarTag == BALT_TAG_EARTH)
    {
        // --- Minor: zloto -> Zwinnosc +2 na 1h ---
        json jE0 = JsonArrayInsert(JsonArray(), BaltEffAbility(ABILITY_DEXTERITY, 2));
        jList = JsonArrayInsert(jList, BaltMakeSac(
            "Holdownicze ziarno",
            "100 zlota",
            "Zwinnosc +2 na 1 godzine",
            0, 100, 0, 3600.0, jE0));

        // --- Flesh: przedmiot -> Regeneracja 2 PW/6s na 1h ---
        json jE1 = JsonArrayInsert(JsonArray(), BaltEffVal(BALT_EFF_REGEN, 2));
        jList = JsonArrayInsert(jList, BaltMakeSac(
            "Ofiara z plonow",
            "Przedmiot z ekwipunku",
            "Regeneracja 2 PW co 6 sekund, 1h",
            1, 0, 0, 3600.0, jE1));

        // --- Blood: 15% maks. PW -> Kondycja +4 na 2h ---
        json jE2 = JsonArrayInsert(JsonArray(), BaltEffAbility(ABILITY_CONSTITUTION, 4));
        jList = JsonArrayInsert(jList, BaltMakeSac(
            "Ucisc ziemi",
            "15% maks. PW",
            "Kondycja +4 na 2 godziny",
            2, 15, 0, 7200.0, jE2));
    }
    else if(sAltarTag == BALT_TAG_SHADOW)
    {
        // --- Minor: zloto -> Ulepszona Niewidzialnosc na 10 min ---
        json jE0 = JsonArrayInsert(JsonArray(), BaltEffNoParam(BALT_EFF_INVIS));
        jList = JsonArrayInsert(jList, BaltMakeSac(
            "Ofiarowanie mroku",
            "400 zlota",
            "Ulepszona Niewidzialnosc na 10 min.",
            0, 400, 10, 600.0, jE0));

        // --- Flesh: przedmiot -> Zwinnosc +4 + rzuty obronne +2 na 2h ---
        json jE1 = JsonArray();
        jE1 = JsonArrayInsert(jE1, BaltEffAbility(ABILITY_DEXTERITY, 4));
        jE1 = JsonArrayInsert(jE1, BaltEffVal(BALT_EFF_SAVES, 2));
        jList = JsonArrayInsert(jList, BaltMakeSac(
            "Serce z cienia",
            "Przedmiot z ekwipunku",
            "Zwinnosc +4, Rzuty +2 na 2 godziny",
            1, 0, 15, 7200.0, jE1));

        // --- Blood: 30% maks. PW -> Sila +4, Zwinnosc +4 na 2h ---
        json jE2 = JsonArray();
        jE2 = JsonArrayInsert(jE2, BaltEffAbility(ABILITY_STRENGTH, 4));
        jE2 = JsonArrayInsert(jE2, BaltEffAbility(ABILITY_DEXTERITY, 4));
        jList = JsonArrayInsert(jList, BaltMakeSac(
            "Pakt Cienia",
            "30% maks. PW",
            "Sila +4, Zwinnosc +4 na 2 godziny",
            2, 30, 30, 7200.0, jE2));
    }

    return jList;
}

// ================================================================
// Aplikacja boonow (efektow)
// ================================================================

void BaltApplyBoon(object oPC, json jSac)
{
    float fDuration = JsonGetFloat(JsonObjectGet(jSac, "duration"));
    json  jEffs     = JsonObjectGet(jSac, "eff");
    int   nCount    = JsonGetLength(jEffs);
    int   i;

    for(i = 0; i < nCount; i++)
    {
        json jE   = JsonArrayGet(jEffs, i);
        int  nT   = JsonGetInt(JsonObjectGet(jE, "t"));
        int  nSub = JsonGetInt(JsonObjectGet(jE, "sub"));
        int  nVal = JsonGetInt(JsonObjectGet(jE, "val"));

        effect eBoon;
        int    bApply = TRUE;

        switch(nT)
        {
            case BALT_EFF_ABILITY:
                eBoon = EffectAbilityIncrease(nSub, nVal);
                break;
            case BALT_EFF_TEMP_HP:
                eBoon = EffectTemporaryHitpoints(nVal);
                break;
            case BALT_EFF_INVIS:
                eBoon = EffectInvisibility(INVISIBILITY_TYPE_IMPROVED);
                break;
            case BALT_EFF_HASTE:
                eBoon = EffectHaste();
                break;
            case BALT_EFF_REGEN:
                eBoon = EffectRegenerate(nVal, 6.0);
                break;
            case BALT_EFF_SPELL_RES:
                eBoon = EffectSpellResistanceIncrease(nVal);
                break;
            case BALT_EFF_SAVES:
                eBoon = EffectSavingThrowIncrease(SAVING_THROW_ALL, nVal, SAVING_THROW_TYPE_ALL);
                break;
            default:
                bApply = FALSE;
                break;
        }

        if(bApply)
        {
            eBoon = TagEffect(eBoon, "BALT_BOON");
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eBoon, oPC, fDuration);
        }
    }

    // Natychmiastowy efekt wizualny w miejscu gracza
    ApplyEffectAtLocation(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_LIGHTNING_M), GetLocation(oPC));
}

// ================================================================
// Korupcja: VFX i debuffs
// ================================================================

void BaltRemoveCorruptionVFX(object oPC)
{
    effect e = GetFirstEffect(oPC);
    while(GetIsEffectValid(e))
    {
        string sTag = GetEffectTag(e);
        if(sTag == BALT_VFX_TAG_LOW || sTag == BALT_VFX_TAG_HIGH || sTag == BALT_VFX_TAG_RIVEN)
            RemoveEffect(oPC, e);
        e = GetNextEffect(oPC);
    }
}

void BaltApplyCorruptionVFX(object oPC, int nCorruption)
{
    BaltRemoveCorruptionVFX(oPC);

    if(nCorruption >= BALT_CORRUPT_LOW)
    {
        effect eAura = EffectVisualEffect(VFX_DUR_AURA_EVIL);
        eAura = TagEffect(eAura, BALT_VFX_TAG_LOW);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eAura, oPC);
    }

    if(nCorruption >= BALT_CORRUPT_HIGH)
    {
        effect eAura2 = EffectVisualEffect(VFX_DUR_AURA_NEGATIVE_ENERGY);
        eAura2 = TagEffect(eAura2, BALT_VFX_TAG_HIGH);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eAura2, oPC);
    }

    if(nCorruption >= BALT_CORRUPT_MAX)
    {
        // "Dusza rozerwana" — staly debuff charyzmy; zdejmowany gdy korupcja spadnie
        effect eRiven = EffectAbilityDecrease(ABILITY_CHARISMA, 4);
        eRiven = TagEffect(eRiven, BALT_VFX_TAG_RIVEN);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eRiven, oPC);

        FloatingTextStringOnCreature(
            "Twoja dusza jest rozdarta... Mroczna moc cie konsumuje.",
            oPC, FALSE);
    }
}

// ================================================================
// Popup potwierdzenia ofiary z krwi
// ================================================================

void BaltShowBloodConfirm(object oPC, int nHPCost, string sAltarName)
{
    if(NuiFindWindow(oPC, BALT_WIN_CONFIRM) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, BALT_WIN_CONFIRM));

    float fW = GetNuiScaleDimension(oPC, 380.0);
    float fH = GetNuiScaleDimension(oPC, 170.0);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;

    string sMsg = "Czy poswieccisz " + IntToString(nHPCost) + " Punktow Wytrzymalosci"
                + " ku chwale " + sAltarName + "?\n\nTego nie da sie cofnac.";

    json jMsg = NuiLabel(JsonString(sMsg), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jMsg = NuiHeight(jMsg, GetNuiScaleDimension(oPC, 70.0));

    json jYes = NuiButton(JsonString("Skladam offare"));
    jYes = NuiId(jYes, BALT_BTN_CONFIRM);
    jYes = NuiWidth(jYes, GetNuiScaleDimension(oPC, 150.0));

    json jNo = NuiButton(JsonString("Odstepuje"));
    jNo = NuiId(jNo, BALT_BTN_CANCEL);
    jNo = NuiWidth(jNo, GetNuiScaleDimension(oPC, 100.0));

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jYes);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jNo);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jMsg);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jWin = NuiWindow(NuiCol(jCol),
        JsonString("Ofiara krwi"),
        NuiRect(fX, fY, fW, fH),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(FALSE), JsonBool(TRUE));

    NuiCreate(oPC, jWin, BALT_WIN_CONFIRM, BALT_EV_SCRIPT);
}

// ================================================================
// Budowanie okna NUI
// ================================================================

json BaltBuildWindow(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fRowH  = GetNuiScaleDimension(oPC, 36.0);
    float fProgH = GetNuiScaleDimension(oPC, 20.0);
    float fLoreH = GetNuiScaleDimension(oPC, 58.0);

    // -- Tekst klimatyczny --
    json jLore = NuiText(NuiBind(BALT_BIND_LORE), FALSE);
    jLore = NuiHeight(jLore, fLoreH);

    // -- Wiersz korupcji: etykieta + pasek postepu --
    json jCorrLbl = NuiLabel(NuiBind(BALT_BIND_CORR_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCorrLbl = NuiWidth(jCorrLbl, GetNuiScaleDimension(oPC, 200.0));
    jCorrLbl = NuiStyleForegroundColor(jCorrLbl, NuiBind(BALT_BIND_CORR_COLOR));

    json jProg = NuiProgress(NuiBind(BALT_BIND_CORRUPTION));
    jProg = NuiHeight(jProg, fProgH);

    json jCorrRow = JsonArray();
    jCorrRow = JsonArrayInsert(jCorrRow, jCorrLbl);
    jCorrRow = JsonArrayInsert(jCorrRow, jProg);

    // -- Lista ofiar (NuiList) --
    float fNameW = GetNuiScaleDimension(oPC, 165.0);
    float fCostW = GetNuiScaleDimension(oPC, 155.0);
    float fSacBW = GetNuiScaleDimension(oPC, 120.0);

    json jNameLbl = NuiLabel(NuiBind(BALT_BIND_SAC_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(BALT_BIND_SAC_COLOR));

    json jCostLbl = NuiLabel(NuiBind(BALT_BIND_SAC_COST),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCostLbl = NuiStyleForegroundColor(jCostLbl, NuiBind(BALT_BIND_SAC_COLOR));

    json jEffLbl = NuiLabel(NuiBind(BALT_BIND_SAC_EFF),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEffLbl = NuiStyleForegroundColor(jEffLbl, NuiBind(BALT_BIND_SAC_COLOR));

    json jSacBtn = NuiButton(JsonString("Zloz ofiare"));
    jSacBtn = NuiId(jSacBtn, BALT_BTN_SACRIFICE);
    jSacBtn = NuiEnabled(jSacBtn, NuiBind(BALT_BIND_SAC_ENA));
    jSacBtn = NuiWidth(jSacBtn, fSacBW);
    jSacBtn = NuiHeight(jSacBtn, fRowH - GetNuiScaleDimension(oPC, 4.0));

    json jTmpl = JsonArray();
    jTmpl = JsonArrayInsert(jTmpl,
        NuiListTemplateCell(NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jNameLbl)), fNameW), fNameW, FALSE));
    jTmpl = JsonArrayInsert(jTmpl,
        NuiListTemplateCell(NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jCostLbl)), fCostW), fCostW, FALSE));
    jTmpl = JsonArrayInsert(jTmpl,
        NuiListTemplateCell(NuiCol(JsonArrayInsert(JsonArray(), jEffLbl)), 0.0, TRUE));
    jTmpl = JsonArrayInsert(jTmpl,
        NuiListTemplateCell(NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jSacBtn)), fSacBW), fSacBW, FALSE));

    float fListH = GetNuiScaleDimension(oPC, 160.0);
    json jList = NuiList(jTmpl, NuiBind(BALT_BIND_ROWCOUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // -- Przycisk zamknij --
    json jCloseBtn = NuiButton(JsonString("Zamknij"));
    jCloseBtn = NuiId(jCloseBtn, BALT_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 100.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jCloseBtn);

    // -- Sklej kolumne --
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jLore);
    jCol = JsonArrayInsert(jCol, NuiRow(jCorrRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    json jSide    = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContW  = GetNuiScaleDimension(oPC, BALT_W - 40.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);

    json jWin = NuiWindow(NuiRow(jMainRow),
        NuiBind(BALT_BIND_TITLE),
        NuiBind(BALT_BIND_WIN_GEOM),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE));

    return jWin;
}

// ================================================================
// Wypelnianie bindow
// ================================================================

void BaltFeedWindow(object oPC, int nToken, string sAltarTag)
{
    int nCorruption = BaltGetCorruption(oPC);

    NuiSetBind(oPC, nToken, BALT_BIND_TITLE, JsonString(BaltGetAltarName(sAltarTag)));
    NuiSetBind(oPC, nToken, BALT_BIND_LORE,  JsonString(BaltGetAltarLore(sAltarTag)));

    // Pasek i kolor korupcji
    float fCorr = IntToFloat(nCorruption) / 100.0;
    NuiSetBind(oPC, nToken, BALT_BIND_CORRUPTION,
        JsonFloat(fCorr < 0.0 ? 0.0 : (fCorr > 1.0 ? 1.0 : fCorr)));
    NuiSetBind(oPC, nToken, BALT_BIND_CORR_LBL,
        JsonString("Skalanie duszy: " + IntToString(nCorruption) + "%"));

    json jCorrColor;
    if(nCorruption >= BALT_CORRUPT_HIGH)
        jCorrColor = NuiColor(210, 30, 30);
    else if(nCorruption >= BALT_CORRUPT_LOW)
        jCorrColor = NuiColor(210, 120, 20);
    else
        jCorrColor = NuiColor(170, 170, 160);
    NuiSetBind(oPC, nToken, BALT_BIND_CORR_COLOR, jCorrColor);

    // Dane listy ofiar
    json jSacs   = BaltGetSacrifices(sAltarTag);
    int  nCount  = JsonGetLength(jSacs);
    int  nGold   = GetGold(oPC);
    int  nHP     = GetCurrentHitPoints(oPC);
    int  nMaxHP  = GetMaxHitPoints(oPC);

    json jNames  = JsonArray();
    json jCosts  = JsonArray();
    json jEffs   = JsonArray();
    json jEnas   = JsonArray();
    json jColors = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jSac     = JsonArrayGet(jSacs, i);
        int  nCostT   = JsonGetInt(JsonObjectGet(jSac, "cost_type"));
        int  nCostV   = JsonGetInt(JsonObjectGet(jSac, "cost_val"));
        int  bAfford;

        if(nCostT == 0)
            bAfford = (nGold >= nCostV);
        else if(nCostT == 1)
            bAfford = TRUE;
        else
        {
            int nHPCost = nMaxHP * nCostV / 100;
            bAfford = (nHP > nHPCost + 5);
        }

        json jColor = bAfford ? NuiColor(220, 200, 150) : NuiColor(100, 85, 65);

        jNames  = JsonArrayInsert(jNames,  JsonString(JsonGetString(JsonObjectGet(jSac, "name"))));
        jCosts  = JsonArrayInsert(jCosts,  JsonString(JsonGetString(JsonObjectGet(jSac, "cost_desc"))));
        jEffs   = JsonArrayInsert(jEffs,   JsonString(JsonGetString(JsonObjectGet(jSac, "eff_desc"))));
        jEnas   = JsonArrayInsert(jEnas,   JsonBool(bAfford));
        jColors = JsonArrayInsert(jColors, jColor);
    }

    NuiSetBind(oPC, nToken, BALT_BIND_SAC_NAME,  jNames);
    NuiSetBind(oPC, nToken, BALT_BIND_SAC_COST,  jCosts);
    NuiSetBind(oPC, nToken, BALT_BIND_SAC_EFF,   jEffs);
    NuiSetBind(oPC, nToken, BALT_BIND_SAC_ENA,   jEnas);
    NuiSetBind(oPC, nToken, BALT_BIND_SAC_COLOR, jColors);
    NuiSetBind(oPC, nToken, BALT_BIND_ROWCOUNT,  JsonInt(nCount));
}

// ================================================================
// Otwieranie okna
// ================================================================

void BaltOpenWindow(object oPC, string sAltarTag)
{
    SetLocalString(oPC, BALT_LVAR_ALTAR_TAG, sAltarTag);

    int nToken = NuiFindWindow(oPC, BALT_WINDOW);
    if(nToken != 0)
    {
        BaltFeedWindow(oPC, nToken, sAltarTag);
        return;
    }

    SetLocalInt(oPC, BALT_LVAR_ITEM_IDX, -1);  // -1 = brak aktywnego celowania

    json jWin = BaltBuildWindow(oPC);
    nToken = NuiCreate(oPC, jWin, BALT_WINDOW, BALT_EV_SCRIPT);

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - GetNuiScaleDimension(oPC, BALT_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - GetNuiScaleDimension(oPC, BALT_H)) / 2.0;
    NuiSetBind(oPC, nToken, BALT_BIND_WIN_GEOM,
        NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, BALT_W), GetNuiScaleDimension(oPC, BALT_H)));

    BaltFeedWindow(oPC, nToken, sAltarTag);
}

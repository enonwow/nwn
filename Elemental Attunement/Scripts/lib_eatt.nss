// lib_eatt.nss — core logic, NUI construction and effect management
#include "lib_eatt_def"

// ----------------------------------------------------------------
// Element helper functions
// ----------------------------------------------------------------

int EattGetTier(int nPoints)
{
    if (nPoints >= EATT_TIER3_PTS) return 3;
    if (nPoints >= EATT_TIER2_PTS) return 2;
    if (nPoints >= EATT_TIER1_PTS) return 1;
    return 0;
}

string EattGetElemName(int nElem)
{
    switch (nElem)
    {
        case EATT_ELEM_FIRE:      return "Ogień";
        case EATT_ELEM_COLD:      return "Zimno";
        case EATT_ELEM_ACID:      return "Kwas";
        case EATT_ELEM_LIGHTNING: return "Błyskawica";
        case EATT_ELEM_SHADOW:    return "Mrok";
        default:                  return "?";
    }
}

string EattGetTierName(int nTier)
{
    switch (nTier)
    {
        case 1: return "Stopień I";
        case 2: return "Stopień II";
        case 3: return "Stopień III";
        default: return "Nieuśpiony";
    }
}

int EattGetOpposite(int nElem)
{
    switch (nElem)
    {
        case EATT_ELEM_FIRE:      return EATT_ELEM_COLD;
        case EATT_ELEM_COLD:      return EATT_ELEM_FIRE;
        case EATT_ELEM_ACID:      return EATT_ELEM_LIGHTNING;
        case EATT_ELEM_LIGHTNING: return EATT_ELEM_ACID;
        default:                  return -1;    // Shadow has no opposite
    }
}

int EattGetDamageTypeConst(int nElem)
{
    switch (nElem)
    {
        case EATT_ELEM_FIRE:      return DAMAGE_TYPE_FIRE;
        case EATT_ELEM_COLD:      return DAMAGE_TYPE_COLD;
        case EATT_ELEM_ACID:      return DAMAGE_TYPE_ACID;
        case EATT_ELEM_LIGHTNING: return DAMAGE_TYPE_ELECTRICAL;
        case EATT_ELEM_SHADOW:    return DAMAGE_TYPE_NEGATIVE;
        default:                  return DAMAGE_TYPE_MAGICAL;
    }
}

int EattGetSaveTypeConst(int nElem)
{
    switch (nElem)
    {
        case EATT_ELEM_FIRE:      return SAVING_THROW_TYPE_FIRE;
        case EATT_ELEM_COLD:      return SAVING_THROW_TYPE_COLD;
        case EATT_ELEM_ACID:      return SAVING_THROW_TYPE_ACID;
        case EATT_ELEM_LIGHTNING: return SAVING_THROW_TYPE_ELECTRICITY;
        case EATT_ELEM_SHADOW:    return SAVING_THROW_TYPE_DEATH;
        default:                  return SAVING_THROW_TYPE_ALL;
    }
}

string EattGetElemDesc(int nElem, int nTier)
{
    if (nElem == EATT_ELEM_FIRE)
    {
        if (nTier == 0) return "Płomień jest ci obcy — jedynie gorący powiew.\n\nAby się nastroić: przyjmuj obrażenia od ognia.";
        if (nTier == 1) return "Stopień I — Skóra twardnieje od popiołu. Ogień zna już twój oddech.\n\n+5 odporności na ogień (każde trafienie).";
        if (nTier == 2) return "Stopień II — Żyłki żarzą się bladym blaskiem. Nie płoniesz już tak łatwo.\n\n+10 odporności na ogień\n+2 do rzutów obronnych vs ogień";
        return "Stopień III — Krew stała się rozżarzonym żużlem. Atakujący oparzą się o twój dotyk.\n\n+15 odporności na ogień\n+4 do rzutów obronnych vs ogień\nTarcza ognia (obrażenia zwrotne 1k4+2)\n!10% podatność na zimno!";
    }
    if (nElem == EATT_ELEM_COLD)
    {
        if (nTier == 0) return "Mróz jest ci obcy — jedynie zimny powiew.\n\nAby się nastroić: przyjmuj obrażenia od zimna.";
        if (nTier == 1) return "Stopień I — Stopy nie marzną. Powietrze wokół ciebie milczy zimnem.\n\n+5 odporności na zimno.";
        if (nTier == 2) return "Stopień II — Oddech zostawia szron. Ciało skrywa się we mgle lodowej.\n\n+10 odporności na zimno\n+2 do rzutów obronnych vs zimno\n+10% zasłony (mgła lodu)";
        return "Stopień III — Skóra błyszczy białym szronem. Każde uderzenie wraca mrozem.\n\n+15 odporności na zimno\n+4 do rzutów obronnych vs zimno\n+10% zasłony (mgła lodu)\nTarcza zimna (obrażenia zwrotne 1k4+2)\n!10% podatność na ogień!";
    }
    if (nElem == EATT_ELEM_ACID)
    {
        if (nTier == 0) return "Kwas gryzie — lecz nie ciebie, nie jeszcze.\n\nAby się nastroić: przyjmuj obrażenia od kwasu.";
        if (nTier == 1) return "Stopień I — Skóra gęstnieje. Kwas ześlizguje się po niej jak deszcz.\n\n+5 odporności na kwas.";
        if (nTier == 2) return "Stopień II — Łuski chityny rosną pod skórą. Ciało staje się pancerzem.\n\n+10 odporności na kwas\n+2 do rzutów obronnych vs kwas\n+1 do klasy zbroi (naturalnej)";
        return "Stopień III — Powleczony jesteś warstwą twardej substancji. Niemal niezniszczalny.\n\n+15 odporności na kwas\n+4 do rzutów obronnych vs kwas\n+2 do klasy zbroi (naturalnej)\n!10% podatność na błyskawicę!";
    }
    if (nElem == EATT_ELEM_LIGHTNING)
    {
        if (nTier == 0) return "Prąd przepływa przez ciebie jak przez ziemię — bez śladu.\n\nAby się nastroić: przyjmuj obrażenia od błyskawicy.";
        if (nTier == 1) return "Stopień I — Nerwy nabrzmiały elektrycznym ładunkiem. Ruchy stają się szybsze.\n\n+5 odporności na błyskawicę.";
        if (nTier == 2) return "Stopień II — Iskry przeskakują po zbroi. Ciało reaguje chwilami nadludzkiej szybkości.\n\n+10 odporności na błyskawicę\n+2 do rzutów obronnych vs prąd\n+10% prędkości ruchu";
        return "Stopień III — Krew śpiewa elektryczną pieśnią. Jesteś jak piorun zamknięty w ciele.\n\n+15 odporności na błyskawicę\n+4 do rzutów obronnych vs prąd\n+20% prędkości ruchu\n!10% podatność na kwas!";
    }
    // Shadow
    if (nTier == 0) return "Ciemność jest ci obca — jak nocna bryza.\n\nAby się nastroić: przyjmuj obrażenia od energii mroku.";
    if (nTier == 1) return "Stopień I — Dusza zna już smak nicości. Mroczna energia ślizga się po tobie.\n\n+5 odporności na energię mroku.";
    if (nTier == 2) return "Stopień II — Cień staje się towarzyszem. Śmierć zna już twoje oblicze.\n\n+10 odporności na energię mroku\n+2 do rzutów obronnych vs śmierć\n+10% zasłony (cień)";
    return "Stopień III — Granica między żywym a martwym rozmazuje się. Stałeś się czymś innym.\n\n+15 odporności na energię mroku\n+4 do rzutów obronnych vs śmierć\n+15% zasłony (cień)";
}

string EattTierAdvanceMsg(int nElem, int nTier)
{
    if (nElem == EATT_ELEM_FIRE)
    {
        if (nTier == 1) return "[Nastrojenie] Płomień wnika w kości — skóra twardnieje od popiołu.";
        if (nTier == 2) return "[Nastrojenie] Ciało przesiąknęło ogniem. Pulsujący żar chroni od wewnątrz.";
        return "[Nastrojenie] Stałeś się pochodnią. Ostrze mrozu będzie cię ranić.";
    }
    if (nElem == EATT_ELEM_COLD)
    {
        if (nTier == 1) return "[Nastrojenie] Mróz osiadł w krwi. Powietrze wokół ciebie milknie.";
        if (nTier == 2) return "[Nastrojenie] Ziąb stał się twoją tarczą. Mgła lodowa otula ciało.";
        return "[Nastrojenie] Zima przemawia twoim głosem. Ogień będzie cię palić mocniej.";
    }
    if (nElem == EATT_ELEM_ACID)
    {
        if (nTier == 1) return "[Nastrojenie] Kwas trawi skórę — lecz i ją twardni.";
        if (nTier == 2) return "[Nastrojenie] Skóra gęstnieje. Chitynowy pancerz rośnie pod mięśniami.";
        return "[Nastrojenie] Jesteś niepodatny na zgniliznę. Lecz błyskawice cię szukają.";
    }
    if (nElem == EATT_ELEM_LIGHTNING)
    {
        if (nTier == 1) return "[Nastrojenie] Piorun żyje w nerwach.";
        if (nTier == 2) return "[Nastrojenie] Błyskawice śpią w tobie. Nogi niosą cię szybciej.";
        return "[Nastrojenie] Piorun to twoja krew. Lecz kwas trawi cię głębiej.";
    }
    // Shadow
    if (nTier == 1) return "[Nastrojenie] Mrok pełza w duszy.";
    if (nTier == 2) return "[Nastrojenie] Cień staje się towarzyszem. Śmierć zna już twoje oblicze.";
    return "[Nastrojenie] Zamazałeś granicę ze śmiercią. Jesteś czymś między.";
}

// ----------------------------------------------------------------
// Effect management
// ----------------------------------------------------------------

void EattRemoveEffects(object oPC)
{
    effect eEff = GetFirstEffect(oPC);
    while (GetIsEffectValid(eEff))
    {
        effect eNext = GetNextEffect(oPC);
        string sTag  = GetEffectTag(eEff);
        if (GetStringLeft(sTag, 5) == EATT_EFF_TAG)
            RemoveEffect(oPC, eEff);
        eEff = eNext;
    }
}

void EattApplyEffectsForElem(object oPC, int nElem, int nTier)
{
    if (nTier <= 0) return;

    int    nDmgType = EattGetDamageTypeConst(nElem);
    string sTag     = EATT_EFF_TAG + IntToString(nElem);

    // Damage resistance: 5 / 10 / 15 by tier
    effect eRes = TagEffect(EffectDamageResistance(nDmgType, nTier * 5, 0), sTag);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eRes, oPC);

    if (nTier >= 2)
    {
        // Saving throw bonus: +2 at T2, +4 at T3
        int nSaveBonus = (nTier >= 3) ? 4 : 2;
        int nSaveType  = EattGetSaveTypeConst(nElem);
        effect eSave = TagEffect(
            EffectSavingThrowIncrease(SAVING_THROW_ALL, nSaveBonus, nSaveType), sTag);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eSave, oPC);

        switch (nElem)
        {
            case EATT_ELEM_COLD:
            {
                effect eCon = TagEffect(EffectConcealment(10, MISS_CHANCE_TYPE_NORMAL), sTag);
                ApplyEffectToObject(DURATION_TYPE_PERMANENT, eCon, oPC);
                if (nTier >= 3)
                {
                    effect eShield = TagEffect(
                        EffectDamageShield(2, DAMAGE_BONUS_1D4, DAMAGE_TYPE_COLD), sTag);
                    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eShield, oPC);
                }
                break;
            }
            case EATT_ELEM_ACID:
            {
                int nAC  = (nTier >= 3) ? 2 : 1;
                effect eAC = TagEffect(EffectACIncrease(nAC, AC_NATURAL_BONUS), sTag);
                ApplyEffectToObject(DURATION_TYPE_PERMANENT, eAC, oPC);
                break;
            }
            case EATT_ELEM_LIGHTNING:
            {
                int nSpd    = (nTier >= 3) ? 20 : 10;
                effect eSpd = TagEffect(EffectMovementSpeedIncrease(nSpd), sTag);
                ApplyEffectToObject(DURATION_TYPE_PERMANENT, eSpd, oPC);
                break;
            }
            case EATT_ELEM_SHADOW:
            {
                int nCon    = (nTier >= 3) ? 15 : 10;
                effect eCon = TagEffect(EffectConcealment(nCon, MISS_CHANCE_TYPE_NORMAL), sTag);
                ApplyEffectToObject(DURATION_TYPE_PERMANENT, eCon, oPC);
                break;
            }
            default: break;
        }
    }

    if (nTier >= 3)
    {
        // Fire T3: damage shield
        if (nElem == EATT_ELEM_FIRE)
        {
            effect eShield = TagEffect(
                EffectDamageShield(2, DAMAGE_BONUS_1D4, DAMAGE_TYPE_FIRE), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eShield, oPC);
        }

        // Vulnerability to opposing element (Fire↔Cold, Acid↔Lightning, Shadow has none)
        int nOpp = EattGetOpposite(nElem);
        if (nOpp >= 0)
        {
            int    nOppDmg  = EattGetDamageTypeConst(nOpp);
            effect eVuln = TagEffect(EffectDamageVulnerability(nOppDmg, 10), sTag);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eVuln, oPC);
        }
    }
}

void EattApplyEffects(object oPC)
{
    string sUUID = GetObjectUUID(oPC);
    EattRemoveEffects(oPC);
    int i;
    for (i = 0; i < EATT_ELEM_COUNT; i++)
    {
        int nPts  = EattGetPoints(sUUID, i);
        int nTier = EattGetTier(nPts);
        EattApplyEffectsForElem(oPC, i, nTier);
    }
}

void EattRestoreEffects(object oPC)
{
    EattApplyEffects(oPC);
}

void EattAddPoints(object oPC, int nElem, int nPoints)
{
    string sUUID = GetObjectUUID(oPC);
    int nBefore  = EattGetTier(EattGetPoints(sUUID, nElem));

    EattAddPointsDB(sUUID, nElem, nPoints, EATT_MAX_PTS);

    int nAfter = EattGetTier(EattGetPoints(sUUID, nElem));
    if (nAfter > nBefore)
    {
        string sMsg = EattTierAdvanceMsg(nElem, nAfter);
        FloatingTextStringOnCreature(sMsg, oPC, FALSE);
        SendMessageToPC(oPC, sMsg);
        // Defer effect update so we're safely out of the damage handler
        DelayCommand(0.1, EattApplyEffects(oPC));

        // Refresh open window if any
        int nToken = NuiFindWindow(oPC, EATT_WINDOW);
        if (nToken != 0) DelayCommand(0.2, EattFeedWindow(oPC, nToken));
    }
}

// ----------------------------------------------------------------
// NUI window construction
// ----------------------------------------------------------------

json BuildEattWindow(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fRowH  = GetNuiScaleDimension(oPC, 36.0);
    float fListH = GetNuiScaleDimension(oPC, 195.0);
    float fDescH = GetNuiScaleDimension(oPC, 180.0);
    float fNameW = GetNuiScaleDimension(oPC, 110.0);
    float fTierW = GetNuiScaleDimension(oPC, 90.0);

    // -- Close button at top-right --
    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, EATT_BTN_CLOSE);
    jClose = NuiWidth(jClose,  GetNuiScaleDimension(oPC, 30.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jTitle = NuiLabel(JsonString("Kamień Rezonansu"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);

    json jTitleRow = JsonArray();
    jTitleRow = JsonArrayInsert(jTitleRow, jTitle);
    jTitleRow = JsonArrayInsert(jTitleRow, NuiSpacer());
    jTitleRow = JsonArrayInsert(jTitleRow, jClose);

    // -- List template: [Name | ProgressBar | Tier] --
    json jNameLbl = NuiLabel(NuiBind(EATT_BIND_ELEM_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiWidth(jNameLbl, fNameW);

    json jProgBar = NuiProgressBar(NuiBind(EATT_BIND_ELEM_PROG));

    json jTierLbl = NuiLabel(NuiBind(EATT_BIND_ELEM_TIER),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTierLbl = NuiWidth(jTierLbl, fTierW);

    json jCellContent = JsonArray();
    jCellContent = JsonArrayInsert(jCellContent, jNameLbl);
    jCellContent = JsonArrayInsert(jCellContent, jProgBar);
    jCellContent = JsonArrayInsert(jCellContent, jTierLbl);

    json jCell = NuiGroup(NuiRow(jCellContent), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, EATT_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(EATT_BIND_ELEM_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(EATT_BIND_ROWCOUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    // -- Description area --
    json jDescGroup = NuiGroup(NuiText(NuiBind(EATT_BIND_DESC), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jDescGroup = NuiHeight(jDescGroup, fDescH);

    // -- Purge button (bottom bar) --
    json jPurgeBtn = NuiButton(NuiBind(EATT_BIND_PURGE_LBL));
    jPurgeBtn = NuiId(jPurgeBtn, EATT_BTN_PURGE);
    jPurgeBtn = NuiEnabled(jPurgeBtn, NuiBind(EATT_BIND_PURGE_ENA));
    jPurgeBtn = NuiWidth(jPurgeBtn,  GetNuiScaleDimension(oPC, 240.0));
    jPurgeBtn = NuiHeight(jPurgeBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jPurgeBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());

    // -- Root column --
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTitleRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jDescGroup);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    // Center with side spacers
    json jSide    = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContW  = GetNuiScaleDimension(oPC, 460.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);

    json jWin = NuiWindow(
        NuiRow(jMainRow),
        JsonBool(FALSE),
        NuiBind(EATT_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    return jWin;
}

// ----------------------------------------------------------------
// Window lifecycle
// ----------------------------------------------------------------

void EattOpenWindow(object oPC)
{
    if (NuiFindWindow(oPC, EATT_WINDOW) != 0)
    {
        EattFeedWindow(oPC, NuiFindWindow(oPC, EATT_WINDOW));
        return;
    }

    int nToken = NuiCreate(oPC, BuildEattWindow(oPC), EATT_WINDOW, EATT_EV_SCRIPT);

    float fW = GetNuiScaleDimension(oPC, EATT_W);
    float fH = GetNuiScaleDimension(oPC, EATT_H);
    float fX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;
    NuiSetBind(oPC, nToken, EATT_WIN_GEOM, NuiRect(fX, fY, fW, fH));

    SetLocalInt(oPC, EATT_LVAR_SEL, -1);
    EattFeedWindow(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed window binds
// ----------------------------------------------------------------

void EattFeedWindow(object oPC, int nToken)
{
    string sUUID = GetObjectUUID(oPC);
    int nSel     = GetLocalInt(oPC, EATT_LVAR_SEL);

    json jNames = JsonArray();
    json jProgs = JsonArray();
    json jTiers = JsonArray();
    json jEncs  = JsonArray();

    int i;
    for (i = 0; i < EATT_ELEM_COUNT; i++)
    {
        int nPts     = EattGetPoints(sUUID, i);
        int nTier    = EattGetTier(nPts);
        float fProg  = IntToFloat(nPts) / IntToFloat(EATT_MAX_PTS);
        if (fProg > 1.0) fProg = 1.0;

        jNames = JsonArrayInsert(jNames, JsonString(EattGetElemName(i)));
        jProgs = JsonArrayInsert(jProgs, JsonFloat(fProg));
        jTiers = JsonArrayInsert(jTiers, JsonString(EattGetTierName(nTier)));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(i == nSel));
    }

    NuiSetBind(oPC, nToken, EATT_BIND_ELEM_NAME, jNames);
    NuiSetBind(oPC, nToken, EATT_BIND_ELEM_PROG, jProgs);
    NuiSetBind(oPC, nToken, EATT_BIND_ELEM_TIER, jTiers);
    NuiSetBind(oPC, nToken, EATT_BIND_ELEM_ENC,  jEncs);
    NuiSetBind(oPC, nToken, EATT_BIND_ROWCOUNT,  JsonInt(EATT_ELEM_COUNT));

    if (nSel >= 0 && nSel < EATT_ELEM_COUNT)
    {
        int nPts  = EattGetPoints(sUUID, nSel);
        int nTier = EattGetTier(nPts);
        string sDesc = EattGetElemDesc(nSel, nTier);
        // Append progress line
        sDesc = sDesc + "\n\nPostęp: " + IntToString(nPts) + " / " + IntToString(EATT_MAX_PTS) + " pkt";
        NuiSetBind(oPC, nToken, EATT_BIND_DESC, JsonString(sDesc));

        string sPurgeLabel = "Oczyść " + EattGetElemName(nSel)
            + " (" + IntToString(EATT_PURGE_COST) + " sz)";
        NuiSetBind(oPC, nToken, EATT_BIND_PURGE_LBL, JsonString(sPurgeLabel));
        NuiSetBind(oPC, nToken, EATT_BIND_PURGE_ENA, JsonBool(nTier > 0));
    }
    else
    {
        NuiSetBind(oPC, nToken, EATT_BIND_DESC,
            JsonString("Wybierz żywioł, aby zobaczyć szczegóły nastrojenia."));
        NuiSetBind(oPC, nToken, EATT_BIND_PURGE_LBL, JsonString("Oczyść"));
        NuiSetBind(oPC, nToken, EATT_BIND_PURGE_ENA, JsonBool(FALSE));
    }
}

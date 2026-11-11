#include "lib_haru_def"

// ----------------------------------------------------------------
// Creature classification
// ----------------------------------------------------------------

int HaruClassifyCreature(object oCreature)
{
    int nRace = GetRacialType(oCreature);
    if(nRace == RACIAL_TYPE_UNDEAD)                 return HARU_CTYPE_UNDEAD;
    if(nRace == RACIAL_TYPE_DRAGON)                 return HARU_CTYPE_DRAGON;
    if(nRace == RACIAL_TYPE_OUTSIDER)               return HARU_CTYPE_DEMON;
    if(nRace == RACIAL_TYPE_ANIMAL   ||
       nRace == RACIAL_TYPE_MAGICAL_BEAST ||
       nRace == RACIAL_TYPE_VERMIN)                 return HARU_CTYPE_BEAST;
    if(nRace == RACIAL_TYPE_HUMAN    ||
       nRace == RACIAL_TYPE_ELF      ||
       nRace == RACIAL_TYPE_DWARF    ||
       nRace == RACIAL_TYPE_GNOME    ||
       nRace == RACIAL_TYPE_HALFLING ||
       nRace == RACIAL_TYPE_HALF_ORC ||
       nRace == RACIAL_TYPE_HALF_ELF ||
       nRace == RACIAL_TYPE_HUMANOID_GOBLINOID   ||
       nRace == RACIAL_TYPE_HUMANOID_MONSTROUS   ||
       nRace == RACIAL_TYPE_HUMANOID_ORC         ||
       nRace == RACIAL_TYPE_HUMANOID_REPTILIAN   ||
       nRace == RACIAL_TYPE_GIANT)                  return HARU_CTYPE_HUMANOID;
    return HARU_CTYPE_OTHER;
}

// ----------------------------------------------------------------
// Sign rolling
// ----------------------------------------------------------------

// Returns json array of 6 ints, each -1/0/+1.
json HaruRollSigns(object oPC, int nCType, int nCR)
{
    json jSigns = JsonArray();
    int nLore   = GetSkillRank(SKILL_LORE, oPC);
    int i;
    for(i = 0; i < 6; i++)
    {
        // Base: uniform d3 → -1, 0, +1
        int nSign = Random(3) - 1;

        // Creature type shifts
        switch(nCType)
        {
            case HARU_CTYPE_UNDEAD:
                // Skew negative
                if(Random(3) != 0) { if(nSign > -1) nSign--; }
                break;
            case HARU_CTYPE_BEAST:
                // Skew positive
                if(Random(3) != 0) { if(nSign < 1) nSign++; }
                break;
            case HARU_CTYPE_DRAGON:
                // Polarise — push neutral signs towards extremes
                if(nSign == 0) nSign = (Random(2) == 0) ? 1 : -1;
                break;
            case HARU_CTYPE_DEMON:
                // Strongly skew negative but allow rare positives
                if(Random(4) != 0) { if(nSign > -1) nSign--; }
                break;
        }

        // High CR amplifies the absolute value
        if(nCR >= 12 && nSign != 0 && Random(3) == 0)
            ; // already extreme, keep it
        else if(nCR >= 8 && nSign == 0 && Random(4) == 0)
            nSign = (Random(2) == 0) ? 1 : -1;

        // Low lore: muddy reading — randomly override some signs
        if(nLore < 5 && Random(3) == 0)
            nSign = Random(3) - 1;

        // Clamp
        if(nSign < -1) nSign = -1;
        if(nSign >  1) nSign =  1;

        jSigns = JsonArrayInsert(jSigns, JsonInt(nSign));
    }
    return jSigns;
}

int HaruScoreFromSigns(json jSigns)
{
    int nScore = 0;
    int i;
    for(i = 0; i < 6; i++)
        nScore += JsonGetInt(JsonArrayGet(jSigns, i));
    return nScore;
}

// ----------------------------------------------------------------
// Sign display helpers
// ----------------------------------------------------------------

string HaruGetSignLabel(int nSign)
{
    if(nSign ==  1) return "Pomyslny";
    if(nSign == -1) return "Zly Omen";
    return "Neutralny";
}

json HaruGetSignColor(int nSign)
{
    if(nSign ==  1) return NuiColor(220, 180,  60);  // gold
    if(nSign == -1) return NuiColor(200,  60,  60);  // red
    return NuiColor(170, 170, 170);                  // grey
}

json HaruGetScoreColor(int nScore)
{
    if(nScore >= 3)  return NuiColor(220, 180,  60);
    if(nScore <= -3) return NuiColor(200,  60,  60);
    return NuiColor(170, 170, 170);
}

// ----------------------------------------------------------------
// Prophecy texts — creature-type overrides take priority
// ----------------------------------------------------------------

string HaruGetProphecy(int nScore, int nCType)
{
    // Creature-type specific overrides
    if(nCType == HARU_CTYPE_UNDEAD)
        return "Martwe trzewia ujawniaja pustkę tam, gdzie powinna byc dusza. "
               "Cos, co nie powinno istniec, zostalo tutaj uwolnione — "
               "granica pomiedzy zycia a smiercia jest w tym miejscu zbyt cienka.";
    if(nCType == HARU_CTYPE_DRAGON && nScore >= 3)
        return "Drakońskie organy pulsuja pradawna moca nawet po smierci. "
               "Czytac je — to jak czytac histoire swiata. "
               "Omen wskazuje na wielkosc: twoje czyny beda pamietane dlugo.";
    if(nCType == HARU_CTYPE_DRAGON && nScore <= -3)
        return "Pradawny smok, nawet martwy, przeklina tych, ktorzy go zabili. "
               "Jego krew krzyczy msciwoscia. Uwazaj — przeklenstwo moze podazac za toba.";
    if(nCType == HARU_CTYPE_DEMON)
        return "Infernalne trzewia wrzą kwasem i siarka. Proroctwo plonie jak pergamin "
               "zbyt blisko ognia — znaki sa niejednoznaczne, lecz grozba jest jasna: "
               "cos z otchlani wciaz obserwuje te sciezke.";

    // Score-based generic prophecies
    if(nScore >= 5)
        return "Kazdy organ lsni jak wypolerowany metal — rzadko zdarza sie tak doskonaly "
               "omen. Bogowie sprzyjaja twej dloni. Idz naprzod bez strachu: sukces jest "
               "w tej chwili niemal pewny, a sily sa po twojej stronie.";
    if(nScore == 4)
        return "Watróba plonie zlotym blaskiem. Bogowie sprzyjaja twym zamiarom. "
               "Omen wskazuje na triumf, lecz nie bez ceny — ktos w cieniu rowniez "
               "sie stara i moze byc szybszy.";
    if(nScore == 3)
        return "Serce silne i regularne jak bicie bębna wojennego. "
               "Bedziesz trwal tam, gdzie inni padaja. Blizszy cel jest "
               "w zasiegu reki — wyciagnij ja bez wahania.";
    if(nScore == 2)
        return "Pluca rozwiniety jak skrzydla ptaka tuż przed lotem. "
               "Cel twoj jest bliski, droga ciemna, lecz twoja determinacja "
               "przebija ciemnosc lepiej niz pochodnia.";
    if(nScore == 1)
        return "Drobna nierownosc w watróbie, lecz serce bije mocno. "
               "Pomyslnosc nie jest gwarantowana — pojdzie dobrze, "
               "jeslí nie zgubisz czujnosci w trakcie.";
    if(nScore == 0)
        return "Znaki sprzeczne — cien rownowazy swiatlo, chlos rownowazy cieplo. "
               "Ani pomyslnosc, ani kleska nie czeka: to, co nastapi, zalezy "
               "wylacznie od twoich wlasnych wyborow. Proroctwo milczy.";
    if(nScore == -1)
        return "Zóldź lekko zacmiona. Cos w cieniu czeka na chwile nieuwagi. "
               "Nie jest to wielka groźba, lecz ignorowanie jej byloby bledem. "
               "Patrz pod nogi rownié czesto co przed siebie.";
    if(nScore == -2)
        return "Sledziona peknieta w polowie — strata zbliiza sie nieuchronnie, "
               "lecz mozna ja zmniejszyc odpowiednim przygotowaniem. "
               "Omen ostrzega, nie skazuje.";
    if(nScore == -3)
        return "Watróba ciemna w polowie. Polowa twoich wysilkow obróci sie "
               "przeciwko tobie w najblizszym czasie. Zbyt wiele frontow "
               "naraz — wybierz jeden i trzymaj sie go.";
    if(nScore == -4)
        return "Zóldź czarna jak smola. Cos zgnitego czeka na twej sciezce. "
               "Omen jest powazny: nie chodzi o kleske w jednej potyczce, "
               "lecz o grozbe, która bedzie sie wlec jak cien przez wiele dni.";
    if(nScore <= -5)
        return "Wszystkie organy naznaczone przeklenstwo — bogowie odwrocili twarze. "
               "Smierc chodzi twoim sladem od dawna i teraz przyspiesza. "
               "Czarny całun na trzewach: jeden z najgorszych omenów jakie widzialy "
               "moje oczy. Szukaj spowiednika lub zloz ofiare, bo jutro moze nie przyjsc.";

    return "Proroctwo nieczytelne.";
}

// ----------------------------------------------------------------
// Effect label and application
// ----------------------------------------------------------------

string HaruGetEffectLabel(int nScore)
{
    if(nScore >= 5)  return "EFEKT: Pospiech (5 minut) — bogowie popychaja w przod.";
    if(nScore >= 3)  return "EFEKT: Rzuty obronne +2 (10 minut) — wola hartowana omenem.";
    if(nScore >= 1)  return "EFEKT: Klasa pancerza +1 (10 minut) — intuicja ostrzega przed ciosami.";
    if(nScore == 0)  return "EFEKT: Lore +2 (10 minut) — puste znaki daja tylko wiedze.";
    if(nScore >= -2) return "EFEKT: Atak -1 (10 minut) — reka niepewna po zlym omenie.";
    if(nScore >= -4) return "EFEKT: Obrazenia -2 (10 minut) — przeklenstwo oslabia uderzenie.";
    return                  "EFEKT: Przeklenstwo wszystkich statystyk (10 minut) — kara za patrzenie w otchlań.";
}

int HaruGetEffectId(int nScore)
{
    if(nScore >= 5)  return HARU_EFF_HASTE;
    if(nScore >= 3)  return HARU_EFF_SAVES;
    if(nScore >= 1)  return HARU_EFF_AC;
    if(nScore == 0)  return HARU_EFF_LORE;
    if(nScore >= -2) return HARU_EFF_ATK_DEBUF;
    if(nScore >= -4) return HARU_EFF_DAM_DEBUF;
    return HARU_EFF_CURSE;
}

void HaruApplyEffect(object oPC, int nScore)
{
    effect eEff;
    if(nScore >= 5)
        eEff = EffectHaste();
    else if(nScore >= 3)
        eEff = EffectSavingThrowIncrease(SAVING_THROW_ALL, 2, SAVING_THROW_TYPE_ALL);
    else if(nScore >= 1)
        eEff = EffectACIncrease(1, AC_DEFLECTION_BONUS);
    else if(nScore == 0)
        eEff = EffectSkillIncrease(SKILL_LORE, 2);
    else if(nScore >= -2)
        eEff = EffectAttackDecrease(1, ATTACK_BONUS_MISC);
    else if(nScore >= -4)
        eEff = EffectDamageDecrease(2, DAMAGE_TYPE_BLUDGEONING | DAMAGE_TYPE_PIERCING | DAMAGE_TYPE_SLASHING);
    else
        eEff = EffectCurse(2, 2, 2, 2, 2, 2);

    float fDur = (nScore >= 5) ? 300.0 : 600.0;
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, SupernaturalEffect(eEff), oPC, fDur);
}

// ----------------------------------------------------------------
// NUI — organ list template
// ----------------------------------------------------------------

json HaruBuildOrganTemplate(object oPC)
{
    float fRowH    = GetNuiScaleDimension(oPC, 32.0);
    float fNameW   = GetNuiScaleDimension(oPC, 140.0);

    json jNameLbl = NuiLabel(NuiBind(HARU_BIND_ORG_NAMES),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jSignLbl = NuiLabel(NuiBind(HARU_BIND_ORG_SIGNS),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSignLbl = NuiStyleForegroundColor(jSignLbl, NuiBind(HARU_BIND_ORG_COLS));

    json jTmpl = JsonArray();
    jTmpl = JsonArrayInsert(jTmpl, NuiListTemplateCell(jNameLbl, fNameW, FALSE));
    jTmpl = JsonArrayInsert(jTmpl, NuiListTemplateCell(jSignLbl, 0.0,   TRUE));
    return jTmpl;
}

// ----------------------------------------------------------------
// NUI — history list template
// ----------------------------------------------------------------

json HaruBuildHistTemplate(object oPC)
{
    float fDateW  = GetNuiScaleDimension(oPC, 50.0);
    float fCNameW = GetNuiScaleDimension(oPC, 160.0);
    float fScoreW = GetNuiScaleDimension(oPC, 46.0);

    json jDateLbl = NuiLabel(NuiBind(HARU_BIND_HIST_DATE),
                             JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDateLbl = NuiWidth(jDateLbl, fDateW);

    json jCNameLbl = NuiLabel(NuiBind(HARU_BIND_HIST_CNAME),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jScoreLbl = NuiLabel(NuiBind(HARU_BIND_HIST_SCORE),
                              JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jScoreLbl = NuiStyleForegroundColor(jScoreLbl, NuiBind(HARU_BIND_HIST_SCOL));
    jScoreLbl = NuiWidth(jScoreLbl, fScoreW);

    json jTmpl = JsonArray();
    jTmpl = JsonArrayInsert(jTmpl, NuiListTemplateCell(jDateLbl,  fDateW,  FALSE));
    jTmpl = JsonArrayInsert(jTmpl, NuiListTemplateCell(jCNameLbl, fCNameW, FALSE));
    jTmpl = JsonArrayInsert(jTmpl, NuiListTemplateCell(jScoreLbl, fScoreW, FALSE));
    return jTmpl;
}

// ----------------------------------------------------------------
// NUI — main window layout
// ----------------------------------------------------------------

json HaruBuildMainLayout(object oPC)
{
    float fBtnH   = GetNuiScaleDimension(oPC, 30.0);
    float fOrgH   = GetNuiScaleDimension(oPC, 32.0);
    float fLeftW  = GetNuiScaleDimension(oPC, 290.0);
    float fPropH  = GetNuiScaleDimension(oPC, 210.0);
    float fListH  = GetNuiScaleDimension(oPC, 210.0);

    // -- Header: title + [Kronika] + [X] --
    json jTitle = NuiLabel(NuiBind(HARU_BIND_TITLE),
                           JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jHistBtn = NuiButton(JsonString("Kronika"));
    jHistBtn = NuiId(jHistBtn, HARU_BTN_HISTORY);
    jHistBtn = NuiWidth(jHistBtn, GetNuiScaleDimension(oPC, 80.0));
    jHistBtn = NuiHeight(jHistBtn, fBtnH);

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, HARU_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 32.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jHeaderRow = JsonArray();
    jHeaderRow = JsonArrayInsert(jHeaderRow, jTitle);
    jHeaderRow = JsonArrayInsert(jHeaderRow, NuiSpacer());
    jHeaderRow = JsonArrayInsert(jHeaderRow, jHistBtn);
    jHeaderRow = JsonArrayInsert(jHeaderRow, jCloseBtn);

    // -- Left column: organ list --
    json jOrgHdr = NuiLabel(JsonString("Narzady"),
                            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jOrgHdr = NuiHeight(jOrgHdr, fBtnH);

    json jOrgList = NuiList(HaruBuildOrganTemplate(oPC),
                            NuiBind(HARU_BIND_ORG_COUNT), fOrgH);
    jOrgList = NuiHeight(jOrgList, fListH);

    json jReadingsLbl = NuiLabel(NuiBind(HARU_BIND_READINGS),
                                 JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jReadingsLbl = NuiHeight(jReadingsLbl, fBtnH);

    json jLeftChildren = JsonArray();
    jLeftChildren = JsonArrayInsert(jLeftChildren, jOrgHdr);
    jLeftChildren = JsonArrayInsert(jLeftChildren, jOrgList);
    jLeftChildren = JsonArrayInsert(jLeftChildren, jReadingsLbl);
    json jLeft = NuiWidth(NuiCol(jLeftChildren), fLeftW);

    // -- Right column: prophecy + score + effect --
    json jProphHdr = NuiLabel(JsonString("Proroctwo"),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jProphHdr = NuiHeight(jProphHdr, fBtnH);

    json jProphTxt = NuiGroup(NuiText(NuiBind(HARU_BIND_PROPHECY), FALSE),
                              TRUE, NUI_SCROLLBARS_Y);
    jProphTxt = NuiHeight(jProphTxt, fPropH);

    json jScoreLbl = NuiLabel(NuiBind(HARU_BIND_SCORE_LBL),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jScoreLbl = NuiStyleForegroundColor(jScoreLbl, NuiBind(HARU_BIND_SCORE_COL));
    jScoreLbl = NuiHeight(jScoreLbl, GetNuiScaleDimension(oPC, 26.0));

    json jEffLbl = NuiLabel(NuiBind(HARU_BIND_EFFECT_LBL),
                            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEffLbl = NuiHeight(jEffLbl, GetNuiScaleDimension(oPC, 26.0));

    json jRightChildren = JsonArray();
    jRightChildren = JsonArrayInsert(jRightChildren, jProphHdr);
    jRightChildren = JsonArrayInsert(jRightChildren, jProphTxt);
    jRightChildren = JsonArrayInsert(jRightChildren, NuiSpacer());
    jRightChildren = JsonArrayInsert(jRightChildren, jScoreLbl);
    jRightChildren = JsonArrayInsert(jRightChildren, jEffLbl);
    json jRight = NuiCol(jRightChildren);

    // -- Content row --
    json jContentRow = JsonArray();
    jContentRow = JsonArrayInsert(jContentRow, jLeft);
    jContentRow = JsonArrayInsert(jContentRow, NuiSpacer());
    jContentRow = JsonArrayInsert(jContentRow, jRight);

    // -- Bottom: Accept + Close --
    json jApplyBtn = NuiButton(JsonString("Przyjmij Wrozbę"));
    jApplyBtn = NuiId(jApplyBtn, HARU_BTN_APPLY);
    jApplyBtn = NuiEnabled(jApplyBtn, NuiBind(HARU_BIND_APPLY_ENA));
    jApplyBtn = NuiWidth(jApplyBtn, GetNuiScaleDimension(oPC, 160.0));
    jApplyBtn = NuiHeight(jApplyBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jApplyBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());

    // -- Root column --
    json jRootChildren = JsonArray();
    jRootChildren = JsonArrayInsert(jRootChildren, NuiRow(jHeaderRow));
    jRootChildren = JsonArrayInsert(jRootChildren, NuiRow(jContentRow));
    jRootChildren = JsonArrayInsert(jRootChildren, NuiRow(jBotRow));
    return NuiCol(jRootChildren);
}

// ----------------------------------------------------------------
// NUI — history window layout
// ----------------------------------------------------------------

json HaruBuildHistLayout(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fRowH  = GetNuiScaleDimension(oPC, 28.0);
    float fListH = GetNuiScaleDimension(oPC, 310.0);

    json jTotalLbl = NuiLabel(NuiBind(HARU_BIND_HIST_TOTAL),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTotalLbl = NuiHeight(jTotalLbl, fBtnH);

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, HARU_BTN_HISTCLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 32.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jHeaderRow = JsonArray();
    jHeaderRow = JsonArrayInsert(jHeaderRow, jTotalLbl);
    jHeaderRow = JsonArrayInsert(jHeaderRow, NuiSpacer());
    jHeaderRow = JsonArrayInsert(jHeaderRow, jCloseBtn);

    json jList = NuiList(HaruBuildHistTemplate(oPC),
                         NuiBind(HARU_BIND_HIST_COUNT), fRowH);
    jList = NuiHeight(jList, fListH);

    json jRootChildren = JsonArray();
    jRootChildren = JsonArrayInsert(jRootChildren, NuiRow(jHeaderRow));
    jRootChildren = JsonArrayInsert(jRootChildren, jList);
    return NuiCol(jRootChildren);
}

// ----------------------------------------------------------------
// Feed functions
// ----------------------------------------------------------------

void HaruFeedSigns(object oPC, int nToken, json jSigns)
{
    json jNames = JsonArray();
    json jLabels = JsonArray();
    json jColors = JsonArray();

    string asOrgans[6];
    asOrgans[0] = "Watroba";
    asOrgans[1] = "Serce";
    asOrgans[2] = "Pluca";
    asOrgans[3] = "Zoladek";
    asOrgans[4] = "Sledziona";
    asOrgans[5] = "Zolc";

    int i;
    for(i = 0; i < 6; i++)
    {
        int nSign = JsonGetInt(JsonArrayGet(jSigns, i));
        jNames  = JsonArrayInsert(jNames,  JsonString(asOrgans[i]));
        jLabels = JsonArrayInsert(jLabels, JsonString(HaruGetSignLabel(nSign)));
        jColors = JsonArrayInsert(jColors, HaruGetSignColor(nSign));
    }

    NuiSetBind(oPC, nToken, HARU_BIND_ORG_NAMES,  jNames);
    NuiSetBind(oPC, nToken, HARU_BIND_ORG_SIGNS,  jLabels);
    NuiSetBind(oPC, nToken, HARU_BIND_ORG_COLS,   jColors);
    NuiSetBind(oPC, nToken, HARU_BIND_ORG_COUNT,  JsonInt(6));
}

void HaruFeedProphecy(object oPC, int nToken, int nScore, string sProphecy)
{
    string sScoreLbl;
    if(nScore > 0) sScoreLbl = "Wynik: +" + IntToString(nScore);
    else           sScoreLbl = "Wynik: "  + IntToString(nScore);

    NuiSetBind(oPC, nToken, HARU_BIND_PROPHECY,  JsonString(sProphecy));
    NuiSetBind(oPC, nToken, HARU_BIND_SCORE_LBL, JsonString(sScoreLbl));
    NuiSetBind(oPC, nToken, HARU_BIND_SCORE_COL, HaruGetScoreColor(nScore));
    NuiSetBind(oPC, nToken, HARU_BIND_EFFECT_LBL,JsonString(HaruGetEffectLabel(nScore)));
}

void HaruFeedHistory(object oPC, int nToken)
{
    json jHistory = HaruGetHistory(oPC, HARU_HIST_LIMIT);
    int nCount = JsonGetLength(jHistory);

    json jDates  = JsonArray();
    json jCNames = JsonArray();
    json jScores = JsonArray();
    json jSCols  = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow        = JsonArrayGet(jHistory, i);
        int  nScore      = JsonGetInt   (JsonObjectGet(jRow, "score"));
        int  nReadAt     = JsonGetInt   (JsonObjectGet(jRow, "read_at"));
        string sCName    = JsonGetString(JsonObjectGet(jRow, "creature_name"));

        string sScoreStr;
        if(nScore > 0) sScoreStr = "+" + IntToString(nScore);
        else           sScoreStr = IntToString(nScore);

        jDates  = JsonArrayInsert(jDates,  JsonString(HaruFormatDate(nReadAt)));
        jCNames = JsonArrayInsert(jCNames, JsonString(sCName));
        jScores = JsonArrayInsert(jScores, JsonString(sScoreStr));
        jSCols  = JsonArrayInsert(jSCols,  HaruGetScoreColor(nScore));
    }

    int nTotal = HaruGetTotalReadings(oPC);
    NuiSetBind(oPC, nToken, HARU_BIND_HIST_DATE,  jDates);
    NuiSetBind(oPC, nToken, HARU_BIND_HIST_CNAME, jCNames);
    NuiSetBind(oPC, nToken, HARU_BIND_HIST_SCORE, jScores);
    NuiSetBind(oPC, nToken, HARU_BIND_HIST_SCOL,  jSCols);
    NuiSetBind(oPC, nToken, HARU_BIND_HIST_COUNT, JsonInt(nCount));
    NuiSetBind(oPC, nToken, HARU_BIND_HIST_TOTAL,
               JsonString("Kronika Haruspika — " + IntToString(nTotal) + " odczytan"));
}

// ----------------------------------------------------------------
// Window open helpers
// ----------------------------------------------------------------

void HaruOpenHistory(object oPC)
{
    int nExist = NuiFindWindow(oPC, HARU_WIN_HIST);
    if(nExist != 0) { NuiDestroy(oPC, nExist); }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, HARU_HIST_W)) / 2.0 + 30.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, HARU_HIST_H)) / 2.0 + 30.0;
    json jGeom = NuiRect(fCX, fCY,
                         GetNuiScaleDimension(oPC, HARU_HIST_W),
                         GetNuiScaleDimension(oPC, HARU_HIST_H));

    json jWin = NuiWindow(HaruBuildHistLayout(oPC),
        JsonBool(FALSE),
        NuiBind(HARU_HIST_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, HARU_WIN_HIST, HARU_EV_SCRIPT);
    NuiSetBind(oPC, nToken, HARU_HIST_GEOM, jGeom);
    HaruFeedHistory(oPC, nToken);
}

void HaruOpenReading(object oPC, object oSource)
{
    if(!GetIsObjectValid(oSource)) return;
    if(!GetLocalInt(oSource, HARU_SRC_READABLE))
    {
        SendMessageToPC(oPC, "[Haruspika] Te szczatki nie sa juz czytelne.");
        return;
    }

    // Gather source data
    string sCName = GetLocalString(oSource, HARU_SRC_CNAME);
    int    nCType = GetLocalInt   (oSource, HARU_SRC_CTYPE);
    int    nCR    = GetLocalInt   (oSource, HARU_SRC_CR);
    if(sCName == "") sCName = "Nieznana Istota";

    // Prevent double reading
    DeleteLocalInt(oSource, HARU_SRC_READABLE);

    // Roll and score
    json jSigns   = HaruRollSigns(oPC, nCType, nCR);
    int  nScore   = HaruScoreFromSigns(jSigns);
    string sProph = HaruGetProphecy(nScore, nCType);

    // Store on PC for event handler
    SetLocalJson  (oPC, HARU_LVAR_SIGNS,   jSigns);
    SetLocalInt   (oPC, HARU_LVAR_SCORE,   nScore);
    SetLocalString(oPC, HARU_LVAR_CNAME,   sCName);
    SetLocalInt   (oPC, HARU_LVAR_CTYPE,   nCType);
    SetLocalInt   (oPC, HARU_LVAR_CR,      nCR);
    DeleteLocalInt(oPC, HARU_LVAR_APPLIED);

    // Open or refresh window
    int nExist = NuiFindWindow(oPC, HARU_WIN_MAIN);
    if(nExist != 0) NuiDestroy(oPC, nExist);

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, HARU_WIN_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, HARU_WIN_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
                         GetNuiScaleDimension(oPC, HARU_WIN_W),
                         GetNuiScaleDimension(oPC, HARU_WIN_H));

    json jWin = NuiWindow(HaruBuildMainLayout(oPC),
        JsonBool(FALSE),
        NuiBind(HARU_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, HARU_WIN_MAIN, HARU_EV_SCRIPT);
    NuiSetBind(oPC, nToken, HARU_WIN_GEOM, jGeom);

    string sCTypeLabel;
    switch(nCType)
    {
        case HARU_CTYPE_UNDEAD:   sCTypeLabel = "Nieumarły";  break;
        case HARU_CTYPE_DRAGON:   sCTypeLabel = "Smok";       break;
        case HARU_CTYPE_DEMON:    sCTypeLabel = "Demon";      break;
        case HARU_CTYPE_BEAST:    sCTypeLabel = "Bestia";     break;
        case HARU_CTYPE_HUMANOID: sCTypeLabel = "Humanoid";   break;
        default:                  sCTypeLabel = "Istota";     break;
    }

    NuiSetBind(oPC, nToken, HARU_BIND_TITLE,
        JsonString("Czytanie Wnętrznosci — " + sCName + " (" + sCTypeLabel + ", CR " + IntToString(nCR) + ")"));
    NuiSetBind(oPC, nToken, HARU_BIND_APPLY_ENA, JsonBool(TRUE));

    int nTotal = HaruGetTotalReadings(oPC);
    NuiSetBind(oPC, nToken, HARU_BIND_READINGS,
        JsonString("Odczytan lacznie: " + IntToString(nTotal)));

    HaruFeedSigns(oPC, nToken, jSigns);
    HaruFeedProphecy(oPC, nToken, nScore, sProph);
}

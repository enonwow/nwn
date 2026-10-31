#include "lib_sleg_def"

// ---------------------------------------------------------------
// Type data helpers
// ---------------------------------------------------------------

string SlegTypeName(int nType)
{
    switch(nType)
    {
        case SLEG_TYPE_WARRIOR:  return "Krwawa Chwała";
        case SLEG_TYPE_MAGE:     return "Przekleństwo Wiedzy";
        case SLEG_TYPE_ROGUE:    return "Cień Złodziejstwa";
        case SLEG_TYPE_MARTYR:   return "Piętno Męczennika";
        case SLEG_TYPE_WANDERER: return "Wieczna Wędrówka";
        case SLEG_TYPE_DEVOUT:   return "Dar Bożej Łaski";
        case SLEG_TYPE_CURSED:   return "Dziedziczone Potępienie";
    }
    return "Nieznane Dziedzictwo";
}

string SlegBlessingDesc(int nType)
{
    switch(nType)
    {
        case SLEG_TYPE_WARRIOR:  return "+2 do rzutów ataku we walce wręcz.\nKrew wrogów otwiera ścieżkę miecza.";
        case SLEG_TYPE_MAGE:     return "+5 odporności na zaklęcia.\nWola poprzednika utrudnia magiczne zakłócenia.";
        case SLEG_TYPE_ROGUE:    return "+3 do Krycia i Cichego Ruchu.\nCień poprzednika otula twoje kroki.";
        case SLEG_TYPE_MARTYR:   return "+10 do maksymalnych punktów życia.\nPamiętasz, jak smakuje ból — i żyjesz dalej.";
        case SLEG_TYPE_WANDERER: return "+2 do Zwierzęcej Empatii i Przeżycia.\nDrogi wielu krain zapisały się w kościach.";
        case SLEG_TYPE_DEVOUT:   return "+2 do rzutów obronnych przeciw zaklęciom.\nŚwiatłość poprzednika osłania twoją duszę.";
        case SLEG_TYPE_CURSED:   return "+25% odporności na ogień.\nKlątwa strawiona przez ogień zahartowała ciało.";
    }
    return "Brak efektu.";
}

string SlegBurdenDesc(int nType)
{
    switch(nType)
    {
        case SLEG_TYPE_WARRIOR:  return "-2 do rzutów obronnych Woli.\nWieczne szepty poległych osłabiają umysł.";
        case SLEG_TYPE_MAGE:     return "-2 do rzutów obronnych Tężyzny.\nArcana kruszyły ciało; dziedziczysz kruche kości.";
        case SLEG_TYPE_ROGUE:    return "-2 do rzutów obronnych Woli.\nZłodziej zawsze szuka drogi ucieczki, nawet we śnie.";
        case SLEG_TYPE_MARTYR:   return "-1 do wszystkich rzutów ataku.\nCiężar ran spowalnia każdy cios.";
        case SLEG_TYPE_WANDERER: return "-1 do Pancerza.\nWędrowiec nie zna wartości osłony — ani żywego płotu.";
        case SLEG_TYPE_DEVOUT:   return "-2 do rzutów obronnych Refleksu.\nWiara zwalnia nogi; bóg wybacza, strzała nie.";
        case SLEG_TYPE_CURSED:   return "Trwała klątwa -1 do Siły.\nZło poprzedniego żywota nie znika — tylko się zmniejsza.";
    }
    return "Brak kary.";
}

string SlegFlavorText(int nType)
{
    switch(nType)
    {
        case SLEG_TYPE_WARRIOR:
            return "„Każda blizna to litera. Twoje ciało pisze kronikę tych, którzy padli przed tobą."";
        case SLEG_TYPE_MAGE:
            return "„Magia to dług. Spłacasz go skórą, kością i snem. Poprzednik zapłacił; teraz ty dziedziczysz procent."";
        case SLEG_TYPE_ROGUE:
            return "„Złodziej umiera tylko raz — resztę czasu udaje martwego. Twój cień wie, jak się chować."";
        case SLEG_TYPE_MARTYR:
            return "„Śmierć zna twoje imię z opowieści. Wróciłeś tyle razy, że przestała się spieszyć."";
        case SLEG_TYPE_WANDERER:
            return "„Nie ma drogi, której stopy przodka nie przemierzyły. Ziemia pamięta i toruje ścieżkę."";
        case SLEG_TYPE_DEVOUT:
            return "„Bóg słyszał modlitwy poprzedniego ciała. Twoje nowe usta wypowiadają stare słowa z mocą."";
        case SLEG_TYPE_CURSED:
            return "„Przekleństwo to żywa rzecz. Żywiło się przodkiem; teraz budzi się w tobie, o krok od syta."";
    }
    return "";
}

// ---------------------------------------------------------------
// Legacy type determination
// ---------------------------------------------------------------

int SlegDetermineType(object oPC)
{
    // Cursed takes precedence — most dramatic legacy
    if(GetLocalInt(oPC, SLEG_LVAR_CURSED))
        return SLEG_TYPE_CURSED;

    int nLevel   = GetHitDice(oPC);
    int nKills   = GetLocalInt(oPC, SLEG_LVAR_KILLS);
    int nDeaths  = GetLocalInt(oPC, SLEG_LVAR_DEATHS);
    int nAreas   = GetLocalInt(oPC, SLEG_LVAR_AREAS);

    // Check primary class
    int nClass1  = GetClassByPosition(1, oPC);
    int nClass2  = GetClassByPosition(2, oPC);

    int bFighter = (nClass1 == CLASS_TYPE_FIGHTER   || nClass1 == CLASS_TYPE_BARBARIAN
                 || nClass2 == CLASS_TYPE_FIGHTER   || nClass2 == CLASS_TYPE_BARBARIAN);
    int bCaster  = (nClass1 == CLASS_TYPE_WIZARD    || nClass1 == CLASS_TYPE_SORCERER
                 || nClass2 == CLASS_TYPE_WIZARD    || nClass2 == CLASS_TYPE_SORCERER);
    int bRogue   = (nClass1 == CLASS_TYPE_ROGUE     || nClass2 == CLASS_TYPE_ROGUE);
    int bDivine  = (nClass1 == CLASS_TYPE_CLERIC    || nClass1 == CLASS_TYPE_DRUID
                 || nClass1 == CLASS_TYPE_PALADIN   || nClass1 == CLASS_TYPE_RANGER
                 || nClass2 == CLASS_TYPE_CLERIC    || nClass2 == CLASS_TYPE_DRUID);

    if(bRogue && nKills >= 15)      return SLEG_TYPE_ROGUE;
    if(bFighter && nKills >= 40)    return SLEG_TYPE_WARRIOR;
    if(bCaster && nLevel >= 5)      return SLEG_TYPE_MAGE;
    if(bDivine && nLevel >= 4)      return SLEG_TYPE_DEVOUT;
    if(nDeaths >= 3)                return SLEG_TYPE_MARTYR;
    if(nAreas  >= 12)               return SLEG_TYPE_WANDERER;
    if(nKills  >= 20)               return SLEG_TYPE_WARRIOR;

    // Default: whatever class is primary
    if(bDivine)     return SLEG_TYPE_DEVOUT;
    if(bCaster)     return SLEG_TYPE_MAGE;
    if(bRogue)      return SLEG_TYPE_ROGUE;
    return SLEG_TYPE_MARTYR;
}

// ---------------------------------------------------------------
// Effect management
// ---------------------------------------------------------------

void SlegApplyOneEffect(object oPC, effect eEff)
{
    eEff = TagEffect(eEff, SLEG_EFFECT_TAG);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eEff, oPC);
}

void SlegRemoveEffects(object oPC)
{
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        if(GetEffectTag(eEff) == SLEG_EFFECT_TAG)
            RemoveEffect(oPC, eEff);
        eEff = GetNextEffect(oPC);
    }
}

void SlegApplyTypeEffects(object oPC, int nType)
{
    switch(nType)
    {
        case SLEG_TYPE_WARRIOR:
            SlegApplyOneEffect(oPC, EffectAttackIncrease(2, ATTACK_BONUS_MISC));
            SlegApplyOneEffect(oPC, EffectSavingThrowDecrease(SAVING_THROW_WILL, 2,
                               SAVING_THROW_TYPE_MIND_SPELLS));
            break;

        case SLEG_TYPE_MAGE:
            SlegApplyOneEffect(oPC, EffectSpellResistanceIncrease(5));
            SlegApplyOneEffect(oPC, EffectSavingThrowDecrease(SAVING_THROW_FORT, 2));
            break;

        case SLEG_TYPE_ROGUE:
            SlegApplyOneEffect(oPC, EffectSkillIncrease(SKILL_HIDE, 3));
            SlegApplyOneEffect(oPC, EffectSkillIncrease(SKILL_MOVE_SILENTLY, 3));
            SlegApplyOneEffect(oPC, EffectSavingThrowDecrease(SAVING_THROW_WILL, 2));
            break;

        case SLEG_TYPE_MARTYR:
            // Re-applied on each rest/enter — this is the standard trick for "permanent" THP
            SlegApplyOneEffect(oPC, EffectTemporaryHitpoints(10));
            SlegApplyOneEffect(oPC, EffectAttackDecrease(1, ATTACK_BONUS_MISC));
            break;

        case SLEG_TYPE_WANDERER:
            SlegApplyOneEffect(oPC, EffectSkillIncrease(SKILL_ANIMAL_EMPATHY, 2));
            SlegApplyOneEffect(oPC, EffectSkillIncrease(SKILL_SURVIVAL, 2));
            SlegApplyOneEffect(oPC, EffectACDecrease(1, AC_DODGE_BONUS));
            break;

        case SLEG_TYPE_DEVOUT:
            SlegApplyOneEffect(oPC, EffectSavingThrowIncrease(SAVING_THROW_ALL, 2,
                               SAVING_THROW_TYPE_DIVINE));
            SlegApplyOneEffect(oPC, EffectSavingThrowDecrease(SAVING_THROW_REFLEX, 2));
            break;

        case SLEG_TYPE_CURSED:
            SlegApplyOneEffect(oPC, EffectDamageImmunityIncrease(DAMAGE_TYPE_FIRE, 25));
            // Small stat curse echoes the original curse
            SlegApplyOneEffect(oPC, EffectCurse(1, 0, 0, 0, 0, 0));
            break;
    }
}

// Public entry point — removes old effects, re-reads DB, reapplies.
void SlegApplyEffects(object oPC)
{
    SlegRemoveEffects(oPC);
    int nType = SlegGetActiveLegacyType(GetObjectUUID(oPC));
    if(nType < 0) return;
    SlegApplyTypeEffects(oPC, nType);
}

// ---------------------------------------------------------------
// Notification on enter
// ---------------------------------------------------------------

void SlegCheckOnEnter(object oPC)
{
    int nUnclaimed = SlegUnclaimedCount(GetPCPublicCDKey(oPC, FALSE));
    if(nUnclaimed <= 0) return;

    SendMessageToPC(oPC,
        "[Dziedzictwo Cieni] Echa przeszłych żywotów czekają na ciebie. "
        "Szukaj Kamienia Pamięci, by odebrać swoje dziedzictwo.");
    FloatingTextStringOnCreature(
        "Przeszłość przemawia...", oPC, FALSE);
}

// ---------------------------------------------------------------
// NUI layout construction
// ---------------------------------------------------------------

json SlegBuildListRow(object oPC)
{
    float fRowH = GetNuiScaleDimension(oPC, 32.0);
    float fTypeW = GetNuiScaleDimension(oPC, 140.0);
    float fStatW = GetNuiScaleDimension(oPC, 55.0);

    json jTypeLbl = NuiLabel(NuiBind(SLEG_BIND_ROW_TYPE),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTypeLbl = NuiStyleForegroundColor(jTypeLbl, NuiBind(SLEG_BIND_ROW_COLOR));
    jTypeLbl = NuiWidth(jTypeLbl, fTypeW);

    json jCharLbl = NuiLabel(NuiBind(SLEG_BIND_ROW_CHAR),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCharLbl = NuiStyleForegroundColor(jCharLbl, NuiBind(SLEG_BIND_ROW_COLOR));

    json jStatLbl = NuiLabel(NuiBind(SLEG_BIND_ROW_STATUS),
                             JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatLbl = NuiStyleForegroundColor(jStatLbl, NuiBind(SLEG_BIND_ROW_COLOR));
    jStatLbl = NuiWidth(jStatLbl, fStatW);

    json jCols = JsonArray();
    jCols = JsonArrayInsert(jCols, jTypeLbl);
    jCols = JsonArrayInsert(jCols, jCharLbl);
    jCols = JsonArrayInsert(jCols, jStatLbl);

    json jRow = NuiGroup(NuiRow(jCols), FALSE, NUI_SCROLLBARS_NONE);
    jRow = NuiId(jRow, SLEG_BTN_ROW);
    jRow = NuiEncouraged(jRow, NuiBind(SLEG_BIND_ROW_ENC));
    jRow = NuiHeight(jRow, fRowH);
    return jRow;
}

json SlegBuildDetailPanel(object oPC)
{
    float fW     = GetNuiScaleDimension(oPC, SLEG_W - SLEG_LIST_W - 20.0);
    float fLblH  = GetNuiScaleDimension(oPC, 28.0);
    float fTextH = GetNuiScaleDimension(oPC, 80.0);
    float fBtnH  = GetNuiScaleDimension(oPC, 34.0);
    float fFlvH  = GetNuiScaleDimension(oPC, 60.0);

    // Legacy name
    json jName = NuiLabel(NuiBind(SLEG_BIND_DET_NAME),
                          JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiHeight(jName, fLblH);

    // Source character
    json jChar = NuiLabel(NuiBind(SLEG_BIND_DET_CHAR),
                          JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jChar = NuiHeight(jChar, GetNuiScaleDimension(oPC, 22.0));

    // Blessing header
    json jBlessHdr = NuiLabel(JsonString("Błogosławieństwo"),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBlessHdr = NuiHeight(jBlessHdr, fLblH);

    // Burden header
    json jBurdHdr = NuiLabel(JsonString("Brzemię"),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBurdHdr = NuiHeight(jBurdHdr, fLblH);

    // Blessing text
    json jBless = NuiLabel(NuiBind(SLEG_BIND_DET_BLESS),
                           JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jBless = NuiHeight(jBless, fTextH);

    // Burden text
    json jBurd = NuiLabel(NuiBind(SLEG_BIND_DET_BURDEN),
                          JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jBurd = NuiHeight(jBurd, fTextH);

    // Two columns: blessing | burden
    json jBlessCol = NuiCol(JsonArrayInsert(JsonArrayInsert(JsonArray(), jBlessHdr), jBless));
    json jBurdCol  = NuiCol(JsonArrayInsert(JsonArrayInsert(JsonArray(), jBurdHdr),  jBurd));
    json jEffRow   = NuiRow(JsonArrayInsert(JsonArrayInsert(JsonArray(), jBlessCol), jBurdCol));

    // Flavor text
    json jFlavor = NuiLabel(NuiBind(SLEG_BIND_DET_FLAVOR),
                            JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jFlavor = NuiHeight(jFlavor, fFlvH);

    // Claim button
    json jClaimBtn = NuiButton(NuiBind(SLEG_BIND_CLAIM_LBL));
    jClaimBtn = NuiId(jClaimBtn, SLEG_BTN_CLAIM);
    jClaimBtn = NuiEnabled(jClaimBtn, NuiBind(SLEG_BIND_CLAIM_ENA));
    jClaimBtn = NuiHeight(jClaimBtn, fBtnH);

    // Status label (shown when this entry is already claimed)
    json jActiveLbl = NuiLabel(NuiBind(SLEG_BIND_ACTIVE_LBL),
                               JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jActiveLbl = NuiVisible(jActiveLbl, NuiBind(SLEG_BIND_ACTIVE_VIS));
    jActiveLbl = NuiHeight(jActiveLbl, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jClaimBtn);
    jBotRow = JsonArrayInsert(jBotRow, jActiveLbl);

    json jDetailItems = JsonArray();
    jDetailItems = JsonArrayInsert(jDetailItems, jName);
    jDetailItems = JsonArrayInsert(jDetailItems, jChar);
    jDetailItems = JsonArrayInsert(jDetailItems, jEffRow);
    jDetailItems = JsonArrayInsert(jDetailItems, jFlavor);
    jDetailItems = JsonArrayInsert(jDetailItems, NuiRow(jBotRow));

    return NuiCol(jDetailItems);
}

void SlegCreateWindow(object oPC)
{
    float fListW = GetNuiScaleDimension(oPC, SLEG_LIST_W);
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);

    // Left panel: header + scrollable list
    json jListHdr = NuiLabel(JsonString("Ślady Przeszłości"),
                             JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jListHdr = NuiHeight(jListHdr, fBtnH);

    json jList = NuiList(SlegBuildListRow(oPC), GetNuiScaleDimension(oPC, 32.0));

    json jLeftItems = JsonArray();
    jLeftItems = JsonArrayInsert(jLeftItems, jListHdr);
    jLeftItems = JsonArrayInsert(jLeftItems, jList);
    json jLeft = NuiWidth(NuiCol(jLeftItems), fListW);

    // Right panel
    json jRight = SlegBuildDetailPanel(oPC);

    json jMain = NuiRow(JsonArrayInsert(JsonArrayInsert(JsonArray(), jLeft), jRight));

    // -1.0 for x/y centers the window
    json jGeom = NuiRect(-1.0, -1.0, SLEG_W, SLEG_H);

    json jWin = NuiWindow(jMain,
        JsonString("Dziedzictwo Cieni"),
        NuiBind(SLEG_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(FALSE));

    NuiCreate(oPC, jWin, SLEG_WINDOW, SLEG_EV_SCRIPT);
    int nToken = NuiFindWindow(oPC, SLEG_WINDOW);
    NuiSetBind(oPC, nToken, SLEG_WIN_GEOM, jGeom);
}

// ---------------------------------------------------------------
// Feed functions
// ---------------------------------------------------------------

void SlegFeedList(object oPC, int nToken)
{
    string sCDKey = GetPCPublicCDKey(oPC, FALSE);
    json jLegacies = SlegGetLegacies(sCDKey);
    int nCount = JsonGetLength(jLegacies);

    json jTypes   = JsonArray();
    json jChars   = JsonArray();
    json jStats   = JsonArray();
    json jColors  = JsonArray();
    json jEncs    = JsonArray();

    json cUnclaimed = NuiColor(255, 220, 100, 255);
    json cClaimed   = NuiColor(130, 130, 130, 255);

    int nSelId = GetLocalInt(oPC, SLEG_LVAR_SEL_ID);

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow     = JsonArrayGet(jLegacies, i);
        int  nId      = JsonGetInt   (JsonObjectGet(jRow, "id"));
        string sName  = JsonGetString(JsonObjectGet(jRow, "source_name"));
        int  nType    = JsonGetInt   (JsonObjectGet(jRow, "legacy_type"));
        int  bClaimed = JsonGetInt   (JsonObjectGet(jRow, "is_claimed"));

        jTypes  = JsonArrayInsert(jTypes,  JsonString(SlegTypeName(nType)));
        jChars  = JsonArrayInsert(jChars,  JsonString(sName));
        jStats  = JsonArrayInsert(jStats,  JsonString(bClaimed ? "Odebrane" : "Wolne"));
        jColors = JsonArrayInsert(jColors, bClaimed ? cClaimed : cUnclaimed);
        jEncs   = JsonArrayInsert(jEncs,   JsonBool(nId == nSelId));
    }

    NuiSetBind(oPC, nToken, SLEG_BIND_ROW_TYPE,   jTypes);
    NuiSetBind(oPC, nToken, SLEG_BIND_ROW_CHAR,   jChars);
    NuiSetBind(oPC, nToken, SLEG_BIND_ROW_STATUS, jStats);
    NuiSetBind(oPC, nToken, SLEG_BIND_ROW_COLOR,  jColors);
    NuiSetBind(oPC, nToken, SLEG_BIND_ROW_ENC,    jEncs);
}

void SlegFeedDetail(object oPC, int nToken, int nId)
{
    json jRec = SlegGetLegacyById(nId);
    if(JsonGetType(jRec) == JSON_TYPE_NULL)
    {
        NuiSetBind(oPC, nToken, SLEG_BIND_DET_NAME,   JsonString(""));
        NuiSetBind(oPC, nToken, SLEG_BIND_DET_CHAR,   JsonString(""));
        NuiSetBind(oPC, nToken, SLEG_BIND_DET_BLESS,  JsonString(""));
        NuiSetBind(oPC, nToken, SLEG_BIND_DET_BURDEN, JsonString(""));
        NuiSetBind(oPC, nToken, SLEG_BIND_DET_FLAVOR, JsonString(""));
        NuiSetBind(oPC, nToken, SLEG_BIND_CLAIM_ENA,  JsonBool(FALSE));
        NuiSetBind(oPC, nToken, SLEG_BIND_ACTIVE_VIS, JsonBool(FALSE));
        return;
    }

    int    nType      = JsonGetInt   (JsonObjectGet(jRec, "legacy_type"));
    string sCharName  = JsonGetString(JsonObjectGet(jRec, "source_name"));
    int    bClaimed   = JsonGetInt   (JsonObjectGet(jRec, "is_claimed"));

    int bHasActive = SlegHasActiveLegacy(GetObjectUUID(oPC));
    // Can claim only if: this record is unclaimed AND PC has no active legacy
    int bCanClaim  = (!bClaimed && !bHasActive);

    NuiSetBind(oPC, nToken, SLEG_BIND_DET_NAME,   JsonString(SlegTypeName(nType)));
    NuiSetBind(oPC, nToken, SLEG_BIND_DET_CHAR,   JsonString("Echo: " + sCharName));
    NuiSetBind(oPC, nToken, SLEG_BIND_DET_BLESS,  JsonString(SlegBlessingDesc(nType)));
    NuiSetBind(oPC, nToken, SLEG_BIND_DET_BURDEN, JsonString(SlegBurdenDesc(nType)));
    NuiSetBind(oPC, nToken, SLEG_BIND_DET_FLAVOR, JsonString(SlegFlavorText(nType)));

    NuiSetBind(oPC, nToken, SLEG_BIND_CLAIM_ENA,  JsonBool(bCanClaim));
    NuiSetBind(oPC, nToken, SLEG_BIND_CLAIM_LBL,  JsonString("Przyjmij dziedzictwo"));
    NuiSetBind(oPC, nToken, SLEG_BIND_ACTIVE_VIS, JsonBool(bClaimed));
    NuiSetBind(oPC, nToken, SLEG_BIND_ACTIVE_LBL, JsonString(
        bClaimed ? "To dziedzictwo zostało już odebrane." : ""));
}

// Public entry point — build window and populate.
void SlegOpenWindow(object oPC)
{
    if(NuiFindWindow(oPC, SLEG_WINDOW) != 0)
    {
        NuiDestroy(oPC, NuiFindWindow(oPC, SLEG_WINDOW));
    }

    string sCDKey = GetPCPublicCDKey(oPC, FALSE);
    json jLegacies = SlegGetLegacies(sCDKey);

    if(JsonGetLength(jLegacies) == 0)
    {
        SendMessageToPC(oPC,
            "[Dziedzictwo Cieni] Kamień milczy — nie ma jeszcze ech poprzednich żywotów.");
        return;
    }

    SlegCreateWindow(oPC);
    int nToken = NuiFindWindow(oPC, SLEG_WINDOW);
    if(nToken == 0) return;

    SlegFeedList(oPC, nToken);

    // Pre-select first unclaimed, or first record
    int nFirstId = JsonGetInt(JsonObjectGet(JsonArrayGet(jLegacies, 0), "id"));
    int i;
    for(i = 0; i < JsonGetLength(jLegacies); i++)
    {
        json jRow = JsonArrayGet(jLegacies, i);
        if(!JsonGetInt(JsonObjectGet(jRow, "is_claimed")))
        {
            nFirstId = JsonGetInt(JsonObjectGet(jRow, "id"));
            break;
        }
    }
    SetLocalInt(oPC, SLEG_LVAR_SEL_ID, nFirstId);
    SlegFeedDetail(oPC, nToken, nFirstId);
    SlegFeedList(oPC, nToken);
}

// ---------------------------------------------------------------
// Record legacy on death
// ---------------------------------------------------------------

void SlegRecordDeath(object oPC)
{
    string sUUID = GetObjectUUID(oPC);
    // One legacy per character life — don't record duplicates
    if(SlegHasRecord(sUUID)) return;

    int nType = SlegDetermineType(oPC);
    if(nType == SLEG_TYPE_NONE) return;

    string sCDKey    = GetPCPublicCDKey(oPC, FALSE);
    string sCharName = GetName(oPC);

    SlegRecordLegacy(sCDKey, sUUID, sCharName, nType);

    SendMessageToPC(oPC,
        "[Dziedzictwo Cieni] Twoje czyny zapisały się w Kamieniu Pamięci. "
        "Kolejna postać tego gracza może odebrać twoje dziedzictwo.");

    // Track death count for future legacy determination
    SetLocalInt(oPC, SLEG_LVAR_DEATHS, GetLocalInt(oPC, SLEG_LVAR_DEATHS) + 1);
}

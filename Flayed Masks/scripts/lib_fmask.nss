#include "lib_fmask_def"

// ----------------------------------------------------------------
// Racial helper text
// ----------------------------------------------------------------

string FmaskRaceName(int nRacialType)
{
    switch(nRacialType)
    {
        case RACIAL_TYPE_DWARF:    return "Krasnolud";
        case RACIAL_TYPE_ELF:      return "Elf";
        case RACIAL_TYPE_HALFELF:  return "Polelf";
        case RACIAL_TYPE_HALFLING: return "Niziolek";
        case RACIAL_TYPE_GNOME:    return "Gnom";
        case RACIAL_TYPE_HALFORC:  return "Polork";
        default:                   return "Czlowiek";
    }
}

string FmaskBonusDescription(int nRacialType)
{
    switch(nRacialType)
    {
        case RACIAL_TYPE_DWARF:    return "+2 obrony przed magią";
        case RACIAL_TYPE_ELF:      return "Widzenie w ciemności";
        case RACIAL_TYPE_HALFELF:  return "Widzenie w ciemności";
        case RACIAL_TYPE_HALFORC:  return "+2 Siły";
        case RACIAL_TYPE_HALFLING: return "+1 do ataku";
        case RACIAL_TYPE_GNOME:    return "+3 do Spellcraft";
        default:                   return "+3 do Ukrywania";
    }
}

string FmaskFlavorText(int nRacialType, int bCursed)
{
    if(bCursed)
        return "Maska oddycha. Powoli, lecz wyraźnie — jakby płuca za nią nigdy nie przestały pracować. Lepiej jej nie nosić zbyt długo.";

    switch(nRacialType)
    {
        case RACIAL_TYPE_DWARF:
            return "Skóra szorstka jak granit, broda przesiąknięta brudem i runą. W pustych oczach czai się zwierający gniew niesiony przez pokolenia.";
        case RACIAL_TYPE_ELF:
            return "Ostrość rysów kryje coś nieludzkiego — zbyt symetryczne, zbyt blade. W półprzymkniętych powiekach widać dalekie, obojętne niebo.";
        case RACIAL_TYPE_HALFELF:
            return "Twarz nosząca piętno dwóch ras, nie należąca do żadnej. Wyraz zmienia się, jakby nie wiedzieć, skąd przyszła i dokąd odejdzie.";
        case RACIAL_TYPE_HALFORC:
            return "Wyraźne kły, niska czaszka, gruba skóra. Ta twarz nigdy nie kłamała — zbyt ciężka, zbyt prawdziwa.";
        case RACIAL_TYPE_HALFLING:
            return "Niewinne rysy, wypłowiałe oczy. W kąciku ust tkwi chytry uśmiech, który widziałeś tuż przed śmiercią swojego złodziejaszka.";
        case RACIAL_TYPE_GNOME:
            return "Wielkie, pełne ciekawości oczy i orli nos przesiąknięty aromatem reagentów. Wystarczy ją nosić, by poczuć, że za każdym kamieniem kryje się tajemnica.";
        default:
            return "Pospolita twarz — na tyle, że może należeć do każdego. I właśnie to ją czyni idealną maską.";
    }
}

// ----------------------------------------------------------------
// Appearance serialization
// ----------------------------------------------------------------

json FmaskSerializeAppearance(object oObj)
{
    json j = JsonObject();
    j = JsonObjectSet(j, "app",   JsonInt(GetAppearanceType(oObj)));
    j = JsonObjectSet(j, "phen",  JsonInt(GetPhenoType(oObj)));
    j = JsonObjectSet(j, "cskin", JsonInt(GetColor(oObj, COLOR_CHANNEL_SKIN)));
    j = JsonObjectSet(j, "chair", JsonInt(GetColor(oObj, COLOR_CHANNEL_HAIR)));
    j = JsonObjectSet(j, "ctat1", JsonInt(GetColor(oObj, COLOR_CHANNEL_TATTOO1)));
    j = JsonObjectSet(j, "ctat2", JsonInt(GetColor(oObj, COLOR_CHANNEL_TATTOO2)));
    j = JsonObjectSet(j, "head",      JsonInt(GetCreatureBodyPart(CREATURE_PART_HEAD,            oObj)));
    j = JsonObjectSet(j, "neck",      JsonInt(GetCreatureBodyPart(CREATURE_PART_NECK,            oObj)));
    j = JsonObjectSet(j, "torso",     JsonInt(GetCreatureBodyPart(CREATURE_PART_TORSO,           oObj)));
    j = JsonObjectSet(j, "pelvis",    JsonInt(GetCreatureBodyPart(CREATURE_PART_PELVIS,          oObj)));
    j = JsonObjectSet(j, "belt",      JsonInt(GetCreatureBodyPart(CREATURE_PART_BELT,            oObj)));
    j = JsonObjectSet(j, "lshin",     JsonInt(GetCreatureBodyPart(CREATURE_PART_LEFT_SHIN,       oObj)));
    j = JsonObjectSet(j, "rshin",     JsonInt(GetCreatureBodyPart(CREATURE_PART_RIGHT_SHIN,      oObj)));
    j = JsonObjectSet(j, "lthigh",    JsonInt(GetCreatureBodyPart(CREATURE_PART_LEFT_THIGH,      oObj)));
    j = JsonObjectSet(j, "rthigh",    JsonInt(GetCreatureBodyPart(CREATURE_PART_RIGHT_THIGH,     oObj)));
    j = JsonObjectSet(j, "lshoulder", JsonInt(GetCreatureBodyPart(CREATURE_PART_LEFT_SHOULDER,   oObj)));
    j = JsonObjectSet(j, "rshoulder", JsonInt(GetCreatureBodyPart(CREATURE_PART_RIGHT_SHOULDER,  oObj)));
    j = JsonObjectSet(j, "lbicep",    JsonInt(GetCreatureBodyPart(CREATURE_PART_LEFT_BICEP,      oObj)));
    j = JsonObjectSet(j, "rbicep",    JsonInt(GetCreatureBodyPart(CREATURE_PART_RIGHT_BICEP,     oObj)));
    j = JsonObjectSet(j, "lforearm",  JsonInt(GetCreatureBodyPart(CREATURE_PART_LEFT_FOREARM,    oObj)));
    j = JsonObjectSet(j, "rforearm",  JsonInt(GetCreatureBodyPart(CREATURE_PART_RIGHT_FOREARM,   oObj)));
    j = JsonObjectSet(j, "lhand",     JsonInt(GetCreatureBodyPart(CREATURE_PART_LEFT_HAND,       oObj)));
    j = JsonObjectSet(j, "rhand",     JsonInt(GetCreatureBodyPart(CREATURE_PART_RIGHT_HAND,      oObj)));
    j = JsonObjectSet(j, "lfoot",     JsonInt(GetCreatureBodyPart(CREATURE_PART_LEFT_FOOT,       oObj)));
    j = JsonObjectSet(j, "rfoot",     JsonInt(GetCreatureBodyPart(CREATURE_PART_RIGHT_FOOT,      oObj)));
    return j;
}

void FmaskApplyAppearance(object oPC, json jApp)
{
    SetAppearanceType(oPC, JsonGetInt(JsonObjectGet(jApp, "app")));
    SetPhenoType(JsonGetInt(JsonObjectGet(jApp, "phen")), oPC);
    SetColor(oPC, COLOR_CHANNEL_SKIN,    JsonGetInt(JsonObjectGet(jApp, "cskin")));
    SetColor(oPC, COLOR_CHANNEL_HAIR,    JsonGetInt(JsonObjectGet(jApp, "chair")));
    SetColor(oPC, COLOR_CHANNEL_TATTOO1, JsonGetInt(JsonObjectGet(jApp, "ctat1")));
    SetColor(oPC, COLOR_CHANNEL_TATTOO2, JsonGetInt(JsonObjectGet(jApp, "ctat2")));
    SetCreatureBodyPart(CREATURE_PART_HEAD,            JsonGetInt(JsonObjectGet(jApp, "head")),      oPC);
    SetCreatureBodyPart(CREATURE_PART_NECK,            JsonGetInt(JsonObjectGet(jApp, "neck")),      oPC);
    SetCreatureBodyPart(CREATURE_PART_TORSO,           JsonGetInt(JsonObjectGet(jApp, "torso")),     oPC);
    SetCreatureBodyPart(CREATURE_PART_PELVIS,          JsonGetInt(JsonObjectGet(jApp, "pelvis")),    oPC);
    SetCreatureBodyPart(CREATURE_PART_BELT,            JsonGetInt(JsonObjectGet(jApp, "belt")),      oPC);
    SetCreatureBodyPart(CREATURE_PART_LEFT_SHIN,       JsonGetInt(JsonObjectGet(jApp, "lshin")),     oPC);
    SetCreatureBodyPart(CREATURE_PART_RIGHT_SHIN,      JsonGetInt(JsonObjectGet(jApp, "rshin")),     oPC);
    SetCreatureBodyPart(CREATURE_PART_LEFT_THIGH,      JsonGetInt(JsonObjectGet(jApp, "lthigh")),    oPC);
    SetCreatureBodyPart(CREATURE_PART_RIGHT_THIGH,     JsonGetInt(JsonObjectGet(jApp, "rthigh")),    oPC);
    SetCreatureBodyPart(CREATURE_PART_LEFT_SHOULDER,   JsonGetInt(JsonObjectGet(jApp, "lshoulder")), oPC);
    SetCreatureBodyPart(CREATURE_PART_RIGHT_SHOULDER,  JsonGetInt(JsonObjectGet(jApp, "rshoulder")), oPC);
    SetCreatureBodyPart(CREATURE_PART_LEFT_BICEP,      JsonGetInt(JsonObjectGet(jApp, "lbicep")),    oPC);
    SetCreatureBodyPart(CREATURE_PART_RIGHT_BICEP,     JsonGetInt(JsonObjectGet(jApp, "rbicep")),    oPC);
    SetCreatureBodyPart(CREATURE_PART_LEFT_FOREARM,    JsonGetInt(JsonObjectGet(jApp, "lforearm")),  oPC);
    SetCreatureBodyPart(CREATURE_PART_RIGHT_FOREARM,   JsonGetInt(JsonObjectGet(jApp, "rforearm")),  oPC);
    SetCreatureBodyPart(CREATURE_PART_LEFT_HAND,       JsonGetInt(JsonObjectGet(jApp, "lhand")),     oPC);
    SetCreatureBodyPart(CREATURE_PART_RIGHT_HAND,      JsonGetInt(JsonObjectGet(jApp, "rhand")),     oPC);
    SetCreatureBodyPart(CREATURE_PART_LEFT_FOOT,       JsonGetInt(JsonObjectGet(jApp, "lfoot")),     oPC);
    SetCreatureBodyPart(CREATURE_PART_RIGHT_FOOT,      JsonGetInt(JsonObjectGet(jApp, "rfoot")),     oPC);
}

// ----------------------------------------------------------------
// Racial bonus effects
// ----------------------------------------------------------------

void FmaskRemoveBonus(object oPC)
{
    effect eCheck = GetFirstEffect(oPC);
    while(GetIsEffectValid(eCheck))
    {
        if(GetEffectTag(eCheck) == FMASK_EFFECT_TAG)
            RemoveEffect(oPC, eCheck);
        eCheck = GetNextEffect(oPC);
    }
}

void FmaskApplyBonus(object oPC, int nRacialType)
{
    FmaskRemoveBonus(oPC);

    effect eBonus;
    switch(nRacialType)
    {
        case RACIAL_TYPE_DWARF:
            eBonus = EffectSavingThrowIncrease(SAVING_THROW_ALL, 2, SAVING_THROW_TYPE_SPELL);
            break;
        case RACIAL_TYPE_ELF:
        case RACIAL_TYPE_HALFELF:
            eBonus = EffectDarkvision();
            break;
        case RACIAL_TYPE_HALFORC:
            eBonus = EffectAbilityIncrease(ABILITY_STRENGTH, 2);
            break;
        case RACIAL_TYPE_HALFLING:
            eBonus = EffectAttackIncrease(1, ATTACK_BONUS_MISC);
            break;
        case RACIAL_TYPE_GNOME:
            eBonus = EffectSkillIncrease(SKILL_SPELLCRAFT, 3);
            break;
        default:
            eBonus = EffectSkillIncrease(SKILL_HIDE, 3);
            break;
    }

    eBonus = TagEffect(eBonus, FMASK_EFFECT_TAG);
    eBonus = ExtraordinaryEffect(eBonus);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eBonus, oPC);
}

// ----------------------------------------------------------------
// Cursed whisper (runs on a delayed loop while mask is worn)
// ----------------------------------------------------------------

void FmaskWhisperTick(object oPC);

void FmaskScheduleWhisper(object oPC)
{
    float fDelay = IntToFloat(FMASK_CURSE_WHISPER_MIN + Random(FMASK_CURSE_WHISPER_RND));
    DelayCommand(fDelay, FmaskWhisperTick(oPC));
}

void FmaskWhisperTick(object oPC)
{
    if(GetLocalInt(oPC, FMASK_LVAR_WORN_ID) <= 0) return;

    string sWhisper;
    switch(Random(6))
    {
        case 0:  sWhisper = "\"...pamiętasz jak mnie zabiłeś...\""; break;
        case 1:  sWhisper = "\"...moje oczy płoną w twojej głowie...\""; break;
        case 2:  sWhisper = "\"...zdejmij tę twarz... zdejmij...\""; break;
        case 3:  sWhisper = "\"...jesteś mną teraz... nie wiesz tego?...\""; break;
        case 4:  sWhisper = "\"...czuję twoją krew... ciepłą...\""; break;
        default: sWhisper = "\"...nie zasługujesz na moją twarz...\""; break;
    }

    FloatingTextStringOnCreature(sWhisper, oPC, FALSE);
    FmaskScheduleWhisper(oPC);
}

// ----------------------------------------------------------------
// Wear / remove
// ----------------------------------------------------------------

void FmaskWearMask(object oPC, int nMaskId)
{
    json jMask = FmaskGetMask(nMaskId);
    if(JsonGetType(jMask) == JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Zdarty Oblicze] Maska nie istnieje.");
        return;
    }

    int nUses = JsonGetInt(JsonObjectGet(jMask, "uses_remaining"));
    if(nUses <= 0)
    {
        SendMessageToPC(oPC, "[Zdarty Oblicze] Ta maska rozpadła się w pył.");
        FmaskDeleteMask(nMaskId);
        return;
    }

    // Serialize current appearance for restoration
    json jOrig = FmaskSerializeAppearance(oPC);
    string sOrigJson = JsonDump(jOrig);

    // Apply creature appearance
    int nApp   = JsonGetInt(JsonObjectGet(jMask, "appearance"));
    int nPhen  = JsonGetInt(JsonObjectGet(jMask, "phenotype"));
    int nCSkin = JsonGetInt(JsonObjectGet(jMask, "color_skin"));
    int nCHair = JsonGetInt(JsonObjectGet(jMask, "color_hair"));
    int nCTat1 = JsonGetInt(JsonObjectGet(jMask, "color_tattoo1"));
    int nCTat2 = JsonGetInt(JsonObjectGet(jMask, "color_tattoo2"));

    string sPartsJson = JsonGetString(JsonObjectGet(jMask, "parts_json"));
    json jParts = JsonParse(sPartsJson);

    SetAppearanceType(oPC, nApp);
    SetPhenoType(nPhen, oPC);
    SetColor(oPC, COLOR_CHANNEL_SKIN,    nCSkin);
    SetColor(oPC, COLOR_CHANNEL_HAIR,    nCHair);
    SetColor(oPC, COLOR_CHANNEL_TATTOO1, nCTat1);
    SetColor(oPC, COLOR_CHANNEL_TATTOO2, nCTat2);

    if(JsonGetType(jParts) == JSON_TYPE_OBJECT)
        FmaskApplyAppearance(oPC, jParts);

    // Apply racial bonus
    int nRace = JsonGetInt(JsonObjectGet(jMask, "racial_type"));
    FmaskApplyBonus(oPC, nRace);

    // Track state
    SetLocalInt   (oPC, FMASK_LVAR_WORN_ID,   nMaskId);
    SetLocalString(oPC, FMASK_LVAR_ORIG_JSON,  sOrigJson);
    FmaskSetWorn(oPC, nMaskId, sOrigJson);

    // Decrement uses; delete if spent
    FmaskDecrementUses(nMaskId);
    if(nUses - 1 <= 0)
        FmaskDeleteMask(nMaskId);

    string sName = JsonGetString(JsonObjectGet(jMask, "creature_name"));
    int bCursed  = JsonGetInt(JsonObjectGet(jMask, "is_cursed"));

    if(bCursed)
    {
        FloatingTextStringOnCreature("Coś niepokojącego wciska się w twoje rysy...", oPC, FALSE);
        SendMessageToPC(oPC, "[Zdarty Oblicze] Nałożyłeś przeklętą maskę " + sName + ". Pulsuje.");
        FmaskScheduleWhisper(oPC);
    }
    else
    {
        FloatingTextStringOnCreature("Obdierasz twarz... i nakładasz ją na swoją.", oPC, FALSE);
        SendMessageToPC(oPC, "[Zdarty Oblicze] Nałożyłeś maskę " + sName + ". (" + IntToString(nUses - 1) + " użyć pozostało)");
    }
}

void FmaskRemoveMask(object oPC)
{
    int nWornId = GetLocalInt(oPC, FMASK_LVAR_WORN_ID);
    if(nWornId <= 0)
    {
        SendMessageToPC(oPC, "[Zdarty Oblicze] Nie nosisz żadnej maski.");
        return;
    }

    string sOrigJson = GetLocalString(oPC, FMASK_LVAR_ORIG_JSON);
    if(sOrigJson != "")
    {
        json jOrig = JsonParse(sOrigJson);
        if(JsonGetType(jOrig) == JSON_TYPE_OBJECT)
            FmaskApplyAppearance(oPC, jOrig);
    }

    FmaskRemoveBonus(oPC);

    DeleteLocalInt   (oPC, FMASK_LVAR_WORN_ID);
    DeleteLocalString(oPC, FMASK_LVAR_ORIG_JSON);
    FmaskClearWorn(oPC);

    FloatingTextStringOnCreature("Odrywasz cudzą twarz od swojej...", oPC, FALSE);
    SendMessageToPC(oPC, "[Zdarty Oblicze] Zdjąłeś maskę. Twoja własna twarz powróciła.");
}

// ----------------------------------------------------------------
// Flay target handler (called from sys_on_target)
// ----------------------------------------------------------------

void FmaskHandleFlayTarget(object oPC)
{
    object oTarget = GetTargetingModeSelectedObject();

    if(!GetIsObjectValid(oTarget) || GetObjectType(oTarget) != OBJECT_TYPE_CREATURE)
    {
        SendMessageToPC(oPC, "[Zdarty Oblicze] Cel musi być istotą.");
        return;
    }

    if(GetCurrentHitPoints(oTarget) > 0)
    {
        SendMessageToPC(oPC, "[Zdarty Oblicze] Istota musi być martwa.");
        return;
    }

    int nRace = GetRacialType(oTarget);
    if(nRace != RACIAL_TYPE_HUMAN    && nRace != RACIAL_TYPE_DWARF  &&
       nRace != RACIAL_TYPE_ELF      && nRace != RACIAL_TYPE_HALFELF &&
       nRace != RACIAL_TYPE_HALFLING && nRace != RACIAL_TYPE_GNOME  &&
       nRace != RACIAL_TYPE_HALFORC)
    {
        SendMessageToPC(oPC, "[Zdarty Oblicze] Możesz zedrzeć twarz tylko z humanoidów.");
        return;
    }

    if(FmaskCountCollection(oPC) >= FMASK_MAX_MASKS)
    {
        SendMessageToPC(oPC, "[Zdarty Oblicze] Twój grimuar jest pełny — usuń stare maski.");
        return;
    }

    string sName  = GetName(oTarget);
    int nApp      = GetAppearanceType(oTarget);
    int nPhen     = GetPhenoType(oTarget);
    int nColorSkin = GetColor(oTarget, COLOR_CHANNEL_SKIN);
    int nColorHair = GetColor(oTarget, COLOR_CHANNEL_HAIR);
    int nColorTat1 = GetColor(oTarget, COLOR_CHANNEL_TATTOO1);
    int nColorTat2 = GetColor(oTarget, COLOR_CHANNEL_TATTOO2);

    json jParts    = FmaskSerializeAppearance(oTarget);
    string sParts  = JsonDump(jParts);

    // 15% cursed chance
    int bCursed = (d20() >= 18);

    FmaskAddMask(oPC, sName, nRace, nApp, nPhen,
                 nColorSkin, nColorHair, nColorTat1, nColorTat2,
                 sParts, bCursed);

    if(bCursed)
    {
        FloatingTextStringOnCreature("Pieczęć krwi pulsuje słabo... oblicze " + sName + " jest przeklęte.", oPC, FALSE);
        SendMessageToPC(oPC, "[Zdarty Oblicze] Maska " + sName + " trafiła do grimuaru. Emanuje niepokojem.");
    }
    else
    {
        FloatingTextStringOnCreature("Obdierasz twarz " + sName + "...", oPC, FALSE);
        SendMessageToPC(oPC, "[Zdarty Oblicze] Maska " + sName + " trafiła do grimuaru (" + IntToString(FMASK_DEFAULT_USES) + " użyć).");
    }

    int nToken = NuiFindWindow(oPC, FMASK_WINDOW);
    if(nToken != 0)
        FeedFmaskList(oPC, nToken);
}

// ----------------------------------------------------------------
// NUI — empty detail placeholder
// ----------------------------------------------------------------

json BuildFmaskDetailEmpty(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    json jLbl = NuiLabel(JsonString("Wybierz maskę z listy."),
                         JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLbl = NuiHeight(jLbl, GetNuiScaleDimension(oPC, 40.0));
    return NuiCol(JsonArrayInsert(JsonArray(), jLbl));
}

// ----------------------------------------------------------------
// NUI — detail panel for selected mask
// ----------------------------------------------------------------

json BuildFmaskDetailView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 32.0);
    float fLblH  = GetNuiScaleDimension(oPC, 24.0);
    float fTextH = GetNuiScaleDimension(oPC, 100.0);

    json jNameLbl = NuiLabel(NuiBind(FMASK_BIND_DET_NAME),
                             JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiHeight(jNameLbl, fBtnH);

    json jFlavor = NuiGroup(NuiText(NuiBind(FMASK_BIND_DET_FLAVOR), FALSE), TRUE, NUI_SCROLLBARS_NONE);
    jFlavor = NuiHeight(jFlavor, fTextH);

    json jBonusRow = JsonArray();
    json jBonusKey = NuiLabel(JsonString("Bonus:"),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBonusKey = NuiWidth(jBonusKey, GetNuiScaleDimension(oPC, 70.0));
    jBonusKey = NuiHeight(jBonusKey, fLblH);
    json jBonusVal = NuiLabel(NuiBind(FMASK_BIND_DET_BONUS),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBonusVal = NuiHeight(jBonusVal, fLblH);
    jBonusRow = JsonArrayInsert(jBonusRow, jBonusKey);
    jBonusRow = JsonArrayInsert(jBonusRow, jBonusVal);

    json jUsesRow = JsonArray();
    json jUsesKey = NuiLabel(JsonString("Użycia:"),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jUsesKey = NuiWidth(jUsesKey, GetNuiScaleDimension(oPC, 70.0));
    jUsesKey = NuiHeight(jUsesKey, fLblH);
    json jUsesVal = NuiLabel(NuiBind(FMASK_BIND_DET_USES),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jUsesVal = NuiHeight(jUsesVal, fLblH);
    jUsesRow = JsonArrayInsert(jUsesRow, jUsesKey);
    jUsesRow = JsonArrayInsert(jUsesRow, jUsesVal);

    json jCurseLbl = NuiLabel(NuiBind(FMASK_BIND_DET_CURSE),
                              JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jCurseLbl = NuiHeight(jCurseLbl, fLblH);

    json jWearBtn = NuiButton(NuiBind(FMASK_BIND_WEAR_LBL));
    jWearBtn = NuiId(jWearBtn, FMASK_BTN_WEAR);
    jWearBtn = NuiEnabled(jWearBtn, NuiBind(FMASK_BIND_WEAR_ENA));
    jWearBtn = NuiHeight(jWearBtn, fBtnH);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jNameLbl);
    jCol = JsonArrayInsert(jCol, jFlavor);
    jCol = JsonArrayInsert(jCol, NuiRow(jBonusRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jUsesRow));
    jCol = JsonArrayInsert(jCol, jCurseLbl);
    jCol = JsonArrayInsert(jCol, NuiSpacer());
    jCol = JsonArrayInsert(jCol, jWearBtn);

    return NuiCol(jCol);
}

// ----------------------------------------------------------------
// NUI — mask list
// ----------------------------------------------------------------

json BuildFmaskListView(object oPC)
{
    float fRowH = GetNuiScaleDimension(oPC, 26.0);
    float fNameW = GetNuiScaleDimension(oPC, 130.0);
    float fRaceW = GetNuiScaleDimension(oPC, 60.0);
    float fUsesW = GetNuiScaleDimension(oPC, 36.0);

    json jNameLbl = NuiLabel(NuiBind(FMASK_BIND_ROW_NAME),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(FMASK_BIND_ROW_COLOR));

    json jRaceLbl = NuiLabel(NuiBind(FMASK_BIND_ROW_RACE),
                             JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jRaceLbl = NuiWidth(jRaceLbl, fRaceW);
    jRaceLbl = NuiStyleForegroundColor(jRaceLbl, NuiBind(FMASK_BIND_ROW_COLOR));

    json jUsesLbl = NuiLabel(NuiBind(FMASK_BIND_ROW_USES),
                             JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jUsesLbl = NuiWidth(jUsesLbl, fUsesW);
    jUsesLbl = NuiStyleForegroundColor(jUsesLbl, NuiBind(FMASK_BIND_ROW_UCOL));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jNameLbl)), fNameW));
    jCellRow = JsonArrayInsert(jCellRow, jRaceLbl);
    jCellRow = JsonArrayInsert(jCellRow, jUsesLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, FMASK_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(FMASK_BIND_ROW_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    float fListH = GetNuiScaleDimension(oPC, 380.0);
    json jList = NuiList(jTmpl, NuiBind("fmask_rowcount"), fRowH);
    jList = NuiHeight(jList, fListH);

    json jCntLbl = NuiLabel(NuiBind(FMASK_BIND_CNT_LBL),
                            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCntLbl = NuiHeight(jCntLbl, GetNuiScaleDimension(oPC, 22.0));

    json jFlayBtn = NuiButton(JsonString("Zderrzyj twarz"));
    jFlayBtn = NuiId(jFlayBtn, FMASK_BTN_FLAY);
    jFlayBtn = NuiHeight(jFlayBtn, GetNuiScaleDimension(oPC, 32.0));
    jFlayBtn = NuiTooltip(jFlayBtn, JsonString("Wskaż martwego humanoida, by zedrzeć jego oblicze."));

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jCntLbl);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jFlayBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    return NuiCol(jCol);
}

// ----------------------------------------------------------------
// Window create
// ----------------------------------------------------------------

void CreateFmaskWindow(object oPC)
{
    if(NuiFindWindow(oPC, FMASK_WINDOW) != 0)
    {
        FeedFmaskList(oPC, NuiFindWindow(oPC, FMASK_WINDOW));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, FMASK_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, FMASK_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, FMASK_W), GetNuiScaleDimension(oPC, FMASK_H));

    float fBtnH   = GetNuiScaleDimension(oPC, 30.0);

    // Close button in title bar
    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, FMASK_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTitleRow = JsonArray();
    jTitleRow = JsonArrayInsert(jTitleRow, NuiLabel(JsonString("Grimuar Zdartyach Oblicz"),
                                                    JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jTitleRow = JsonArrayInsert(jTitleRow, NuiSpacer());
    jTitleRow = JsonArrayInsert(jTitleRow, jCloseBtn);

    // Split: list | detail
    float fListW   = GetNuiScaleDimension(oPC, FMASK_LIST_W);
    float fDetailW = GetNuiScaleDimension(oPC, FMASK_W - FMASK_LIST_W - 20.0);

    json jBodyRow = JsonArray();
    jBodyRow = JsonArrayInsert(jBodyRow, NuiWidth(BuildFmaskListView(oPC), fListW));
    jBodyRow = JsonArrayInsert(jBodyRow, NuiWidth(NuiGroup(BuildFmaskDetailEmpty(oPC), FALSE, NUI_SCROLLBARS_NONE), fDetailW));

    // The detail group is what we swap via NuiSetGroupLayout
    json jDetailGrp = NuiGroup(BuildFmaskDetailEmpty(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jDetailGrp = NuiId(jDetailGrp, FMASK_GRP_DETAIL);
    jDetailGrp = NuiWidth(jDetailGrp, fDetailW);

    json jSplitRow = JsonArray();
    jSplitRow = JsonArrayInsert(jSplitRow, NuiWidth(BuildFmaskListView(oPC), fListW));
    jSplitRow = JsonArrayInsert(jSplitRow, jDetailGrp);

    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jTitleRow));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jSplitRow));

    json jWin = NuiWindow(NuiCol(jRoot),
        JsonBool(FALSE),
        NuiBind(FMASK_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, FMASK_WINDOW, FMASK_EV_SCRIPT);
    NuiSetBind(oPC, nToken, FMASK_WIN_GEOM, jGeom);

    FeedFmaskList(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed list
// ----------------------------------------------------------------

void FeedFmaskList(object oPC, int nToken)
{
    json jMasks = FmaskGetCollection(oPC);
    int nCount  = JsonGetLength(jMasks);
    int nSelId  = GetLocalInt(oPC, FMASK_LVAR_SEL_ID);
    int nWornId = GetLocalInt(oPC, FMASK_LVAR_WORN_ID);

    json jNames  = JsonArray();
    json jRaces  = JsonArray();
    json jUses   = JsonArray();
    json jEncs   = JsonArray();
    json jColors = JsonArray();
    json jUCols  = JsonArray();

    json jWhite  = NuiColor(220, 215, 200);
    json jWorn   = NuiColor(255, 180, 60);
    json jGreen  = NuiColor(100, 220, 100);
    json jYellow = NuiColor(230, 220, 60);
    json jRed    = NuiColor(220, 80, 80);

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow = JsonArrayGet(jMasks, i);
        int nId   = JsonGetInt(JsonObjectGet(jRow, "id"));
        int nRace = JsonGetInt(JsonObjectGet(jRow, "racial_type"));
        int nUses = JsonGetInt(JsonObjectGet(jRow, "uses_remaining"));
        int bCursed = JsonGetInt(JsonObjectGet(jRow, "is_cursed"));
        string sName = JsonGetString(JsonObjectGet(jRow, "creature_name"));

        json jRowColor = (nId == nWornId) ? jWorn : jWhite;
        json jUseColor = (nUses >= 3) ? jGreen : ((nUses == 2) ? jYellow : jRed);
        string sCurseTag = bCursed ? " !" : "";

        jNames  = JsonArrayInsert(jNames,  JsonString(sName + sCurseTag));
        jRaces  = JsonArrayInsert(jRaces,  JsonString(FmaskRaceName(nRace)));
        jUses   = JsonArrayInsert(jUses,   JsonString(IntToString(nUses)));
        jEncs   = JsonArrayInsert(jEncs,   JsonBool(nId == nSelId));
        jColors = JsonArrayInsert(jColors, jRowColor);
        jUCols  = JsonArrayInsert(jUCols,  jUseColor);
    }

    NuiSetBind(oPC, nToken, FMASK_BIND_ROW_NAME,  jNames);
    NuiSetBind(oPC, nToken, FMASK_BIND_ROW_RACE,  jRaces);
    NuiSetBind(oPC, nToken, FMASK_BIND_ROW_USES,  jUses);
    NuiSetBind(oPC, nToken, FMASK_BIND_ROW_ENC,   jEncs);
    NuiSetBind(oPC, nToken, FMASK_BIND_ROW_COLOR, jColors);
    NuiSetBind(oPC, nToken, FMASK_BIND_ROW_UCOL,  jUCols);
    NuiSetBind(oPC, nToken, "fmask_rowcount",      JsonInt(nCount));

    string sCntLbl = "Maski: " + IntToString(nCount) + "/" + IntToString(FMASK_MAX_MASKS);
    NuiSetBind(oPC, nToken, FMASK_BIND_CNT_LBL, JsonString(sCntLbl));
}

// ----------------------------------------------------------------
// Feed detail panel
// ----------------------------------------------------------------

void FeedFmaskDetail(object oPC, int nToken, int nMaskId)
{
    json jMask = FmaskGetMask(nMaskId);
    if(JsonGetType(jMask) == JSON_TYPE_NULL)
    {
        NuiSetGroupLayout(oPC, nToken, FMASK_GRP_DETAIL, BuildFmaskDetailEmpty(oPC));
        return;
    }

    NuiSetGroupLayout(oPC, nToken, FMASK_GRP_DETAIL, BuildFmaskDetailView(oPC));

    int nRace   = JsonGetInt(JsonObjectGet(jMask, "racial_type"));
    int nUses   = JsonGetInt(JsonObjectGet(jMask, "uses_remaining"));
    int bCursed = JsonGetInt(JsonObjectGet(jMask, "is_cursed"));
    string sName = JsonGetString(JsonObjectGet(jMask, "creature_name"));

    int nWornId = GetLocalInt(oPC, FMASK_LVAR_WORN_ID);
    int bWorn   = (nMaskId == nWornId);
    int bCanWear = !bWorn && nUses > 0;

    NuiSetBind(oPC, nToken, FMASK_BIND_DET_NAME,   JsonString(sName));
    NuiSetBind(oPC, nToken, FMASK_BIND_DET_FLAVOR,  JsonString(FmaskFlavorText(nRace, bCursed)));
    NuiSetBind(oPC, nToken, FMASK_BIND_DET_BONUS,   JsonString(FmaskBonusDescription(nRace)));
    NuiSetBind(oPC, nToken, FMASK_BIND_DET_USES,    JsonString(IntToString(nUses) + " użyć"));
    NuiSetBind(oPC, nToken, FMASK_BIND_DET_CURSE,   JsonString(bCursed ? "~ Maska jest przeklęta ~" : ""));
    NuiSetBind(oPC, nToken, FMASK_BIND_WEAR_LBL,    JsonString(bWorn ? "Zdejmij" : "Nałóż"));
    NuiSetBind(oPC, nToken, FMASK_BIND_WEAR_ENA,    JsonBool(bCanWear || bWorn));
}

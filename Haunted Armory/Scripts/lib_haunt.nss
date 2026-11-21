#include "lib_haunt_def"

// ----------------------------------------------------------------
// Text helpers
// ----------------------------------------------------------------

string HauntLevelName(int nLevel, int bEmbraced)
{
    string sBase;
    switch(nLevel)
    {
        case 0: sBase = "Nieskalana";       break;
        case 1: sBase = "Pokropiona krwią"; break;
        case 2: sBase = "Głodna dusz";      break;
        case 3: sBase = "Przeklęta";        break;
        case 4: sBase = "Opętana";          break;
        case 5: sBase = "Czarny Artefakt";  break;
        default: sBase = "Nieznana";        break;
    }
    if(bEmbraced && nLevel >= 1) return sBase + " [Objęta]";
    return sBase;
}

string HauntRaceName(int nRace)
{
    switch(nRace)
    {
        case RACIAL_TYPE_HUMAN:    return "człowiek";
        case RACIAL_TYPE_ELF:      return "elf";
        case RACIAL_TYPE_DWARF:    return "krasnolud";
        case RACIAL_TYPE_HALFLING: return "niziołek";
        case RACIAL_TYPE_GNOME:    return "gnom";
        case RACIAL_TYPE_HALFORC:  return "półork";
        case RACIAL_TYPE_HALFELF:  return "półelf";
        case RACIAL_TYPE_UNDEAD:   return "nieumarły";
        case RACIAL_TYPE_ANIMAL:   return "zwierzę";
        default:                   return "stwór";
    }
}

// Returns flavor whisper based on level and embrace state.
string HauntGetWhisper(int nLevel, int bEmbraced)
{
    if(nLevel == 0) return "Ostrze milczy.";
    if(nLevel == 1 && !bEmbraced) return "„Pierwsze życie... i już broń pamięta."";
    if(nLevel == 1)               return "„Więcej. Daj mi więcej krwi."";
    if(nLevel == 2 && !bEmbraced) return "„Głosy. Ledwie słyszalne, lecz wyraźne w ciemności."";
    if(nLevel == 2)               return "„Pamiętam ich twarze. Czy ty pamiętasz?"";
    if(nLevel == 3 && !bEmbraced) return "Pieczęć krwi pulsuje słabo. Widzisz twarze?";
    if(nLevel == 3)               return "„Jesteśmy jedno. Nie ma odwrotu."";
    if(nLevel == 4 && !bEmbraced) return "Metaliczne krzyki rozsadzają głowę. Nie twoje krzyki.";
    if(nLevel == 4)               return "„TY JESTEŚ BROŃ. JA JESTEM CIOS."";
    // Level 5
    return "«Milczenie gorsze od śmierci. Odłóż mnie… jeśli śmiesz.»";
}

// Returns human-readable bonus/curse description for the current state.
string HauntGetBonusDesc(int nLevel, int bEmbraced)
{
    int nMul = bEmbraced ? 2 : 1;
    switch(nLevel)
    {
        case 0: return "Brak efektów.";
        case 1: return "Brak bonusów. Wyczuwasz niepokojące mrowienie.";
        case 2:
            return "+" + IntToString(nMul) + " do ataku.\n"
                 + "Klątwa: co ~120s rzut na Wolę DC 12 — przy niepowodzeniu -1 Mądrości (1 min).";
        case 3:
            return "+" + IntToString(2*nMul) + " do ataku, +1k4" + (bEmbraced ? "×2" : "") + " obrażeń magicznych.\n"
                 + "Klątwa: co ~60s rzut na Wolę DC 15 — przy niepowodzeniu -2 Mądrości (2 min).";
        case 4:
            return "+" + IntToString(3*nMul) + " do ataku, +2k4" + (bEmbraced ? "×2" : "") + " obrażeń magicznych.\n"
                 + "Klątwa: co ~30s rzut na Wolę DC 18 — przy niepowodzeniu zamęt (6s).";
        case 5:
            return "+" + IntToString(5*nMul) + " do ataku, +3k6" + (bEmbraced ? "×2" : "") + " obrażeń magicznych.\n"
                 + "Klątwa: stały spadek Mądrości -" + IntToString(4*nMul) + ". Brak rzutu obronnego.";
    }
    return "";
}

// How many more kills are needed to reach the next level (-1 if already at max).
int HauntKillsForNextLevel(int nLevel, int nKills)
{
    int nThreshold;
    switch(nLevel)
    {
        case 0: nThreshold = HAUNT_LVL1_KILLS; break;
        case 1: nThreshold = HAUNT_LVL2_KILLS; break;
        case 2: nThreshold = HAUNT_LVL3_KILLS; break;
        case 3: nThreshold = HAUNT_LVL4_KILLS; break;
        case 4: nThreshold = HAUNT_LVL5_KILLS; break;
        default: return -1;
    }
    return nThreshold - nKills;
}

// ----------------------------------------------------------------
// Effect management
// ----------------------------------------------------------------

// Removes every effect on oPC whose tag starts with HAUNT_FX_ + sItemUUID.
void HauntRemoveEffects(object oPC, string sItemUUID)
{
    string sTag = HAUNT_FX_TAG + sItemUUID;
    effect eFX = GetFirstEffect(oPC);
    while(GetIsEffectValid(eFX))
    {
        if(GetEffectTag(eFX) == sTag)
            RemoveEffect(oPC, eFX);
        eFX = GetNextEffect(oPC);
    }
}

// Strips all haunt effects from a PC regardless of which weapon caused them.
void HauntStripAllEffects(object oPC)
{
    effect eFX = GetFirstEffect(oPC);
    while(GetIsEffectValid(eFX))
    {
        if(GetStringLeft(GetEffectTag(eFX), GetStringLength(HAUNT_FX_TAG)) == HAUNT_FX_TAG)
            RemoveEffect(oPC, eFX);
        eFX = GetNextEffect(oPC);
    }
}

// Applies (or refreshes) bonus and level-5 Wisdom-drain effects for a haunted weapon.
// Safe to call repeatedly — it removes the old effects first to prevent stacking.
void HauntApplyEffects(object oPC, object oWeapon)
{
    string sUUID = GetObjectUUID(oWeapon);
    json   jData = HauntGetWeaponData(sUUID);
    if(JsonGetType(jData) == JSON_TYPE_NULL) return;

    int nLevel    = JsonGetInt(JsonObjectGet(jData, "haunt_level"));
    int bEmbraced = JsonGetInt(JsonObjectGet(jData, "is_embraced"));
    if(nLevel < 2) { HauntRemoveEffects(oPC, sUUID); return; }

    HauntRemoveEffects(oPC, sUUID);

    string sTag  = HAUNT_FX_TAG + sUUID;
    int    nMul  = bEmbraced ? 2 : 1;

    // Attack bonus (levels 2-5)
    int nAtkBonus = 0;
    if     (nLevel == 2) nAtkBonus = 1;
    else if(nLevel == 3) nAtkBonus = 2;
    else if(nLevel == 4) nAtkBonus = 3;
    else                 nAtkBonus = 5;
    nAtkBonus *= nMul;
    ApplyEffectToObject(DURATION_TYPE_PERMANENT,
        TagEffect(EffectAttackIncrease(nAtkBonus, ATTACK_BONUS_MISC), sTag), oPC);

    // Damage bonus (levels 3-5)
    if(nLevel >= 3)
    {
        int nDmgConst;
        if     (nLevel == 3 && !bEmbraced) nDmgConst = DAMAGE_BONUS_1d4;
        else if(nLevel == 3)               nDmgConst = DAMAGE_BONUS_2d4;
        else if(nLevel == 4 && !bEmbraced) nDmgConst = DAMAGE_BONUS_2d4;
        else if(nLevel == 4)               nDmgConst = DAMAGE_BONUS_4d4;
        else if(nLevel == 5 && !bEmbraced) nDmgConst = DAMAGE_BONUS_3d6;
        else                               nDmgConst = DAMAGE_BONUS_6d6;
        ApplyEffectToObject(DURATION_TYPE_PERMANENT,
            TagEffect(EffectDamageIncrease(nDmgConst, DAMAGE_TYPE_MAGICAL), sTag), oPC);
    }

    // Level 5: permanent Wisdom drain (no save)
    if(nLevel >= 5)
    {
        ApplyEffectToObject(DURATION_TYPE_PERMANENT,
            TagEffect(EffectAbilityDecrease(ABILITY_WISDOM, 4 * nMul), sTag), oPC);
    }
}

// ----------------------------------------------------------------
// Curse processing (called periodically per PC)
// ----------------------------------------------------------------

// Checks if oPC is wielding a haunted weapon and processes curse saves.
// nTick: running module heartbeat counter (used to throttle per level).
void HauntProcessCurse(object oPC)
{
    if(!GetIsPC(oPC) || GetIsDM(oPC)) return;

    object oWeap = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
    if(!GetIsObjectValid(oWeap))
        oWeap = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oPC);

    if(!GetIsObjectValid(oWeap))
    {
        HauntStripAllEffects(oPC);
        return;
    }

    string sUUID = GetObjectUUID(oWeap);
    json   jData = HauntGetWeaponData(sUUID);
    if(JsonGetType(jData) == JSON_TYPE_NULL)
    {
        HauntStripAllEffects(oPC);
        return;
    }

    int nLevel    = JsonGetInt(JsonObjectGet(jData, "haunt_level"));
    int bEmbraced = JsonGetInt(JsonObjectGet(jData, "is_embraced"));
    if(nLevel < 2) return;

    // Keep bonus effects current (handles equip/re-log cases).
    HauntApplyEffects(oPC, oWeap);

    // Save-based curse effects depend on haunt level.
    // HauntProcessCurse is called every ~30s from the heartbeat.
    // Level 2: DC 12, -1 Wis 60s
    // Level 3: DC 15, -2 Wis 120s  (but we want 60s interval; handled by caller tick)
    // Level 4: DC 18, Confused 6s
    // Level 5: no save (handled via permanent effect in HauntApplyEffects)

    int nMul = bEmbraced ? 2 : 1;
    int nSaveRoll;
    int nDC;

    if(nLevel == 2)
    {
        nDC = 12 + (bEmbraced ? 3 : 0);
        nSaveRoll = FortitudeSave(oPC, nDC, SAVING_THROW_TYPE_MIND_SPELLS, OBJECT_INVALID);
        if(nSaveRoll == 0)
        {
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectAbilityDecrease(ABILITY_WISDOM, 1 * nMul), oPC, 60.0);
            SendMessageToPC(oPC, "[Oręże] Szept broni sączy się w myśli... (-" + IntToString(1*nMul) + " Mądrości, 1 min).");
        }
    }
    else if(nLevel == 3)
    {
        nDC = 15 + (bEmbraced ? 3 : 0);
        nSaveRoll = WillSave(oPC, nDC, SAVING_THROW_TYPE_MIND_SPELLS, OBJECT_INVALID);
        if(nSaveRoll == 0)
        {
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectAbilityDecrease(ABILITY_WISDOM, 2 * nMul), oPC, 120.0);
            SendMessageToPC(oPC, "[Oręże] Twarze zabitych kłębią się przed oczami... (-" + IntToString(2*nMul) + " Mądrości, 2 min).");
        }
    }
    else if(nLevel == 4)
    {
        nDC = 18 + (bEmbraced ? 3 : 0);
        nSaveRoll = WillSave(oPC, nDC, SAVING_THROW_TYPE_MIND_SPELLS, OBJECT_INVALID);
        if(nSaveRoll == 0)
        {
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectConfused(), oPC, 6.0);
            SendMessageToPC(oPC, "[Oręże] Broń przemawia. Ty przestajesz słyszeć siebie... (zamęt, 6s).");
        }
    }
    // Level 5 has no save: handled by permanent WIS drain in HauntApplyEffects.
}

// ----------------------------------------------------------------
// Kill recording
// ----------------------------------------------------------------

// Records a kill on the weapon wielded by oKiller.
// Only melee/thrown weapons qualify; bows, wands and fists are ignored.
void HauntRecordKill(object oKiller, object oVictim)
{
    if(!GetIsObjectValid(oKiller) || !GetIsObjectValid(oVictim)) return;

    object oWeap = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oKiller);
    if(!GetIsObjectValid(oWeap))
        oWeap = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oKiller);
    if(!GetIsObjectValid(oWeap)) return;

    // Exclude ranged launchers.
    int nBase = GetBaseItemType(oWeap);
    if(nBase == BASE_ITEM_LONGBOW     || nBase == BASE_ITEM_SHORTBOW      ||
       nBase == BASE_ITEM_HEAVYCROSSBOW || nBase == BASE_ITEM_LIGHTCROSSBOW ||
       nBase == BASE_ITEM_SLING       || nBase == BASE_ITEM_DART           ||
       nBase == BASE_ITEM_SHURIKEN    || nBase == BASE_ITEM_THROWINGAXE)
        return;

    // Exclude pets/associates so grinding with summons feels cheap.
    if(GetMaster(oVictim) == oKiller) return;

    string sUUID    = GetObjectUUID(oWeap);
    string sName    = GetName(oVictim);
    int    nRace    = GetRacialType(oVictim);

    int nOldKills = 0;
    json jOld = HauntGetWeaponData(sUUID);
    if(JsonGetType(jOld) != JSON_TYPE_NULL)
        nOldKills = JsonGetInt(JsonObjectGet(jOld, "kill_count"));

    HauntRecordKillSQL(sUUID, sName, nRace);

    // Notify the PC if the weapon just reached a new haunt level.
    if(!GetIsPC(oKiller)) return;

    json jNew = HauntGetWeaponData(sUUID);
    int  nNewLevel = JsonGetInt(JsonObjectGet(jNew, "haunt_level"));

    int nOldLevel = 0;
    if     (nOldKills >= 300) nOldLevel = 5;
    else if(nOldKills >= 150) nOldLevel = 4;
    else if(nOldKills >= 75)  nOldLevel = 3;
    else if(nOldKills >= 30)  nOldLevel = 2;
    else if(nOldKills >= 10)  nOldLevel = 1;

    if(nNewLevel > nOldLevel)
    {
        int bEmb = JsonGetInt(JsonObjectGet(jNew, "is_embraced"));
        string sMsg = "[Oręże] „" + GetName(oWeap) + """ + " przeszła na poziom: " + HauntLevelName(nNewLevel, bEmb);
        FloatingTextStringOnCreature(sMsg, oKiller, FALSE);
        SendMessageToPC(oKiller, sMsg);
    }
}

// ----------------------------------------------------------------
// NUI construction
// ----------------------------------------------------------------

json HauntBuildPanel(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 30.0);
    float fLblH  = GetNuiScaleDimension(oPC, 22.0);
    float fRowH  = GetNuiScaleDimension(oPC, 22.0);
    float fNameW = GetNuiScaleDimension(oPC, 230.0);
    float fRaceW = GetNuiScaleDimension(oPC, 90.0);
    float fDateW = GetNuiScaleDimension(oPC, 60.0);

    // -- Title bar row: weapon name + close --
    json jNameLbl = NuiLabel(NuiBind(HAUNT_BIND_ITEM_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiHeight(jNameLbl, fBtnH);
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(HAUNT_BIND_STATUS_COLOR));

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, HAUNT_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jNameLbl);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jCloseBtn);

    // -- Haunt level and kill count --
    json jLevelLbl = NuiLabel(NuiBind(HAUNT_BIND_LEVEL_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jLevelLbl = NuiHeight(jLevelLbl, fLblH);
    jLevelLbl = NuiStyleForegroundColor(jLevelLbl, NuiBind(HAUNT_BIND_STATUS_COLOR));

    json jKillsLbl = NuiLabel(NuiBind(HAUNT_BIND_KILLS_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jKillsLbl = NuiHeight(jKillsLbl, fLblH);

    json jNextLbl = NuiLabel(NuiBind(HAUNT_BIND_NEXT_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jNextLbl = NuiHeight(jNextLbl, fLblH);

    // -- Effects section --
    json jSepEffects = NuiLabel(JsonString("── Efekty ──"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jSepEffects = NuiHeight(jSepEffects, fLblH);

    json jBonusText = NuiText(NuiBind(HAUNT_BIND_BONUS_LBL), FALSE);
    jBonusText = NuiHeight(jBonusText, GetNuiScaleDimension(oPC, 60.0));

    // -- Kill history list --
    json jSepHist = NuiLabel(JsonString("── Kronika Ofiar ──"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jSepHist = NuiHeight(jSepHist, fLblH);

    json jHistName = NuiLabel(NuiBind(HAUNT_BIND_HIST_NAME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jHistName = NuiWidth(jHistName, fNameW);

    json jHistRace = NuiLabel(NuiBind(HAUNT_BIND_HIST_RACE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHistRace = NuiWidth(jHistRace, fRaceW);

    json jHistDate = NuiLabel(NuiBind(HAUNT_BIND_HIST_DATE),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jHistDate = NuiWidth(jHistDate, fDateW);

    json jHistCells = JsonArray();
    jHistCells = JsonArrayInsert(jHistCells, jHistName);
    jHistCells = JsonArrayInsert(jHistCells, jHistRace);
    jHistCells = JsonArrayInsert(jHistCells, jHistDate);

    json jHistRow = NuiGroup(NuiRow(jHistCells), TRUE, NUI_SCROLLBARS_NONE);
    json jHistTmpl = JsonArrayInsert(JsonArray(),
        NuiListTemplateCell(jHistRow, 0.0, TRUE));

    float fListH = GetNuiScaleDimension(oPC, 180.0);
    json jHistList = NuiList(jHistTmpl, NuiBind("haunt_hist_count"), fRowH);
    jHistList = NuiHeight(jHistList, fListH);

    // -- Whisper section --
    json jSepWhisper = NuiLabel(JsonString("── Szept Broni ──"),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jSepWhisper = NuiHeight(jSepWhisper, fLblH);

    json jWhisperLbl = NuiLabel(NuiBind(HAUNT_BIND_WHISPER_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jWhisperLbl = NuiHeight(jWhisperLbl, GetNuiScaleDimension(oPC, 34.0));
    jWhisperLbl = NuiStyleForegroundColor(jWhisperLbl, NuiBind(HAUNT_BIND_STATUS_COLOR));

    // -- Action buttons --
    json jEmbraceBtn = NuiButton(NuiBind(HAUNT_BIND_EMBRACE_LBL));
    jEmbraceBtn = NuiId(jEmbraceBtn, HAUNT_BTN_EMBRACE);
    jEmbraceBtn = NuiEnabled(jEmbraceBtn, NuiBind(HAUNT_BIND_EMBRACE_ENA));
    jEmbraceBtn = NuiWidth(jEmbraceBtn, GetNuiScaleDimension(oPC, 185.0));
    jEmbraceBtn = NuiHeight(jEmbraceBtn, fBtnH);

    json jCleanseBtn = NuiButton(JsonString("Oczyść [Święcona Woda]"));
    jCleanseBtn = NuiId(jCleanseBtn, HAUNT_BTN_CLEANSE);
    jCleanseBtn = NuiEnabled(jCleanseBtn, NuiBind(HAUNT_BIND_CLEANSE_ENA));
    jCleanseBtn = NuiWidth(jCleanseBtn, GetNuiScaleDimension(oPC, 220.0));
    jCleanseBtn = NuiHeight(jCleanseBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jEmbraceBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jCleanseBtn);

    // -- Assemble column --
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTopRow));
    jCol = JsonArrayInsert(jCol, jLevelLbl);
    jCol = JsonArrayInsert(jCol, jKillsLbl);
    jCol = JsonArrayInsert(jCol, jNextLbl);
    jCol = JsonArrayInsert(jCol, jSepEffects);
    jCol = JsonArrayInsert(jCol, jBonusText);
    jCol = JsonArrayInsert(jCol, jSepHist);
    jCol = JsonArrayInsert(jCol, jHistList);
    jCol = JsonArrayInsert(jCol, jSepWhisper);
    jCol = JsonArrayInsert(jCol, jWhisperLbl);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    // Side spacers keep the content centered at wide GUI scales.
    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 540.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Window open / feed
// ----------------------------------------------------------------

void HauntOpenWindow(object oPC, object oWeapon)
{
    string sUUID = GetObjectUUID(oWeapon);
    SetLocalString(oPC, HAUNT_LVAR_OPEN_UUID, sUUID);

    int nToken = NuiFindWindow(oPC, HAUNT_WINDOW);
    if(nToken != 0)
    {
        HauntFeedPanel(oPC, nToken, oWeapon);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, HAUNT_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, HAUNT_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
        GetNuiScaleDimension(oPC, HAUNT_W),
        GetNuiScaleDimension(oPC, HAUNT_H));

    json jWin = NuiWindow(
        HauntBuildPanel(oPC),
        JsonBool(FALSE),
        NuiBind(HAUNT_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, HAUNT_WINDOW, HAUNT_EV_SCRIPT);
    NuiSetBind(oPC, nToken, HAUNT_WIN_GEOM, jGeom);

    HauntFeedPanel(oPC, nToken, oWeapon);
}

void HauntFeedPanel(object oPC, int nToken, object oWeapon)
{
    string sUUID  = GetObjectUUID(oWeapon);
    json   jData  = HauntGetWeaponData(sUUID);

    int nLevel    = 0;
    int nKills    = 0;
    int bEmbraced = 0;
    if(JsonGetType(jData) != JSON_TYPE_NULL)
    {
        nLevel    = JsonGetInt(JsonObjectGet(jData, "haunt_level"));
        nKills    = JsonGetInt(JsonObjectGet(jData, "kill_count"));
        bEmbraced = JsonGetInt(JsonObjectGet(jData, "is_embraced"));
    }

    // Color shifts from pale silver → amber → dark red → violet → near-black.
    json jColor;
    switch(nLevel)
    {
        case 0: jColor = NuiColor(200, 200, 200); break;
        case 1: jColor = NuiColor(220, 200, 140); break;
        case 2: jColor = NuiColor(230, 140,  80); break;
        case 3: jColor = NuiColor(220,  60,  60); break;
        case 4: jColor = NuiColor(160,  40, 210); break;
        default:jColor = NuiColor( 90,   0,   0); break;
    }
    if(bEmbraced) jColor = NuiColor(210, 10, 30);

    NuiSetBind(oPC, nToken, HAUNT_BIND_ITEM_NAME,   JsonString(GetName(oWeapon)));
    NuiSetBind(oPC, nToken, HAUNT_BIND_STATUS_COLOR,jColor);
    NuiSetBind(oPC, nToken, HAUNT_BIND_LEVEL_LBL,
        JsonString("Poziom nawiedzenia: " + HauntLevelName(nLevel, bEmbraced)));
    NuiSetBind(oPC, nToken, HAUNT_BIND_KILLS_LBL,
        JsonString("Zabite stworzenia: " + IntToString(nKills)));

    int nToNext = HauntKillsForNextLevel(nLevel, nKills);
    string sNext = (nToNext > 0 && nLevel < 5)
        ? "Do następnego progu: " + IntToString(nToNext) + " zabójstw"
        : (nLevel >= 5 ? "Poziom maksymalny." : "");
    NuiSetBind(oPC, nToken, HAUNT_BIND_NEXT_LBL,     JsonString(sNext));
    NuiSetBind(oPC, nToken, HAUNT_BIND_BONUS_LBL,    JsonString(HauntGetBonusDesc(nLevel, bEmbraced)));
    NuiSetBind(oPC, nToken, HAUNT_BIND_WHISPER_LBL,  JsonString(HauntGetWhisper(nLevel, bEmbraced)));

    NuiSetBind(oPC, nToken, HAUNT_BIND_EMBRACE_ENA,  JsonBool(nLevel >= 1 && !bEmbraced));
    NuiSetBind(oPC, nToken, HAUNT_BIND_EMBRACE_LBL,
        JsonString(bEmbraced ? "Objęta [aktywna]" : "Objąć Klątwę"));
    NuiSetBind(oPC, nToken, HAUNT_BIND_CLEANSE_ENA,  JsonBool(nKills > 0));

    // Fill kill history list.
    json jHist   = HauntGetKillHistory(sUUID, HAUNT_HIST_ROWS);
    int  nHCount = JsonGetLength(jHist);
    json jNames  = JsonArray();
    json jRaces  = JsonArray();
    json jDates  = JsonArray();
    int i;
    for(i = 0; i < nHCount; i++)
    {
        json jRow = JsonArrayGet(jHist, i);
        jNames = JsonArrayInsert(jNames, JsonString(JsonGetString(JsonObjectGet(jRow, "victim_name"))));
        jRaces = JsonArrayInsert(jRaces, JsonString(HauntRaceName(JsonGetInt(JsonObjectGet(jRow, "victim_race")))));
        jDates = JsonArrayInsert(jDates, JsonString(HauntFormatDate(JsonGetInt(JsonObjectGet(jRow, "kill_at")))));
    }
    NuiSetBind(oPC, nToken, HAUNT_BIND_HIST_NAME,   jNames);
    NuiSetBind(oPC, nToken, HAUNT_BIND_HIST_RACE,   jRaces);
    NuiSetBind(oPC, nToken, HAUNT_BIND_HIST_DATE,   jDates);
    NuiSetBind(oPC, nToken, "haunt_hist_count",      JsonInt(nHCount));
}

#include "lib_sea_def"

// ----------------------------------------------------------------
// Name helpers
// ----------------------------------------------------------------

string SeaGetSeasonName(int nSeason)
{
    switch (nSeason)
    {
        case SEA_SEASON_SPRING: return "Wiosna Odrodzenia";
        case SEA_SEASON_SUMMER: return "Lato Skwaru";
        case SEA_SEASON_AUTUMN: return "Jesień Żniw Krwi";
        case SEA_SEASON_WINTER: return "Zima Śmierci";
        case SEA_SEASON_DYING:  return "Tydzień Umierającego Boga";
    }
    return "Nieznana Pora";
}

string SeaGetWeatherName(int nWeather)
{
    switch (nWeather)
    {
        case SEA_WEATHER_CLEAR:    return "Pogodnie";
        case SEA_WEATHER_OVERCAST: return "Zachmurzenie";
        case SEA_WEATHER_RAIN:     return "Deszcz";
        case SEA_WEATHER_STORM:    return "Burza";
        case SEA_WEATHER_SNOW:     return "Śnieg";
        case SEA_WEATHER_BLIZZARD: return "Zamieć";
        case SEA_WEATHER_DROUGHT:  return "Susza";
    }
    return "Nieznana Pogoda";
}

string SeaGetClimateName(int nClimate)
{
    switch (nClimate)
    {
        case SEA_CLIMATE_TEMPERATE: return "Umiarkowany";
        case SEA_CLIMATE_ARCTIC:    return "Arktyczny";
        case SEA_CLIMATE_DESERT:    return "Pustynny";
        case SEA_CLIMATE_COASTAL:   return "Nadmorski";
        case SEA_CLIMATE_CURSED:    return "Przeklęty";
    }
    return "Nieznany";
}

string SeaGetWeatherEffectDesc(int nWeather)
{
    switch (nWeather)
    {
        case SEA_WEATHER_CLEAR:
            return "Cisza. Powietrze jest chłodne i czyste.";
        case SEA_WEATHER_OVERCAST:
            return "Szare niebo ciąży nad ziemią. -1 Nasłuchiwanie.";
        case SEA_WEATHER_RAIN:
            return "Deszcz utrudnia ruch. -20% prędkość, -1 Reflex.";
        case SEA_WEATHER_STORM:
            return "Burza grzmi. -40% prędkość, -2 Reflex, -2 Nasłuchiwanie. Ryzyko pioruna.";
        case SEA_WEATHER_SNOW:
            return "Śnieg prószy cicho. -20% prędkość, -2 Zwinność.";
        case SEA_WEATHER_BLIZZARD:
            return "Zamieć pożera ciepło. -40% prędkość, -4 Siła i Zwinność. Odmrożenia co minutę.";
        case SEA_WEATHER_DROUGHT:
            return "Żar pali skórę. -2 Kondycja, +25% podatność na ogień.";
    }
    return "";
}

// ----------------------------------------------------------------
// Season / weather cycling
// ----------------------------------------------------------------

int SeaNextSeason(int nSeason)
{
    // SPRING -> SUMMER -> AUTUMN -> WINTER -> DYING -> SPRING
    nSeason++;
    if (nSeason >= SEA_SEASON_COUNT) nSeason = 0;
    return nSeason;
}

int SeaPrevSeason(int nSeason)
{
    nSeason--;
    if (nSeason < 0) nSeason = SEA_SEASON_COUNT - 1;
    return nSeason;
}

int SeaNextWeather(int nWeather)
{
    nWeather++;
    if (nWeather >= SEA_WEATHER_COUNT) nWeather = 0;
    return nWeather;
}

int SeaPrevWeather(int nWeather)
{
    nWeather--;
    if (nWeather < 0) nWeather = SEA_WEATHER_COUNT - 1;
    return nWeather;
}

// Weighted random weather selection based on season + climate
int SeaPickWeather(int nSeason, int nClimate)
{
    int r = Random(100);

    if (nClimate == SEA_CLIMATE_CURSED)
        return (r < 50) ? SEA_WEATHER_STORM : SEA_WEATHER_BLIZZARD;

    if (nClimate == SEA_CLIMATE_DESERT)
    {
        if (nSeason == SEA_SEASON_SUMMER) return (r < 60) ? SEA_WEATHER_DROUGHT : SEA_WEATHER_CLEAR;
        return (r < 50) ? SEA_WEATHER_CLEAR : SEA_WEATHER_OVERCAST;
    }

    if (nClimate == SEA_CLIMATE_ARCTIC)
    {
        if (nSeason == SEA_SEASON_WINTER || nSeason == SEA_SEASON_DYING)
            return (r < 55) ? SEA_WEATHER_BLIZZARD : SEA_WEATHER_SNOW;
        if (nSeason == SEA_SEASON_AUTUMN)
            return (r < 40) ? SEA_WEATHER_SNOW : (r < 70 ? SEA_WEATHER_OVERCAST : SEA_WEATHER_CLEAR);
        return (r < 25) ? SEA_WEATHER_SNOW : (r < 55 ? SEA_WEATHER_OVERCAST : SEA_WEATHER_CLEAR);
    }

    if (nClimate == SEA_CLIMATE_COASTAL)
    {
        if (nSeason == SEA_SEASON_AUTUMN)
            return (r < 40) ? SEA_WEATHER_STORM : (r < 70 ? SEA_WEATHER_RAIN : SEA_WEATHER_OVERCAST);
        if (nSeason == SEA_SEASON_WINTER)
            return (r < 30) ? SEA_WEATHER_STORM : (r < 60 ? SEA_WEATHER_RAIN : SEA_WEATHER_SNOW);
    }

    // Temperate (and coastal fallthrough)
    switch (nSeason)
    {
        case SEA_SEASON_SPRING:
            if (r < 30) return SEA_WEATHER_CLEAR;
            if (r < 60) return SEA_WEATHER_RAIN;
            if (r < 80) return SEA_WEATHER_OVERCAST;
            return SEA_WEATHER_STORM;

        case SEA_SEASON_SUMMER:
            if (r < 50) return SEA_WEATHER_CLEAR;
            if (r < 70) return SEA_WEATHER_OVERCAST;
            if (r < 85) return SEA_WEATHER_DROUGHT;
            return SEA_WEATHER_STORM;

        case SEA_SEASON_AUTUMN:
            if (r < 25) return SEA_WEATHER_CLEAR;
            if (r < 55) return SEA_WEATHER_OVERCAST;
            if (r < 75) return SEA_WEATHER_RAIN;
            return SEA_WEATHER_STORM;

        case SEA_SEASON_WINTER:
            if (r < 20) return SEA_WEATHER_CLEAR;
            if (r < 45) return SEA_WEATHER_SNOW;
            if (r < 70) return SEA_WEATHER_OVERCAST;
            return SEA_WEATHER_BLIZZARD;

        case SEA_SEASON_DYING:
            if (r < 40) return SEA_WEATHER_BLIZZARD;
            if (r < 70) return SEA_WEATHER_STORM;
            return SEA_WEATHER_OVERCAST;
    }
    return SEA_WEATHER_CLEAR;
}

// ----------------------------------------------------------------
// Area check
// ----------------------------------------------------------------

// Returns TRUE if the PC is in a natural (sky-exposed) area
int SeaIsOutdoor(object oPC)
{
    object oArea = GetArea(oPC);
    if (!GetIsObjectValid(oArea)) return FALSE;
    return GetIsAreaNatural(oArea);
}

// ----------------------------------------------------------------
// Effect management
// ----------------------------------------------------------------

void SeaRemoveWeatherEffects(object oPC)
{
    effect e = GetFirstEffect(oPC);
    while (GetIsEffectValid(e))
    {
        effect eNext = GetNextEffect(oPC);
        if (GetEffectTag(e) == SEA_EFFECT_TAG)
            RemoveEffect(oPC, e);
        e = eNext;
    }
}

void SeaApplyWeatherEffects(object oPC)
{
    if (!GetIsPC(oPC)) return;

    SeaRemoveWeatherEffects(oPC);

    json jState = SeaGetStateRow();
    if (JsonGetType(jState) == JSON_TYPE_NULL) return;

    int nWeather = JsonGetInt(JsonObjectGet(jState, "weather"));
    int nSeason  = JsonGetInt(JsonObjectGet(jState, "season"));

    // Dying Season: save penalty applies even indoors
    if (nSeason == SEA_SEASON_DYING)
    {
        effect eDying = TagEffect(
            EffectSavingThrowDecrease(SAVING_THROW_ALL, 2, SAVING_THROW_TYPE_ALL),
            SEA_EFFECT_TAG);
        ApplyEffectToObject(DURATION_TYPE_PERMANENT, eDying, oPC);
    }

    if (!SeaIsOutdoor(oPC)) return;

    switch (nWeather)
    {
        case SEA_WEATHER_CLEAR:
            break;

        case SEA_WEATHER_OVERCAST:
        {
            effect e = TagEffect(EffectSkillDecrease(SKILL_LISTEN, 1), SEA_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, e, oPC);
            break;
        }

        case SEA_WEATHER_RAIN:
        {
            effect eSpd = TagEffect(EffectMovementSpeedDecrease(20), SEA_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eSpd, oPC);
            effect eRef = TagEffect(
                EffectSavingThrowDecrease(SAVING_THROW_REFLEX, 1, SAVING_THROW_TYPE_ALL),
                SEA_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eRef, oPC);
            break;
        }

        case SEA_WEATHER_STORM:
        {
            effect eSpd = TagEffect(EffectMovementSpeedDecrease(40), SEA_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eSpd, oPC);
            effect eRef = TagEffect(
                EffectSavingThrowDecrease(SAVING_THROW_REFLEX, 2, SAVING_THROW_TYPE_ALL),
                SEA_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eRef, oPC);
            effect eLis = TagEffect(EffectSkillDecrease(SKILL_LISTEN, 2), SEA_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eLis, oPC);
            break;
        }

        case SEA_WEATHER_SNOW:
        {
            effect eSpd = TagEffect(EffectMovementSpeedDecrease(20), SEA_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eSpd, oPC);
            effect eDex = TagEffect(EffectAbilityDecrease(ABILITY_DEXTERITY, 2), SEA_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eDex, oPC);
            break;
        }

        case SEA_WEATHER_BLIZZARD:
        {
            effect eSpd = TagEffect(EffectMovementSpeedDecrease(40), SEA_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eSpd, oPC);
            effect eStr = TagEffect(EffectAbilityDecrease(ABILITY_STRENGTH, 4), SEA_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eStr, oPC);
            effect eDex = TagEffect(EffectAbilityDecrease(ABILITY_DEXTERITY, 4), SEA_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eDex, oPC);
            break;
        }

        case SEA_WEATHER_DROUGHT:
        {
            effect eCon = TagEffect(EffectAbilityDecrease(ABILITY_CONSTITUTION, 2), SEA_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eCon, oPC);
            effect eFire = TagEffect(EffectDamageImmunityDecrease(DAMAGE_TYPE_FIRE, 25), SEA_EFFECT_TAG);
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eFire, oPC);
            break;
        }
    }
}

void SeaUpdateAllPCs()
{
    object oPC = GetFirstPC();
    while (GetIsObjectValid(oPC))
    {
        SeaApplyWeatherEffects(oPC);
        oPC = GetNextPC();
    }
}

void SeaNotifyAll(string sMsg)
{
    object oPC = GetFirstPC();
    while (GetIsObjectValid(oPC))
    {
        FloatingTextStringOnCreature(sMsg, oPC, FALSE);
        SendMessageToPC(oPC, "[Klimat] " + sMsg);
        oPC = GetNextPC();
    }
}

// ----------------------------------------------------------------
// NUI helpers
// ----------------------------------------------------------------

string SeaNextChangeStr(int nWeatherChanged)
{
    int nNow  = SeaGetNow();
    int nLeft = SEA_WEATHER_INTERVAL - (nNow - nWeatherChanged);
    if (nLeft <= 0) return "wkrótce";
    int nH = nLeft / 3600;
    int nM = (nLeft % 3600) / 60;
    if (nH > 0) return IntToString(nH) + "g " + IntToString(nM) + "m";
    return IntToString(nM) + " min";
}

// ----------------------------------------------------------------
// Player window
// ----------------------------------------------------------------

json BuildSeaPlayerLayout(object oPC)
{
    float fLbl  = GetNuiScaleDimension(oPC, 22.0);
    float fDesc = GetNuiScaleDimension(oPC, 60.0);
    float fBtn  = GetNuiScaleDimension(oPC, 28.0);

    json jSeaLbl = NuiHeight(
        NuiLabel(NuiBind(SEA_BIND_SEASON_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)),
        fLbl);
    json jWeaLbl = NuiHeight(
        NuiLabel(NuiBind(SEA_BIND_WEATHER_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)),
        fLbl);
    json jEffLbl = NuiHeight(
        NuiLabel(NuiBind(SEA_BIND_EFFECT_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP)),
        fDesc);
    json jNxtLbl = NuiHeight(
        NuiLabel(NuiBind(SEA_BIND_NEXTCH_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)),
        fLbl);

    json jClose = NuiHeight(NuiId(NuiButton(JsonString("Zamknij")), SEA_BTN_CLOSE), fBtn);

    json jCols = JsonArray();
    jCols = JsonArrayInsert(jCols, NuiRow(JsonArrayInsert(JsonArray(), jSeaLbl)));
    jCols = JsonArrayInsert(jCols, NuiRow(JsonArrayInsert(JsonArray(), jWeaLbl)));
    jCols = JsonArrayInsert(jCols, NuiRow(JsonArrayInsert(JsonArray(), jEffLbl)));
    jCols = JsonArrayInsert(jCols, NuiRow(JsonArrayInsert(JsonArray(), jNxtLbl)));
    jCols = JsonArrayInsert(jCols, CreateEmptyRow(oPC, 6.0));
    jCols = JsonArrayInsert(jCols, NuiRow(JsonArrayInsert(JsonArray(), jClose)));

    return NuiCol(jCols);
}

void SeaFeedPlayerWindow(object oPC, int nToken)
{
    json jState = SeaGetStateRow();
    if (JsonGetType(jState) == JSON_TYPE_NULL) return;

    int nSeason  = JsonGetInt(JsonObjectGet(jState, "season"));
    int nWeather = JsonGetInt(JsonObjectGet(jState, "weather"));
    int nWeaChg  = JsonGetInt(JsonObjectGet(jState, "weather_changed"));

    NuiSetBind(oPC, nToken, SEA_BIND_SEASON_LBL,
        JsonString("Pora roku: " + SeaGetSeasonName(nSeason)));
    NuiSetBind(oPC, nToken, SEA_BIND_WEATHER_LBL,
        JsonString("Pogoda: " + SeaGetWeatherName(nWeather)));
    NuiSetBind(oPC, nToken, SEA_BIND_EFFECT_LBL,
        JsonString(SeaGetWeatherEffectDesc(nWeather)));
    NuiSetBind(oPC, nToken, SEA_BIND_NEXTCH_LBL,
        JsonString("Zmiana za: " + SeaNextChangeStr(nWeaChg)));
}

void SeaOpenPlayerWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, SEA_WIN_PLAYER);
    if (nToken != 0)
    {
        SeaFeedPlayerWindow(oPC, nToken);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, SEA_PLY_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, SEA_PLY_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
        GetNuiScaleDimension(oPC, SEA_PLY_W),
        GetNuiScaleDimension(oPC, SEA_PLY_H));

    json jLayout = BuildSeaPlayerLayout(oPC);

    json jWin = NuiWindow(jLayout,
        JsonString("Wiatrowskaz"),
        NuiBind("sea_ply_geom"),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    nToken = NuiCreate(oPC, jWin, SEA_WIN_PLAYER, SEA_EV_SCRIPT);
    NuiSetBind(oPC, nToken, "sea_ply_geom", jGeom);
    SeaFeedPlayerWindow(oPC, nToken);
}

// ----------------------------------------------------------------
// DM window
// ----------------------------------------------------------------

json BuildSeaDMLayout(object oPC)
{
    float fLbl  = GetNuiScaleDimension(oPC, 22.0);
    float fBtn  = GetNuiScaleDimension(oPC, 28.0);
    float fArrow = GetNuiScaleDimension(oPC, 30.0);

    // ---- Season row ----
    json jSeaHdr = NuiWidth(
        NuiHeight(NuiLabel(JsonString("Pora roku:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), fLbl),
        GetNuiScaleDimension(oPC, 100.0));

    json jPrevSea = NuiWidth(NuiHeight(
        NuiId(NuiButton(JsonString("<")), SEA_BTN_PREV_SEA), fBtn), fArrow);
    json jSeaVal  = NuiHeight(
        NuiLabel(NuiBind(SEA_BIND_DM_SEA_LBL), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)), fLbl);
    json jNextSea = NuiWidth(NuiHeight(
        NuiId(NuiButton(JsonString(">")), SEA_BTN_NEXT_SEA), fBtn), fArrow);

    json jSeaArr = JsonArray();
    jSeaArr = JsonArrayInsert(jSeaArr, jSeaHdr);
    jSeaArr = JsonArrayInsert(jSeaArr, jPrevSea);
    jSeaArr = JsonArrayInsert(jSeaArr, jSeaVal);
    jSeaArr = JsonArrayInsert(jSeaArr, jNextSea);
    json jSeaRow = NuiRow(jSeaArr);

    // ---- Weather row ----
    json jWeaHdr = NuiWidth(
        NuiHeight(NuiLabel(JsonString("Pogoda:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), fLbl),
        GetNuiScaleDimension(oPC, 100.0));

    json jPrevWea = NuiWidth(NuiHeight(
        NuiId(NuiButton(JsonString("<")), SEA_BTN_PREV_WEA), fBtn), fArrow);
    json jWeaVal  = NuiHeight(
        NuiLabel(NuiBind(SEA_BIND_DM_WEA_LBL), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)), fLbl);
    json jNextWea = NuiWidth(NuiHeight(
        NuiId(NuiButton(JsonString(">")), SEA_BTN_NEXT_WEA), fBtn), fArrow);

    json jWeaArr = JsonArray();
    jWeaArr = JsonArrayInsert(jWeaArr, jWeaHdr);
    jWeaArr = JsonArrayInsert(jWeaArr, jPrevWea);
    jWeaArr = JsonArrayInsert(jWeaArr, jWeaVal);
    jWeaArr = JsonArrayInsert(jWeaArr, jNextWea);
    json jWeaRow = NuiRow(jWeaArr);

    // ---- Area / climate section ----
    json jAreaHdrLbl = NuiHeight(
        NuiLabel(JsonString("Klimat bieżącego obszaru:"),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)),
        fLbl);
    json jAreaHdrRow = NuiRow(JsonArrayInsert(JsonArray(), jAreaHdrLbl));

    json jAreaLbl = NuiHeight(
        NuiLabel(NuiBind(SEA_BIND_DM_AREA_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)),
        fLbl);
    json jAreaRow = NuiRow(JsonArrayInsert(JsonArray(), jAreaLbl));

    // Five climate buttons
    json jClimArr = JsonArray();
    int ci;
    for (ci = 0; ci < SEA_CLIMATE_COUNT; ci++)
    {
        json jBtn = NuiHeight(
            NuiId(NuiButton(JsonString(SeaGetClimateName(ci))),
                SEA_BTN_CLIMATE + IntToString(ci)),
            fBtn);
        jClimArr = JsonArrayInsert(jClimArr, jBtn);
    }
    json jClimRow = NuiRow(jClimArr);

    // ---- Close ----
    json jCloseBtn = NuiHeight(
        NuiId(NuiButton(JsonString("Zamknij")), SEA_BTN_DM_CLOSE), fBtn);
    json jCloseRow = NuiRow(JsonArrayInsert(JsonArray(), jCloseBtn));

    json jCols = JsonArray();
    jCols = JsonArrayInsert(jCols, jSeaRow);
    jCols = JsonArrayInsert(jCols, jWeaRow);
    jCols = JsonArrayInsert(jCols, CreateEmptyRow(oPC, 8.0));
    jCols = JsonArrayInsert(jCols, jAreaHdrRow);
    jCols = JsonArrayInsert(jCols, jAreaRow);
    jCols = JsonArrayInsert(jCols, jClimRow);
    jCols = JsonArrayInsert(jCols, CreateEmptyRow(oPC, 8.0));
    jCols = JsonArrayInsert(jCols, jCloseRow);

    return NuiCol(jCols);
}

void SeaFeedDMWindow(object oPC, int nToken)
{
    json jState = SeaGetStateRow();
    if (JsonGetType(jState) == JSON_TYPE_NULL) return;

    int nSeason  = JsonGetInt(JsonObjectGet(jState, "season"));
    int nWeather = JsonGetInt(JsonObjectGet(jState, "weather"));

    NuiSetBind(oPC, nToken, SEA_BIND_DM_SEA_LBL, JsonString(SeaGetSeasonName(nSeason)));
    NuiSetBind(oPC, nToken, SEA_BIND_DM_WEA_LBL, JsonString(SeaGetWeatherName(nWeather)));

    object oArea    = GetArea(oPC);
    string sAreaTag = GetTag(oArea);
    int nClimate    = SeaGetAreaClimate(sAreaTag);
    NuiSetBind(oPC, nToken, SEA_BIND_DM_AREA_LBL,
        JsonString(GetName(oArea) + "  [" + SeaGetClimateName(nClimate) + "]"));
}

void SeaOpenDMWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, SEA_WIN_DM);
    if (nToken != 0)
    {
        SeaFeedDMWindow(oPC, nToken);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, SEA_DM_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, SEA_DM_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
        GetNuiScaleDimension(oPC, SEA_DM_W),
        GetNuiScaleDimension(oPC, SEA_DM_H));

    json jLayout = BuildSeaDMLayout(oPC);

    json jWin = NuiWindow(jLayout,
        JsonString("Mistrz Klimatu"),
        NuiBind("sea_dm_geom"),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE),
        JsonBool(TRUE));

    nToken = NuiCreate(oPC, jWin, SEA_WIN_DM, SEA_EV_SCRIPT);
    NuiSetBind(oPC, nToken, "sea_dm_geom", jGeom);
    SeaFeedDMWindow(oPC, nToken);
}

void SeaOpenWindow(object oPC)
{
    if (GetIsDM(oPC) || GetIsDMPossessed(oPC))
        SeaOpenDMWindow(oPC);
    else
        SeaOpenPlayerWindow(oPC);
}

void SeaUpdateAllWindows()
{
    object oPC = GetFirstPC();
    while (GetIsObjectValid(oPC))
    {
        int nPly = NuiFindWindow(oPC, SEA_WIN_PLAYER);
        if (nPly != 0) SeaFeedPlayerWindow(oPC, nPly);

        int nDM = NuiFindWindow(oPC, SEA_WIN_DM);
        if (nDM != 0) SeaFeedDMWindow(oPC, nDM);

        oPC = GetNextPC();
    }
}

// ----------------------------------------------------------------
// Periodic tick — called from sea_hb_tick.nss via ExecuteScript
// ----------------------------------------------------------------

void SeaTick()
{
    json jState = SeaGetStateRow();
    if (JsonGetType(jState) == JSON_TYPE_NULL) return;

    int nNow       = SeaGetNow();
    int nSeason    = JsonGetInt(JsonObjectGet(jState, "season"));
    int nWeather   = JsonGetInt(JsonObjectGet(jState, "weather"));
    int nSeaChg    = JsonGetInt(JsonObjectGet(jState, "season_changed"));
    int nWeaChg    = JsonGetInt(JsonObjectGet(jState, "weather_changed"));

    int bWeatherUpdated = FALSE;

    // Advance season when its duration has elapsed
    if (nSeaChg > 0 && (nNow - nSeaChg) >= SEA_SEASON_DURATION)
    {
        nSeason = (nSeason >= SEA_SEASON_DYING) ? SEA_SEASON_SPRING : nSeason + 1;
        SeaSetSeason(nSeason);
        // Force immediate weather re-roll on season change
        nWeaChg = 0;
        SeaNotifyAll("Nadeszła nowa pora roku: " + SeaGetSeasonName(nSeason) + ".");
    }

    // Advance weather when its interval has elapsed (or never set)
    if (nWeaChg == 0 || (nNow - nWeaChg) >= SEA_WEATHER_INTERVAL)
    {
        // Climate of the first online PC's area, or temperate as fallback
        int nClimate = SEA_CLIMATE_TEMPERATE;
        object oRef  = GetFirstPC();
        if (GetIsObjectValid(oRef))
            nClimate = SeaGetAreaClimate(GetTag(GetArea(oRef)));

        int nNew = SeaPickWeather(nSeason, nClimate);
        SeaSetWeather(nNew);

        // Announce only when weather actually changes after first init
        if (nWeaChg > 0 && nNew != nWeather)
            SeaNotifyAll(SeaGetSeasonName(nSeason) + ": " + SeaGetWeatherName(nNew) + ".");

        nWeather        = nNew;
        bWeatherUpdated = TRUE;
    }

    // Always sync effects (handles indoor/outdoor transitions too)
    SeaUpdateAllPCs();
    if (bWeatherUpdated)
        SeaUpdateAllWindows();

    // Blizzard: 1d4 cold damage per tick for outdoor PCs
    if (nWeather == SEA_WEATHER_BLIZZARD)
    {
        object oPC = GetFirstPC();
        while (GetIsObjectValid(oPC))
        {
            if (SeaIsOutdoor(oPC))
            {
                int nDmg = Random(4) + 1;
                ApplyEffectToObject(DURATION_TYPE_INSTANT,
                    EffectVisualEffect(VFX_IMP_FROST_S), oPC);
                ApplyEffectToObject(DURATION_TYPE_INSTANT,
                    EffectDamage(nDmg, DAMAGE_TYPE_COLD), oPC);
            }
            oPC = GetNextPC();
        }
    }

    // Storm: 1% chance per tick of a lightning strike (outdoor PCs, DC 18 Fortitude)
    if (nWeather == SEA_WEATHER_STORM)
    {
        object oPC = GetFirstPC();
        while (GetIsObjectValid(oPC))
        {
            if (SeaIsOutdoor(oPC) && Random(100) < 1)
            {
                ApplyEffectToObject(DURATION_TYPE_INSTANT,
                    EffectVisualEffect(VFX_IMP_LIGHTNING_S), oPC);
                if (!FortitudeSave(oPC, 18, SAVING_THROW_TYPE_ELECTRICITY, OBJECT_SELF))
                {
                    int nDmg = d6(2) + 2;
                    ApplyEffectToObject(DURATION_TYPE_INSTANT,
                        EffectDamage(nDmg, DAMAGE_TYPE_ELECTRICAL), oPC);
                    FloatingTextStringOnCreature("Piorun uderza!", oPC, FALSE);
                }
            }
            oPC = GetNextPC();
        }
    }
}

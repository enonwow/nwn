#include "lib_herb_def"

// ----------------------------------------------------------------
// Forward declarations
// ----------------------------------------------------------------

void OpenHarvestWindow(object oPC, object oNode);
void FeedHarvestWindow(object oPC, int nToken);
void OpenJournalWindow(object oPC);
void FeedJournalWindow(object oPC, int nToken);

// ================================================================
// Herb data — name, lore, effect description, season
// ================================================================

string HerbGetName(int nType)
{
    switch(nType)
    {
        case HERB_BLOODMOSS:    return "Krwawnik";
        case HERB_NIGHTSHADE:   return "Nocny Cień";
        case HERB_SUNROOT:      return "Słonecznik Polny";
        case HERB_GHOSTWEED:    return "Strach-Ziele";
        case HERB_IRONBARK:     return "Żelazokora";
        case HERB_GRAVEMINT:    return "Grobowamiętka";
        case HERB_VOIDFERN:     return "Pustokwiat";
        case HERB_WITCH_CLOVER: return "Wiedźmia Koniczyna";
    }
    return "Nieznane Zioło";
}

string HerbGetDesc(int nType)
{
    switch(nType)
    {
        case HERB_BLOODMOSS:
            return "Ciemnoczerwony mech rosnący na mokrych kamieniach i spróchniałych pniach. "
                   "Zbierany jesienią, gdy deszcze nasycają go żelazistą wodą. Przyłożony do "
                   "rany natychmiast zaciska naczynia krwionośne. Zielarki mówią, że pamięta "
                   "smak każdej przelanej krwi.";
        case HERB_NIGHTSHADE:
            return "Czarne jagody o mdlącym, słodkawym aromacie. Mała dawka paradoksalnie "
                   "uodparnia mięśnie na toksyny paraliżujące — większa zabija. Rośnie jedynie "
                   "zimą, w cieniu głazów pokrytych lodem. Zbieranie bez rękawic jest szaleństwem.";
        case HERB_SUNROOT:
            return "Żółty korzeń wyrastający z wiosennego błota przy rzekach. Spożywany surowy "
                   "smakuje jak świeża trawa i miód. Ciepło, które daje, rozchodzi się po ciele "
                   "od żołądka ku kończynom, łatając drobne uszkodzenia ciała.";
        case HERB_GHOSTWEED:
            return "Blada, niemal przezroczysta trawa rosnąca na pobojowiskach i cmentarzach. "
                   "Mówi się, że wyrasta tam, gdzie duchy nie chcą odejść. Rozgryziona tuż przed "
                   "bitwą wypędza strach z serca — nie dlatego, że go nie ma, lecz dlatego, "
                   "że przestaje mieć znaczenie.";
        case HERB_IRONBARK:
            return "Łuszcząca się kora drzew rosnących przy złożach żelaznej rudy. Latem, "
                   "gdy słońce wypala z niej wilgoć, staje się twarda jak łupek. Zielarze "
                   "moczą ją w oleju i wcierają w skórę — twardnieje ona wtedy jak skórzana zbroja.";
        case HERB_GRAVEMINT:
            return "Mięta o lodowato niebieskich liściach, rosnąca przy studniach, fontannach "
                   "i w wilgotnych jaskiniach. Zimą kwitnie maleńkimi kryształkami lodu zamiast "
                   "kwiatów. Przeżuta chroni przed mrozem i wychłodzeniem — krew płynie szybciej, "
                   "choć oddech paruje gęstym obłokiem.";
        case HERB_VOIDFERN:
            return "Paproć o czarnych, aksamitnych zarodnikach, rosnąca wyłącznie tam, gdzie "
                   "magia się skupia — w jaskiniach starych magów, przy runie spalonych świątyń. "
                   "Zarodniki wdychane przez zielarza wyostrzają percepcję do granic bólu: "
                   "aurę magii widać jak dym, a iluzje rozpadają się w pył.";
        case HERB_WITCH_CLOVER:
            return "Czterolistna koniczyna o złotawym odcieniu, spotykana raz na tysiąc łąk. "
                   "Noszący ją przy sobie twierdzą, że los się do nich uśmiecha — strzały lecą "
                   "o cal za daleko, kamień spada o chwilę za wcześnie. Wiedźmy zbierają ją "
                   "w noc nowiu i nie powiedzą, do czego naprawdę służy.";
    }
    return "Zioło o nieznanym przeznaczeniu.";
}

string HerbGetEffect(int nType)
{
    switch(nType)
    {
        case HERB_BLOODMOSS:    return "Przywraca 5 PŻ.";
        case HERB_NIGHTSHADE:   return "Odporność na paraliż przez 10 minut.";
        case HERB_SUNROOT:      return "Przywraca 8 PŻ.";
        case HERB_GHOSTWEED:    return "Odporność na strach przez 10 minut.";
        case HERB_IRONBARK:     return "Naturalny pancerz +2 przez 10 minut.";
        case HERB_GRAVEMINT:    return "Odporność na zimno (5 pkt) przez 10 minut.";
        case HERB_VOIDFERN:     return "Prawdziwe widzenie przez 10 minut.";
        case HERB_WITCH_CLOVER: return "+2 do wszystkich rzutów obronnych przez 10 minut.";
    }
    return "Brak efektu.";
}

// Returns SEASON_* constant, or -1 for year-round herbs
int HerbGetSeason(int nType)
{
    switch(nType)
    {
        case HERB_BLOODMOSS:    return SEASON_AUTUMN;
        case HERB_NIGHTSHADE:   return SEASON_WINTER;
        case HERB_SUNROOT:      return SEASON_SPRING;
        case HERB_GHOSTWEED:    return -1;
        case HERB_IRONBARK:     return SEASON_SUMMER;
        case HERB_GRAVEMINT:    return SEASON_WINTER;
        case HERB_VOIDFERN:     return -1;
        case HERB_WITCH_CLOVER: return -1;
    }
    return -1;
}

string HerbGetSeasonName(int nSeason)
{
    switch(nSeason)
    {
        case SEASON_SPRING: return "Wiosna";
        case SEASON_SUMMER: return "Lato";
        case SEASON_AUTUMN: return "Jesień";
        case SEASON_WINTER: return "Zima";
    }
    return "Każda";
}

string HerbGetSeasonForType(int nType)
{
    int nSeas = HerbGetSeason(nType);
    if(nSeas < 0) return "Każda pora";
    return HerbGetSeasonName(nSeas);
}

int HerbGetCurrentSeason()
{
    int nMonth = GetCalendarMonth();
    if(nMonth >= 3 && nMonth <= 5)  return SEASON_SPRING;
    if(nMonth >= 6 && nMonth <= 8)  return SEASON_SUMMER;
    if(nMonth >= 9 && nMonth <= 11) return SEASON_AUTUMN;
    return SEASON_WINTER;
}

int HerbIsInSeason(int nType)
{
    int nSeas = HerbGetSeason(nType);
    if(nSeas < 0) return TRUE;
    return (nSeas == HerbGetCurrentSeason());
}

// ================================================================
// Apply herb effect to PC
// ================================================================

void HerbApplyEffect(object oPC, int nType)
{
    switch(nType)
    {
        case HERB_BLOODMOSS:
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(5), oPC);
            SendMessageToPC(oPC, "[Zielarz] Krwawnik zatamował krew. Rany powoli się zamykają.");
            break;
        case HERB_NIGHTSHADE:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectImmunity(IMMUNITY_TYPE_PARALYSIS), oPC, HERB_EFFECT_DUR);
            SendMessageToPC(oPC, "[Zielarz] Gorycz Nocnego Cienia przenika nerwy. Paraliż cię nie dosięgnie.");
            break;
        case HERB_SUNROOT:
            ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(8), oPC);
            SendMessageToPC(oPC, "[Zielarz] Słonecznik Polny krzepi ciało i przywraca ciepło.");
            break;
        case HERB_GHOSTWEED:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectImmunity(IMMUNITY_TYPE_FEAR), oPC, HERB_EFFECT_DUR);
            SendMessageToPC(oPC, "[Zielarz] Strach-Ziele wypaliło lęk z twojego serca. Strach przestał mieć znaczenie.");
            break;
        case HERB_IRONBARK:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectACIncrease(2, AC_NATURAL_BONUS), oPC, HERB_EFFECT_DUR);
            SendMessageToPC(oPC, "[Zielarz] Żelazokora twardnieje na skórze. Czujesz się odporniejszy na ciosy.");
            break;
        case HERB_GRAVEMINT:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectDamageResistance(DAMAGE_TYPE_COLD, 5, 0), oPC, HERB_EFFECT_DUR);
            SendMessageToPC(oPC, "[Zielarz] Lodowata Grobowamiętka chroni przed mrozem. Krew płynie szybciej.");
            break;
        case HERB_VOIDFERN:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectTrueSeeing(), oPC, HERB_EFFECT_DUR);
            SendMessageToPC(oPC, "[Zielarz] Zarodniki Pustokwiatu wyostrzają zmysły. Magia staje się widoczna jak dym.");
            break;
        case HERB_WITCH_CLOVER:
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
                EffectSavingThrowIncrease(SAVING_THROW_ALL, 2), oPC, HERB_EFFECT_DUR);
            SendMessageToPC(oPC, "[Zielarz] Wiedźmia Koniczyna przynosi łut szczęścia. Los się uśmiecha.");
            break;
    }
}

// ================================================================
// Harvest window
// ================================================================

void OpenHarvestWindow(object oPC, object oNode)
{
    if(NuiFindWindow(oPC, HERB_WIN_HARVEST) != 0)
        NuiDestroy(oPC, NuiFindWindow(oPC, HERB_WIN_HARVEST));

    string sTag  = GetTag(oNode);
    int    nType = HerbNodeGetType(sTag);

    SetLocalString(oPC, HERB_LVAR_NODE,  sTag);
    SetLocalInt   (oPC, HERB_LVAR_NTYPE, nType);

    float fW    = GetNuiScaleDimension(oPC, HERB_HW);
    float fH    = GetNuiScaleDimension(oPC, HERB_HH);
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fX    = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY    = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;
    json jGeom  = NuiRect(fX, fY, fW, fH);

    // Name label (larger, centered)
    json jName = NuiLabel(NuiBind(HERB_BIND_H_NAME), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiHeight(jName, GetNuiScaleDimension(oPC, 34.0));

    // Scrollable description
    json jDesc = NuiGroup(NuiText(NuiBind(HERB_BIND_H_DESC), FALSE), TRUE, NUI_SCROLLBARS_NONE);
    jDesc = NuiHeight(jDesc, GetNuiScaleDimension(oPC, 80.0));

    // Charges remaining
    json jChrg = NuiLabel(NuiBind(HERB_BIND_H_CHRG), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jChrg = NuiHeight(jChrg, GetNuiScaleDimension(oPC, 22.0));

    // Season bonus indicator
    json jBonus = NuiLabel(NuiBind(HERB_BIND_H_BONUS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jBonus = NuiHeight(jBonus, GetNuiScaleDimension(oPC, 20.0));

    json jHarvestBtn = NuiButton(JsonString("Zbierz"));
    jHarvestBtn = NuiId(jHarvestBtn, HERB_BTN_HARVEST);
    jHarvestBtn = NuiEnabled(jHarvestBtn, NuiBind(HERB_BIND_H_ENA));
    jHarvestBtn = NuiWidth(jHarvestBtn,  GetNuiScaleDimension(oPC, 120.0));
    jHarvestBtn = NuiHeight(jHarvestBtn, fBtnH);

    json jJournalBtn = NuiButton(JsonString("Dziennik"));
    jJournalBtn = NuiId(jJournalBtn, HERB_BTN_JOURNAL);
    jJournalBtn = NuiWidth(jJournalBtn,  GetNuiScaleDimension(oPC, 110.0));
    jJournalBtn = NuiHeight(jJournalBtn, fBtnH);

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, HERB_BTN_CLOSE_H);
    jCloseBtn = NuiWidth(jCloseBtn,  GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jBtnRow = JsonArray();
    jBtnRow = JsonArrayInsert(jBtnRow, jHarvestBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jJournalBtn);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jCloseBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jName);
    jCol = JsonArrayInsert(jCol, jDesc);
    jCol = JsonArrayInsert(jCol, jChrg);
    jCol = JsonArrayInsert(jCol, jBonus);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jWin = NuiWindow(NuiCol(jCol),
        JsonBool(FALSE),
        NuiBind(HERB_BIND_H_GEOM),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(FALSE), JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, HERB_WIN_HARVEST, HERB_EV);
    NuiSetBind(oPC, nToken, HERB_BIND_H_GEOM, jGeom);
    FeedHarvestWindow(oPC, nToken);
}

void FeedHarvestWindow(object oPC, int nToken)
{
    string sTag   = GetLocalString(oPC, HERB_LVAR_NODE);
    int    nType  = GetLocalInt   (oPC, HERB_LVAR_NTYPE);

    HerbNodeRegen(sTag, HERB_REGEN_SECS);
    int nCharges = HerbNodeGetCharges(sTag);
    int bSeason  = HerbIsInSeason(nType);

    string sBonus = bSeason
        ? "★ Sezon zbiorów — dodatkowy plon!"
        : "Poza sezonem zbiorów.";

    NuiSetBind(oPC, nToken, HERB_BIND_H_NAME,  JsonString(HerbGetName(nType)));
    NuiSetBind(oPC, nToken, HERB_BIND_H_DESC,  JsonString(HerbGetDesc(nType)));
    NuiSetBind(oPC, nToken, HERB_BIND_H_CHRG,
        JsonString("Plony: " + IntToString(nCharges) + " / " + IntToString(HERB_NODE_CHARGES)));
    NuiSetBind(oPC, nToken, HERB_BIND_H_BONUS, JsonString(sBonus));
    NuiSetBind(oPC, nToken, HERB_BIND_H_ENA,   JsonBool(nCharges > 0));
}

// ================================================================
// Journal window
// ================================================================

json BuildJournalLayout(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fRowH = GetNuiScaleDimension(oPC, 28.0);

    float fNameW = GetNuiScaleDimension(oPC, 190.0);
    float fCntW  = GetNuiScaleDimension(oPC, 62.0);
    float fSeasW = GetNuiScaleDimension(oPC, 100.0);

    // List row template: name | count | season
    json jNameLbl = NuiLabel(NuiBind(HERB_BIND_J_RNAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(HERB_BIND_J_RCOL));

    json jCntLbl = NuiLabel(NuiBind(HERB_BIND_J_RCNT), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jCntLbl = NuiWidth(jCntLbl, fCntW);
    jCntLbl = NuiStyleForegroundColor(jCntLbl, NuiBind(HERB_BIND_J_RCOL));

    json jSeasLbl = NuiLabel(NuiBind(HERB_BIND_J_RSEAS), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jSeasLbl = NuiWidth(jSeasLbl, fSeasW);
    jSeasLbl = NuiStyleForegroundColor(jSeasLbl, NuiBind(HERB_BIND_J_RCOL));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow,
        NuiWidth(NuiCol(JsonArrayInsert(JsonArray(), jNameLbl)), fNameW));
    jCellRow = JsonArrayInsert(jCellRow, jCntLbl);
    jCellRow = JsonArrayInsert(jCellRow, jSeasLbl);

    json jCell = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, HERB_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(HERB_BIND_J_RENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));
    float fListH = GetNuiScaleDimension(oPC, 200.0);
    json jList = NuiList(jTmpl, NuiBind(HERB_BIND_J_ROWS), fRowH);
    jList = NuiHeight(jList, fListH);

    // Lore panel: selected herb name + desc + effect
    json jLoreN = NuiLabel(NuiBind(HERB_BIND_LORE_N), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLoreN = NuiHeight(jLoreN, GetNuiScaleDimension(oPC, 24.0));

    json jLoreT = NuiGroup(NuiText(NuiBind(HERB_BIND_LORE_T), FALSE), TRUE, NUI_SCROLLBARS_NONE);
    jLoreT = NuiHeight(jLoreT, GetNuiScaleDimension(oPC, 95.0));

    json jLoreP = NuiLabel(NuiBind(HERB_BIND_LORE_P), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLoreP = NuiHeight(jLoreP, GetNuiScaleDimension(oPC, 22.0));

    // Use / Close buttons
    json jUseBtn = NuiButton(NuiBind(HERB_BIND_USE_LBL));
    jUseBtn = NuiId(jUseBtn, HERB_BTN_USE);
    jUseBtn = NuiEnabled(jUseBtn, NuiBind(HERB_BIND_USE_ENA));
    jUseBtn = NuiWidth(jUseBtn,  GetNuiScaleDimension(oPC, 150.0));
    jUseBtn = NuiHeight(jUseBtn, fBtnH);

    json jCloseBtn = NuiButton(JsonString("Zamknij"));
    jCloseBtn = NuiId(jCloseBtn, HERB_BTN_CLOSE_J);
    jCloseBtn = NuiWidth(jCloseBtn,  GetNuiScaleDimension(oPC, 90.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jUseBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jCloseBtn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, jLoreN);
    jCol = JsonArrayInsert(jCol, jLoreT);
    jCol = JsonArrayInsert(jCol, jLoreP);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jBotRow));

    return NuiCol(jCol);
}

void OpenJournalWindow(object oPC)
{
    if(NuiFindWindow(oPC, HERB_WIN_JOURNAL) != 0)
    {
        FeedJournalWindow(oPC, NuiFindWindow(oPC, HERB_WIN_JOURNAL));
        return;
    }

    float fW  = GetNuiScaleDimension(oPC, HERB_JW);
    float fH  = GetNuiScaleDimension(oPC, HERB_JH);
    float fX  = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - fW) / 2.0;
    float fY  = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - fH) / 2.0;
    json jGeom = NuiRect(fX, fY, fW, fH);

    json jWin = NuiWindow(BuildJournalLayout(oPC),
        JsonString("Dziennik Zielarza"),
        NuiBind(HERB_BIND_J_GEOM),
        JsonBool(TRUE), JsonBool(FALSE), JsonBool(TRUE),
        JsonBool(TRUE),  JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, HERB_WIN_JOURNAL, HERB_EV);
    NuiSetBind(oPC, nToken, HERB_BIND_J_GEOM, jGeom);
    SetLocalInt(oPC, HERB_LVAR_SEL, 0);
    FeedJournalWindow(oPC, nToken);
}

void FeedJournalWindow(object oPC, int nToken)
{
    json jAll   = HerbPlayerGetAll(oPC);
    int  nCount = JsonGetLength(jAll);
    int  nSel   = GetLocalInt(oPC, HERB_LVAR_SEL);
    int  nCurSeas = HerbGetCurrentSeason();

    json jNames = JsonArray();
    json jCnts  = JsonArray();
    json jSeas  = JsonArray();
    json jEncs  = JsonArray();
    json jCols  = JsonArray();

    json jGreen = NuiColor(100, 220, 100);
    json jWhite = NuiColor(210, 210, 210);

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow  = JsonArrayGet(jAll, i);
        int  nType = JsonGetInt(JsonObjectGet(jRow, "type"));
        int  nCnt  = JsonGetInt(JsonObjectGet(jRow, "count"));
        int  nSeas = HerbGetSeason(nType);
        int  bIn   = (nSeas < 0 || nSeas == nCurSeas);

        jNames = JsonArrayInsert(jNames, JsonString(HerbGetName(nType)));
        jCnts  = JsonArrayInsert(jCnts,  JsonString(IntToString(nCnt) + " szt."));
        jSeas  = JsonArrayInsert(jSeas,  JsonString(HerbGetSeasonForType(nType)));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(nType == nSel));
        jCols  = JsonArrayInsert(jCols,  bIn ? jGreen : jWhite);
    }

    NuiSetBind(oPC, nToken, HERB_BIND_J_RNAME, jNames);
    NuiSetBind(oPC, nToken, HERB_BIND_J_RCNT,  jCnts);
    NuiSetBind(oPC, nToken, HERB_BIND_J_RSEAS, jSeas);
    NuiSetBind(oPC, nToken, HERB_BIND_J_RENC,  jEncs);
    NuiSetBind(oPC, nToken, HERB_BIND_J_RCOL,  jCols);
    NuiSetBind(oPC, nToken, HERB_BIND_J_ROWS,  JsonInt(nCount));

    if(nSel > 0)
    {
        int nHave = HerbPlayerGetCount(oPC, nSel);
        NuiSetBind(oPC, nToken, HERB_BIND_LORE_N, JsonString("▸ " + HerbGetName(nSel)));
        NuiSetBind(oPC, nToken, HERB_BIND_LORE_T, JsonString(HerbGetDesc(nSel)));
        NuiSetBind(oPC, nToken, HERB_BIND_LORE_P, JsonString("Efekt: " + HerbGetEffect(nSel)));
        NuiSetBind(oPC, nToken, HERB_BIND_USE_ENA, JsonBool(nHave > 0));
        NuiSetBind(oPC, nToken, HERB_BIND_USE_LBL,
            JsonString("Zażyj (" + IntToString(nHave) + " szt.)"));
    }
    else
    {
        NuiSetBind(oPC, nToken, HERB_BIND_LORE_N,  JsonString("Wybierz zioło z listy."));
        NuiSetBind(oPC, nToken, HERB_BIND_LORE_T,  JsonString(""));
        NuiSetBind(oPC, nToken, HERB_BIND_LORE_P,  JsonString(""));
        NuiSetBind(oPC, nToken, HERB_BIND_USE_ENA, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, HERB_BIND_USE_LBL, JsonString("Zażyj"));
    }
}

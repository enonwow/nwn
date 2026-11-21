#include "lib_gla_def"

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------

string ArenaLeagueName(int nLeague)
{
    switch(nLeague)
    {
        case ARENA_LEAGUE_RECRUIT:  return "Rekrut";
        case ARENA_LEAGUE_WARRIOR:  return "Wojownik";
        case ARENA_LEAGUE_CHAMPION: return "Mistrz";
    }
    return "Rekrut";
}

int ArenaLeagueInfamy(int nLeague)
{
    switch(nLeague)
    {
        case ARENA_LEAGUE_RECRUIT:  return ARENA_INF_WIN_L1;
        case ARENA_LEAGUE_WARRIOR:  return ARENA_INF_WIN_L2;
        case ARENA_LEAGUE_CHAMPION: return ARENA_INF_WIN_L3;
    }
    return ARENA_INF_WIN_L1;
}

string ArenaTitleFromWins(int nTotalWins)
{
    if(nTotalWins >= ARENA_WINS_LEGEND)  return "Legenda Krwi";
    if(nTotalWins >= ARENA_WINS_VETERAN) return "Weteran Areny";
    if(nTotalWins >= ARENA_WINS_FIGHTER) return "Gladiator";
    return "Nowicjusz";
}

// Number of creatures spawned per wave, scales with league.
int ArenaWaveSize(int nLeague)
{
    switch(nLeague)
    {
        case ARENA_LEAGUE_RECRUIT:  return 2;
        case ARENA_LEAGUE_WARRIOR:  return 3;
        case ARENA_LEAGUE_CHAMPION: return 4;
    }
    return 2;
}

// Returns the creature blueprint resref for a given league, wave index (0-2), and slot (0-3).
// Wave index drives escalating toughness within a fight session.
string ArenaCreatureResRef(int nLeague, int nWave, int nSlot)
{
    if(nLeague == ARENA_LEAGUE_RECRUIT)
    {
        if(nWave == 0) return (nSlot == 0 ? "nw_goblin001" : "nw_goblina");
        if(nWave == 1) return (nSlot < 2   ? "nw_bandit001" : "nw_bandita");
        return (nSlot == 0 ? "nw_bandit001" : "nw_kobold001");
    }
    if(nLeague == ARENA_LEAGUE_WARRIOR)
    {
        if(nWave == 0) return (nSlot < 2 ? "nw_orc001"      : "nw_orca");
        if(nWave == 1) return (nSlot < 2 ? "nw_gnoll001"    : "nw_gnollarcher");
        return (nSlot < 2 ? "nw_bugbear001" : "nw_gnoll001");
    }
    // ARENA_LEAGUE_CHAMPION
    if(nWave == 0) return (nSlot < 2 ? "nw_ogre001"      : "nw_ogrehalf001");
    if(nWave == 1) return (nSlot < 2 ? "nw_troll001"     : "nw_ogre001");
    return (nSlot < 3 ? "nw_gianthill001" : "nw_troll001");
}

// ----------------------------------------------------------------
// Fight: spawn / clear / check
// ----------------------------------------------------------------

void ArenaClearSpawns(object oPC)
{
    int nCount = GetLocalInt(oPC, ARENA_LVAR_SPAWN_N);
    int i;
    for(i = 0; i < nCount; i++)
    {
        object oC = GetLocalObject(oPC, "ARENA_C_" + IntToString(i));
        if(GetIsObjectValid(oC) && !GetIsDead(oC))
            DestroyObject(oC, 0.0);
    }
    SetLocalInt(oPC, ARENA_LVAR_SPAWN_N, 0);
}

void ArenaSpawnWave(object oPC, int nWave)
{
    int nLeague = GetLocalInt(oPC, ARENA_LVAR_FT_LG);
    int nSize   = ArenaWaveSize(nLeague);

    int i;
    for(i = 0; i < nSize; i++)
    {
        string sRes  = ArenaCreatureResRef(nLeague, nWave, i);
        // Spread spawns in a ring of radius 5 at equal angles so they don't stack.
        float fAngle = (360.0 / IntToFloat(nSize)) * IntToFloat(i);
        location lSpawn = GenerateNewLocation(oPC, 5.0, fAngle, fAngle + 180.0);
        object oC = CreateObject(OBJECT_TYPE_CREATURE, sRes, lSpawn);
        if(GetIsObjectValid(oC))
        {
            SetLocalObject(oPC, "ARENA_C_" + IntToString(i), oC);
            ChangeToStandardFaction(oC, STANDARD_FACTION_HOSTILE);
            // Short delay before attack command so the creature spawns fully
            DelayCommand(0.5, AssignCommand(oC, ActionAttack(oPC)));
        }
    }
    SetLocalInt(oPC, ARENA_LVAR_SPAWN_N, nSize);

    SendMessageToPC(oPC, "[Arena] Fala " + IntToString(nWave + 1) + "/" +
        IntToString(ARENA_WAVES_PER_FIGHT) + " wchodzi na piasek!");
}

void ArenaCheckWave(object oPC)
{
    if(!GetLocalInt(oPC, ARENA_LVAR_IN_FIGHT)) return;
    if(!GetIsObjectValid(oPC))                 return;

    if(GetIsDead(oPC))
    {
        ArenaHandleLoss(oPC);
        return;
    }

    // Count down the timeout so fights don't linger forever.
    int nLeft = GetLocalInt(oPC, ARENA_LVAR_TIMEOUT) - ARENA_CHECK_DELAY;
    SetLocalInt(oPC, ARENA_LVAR_TIMEOUT, nLeft);
    if(nLeft <= 0)
    {
        SendMessageToPC(oPC, "[Arena] Czas się skończył. Walka przegrana z powodu opieszałości.");
        ArenaClearSpawns(oPC);
        ArenaHandleLoss(oPC);
        return;
    }

    // Count arena creatures that are still alive.
    int nCount = GetLocalInt(oPC, ARENA_LVAR_SPAWN_N);
    int nAlive = 0;
    int i;
    for(i = 0; i < nCount; i++)
    {
        object oC = GetLocalObject(oPC, "ARENA_C_" + IntToString(i));
        if(GetIsObjectValid(oC) && !GetIsDead(oC))
            nAlive++;
    }

    if(nAlive > 0)
    {
        DelayCommand(IntToFloat(ARENA_CHECK_DELAY), ArenaCheckWave(oPC));
        return;
    }

    // Wave cleared — advance or declare victory.
    int nWave = GetLocalInt(oPC, ARENA_LVAR_WAVE) + 1;
    SetLocalInt(oPC, ARENA_LVAR_WAVE, nWave);

    if(nWave >= ARENA_WAVES_PER_FIGHT)
    {
        ArenaHandleWin(oPC);
    }
    else
    {
        SendMessageToPC(oPC, "[Arena] Fala " + IntToString(nWave) + " pokonana. Chwila wytchnienia...");
        DelayCommand(2.0, ArenaSpawnWave(oPC, nWave));
        DelayCommand(2.0 + IntToFloat(ARENA_CHECK_DELAY), ArenaCheckWave(oPC));
    }
}

void ArenaHandleWin(object oPC)
{
    SetLocalInt(oPC, ARENA_LVAR_IN_FIGHT, 0);
    int    nLeague    = GetLocalInt(oPC, ARENA_LVAR_FT_LG);
    int    nInfGain   = ArenaLeagueInfamy(nLeague);
    string sUuid      = GetObjectUUID(oPC);

    ArenaRecordWin(sUuid, nLeague, nInfGain);

    json   jF      = ArenaGetFighter(sUuid);
    int    nWins   = JsonGetInt(JsonObjectGet(jF, "total_wins"));
    string sTitle  = ArenaTitleFromWins(nWins);

    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
        EffectVisualEffect(VFX_IMP_GOOD_HELP), oPC, 5.0);
    FloatingTextStringOnCreature("Zwycięstwo! +" + IntToString(nInfGain) + " infamii", oPC, FALSE);
    SendMessageToPC(oPC, "[Arena] Wszystkie fale pokonane. Infamia +" + IntToString(nInfGain) +
        ". Tytuł: " + sTitle + ".");

    // Special fanfare when the fighter crosses a title threshold for the first time.
    if(nWins == ARENA_WINS_FIGHTER || nWins == ARENA_WINS_VETERAN || nWins == ARENA_WINS_LEGEND)
    {
        FloatingTextStringOnCreature("Nowy tytuł: " + sTitle + "!", oPC, FALSE);
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
            EffectVisualEffect(VFX_FNF_LOS_NORMAL_20), oPC, 3.0);
        SendMessageToPC(oPC, "[Arena] Tłum skanduje twoje imię. Tytuł '" + sTitle + "' jest twój.");
    }

    int nToken = NuiFindWindow(oPC, ARENA_WINDOW);
    if(nToken != 0)
    {
        ArenaFeedLeaderboard(oPC, nToken);
        ArenaFeedStatus(oPC, nToken);
    }
}

void ArenaHandleLoss(object oPC)
{
    SetLocalInt(oPC, ARENA_LVAR_IN_FIGHT, 0);
    string sUuid = GetObjectUUID(oPC);
    ArenaRecordLoss(sUuid, ARENA_INF_LOSS);

    FloatingTextStringOnCreature("Porażka... -" + IntToString(ARENA_INF_LOSS) + " infamii", oPC, FALSE);
    SendMessageToPC(oPC, "[Arena] Porażka. Blizny uczą lepiej niż słowa. Infamia -" +
        IntToString(ARENA_INF_LOSS) + ".");

    int nToken = NuiFindWindow(oPC, ARENA_WINDOW);
    if(nToken != 0)
    {
        ArenaFeedLeaderboard(oPC, nToken);
        ArenaFeedStatus(oPC, nToken);
    }
}

void ArenaStartFight(object oPC)
{
    if(GetLocalInt(oPC, ARENA_LVAR_IN_FIGHT))
    {
        SendMessageToPC(oPC, "[Arena] Walka już trwa.");
        return;
    }

    int nLeague = GetLocalInt(oPC, ARENA_LVAR_LEAGUE);
    if(nLeague == 0) nLeague = ARENA_LEAGUE_RECRUIT;

    SetLocalInt(oPC, ARENA_LVAR_IN_FIGHT, 1);
    SetLocalInt(oPC, ARENA_LVAR_WAVE,     0);
    SetLocalInt(oPC, ARENA_LVAR_FT_LG,   nLeague);
    SetLocalInt(oPC, ARENA_LVAR_TIMEOUT,  ARENA_TIMEOUT_SEC);

    SendMessageToPC(oPC, "[Arena] Wchodzisz na piasek. Liga: " + ArenaLeagueName(nLeague) +
        ". " + IntToString(ARENA_WAVES_PER_FIGHT) + " fale. Powodzenia.");
    FloatingTextStringOnCreature("Arena — " + ArenaLeagueName(nLeague), oPC, FALSE);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectVisualEffect(VFX_IMP_DOOM), oPC, 2.0);

    ArenaSpawnWave(oPC, 0);
    DelayCommand(IntToFloat(ARENA_CHECK_DELAY), ArenaCheckWave(oPC));

    int nToken = NuiFindWindow(oPC, ARENA_WINDOW);
    if(nToken != 0)
        ArenaFeedStatus(oPC, nToken);
}

// ----------------------------------------------------------------
// NUI: leaderboard view
// ----------------------------------------------------------------

json ArenaBuildLeaderboardView(object oPC)
{
    float fRowH   = GetNuiScaleDimension(oPC, 26.0);
    float fHdrH   = GetNuiScaleDimension(oPC, 28.0);
    float fRankW  = GetNuiScaleDimension(oPC, 32.0);
    float fNameW  = GetNuiScaleDimension(oPC, 180.0);
    float fLeagW  = GetNuiScaleDimension(oPC, 90.0);
    float fNumW   = GetNuiScaleDimension(oPC, 58.0);

    // Header
    json jHdr = JsonArray();
    jHdr = JsonArrayInsert(jHdr, NuiWidth(NuiLabel(JsonString("#"),       JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)), fRankW));
    jHdr = JsonArrayInsert(jHdr, NuiWidth(NuiLabel(JsonString("Imię"),   JsonInt(NUI_HALIGN_LEFT),   JsonInt(NUI_VALIGN_MIDDLE)), fNameW));
    jHdr = JsonArrayInsert(jHdr, NuiWidth(NuiLabel(JsonString("Liga"),   JsonInt(NUI_HALIGN_LEFT),   JsonInt(NUI_VALIGN_MIDDLE)), fLeagW));
    jHdr = JsonArrayInsert(jHdr, NuiWidth(NuiLabel(JsonString("Zwyc."),  JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)), fNumW));
    jHdr = JsonArrayInsert(jHdr, NuiWidth(NuiLabel(JsonString("Poraż."), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)), fNumW));
    jHdr = JsonArrayInsert(jHdr, NuiLabel(JsonString("Infamia"),         JsonInt(NUI_HALIGN_RIGHT),  JsonInt(NUI_VALIGN_MIDDLE)));

    // Row template
    json jRankCell = NuiWidth(NuiLabel(NuiBind(ARENA_BIND_BD_RANK), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)), fRankW);
    json jNameCell = NuiWidth(NuiLabel(NuiBind(ARENA_BIND_BD_NAME), JsonInt(NUI_HALIGN_LEFT),   JsonInt(NUI_VALIGN_MIDDLE)), fNameW);
    json jLgCell   = NuiWidth(NuiLabel(NuiBind(ARENA_BIND_BD_LG),   JsonInt(NUI_HALIGN_LEFT),   JsonInt(NUI_VALIGN_MIDDLE)), fLeagW);
    json jWinCell  = NuiWidth(NuiLabel(NuiBind(ARENA_BIND_BD_WINS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)), fNumW);
    json jLossCell = NuiWidth(NuiLabel(NuiBind(ARENA_BIND_BD_LOSS), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE)), fNumW);
    json jInfCell  = NuiLabel(NuiBind(ARENA_BIND_BD_INF),           JsonInt(NUI_HALIGN_RIGHT),  JsonInt(NUI_VALIGN_MIDDLE));

    json jCellRow = JsonArray();
    jCellRow = JsonArrayInsert(jCellRow, jRankCell);
    jCellRow = JsonArrayInsert(jCellRow, jNameCell);
    jCellRow = JsonArrayInsert(jCellRow, jLgCell);
    jCellRow = JsonArrayInsert(jCellRow, jWinCell);
    jCellRow = JsonArrayInsert(jCellRow, jLossCell);
    jCellRow = JsonArrayInsert(jCellRow, jInfCell);

    json jRowGrp = NuiGroup(NuiRow(jCellRow), TRUE, NUI_SCROLLBARS_NONE);
    json jTmpl   = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jRowGrp, 0.0, TRUE));

    float fListH = GetNuiScaleDimension(oPC, ARENA_H - 90.0);
    json jList   = NuiList(jTmpl, NuiBind(ARENA_BIND_BD_COUNT), fRowH);
    jList        = NuiHeight(jList, fListH);

    json jCols = JsonArray();
    jCols = JsonArrayInsert(jCols, NuiHeight(NuiRow(jHdr), fHdrH));
    jCols = JsonArrayInsert(jCols, jList);

    return NuiCol(jCols);
}

// ----------------------------------------------------------------
// NUI: my-status view
// ----------------------------------------------------------------

json ArenaBuildStatusView(object oPC)
{
    float fLblH = GetNuiScaleDimension(oPC, 26.0);
    float fBtnH = GetNuiScaleDimension(oPC, 32.0);
    float fBigH = GetNuiScaleDimension(oPC, 42.0);
    float fLblW = GetNuiScaleDimension(oPC, 120.0);
    float fBtnW = GetNuiScaleDimension(oPC, 145.0);

    json jRows = JsonArray();

    // --- Stats block ---
    {
        json r = JsonArray();
        r = JsonArrayInsert(r, NuiWidth(NuiLabel(JsonString("Wojownik:"), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE)), fLblW));
        r = JsonArrayInsert(r, NuiLabel(NuiBind(ARENA_BIND_MY_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
        jRows = JsonArrayInsert(jRows, NuiHeight(NuiRow(r), fLblH));
    }
    {
        json r = JsonArray();
        r = JsonArrayInsert(r, NuiWidth(NuiLabel(JsonString("Najwyższa liga:"), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE)), fLblW));
        r = JsonArrayInsert(r, NuiWidth(NuiLabel(NuiBind(ARENA_BIND_MY_LG),   JsonInt(NUI_HALIGN_LEFT),  JsonInt(NUI_VALIGN_MIDDLE)), GetNuiScaleDimension(oPC, 110.0)));
        r = JsonArrayInsert(r, NuiWidth(NuiLabel(JsonString("Infamia:"),        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE)), GetNuiScaleDimension(oPC, 70.0)));
        r = JsonArrayInsert(r, NuiLabel(NuiBind(ARENA_BIND_MY_INF), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
        jRows = JsonArrayInsert(jRows, NuiHeight(NuiRow(r), fLblH));
    }
    {
        json r = JsonArray();
        r = JsonArrayInsert(r, NuiWidth(NuiLabel(JsonString("Zwycięstwa:"), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE)), fLblW));
        r = JsonArrayInsert(r, NuiWidth(NuiLabel(NuiBind(ARENA_BIND_MY_WINS), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)), GetNuiScaleDimension(oPC, 110.0)));
        r = JsonArrayInsert(r, NuiWidth(NuiLabel(JsonString("Porażki:"),      JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE)), GetNuiScaleDimension(oPC, 70.0)));
        r = JsonArrayInsert(r, NuiLabel(NuiBind(ARENA_BIND_MY_LOSS), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
        jRows = JsonArrayInsert(jRows, NuiHeight(NuiRow(r), fLblH));
    }
    {
        json r = JsonArray();
        r = JsonArrayInsert(r, NuiWidth(NuiLabel(JsonString("Tytuł:"), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE)), fLblW));
        r = JsonArrayInsert(r, NuiLabel(NuiBind(ARENA_BIND_MY_TITLE), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
        jRows = JsonArrayInsert(jRows, NuiHeight(NuiRow(r), fLblH));
    }

    jRows = JsonArrayInsert(jRows, CreateEmptyRow(oPC, 14.0));

    // --- League selector ---
    {
        json r = JsonArray();
        r = JsonArrayInsert(r, NuiLabel(JsonString("Wybierz ligę:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
        jRows = JsonArrayInsert(jRows, NuiHeight(NuiRow(r), fLblH));
    }
    {
        json jB1 = NuiEncouraged(NuiId(NuiButton(JsonString("Rekrut (+50)")),   ARENA_BTN_L1), NuiBind(ARENA_BIND_L1_ENC));
        jB1 = NuiWidth(jB1, fBtnW);
        jB1 = NuiHeight(jB1, fBtnH);
        json jB2 = NuiEncouraged(NuiId(NuiButton(JsonString("Wojownik (+120)")), ARENA_BTN_L2), NuiBind(ARENA_BIND_L2_ENC));
        jB2 = NuiWidth(jB2, fBtnW);
        jB2 = NuiHeight(jB2, fBtnH);
        json jB3 = NuiEncouraged(NuiId(NuiButton(JsonString("Mistrz (+250)")),  ARENA_BTN_L3), NuiBind(ARENA_BIND_L3_ENC));
        jB3 = NuiWidth(jB3, fBtnW);
        jB3 = NuiHeight(jB3, fBtnH);

        json r = JsonArray();
        r = JsonArrayInsert(r, jB1);
        r = JsonArrayInsert(r, NuiSpacer());
        r = JsonArrayInsert(r, jB2);
        r = JsonArrayInsert(r, NuiSpacer());
        r = JsonArrayInsert(r, jB3);
        jRows = JsonArrayInsert(jRows, NuiHeight(NuiRow(r), fBtnH));
    }

    jRows = JsonArrayInsert(jRows, CreateEmptyRow(oPC, 18.0));

    // --- Fight button ---
    {
        json jFight = NuiId(NuiButton(NuiBind(ARENA_BIND_FIGHT_LB)), ARENA_BTN_FIGHT);
        jFight = NuiEnabled(jFight, NuiBind(ARENA_BIND_FIGHT_EN));
        jFight = NuiHeight(jFight, fBigH);

        json r = JsonArray();
        r = JsonArrayInsert(r, NuiWidth(NuiSpacer(), GetNuiScaleDimension(oPC, 80.0)));
        r = JsonArrayInsert(r, jFight);
        r = JsonArrayInsert(r, NuiWidth(NuiSpacer(), GetNuiScaleDimension(oPC, 80.0)));
        jRows = JsonArrayInsert(jRows, NuiHeight(NuiRow(r), fBigH));
    }

    jRows = JsonArrayInsert(jRows, NuiSpacer());

    // --- Flavor text ---
    {
        json jFlavor = NuiLabel(NuiBind(ARENA_BIND_FLAVOR), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
        jFlavor = NuiStyleForegroundColor(jFlavor, NuiColor(160, 100, 60));
        json r = JsonArray();
        r = JsonArrayInsert(r, jFlavor);
        jRows = JsonArrayInsert(jRows, NuiHeight(NuiRow(r), fLblH));
    }

    return NuiCol(jRows);
}

// ----------------------------------------------------------------
// NUI: window creation and tab bar
// ----------------------------------------------------------------

json ArenaBuildTabBar(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fBtnW = GetNuiScaleDimension(oPC, 150.0);

    json jTabBoard = NuiId(NuiButton(JsonString("Tabela Chwały")), ARENA_BTN_TAB_BOARD);
    jTabBoard = NuiWidth(jTabBoard, fBtnW);
    jTabBoard = NuiHeight(jTabBoard, fBtnH);

    json jTabMine = NuiId(NuiButton(JsonString("Moje Walki")), ARENA_BTN_TAB_MINE);
    jTabMine = NuiWidth(jTabMine, fBtnW);
    jTabMine = NuiHeight(jTabMine, fBtnH);

    json jClose = NuiId(NuiButton(JsonString("X")), ARENA_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 28.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jTabBoard);
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), GetNuiScaleDimension(oPC, 4.0)));
    jRow = JsonArrayInsert(jRow, jTabMine);
    jRow = JsonArrayInsert(jRow, NuiSpacer());
    jRow = JsonArrayInsert(jRow, jClose);

    return NuiHeight(NuiRow(jRow), fBtnH);
}

void ArenaOpenWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, ARENA_WINDOW);
    if(nToken != 0)
    {
        NuiSetGroupLayout(oPC, nToken, ARENA_GRP_SWAP, ArenaBuildLeaderboardView(oPC));
        SetLocalString(oPC, ARENA_LVAR_TAB, "board");
        ArenaFeedLeaderboard(oPC, nToken);
        ArenaFeedStatus(oPC, nToken);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  -
                 GetNuiScaleDimension(oPC, ARENA_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) -
                 GetNuiScaleDimension(oPC, ARENA_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, ARENA_W), GetNuiScaleDimension(oPC, ARENA_H));

    json jSwapGrp = NuiGroup(ArenaBuildLeaderboardView(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, ARENA_GRP_SWAP);

    json jRootCols = JsonArray();
    jRootCols = JsonArrayInsert(jRootCols, ArenaBuildTabBar(oPC));
    jRootCols = JsonArrayInsert(jRootCols, jSwapGrp);
    json jRoot = NuiCol(jRootCols);

    json jWin = NuiWindow(jRoot,
        JsonBool(FALSE),
        NuiBind(ARENA_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, ARENA_WINDOW, ARENA_EV_SCRIPT);
    NuiSetBind(oPC, nToken, ARENA_WIN_GEOM, jGeom);

    SetLocalString(oPC, ARENA_LVAR_TAB, "board");
    if(GetLocalInt(oPC, ARENA_LVAR_LEAGUE) == 0)
        SetLocalInt(oPC, ARENA_LVAR_LEAGUE, ARENA_LEAGUE_RECRUIT);

    ArenaFeedLeaderboard(oPC, nToken);
    ArenaFeedStatus(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed functions
// ----------------------------------------------------------------

void ArenaFeedLeaderboard(object oPC, int nToken)
{
    json jBoard = ArenaGetLeaderboard(ARENA_BOARD_ROWS);
    int  nRows  = JsonGetLength(jBoard);

    json jRanks  = JsonArray();
    json jNames  = JsonArray();
    json jLeagues= JsonArray();
    json jWins   = JsonArray();
    json jLosses = JsonArray();
    json jInf    = JsonArray();

    int i;
    for(i = 0; i < nRows; i++)
    {
        json jR  = JsonArrayGet(jBoard, i);
        jRanks   = JsonArrayInsert(jRanks,   JsonString(IntToString(JsonGetInt(JsonObjectGet(jR, "rank")))));
        jNames   = JsonArrayInsert(jNames,   JsonObjectGet(jR, "char_name"));
        jLeagues = JsonArrayInsert(jLeagues, JsonString(ArenaLeagueName(JsonGetInt(JsonObjectGet(jR, "best_league")))));
        jWins    = JsonArrayInsert(jWins,    JsonString(IntToString(JsonGetInt(JsonObjectGet(jR, "total_wins")))));
        jLosses  = JsonArrayInsert(jLosses,  JsonString(IntToString(JsonGetInt(JsonObjectGet(jR, "total_losses")))));
        jInf     = JsonArrayInsert(jInf,     JsonString(IntToString(JsonGetInt(JsonObjectGet(jR, "infamy")))));
    }

    // Pad empty rows so the list renders at a fixed height.
    for(i = nRows; i < ARENA_BOARD_ROWS; i++)
    {
        jRanks   = JsonArrayInsert(jRanks,   JsonString(""));
        jNames   = JsonArrayInsert(jNames,   JsonString(""));
        jLeagues = JsonArrayInsert(jLeagues, JsonString(""));
        jWins    = JsonArrayInsert(jWins,    JsonString(""));
        jLosses  = JsonArrayInsert(jLosses,  JsonString(""));
        jInf     = JsonArrayInsert(jInf,     JsonString(""));
    }

    NuiSetBind(oPC, nToken, ARENA_BIND_BD_COUNT, JsonInt(ARENA_BOARD_ROWS));
    NuiSetBind(oPC, nToken, ARENA_BIND_BD_RANK,  jRanks);
    NuiSetBind(oPC, nToken, ARENA_BIND_BD_NAME,  jNames);
    NuiSetBind(oPC, nToken, ARENA_BIND_BD_LG,    jLeagues);
    NuiSetBind(oPC, nToken, ARENA_BIND_BD_WINS,  jWins);
    NuiSetBind(oPC, nToken, ARENA_BIND_BD_LOSS,  jLosses);
    NuiSetBind(oPC, nToken, ARENA_BIND_BD_INF,   jInf);
}

void ArenaFeedStatus(object oPC, int nToken)
{
    string sUuid = GetObjectUUID(oPC);
    json   jF    = ArenaGetFighter(sUuid);
    if(JsonGetType(jF) == JSON_TYPE_NULL)
    {
        ArenaRegisterFighter(oPC);
        jF = ArenaGetFighter(sUuid);
        if(JsonGetType(jF) == JSON_TYPE_NULL) return;
    }

    int    nWins   = JsonGetInt(JsonObjectGet(jF, "total_wins"));
    int    nLosses = JsonGetInt(JsonObjectGet(jF, "total_losses"));
    int    nLeague = JsonGetInt(JsonObjectGet(jF, "best_league"));
    int    nInfamy = JsonGetInt(JsonObjectGet(jF, "infamy"));
    string sTitle  = ArenaTitleFromWins(nWins);

    NuiSetBind(oPC, nToken, ARENA_BIND_MY_NAME,  JsonString(GetName(oPC)));
    NuiSetBind(oPC, nToken, ARENA_BIND_MY_LG,    JsonString(ArenaLeagueName(nLeague)));
    NuiSetBind(oPC, nToken, ARENA_BIND_MY_WINS,  JsonString(IntToString(nWins)));
    NuiSetBind(oPC, nToken, ARENA_BIND_MY_LOSS,  JsonString(IntToString(nLosses)));
    NuiSetBind(oPC, nToken, ARENA_BIND_MY_INF,   JsonString(IntToString(nInfamy)));
    NuiSetBind(oPC, nToken, ARENA_BIND_MY_TITLE, JsonString(sTitle));

    int    nInFight = GetLocalInt(oPC, ARENA_LVAR_IN_FIGHT);
    NuiSetBind(oPC, nToken, ARENA_BIND_FIGHT_EN, JsonBool(!nInFight));
    NuiSetBind(oPC, nToken, ARENA_BIND_FIGHT_LB, JsonString(nInFight ? "Walka trwa..." : "— WALCZ! —"));

    string sFlavor;
    if(nInFight)
        sFlavor = "Walka trwa. Zabij lub zgiń.";
    else if(nWins >= ARENA_WINS_LEGEND)
        sFlavor = "Legenda przemawia ciszą. Wróg wie, że przegra.";
    else if(nWins >= ARENA_WINS_VETERAN)
        sFlavor = "Piasek pamięta każdą kroplę. Ty też pamiętasz.";
    else if(nWins > 0)
        sFlavor = "Krew woła z areny. Czyż twoje żyły nie odpowiadają?";
    else
        sFlavor = "Nikt cię tu nie zna. Zmień to.";
    NuiSetBind(oPC, nToken, ARENA_BIND_FLAVOR, JsonString(sFlavor));

    int nSel = GetLocalInt(oPC, ARENA_LVAR_LEAGUE);
    if(nSel == 0) nSel = ARENA_LEAGUE_RECRUIT;
    NuiSetBind(oPC, nToken, ARENA_BIND_L1_ENC, JsonBool(nSel == ARENA_LEAGUE_RECRUIT));
    NuiSetBind(oPC, nToken, ARENA_BIND_L2_ENC, JsonBool(nSel == ARENA_LEAGUE_WARRIOR));
    NuiSetBind(oPC, nToken, ARENA_BIND_L3_ENC, JsonBool(nSel == ARENA_LEAGUE_CHAMPION));
}

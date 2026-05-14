#include "sql_btrk"
#include "nw_inc_nui"

void BtrkOpen(object oPC);
void BtrkFeedDisplay(object oPC, int nToken);
void BtrkAddLog(object oPC, string sEntry);
void BtrkSearchTrails(object oPC, int nToken);
void BtrkRefreshTrackerUI(object oPC);

// ----------------------------------------------------------------
// Compass / text helpers
// ----------------------------------------------------------------

// VectorToAngle returns 0=East, 90=North (NWN convention).
string BtrkCompassLabel(float fAngle)
{
    if(fAngle >= 337.5 || fAngle < 22.5)  return "WSCHÓD";
    if(fAngle < 67.5)                      return "PÓŁNOCNY-WSCHÓD";
    if(fAngle < 112.5)                     return "PÓŁNOC";
    if(fAngle < 157.5)                     return "PÓŁNOCNY-ZACHÓD";
    if(fAngle < 202.5)                     return "ZACHÓD";
    if(fAngle < 247.5)                     return "POŁUDNIOWY-ZACHÓD";
    if(fAngle < 292.5)                     return "POŁUDNIE";
    return "POŁUDNIOWY-WSCHÓD";
}

string BtrkDistanceLabel(float fDist)
{
    if(fDist < 4.0)  return "bardzo blisko (poniżej 4 m)";
    if(fDist < 12.0) return "blisko (ok. " + IntToString(FloatToInt(fDist)) + " m)";
    if(fDist < 28.0) return "w pobliżu (ok. " + IntToString(FloatToInt(fDist)) + " m)";
    return "daleko (ok. " + IntToString(FloatToInt(fDist)) + " m)";
}

string BtrkFreshnessLabel(int nAgeSeconds)
{
    if(nAgeSeconds < BTRK_DECAY_FRESH) return "Świeże";
    if(nAgeSeconds < BTRK_DECAY_STALE) return "Stare";
    return "Lodowate";
}

int BtrkFreshnessDC(int nAgeSeconds)
{
    if(nAgeSeconds < BTRK_DECAY_FRESH) return BTRK_DC_FRESH;
    if(nAgeSeconds < BTRK_DECAY_STALE) return BTRK_DC_STALE;
    return BTRK_DC_COLD;
}

string BtrkFreshnessColor(int nAgeSeconds)
{
    // Colour prefix tags for log entries only — not used in NUI color binds
    if(nAgeSeconds < BTRK_DECAY_FRESH) return "<c=red>";
    if(nAgeSeconds < BTRK_DECAY_STALE) return "<c=orange>";
    return "<c=gray>";
}

// ----------------------------------------------------------------
// NUI layout builder
// ----------------------------------------------------------------

json BtrkBuildWindow(object oPC)
{
    float fW    = GetNuiScaleDimension(oPC, 310.0);
    float fH    = GetNuiScaleDimension(oPC, 460.0);
    float fBtnH = GetNuiScaleDimension(oPC, 30.0);
    float fRowH = GetNuiScaleDimension(oPC, 22.0);
    float fLblH = GetNuiScaleDimension(oPC, 20.0);

    // ---- Header row ----
    json jTitle = NuiLabel(JsonString("Tropiciel Krwi"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiHeight(jTitle, fBtnH);

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, BTRK_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, fBtnH);
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jHdrElems = JsonArray();
    jHdrElems = JsonArrayInsert(jHdrElems, jTitle);
    jHdrElems = JsonArrayInsert(jHdrElems, jCloseBtn);
    json jHeader = NuiRow(jHdrElems);

    // ---- Status row ----
    json jStatusLbl = NuiLabel(NuiBind(BTRK_BIND_STATUS_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jStatusLbl = NuiStyleForegroundColor(jStatusLbl, NuiBind(BTRK_BIND_STATUS_COL));
    jStatusLbl = NuiHeight(jStatusLbl, fBtnH);

    json jActBtn = NuiButton(NuiBind(BTRK_BIND_ACT_LBL));
    jActBtn = NuiId(jActBtn, BTRK_BTN_ACTIVATE);
    jActBtn = NuiWidth(jActBtn, GetNuiScaleDimension(oPC, 120.0));
    jActBtn = NuiHeight(jActBtn, fBtnH);

    json jStatusElems = JsonArray();
    jStatusElems = JsonArrayInsert(jStatusElems, jStatusLbl);
    jStatusElems = JsonArrayInsert(jStatusElems, jActBtn);
    json jStatusRow = NuiRow(jStatusElems);

    // ---- Divider ----
    json jDiv1 = NuiLabel(JsonString("────────── Ślad ──────────────────"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDiv1 = NuiHeight(jDiv1, fLblH);

    // ---- Trail direction ----
    json jDirLbl = NuiLabel(NuiBind(BTRK_BIND_DIR_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDirLbl = NuiHeight(jDirLbl, fRowH);

    // ---- Freshness ----
    json jFreshLbl = NuiLabel(NuiBind(BTRK_BIND_FRESH_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jFreshLbl = NuiHeight(jFreshLbl, fRowH);

    // ---- Distance ----
    json jDistLbl = NuiLabel(NuiBind(BTRK_BIND_DIST_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDistLbl = NuiHeight(jDistLbl, fRowH);

    // ---- Source ----
    json jSrcLbl = NuiLabel(NuiBind(BTRK_BIND_SRC_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jSrcLbl = NuiHeight(jSrcLbl, fRowH);

    // ---- Search button ----
    json jSearchBtn = NuiButton(JsonString("Szukaj Śladów"));
    jSearchBtn = NuiId(jSearchBtn, BTRK_BTN_SEARCH);
    jSearchBtn = NuiEnabled(jSearchBtn, NuiBind(BTRK_BIND_SEARCH_ENA));
    jSearchBtn = NuiHeight(jSearchBtn, fBtnH);

    // ---- Log divider ----
    json jDiv2 = NuiLabel(JsonString("────────── Dziennik ──────────────"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDiv2 = NuiHeight(jDiv2, fLblH);

    // ---- Log list ----
    json jLogLbl = NuiLabel(NuiBind(BTRK_BIND_LOG_ROW),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jLogCell = NuiListTemplateCell(jLogLbl, 0.0, TRUE);
    json jLogTmpl = JsonArrayInsert(JsonArray(), jLogCell);
    json jLogList = NuiList(jLogTmpl, NuiBind(BTRK_BIND_LOG_COUNT), fRowH);
    jLogList = NuiHeight(jLogList, fRowH * BTRK_LOG_MAX + 4.0);

    // ---- Clear log button ----
    json jClearBtn = NuiButton(JsonString("Wyczyść Dziennik"));
    jClearBtn = NuiId(jClearBtn, BTRK_BTN_CLEAR_LOG);
    jClearBtn = NuiHeight(jClearBtn, fBtnH);

    // ---- Assemble root column ----
    json jRootElems = JsonArray();
    jRootElems = JsonArrayInsert(jRootElems, jHeader);
    jRootElems = JsonArrayInsert(jRootElems, jStatusRow);
    jRootElems = JsonArrayInsert(jRootElems, jDiv1);
    jRootElems = JsonArrayInsert(jRootElems, jDirLbl);
    jRootElems = JsonArrayInsert(jRootElems, jFreshLbl);
    jRootElems = JsonArrayInsert(jRootElems, jDistLbl);
    jRootElems = JsonArrayInsert(jRootElems, jSrcLbl);
    jRootElems = JsonArrayInsert(jRootElems, jSearchBtn);
    jRootElems = JsonArrayInsert(jRootElems, jDiv2);
    jRootElems = JsonArrayInsert(jRootElems, jLogList);
    jRootElems = JsonArrayInsert(jRootElems, jClearBtn);
    json jRoot = NuiCol(jRootElems);

    json jWin = NuiWindow(jRoot,
        JsonBool(FALSE),
        NuiBind(BTRK_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    return jWin;
}

// ----------------------------------------------------------------
// Window open / feed
// ----------------------------------------------------------------

void BtrkOpen(object oPC)
{
    int nToken = NuiFindWindow(oPC, BTRK_WINDOW);
    if(nToken != 0)
    {
        BtrkFeedDisplay(oPC, nToken);
        return;
    }

    float fGuiW = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH));
    float fGuiH = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT));
    float fWinW = GetNuiScaleDimension(oPC, 310.0);
    float fWinH = GetNuiScaleDimension(oPC, 460.0);
    json jGeom  = NuiRect(
        (fGuiW - fWinW) / 2.0,
        (fGuiH - fWinH) / 2.0,
        fWinW, fWinH);

    json jWin = BtrkBuildWindow(oPC);
    nToken = NuiCreate(oPC, jWin, BTRK_WINDOW, BTRK_EV_SCRIPT);
    NuiSetBind(oPC, nToken, BTRK_WIN_GEOM, jGeom);

    BtrkFeedDisplay(oPC, nToken);
}

// Pushes all data-binds for the current state of oPC.
void BtrkFeedDisplay(object oPC, int nToken)
{
    int bActive = GetLocalInt(oPC, BTRK_LVAR_ACTIVE);

    // Status + activate button
    if(bActive)
    {
        NuiSetBind(oPC, nToken, BTRK_BIND_STATUS_LBL, JsonString("Tryb: AKTYWNY"));
        NuiSetBind(oPC, nToken, BTRK_BIND_STATUS_COL, NuiColor(180, 60, 60));
        NuiSetBind(oPC, nToken, BTRK_BIND_ACT_LBL,    JsonString("Dezaktywuj"));
    }
    else
    {
        NuiSetBind(oPC, nToken, BTRK_BIND_STATUS_LBL, JsonString("Tryb: NIEAKTYWNY"));
        NuiSetBind(oPC, nToken, BTRK_BIND_STATUS_COL, NuiColor(120, 120, 120));
        NuiSetBind(oPC, nToken, BTRK_BIND_ACT_LBL,    JsonString("Aktywuj"));
    }

    NuiSetBind(oPC, nToken, BTRK_BIND_SEARCH_ENA, JsonBool(bActive));

    // Trail panel — refresh from stored tracked id if active
    int nTrackedId = GetLocalInt(oPC, BTRK_LVAR_TRACKED_ID);
    if(bActive && nTrackedId > 0)
    {
        json jTrail = BtrkGetTrailById(nTrackedId);
        if(JsonGetType(jTrail) != JSON_TYPE_NULL)
        {
            float fTX  = JsonGetFloat(JsonObjectGet(jTrail, "pos_x"));
            float fTY  = JsonGetFloat(JsonObjectGet(jTrail, "pos_y"));
            vector vPC = GetPosition(oPC);
            float fDX  = fTX - vPC.x;
            float fDY  = fTY - vPC.y;
            float fDist = sqrt(fDX * fDX + fDY * fDY);
            float fAngle = VectorToAngle(Vector(fDX, fDY, 0.0));

            int nAge      = BtrkGetAgeSeconds(JsonGetInt(JsonObjectGet(jTrail, "created_at")));
            string sFresh = BtrkFreshnessLabel(nAge);
            string sName  = JsonGetString(JsonObjectGet(jTrail, "source_name"));
            int nAmt      = JsonGetInt(JsonObjectGet(jTrail, "blood_amt"));

            NuiSetBind(oPC, nToken, BTRK_BIND_DIR_LBL,
                JsonString("Kierunek: " + BtrkCompassLabel(fAngle)));
            NuiSetBind(oPC, nToken, BTRK_BIND_FRESH_LBL,
                JsonString("Świeżość: " + sFresh));
            NuiSetBind(oPC, nToken, BTRK_BIND_DIST_LBL,
                JsonString("Odległość: " + BtrkDistanceLabel(fDist)));
            string sBleed = nAmt >= 30 ? " (ciężka rana)" : "";
            NuiSetBind(oPC, nToken, BTRK_BIND_SRC_LBL,
                JsonString("Ofiara: " + sName + sBleed));
        }
        else
        {
            // Trail expired
            DeleteLocalInt(oPC, BTRK_LVAR_TRACKED_ID);
            NuiSetBind(oPC, nToken, BTRK_BIND_DIR_LBL,   JsonString("Ślad wystygł..."));
            NuiSetBind(oPC, nToken, BTRK_BIND_FRESH_LBL, JsonString(""));
            NuiSetBind(oPC, nToken, BTRK_BIND_DIST_LBL,  JsonString(""));
            NuiSetBind(oPC, nToken, BTRK_BIND_SRC_LBL,   JsonString(""));
        }
    }
    else if(!bActive)
    {
        NuiSetBind(oPC, nToken, BTRK_BIND_DIR_LBL,   JsonString("Aktywuj tropienie, by szukać śladów."));
        NuiSetBind(oPC, nToken, BTRK_BIND_FRESH_LBL, JsonString(""));
        NuiSetBind(oPC, nToken, BTRK_BIND_DIST_LBL,  JsonString(""));
        NuiSetBind(oPC, nToken, BTRK_BIND_SRC_LBL,   JsonString(""));
    }
    else
    {
        NuiSetBind(oPC, nToken, BTRK_BIND_DIR_LBL,   JsonString("Brak tropionego śladu. Użyj Szukaj."));
        NuiSetBind(oPC, nToken, BTRK_BIND_FRESH_LBL, JsonString(""));
        NuiSetBind(oPC, nToken, BTRK_BIND_DIST_LBL,  JsonString(""));
        NuiSetBind(oPC, nToken, BTRK_BIND_SRC_LBL,   JsonString(""));
    }

    // Log
    json jLog  = GetLocalJson(oPC, BTRK_LVAR_LOG);
    if(JsonGetType(jLog) != JSON_TYPE_ARRAY) jLog = JsonArray();
    NuiSetBind(oPC, nToken, BTRK_BIND_LOG_ROW,   jLog);
    NuiSetBind(oPC, nToken, BTRK_BIND_LOG_COUNT, JsonInt(JsonGetLength(jLog)));
}

// ----------------------------------------------------------------
// Log management
// ----------------------------------------------------------------

void BtrkAddLog(object oPC, string sEntry)
{
    json jLog = GetLocalJson(oPC, BTRK_LVAR_LOG);
    if(JsonGetType(jLog) != JSON_TYPE_ARRAY) jLog = JsonArray();

    // Prepend newest entry so list shows most recent at top
    json jNew = JsonArray();
    jNew = JsonArrayInsert(jNew, JsonString(sEntry));
    int i;
    int nCount = JsonGetLength(jLog);
    for(i = 0; i < nCount && i < BTRK_LOG_MAX - 1; i++)
        jNew = JsonArrayInsert(jNew, JsonArrayGet(jLog, i));

    SetLocalJson(oPC, BTRK_LVAR_LOG, jNew);
}

// ----------------------------------------------------------------
// Trail search (skill check + nearest trail lookup)
// ----------------------------------------------------------------

void BtrkSearchTrails(object oPC, int nToken)
{
    string sArea  = GetTag(GetArea(oPC));
    vector vPC    = GetPosition(oPC);
    string sUUID  = GetObjectUUID(oPC);

    json jTrail = BtrkFindNearest(sArea, vPC.x, vPC.y, sUUID);

    if(JsonGetType(jTrail) == JSON_TYPE_NULL)
    {
        SendMessageToPC(oPC, "[Tropiciel] Nie znaleziono żadnych śladów w pobliżu.");
        BtrkAddLog(oPC, "Brak śladów w pobliżu.");
        BtrkFeedDisplay(oPC, nToken);
        return;
    }

    int nCreatedAt = JsonGetInt(JsonObjectGet(jTrail, "created_at"));
    int nAge       = BtrkGetAgeSeconds(nCreatedAt);
    int nDC        = BtrkFreshnessDC(nAge);
    int nSkill     = GetSkillRank(SKILL_SEARCH, oPC) + d20();

    if(nSkill < nDC)
    {
        // Failed — vague or wrong direction as flavor
        string sWrong = "Ślady zacierają się... nie możesz ich odczytać. (DC " +
            IntToString(nDC) + ", rzut: " + IntToString(nSkill) + ")";
        SendMessageToPC(oPC, "[Tropiciel] " + sWrong);
        BtrkAddLog(oPC, "Rzut nieudany — DC " + IntToString(nDC) + ".");
        BtrkFeedDisplay(oPC, nToken);
        return;
    }

    // Success
    int nId        = JsonGetInt(JsonObjectGet(jTrail, "id"));
    string sName   = JsonGetString(JsonObjectGet(jTrail, "source_name"));
    float fDist    = JsonGetFloat(JsonObjectGet(jTrail, "dist"));
    float fTX      = JsonGetFloat(JsonObjectGet(jTrail, "pos_x"));
    float fTY      = JsonGetFloat(JsonObjectGet(jTrail, "pos_y"));
    float fAngle   = VectorToAngle(Vector(fTX - vPC.x, fTY - vPC.y, 0.0));
    string sFresh  = BtrkFreshnessLabel(nAge);
    int nBlood     = JsonGetInt(JsonObjectGet(jTrail, "blood_amt"));

    SetLocalInt(oPC, BTRK_LVAR_TRACKED_ID, nId);
    BtrkMarkDiscovered(sUUID, nId);
    GiveXPToCreature(oPC, BTRK_XP_PER_TRAIL);

    string sLog = sFresh + " ślad — " + BtrkCompassLabel(fAngle)
        + " (" + IntToString(FloatToInt(fDist)) + "m)"
        + (nBlood >= 30 ? " [ciężki]" : "");
    BtrkAddLog(oPC, sLog);

    string sMsg = "[Tropiciel] Odnalazłeś ślad " + sName + "! "
        + sFresh + ", kierunek: " + BtrkCompassLabel(fAngle)
        + ", " + BtrkDistanceLabel(fDist) + ". (DC " + IntToString(nDC)
        + ", rzut: " + IntToString(nSkill) + ")";
    SendMessageToPC(oPC, sMsg);

    BtrkFeedDisplay(oPC, nToken);
}

// ----------------------------------------------------------------
// Heartbeat refresh — called from sys_on_hb for each active tracker
// ----------------------------------------------------------------

void BtrkRefreshTrackerUI(object oPC)
{
    int nToken = NuiFindWindow(oPC, BTRK_WINDOW);
    if(nToken == 0) return;
    BtrkFeedDisplay(oPC, nToken);
}

// ----------------------------------------------------------------
// Trail drop — called from sys_on_dmg (NPCs) or sys_on_hb (PCs)
// ----------------------------------------------------------------

void BtrkClearBleedLock(object oCreature)
{
    DeleteLocalInt(oCreature, "BTRK_BLEED_LOCK");
}

void BtrkDropTrail(object oCreature, int nDamage)
{
    if(nDamage < BTRK_MIN_BLEED_DMG) return;

    // Per-creature cooldown: one trail entry per BTRK_BLEED_COOLDOWN seconds max.
    // DelayCommand resets the lock after the cooldown — no tick arithmetic needed.
    if(GetLocalInt(oCreature, "BTRK_BLEED_LOCK")) return;
    SetLocalInt(oCreature, "BTRK_BLEED_LOCK", 1);
    DelayCommand(IntToFloat(BTRK_BLEED_COOLDOWN), BtrkClearBleedLock(oCreature));

    object oArea = GetArea(oCreature);
    if(!GetIsObjectValid(oArea)) return;

    string sArea = GetTag(oArea);
    vector vPos  = GetPosition(oCreature);
    string sUUID = GetIsPC(oCreature) ? GetObjectUUID(oCreature) : "";
    string sName = GetName(oCreature);

    BtrkInsertTrail(sArea, vPos.x, vPos.y, vPos.z, sUUID, sName, nDamage);
}

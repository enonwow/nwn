// sql_plg_events.nss - telemetria event-based dla Plague v2
//
// Tabela plg_events - logujemy wszystkie kluczowe tranzycje i decyzje.
// Z eventow odbudowujemy dowolna metryke. Bez TTL, bez anonimizacji.

#include "sql_plg"

// Event types
const string PLG_EVT_CONTRACT          = "contract";
const string PLG_EVT_PHASE_ADVANCE     = "phase_advance";
const string PLG_EVT_PHASE_RETREAT     = "phase_retreat";
const string PLG_EVT_BODY_FIGHT        = "body_fight";
const string PLG_EVT_LENS_USED         = "lens_used";
const string PLG_EVT_CURE_ATTEMPT      = "cure_attempt";
const string PLG_EVT_CURE_SUCCESS      = "cure_success";
const string PLG_EVT_APTECZKA_ATTEMPT  = "apteczka_attempt";
const string PLG_EVT_CONTAGION_SPREAD  = "contagion_spread";
const string PLG_EVT_CONTAGION_RESIST  = "contagion_resisted";
const string PLG_EVT_DEATH             = "death_from_disease";
const string PLG_EVT_LOGOUT_DISEASED   = "logout_diseased";
const string PLG_EVT_LOGIN_DISEASED    = "login_diseased";
const string PLG_EVT_OFFLINE_PROG      = "offline_progression";
const string PLG_EVT_DM_ACTION         = "dm_action";

// Save result strings (dla event log)
const string PLG_SAVERES_FAIL         = "fail";
const string PLG_SAVERES_SUCCESS      = "success";
const string PLG_SAVERES_CRIT_SUCCESS = "crit_success";
const string PLG_SAVERES_CRIT_FAIL    = "crit_fail";

// First login tracking - do is_new_player flag
const string PLG_LVAR_FIRST_LOGIN_PRE = "first_login_";
const int PLG_NEW_PLAYER_HOURS = 10;

// ============================================================
// Schema
// ============================================================

void PlgCreateEventsTable()
{
    string sSql = "CREATE TABLE IF NOT EXISTS plg_events ("
        + "event_id INTEGER PRIMARY KEY AUTOINCREMENT,"
        + "timestamp INTEGER NOT NULL,"
        + "uuid TEXT NOT NULL,"
        + "char_name TEXT,"
        + "is_new_player INTEGER DEFAULT 0,"
        + "event_type TEXT NOT NULL,"
        + "disease_id INTEGER DEFAULT -1,"
        + "episode_id TEXT,"
        + "phase_from INTEGER DEFAULT -1,"
        + "phase_to INTEGER DEFAULT -1,"
        + "save_roll INTEGER DEFAULT 0,"
        + "save_dc INTEGER DEFAULT 0,"
        + "save_result TEXT,"
        + "item_tag TEXT,"
        + "item_rank INTEGER DEFAULT 0,"
        + "area_resref TEXT,"
        + "extra_data TEXT)";
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN, sSql);
    SqlStep(q);

    // Indeksy
    sqlquery i1 = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "CREATE INDEX IF NOT EXISTS idx_plg_events_uuid ON plg_events(uuid)");
    SqlStep(i1);
    sqlquery i2 = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "CREATE INDEX IF NOT EXISTS idx_plg_events_episode ON plg_events(episode_id)");
    SqlStep(i2);
    sqlquery i3 = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "CREATE INDEX IF NOT EXISTS idx_plg_events_disease ON plg_events(disease_id)");
    SqlStep(i3);
    sqlquery i4 = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "CREATE INDEX IF NOT EXISTS idx_plg_events_type ON plg_events(event_type)");
    SqlStep(i4);
    sqlquery i5 = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "CREATE INDEX IF NOT EXISTS idx_plg_events_ts ON plg_events(timestamp)");
    SqlStep(i5);
}

// ============================================================
// New player cohort tracking
// ============================================================

// Sprawdz czy gracz ma <10h gameplay (cohort flag).
int PlgIsNewPlayer(object oPC)
{
    string sKey = PLG_LVAR_FIRST_LOGIN_PRE + GetObjectUUID(oPC);
    int nFirstLogin = GetCampaignInt(PLG_CAMPAIGN, sKey);
    if(nFirstLogin == 0) return TRUE; // pierwszy raz
    int nHoursSince = (PlgUnixNow() - nFirstLogin) / 3600;
    return nHoursSince < PLG_NEW_PLAYER_HOURS;
}

// Inicjalizuj first_login dla nowego gracza (wywoluj raz w OnClientEnter).
void PlgInitFirstLogin(object oPC)
{
    string sKey = PLG_LVAR_FIRST_LOGIN_PRE + GetObjectUUID(oPC);
    int nFirstLogin = GetCampaignInt(PLG_CAMPAIGN, sKey);
    if(nFirstLogin == 0)
    {
        SetCampaignInt(PLG_CAMPAIGN, sKey, PlgUnixNow());
    }
}

// ============================================================
// Generic event logger - low level
// ============================================================

void PlgLogEventFull(object oPC, string sEventType, int nDiseaseId,
    string sEpisodeId, int nPhaseFrom, int nPhaseTo,
    int nSaveRoll, int nSaveDC, string sSaveResult,
    string sItemTag, int nItemRank, string sExtra)
{
    string sSql = "INSERT INTO plg_events ("
        + "timestamp, uuid, char_name, is_new_player, event_type, "
        + "disease_id, episode_id, phase_from, phase_to, "
        + "save_roll, save_dc, save_result, item_tag, item_rank, "
        + "area_resref, extra_data) VALUES ("
        + "@ts, @uuid, @name, @new, @evt, "
        + "@did, @eid, @pf, @pt, "
        + "@roll, @dc, @sres, @itag, @irank, "
        + "@area, @extra)";
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN, sSql);
    SqlBindInt   (q, "@ts",    PlgUnixNow());
    SqlBindString(q, "@uuid",  GetObjectUUID(oPC));
    SqlBindString(q, "@name",  GetName(oPC));
    SqlBindInt   (q, "@new",   PlgIsNewPlayer(oPC) ? 1 : 0);
    SqlBindString(q, "@evt",   sEventType);
    SqlBindInt   (q, "@did",   nDiseaseId);
    SqlBindString(q, "@eid",   sEpisodeId);
    SqlBindInt   (q, "@pf",    nPhaseFrom);
    SqlBindInt   (q, "@pt",    nPhaseTo);
    SqlBindInt   (q, "@roll",  nSaveRoll);
    SqlBindInt   (q, "@dc",    nSaveDC);
    SqlBindString(q, "@sres",  sSaveResult);
    SqlBindString(q, "@itag",  sItemTag);
    SqlBindInt   (q, "@irank", nItemRank);
    SqlBindString(q, "@area",  GetResRef(GetArea(oPC)));
    SqlBindString(q, "@extra", sExtra);
    SqlStep(q);
}

// ============================================================
// Convenience helpers per event type
// ============================================================

void PlgLogContract(object oPC, int nDiseaseId, string sEpisodeId)
{
    PlgLogEventFull(oPC, PLG_EVT_CONTRACT, nDiseaseId, sEpisodeId,
        -1, -1, 0, 0, "", "", 0, "");
}

void PlgLogPhaseChange(object oPC, string sEventType, int nDiseaseId,
    string sEpisodeId, int nPhaseFrom, int nPhaseTo,
    int nRoll, int nDC, string sResult)
{
    PlgLogEventFull(oPC, sEventType, nDiseaseId, sEpisodeId,
        nPhaseFrom, nPhaseTo, nRoll, nDC, sResult, "", 0, "");
}

void PlgLogBodyFight(object oPC, int nDiseaseId, string sEpisodeId,
    int nPhase, int nRoll, int nDC, string sResult)
{
    PlgLogEventFull(oPC, PLG_EVT_BODY_FIGHT, nDiseaseId, sEpisodeId,
        nPhase, nPhase, nRoll, nDC, sResult, "", 0, "");
}

void PlgLogLensUsed(object oPC, int nDiseaseId, string sEpisodeId)
{
    PlgLogEventFull(oPC, PLG_EVT_LENS_USED, nDiseaseId, sEpisodeId,
        -1, -1, 0, 0, "", "plg_lens", 0, "");
}

void PlgLogCureAttempt(object oPC, int nDiseaseId, string sEpisodeId,
    string sItemTag, int nItemRank, string sResult)
{
    PlgLogEventFull(oPC, PLG_EVT_CURE_ATTEMPT, nDiseaseId, sEpisodeId,
        -1, -1, 0, 0, sResult, sItemTag, nItemRank, "");
}

void PlgLogCureSuccess(object oPC, int nDiseaseId, string sEpisodeId, string sSource)
{
    string sExtra = "{\"source\":\"" + sSource + "\"}";
    PlgLogEventFull(oPC, PLG_EVT_CURE_SUCCESS, nDiseaseId, sEpisodeId,
        -1, -1, 0, 0, "", "", 0, sExtra);
}

void PlgLogApteczka(object oPC, int nDiseaseId, string sEpisodeId,
    int nPhase, int nRoll, int nDC, string sResult)
{
    PlgLogEventFull(oPC, PLG_EVT_APTECZKA_ATTEMPT, nDiseaseId, sEpisodeId,
        nPhase, nPhase, nRoll, nDC, sResult, "plg_apteczka", 0, "");
}

void PlgLogContagion(object oCarrier, object oTarget, int nDiseaseId,
    string sCarrierEpisodeId, int nRoll, int nDC, int bInfected)
{
    string sExtra = "{\"target_uuid\":\"" + GetObjectUUID(oTarget)
        + "\",\"target_name\":\"" + GetName(oTarget) + "\"}";
    string sEvtType = bInfected ? PLG_EVT_CONTAGION_SPREAD : PLG_EVT_CONTAGION_RESIST;
    PlgLogEventFull(oCarrier, sEvtType, nDiseaseId, sCarrierEpisodeId,
        -1, -1, nRoll, nDC, "", "", 0, sExtra);
}

void PlgLogDeath(object oPC, int nDiseaseId, string sEpisodeId)
{
    PlgLogEventFull(oPC, PLG_EVT_DEATH, nDiseaseId, sEpisodeId,
        -1, -1, 0, 0, "", "", 0, "");
}

void PlgLogLogout(object oPC, int nDiseaseId, string sEpisodeId, int nPhase, int bInSafeArea)
{
    string sExtra = "{\"in_safe_area\":" + IntToString(bInSafeArea) + "}";
    PlgLogEventFull(oPC, PLG_EVT_LOGOUT_DISEASED, nDiseaseId, sEpisodeId,
        -1, nPhase, 0, 0, "", "", 0, sExtra);
}

void PlgLogLogin(object oPC, int nDiseaseId, string sEpisodeId, int nPhase)
{
    PlgLogEventFull(oPC, PLG_EVT_LOGIN_DISEASED, nDiseaseId, sEpisodeId,
        -1, nPhase, 0, 0, "", "", 0, "");
}

void PlgLogOfflineProg(object oPC, int nDiseaseId, string sEpisodeId,
    int nPhaseFrom, int nPhaseTo, int nPhasesAdvanced, int nTimeOfflineSec)
{
    string sExtra = "{\"phases_advanced\":" + IntToString(nPhasesAdvanced)
        + ",\"time_offline_sec\":" + IntToString(nTimeOfflineSec) + "}";
    PlgLogEventFull(oPC, PLG_EVT_OFFLINE_PROG, nDiseaseId, sEpisodeId,
        nPhaseFrom, nPhaseTo, 0, 0, "", "", 0, sExtra);
}

void PlgLogDmAction(object oDm, object oTarget, int nDiseaseId, string sAction)
{
    string sExtra = "{\"target_uuid\":\"" + GetObjectUUID(oTarget)
        + "\",\"target_name\":\"" + GetName(oTarget)
        + "\",\"dm_name\":\"" + GetName(oDm)
        + "\",\"action\":\"" + sAction + "\"}";
    PlgLogEventFull(oTarget, PLG_EVT_DM_ACTION, nDiseaseId, "",
        -1, -1, 0, 0, "", "", 0, sExtra);
}

// ============================================================
// Save result int -> string
// ============================================================

string PlgSaveResultToString(int nResult)
{
    switch(nResult)
    {
        case 0: return PLG_SAVERES_FAIL;
        case 1: return PLG_SAVERES_SUCCESS;
        case 2: return PLG_SAVERES_CRIT_SUCCESS;
        case 3: return PLG_SAVERES_CRIT_FAIL;
    }
    return "";
}

// ============================================================
// Statistics queries (for DM Stats panel)
// ============================================================

// Currently infected (rows in plg_diseases).
int PlgQryActiveDiseases()
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "SELECT COUNT(*) FROM plg_diseases");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Cured in last 24h.
int PlgQryCuredLast24h()
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "SELECT COUNT(*) FROM plg_events "
        + "WHERE event_type = 'cure_success' "
        + "AND timestamp >= strftime('%s','now') - 86400");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Deaths from disease in last 7 days.
int PlgQryDeaths7d()
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "SELECT COUNT(*) FROM plg_events "
        + "WHERE event_type = 'death_from_disease' "
        + "AND timestamp >= strftime('%s','now') - 604800");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Top diseases (by contract count) in last 30 days.
// Returns JsonArray of {disease_id, count}.
json PlgQryTopDiseases30d()
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "SELECT disease_id, COUNT(*) AS cnt FROM plg_events "
        + "WHERE event_type = 'contract' "
        + "AND timestamp >= strftime('%s','now') - 2592000 "
        + "GROUP BY disease_id ORDER BY cnt DESC");
    json jArr = JsonArray();
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "disease_id", JsonInt(SqlGetInt(q, 0)));
        j = JsonObjectSet(j, "count",      JsonInt(SqlGetInt(q, 1)));
        jArr = JsonArrayInsert(jArr, j);
    }
    return jArr;
}

// Top 5 areas with most contracts in last 30 days.
// Returns JsonArray of {area_resref, count}.
json PlgQryTopAreas30d()
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "SELECT area_resref, COUNT(*) AS cnt FROM plg_events "
        + "WHERE event_type = 'contract' AND area_resref IS NOT NULL "
        + "AND timestamp >= strftime('%s','now') - 2592000 "
        + "GROUP BY area_resref ORDER BY cnt DESC LIMIT 5");
    json jArr = JsonArray();
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "area_resref", JsonString(SqlGetString(q, 0)));
        j = JsonObjectSet(j, "count",       JsonInt(SqlGetInt(q, 1)));
        jArr = JsonArrayInsert(jArr, j);
    }
    return jArr;
}

// Body fight win rate per phase (incubation/mild/severe/critical).
// Returns JsonArray of {phase, total, successes, win_pct} ordered by phase.
json PlgQryBodyFightWinRate()
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "SELECT phase_from AS phase, COUNT(*) AS total, "
        + "SUM(CASE WHEN save_result IN ('success','crit_success') THEN 1 ELSE 0 END) AS successes "
        + "FROM plg_events WHERE event_type = 'body_fight' "
        + "GROUP BY phase_from ORDER BY phase_from");
    json jArr = JsonArray();
    while(SqlStep(q))
    {
        int nPhase = SqlGetInt(q, 0);
        int nTotal = SqlGetInt(q, 1);
        int nSucc  = SqlGetInt(q, 2);
        int nPct = (nTotal > 0) ? (nSucc * 100) / nTotal : 0;
        json j = JsonObject();
        j = JsonObjectSet(j, "phase",     JsonInt(nPhase));
        j = JsonObjectSet(j, "total",     JsonInt(nTotal));
        j = JsonObjectSet(j, "successes", JsonInt(nSucc));
        j = JsonObjectSet(j, "win_pct",   JsonInt(nPct));
        jArr = JsonArrayInsert(jArr, j);
    }
    return jArr;
}

// Total contracts in last 30 days (for percentage calculation).
int PlgQryTotalContracts30d()
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "SELECT COUNT(*) FROM plg_events "
        + "WHERE event_type = 'contract' "
        + "AND timestamp >= strftime('%s','now') - 2592000");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Total cure_success events in last 30 days.
int PlgQryTotalCures30d()
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "SELECT COUNT(*) FROM plg_events "
        + "WHERE event_type = 'cure_success' "
        + "AND timestamp >= strftime('%s','now') - 2592000");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Diagnostic lens uses in last 30 days.
int PlgQryLensUses30d()
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "SELECT COUNT(*) FROM plg_events "
        + "WHERE event_type = 'lens_used' "
        + "AND timestamp >= strftime('%s','now') - 2592000");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// First aid attempts in last 30 days, by result ('success'/'fail').
int PlgQryFirstAidByResult30d(string sResult)
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "SELECT COUNT(*) FROM plg_events "
        + "WHERE event_type = 'apteczka_attempt' "
        + "AND save_result = @res "
        + "AND timestamp >= strftime('%s','now') - 2592000");
    SqlBindString(q, "@res", sResult);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Wrong-rank cure attempts in last 30 days (player tried lower rank than required).
int PlgQryWrongCureAttempts30d()
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "SELECT COUNT(*) FROM plg_events "
        + "WHERE event_type = 'cure_attempt' "
        + "AND save_result = 'rank_mismatch' "
        + "AND timestamp >= strftime('%s','now') - 2592000");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Contagion spreads (carrier -> target infected) in last 7 days.
int PlgQryContagionSpreads7d()
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "SELECT COUNT(*) FROM plg_events "
        + "WHERE event_type = 'contagion_spread' "
        + "AND timestamp >= strftime('%s','now') - 604800");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Players currently carrying 2+ diseases (multi-disease count).
int PlgQryMultiDiseasePlayers()
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "SELECT COUNT(*) FROM ("
        + "SELECT uuid FROM plg_diseases GROUP BY uuid HAVING COUNT(*) >= 2"
        + ")");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns the disease_id with most contracts in last 30d, or -1 if none.
int PlgQryTopDiseaseId30d()
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "SELECT disease_id FROM plg_events "
        + "WHERE event_type = 'contract' "
        + "AND timestamp >= strftime('%s','now') - 2592000 "
        + "GROUP BY disease_id ORDER BY COUNT(*) DESC LIMIT 1");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return -1;
}

// Returns the area_resref with most contracts in last 30d, or "" if none.
string PlgQryTopAreaName30d()
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "SELECT area_resref FROM plg_events "
        + "WHERE event_type = 'contract' AND area_resref IS NOT NULL "
        + "AND timestamp >= strftime('%s','now') - 2592000 "
        + "GROUP BY area_resref ORDER BY COUNT(*) DESC LIMIT 1");
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "";
}

// Recovery rate: cures / (cures + deaths) * 100, in last 30 days. Returns -1 if no episodes.
int PlgQryRecoveryRate30d()
{
    int nCures  = PlgQryTotalCures30d();
    int nDeaths = 0;
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "SELECT COUNT(*) FROM plg_events "
        + "WHERE event_type = 'death_from_disease' "
        + "AND timestamp >= strftime('%s','now') - 2592000");
    if(SqlStep(q)) nDeaths = SqlGetInt(q, 0);

    int nTotal = nCures + nDeaths;
    if(nTotal == 0) return -1;
    return (nCures * 100) / nTotal;
}

// Average seconds from contract to first reaching critical phase
// (only completed escalations, last 30 days). Returns 0 if no data.
int PlgQryAvgIncubToCritical30d()
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "SELECT AVG(adv.timestamp - ctr.timestamp) "
        + "FROM plg_events ctr "
        + "JOIN plg_events adv ON adv.episode_id = ctr.episode_id "
        + "WHERE ctr.event_type = 'contract' "
        + "AND adv.event_type = 'phase_advance' "
        + "AND adv.phase_to = 4 "
        + "AND ctr.timestamp >= strftime('%s','now') - 2592000");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Body fight win rate for a specific phase (in percent, 0-100).
int PlgQryBodyFightWinRateForPhase(int nPhase)
{
    sqlquery q = SqlPrepareQueryCampaign(PLG_CAMPAIGN,
        "SELECT COUNT(*), "
        + "SUM(CASE WHEN save_result IN ('success','crit_success') THEN 1 ELSE 0 END) "
        + "FROM plg_events "
        + "WHERE event_type = 'body_fight' AND phase_from = @ph");
    SqlBindInt(q, "@ph", nPhase);
    if(!SqlStep(q)) return 0;
    int nTotal = SqlGetInt(q, 0);
    int nSucc  = SqlGetInt(q, 1);
    if(nTotal == 0) return 0;
    return (nSucc * 100) / nTotal;
}

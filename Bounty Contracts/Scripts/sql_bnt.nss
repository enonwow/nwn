// sql_bnt.nss — Bounty Contracts: SQL schema and all data-layer queries.

// ============================================================
// Contract states
// ============================================================
const int BNT_STATE_OPEN      = 0;
const int BNT_STATE_ACCEPTED  = 1;
const int BNT_STATE_COMPLETED = 2;
const int BNT_STATE_EXPIRED   = 3;
const int BNT_STATE_CANCELLED = 4;

// ============================================================
// Tuning constants
// ============================================================
const int BNT_EXPIRY_DAYS     = 7;
const int BNT_MIN_REWARD      = 50;
const int BNT_MAX_REWARD      = 999999;
const int BNT_MAX_DESC        = 200;
const int BNT_MAX_TARGET_NAME = 60;

// ============================================================
// Schema
// ============================================================

void BntCreateTables()
{
    sqlquery q;

    q = SqlPrepareQueryCampaign("bounty",
        "CREATE TABLE IF NOT EXISTS bnt_contracts ("
        "  id          INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  target_name TEXT    NOT NULL DEFAULT '',"
        "  target_uuid TEXT             DEFAULT '',"
        "  description TEXT             DEFAULT '',"
        "  reward      INTEGER          DEFAULT 0,"
        "  poster_uuid TEXT    NOT NULL DEFAULT '',"
        "  poster_name TEXT    NOT NULL DEFAULT '',"
        "  hunter_uuid TEXT             DEFAULT '',"
        "  hunter_name TEXT             DEFAULT '',"
        "  state       INTEGER          DEFAULT 0,"
        "  posted_at   INTEGER          DEFAULT (strftime('%s','now')),"
        "  expires_at  INTEGER          DEFAULT 0,"
        "  completed_at INTEGER         DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("bounty",
        "CREATE TABLE IF NOT EXISTS bnt_players ("
        "  uuid      TEXT PRIMARY KEY,"
        "  char_name TEXT DEFAULT '',"
        "  last_seen INTEGER DEFAULT (strftime('%s','now'))"
        ")");
    SqlStep(q);
}

// ============================================================
// Player registry
// ============================================================

void BntRegisterPlayer(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("bounty",
        "INSERT OR REPLACE INTO bnt_players (uuid, char_name, last_seen) "
        "VALUES (@uuid, @name, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlStep(q);
}

// Returns uuid string or "" if not found
string BntFindPlayerUUID(string sName)
{
    sqlquery q = SqlPrepareQueryCampaign("bounty",
        "SELECT uuid FROM bnt_players WHERE LOWER(char_name) = LOWER(@name) LIMIT 1");
    SqlBindString(q, "@name", sName);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "";
}

// ============================================================
// Maintenance
// ============================================================

void BntExpireContracts()
{
    sqlquery q = SqlPrepareQueryCampaign("bounty",
        "UPDATE bnt_contracts SET state = @exp "
        "WHERE state IN (@open, @acc) AND expires_at > 0 AND expires_at < strftime('%s','now')");
    SqlBindInt(q, "@exp",  BNT_STATE_EXPIRED);
    SqlBindInt(q, "@open", BNT_STATE_OPEN);
    SqlBindInt(q, "@acc",  BNT_STATE_ACCEPTED);
    SqlStep(q);
}

// ============================================================
// Write operations
// ============================================================

// Returns new contract id, or 0 on failure
int BntPostContract(object oPoster, string sTargetName, string sTargetUuid,
                    string sDesc, int nReward)
{
    sqlquery q = SqlPrepareQueryCampaign("bounty",
        "INSERT INTO bnt_contracts "
        "  (target_name, target_uuid, description, reward, poster_uuid, poster_name,"
        "   state, posted_at, expires_at) "
        "VALUES (@tname, @tuuid, @desc, @rew, @puuid, @pname, "
        "        @open, strftime('%s','now'), strftime('%s','now') + @exp)");
    SqlBindString(q, "@tname", sTargetName);
    SqlBindString(q, "@tuuid", sTargetUuid);
    SqlBindString(q, "@desc",  sDesc);
    SqlBindInt   (q, "@rew",   nReward);
    SqlBindString(q, "@puuid", GetObjectUUID(oPoster));
    SqlBindString(q, "@pname", GetName(oPoster));
    SqlBindInt   (q, "@open",  BNT_STATE_OPEN);
    SqlBindInt   (q, "@exp",   BNT_EXPIRY_DAYS * 86400);
    SqlStep(q);

    sqlquery qId = SqlPrepareQueryCampaign("bounty", "SELECT last_insert_rowid()");
    if(SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

// Returns TRUE if successfully accepted (contract was open)
int BntAcceptContract(object oPC, int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("bounty",
        "UPDATE bnt_contracts SET state = @acc, hunter_uuid = @uuid, hunter_name = @name "
        "WHERE id = @id AND state = @open");
    SqlBindInt   (q, "@acc",  BNT_STATE_ACCEPTED);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlBindInt   (q, "@id",   nId);
    SqlBindInt   (q, "@open", BNT_STATE_OPEN);
    SqlStep(q);

    sqlquery qC = SqlPrepareQueryCampaign("bounty", "SELECT changes()");
    if(SqlStep(qC)) return SqlGetInt(qC, 0) > 0;
    return FALSE;
}

void BntAbandonContract(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("bounty",
        "UPDATE bnt_contracts SET state = @open, hunter_uuid = '', hunter_name = '' "
        "WHERE hunter_uuid = @uuid AND state = @acc");
    SqlBindInt   (q, "@open", BNT_STATE_OPEN);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@acc",  BNT_STATE_ACCEPTED);
    SqlStep(q);
}

// Returns reward gold if claim succeeded, 0 otherwise
int BntClaimContract(object oPC, int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("bounty",
        "SELECT reward FROM bnt_contracts WHERE id = @id AND hunter_uuid = @uuid AND state = @acc");
    SqlBindInt   (q, "@id",   nId);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@acc",  BNT_STATE_ACCEPTED);
    if(!SqlStep(q)) return 0;
    int nReward = SqlGetInt(q, 0);

    sqlquery qU = SqlPrepareQueryCampaign("bounty",
        "UPDATE bnt_contracts SET state = @done, completed_at = strftime('%s','now') "
        "WHERE id = @id AND hunter_uuid = @uuid AND state = @acc");
    SqlBindInt   (qU, "@done", BNT_STATE_COMPLETED);
    SqlBindInt   (qU, "@id",   nId);
    SqlBindString(qU, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (qU, "@acc",  BNT_STATE_ACCEPTED);
    SqlStep(qU);

    return nReward;
}

// Returns gold refunded (full if open, 0 if already accepted)
int BntCancelOwnContract(object oPC, int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("bounty",
        "SELECT reward, state FROM bnt_contracts WHERE id = @id AND poster_uuid = @uuid");
    SqlBindInt   (q, "@id",   nId);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(!SqlStep(q)) return 0;

    int nReward = SqlGetInt(q, 0);
    int nState  = SqlGetInt(q, 1);
    int nRefund = (nState == BNT_STATE_OPEN) ? nReward : 0;

    sqlquery qU = SqlPrepareQueryCampaign("bounty",
        "UPDATE bnt_contracts SET state = @can "
        "WHERE id = @id AND poster_uuid = @uuid AND state IN (@open, @acc)");
    SqlBindInt   (qU, "@can",  BNT_STATE_CANCELLED);
    SqlBindInt   (qU, "@id",   nId);
    SqlBindString(qU, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (qU, "@open", BNT_STATE_OPEN);
    SqlBindInt   (qU, "@acc",  BNT_STATE_ACCEPTED);
    SqlStep(qU);

    return nRefund;
}

// Called from OnPlayerDeath — auto-payout when killer has active contract on dead PC.
// Returns reward paid out, 0 if nothing triggered.
int BntCheckDeathPayout(object oDeadPC, object oKillerPC)
{
    if(!GetIsObjectValid(oKillerPC) || !GetIsPC(oKillerPC)) return 0;

    string sDeadUuid   = GetObjectUUID(oDeadPC);
    string sKillerUuid = GetObjectUUID(oKillerPC);

    sqlquery q = SqlPrepareQueryCampaign("bounty",
        "SELECT id, reward FROM bnt_contracts "
        "WHERE target_uuid = @tuuid AND hunter_uuid = @huuid AND state = @acc LIMIT 1");
    SqlBindString(q, "@tuuid", sDeadUuid);
    SqlBindString(q, "@huuid", sKillerUuid);
    SqlBindInt   (q, "@acc",   BNT_STATE_ACCEPTED);
    if(!SqlStep(q)) return 0;

    int nId     = SqlGetInt(q, 0);
    int nReward = SqlGetInt(q, 1);

    sqlquery qU = SqlPrepareQueryCampaign("bounty",
        "UPDATE bnt_contracts SET state = @done, completed_at = strftime('%s','now') "
        "WHERE id = @id");
    SqlBindInt(qU, "@done", BNT_STATE_COMPLETED);
    SqlBindInt(qU, "@id",   nId);
    SqlStep(qU);

    return nReward;
}

// ============================================================
// Read operations
// ============================================================

// Returns JsonArray [{id, target_name, reward, poster_name, expires_at, description}, ...]
// ordered by reward DESC
json BntGetOpenContracts()
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("bounty",
        "SELECT id, target_name, reward, poster_name, expires_at, description "
        "FROM bnt_contracts WHERE state = @open ORDER BY reward DESC");
    SqlBindInt(q, "@open", BNT_STATE_OPEN);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",          JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "target_name", JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "reward",      JsonInt   (SqlGetInt   (q, 2)));
        jRow = JsonObjectSet(jRow, "poster_name", JsonString(SqlGetString(q, 3)));
        jRow = JsonObjectSet(jRow, "expires_at",  JsonInt   (SqlGetInt   (q, 4)));
        jRow = JsonObjectSet(jRow, "description", JsonString(SqlGetString(q, 5)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

// Returns JsonObject for active (accepted) contract held by this hunter, or JsonNull()
json BntGetActiveContract(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("bounty",
        "SELECT id, target_name, target_uuid, description, reward, poster_name, expires_at "
        "FROM bnt_contracts WHERE hunter_uuid = @uuid AND state = @acc");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@acc",  BNT_STATE_ACCEPTED);
    if(!SqlStep(q)) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "id",          JsonInt   (SqlGetInt   (q, 0)));
    j = JsonObjectSet(j, "target_name", JsonString(SqlGetString(q, 1)));
    j = JsonObjectSet(j, "target_uuid", JsonString(SqlGetString(q, 2)));
    j = JsonObjectSet(j, "description", JsonString(SqlGetString(q, 3)));
    j = JsonObjectSet(j, "reward",      JsonInt   (SqlGetInt   (q, 4)));
    j = JsonObjectSet(j, "poster_name", JsonString(SqlGetString(q, 5)));
    j = JsonObjectSet(j, "expires_at",  JsonInt   (SqlGetInt   (q, 6)));
    return j;
}

// Returns JsonArray [{id, target_name, reward, state, hunter_name}, ...] for poster
json BntGetMyPostedContracts(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("bounty",
        "SELECT id, target_name, reward, state, hunter_name "
        "FROM bnt_contracts WHERE poster_uuid = @uuid AND state IN (@open, @acc) "
        "ORDER BY posted_at DESC");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@open", BNT_STATE_OPEN);
    SqlBindInt   (q, "@acc",  BNT_STATE_ACCEPTED);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",          JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "target_name", JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "reward",      JsonInt   (SqlGetInt   (q, 2)));
        jRow = JsonObjectSet(jRow, "state",       JsonInt   (SqlGetInt   (q, 3)));
        jRow = JsonObjectSet(jRow, "hunter_name", JsonString(SqlGetString(q, 4)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

// ============================================================
// Formatting helpers
// ============================================================

string BntFormatDate(int nUnix)
{
    sqlquery q = SqlPrepareQueryCampaign("bounty",
        "SELECT strftime('%d.%m.%y', @ts, 'unixepoch')");
    SqlBindInt(q, "@ts", nUnix);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "";
}

string BntDaysLeft(int nExpiresAt)
{
    sqlquery q = SqlPrepareQueryCampaign("bounty",
        "SELECT MAX(0, CAST((@exp - strftime('%s','now')) / 86400 AS INTEGER))");
    SqlBindInt(q, "@exp", nExpiresAt);
    if(SqlStep(q)) return IntToString(SqlGetInt(q, 0)) + "d";
    return "?d";
}

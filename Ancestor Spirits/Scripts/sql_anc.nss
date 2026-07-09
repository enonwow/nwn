// sql_anc.nss — Ancestor Spirits: SQL layer (campaign "anc")

const int ANC_FAVOR_MAX      = 100;
const int ANC_COOLDOWN_SECS  = 86400;   // 24 hours

void AncCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("anc",
        "CREATE TABLE IF NOT EXISTS anc_chars ("
        "  uuid          TEXT PRIMARY KEY, "
        "  char_name     TEXT DEFAULT '', "
        "  lineage       INTEGER DEFAULT -1, "
        "  favor         INTEGER DEFAULT 0, "
        "  total_offered INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("anc",
        "CREATE TABLE IF NOT EXISTS anc_cooldowns ("
        "  uuid         TEXT NOT NULL, "
        "  ancestor_id  INTEGER NOT NULL, "
        "  last_invoked INTEGER DEFAULT 0, "
        "  PRIMARY KEY (uuid, ancestor_id)"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("anc",
        "CREATE TABLE IF NOT EXISTS anc_history ("
        "  id            INTEGER PRIMARY KEY AUTOINCREMENT, "
        "  uuid          TEXT NOT NULL, "
        "  ancestor_id   INTEGER NOT NULL, "
        "  ancestor_name TEXT DEFAULT '', "
        "  invoked_at    INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

void AncRegisterPC(object oPC)
{
    string sUuid = GetObjectUUID(oPC);
    string sName = GetName(oPC);

    sqlquery q = SqlPrepareQueryCampaign("anc",
        "INSERT OR IGNORE INTO anc_chars (uuid, char_name) VALUES (@uuid, @name)");
    SqlBindString(q, "@uuid", sUuid);
    SqlBindString(q, "@name", sName);
    SqlStep(q);

    q = SqlPrepareQueryCampaign("anc",
        "UPDATE anc_chars SET char_name = @name WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", sUuid);
    SqlBindString(q, "@name", sName);
    SqlStep(q);
}

int AncGetLineage(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("anc",
        "SELECT lineage FROM anc_chars WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return -1;
}

void AncSetLineage(object oPC, int nLineage)
{
    sqlquery q = SqlPrepareQueryCampaign("anc",
        "UPDATE anc_chars SET lineage = @lin WHERE uuid = @uuid");
    SqlBindInt   (q, "@lin",  nLineage);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

int AncGetFavor(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("anc",
        "SELECT favor FROM anc_chars WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns how many Favor points were actually added (capped at MAX).
int AncAddFavor(object oPC, int nAmount)
{
    int nCurrent = AncGetFavor(oPC);
    int nNew     = nCurrent + nAmount;
    if(nNew > ANC_FAVOR_MAX) nNew = ANC_FAVOR_MAX;
    int nAdded   = nNew - nCurrent;
    if(nAdded <= 0) return 0;

    sqlquery q = SqlPrepareQueryCampaign("anc",
        "UPDATE anc_chars SET favor = @fav, total_offered = total_offered + @add "
        "WHERE uuid = @uuid");
    SqlBindInt   (q, "@fav",  nNew);
    SqlBindInt   (q, "@add",  nAdded);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
    return nAdded;
}

// Returns TRUE on success, FALSE if insufficient Favor.
int AncSpendFavor(object oPC, int nCost)
{
    if(AncGetFavor(oPC) < nCost) return FALSE;

    sqlquery q = SqlPrepareQueryCampaign("anc",
        "UPDATE anc_chars SET favor = favor - @cost WHERE uuid = @uuid");
    SqlBindInt   (q, "@cost", nCost);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
    return TRUE;
}

int AncGetCurrentUnix()
{
    sqlquery q = SqlPrepareQueryCampaign("anc", "SELECT strftime('%s','now')");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns unix timestamp of the last invocation, or 0 if never invoked.
int AncGetLastInvoked(object oPC, int nAncestorId)
{
    sqlquery q = SqlPrepareQueryCampaign("anc",
        "SELECT last_invoked FROM anc_cooldowns "
        "WHERE uuid = @uuid AND ancestor_id = @aid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@aid",  nAncestorId);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void AncSetInvoked(object oPC, int nAncestorId)
{
    sqlquery q = SqlPrepareQueryCampaign("anc",
        "INSERT OR REPLACE INTO anc_cooldowns (uuid, ancestor_id, last_invoked) "
        "VALUES (@uuid, @aid, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@aid",  nAncestorId);
    SqlStep(q);
}

void AncAddHistory(object oPC, int nAncestorId, string sName)
{
    sqlquery q = SqlPrepareQueryCampaign("anc",
        "INSERT INTO anc_history (uuid, ancestor_id, ancestor_name, invoked_at) "
        "VALUES (@uuid, @aid, @name, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@aid",  nAncestorId);
    SqlBindString(q, "@name", sName);
    SqlStep(q);
}

// Returns JsonArray of last 5 entries: [{name, date}, ...]
json AncGetHistory(object oPC)
{
    json jHist = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("anc",
        "SELECT ancestor_name, "
        "strftime('%d.%m %H:%M', invoked_at, 'unixepoch') AS dt "
        "FROM anc_history WHERE uuid = @uuid "
        "ORDER BY invoked_at DESC LIMIT 5");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "name", JsonString(SqlGetString(q, 0)));
        jRow = JsonObjectSet(jRow, "date", JsonString(SqlGetString(q, 1)));
        jHist = JsonArrayInsert(jHist, jRow);
    }
    return jHist;
}

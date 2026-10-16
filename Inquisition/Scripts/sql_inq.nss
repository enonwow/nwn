// sql_inq.nss - Inquisition: schema + queries

void InqCreateTables()
{
    sqlquery q;

    // One row per PC per heretical act committed. Multiple rows for same act = repeat offence.
    q = SqlPrepareQueryCampaign("inquisition",
        "CREATE TABLE IF NOT EXISTS inq_charges ("
        "  id          INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  pc_uuid     TEXT    NOT NULL,"
        "  pc_name     TEXT    NOT NULL DEFAULT '',"
        "  act_id      INTEGER NOT NULL,"
        "  weight      INTEGER NOT NULL DEFAULT 0,"
        "  recorded_at INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);

    // Aggregated rating cache + state per PC. Rebuilt from inq_charges on demand.
    q = SqlPrepareQueryCampaign("inquisition",
        "CREATE TABLE IF NOT EXISTS inq_ratings ("
        "  pc_uuid     TEXT PRIMARY KEY,"
        "  pc_name     TEXT    NOT NULL DEFAULT '',"
        "  rating      INTEGER NOT NULL DEFAULT 0,"
        "  last_update INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);
}

// Returns current rating for PC, or 0 if no record.
int InqGetRating(string sPcUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("inquisition",
        "SELECT rating FROM inq_ratings WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", sPcUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Recomputes rating from charges table and writes to cache.
int InqRebuildRating(string sPcUuid, string sPcName)
{
    sqlquery q = SqlPrepareQueryCampaign("inquisition",
        "SELECT COALESCE(SUM(weight), 0) FROM inq_charges WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", sPcUuid);
    int nRating = 0;
    if(SqlStep(q)) nRating = SqlGetInt(q, 0);
    if(nRating > 100) nRating = 100;

    q = SqlPrepareQueryCampaign("inquisition",
        "INSERT OR REPLACE INTO inq_ratings (pc_uuid, pc_name, rating, last_update)"
        "  VALUES (@uuid, @name, @rating, strftime('%s','now'))");
    SqlBindString(q, "@uuid",   sPcUuid);
    SqlBindString(q, "@name",   sPcName);
    SqlBindInt   (q, "@rating", nRating);
    SqlStep(q);

    return nRating;
}

// Inserts a new charge, returns updated rating.
int InqInsertCharge(string sPcUuid, string sPcName, int nActId, int nWeight)
{
    sqlquery q = SqlPrepareQueryCampaign("inquisition",
        "INSERT INTO inq_charges (pc_uuid, pc_name, act_id, weight, recorded_at)"
        "  VALUES (@uuid, @name, @act, @weight, strftime('%s','now'))");
    SqlBindString(q, "@uuid",   sPcUuid);
    SqlBindString(q, "@name",   sPcName);
    SqlBindInt   (q, "@act",    nActId);
    SqlBindInt   (q, "@weight", nWeight);
    SqlStep(q);

    return InqRebuildRating(sPcUuid, sPcName);
}

// Reduces rating by nAmount (removes oldest charges until nAmount weight removed or none left).
int InqReduceRating(string sPcUuid, string sPcName, int nAmount)
{
    int nCurrent = InqGetRating(sPcUuid);
    int nTarget  = nCurrent - nAmount;
    if(nTarget < 0) nTarget = 0;

    // Remove oldest charges until we hit target
    sqlquery qList = SqlPrepareQueryCampaign("inquisition",
        "SELECT id, weight FROM inq_charges WHERE pc_uuid = @uuid ORDER BY recorded_at ASC");
    SqlBindString(qList, "@uuid", sPcUuid);

    int nRemoved = 0;
    while(SqlStep(qList) && (nCurrent - nRemoved) > nTarget)
    {
        int nId     = SqlGetInt(qList, 0);
        int nWeight = SqlGetInt(qList, 1);

        sqlquery qDel = SqlPrepareQueryCampaign("inquisition",
            "DELETE FROM inq_charges WHERE id = @id");
        SqlBindInt(qDel, "@id", nId);
        SqlStep(qDel);

        nRemoved += nWeight;
    }

    return InqRebuildRating(sPcUuid, sPcName);
}

// Clears ALL charges for a PC (full pardon).
int InqClearAll(string sPcUuid, string sPcName)
{
    sqlquery q = SqlPrepareQueryCampaign("inquisition",
        "DELETE FROM inq_charges WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", sPcUuid);
    SqlStep(q);

    return InqRebuildRating(sPcUuid, sPcName);
}

// Returns JsonArray of charge summaries for a PC:
// [{act_id, act_name, weight, count, total_weight}, ...]  grouped by act_id.
json InqGetChargesSummary(string sPcUuid)
{
    json jResult = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("inquisition",
        "SELECT act_id, weight, COUNT(*) as cnt, SUM(weight) as total"
        "  FROM inq_charges WHERE pc_uuid = @uuid"
        "  GROUP BY act_id ORDER BY total DESC");
    SqlBindString(q, "@uuid", sPcUuid);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "act_id",       JsonInt(SqlGetInt(q, 0)));
        jRow = JsonObjectSet(jRow, "weight",        JsonInt(SqlGetInt(q, 1)));
        jRow = JsonObjectSet(jRow, "count",         JsonInt(SqlGetInt(q, 2)));
        jRow = JsonObjectSet(jRow, "total_weight",  JsonInt(SqlGetInt(q, 3)));
        jResult = JsonArrayInsert(jResult, jRow);
    }
    return jResult;
}

// Returns JsonArray of all PCs with nonzero rating for DM panel:
// [{uuid, name, rating}, ...]
json InqGetAllSuspects()
{
    json jResult = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("inquisition",
        "SELECT pc_uuid, pc_name, rating FROM inq_ratings"
        "  WHERE rating > 0 ORDER BY rating DESC LIMIT 50");
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "uuid",   JsonString(SqlGetString(q, 0)));
        jRow = JsonObjectSet(jRow, "name",   JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "rating", JsonInt   (SqlGetInt   (q, 2)));
        jResult = JsonArrayInsert(jResult, jRow);
    }
    return jResult;
}

// Upserts PC name (call on enter to keep names current).
void InqUpsertPcName(string sPcUuid, string sPcName)
{
    sqlquery q = SqlPrepareQueryCampaign("inquisition",
        "INSERT OR IGNORE INTO inq_ratings (pc_uuid, pc_name, rating, last_update)"
        "  VALUES (@uuid, @name, 0, strftime('%s','now'))");
    SqlBindString(q, "@uuid", sPcUuid);
    SqlBindString(q, "@name", sPcName);
    SqlStep(q);

    q = SqlPrepareQueryCampaign("inquisition",
        "UPDATE inq_ratings SET pc_name = @name WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", sPcUuid);
    SqlBindString(q, "@name", sPcName);
    SqlStep(q);

    // Keep charge rows in sync too
    q = SqlPrepareQueryCampaign("inquisition",
        "UPDATE inq_charges SET pc_name = @name WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", sPcUuid);
    SqlBindString(q, "@name", sPcName);
    SqlStep(q);
}

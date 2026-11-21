// SQL schema and queries for Demonic Pacts module.
// Campaign database name: "pact"

void PactCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("pact",
        "CREATE TABLE IF NOT EXISTS pact_active ("
        "pc_uuid TEXT PRIMARY KEY, "
        "demon_id TEXT NOT NULL, "
        "signed_at INTEGER DEFAULT 0, "
        "last_toll_at INTEGER DEFAULT 0, "
        "toll_count INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

// Returns {demon_id, signed_at, last_toll_at, toll_count} or JSON_NULL if no pact.
json PactGetActive(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("pact",
        "SELECT demon_id, signed_at, last_toll_at, toll_count "
        "FROM pact_active WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(!SqlStep(q)) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "demon_id",     JsonString(SqlGetString(q, 0)));
    j = JsonObjectSet(j, "signed_at",    JsonInt   (SqlGetInt   (q, 1)));
    j = JsonObjectSet(j, "last_toll_at", JsonInt   (SqlGetInt   (q, 2)));
    j = JsonObjectSet(j, "toll_count",   JsonInt   (SqlGetInt   (q, 3)));
    return j;
}

void PactSign(object oPC, string sDemonId)
{
    sqlquery q = SqlPrepareQueryCampaign("pact",
        "INSERT OR REPLACE INTO pact_active "
        "(pc_uuid, demon_id, signed_at, last_toll_at, toll_count) "
        "VALUES (@uuid, @demon, strftime('%s','now'), strftime('%s','now'), 0)");
    SqlBindString(q, "@uuid",  GetObjectUUID(oPC));
    SqlBindString(q, "@demon", sDemonId);
    SqlStep(q);
}

void PactBreak(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("pact",
        "DELETE FROM pact_active WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void PactRecordToll(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("pact",
        "UPDATE pact_active "
        "SET last_toll_at = strftime('%s','now'), toll_count = toll_count + 1 "
        "WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Returns seconds elapsed since last toll, or 0 if no record.
int PactGetTimeSinceLastToll(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("pact",
        "SELECT CAST(strftime('%s','now') AS INTEGER) - last_toll_at "
        "FROM pact_active WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

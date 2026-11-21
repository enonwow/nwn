void ExrcCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("exorcism",
        "CREATE TABLE IF NOT EXISTS exrc_possession ("
        "uuid TEXT PRIMARY KEY, "
        "level INTEGER DEFAULT 0, "
        "entity_name TEXT DEFAULT '', "
        "possessed_at INTEGER DEFAULT 0)");
    SqlStep(q);
}

void ExrcSavePossession(object oPC, int nLevel, string sEntity)
{
    sqlquery q = SqlPrepareQueryCampaign("exorcism",
        "INSERT OR REPLACE INTO exrc_possession (uuid, level, entity_name, possessed_at) "
        "VALUES (@uuid, @lvl, @ent, "
        "CASE WHEN @lvl2 > 0 THEN strftime('%s','now') "
        "ELSE (SELECT possessed_at FROM exrc_possession WHERE uuid = @uuid3) END)");
    SqlBindString(q, "@uuid",  GetObjectUUID(oPC));
    SqlBindInt   (q, "@lvl",   nLevel);
    SqlBindString(q, "@ent",   sEntity);
    SqlBindInt   (q, "@lvl2",  nLevel);
    SqlBindString(q, "@uuid3", GetObjectUUID(oPC));
    SqlStep(q);
}

int ExrcGetLevel(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("exorcism",
        "SELECT level FROM exrc_possession WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

json ExrcGetRecord(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("exorcism",
        "SELECT level, entity_name, possessed_at FROM exrc_possession WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(!SqlStep(q)) return JsonNull();
    json j = JsonObject();
    j = JsonObjectSet(j, "level",        JsonInt   (SqlGetInt   (q, 0)));
    j = JsonObjectSet(j, "entity_name",  JsonString(SqlGetString(q, 1)));
    j = JsonObjectSet(j, "possessed_at", JsonInt   (SqlGetInt   (q, 2)));
    return j;
}

// Returns seconds since possession, 0 if not possessed
int ExrcGetPossessionAge(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("exorcism",
        "SELECT CAST(strftime('%s','now') AS INTEGER) - possessed_at "
        "FROM exrc_possession WHERE uuid = @uuid AND level > 0");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void BurCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("burial",
        "CREATE TABLE IF NOT EXISTS bur_graves (" +
        "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
        "area_tag TEXT DEFAULT '', " +
        "buried_by_uuid TEXT DEFAULT '', " +
        "victim_name TEXT DEFAULT '', " +
        "rite_type INTEGER DEFAULT 0, " +
        "buried_at INTEGER DEFAULT 0, " +
        "desecrated INTEGER DEFAULT 0)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("burial",
        "CREATE TABLE IF NOT EXISTS bur_meditation (" +
        "player_uuid TEXT NOT NULL, " +
        "grave_id INTEGER NOT NULL, " +
        "last_meditated INTEGER DEFAULT 0, " +
        "PRIMARY KEY (player_uuid, grave_id))");
    SqlStep(q);
}

int BurInsertGrave(object oPC, string sVictimName, int nRiteType)
{
    sqlquery q = SqlPrepareQueryCampaign("burial",
        "INSERT INTO bur_graves (area_tag, buried_by_uuid, victim_name, rite_type, buried_at) " +
        "VALUES (@area, @uuid, @name, @rite, strftime('%s','now'))");
    SqlBindString(q, "@area", GetTag(GetArea(oPC)));
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", sVictimName);
    SqlBindInt   (q, "@rite", nRiteType);
    SqlStep(q);

    sqlquery qId = SqlPrepareQueryCampaign("burial", "SELECT last_insert_rowid()");
    if(SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

json BurGetMyGraves(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("burial",
        "SELECT id, victim_name, rite_type, buried_at, desecrated " +
        "FROM bur_graves WHERE buried_by_uuid = @uuid ORDER BY buried_at DESC LIMIT 40");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",          JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "victim_name", JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "rite_type",   JsonInt   (SqlGetInt   (q, 2)));
        jRow = JsonObjectSet(jRow, "buried_at",   JsonInt   (SqlGetInt   (q, 3)));
        jRow = JsonObjectSet(jRow, "desecrated",  JsonInt   (SqlGetInt   (q, 4)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

json BurGetGrave(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("burial",
        "SELECT id, area_tag, buried_by_uuid, victim_name, rite_type, buried_at, desecrated " +
        "FROM bur_graves WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();

    json jRow = JsonObject();
    jRow = JsonObjectSet(jRow, "id",          JsonInt   (SqlGetInt   (q, 0)));
    jRow = JsonObjectSet(jRow, "area_tag",    JsonString(SqlGetString(q, 1)));
    jRow = JsonObjectSet(jRow, "buried_by",   JsonString(SqlGetString(q, 2)));
    jRow = JsonObjectSet(jRow, "victim_name", JsonString(SqlGetString(q, 3)));
    jRow = JsonObjectSet(jRow, "rite_type",   JsonInt   (SqlGetInt   (q, 4)));
    jRow = JsonObjectSet(jRow, "buried_at",   JsonInt   (SqlGetInt   (q, 5)));
    jRow = JsonObjectSet(jRow, "desecrated",  JsonInt   (SqlGetInt   (q, 6)));
    return jRow;
}

void BurMarkDesecrated(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("burial",
        "UPDATE bur_graves SET desecrated = 1 WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

int BurGetLastMeditated(object oPC, int nGraveId)
{
    sqlquery q = SqlPrepareQueryCampaign("burial",
        "SELECT last_meditated FROM bur_meditation WHERE player_uuid = @uuid AND grave_id = @gid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@gid",  nGraveId);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void BurSetMeditated(object oPC, int nGraveId)
{
    sqlquery q = SqlPrepareQueryCampaign("burial",
        "INSERT OR REPLACE INTO bur_meditation (player_uuid, grave_id, last_meditated) " +
        "VALUES (@uuid, @gid, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@gid",  nGraveId);
    SqlStep(q);
}

// Returns current unix timestamp from SQLite (avoids NWN calendar quirks)
int BurNow()
{
    sqlquery q = SqlPrepareQueryCampaign("burial", "SELECT strftime('%s','now')");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

string BurFormatDate(int nUnix)
{
    sqlquery q = SqlPrepareQueryCampaign("burial",
        "SELECT strftime('%d.%m', @ts, 'unixepoch')");
    SqlBindInt(q, "@ts", nUnix);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "";
}

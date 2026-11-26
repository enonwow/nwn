// Persistent storage for the Last Breath module.
// Campaign DB name: "last_breath"

const int LBR_DECAY_DAYS = 7;

void LbrCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("last_breath",
        "CREATE TABLE IF NOT EXISTS lbr_essences ("
        "  id            INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  char_uuid     TEXT    NOT NULL,"
        "  essence_type  INTEGER DEFAULT 0,"
        "  creature_name TEXT    DEFAULT '',"
        "  harvested_at  INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

int LbrGetEssenceCount(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("last_breath",
        "SELECT COUNT(*) FROM lbr_essences WHERE char_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns JsonArray of essence rows ordered newest first.
json LbrGetEssences(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("last_breath",
        "SELECT id, essence_type, creature_name, harvested_at"
        " FROM lbr_essences"
        " WHERE char_uuid = @uuid"
        " ORDER BY harvested_at DESC");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",            JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "essence_type",  JsonInt   (SqlGetInt   (q, 1)));
        jRow = JsonObjectSet(jRow, "creature_name", JsonString(SqlGetString(q, 2)));
        jRow = JsonObjectSet(jRow, "harvested_at",  JsonInt   (SqlGetInt   (q, 3)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

void LbrAddEssence(object oPC, int nType, string sCreatureName)
{
    sqlquery q = SqlPrepareQueryCampaign("last_breath",
        "INSERT INTO lbr_essences (char_uuid, essence_type, creature_name, harvested_at)"
        " VALUES (@uuid, @type, @name, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@type", nType);
    SqlBindString(q, "@name", sCreatureName);
    SqlStep(q);
}

void LbrDeleteEssence(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("last_breath",
        "DELETE FROM lbr_essences WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

// Removes essences older than LBR_DECAY_DAYS days.
void LbrClearDecayed(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("last_breath",
        "DELETE FROM lbr_essences"
        " WHERE char_uuid = @uuid"
        "   AND harvested_at < strftime('%s','now') - @days * 86400");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@days", LBR_DECAY_DAYS);
    SqlStep(q);
}

// sql_soc.nss — Soul Crystals: SQLite schema and query helpers.
// Campaign DB: "soc"

void SocCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("soc",
        "CREATE TABLE IF NOT EXISTS soc_crystals ("
        "  id            INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  owner_uuid    TEXT    NOT NULL,"
        "  soul_name     TEXT    NOT NULL DEFAULT 'Duch',"
        "  race_cat      INTEGER NOT NULL DEFAULT 1,"
        "  essence       INTEGER NOT NULL DEFAULT 10,"
        "  tier          INTEGER NOT NULL DEFAULT 1,"
        "  captured_at   INTEGER DEFAULT (strftime('%s','now'))"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("soc",
        "CREATE TABLE IF NOT EXISTS soc_players ("
        "  uuid                 TEXT PRIMARY KEY,"
        "  total_captured       INTEGER DEFAULT 0,"
        "  total_essence_spent  INTEGER DEFAULT 0,"
        "  last_full_consume    INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

void SocRegisterPlayer(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("soc",
        "INSERT OR IGNORE INTO soc_players (uuid) VALUES (@uuid)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

int SocGetCrystalCount(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("soc",
        "SELECT COUNT(*) FROM soc_crystals WHERE owner_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if (SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns new crystal id (0 on failure)
int SocAddCrystal(object oPC, string sSoulName, int nRaceCat, int nEssence, int nTier)
{
    sqlquery q = SqlPrepareQueryCampaign("soc",
        "INSERT INTO soc_crystals (owner_uuid, soul_name, race_cat, essence, tier) "
        "VALUES (@uuid, @name, @race, @ess, @tier)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", sSoulName);
    SqlBindInt(q, "@race", nRaceCat);
    SqlBindInt(q, "@ess",  nEssence);
    SqlBindInt(q, "@tier", nTier);
    SqlStep(q);
    sqlquery qId = SqlPrepareQueryCampaign("soc", "SELECT last_insert_rowid()");
    if (SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

void SocRemoveCrystal(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("soc",
        "DELETE FROM soc_crystals WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

void SocSetCrystalEssence(int nId, int nNewEssence)
{
    sqlquery q = SqlPrepareQueryCampaign("soc",
        "UPDATE soc_crystals SET essence = @ess WHERE id = @id");
    SqlBindInt(q, "@ess", nNewEssence);
    SqlBindInt(q, "@id",  nId);
    SqlStep(q);
}

// Returns JsonArray of {id, soul_name, race_cat, essence, tier}
json SocGetCrystals(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("soc",
        "SELECT id, soul_name, race_cat, essence, tier "
        "FROM soc_crystals WHERE owner_uuid = @uuid ORDER BY tier DESC, essence DESC");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while (SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",        JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "soul_name",  JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "race_cat",   JsonInt   (SqlGetInt   (q, 2)));
        jRow = JsonObjectSet(jRow, "essence",    JsonInt   (SqlGetInt   (q, 3)));
        jRow = JsonObjectSet(jRow, "tier",       JsonInt   (SqlGetInt   (q, 4)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

// Returns single crystal object or JsonNull()
json SocGetCrystalById(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("soc",
        "SELECT id, soul_name, race_cat, essence, tier "
        "FROM soc_crystals WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if (!SqlStep(q)) return JsonNull();
    json jRow = JsonObject();
    jRow = JsonObjectSet(jRow, "id",        JsonInt   (SqlGetInt   (q, 0)));
    jRow = JsonObjectSet(jRow, "soul_name",  JsonString(SqlGetString(q, 1)));
    jRow = JsonObjectSet(jRow, "race_cat",   JsonInt   (SqlGetInt   (q, 2)));
    jRow = JsonObjectSet(jRow, "essence",    JsonInt   (SqlGetInt   (q, 3)));
    jRow = JsonObjectSet(jRow, "tier",       JsonInt   (SqlGetInt   (q, 4)));
    return jRow;
}

void SocRecordCapture(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("soc",
        "UPDATE soc_players SET total_captured = total_captured + 1 WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void SocRecordEssenceSpent(object oPC, int nAmt)
{
    sqlquery q = SqlPrepareQueryCampaign("soc",
        "UPDATE soc_players SET total_essence_spent = total_essence_spent + @amt WHERE uuid = @uuid");
    SqlBindInt   (q, "@amt",  nAmt);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void SocSetLastFullConsume(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("soc",
        "UPDATE soc_players SET last_full_consume = strftime('%s','now') WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

int SocGetLastFullConsume(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("soc",
        "SELECT last_full_consume FROM soc_players WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if (SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns current unix timestamp via SQLite
int SocGetNowUnix()
{
    sqlquery q = SqlPrepareQueryCampaign("soc", "SELECT strftime('%s','now')");
    if (SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns {total_captured, total_essence_spent, last_full_consume} or JsonNull
json SocGetPlayerStats(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("soc",
        "SELECT total_captured, total_essence_spent, last_full_consume "
        "FROM soc_players WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if (!SqlStep(q)) return JsonNull();
    json j = JsonObject();
    j = JsonObjectSet(j, "total_captured",      JsonInt(SqlGetInt(q, 0)));
    j = JsonObjectSet(j, "total_essence_spent",  JsonInt(SqlGetInt(q, 1)));
    j = JsonObjectSet(j, "last_full_consume",    JsonInt(SqlGetInt(q, 2)));
    return j;
}

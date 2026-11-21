// sql_fcraft.nss — SQLite schema and queries for Kowalnia Ciala

void FcraftCreateSchema()
{
    sqlquery q = SqlPrepareQueryCampaign("fleshcraft",
        "CREATE TABLE IF NOT EXISTS fcraft_mods ("
        "  uuid TEXT NOT NULL,"
        "  mod_id TEXT NOT NULL,"
        "  installed_at INTEGER DEFAULT (strftime('%s','now')),"
        "  PRIMARY KEY (uuid, mod_id)"
        ")");
    SqlStep(q);
}

// Returns JsonArray of mod_id strings for this PC
json FcraftGetMods(object oPC)
{
    json jMods = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("fleshcraft",
        "SELECT mod_id FROM fcraft_mods WHERE uuid = @uuid ORDER BY installed_at");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
        jMods = JsonArrayInsert(jMods, JsonString(SqlGetString(q, 0)));
    return jMods;
}

int FcraftGetModCount(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("fleshcraft",
        "SELECT COUNT(*) FROM fcraft_mods WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int FcraftHasMod(object oPC, string sModId)
{
    sqlquery q = SqlPrepareQueryCampaign("fleshcraft",
        "SELECT 1 FROM fcraft_mods WHERE uuid = @uuid AND mod_id = @mod");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@mod",  sModId);
    return SqlStep(q);
}

void FcraftAddMod(object oPC, string sModId)
{
    sqlquery q = SqlPrepareQueryCampaign("fleshcraft",
        "INSERT OR IGNORE INTO fcraft_mods (uuid, mod_id) VALUES (@uuid, @mod)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@mod",  sModId);
    SqlStep(q);
}

void FcraftDeleteMod(object oPC, string sModId)
{
    sqlquery q = SqlPrepareQueryCampaign("fleshcraft",
        "DELETE FROM fcraft_mods WHERE uuid = @uuid AND mod_id = @mod");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@mod",  sModId);
    SqlStep(q);
}

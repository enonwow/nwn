void SbCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("soulbond",
        "CREATE TABLE IF NOT EXISTS sb_weapons ("
        "  weapon_uuid  TEXT PRIMARY KEY,"
        "  weapon_name  TEXT DEFAULT '',"
        "  bond_name    TEXT DEFAULT '',"
        "  bonder_name  TEXT DEFAULT '',"
        "  kills        INTEGER DEFAULT 0,"
        "  rank         INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

// Returns JsonObject {weapon_uuid, weapon_name, bond_name, bonder_name, kills, rank} or JsonNull
json SbGetWeapon(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("soulbond",
        "SELECT weapon_name, bond_name, bonder_name, kills, rank "
        "FROM sb_weapons WHERE weapon_uuid = @uuid");
    SqlBindString(q, "@uuid", sUuid);
    if(!SqlStep(q)) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "weapon_uuid",  JsonString(sUuid));
    j = JsonObjectSet(j, "weapon_name",  JsonString(SqlGetString(q, 0)));
    j = JsonObjectSet(j, "bond_name",    JsonString(SqlGetString(q, 1)));
    j = JsonObjectSet(j, "bonder_name",  JsonString(SqlGetString(q, 2)));
    j = JsonObjectSet(j, "kills",        JsonInt   (SqlGetInt   (q, 3)));
    j = JsonObjectSet(j, "rank",         JsonInt   (SqlGetInt   (q, 4)));
    return j;
}

void SbRegisterWeapon(string sUuid, string sWeaponName, string sBonderName)
{
    sqlquery q = SqlPrepareQueryCampaign("soulbond",
        "INSERT OR IGNORE INTO sb_weapons (weapon_uuid, weapon_name, bonder_name) "
        "VALUES (@uuid, @wname, @bname)");
    SqlBindString(q, "@uuid",  sUuid);
    SqlBindString(q, "@wname", sWeaponName);
    SqlBindString(q, "@bname", sBonderName);
    SqlStep(q);
}

// Returns new kill count after increment
int SbIncrementKills(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("soulbond",
        "UPDATE sb_weapons SET kills = kills + 1 WHERE weapon_uuid = @uuid");
    SqlBindString(q, "@uuid", sUuid);
    SqlStep(q);

    q = SqlPrepareQueryCampaign("soulbond",
        "SELECT kills FROM sb_weapons WHERE weapon_uuid = @uuid");
    SqlBindString(q, "@uuid", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void SbSetRank(string sUuid, int nRank, string sBondName)
{
    sqlquery q = SqlPrepareQueryCampaign("soulbond",
        "UPDATE sb_weapons SET rank = @rank, bond_name = @bname "
        "WHERE weapon_uuid = @uuid");
    SqlBindInt   (q, "@rank",  nRank);
    SqlBindString(q, "@bname", sBondName);
    SqlBindString(q, "@uuid",  sUuid);
    SqlStep(q);
}

void SbDeleteWeapon(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("soulbond",
        "DELETE FROM sb_weapons WHERE weapon_uuid = @uuid");
    SqlBindString(q, "@uuid", sUuid);
    SqlStep(q);
}

// Returns JsonArray of all weapons for display (no PC filter — weapon-centric)
json SbGetAllBonded()
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("soulbond",
        "SELECT weapon_uuid, weapon_name, bond_name, bonder_name, kills, rank "
        "FROM sb_weapons ORDER BY kills DESC LIMIT 50");
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "weapon_uuid",  JsonString(SqlGetString(q, 0)));
        j = JsonObjectSet(j, "weapon_name",  JsonString(SqlGetString(q, 1)));
        j = JsonObjectSet(j, "bond_name",    JsonString(SqlGetString(q, 2)));
        j = JsonObjectSet(j, "bonder_name",  JsonString(SqlGetString(q, 3)));
        j = JsonObjectSet(j, "kills",        JsonInt   (SqlGetInt   (q, 4)));
        j = JsonObjectSet(j, "rank",         JsonInt   (SqlGetInt   (q, 5)));
        jRows = JsonArrayInsert(jRows, j);
    }
    return jRows;
}

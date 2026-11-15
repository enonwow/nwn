void MacCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("danse_macabre",
        "CREATE TABLE IF NOT EXISTS mac_proximity ("
        " uuid TEXT PRIMARY KEY,"
        " char_name TEXT DEFAULT '',"
        " proximity INTEGER DEFAULT 0,"
        " last_updated INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("danse_macabre",
        "CREATE TABLE IF NOT EXISTS mac_contracts ("
        " id INTEGER PRIMARY KEY AUTOINCREMENT,"
        " uuid TEXT NOT NULL,"
        " char_name TEXT DEFAULT '',"
        " contract_type INTEGER DEFAULT 0,"
        " sacrifice_desc TEXT DEFAULT '',"
        " proximity_before INTEGER DEFAULT 0,"
        " proximity_after INTEGER DEFAULT 0,"
        " made_at INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("danse_macabre",
        "CREATE TABLE IF NOT EXISTS mac_omens ("
        " id INTEGER PRIMARY KEY AUTOINCREMENT,"
        " uuid TEXT NOT NULL,"
        " omen_text TEXT DEFAULT '',"
        " proximity_at INTEGER DEFAULT 0,"
        " seen_at INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

void MacRegisterPlayer(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("danse_macabre",
        "INSERT OR IGNORE INTO mac_proximity (uuid, char_name, proximity, last_updated)"
        " VALUES (@uuid, @name, 0, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlStep(q);

    q = SqlPrepareQueryCampaign("danse_macabre",
        "UPDATE mac_proximity SET char_name = @name, last_updated = strftime('%s','now')"
        " WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlStep(q);
}

int MacGetProximity(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("danse_macabre",
        "SELECT proximity FROM mac_proximity WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void MacSetProximity(object oPC, int nProximity)
{
    if(nProximity < 0)   nProximity = 0;
    if(nProximity > 100) nProximity = 100;

    sqlquery q = SqlPrepareQueryCampaign("danse_macabre",
        "UPDATE mac_proximity SET proximity = @prox, last_updated = strftime('%s','now')"
        " WHERE uuid = @uuid");
    SqlBindInt   (q, "@prox", nProximity);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void MacAddProximity(object oPC, int nAmount)
{
    int nCurrent = MacGetProximity(oPC);
    MacSetProximity(oPC, nCurrent + nAmount);
}

void MacLogOmen(object oPC, string sText, int nProximity)
{
    sqlquery q = SqlPrepareQueryCampaign("danse_macabre",
        "INSERT INTO mac_omens (uuid, omen_text, proximity_at, seen_at)"
        " VALUES (@uuid, @text, @prox, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@text", sText);
    SqlBindInt   (q, "@prox", nProximity);
    SqlStep(q);

    // Keep only the last 10 omens per player
    q = SqlPrepareQueryCampaign("danse_macabre",
        "DELETE FROM mac_omens WHERE uuid = @uuid AND id NOT IN ("
        " SELECT id FROM mac_omens WHERE uuid = @uuid ORDER BY seen_at DESC LIMIT 10)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

json MacGetRecentOmens(object oPC, int nLimit)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("danse_macabre",
        "SELECT omen_text, proximity_at FROM mac_omens"
        " WHERE uuid = @uuid ORDER BY seen_at DESC LIMIT @lim");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@lim",  nLimit);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "text", JsonString(SqlGetString(q, 0)));
        jRow = JsonObjectSet(jRow, "prox", JsonInt   (SqlGetInt   (q, 1)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

void MacLogContract(object oPC, int nType, string sSacrifice, int nBefore, int nAfter)
{
    sqlquery q = SqlPrepareQueryCampaign("danse_macabre",
        "INSERT INTO mac_contracts"
        " (uuid, char_name, contract_type, sacrifice_desc, proximity_before, proximity_after, made_at)"
        " VALUES (@uuid, @name, @type, @sac, @before, @after, strftime('%s','now'))");
    SqlBindString(q, "@uuid",   GetObjectUUID(oPC));
    SqlBindString(q, "@name",   GetName(oPC));
    SqlBindInt   (q, "@type",   nType);
    SqlBindString(q, "@sac",    sSacrifice);
    SqlBindInt   (q, "@before", nBefore);
    SqlBindInt   (q, "@after",  nAfter);
    SqlStep(q);
}

json MacGetContracts(object oPC, int nLimit)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("danse_macabre",
        "SELECT contract_type, sacrifice_desc, proximity_before, proximity_after, made_at"
        " FROM mac_contracts WHERE uuid = @uuid ORDER BY made_at DESC LIMIT @lim");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@lim",  nLimit);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "type",   JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "sac",    JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "before", JsonInt   (SqlGetInt   (q, 2)));
        jRow = JsonObjectSet(jRow, "after",  JsonInt   (SqlGetInt   (q, 3)));
        jRow = JsonObjectSet(jRow, "at",     JsonInt   (SqlGetInt   (q, 4)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

int MacGetContractCount(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("danse_macabre",
        "SELECT COUNT(*) FROM mac_contracts WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

string MacFormatDate(int nUnix)
{
    sqlquery q = SqlPrepareQueryCampaign("danse_macabre",
        "SELECT strftime('%d.%m', @ts, 'unixepoch')");
    SqlBindInt(q, "@ts", nUnix);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "";
}

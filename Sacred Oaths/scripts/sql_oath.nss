// sql_oath.nss — DB schema and queries for Sacred Oaths

void OathCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("oaths",
        "CREATE TABLE IF NOT EXISTS oaths ("
        "uuid TEXT PRIMARY KEY, "
        "oath_id INTEGER DEFAULT 0, "
        "sworn_at INTEGER DEFAULT 0, "
        "violations INTEGER DEFAULT 0, "
        "is_broken INTEGER DEFAULT 0)");
    SqlStep(q);
}

int OathGetActive(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("oaths",
        "SELECT oath_id FROM oaths WHERE uuid=@u AND is_broken=0 AND oath_id>0");
    SqlBindString(q, "@u", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int OathIsBroken(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("oaths",
        "SELECT is_broken FROM oaths WHERE uuid=@u");
    SqlBindString(q, "@u", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int OathGetViolations(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("oaths",
        "SELECT violations FROM oaths WHERE uuid=@u");
    SqlBindString(q, "@u", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int OathGetSwornAt(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("oaths",
        "SELECT sworn_at FROM oaths WHERE uuid=@u");
    SqlBindString(q, "@u", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void OathDbSwear(object oPC, int nOathId)
{
    sqlquery q = SqlPrepareQueryCampaign("oaths",
        "INSERT OR REPLACE INTO oaths "
        "(uuid, oath_id, sworn_at, violations, is_broken) "
        "VALUES (@u, @id, strftime('%s','now'), 0, 0)");
    SqlBindString(q, "@u",  GetObjectUUID(oPC));
    SqlBindInt   (q, "@id", nOathId);
    SqlStep(q);
}

void OathDbViolation(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("oaths",
        "UPDATE oaths SET violations=violations+1 WHERE uuid=@u");
    SqlBindString(q, "@u", GetObjectUUID(oPC));
    SqlStep(q);
}

void OathDbMarkBroken(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("oaths",
        "UPDATE oaths SET is_broken=1 WHERE uuid=@u");
    SqlBindString(q, "@u", GetObjectUUID(oPC));
    SqlStep(q);
}

// Clears the broken record so PC can take a new oath after atonement
void OathDbClear(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("oaths",
        "DELETE FROM oaths WHERE uuid=@u");
    SqlBindString(q, "@u", GetObjectUUID(oPC));
    SqlStep(q);
}

// Returns elapsed days as a string (SQLite handles the arithmetic)
string OathDaysSince(int nUnix)
{
    if(nUnix <= 0) return "0";
    sqlquery q = SqlPrepareQueryCampaign("oaths",
        "SELECT CAST((strftime('%s','now') - @ts) / 86400 AS INTEGER)");
    SqlBindInt(q, "@ts", nUnix);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "0";
}

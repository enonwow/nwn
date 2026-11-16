// sql_bld.nss — persistent storage for the Bloodline module

void BldCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("bloodline",
        "CREATE TABLE IF NOT EXISTS bld_chars ("
        " uuid         TEXT PRIMARY KEY,"
        " bloodline_type INTEGER DEFAULT -1,"
        " purity        INTEGER DEFAULT 0,"
        " last_ritual   INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

void BldEnsureRecord(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("bloodline",
        "INSERT OR IGNORE INTO bld_chars (uuid) VALUES (@uuid)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

int BldGetBloodlineType(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("bloodline",
        "SELECT bloodline_type FROM bld_chars WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return -1;
}

int BldGetPurity(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("bloodline",
        "SELECT purity FROM bld_chars WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int BldGetLastRitual(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("bloodline",
        "SELECT last_ritual FROM bld_chars WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void BldSetBloodlineType(object oPC, int nType)
{
    sqlquery q = SqlPrepareQueryCampaign("bloodline",
        "UPDATE bld_chars SET bloodline_type = @type WHERE uuid = @uuid");
    SqlBindInt   (q, "@type", nType);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void BldSetPurity(object oPC, int nPurity)
{
    sqlquery q = SqlPrepareQueryCampaign("bloodline",
        "UPDATE bld_chars SET purity = @purity WHERE uuid = @uuid");
    SqlBindInt   (q, "@purity", nPurity);
    SqlBindString(q, "@uuid",   GetObjectUUID(oPC));
    SqlStep(q);
}

void BldSetLastRitual(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("bloodline",
        "UPDATE bld_chars SET last_ritual = strftime('%s','now') WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

int BldGetCurrentTimestamp()
{
    sqlquery q = SqlPrepareQueryCampaign("bloodline", "SELECT strftime('%s','now')");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

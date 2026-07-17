void NitCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("nit",
        "CREATE TABLE IF NOT EXISTS nit_chars ("
        "  uuid        TEXT PRIMARY KEY,"
        "  thread_val  INTEGER NOT NULL DEFAULT 100"
        ")");
    SqlStep(q);
}

void NitPersist(object oPC, int nVal)
{
    sqlquery q = SqlPrepareQueryCampaign("nit",
        "INSERT OR REPLACE INTO nit_chars (uuid, thread_val)"
        " VALUES (@uuid, @val)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@val",  nVal);
    SqlStep(q);
}

int NitLoad(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("nit",
        "SELECT thread_val FROM nit_chars WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 100;
}

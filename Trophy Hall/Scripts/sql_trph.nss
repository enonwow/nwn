// sql_trph.nss — Trophy Hall: SQLite schema + queries
// Campaign DB name: "trph"

void TrphCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("trph",
        "CREATE TABLE IF NOT EXISTS trph_records ("
        "  pc_uuid       TEXT NOT NULL,"
        "  pc_name       TEXT NOT NULL DEFAULT '',"
        "  cat_id        INTEGER NOT NULL,"
        "  deposited     INTEGER NOT NULL DEFAULT 0,"
        "  crafted_minor INTEGER NOT NULL DEFAULT 0,"
        "  crafted_major INTEGER NOT NULL DEFAULT 0,"
        "  PRIMARY KEY (pc_uuid, cat_id)"
        ")");
    SqlStep(q);
}

// Inserts a row for each category if it doesn't exist; updates name.
void TrphRegisterPlayer(object oPC)
{
    string sUuid = GetObjectUUID(oPC);
    string sName = GetName(oPC);
    int i;
    for(i = 0; i < 6; i++)
    {
        sqlquery qIns = SqlPrepareQueryCampaign("trph",
            "INSERT OR IGNORE INTO trph_records (pc_uuid, pc_name, cat_id) "
            "VALUES (@uuid, @name, @cat)");
        SqlBindString(qIns, "@uuid", sUuid);
        SqlBindString(qIns, "@name", sName);
        SqlBindInt   (qIns, "@cat",  i);
        SqlStep(qIns);

        sqlquery qUpd = SqlPrepareQueryCampaign("trph",
            "UPDATE trph_records SET pc_name = @name "
            "WHERE pc_uuid = @uuid AND cat_id = @cat");
        SqlBindString(qUpd, "@name", sName);
        SqlBindString(qUpd, "@uuid", sUuid);
        SqlBindInt   (qUpd, "@cat",  i);
        SqlStep(qUpd);
    }
}

void TrphAddDeposit(object oPC, int nCat, int nAmount)
{
    sqlquery q = SqlPrepareQueryCampaign("trph",
        "UPDATE trph_records SET deposited = deposited + @amt "
        "WHERE pc_uuid = @uuid AND cat_id = @cat");
    SqlBindInt   (q, "@amt",  nAmount);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@cat",  nCat);
    SqlStep(q);
}

void TrphAddCraftedMinor(object oPC, int nCat)
{
    sqlquery q = SqlPrepareQueryCampaign("trph",
        "UPDATE trph_records SET crafted_minor = crafted_minor + 1 "
        "WHERE pc_uuid = @uuid AND cat_id = @cat");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@cat",  nCat);
    SqlStep(q);
}

void TrphAddCraftedMajor(object oPC, int nCat)
{
    sqlquery q = SqlPrepareQueryCampaign("trph",
        "UPDATE trph_records SET crafted_major = crafted_major + 1 "
        "WHERE pc_uuid = @uuid AND cat_id = @cat");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@cat",  nCat);
    SqlStep(q);
}

int TrphGetDeposited(object oPC, int nCat)
{
    sqlquery q = SqlPrepareQueryCampaign("trph",
        "SELECT deposited FROM trph_records "
        "WHERE pc_uuid = @uuid AND cat_id = @cat");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@cat",  nCat);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int TrphGetCraftedMinor(object oPC, int nCat)
{
    sqlquery q = SqlPrepareQueryCampaign("trph",
        "SELECT crafted_minor FROM trph_records "
        "WHERE pc_uuid = @uuid AND cat_id = @cat");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@cat",  nCat);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int TrphGetCraftedMajor(object oPC, int nCat)
{
    sqlquery q = SqlPrepareQueryCampaign("trph",
        "SELECT crafted_major FROM trph_records "
        "WHERE pc_uuid = @uuid AND cat_id = @cat");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@cat",  nCat);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Available = deposited - (minor_crafted * 5) - (major_crafted * 15)
int TrphGetAvailable(object oPC, int nCat)
{
    sqlquery q = SqlPrepareQueryCampaign("trph",
        "SELECT deposited - (crafted_minor * 5) - (crafted_major * 15) "
        "FROM trph_records WHERE pc_uuid = @uuid AND cat_id = @cat");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@cat",  nCat);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns JsonArray [{pc_name, deposited}], sorted desc, up to 5 rows.
json TrphGetLeaderboard(int nCat)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("trph",
        "SELECT pc_name, deposited FROM trph_records "
        "WHERE cat_id = @cat AND deposited > 0 "
        "ORDER BY deposited DESC LIMIT 5");
    SqlBindInt(q, "@cat", nCat);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "pc_name",   JsonString(SqlGetString(q, 0)));
        jRow = JsonObjectSet(jRow, "deposited", JsonInt   (SqlGetInt   (q, 1)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

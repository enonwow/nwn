void MrkCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("mrk",
        "CREATE TABLE IF NOT EXISTS mrk_data ("
        " uuid TEXT PRIMARY KEY,"
        " beast INTEGER DEFAULT 0,"
        " undead INTEGER DEFAULT 0,"
        " elemental INTEGER DEFAULT 0,"
        " infernal INTEGER DEFAULT 0,"
        " fey INTEGER DEFAULT 0,"
        " beast_total INTEGER DEFAULT 0,"
        " undead_total INTEGER DEFAULT 0,"
        " elemental_total INTEGER DEFAULT 0,"
        " infernal_total INTEGER DEFAULT 0,"
        " fey_total INTEGER DEFAULT 0,"
        " brands INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

// Returns JsonObject: {beast, undead, elemental, infernal, fey, beast_total, ..., brands}
// Returns JSON_NULL if no row yet.
json MrkLoadData(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("mrk",
        "SELECT beast,undead,elemental,infernal,fey,"
        "beast_total,undead_total,elemental_total,infernal_total,fey_total,brands"
        " FROM mrk_data WHERE uuid=@uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(!SqlStep(q)) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "beast",          JsonInt(SqlGetInt(q, 0)));
    j = JsonObjectSet(j, "undead",         JsonInt(SqlGetInt(q, 1)));
    j = JsonObjectSet(j, "elemental",      JsonInt(SqlGetInt(q, 2)));
    j = JsonObjectSet(j, "infernal",       JsonInt(SqlGetInt(q, 3)));
    j = JsonObjectSet(j, "fey",            JsonInt(SqlGetInt(q, 4)));
    j = JsonObjectSet(j, "beast_total",    JsonInt(SqlGetInt(q, 5)));
    j = JsonObjectSet(j, "undead_total",   JsonInt(SqlGetInt(q, 6)));
    j = JsonObjectSet(j, "elemental_total",JsonInt(SqlGetInt(q, 7)));
    j = JsonObjectSet(j, "infernal_total", JsonInt(SqlGetInt(q, 8)));
    j = JsonObjectSet(j, "fey_total",      JsonInt(SqlGetInt(q, 9)));
    j = JsonObjectSet(j, "brands",         JsonInt(SqlGetInt(q, 10)));
    return j;
}

json MrkEnsureData(object oPC)
{
    json j = MrkLoadData(oPC);
    if(JsonGetType(j) != JSON_TYPE_NULL) return j;

    sqlquery q = SqlPrepareQueryCampaign("mrk",
        "INSERT OR IGNORE INTO mrk_data (uuid) VALUES (@uuid)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
    return MrkLoadData(oPC);
}

void MrkSaveEssence(object oPC, int nType, int nAmount, int nTotal, int nBrands)
{
    string sCol;
    string sTotalCol;
    switch(nType)
    {
        case 0: sCol = "beast";     sTotalCol = "beast_total";     break;
        case 1: sCol = "undead";    sTotalCol = "undead_total";    break;
        case 2: sCol = "elemental"; sTotalCol = "elemental_total"; break;
        case 3: sCol = "infernal";  sTotalCol = "infernal_total";  break;
        case 4: sCol = "fey";       sTotalCol = "fey_total";       break;
        default: return;
    }
    sqlquery q = SqlPrepareQueryCampaign("mrk",
        "UPDATE mrk_data SET " + sCol + "=@amount, " + sTotalCol + "=@total, brands=@brands"
        " WHERE uuid=@uuid");
    SqlBindInt   (q, "@amount", nAmount);
    SqlBindInt   (q, "@total",  nTotal);
    SqlBindInt   (q, "@brands", nBrands);
    SqlBindString(q, "@uuid",   GetObjectUUID(oPC));
    SqlStep(q);
}

void MrkSaveBrands(object oPC, int nBrands)
{
    sqlquery q = SqlPrepareQueryCampaign("mrk",
        "UPDATE mrk_data SET brands=@brands WHERE uuid=@uuid");
    SqlBindInt   (q, "@brands", nBrands);
    SqlBindString(q, "@uuid",   GetObjectUUID(oPC));
    SqlStep(q);
}

int MrkGetBrands(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("mrk",
        "SELECT brands FROM mrk_data WHERE uuid=@uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Persistent storage for the Miasma system.
// All area records live in campaign DB "miasma" so they survive server restarts.
// Player exposure is kept as local variables only — it resets on relog by design.

void MiaCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("miasma",
        "CREATE TABLE IF NOT EXISTS mia_areas ("
        "  area_tag  TEXT PRIMARY KEY,"
        "  intensity INTEGER DEFAULT 1,"
        "  mia_type  INTEGER DEFAULT 1"
        ")");
    SqlStep(q);
}

void MiaSetArea(string sTag, int nIntensity, int nType)
{
    sqlquery q = SqlPrepareQueryCampaign("miasma",
        "INSERT OR REPLACE INTO mia_areas (area_tag, intensity, mia_type)"
        " VALUES (@tag, @intensity, @type)");
    SqlBindString(q, "@tag",       sTag);
    SqlBindInt(q,    "@intensity", nIntensity);
    SqlBindInt(q,    "@type",      nType);
    SqlStep(q);
}

void MiaClearArea(string sTag)
{
    sqlquery q = SqlPrepareQueryCampaign("miasma",
        "DELETE FROM mia_areas WHERE area_tag = @tag");
    SqlBindString(q, "@tag", sTag);
    SqlStep(q);
}

// Returns object with intensity + mia_type, or intensity=0 when area is clean.
json MiaGetAreaData(string sTag)
{
    sqlquery q = SqlPrepareQueryCampaign("miasma",
        "SELECT intensity, mia_type FROM mia_areas WHERE area_tag = @tag");
    SqlBindString(q, "@tag", sTag);
    if(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "intensity", JsonInt(SqlGetInt(q, 0)));
        j = JsonObjectSet(j, "mia_type",  JsonInt(SqlGetInt(q, 1)));
        return j;
    }
    json j = JsonObject();
    j = JsonObjectSet(j, "intensity", JsonInt(0));
    j = JsonObjectSet(j, "mia_type",  JsonInt(0));
    return j;
}

// Returns all tainted areas as a JsonArray for the DM panel list.
json MiaGetAllAreas()
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("miasma",
        "SELECT area_tag, intensity, mia_type FROM mia_areas ORDER BY intensity DESC");
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "area_tag",  JsonString(SqlGetString(q, 0)));
        j = JsonObjectSet(j, "intensity", JsonInt(SqlGetInt(q, 1)));
        j = JsonObjectSet(j, "mia_type",  JsonInt(SqlGetInt(q, 2)));
        jRows = JsonArrayInsert(jRows, j);
    }
    return jRows;
}

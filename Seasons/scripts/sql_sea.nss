void SeaCreateTables()
{
    sqlquery q;

    q = SqlPrepareQueryCampaign("seasons",
        "CREATE TABLE IF NOT EXISTS sea_state ("
        "  id              INTEGER PRIMARY KEY,"
        "  season          INTEGER DEFAULT 0,"
        "  weather         INTEGER DEFAULT 0,"
        "  season_changed  INTEGER DEFAULT 0,"
        "  weather_changed INTEGER DEFAULT 0)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("seasons",
        "CREATE TABLE IF NOT EXISTS sea_areas ("
        "  area_tag TEXT PRIMARY KEY,"
        "  climate  INTEGER DEFAULT 0)");
    SqlStep(q);

    // Seed single state row if absent
    q = SqlPrepareQueryCampaign("seasons",
        "INSERT OR IGNORE INTO sea_state "
        "(id, season, weather, season_changed, weather_changed) "
        "VALUES (1, 0, 0, 0, 0)");
    SqlStep(q);
}

json SeaGetStateRow()
{
    sqlquery q = SqlPrepareQueryCampaign("seasons",
        "SELECT season, weather, season_changed, weather_changed "
        "FROM sea_state WHERE id = 1");
    if (!SqlStep(q)) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "season",          JsonInt(SqlGetInt(q, 0)));
    j = JsonObjectSet(j, "weather",         JsonInt(SqlGetInt(q, 1)));
    j = JsonObjectSet(j, "season_changed",  JsonInt(SqlGetInt(q, 2)));
    j = JsonObjectSet(j, "weather_changed", JsonInt(SqlGetInt(q, 3)));
    return j;
}

void SeaSetSeason(int nSeason)
{
    sqlquery q = SqlPrepareQueryCampaign("seasons",
        "UPDATE sea_state SET season = @s, season_changed = strftime('%s','now') WHERE id = 1");
    SqlBindInt(q, "@s", nSeason);
    SqlStep(q);
}

void SeaSetWeather(int nWeather)
{
    sqlquery q = SqlPrepareQueryCampaign("seasons",
        "UPDATE sea_state SET weather = @w, weather_changed = strftime('%s','now') WHERE id = 1");
    SqlBindInt(q, "@w", nWeather);
    SqlStep(q);
}

void SeaSetState(int nSeason, int nWeather)
{
    sqlquery q = SqlPrepareQueryCampaign("seasons",
        "UPDATE sea_state "
        "SET season = @s, weather = @w, "
        "    season_changed = strftime('%s','now'), "
        "    weather_changed = strftime('%s','now') "
        "WHERE id = 1");
    SqlBindInt(q, "@s", nSeason);
    SqlBindInt(q, "@w", nWeather);
    SqlStep(q);
}

int SeaGetAreaClimate(string sAreaTag)
{
    sqlquery q = SqlPrepareQueryCampaign("seasons",
        "SELECT climate FROM sea_areas WHERE area_tag = @tag");
    SqlBindString(q, "@tag", sAreaTag);
    if (SqlStep(q)) return SqlGetInt(q, 0);
    return 0; // SEA_CLIMATE_TEMPERATE
}

void SeaSetAreaClimate(string sAreaTag, int nClimate)
{
    sqlquery q = SqlPrepareQueryCampaign("seasons",
        "INSERT OR REPLACE INTO sea_areas (area_tag, climate) VALUES (@tag, @c)");
    SqlBindString(q, "@tag", sAreaTag);
    SqlBindInt(q, "@c",  nClimate);
    SqlStep(q);
}

// Returns current Unix timestamp via SQLite (avoids NWScript date arithmetic)
int SeaGetNow()
{
    sqlquery q = SqlPrepareQueryCampaign("seasons", "SELECT strftime('%s','now')");
    if (SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

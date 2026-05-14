// sql_rit.nss - Ritual Circles: SQLite DB layer
// Campaign DB: "ritual"
// Table: rit_circles — one row per circle placeable (identified by its tag)

const string RIT_DB = "ritual";

void RitCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign(RIT_DB,
        "CREATE TABLE IF NOT EXISTS rit_circles ("
        " tag TEXT PRIMARY KEY,"
        " ritual_type INTEGER DEFAULT 0,"
        " state INTEGER DEFAULT 0,"
        " leader_uuid TEXT DEFAULT '',"
        " participants_json TEXT DEFAULT '[]',"
        " cast_start INTEGER DEFAULT 0,"
        " cooldown_end INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

// Ensures a row exists for the given tag (idempotent).
void RitEnsureCircle(string sTag)
{
    sqlquery q = SqlPrepareQueryCampaign(RIT_DB,
        "INSERT OR IGNORE INTO rit_circles (tag) VALUES (@tag)");
    SqlBindString(q, "@tag", sTag);
    SqlStep(q);
}

// Returns a JsonObject with all circle fields, or JsonNull if not found.
json RitGetCircle(string sTag)
{
    RitEnsureCircle(sTag);
    sqlquery q = SqlPrepareQueryCampaign(RIT_DB,
        "SELECT ritual_type, state, leader_uuid, participants_json, cast_start, cooldown_end"
        " FROM rit_circles WHERE tag = @tag");
    SqlBindString(q, "@tag", sTag);
    if(!SqlStep(q)) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "ritual_type",       JsonInt   (SqlGetInt   (q, 0)));
    j = JsonObjectSet(j, "state",             JsonInt   (SqlGetInt   (q, 1)));
    j = JsonObjectSet(j, "leader_uuid",       JsonString(SqlGetString(q, 2)));
    j = JsonObjectSet(j, "participants_json", JsonString(SqlGetString(q, 3)));
    j = JsonObjectSet(j, "cast_start",        JsonInt   (SqlGetInt   (q, 4)));
    j = JsonObjectSet(j, "cooldown_end",      JsonInt   (SqlGetInt   (q, 5)));
    return j;
}

// Writes all circle fields back to DB (REPLACE semantics).
void RitSetCircle(string sTag, json jData)
{
    sqlquery q = SqlPrepareQueryCampaign(RIT_DB,
        "INSERT OR REPLACE INTO rit_circles"
        " (tag, ritual_type, state, leader_uuid, participants_json, cast_start, cooldown_end)"
        " VALUES (@tag, @type, @state, @leader, @parts, @start, @cd)");
    SqlBindString(q, "@tag",    sTag);
    SqlBindInt   (q, "@type",   JsonGetInt   (JsonObjectGet(jData, "ritual_type")));
    SqlBindInt   (q, "@state",  JsonGetInt   (JsonObjectGet(jData, "state")));
    SqlBindString(q, "@leader", JsonGetString(JsonObjectGet(jData, "leader_uuid")));
    SqlBindString(q, "@parts",  JsonGetString(JsonObjectGet(jData, "participants_json")));
    SqlBindInt   (q, "@start",  JsonGetInt   (JsonObjectGet(jData, "cast_start")));
    SqlBindInt   (q, "@cd",     JsonGetInt   (JsonObjectGet(jData, "cooldown_end")));
    SqlStep(q);
}

// Resets a circle to idle/empty state.
void RitResetCircle(string sTag)
{
    sqlquery q = SqlPrepareQueryCampaign(RIT_DB,
        "UPDATE rit_circles"
        " SET ritual_type=0, state=0, leader_uuid='', participants_json='[]',"
        "     cast_start=0, cooldown_end=0"
        " WHERE tag = @tag");
    SqlBindString(q, "@tag", sTag);
    SqlStep(q);
}

// Returns JsonArray of {tag, ritual_type, cast_start} for circles in CASTING state.
json RitGetActiveCastingCircles()
{
    json jList = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(RIT_DB,
        "SELECT tag, ritual_type, participants_json, cast_start FROM rit_circles WHERE state = 2");
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "tag",               JsonString(SqlGetString(q, 0)));
        j = JsonObjectSet(j, "ritual_type",        JsonInt   (SqlGetInt   (q, 1)));
        j = JsonObjectSet(j, "participants_json",  JsonString(SqlGetString(q, 2)));
        j = JsonObjectSet(j, "cast_start",         JsonInt   (SqlGetInt   (q, 3)));
        jList = JsonArrayInsert(jList, j);
    }
    return jList;
}

// Returns JsonArray of {tag, cooldown_end} for circles in COOLDOWN state.
json RitGetCooldownCircles()
{
    json jList = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(RIT_DB,
        "SELECT tag, cooldown_end FROM rit_circles WHERE state = 3");
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "tag",          JsonString(SqlGetString(q, 0)));
        j = JsonObjectSet(j, "cooldown_end", JsonInt   (SqlGetInt   (q, 1)));
        jList = JsonArrayInsert(jList, j);
    }
    return jList;
}

// Current unix timestamp via SQLite (matches server clock for interval math).
int RitGetUnixTime()
{
    sqlquery q = SqlPrepareQueryCampaign(RIT_DB, "SELECT strftime('%s','now')");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void HaruCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("haruspicy",
        "CREATE TABLE IF NOT EXISTS haru_readings ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "pc_uuid TEXT NOT NULL,"
        "creature_name TEXT DEFAULT '',"
        "creature_type INTEGER DEFAULT 0,"
        "creature_cr INTEGER DEFAULT 0,"
        "signs_json TEXT DEFAULT '[]',"
        "score INTEGER DEFAULT 0,"
        "prophecy_text TEXT DEFAULT '',"
        "effect_id INTEGER DEFAULT 0,"
        "read_at INTEGER DEFAULT 0)");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("haruspicy",
        "CREATE TABLE IF NOT EXISTS haru_mastery ("
        "pc_uuid TEXT PRIMARY KEY,"
        "total_readings INTEGER DEFAULT 0,"
        "auspicious_count INTEGER DEFAULT 0,"
        "inauspicious_count INTEGER DEFAULT 0)");
    SqlStep(q);
}

void HaruSaveReading(object oPC, string sCreatureName, int nCreatureType,
    int nCR, json jSigns, int nScore, string sProphecy, int nEffectId)
{
    sqlquery q = SqlPrepareQueryCampaign("haruspicy",
        "INSERT INTO haru_readings "
        "(pc_uuid, creature_name, creature_type, creature_cr, signs_json, "
        "score, prophecy_text, effect_id, read_at) "
        "VALUES (@uuid, @cname, @ctype, @cr, @signs, @score, @proph, @eff, strftime('%s','now'))");
    SqlBindString(q, "@uuid",  GetObjectUUID(oPC));
    SqlBindString(q, "@cname", sCreatureName);
    SqlBindInt   (q, "@ctype", nCreatureType);
    SqlBindInt   (q, "@cr",    nCR);
    SqlBindString(q, "@signs", JsonDump(jSigns));
    SqlBindInt   (q, "@score", nScore);
    SqlBindString(q, "@proph", sProphecy);
    SqlBindInt   (q, "@eff",   nEffectId);
    SqlStep(q);
}

void HaruIncrementMastery(object oPC, int nScore)
{
    int nAusp  = (nScore > 0) ? 1 : 0;
    int nInasp = (nScore < 0) ? 1 : 0;
    sqlquery q = SqlPrepareQueryCampaign("haruspicy",
        "INSERT INTO haru_mastery (pc_uuid, total_readings, auspicious_count, inauspicious_count) "
        "VALUES (@uuid, 1, @a, @i) "
        "ON CONFLICT(pc_uuid) DO UPDATE SET "
        "total_readings = total_readings + 1, "
        "auspicious_count = auspicious_count + @a, "
        "inauspicious_count = inauspicious_count + @i");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@a",    nAusp);
    SqlBindInt   (q, "@i",    nInasp);
    SqlStep(q);
}

int HaruGetTotalReadings(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("haruspicy",
        "SELECT total_readings FROM haru_mastery WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns up to nLimit most recent readings as a JsonArray:
// [{creature_name, score, prophecy_text, read_at}, ...]
json HaruGetHistory(object oPC, int nLimit)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("haruspicy",
        "SELECT creature_name, score, prophecy_text, read_at "
        "FROM haru_readings WHERE pc_uuid = @uuid "
        "ORDER BY read_at DESC LIMIT @lim");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@lim",  nLimit);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "creature_name",  JsonString(SqlGetString(q, 0)));
        jRow = JsonObjectSet(jRow, "score",          JsonInt   (SqlGetInt   (q, 1)));
        jRow = JsonObjectSet(jRow, "prophecy_text",  JsonString(SqlGetString(q, 2)));
        jRow = JsonObjectSet(jRow, "read_at",        JsonInt   (SqlGetInt   (q, 3)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

string HaruFormatDate(int nUnix)
{
    sqlquery q = SqlPrepareQueryCampaign("haruspicy",
        "SELECT strftime('%d.%m', @ts, 'unixepoch')");
    SqlBindInt(q, "@ts", nUnix);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "";
}

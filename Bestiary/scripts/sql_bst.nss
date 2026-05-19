// sql_bst.nss — SQLite schema and queries for Codex Bestiarum
// Campaign DB: "bestiary"

void BstCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("bestiary",
        "CREATE TABLE IF NOT EXISTS bst_knowledge ("
        "  char_uuid  TEXT    NOT NULL,"
        "  race_idx   INTEGER NOT NULL,"
        "  study_count INTEGER DEFAULT 0,"
        "  PRIMARY KEY (char_uuid, race_idx)"
        ")");
    SqlStep(q);
}

// Returns current study count for this PC + race index.
int BstGetKills(object oPC, int nRaceIdx)
{
    sqlquery q = SqlPrepareQueryCampaign("bestiary",
        "SELECT study_count FROM bst_knowledge"
        " WHERE char_uuid = @uuid AND race_idx = @race");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@race", nRaceIdx);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Increments study count for this PC + race by 1 (upsert).
void BstAddStudy(object oPC, int nRaceIdx)
{
    sqlquery q = SqlPrepareQueryCampaign("bestiary",
        "INSERT INTO bst_knowledge (char_uuid, race_idx, study_count)"
        " VALUES (@uuid, @race, 1)"
        " ON CONFLICT(char_uuid, race_idx)"
        " DO UPDATE SET study_count = study_count + 1");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@race", nRaceIdx);
    SqlStep(q);
}

// Returns a JsonArray of {race_idx, study_count} for all rows of this PC.
json BstGetAllKills(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("bestiary",
        "SELECT race_idx, study_count FROM bst_knowledge"
        " WHERE char_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "race_idx",    JsonInt(SqlGetInt(q, 0)));
        jRow = JsonObjectSet(jRow, "study_count", JsonInt(SqlGetInt(q, 1)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

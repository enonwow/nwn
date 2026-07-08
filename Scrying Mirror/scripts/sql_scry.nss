void ScryCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("scrying",
        "CREATE TABLE IF NOT EXISTS scry_mirrors (id INTEGER PRIMARY KEY AUTOINCREMENT, mirror_name TEXT NOT NULL DEFAULT '', area_tag TEXT NOT NULL DEFAULT '', area_name TEXT NOT NULL DEFAULT '', note TEXT DEFAULT '', attuner_name TEXT NOT NULL DEFAULT '', attuner_uuid TEXT NOT NULL DEFAULT '', created_at INTEGER DEFAULT 0, is_active INTEGER DEFAULT 1)");
    SqlStep(q);
}

int ScryAddMirror(object oPC, string sMirrorName, string sNote)
{
    string sAreaTag  = GetTag(GetArea(oPC));
    string sAreaName = GetName(GetArea(oPC));

    sqlquery q = SqlPrepareQueryCampaign("scrying",
        "INSERT INTO scry_mirrors (mirror_name, area_tag, area_name, note, attuner_name, attuner_uuid, created_at) VALUES (@name, @area_tag, @area_name, @note, @attuner_name, @attuner_uuid, strftime('%s','now'))");
    SqlBindString(q, "@name",         sMirrorName);
    SqlBindString(q, "@area_tag",     sAreaTag);
    SqlBindString(q, "@area_name",    sAreaName);
    SqlBindString(q, "@note",         sNote);
    SqlBindString(q, "@attuner_name", GetName(oPC));
    SqlBindString(q, "@attuner_uuid", GetObjectUUID(oPC));
    SqlStep(q);

    sqlquery qId = SqlPrepareQueryCampaign("scrying", "SELECT last_insert_rowid()");
    if(SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

void ScryDeactivateMirror(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("scrying",
        "UPDATE scry_mirrors SET is_active = 0 WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

int ScryGetActiveMirrorCount()
{
    sqlquery q = SqlPrepareQueryCampaign("scrying",
        "SELECT COUNT(*) FROM scry_mirrors WHERE is_active = 1");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

json ScryGetMirrors()
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("scrying",
        "SELECT id, mirror_name, area_tag, area_name, note, attuner_name, created_at FROM scry_mirrors WHERE is_active = 1 ORDER BY created_at ASC");
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",           JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "mirror_name",  JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "area_tag",     JsonString(SqlGetString(q, 2)));
        jRow = JsonObjectSet(jRow, "area_name",    JsonString(SqlGetString(q, 3)));
        jRow = JsonObjectSet(jRow, "note",         JsonString(SqlGetString(q, 4)));
        jRow = JsonObjectSet(jRow, "attuner_name", JsonString(SqlGetString(q, 5)));
        jRow = JsonObjectSet(jRow, "created_at",   JsonInt   (SqlGetInt   (q, 6)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

json ScryGetMirrorById(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("scrying",
        "SELECT id, mirror_name, area_tag, area_name, note, attuner_name, attuner_uuid FROM scry_mirrors WHERE id = @id AND is_active = 1");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();

    json jRow = JsonObject();
    jRow = JsonObjectSet(jRow, "id",           JsonInt   (SqlGetInt   (q, 0)));
    jRow = JsonObjectSet(jRow, "mirror_name",  JsonString(SqlGetString(q, 1)));
    jRow = JsonObjectSet(jRow, "area_tag",     JsonString(SqlGetString(q, 2)));
    jRow = JsonObjectSet(jRow, "area_name",    JsonString(SqlGetString(q, 3)));
    jRow = JsonObjectSet(jRow, "note",         JsonString(SqlGetString(q, 4)));
    jRow = JsonObjectSet(jRow, "attuner_name", JsonString(SqlGetString(q, 5)));
    jRow = JsonObjectSet(jRow, "attuner_uuid", JsonString(SqlGetString(q, 6)));
    return jRow;
}

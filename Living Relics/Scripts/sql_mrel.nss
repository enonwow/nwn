// SQL layer for Living Relics.
// Campaign DB name: "mrel"
// All relics stored per PC UUID, per slot (1-3).

void MrelCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("mrel",
        "CREATE TABLE IF NOT EXISTS mrel_relics ("
        " id INTEGER PRIMARY KEY AUTOINCREMENT,"
        " pc_uuid TEXT NOT NULL,"
        " slot INTEGER NOT NULL,"
        " mrel_id TEXT NOT NULL,"
        " item_name TEXT NOT NULL DEFAULT '',"
        " item_basetype INTEGER NOT NULL DEFAULT 0,"
        " hunger INTEGER NOT NULL DEFAULT 1,"
        " memory INTEGER NOT NULL DEFAULT 0,"
        " visions_json TEXT NOT NULL DEFAULT '[]',"
        " attuned_at INTEGER NOT NULL DEFAULT 0,"
        " UNIQUE(pc_uuid, slot)"
        ")");
    SqlStep(q);
}

// Inserts or replaces a relic record (new attunement).
void MrelDbAttune(string sPcUuid, int nSlot, string sMrelId,
                  string sItemName, int nItemBasetype)
{
    sqlquery q = SqlPrepareQueryCampaign("mrel",
        "INSERT OR REPLACE INTO mrel_relics "
        "(pc_uuid, slot, mrel_id, item_name, item_basetype, hunger, memory, visions_json, attuned_at) "
        "VALUES (@uuid, @slot, @mid, @name, @type, 1, 0, '[]', strftime('%s','now'))");
    SqlBindString(q, "@uuid",  sPcUuid);
    SqlBindInt   (q, "@slot",  nSlot);
    SqlBindString(q, "@mid",   sMrelId);
    SqlBindString(q, "@name",  sItemName);
    SqlBindInt   (q, "@type",  nItemBasetype);
    SqlStep(q);
}

// Atomically updates hunger, memory, and vision history for a slot.
void MrelDbUpdateState(string sPcUuid, int nSlot,
                       int nHunger, int nMemory, string sVisionsJson)
{
    sqlquery q = SqlPrepareQueryCampaign("mrel",
        "UPDATE mrel_relics SET hunger=@hunger, memory=@memory, visions_json=@vis "
        "WHERE pc_uuid=@uuid AND slot=@slot");
    SqlBindInt   (q, "@hunger", nHunger);
    SqlBindInt   (q, "@memory", nMemory);
    SqlBindString(q, "@vis",    sVisionsJson);
    SqlBindString(q, "@uuid",   sPcUuid);
    SqlBindInt   (q, "@slot",   nSlot);
    SqlStep(q);
}

void MrelDbRemove(string sPcUuid, int nSlot)
{
    sqlquery q = SqlPrepareQueryCampaign("mrel",
        "DELETE FROM mrel_relics WHERE pc_uuid=@uuid AND slot=@slot");
    SqlBindString(q, "@uuid", sPcUuid);
    SqlBindInt   (q, "@slot", nSlot);
    SqlStep(q);
}

// Returns a JSON object for the relic in the given slot, or JSON_NULL if empty.
json MrelDbGetRelic(string sPcUuid, int nSlot)
{
    sqlquery q = SqlPrepareQueryCampaign("mrel",
        "SELECT mrel_id, item_name, item_basetype, hunger, memory, visions_json "
        "FROM mrel_relics WHERE pc_uuid=@uuid AND slot=@slot");
    SqlBindString(q, "@uuid", sPcUuid);
    SqlBindInt   (q, "@slot", nSlot);

    if(!SqlStep(q)) return JsonNull();

    json jRow = JsonObject();
    jRow = JsonObjectSet(jRow, "mrel_id",       JsonString(SqlGetString(q, 0)));
    jRow = JsonObjectSet(jRow, "item_name",     JsonString(SqlGetString(q, 1)));
    jRow = JsonObjectSet(jRow, "item_basetype", JsonInt   (SqlGetInt   (q, 2)));
    jRow = JsonObjectSet(jRow, "hunger",        JsonInt   (SqlGetInt   (q, 3)));
    jRow = JsonObjectSet(jRow, "memory",        JsonInt   (SqlGetInt   (q, 4)));
    jRow = JsonObjectSet(jRow, "visions_json",  JsonString(SqlGetString(q, 5)));
    return jRow;
}

// Returns a JsonArray of 3 entries (slot 1-3), each either an object or JSON_NULL.
json MrelDbGetAllRelics(string sPcUuid)
{
    json jAll = JsonArray();
    int i;
    for(i = 1; i <= 3; i++)
        jAll = JsonArrayInsert(jAll, MrelDbGetRelic(sPcUuid, i));
    return jAll;
}

// Appends a vision entry to the stored visions_json, capping at 5 entries.
// Returns the new visions_json string.
string MrelDbAppendVision(string sExistingJson, string sVisionText,
                          int nTrigger, int nHunger)
{
    json jArr = JsonParse(sExistingJson);
    if(JsonGetType(jArr) != JSON_TYPE_ARRAY)
        jArr = JsonArray();

    json jEntry = JsonObject();
    jEntry = JsonObjectSet(jEntry, "text",    JsonString(sVisionText));
    jEntry = JsonObjectSet(jEntry, "trigger", JsonInt(nTrigger));
    jEntry = JsonObjectSet(jEntry, "hunger",  JsonInt(nHunger));
    jArr   = JsonArrayInsert(jArr, jEntry);

    // Keep only the last 5 visions
    while(JsonGetLength(jArr) > 5)
        jArr = JsonArrayDel(jArr, 0);

    return JsonDump(jArr);
}

// Returns the most recent vision text from the visions_json string, or "" if none.
string MrelDbGetLastVision(string sVisionsJson)
{
    json jArr = JsonParse(sVisionsJson);
    if(JsonGetType(jArr) != JSON_TYPE_ARRAY || JsonGetLength(jArr) == 0)
        return "";
    int nLast = JsonGetLength(jArr) - 1;
    json jEntry = JsonArrayGet(jArr, nLast);
    return JsonGetString(JsonObjectGet(jEntry, "text"));
}

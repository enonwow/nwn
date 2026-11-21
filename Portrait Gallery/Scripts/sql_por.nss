// Portrait Gallery — SQL layer
// Campaign database name: "portraits"
// All queries use SqlPrepareQueryCampaign for server-wide persistence.

void PorCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("portraits",
        "CREATE TABLE IF NOT EXISTS por_portraits ("
        "  id           INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  owner_uuid   TEXT    NOT NULL UNIQUE,"
        "  owner_name   TEXT    NOT NULL DEFAULT '',"
        "  owner_class  TEXT    NOT NULL DEFAULT '',"
        "  owner_level  INTEGER NOT NULL DEFAULT 1,"
        "  owner_align  TEXT    NOT NULL DEFAULT '',"
        "  shadow_score INTEGER NOT NULL DEFAULT 0,"
        "  state        INTEGER NOT NULL DEFAULT 0,"
        "  motto        TEXT    NOT NULL DEFAULT '',"
        "  created_at   INTEGER NOT NULL DEFAULT 0,"
        "  last_buff_at INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);
}

int PorHasPortrait(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("portraits",
        "SELECT 1 FROM por_portraits WHERE owner_uuid = @uuid LIMIT 1");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    return SqlStep(q);
}

void PorCreatePortrait(object oPC, string sClass, string sAlign, string sMotto)
{
    sqlquery q = SqlPrepareQueryCampaign("portraits",
        "INSERT OR IGNORE INTO por_portraits"
        "  (owner_uuid, owner_name, owner_class, owner_level, owner_align, motto, created_at)"
        "  VALUES (@uuid, @name, @class, @level, @align, @motto, strftime('%s','now'))");
    SqlBindString(q, "@uuid",  GetObjectUUID(oPC));
    SqlBindString(q, "@name",  GetName(oPC));
    SqlBindString(q, "@class", sClass);
    SqlBindInt   (q, "@level", GetHitDice(oPC));
    SqlBindString(q, "@align", sAlign);
    SqlBindString(q, "@motto", sMotto);
    SqlStep(q);
}

json PorGetAll()
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("portraits",
        "SELECT id, owner_name, owner_class, owner_level, owner_align,"
        "  shadow_score, state, motto, created_at, last_buff_at, owner_uuid"
        "  FROM por_portraits ORDER BY created_at ASC");
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "id",           JsonInt   (SqlGetInt   (q, 0)));
        j = JsonObjectSet(j, "owner_name",   JsonString(SqlGetString(q, 1)));
        j = JsonObjectSet(j, "owner_class",  JsonString(SqlGetString(q, 2)));
        j = JsonObjectSet(j, "owner_level",  JsonInt   (SqlGetInt   (q, 3)));
        j = JsonObjectSet(j, "owner_align",  JsonString(SqlGetString(q, 4)));
        j = JsonObjectSet(j, "shadow_score", JsonInt   (SqlGetInt   (q, 5)));
        j = JsonObjectSet(j, "state",        JsonInt   (SqlGetInt   (q, 6)));
        j = JsonObjectSet(j, "motto",        JsonString(SqlGetString(q, 7)));
        j = JsonObjectSet(j, "created_at",   JsonInt   (SqlGetInt   (q, 8)));
        j = JsonObjectSet(j, "last_buff_at", JsonInt   (SqlGetInt   (q, 9)));
        j = JsonObjectSet(j, "owner_uuid",   JsonString(SqlGetString(q, 10)));
        jRows = JsonArrayInsert(jRows, j);
    }
    return jRows;
}

json PorGetById(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("portraits",
        "SELECT id, owner_name, owner_class, owner_level, owner_align,"
        "  shadow_score, state, motto, created_at, last_buff_at, owner_uuid"
        "  FROM por_portraits WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();
    json j = JsonObject();
    j = JsonObjectSet(j, "id",           JsonInt   (SqlGetInt   (q, 0)));
    j = JsonObjectSet(j, "owner_name",   JsonString(SqlGetString(q, 1)));
    j = JsonObjectSet(j, "owner_class",  JsonString(SqlGetString(q, 2)));
    j = JsonObjectSet(j, "owner_level",  JsonInt   (SqlGetInt   (q, 3)));
    j = JsonObjectSet(j, "owner_align",  JsonString(SqlGetString(q, 4)));
    j = JsonObjectSet(j, "shadow_score", JsonInt   (SqlGetInt   (q, 5)));
    j = JsonObjectSet(j, "state",        JsonInt   (SqlGetInt   (q, 6)));
    j = JsonObjectSet(j, "motto",        JsonString(SqlGetString(q, 7)));
    j = JsonObjectSet(j, "created_at",   JsonInt   (SqlGetInt   (q, 8)));
    j = JsonObjectSet(j, "last_buff_at", JsonInt   (SqlGetInt   (q, 9)));
    j = JsonObjectSet(j, "owner_uuid",   JsonString(SqlGetString(q, 10)));
    return j;
}

json PorGetByOwner(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("portraits",
        "SELECT id FROM por_portraits WHERE owner_uuid = @uuid LIMIT 1");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(!SqlStep(q)) return JsonNull();
    return PorGetById(SqlGetInt(q, 0));
}

// Public API — call from other scripts to darken a portrait after a dark deed.
// nAmount: 1–5 recommended; state=2 (memorial) portraits are immune to shadow gain.
void PorAddShadow(object oPC, int nAmount)
{
    sqlquery q = SqlPrepareQueryCampaign("portraits",
        "UPDATE por_portraits SET shadow_score = MIN(shadow_score + @n, 100)"
        "  WHERE owner_uuid = @uuid AND state != 2");
    SqlBindInt   (q, "@n",    nAmount);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void PorSetState(int nId, int nState)
{
    sqlquery q = SqlPrepareQueryCampaign("portraits",
        "UPDATE por_portraits SET state = @state WHERE id = @id");
    SqlBindInt(q, "@state", nState);
    SqlBindInt(q, "@id",    nId);
    SqlStep(q);
}

// Called from sys_on_death to seal a character's portrait as a memorial.
void PorMarkMemorial(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("portraits",
        "UPDATE por_portraits SET state = 2 WHERE owner_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void PorUpdateLastBuff(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("portraits",
        "UPDATE por_portraits SET last_buff_at = strftime('%s','now') WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

// Adds nAmount shadow to a portrait by its ID (DM use; owner may be offline).
void PorAddShadowById(int nId, int nAmount)
{
    sqlquery q = SqlPrepareQueryCampaign("portraits",
        "UPDATE por_portraits SET shadow_score = MIN(shadow_score + @n, 100)"
        "  WHERE id = @id AND state != 2");
    SqlBindInt(q, "@n",  nAmount);
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

// Returns 1 if the buff cooldown (3600 s) has passed since last use.
int PorBuffReady(int nLastBuffAt)
{
    sqlquery q = SqlPrepareQueryCampaign("portraits",
        "SELECT (strftime('%s','now') - @last) >= 3600");
    SqlBindInt(q, "@last", nLastBuffAt);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 1;
}

string PorFormatDate(int nUnix)
{
    sqlquery q = SqlPrepareQueryCampaign("portraits",
        "SELECT strftime('%d.%m.%Y', @ts, 'unixepoch')");
    SqlBindInt(q, "@ts", nUnix);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "??";
}

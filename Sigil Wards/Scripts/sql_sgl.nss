// Campaign DB identifier
const string SGL_DB = "sigil_wards";

// Default charge counts per sigil type
const int SGL_CHARGES_ALARM = 10;
const int SGL_CHARGES_SHOCK = 5;
const int SGL_CHARGES_HOLD  = 3;
const int SGL_CHARGES_FEAR  = 5;

void SglCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign(SGL_DB,
        "CREATE TABLE IF NOT EXISTS sgl_sigils ("
        "  id         INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  owner_uuid TEXT    NOT NULL,"
        "  owner_name TEXT    NOT NULL DEFAULT '',"
        "  area_tag   TEXT    NOT NULL DEFAULT '',"
        "  area_name  TEXT    NOT NULL DEFAULT '',"
        "  pos_x      REAL    NOT NULL DEFAULT 0.0,"
        "  pos_y      REAL    NOT NULL DEFAULT 0.0,"
        "  pos_z      REAL    NOT NULL DEFAULT 0.0,"
        "  sigil_type INTEGER NOT NULL DEFAULT 0,"
        "  charges    INTEGER NOT NULL DEFAULT 5,"
        "  placed_at  INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(SGL_DB,
        "CREATE TABLE IF NOT EXISTS sgl_attuned ("
        "  sigil_id      INTEGER NOT NULL,"
        "  attuned_uuid  TEXT    NOT NULL,"
        "  attuned_name  TEXT    NOT NULL DEFAULT '',"
        "  PRIMARY KEY (sigil_id, attuned_uuid)"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(SGL_DB,
        "CREATE TABLE IF NOT EXISTS sgl_players ("
        "  uuid TEXT PRIMARY KEY,"
        "  name TEXT NOT NULL DEFAULT ''"
        ")");
    SqlStep(q);
}

void SglRegisterPlayer(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(SGL_DB,
        "INSERT OR REPLACE INTO sgl_players (uuid, name) VALUES (@uuid, @name)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlStep(q);
}

// Returns id of inserted sigil or 0 on failure
int SglPlaceSigil(object oPC, string sAreaTag, string sAreaName,
                  float fX, float fY, float fZ, int nType, int nCharges)
{
    sqlquery q = SqlPrepareQueryCampaign(SGL_DB,
        "INSERT INTO sgl_sigils (owner_uuid, owner_name, area_tag, area_name, "
        "  pos_x, pos_y, pos_z, sigil_type, charges, placed_at) "
        "VALUES (@ouuid, @oname, @atag, @aname, @x, @y, @z, @type, @chg, strftime('%s','now'))");
    SqlBindString(q, "@ouuid",  GetObjectUUID(oPC));
    SqlBindString(q, "@oname",  GetName(oPC));
    SqlBindString(q, "@atag",   sAreaTag);
    SqlBindString(q, "@aname",  sAreaName);
    SqlBindFloat (q, "@x",      fX);
    SqlBindFloat (q, "@y",      fY);
    SqlBindFloat (q, "@z",      fZ);
    SqlBindInt   (q, "@type",   nType);
    SqlBindInt   (q, "@chg",    nCharges);
    SqlStep(q);

    sqlquery qId = SqlPrepareQueryCampaign(SGL_DB, "SELECT last_insert_rowid()");
    if(SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

// Returns JsonArray [{id, area_tag, area_name, sigil_type, charges, placed_at}]
json SglGetPlayerSigils(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(SGL_DB,
        "SELECT id, area_tag, area_name, sigil_type, charges, placed_at "
        "FROM sgl_sigils WHERE owner_uuid = @uuid AND charges > 0 ORDER BY placed_at ASC");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",         JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "area_tag",   JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "area_name",  JsonString(SqlGetString(q, 2)));
        jRow = JsonObjectSet(jRow, "sigil_type", JsonInt   (SqlGetInt   (q, 3)));
        jRow = JsonObjectSet(jRow, "charges",    JsonInt   (SqlGetInt   (q, 4)));
        jRow = JsonObjectSet(jRow, "placed_at",  JsonInt   (SqlGetInt   (q, 5)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

// Returns JsonArray of ALL active sigils for heartbeat proximity check
// [{id, owner_uuid, area_tag, area_name, pos_x, pos_y, pos_z, sigil_type, charges}]
json SglGetAllActiveSigils()
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(SGL_DB,
        "SELECT id, owner_uuid, area_tag, area_name, pos_x, pos_y, pos_z, sigil_type, charges "
        "FROM sgl_sigils WHERE charges > 0");
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",         JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "owner_uuid", JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "area_tag",   JsonString(SqlGetString(q, 2)));
        jRow = JsonObjectSet(jRow, "area_name",  JsonString(SqlGetString(q, 3)));
        jRow = JsonObjectSet(jRow, "pos_x",      JsonFloat (SqlGetFloat (q, 4)));
        jRow = JsonObjectSet(jRow, "pos_y",      JsonFloat (SqlGetFloat (q, 5)));
        jRow = JsonObjectSet(jRow, "pos_z",      JsonFloat (SqlGetFloat (q, 6)));
        jRow = JsonObjectSet(jRow, "sigil_type", JsonInt   (SqlGetInt   (q, 7)));
        jRow = JsonObjectSet(jRow, "charges",    JsonInt   (SqlGetInt   (q, 8)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

// Returns remaining charges after decrement, or 0
int SglDecrementCharges(int nSigilId)
{
    sqlquery q = SqlPrepareQueryCampaign(SGL_DB,
        "UPDATE sgl_sigils SET charges = MAX(0, charges - 1) WHERE id = @id");
    SqlBindInt(q, "@id", nSigilId);
    SqlStep(q);

    q = SqlPrepareQueryCampaign(SGL_DB,
        "SELECT charges FROM sgl_sigils WHERE id = @id");
    SqlBindInt(q, "@id", nSigilId);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void SglRemoveSigil(int nSigilId)
{
    sqlquery q = SqlPrepareQueryCampaign(SGL_DB,
        "DELETE FROM sgl_sigils WHERE id = @id");
    SqlBindInt(q, "@id", nSigilId);
    SqlStep(q);

    q = SqlPrepareQueryCampaign(SGL_DB,
        "DELETE FROM sgl_attuned WHERE sigil_id = @id");
    SqlBindInt(q, "@id", nSigilId);
    SqlStep(q);
}

int SglGetPlayerSigilCount(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(SGL_DB,
        "SELECT COUNT(*) FROM sgl_sigils WHERE owner_uuid = @uuid AND charges > 0");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void SglAttunePlayer(int nSigilId, string sUuid, string sName)
{
    sqlquery q = SqlPrepareQueryCampaign(SGL_DB,
        "INSERT OR IGNORE INTO sgl_attuned (sigil_id, attuned_uuid, attuned_name) "
        "VALUES (@sid, @uuid, @name)");
    SqlBindInt   (q, "@sid",  nSigilId);
    SqlBindString(q, "@uuid", sUuid);
    SqlBindString(q, "@name", sName);
    SqlStep(q);
}

void SglRevokeAttunement(int nSigilId, string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(SGL_DB,
        "DELETE FROM sgl_attuned WHERE sigil_id = @sid AND attuned_uuid = @uuid");
    SqlBindInt   (q, "@sid",  nSigilId);
    SqlBindString(q, "@uuid", sUuid);
    SqlStep(q);
}

// Returns JsonArray [{uuid, name}]
json SglGetAttuned(int nSigilId)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(SGL_DB,
        "SELECT attuned_uuid, attuned_name FROM sgl_attuned WHERE sigil_id = @sid");
    SqlBindInt(q, "@sid", nSigilId);
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "uuid", JsonString(SqlGetString(q, 0)));
        jRow = JsonObjectSet(jRow, "name", JsonString(SqlGetString(q, 1)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

int SglIsAttuned(int nSigilId, string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(SGL_DB,
        "SELECT COUNT(*) FROM sgl_attuned WHERE sigil_id = @sid AND attuned_uuid = @uuid");
    SqlBindInt   (q, "@sid",  nSigilId);
    SqlBindString(q, "@uuid", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0) > 0;
    return FALSE;
}

// Returns sigil row or JsonNull
json SglGetSigilById(int nSigilId)
{
    sqlquery q = SqlPrepareQueryCampaign(SGL_DB,
        "SELECT id, owner_uuid, area_tag, area_name, pos_x, pos_y, pos_z, sigil_type, charges "
        "FROM sgl_sigils WHERE id = @id");
    SqlBindInt(q, "@id", nSigilId);
    if(!SqlStep(q)) return JsonNull();
    json jRow = JsonObject();
    jRow = JsonObjectSet(jRow, "id",         JsonInt   (SqlGetInt   (q, 0)));
    jRow = JsonObjectSet(jRow, "owner_uuid", JsonString(SqlGetString(q, 1)));
    jRow = JsonObjectSet(jRow, "area_tag",   JsonString(SqlGetString(q, 2)));
    jRow = JsonObjectSet(jRow, "area_name",  JsonString(SqlGetString(q, 3)));
    jRow = JsonObjectSet(jRow, "pos_x",      JsonFloat (SqlGetFloat (q, 4)));
    jRow = JsonObjectSet(jRow, "pos_y",      JsonFloat (SqlGetFloat (q, 5)));
    jRow = JsonObjectSet(jRow, "pos_z",      JsonFloat (SqlGetFloat (q, 6)));
    jRow = JsonObjectSet(jRow, "sigil_type", JsonInt   (SqlGetInt   (q, 7)));
    jRow = JsonObjectSet(jRow, "charges",    JsonInt   (SqlGetInt   (q, 8)));
    return jRow;
}

// Returns JsonArray of registered players matching name fragment, excluding self
json SglSearchPlayers(string sQuery, object oExclude)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(SGL_DB,
        "SELECT uuid, name FROM sgl_players "
        "WHERE LOWER(name) LIKE LOWER('%' || @q || '%') AND uuid != @excl LIMIT 10");
    SqlBindString(q, "@q",    sQuery);
    SqlBindString(q, "@excl", GetObjectUUID(oExclude));
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "uuid", JsonString(SqlGetString(q, 0)));
        jRow = JsonObjectSet(jRow, "name", JsonString(SqlGetString(q, 1)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

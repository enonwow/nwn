const int FMASK_DEFAULT_USES = 5;
const int FMASK_MAX_MASKS    = 20;

void FmaskCreateTables()
{
    sqlquery q;

    q = SqlPrepareQueryCampaign("fmask",
        "CREATE TABLE IF NOT EXISTS fmask_collection ("
        "  id              INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  owner_uuid      TEXT NOT NULL,"
        "  creature_name   TEXT DEFAULT '',"
        "  racial_type     INTEGER DEFAULT 0,"
        "  appearance_type INTEGER DEFAULT 0,"
        "  phenotype       INTEGER DEFAULT 0,"
        "  color_skin      INTEGER DEFAULT 0,"
        "  color_hair      INTEGER DEFAULT 0,"
        "  color_tattoo1   INTEGER DEFAULT 0,"
        "  color_tattoo2   INTEGER DEFAULT 0,"
        "  parts_json      TEXT DEFAULT '{}',"
        "  uses_remaining  INTEGER DEFAULT 5,"
        "  is_cursed       INTEGER DEFAULT 0,"
        "  created_at      INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("fmask",
        "CREATE TABLE IF NOT EXISTS fmask_worn ("
        "  owner_uuid    TEXT PRIMARY KEY,"
        "  mask_id       INTEGER DEFAULT 0,"
        "  original_json TEXT DEFAULT '{}',"
        "  worn_at       INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

int FmaskAddMask(object oPC, string sCreatureName, int nRacialType,
                 int nAppearance, int nPhenotype,
                 int nColorSkin, int nColorHair,
                 int nColorTat1, int nColorTat2,
                 string sPartsJson, int bCursed)
{
    sqlquery q = SqlPrepareQueryCampaign("fmask",
        "INSERT INTO fmask_collection "
        "(owner_uuid, creature_name, racial_type, appearance_type, phenotype, "
        " color_skin, color_hair, color_tattoo1, color_tattoo2, parts_json, "
        " uses_remaining, is_cursed, created_at) "
        "VALUES (@uuid, @name, @race, @app, @phen, @cskin, @chair, @ct1, @ct2,"
        "        @parts, @uses, @curs, strftime('%s','now'))");
    SqlBindString(q, "@uuid",  GetObjectUUID(oPC));
    SqlBindString(q, "@name",  sCreatureName);
    SqlBindInt   (q, "@race",  nRacialType);
    SqlBindInt   (q, "@app",   nAppearance);
    SqlBindInt   (q, "@phen",  nPhenotype);
    SqlBindInt   (q, "@cskin", nColorSkin);
    SqlBindInt   (q, "@chair", nColorHair);
    SqlBindInt   (q, "@ct1",   nColorTat1);
    SqlBindInt   (q, "@ct2",   nColorTat2);
    SqlBindString(q, "@parts", sPartsJson);
    SqlBindInt   (q, "@uses",  FMASK_DEFAULT_USES);
    SqlBindInt   (q, "@curs",  bCursed);
    SqlStep(q);

    sqlquery qId = SqlPrepareQueryCampaign("fmask", "SELECT last_insert_rowid()");
    if(SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

json FmaskGetCollection(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("fmask",
        "SELECT id, creature_name, racial_type, appearance_type, phenotype,"
        "       color_skin, color_hair, color_tattoo1, color_tattoo2, parts_json,"
        "       uses_remaining, is_cursed"
        "  FROM fmask_collection"
        "  WHERE owner_uuid = @uuid AND uses_remaining > 0"
        "  ORDER BY created_at DESC");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "id",            JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "creature_name", JsonString(SqlGetString(q, 1)));
        jRow = JsonObjectSet(jRow, "racial_type",   JsonInt   (SqlGetInt   (q, 2)));
        jRow = JsonObjectSet(jRow, "appearance",    JsonInt   (SqlGetInt   (q, 3)));
        jRow = JsonObjectSet(jRow, "phenotype",     JsonInt   (SqlGetInt   (q, 4)));
        jRow = JsonObjectSet(jRow, "color_skin",    JsonInt   (SqlGetInt   (q, 5)));
        jRow = JsonObjectSet(jRow, "color_hair",    JsonInt   (SqlGetInt   (q, 6)));
        jRow = JsonObjectSet(jRow, "color_tattoo1", JsonInt   (SqlGetInt   (q, 7)));
        jRow = JsonObjectSet(jRow, "color_tattoo2", JsonInt   (SqlGetInt   (q, 8)));
        jRow = JsonObjectSet(jRow, "parts_json",    JsonString(SqlGetString(q, 9)));
        jRow = JsonObjectSet(jRow, "uses_remaining",JsonInt   (SqlGetInt   (q, 10)));
        jRow = JsonObjectSet(jRow, "is_cursed",     JsonInt   (SqlGetInt   (q, 11)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

json FmaskGetMask(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("fmask",
        "SELECT id, creature_name, racial_type, appearance_type, phenotype,"
        "       color_skin, color_hair, color_tattoo1, color_tattoo2, parts_json,"
        "       uses_remaining, is_cursed"
        "  FROM fmask_collection WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();

    json jRow = JsonObject();
    jRow = JsonObjectSet(jRow, "id",            JsonInt   (SqlGetInt   (q, 0)));
    jRow = JsonObjectSet(jRow, "creature_name", JsonString(SqlGetString(q, 1)));
    jRow = JsonObjectSet(jRow, "racial_type",   JsonInt   (SqlGetInt   (q, 2)));
    jRow = JsonObjectSet(jRow, "appearance",    JsonInt   (SqlGetInt   (q, 3)));
    jRow = JsonObjectSet(jRow, "phenotype",     JsonInt   (SqlGetInt   (q, 4)));
    jRow = JsonObjectSet(jRow, "color_skin",    JsonInt   (SqlGetInt   (q, 5)));
    jRow = JsonObjectSet(jRow, "color_hair",    JsonInt   (SqlGetInt   (q, 6)));
    jRow = JsonObjectSet(jRow, "color_tattoo1", JsonInt   (SqlGetInt   (q, 7)));
    jRow = JsonObjectSet(jRow, "color_tattoo2", JsonInt   (SqlGetInt   (q, 8)));
    jRow = JsonObjectSet(jRow, "parts_json",    JsonString(SqlGetString(q, 9)));
    jRow = JsonObjectSet(jRow, "uses_remaining",JsonInt   (SqlGetInt   (q, 10)));
    jRow = JsonObjectSet(jRow, "is_cursed",     JsonInt   (SqlGetInt   (q, 11)));
    return jRow;
}

void FmaskDecrementUses(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("fmask",
        "UPDATE fmask_collection SET uses_remaining = uses_remaining - 1 WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

void FmaskDeleteMask(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("fmask",
        "DELETE FROM fmask_collection WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

int FmaskCountCollection(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("fmask",
        "SELECT COUNT(*) FROM fmask_collection WHERE owner_uuid = @uuid AND uses_remaining > 0");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void FmaskSetWorn(object oPC, int nMaskId, string sOrigJson)
{
    sqlquery q = SqlPrepareQueryCampaign("fmask",
        "INSERT OR REPLACE INTO fmask_worn (owner_uuid, mask_id, original_json, worn_at)"
        "  VALUES (@uuid, @mask, @orig, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@mask", nMaskId);
    SqlBindString(q, "@orig", sOrigJson);
    SqlStep(q);
}

void FmaskClearWorn(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("fmask",
        "DELETE FROM fmask_worn WHERE owner_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

json FmaskGetWornEntry(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("fmask",
        "SELECT mask_id, original_json FROM fmask_worn WHERE owner_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(!SqlStep(q)) return JsonNull();

    json jRow = JsonObject();
    jRow = JsonObjectSet(jRow, "mask_id",      JsonInt   (SqlGetInt   (q, 0)));
    jRow = JsonObjectSet(jRow, "original_json",JsonString(SqlGetString(q, 1)));
    return jRow;
}

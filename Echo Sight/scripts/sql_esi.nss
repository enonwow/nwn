// sql_esi.nss — Echo Sight: SQL schema and all database access

void EsiCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("esi",
        "CREATE TABLE IF NOT EXISTS esi_echoes ("
        "player_uuid TEXT NOT NULL, "
        "echo_uuid   TEXT NOT NULL, "
        "title       TEXT DEFAULT '', "
        "vision_text TEXT DEFAULT '', "
        "category    INTEGER DEFAULT 0, "
        "flavor      TEXT DEFAULT '', "
        "bonus_type  INTEGER DEFAULT 0, "
        "bonus_val   INTEGER DEFAULT 0, "
        "trauma      INTEGER DEFAULT 0, "
        "absorbed_at INTEGER DEFAULT 0, "
        "consumed    INTEGER DEFAULT 0, "
        "PRIMARY KEY (player_uuid, echo_uuid))");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("esi",
        "CREATE TABLE IF NOT EXISTS esi_active_bonuses ("
        "player_uuid TEXT NOT NULL, "
        "echo_uuid   TEXT NOT NULL, "
        "bonus_type  INTEGER DEFAULT 0, "
        "bonus_val   INTEGER DEFAULT 0, "
        "PRIMARY KEY (player_uuid, echo_uuid))");
    SqlStep(q);
}

int EsiHasAbsorbed(object oPC, string sEchoUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("esi",
        "SELECT 1 FROM esi_echoes WHERE player_uuid=@puuid AND echo_uuid=@euuid");
    SqlBindString(q, "@puuid", GetObjectUUID(oPC));
    SqlBindString(q, "@euuid", sEchoUuid);
    return SqlStep(q) ? 1 : 0;
}

void EsiAbsorbEcho(object oPC, string sEchoUuid, string sTitle, string sText,
                   int nCategory, string sFlavor, int nBonusType, int nBonusVal, int nTrauma)
{
    sqlquery q = SqlPrepareQueryCampaign("esi",
        "INSERT OR IGNORE INTO esi_echoes "
        "(player_uuid, echo_uuid, title, vision_text, category, flavor, bonus_type, bonus_val, trauma, absorbed_at, consumed) "
        "VALUES (@puuid, @euuid, @title, @text, @cat, @flavor, @btype, @bval, @trauma, strftime('%s','now'), 0)");
    SqlBindString(q, "@puuid",  GetObjectUUID(oPC));
    SqlBindString(q, "@euuid",  sEchoUuid);
    SqlBindString(q, "@title",  sTitle);
    SqlBindString(q, "@text",   sText);
    SqlBindInt   (q, "@cat",    nCategory);
    SqlBindString(q, "@flavor", sFlavor);
    SqlBindInt   (q, "@btype",  nBonusType);
    SqlBindInt   (q, "@bval",   nBonusVal);
    SqlBindInt   (q, "@trauma", nTrauma);
    SqlStep(q);
}

json EsiGetCodex(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("esi",
        "SELECT echo_uuid, title, category, flavor, bonus_type, bonus_val, trauma, consumed "
        "FROM esi_echoes WHERE player_uuid=@puuid ORDER BY absorbed_at DESC");
    SqlBindString(q, "@puuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "echo_uuid",  JsonString(SqlGetString(q, 0)));
        j = JsonObjectSet(j, "title",      JsonString(SqlGetString(q, 1)));
        j = JsonObjectSet(j, "category",   JsonInt   (SqlGetInt   (q, 2)));
        j = JsonObjectSet(j, "flavor",     JsonString(SqlGetString(q, 3)));
        j = JsonObjectSet(j, "bonus_type", JsonInt   (SqlGetInt   (q, 4)));
        j = JsonObjectSet(j, "bonus_val",  JsonInt   (SqlGetInt   (q, 5)));
        j = JsonObjectSet(j, "trauma",     JsonInt   (SqlGetInt   (q, 6)));
        j = JsonObjectSet(j, "consumed",   JsonInt   (SqlGetInt   (q, 7)));
        jRows = JsonArrayInsert(jRows, j);
    }
    return jRows;
}

json EsiGetEchoDetail(object oPC, string sEchoUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("esi",
        "SELECT echo_uuid, title, vision_text, category, flavor, bonus_type, bonus_val, trauma, consumed "
        "FROM esi_echoes WHERE player_uuid=@puuid AND echo_uuid=@euuid");
    SqlBindString(q, "@puuid", GetObjectUUID(oPC));
    SqlBindString(q, "@euuid", sEchoUuid);
    if(!SqlStep(q)) return JsonNull();
    json j = JsonObject();
    j = JsonObjectSet(j, "echo_uuid",   JsonString(SqlGetString(q, 0)));
    j = JsonObjectSet(j, "title",       JsonString(SqlGetString(q, 1)));
    j = JsonObjectSet(j, "vision_text", JsonString(SqlGetString(q, 2)));
    j = JsonObjectSet(j, "category",    JsonInt   (SqlGetInt   (q, 3)));
    j = JsonObjectSet(j, "flavor",      JsonString(SqlGetString(q, 4)));
    j = JsonObjectSet(j, "bonus_type",  JsonInt   (SqlGetInt   (q, 5)));
    j = JsonObjectSet(j, "bonus_val",   JsonInt   (SqlGetInt   (q, 6)));
    j = JsonObjectSet(j, "trauma",      JsonInt   (SqlGetInt   (q, 7)));
    j = JsonObjectSet(j, "consumed",    JsonInt   (SqlGetInt   (q, 8)));
    return j;
}

void EsiConsumeEcho(object oPC, string sEchoUuid)
{
    sqlquery q = SqlPrepareQueryCampaign("esi",
        "UPDATE esi_echoes SET consumed=1 WHERE player_uuid=@puuid AND echo_uuid=@euuid AND consumed=0");
    SqlBindString(q, "@puuid", GetObjectUUID(oPC));
    SqlBindString(q, "@euuid", sEchoUuid);
    SqlStep(q);
}

int EsiGetAbsorbedCount(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("esi",
        "SELECT COUNT(*) FROM esi_echoes WHERE player_uuid=@puuid");
    SqlBindString(q, "@puuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int EsiGetConsumedCount(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("esi",
        "SELECT COUNT(*) FROM esi_echoes WHERE player_uuid=@puuid AND consumed=1");
    SqlBindString(q, "@puuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void EsiInsertActiveBonus(object oPC, string sEchoUuid, int nBonusType, int nBonusVal)
{
    sqlquery q = SqlPrepareQueryCampaign("esi",
        "INSERT OR IGNORE INTO esi_active_bonuses (player_uuid, echo_uuid, bonus_type, bonus_val) "
        "VALUES (@puuid, @euuid, @btype, @bval)");
    SqlBindString(q, "@puuid", GetObjectUUID(oPC));
    SqlBindString(q, "@euuid", sEchoUuid);
    SqlBindInt   (q, "@btype", nBonusType);
    SqlBindInt   (q, "@bval",  nBonusVal);
    SqlStep(q);
}

json EsiGetAllActiveBonuses(object oPC)
{
    json jBonuses = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("esi",
        "SELECT bonus_type, bonus_val FROM esi_active_bonuses WHERE player_uuid=@puuid");
    SqlBindString(q, "@puuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "bonus_type", JsonInt(SqlGetInt(q, 0)));
        j = JsonObjectSet(j, "bonus_val",  JsonInt(SqlGetInt(q, 1)));
        jBonuses = JsonArrayInsert(jBonuses, j);
    }
    return jBonuses;
}

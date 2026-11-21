const int GRV_PRAY_COOLDOWN_SEC = 86400;

void GrvCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("graveyard",
        "CREATE TABLE IF NOT EXISTS grv_graves ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "owner_uuid TEXT NOT NULL,"
        "owner_name TEXT DEFAULT '',"
        "deceased_name TEXT DEFAULT 'Nieznany',"
        "grave_type INTEGER DEFAULT 0,"
        "gold_buried INTEGER DEFAULT 0,"
        "area_resref TEXT DEFAULT '',"
        "created_at INTEGER DEFAULT 0,"
        "is_desecrated INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("graveyard",
        "CREATE TABLE IF NOT EXISTS grv_players ("
        "uuid TEXT PRIMARY KEY,"
        "char_name TEXT DEFAULT '',"
        "bone_grace INTEGER DEFAULT 0,"
        "desec_marks INTEGER DEFAULT 0,"
        "last_online INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("graveyard",
        "CREATE TABLE IF NOT EXISTS grv_pray_log ("
        "player_uuid TEXT NOT NULL,"
        "grave_id INTEGER NOT NULL,"
        "prayed_at INTEGER DEFAULT 0,"
        "PRIMARY KEY (player_uuid, grave_id)"
        ")");
    SqlStep(q);
}

void GrvRegisterPlayer(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("graveyard",
        "INSERT OR IGNORE INTO grv_players (uuid, char_name, last_online) "
        "VALUES (@uuid, @name, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlStep(q);

    q = SqlPrepareQueryCampaign("graveyard",
        "UPDATE grv_players SET char_name = @name, last_online = strftime('%s','now') "
        "WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@name", GetName(oPC));
    SqlStep(q);
}

int GrvGetBoneGrace(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("graveyard",
        "SELECT bone_grace FROM grv_players WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int GrvGetDesecMarks(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("graveyard",
        "SELECT desec_marks FROM grv_players WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void GrvAddBoneGrace(object oPC, int nAmount)
{
    sqlquery q = SqlPrepareQueryCampaign("graveyard",
        "UPDATE grv_players SET bone_grace = MAX(0, bone_grace + @amt) WHERE uuid = @uuid");
    SqlBindInt   (q, "@amt",  nAmount);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

int GrvSpendBoneGrace(object oPC, int nCost)
{
    if(GrvGetBoneGrace(oPC) < nCost) return FALSE;
    GrvAddBoneGrace(oPC, -nCost);
    return TRUE;
}

void GrvAddDesecMark(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("graveyard",
        "UPDATE grv_players SET desec_marks = desec_marks + 1 WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void GrvRemoveDesecMark(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("graveyard",
        "UPDATE grv_players SET desec_marks = MAX(0, desec_marks - 1) WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

int GrvInsertGrave(object oPC, string sDeceasedName, int nType, int nGold, string sArea)
{
    sqlquery q = SqlPrepareQueryCampaign("graveyard",
        "INSERT INTO grv_graves "
        "(owner_uuid, owner_name, deceased_name, grave_type, gold_buried, area_resref, created_at) "
        "VALUES (@uuid, @oname, @dname, @type, @gold, @area, strftime('%s','now'))");
    SqlBindString(q, "@uuid",  GetObjectUUID(oPC));
    SqlBindString(q, "@oname", GetName(oPC));
    SqlBindString(q, "@dname", sDeceasedName);
    SqlBindInt   (q, "@type",  nType);
    SqlBindInt   (q, "@gold",  nGold);
    SqlBindString(q, "@area",  sArea);
    SqlStep(q);

    sqlquery qId = SqlPrepareQueryCampaign("graveyard", "SELECT last_insert_rowid()");
    if(SqlStep(qId)) return SqlGetInt(qId, 0);
    return 0;
}

json GrvGetGrave(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("graveyard",
        "SELECT id, owner_name, deceased_name, grave_type, gold_buried, created_at, is_desecrated "
        "FROM grv_graves WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "id",            JsonInt   (SqlGetInt   (q, 0)));
    j = JsonObjectSet(j, "owner_name",    JsonString(SqlGetString(q, 1)));
    j = JsonObjectSet(j, "deceased_name", JsonString(SqlGetString(q, 2)));
    j = JsonObjectSet(j, "grave_type",    JsonInt   (SqlGetInt   (q, 3)));
    j = JsonObjectSet(j, "gold_buried",   JsonInt   (SqlGetInt   (q, 4)));
    j = JsonObjectSet(j, "created_at",    JsonInt   (SqlGetInt   (q, 5)));
    j = JsonObjectSet(j, "is_desecrated", JsonInt   (SqlGetInt   (q, 6)));
    return j;
}

void GrvMarkDesecrated(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("graveyard",
        "UPDATE grv_graves SET is_desecrated = 1 WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

int GrvHasPrayed(object oPC, int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("graveyard",
        "SELECT 1 FROM grv_pray_log "
        "WHERE player_uuid = @uuid AND grave_id = @gid "
        "AND prayed_at > strftime('%s','now') - @cd");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@gid",  nId);
    SqlBindInt   (q, "@cd",   GRV_PRAY_COOLDOWN_SEC);
    return SqlStep(q);
}

void GrvLogPrayer(object oPC, int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("graveyard",
        "INSERT OR REPLACE INTO grv_pray_log (player_uuid, grave_id, prayed_at) "
        "VALUES (@uuid, @gid, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@gid",  nId);
    SqlStep(q);
}

string GrvFormatDate(int nUnix)
{
    sqlquery q = SqlPrepareQueryCampaign("graveyard",
        "SELECT strftime('%d.%m.%Y', @ts, 'unixepoch')");
    SqlBindInt(q, "@ts", nUnix);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "??";
}

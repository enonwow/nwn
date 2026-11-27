// Beast Binder — SQL layer
// Campaign DB name: "bb"

const int BB_BOND_KILL       = 2;   // bonding per kill alongside beast
const int BB_BOND_DECAY_HOUR = 8;   // bonding lost per hour without feeding

void BbCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("bb",
        "CREATE TABLE IF NOT EXISTS bb_beasts ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "owner_uuid TEXT NOT NULL,"
        "resref TEXT DEFAULT '',"
        "name TEXT DEFAULT '',"
        "appearance INTEGER DEFAULT 0,"
        "bonding INTEGER DEFAULT 0,"
        "is_active INTEGER DEFAULT 0,"
        "captured_at INTEGER DEFAULT 0,"
        "last_fed INTEGER DEFAULT 0,"
        "kill_count INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

int BbInsertBeast(object oPC, string sResRef, string sName, int nAppearance)
{
    sqlquery q = SqlPrepareQueryCampaign("bb",
        "INSERT INTO bb_beasts "
        "(owner_uuid, resref, name, appearance, bonding, captured_at, last_fed)"
        " VALUES (@uuid, @resref, @name, @app, 10,"
        " strftime('%s','now'), strftime('%s','now'))");
    SqlBindString(q, "@uuid",   GetObjectUUID(oPC));
    SqlBindString(q, "@resref", sResRef);
    SqlBindString(q, "@name",   sName);
    SqlBindInt(q, "@app",       nAppearance);
    SqlStep(q);

    sqlquery qId = SqlPrepareQueryCampaign("bb", "SELECT last_insert_rowid()");
    if(SqlStep(qId)) return SqlGetInt(qId, 0);
    return -1;
}

json BbGetBeasts(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("bb",
        "SELECT id, name, bonding, is_active, kill_count"
        " FROM bb_beasts WHERE owner_uuid = @uuid ORDER BY captured_at ASC");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));

    json jArr = JsonArray();
    while(SqlStep(q))
    {
        json jE = JsonObject();
        jE = JsonObjectSet(jE, "id",        JsonInt(SqlGetInt(q, 0)));
        jE = JsonObjectSet(jE, "name",      JsonString(SqlGetString(q, 1)));
        jE = JsonObjectSet(jE, "bonding",   JsonInt(SqlGetInt(q, 2)));
        jE = JsonObjectSet(jE, "is_active", JsonInt(SqlGetInt(q, 3)));
        jE = JsonObjectSet(jE, "kills",     JsonInt(SqlGetInt(q, 4)));
        jArr = JsonArrayInsert(jArr, jE);
    }
    return jArr;
}

json BbGetBeast(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("bb",
        "SELECT id, owner_uuid, resref, name, appearance, bonding, is_active, kill_count, last_fed"
        " FROM bb_beasts WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();

    json jB = JsonObject();
    jB = JsonObjectSet(jB, "id",         JsonInt(SqlGetInt(q, 0)));
    jB = JsonObjectSet(jB, "owner_uuid", JsonString(SqlGetString(q, 1)));
    jB = JsonObjectSet(jB, "resref",     JsonString(SqlGetString(q, 2)));
    jB = JsonObjectSet(jB, "name",       JsonString(SqlGetString(q, 3)));
    jB = JsonObjectSet(jB, "appearance", JsonInt(SqlGetInt(q, 4)));
    jB = JsonObjectSet(jB, "bonding",    JsonInt(SqlGetInt(q, 5)));
    jB = JsonObjectSet(jB, "is_active",  JsonInt(SqlGetInt(q, 6)));
    jB = JsonObjectSet(jB, "kills",      JsonInt(SqlGetInt(q, 7)));
    jB = JsonObjectSet(jB, "last_fed",   JsonInt(SqlGetInt(q, 8)));
    return jB;
}

void BbSetActive(int nId, int bActive)
{
    sqlquery q = SqlPrepareQueryCampaign("bb",
        "UPDATE bb_beasts SET is_active = @v WHERE id = @id");
    SqlBindInt(q, "@v",  bActive);
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

void BbClearActiveForPC(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("bb",
        "UPDATE bb_beasts SET is_active = 0 WHERE owner_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void BbUpdateBonding(int nId, int nDelta)
{
    sqlquery q = SqlPrepareQueryCampaign("bb",
        "UPDATE bb_beasts SET bonding = MAX(0, MIN(100, bonding + @d)) WHERE id = @id");
    SqlBindInt(q, "@d",  nDelta);
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

void BbMarkFed(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("bb",
        "UPDATE bb_beasts SET last_fed = strftime('%s','now') WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

void BbDeleteBeast(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("bb",
        "DELETE FROM bb_beasts WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    SqlStep(q);
}

int BbGetActiveBeastId(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("bb",
        "SELECT id FROM bb_beasts WHERE owner_uuid = @uuid AND is_active = 1 LIMIT 1");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int BbGetBeastCount(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("bb",
        "SELECT COUNT(*) FROM bb_beasts WHERE owner_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void BbAddKill(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("bb",
        "UPDATE bb_beasts SET kill_count = kill_count + 1,"
        " bonding = MIN(100, bonding + @gain) WHERE id = @id");
    SqlBindInt(q, "@gain", BB_BOND_KILL);
    SqlBindInt(q, "@id",   nId);
    SqlStep(q);
}

void BbDecayBonding(object oPC)
{
    // Decays bonding for beasts not fed in the last hour
    sqlquery q = SqlPrepareQueryCampaign("bb",
        "UPDATE bb_beasts SET bonding = MAX(0, bonding - @decay)"
        " WHERE owner_uuid = @uuid AND last_fed < strftime('%s','now') - 3600");
    SqlBindInt(q, "@decay",  BB_BOND_DECAY_HOUR);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

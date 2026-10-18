void GwkCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("gwk",
        "CREATE TABLE IF NOT EXISTS gwk_golems ("
        "pc_uuid   TEXT    PRIMARY KEY, "
        "golem_type INTEGER NOT NULL DEFAULT 0, "
        "current_hp INTEGER NOT NULL DEFAULT 0, "
        "max_hp     INTEGER NOT NULL DEFAULT 0, "
        "is_active  INTEGER NOT NULL DEFAULT 0, "
        "created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')))");
    SqlStep(q);
}

void GwkSaveGolem(object oPC, int nType, int nCurHp, int nMaxHp, int bActive)
{
    sqlquery q = SqlPrepareQueryCampaign("gwk",
        "INSERT OR REPLACE INTO gwk_golems (pc_uuid, golem_type, current_hp, max_hp, is_active) "
        "VALUES (@uuid, @type, @cur, @max, @active)");
    SqlBindString(q, "@uuid",   GetObjectUUID(oPC));
    SqlBindInt   (q, "@type",   nType);
    SqlBindInt   (q, "@cur",    nCurHp);
    SqlBindInt   (q, "@max",    nMaxHp);
    SqlBindInt   (q, "@active", bActive);
    SqlStep(q);
}

void GwkUpdateHp(object oPC, int nCurHp)
{
    sqlquery q = SqlPrepareQueryCampaign("gwk",
        "UPDATE gwk_golems SET current_hp = @cur WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@cur",  nCurHp);
    SqlStep(q);
}

void GwkSetActive(object oPC, int bActive)
{
    sqlquery q = SqlPrepareQueryCampaign("gwk",
        "UPDATE gwk_golems SET is_active = @active WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid",   GetObjectUUID(oPC));
    SqlBindInt   (q, "@active", bActive);
    SqlStep(q);
}

void GwkDeleteGolem(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("gwk",
        "DELETE FROM gwk_golems WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

// Returns JSON {type, current_hp, max_hp, is_active} or JSON_NULL when no record.
json GwkLoadGolem(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("gwk",
        "SELECT golem_type, current_hp, max_hp, is_active "
        "FROM gwk_golems WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(!SqlStep(q)) return JsonNull();
    json j = JsonObject();
    j = JsonObjectSet(j, "type",       JsonInt(SqlGetInt(q, 0)));
    j = JsonObjectSet(j, "current_hp", JsonInt(SqlGetInt(q, 1)));
    j = JsonObjectSet(j, "max_hp",     JsonInt(SqlGetInt(q, 2)));
    j = JsonObjectSet(j, "is_active",  JsonInt(SqlGetInt(q, 3)));
    return j;
}

int GwkHasGolem(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("gwk",
        "SELECT COUNT(*) FROM gwk_golems WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0) > 0;
    return FALSE;
}

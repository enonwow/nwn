// sql_bur.nss — SQL schema and queries for Burial Rites

void BurCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("burial",
        "CREATE TABLE IF NOT EXISTS bur_records ("
        "pc_uuid TEXT PRIMARY KEY, "
        "total_pauper INTEGER DEFAULT 0, "
        "total_proper INTEGER DEFAULT 0, "
        "total_sacred INTEGER DEFAULT 0, "
        "last_pauper_time INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

void BurEnsureRecord(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("burial",
        "INSERT OR IGNORE INTO bur_records (pc_uuid) VALUES (@uuid)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

json BurGetRecord(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("burial",
        "SELECT total_pauper, total_proper, total_sacred, last_pauper_time "
        "FROM bur_records WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(!SqlStep(q)) return JsonNull();
    json j = JsonObject();
    j = JsonObjectSet(j, "total_pauper",     JsonInt(SqlGetInt(q, 0)));
    j = JsonObjectSet(j, "total_proper",     JsonInt(SqlGetInt(q, 1)));
    j = JsonObjectSet(j, "total_sacred",     JsonInt(SqlGetInt(q, 2)));
    j = JsonObjectSet(j, "last_pauper_time", JsonInt(SqlGetInt(q, 3)));
    return j;
}

// Returns seconds remaining on pauper cooldown (0 = ready).
int BurPauperCooldownLeft(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("burial",
        "SELECT MAX(0, 3600 - (CAST(strftime('%s','now') AS INTEGER) - last_pauper_time)) "
        "FROM bur_records WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void BurRecordPauper(object oPC)
{
    BurEnsureRecord(oPC);
    sqlquery q = SqlPrepareQueryCampaign("burial",
        "UPDATE bur_records "
        "SET total_pauper = total_pauper + 1, "
        "    last_pauper_time = CAST(strftime('%s','now') AS INTEGER) "
        "WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void BurRecordProper(object oPC)
{
    BurEnsureRecord(oPC);
    sqlquery q = SqlPrepareQueryCampaign("burial",
        "UPDATE bur_records SET total_proper = total_proper + 1 WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void BurRecordSacred(object oPC)
{
    BurEnsureRecord(oPC);
    sqlquery q = SqlPrepareQueryCampaign("burial",
        "UPDATE bur_records SET total_sacred = total_sacred + 1 WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

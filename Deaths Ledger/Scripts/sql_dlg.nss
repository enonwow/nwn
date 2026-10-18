void DlgCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("deaths_ledger",
        "CREATE TABLE IF NOT EXISTS dlg_debt ("
        "uuid TEXT PRIMARY KEY, "
        "debt INTEGER DEFAULT 0, "
        "hp_penalty INTEGER DEFAULT 0, "
        "last_bargain INTEGER DEFAULT 0, "
        "last_emissary INTEGER DEFAULT 0, "
        "penance_deadline INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

int DlgGetDebt(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("deaths_ledger",
        "SELECT debt FROM dlg_debt WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int DlgGetHpPenalty(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("deaths_ledger",
        "SELECT hp_penalty FROM dlg_debt WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int DlgGetLastEmissary(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("deaths_ledger",
        "SELECT last_emissary FROM dlg_debt WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int DlgGetPenanceDeadline(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("deaths_ledger",
        "SELECT penance_deadline FROM dlg_debt WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void DlgEnsureRow(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("deaths_ledger",
        "INSERT OR IGNORE INTO dlg_debt (uuid) VALUES (@uuid)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void DlgAddDebt(object oPC, int nAmount)
{
    DlgEnsureRow(oPC);
    sqlquery q = SqlPrepareQueryCampaign("deaths_ledger",
        "UPDATE dlg_debt SET debt = MIN(debt + @amt, 10), last_bargain = strftime('%s','now') WHERE uuid = @uuid");
    SqlBindInt   (q, "@amt",  nAmount);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void DlgReduceDebt(object oPC, int nAmount)
{
    DlgEnsureRow(oPC);
    sqlquery q = SqlPrepareQueryCampaign("deaths_ledger",
        "UPDATE dlg_debt SET debt = MAX(debt - @amt, 0) WHERE uuid = @uuid");
    SqlBindInt   (q, "@amt",  nAmount);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void DlgAddHpPenalty(object oPC, int nPts)
{
    DlgEnsureRow(oPC);
    sqlquery q = SqlPrepareQueryCampaign("deaths_ledger",
        "UPDATE dlg_debt SET hp_penalty = hp_penalty + @pts WHERE uuid = @uuid");
    SqlBindInt   (q, "@pts",  nPts);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void DlgSetLastEmissary(object oPC)
{
    DlgEnsureRow(oPC);
    sqlquery q = SqlPrepareQueryCampaign("deaths_ledger",
        "UPDATE dlg_debt SET last_emissary = strftime('%s','now') WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void DlgSetPenanceDeadline(object oPC, int nDays)
{
    DlgEnsureRow(oPC);
    sqlquery q = SqlPrepareQueryCampaign("deaths_ledger",
        "UPDATE dlg_debt SET penance_deadline = strftime('%s','now') + @secs WHERE uuid = @uuid");
    SqlBindInt   (q, "@secs", nDays * 86400);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

void DlgClearPenanceDeadline(object oPC)
{
    DlgEnsureRow(oPC);
    sqlquery q = SqlPrepareQueryCampaign("deaths_ledger",
        "UPDATE dlg_debt SET penance_deadline = 0 WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
}

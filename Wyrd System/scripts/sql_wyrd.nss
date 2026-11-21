// sql_wyrd.nss — Wyrd System persistent storage
// Campaign DB (global): wyrd_chars stores per-PC wyrd balance and audit data.

void WyrdDbInit()
{
    SqlStep(SqlPrepareQueryCampaign(GetModule(),
        "CREATE TABLE IF NOT EXISTS wyrd_chars ("
        "  uuid        TEXT PRIMARY KEY,"
        "  char_name   TEXT    NOT NULL DEFAULT '',"
        "  wyrd        INTEGER NOT NULL DEFAULT 0,"
        "  total_spent INTEGER NOT NULL DEFAULT 0,"
        "  last_decay  INTEGER NOT NULL DEFAULT 0"
        ")"));
}

void WyrdDbUpsert(string sUuid, string sName, int nWyrd, int nSpent, int nLastDecay)
{
    sqlquery q = SqlPrepareQueryCampaign(GetModule(),
        "INSERT INTO wyrd_chars(uuid, char_name, wyrd, total_spent, last_decay)"
        " VALUES(@u,@n,@w,@s,@d)"
        " ON CONFLICT(uuid) DO UPDATE SET"
        "  char_name=excluded.char_name,"
        "  wyrd=excluded.wyrd,"
        "  total_spent=excluded.total_spent,"
        "  last_decay=excluded.last_decay");
    SqlBindString(q, "@u", sUuid);
    SqlBindString(q, "@n", sName);
    SqlBindInt(q, "@w", nWyrd);
    SqlBindInt(q, "@s", nSpent);
    SqlBindInt(q, "@d", nLastDecay);
    SqlStep(q);
}

int WyrdDbLoadWyrd(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(GetModule(),
        "SELECT wyrd FROM wyrd_chars WHERE uuid=@u");
    SqlBindString(q, "@u", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int WyrdDbLoadSpent(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(GetModule(),
        "SELECT total_spent FROM wyrd_chars WHERE uuid=@u");
    SqlBindString(q, "@u", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int WyrdDbLoadLastDecay(string sUuid)
{
    sqlquery q = SqlPrepareQueryCampaign(GetModule(),
        "SELECT last_decay FROM wyrd_chars WHERE uuid=@u");
    SqlBindString(q, "@u", sUuid);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Top N spenders for the Kronika leaderboard.
json WyrdDbTopSpenders(int nLimit)
{
    sqlquery q = SqlPrepareQueryCampaign(GetModule(),
        "SELECT char_name, total_spent FROM wyrd_chars"
        " ORDER BY total_spent DESC LIMIT @l");
    SqlBindInt(q, "@l", nLimit);
    json jArr = JsonArray();
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "n", JsonString(SqlGetString(q, 0)));
        jRow = JsonObjectSet(jRow, "s", JsonInt(SqlGetInt(q, 1)));
        jArr = JsonArrayInsert(jArr, jRow);
    }
    return jArr;
}

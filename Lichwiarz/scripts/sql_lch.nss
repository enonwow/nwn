// sql_lch.nss — SQLite schema and query layer for Lichwiarz (Usurer system)

const int   LCH_TICK_SECONDS = 3600;   // interest tick: every real hour
const float LCH_BASE_RATE    = 0.05;   // 5% per tick

void LchCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("lichwiarz",
        "CREATE TABLE IF NOT EXISTS lch_loans (uuid TEXT PRIMARY KEY, char_name TEXT NOT NULL DEFAULT '', principal INTEGER NOT NULL DEFAULT 0, current_debt INTEGER NOT NULL DEFAULT 0, interest_rate REAL NOT NULL DEFAULT 0.05, last_tick INTEGER NOT NULL DEFAULT 0, borrowed_at INTEGER NOT NULL DEFAULT 0, penalty_level INTEGER NOT NULL DEFAULT 0, total_repaid INTEGER NOT NULL DEFAULT 0)");
    SqlStep(q);
}

// Returns current UTC unix timestamp via SQLite
int LchNow()
{
    sqlquery q = SqlPrepareQueryCampaign("lichwiarz",
        "SELECT CAST(strftime('%s','now') AS INTEGER)");
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns loan row for oPC, or JsonNull() if no debt
json LchGetLoan(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("lichwiarz",
        "SELECT char_name, principal, current_debt, interest_rate, last_tick, borrowed_at, penalty_level, total_repaid FROM lch_loans WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(!SqlStep(q)) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "char_name",     JsonString(SqlGetString(q, 0)));
    j = JsonObjectSet(j, "principal",     JsonInt   (SqlGetInt   (q, 1)));
    j = JsonObjectSet(j, "current_debt",  JsonInt   (SqlGetInt   (q, 2)));
    j = JsonObjectSet(j, "interest_rate", JsonFloat (SqlGetFloat (q, 3)));
    j = JsonObjectSet(j, "last_tick",     JsonInt   (SqlGetInt   (q, 4)));
    j = JsonObjectSet(j, "borrowed_at",   JsonInt   (SqlGetInt   (q, 5)));
    j = JsonObjectSet(j, "penalty_level", JsonInt   (SqlGetInt   (q, 6)));
    j = JsonObjectSet(j, "total_repaid",  JsonInt   (SqlGetInt   (q, 7)));
    return j;
}

// Calculates and applies all elapsed hourly ticks; returns updated debt (0 = no loan)
int LchTickInterest(object oPC)
{
    json jLoan = LchGetLoan(oPC);
    if(JsonGetType(jLoan) == JSON_TYPE_NULL) return 0;

    int   nDebt     = JsonGetInt  (JsonObjectGet(jLoan, "current_debt"));
    float fRate     = JsonGetFloat(JsonObjectGet(jLoan, "interest_rate"));
    int   nLastTick = JsonGetInt  (JsonObjectGet(jLoan, "last_tick"));
    int   nNow      = LchNow();
    int   nElapsed  = nNow - nLastTick;

    if(nElapsed < LCH_TICK_SECONDS) return nDebt;

    int nTicks   = nElapsed / LCH_TICK_SECONDS;
    int nNewTick = nLastTick + nTicks * LCH_TICK_SECONDS;
    int i;
    for(i = 0; i < nTicks; i++)
        nDebt = FloatToInt(IntToFloat(nDebt) * (1.0 + fRate));

    sqlquery q = SqlPrepareQueryCampaign("lichwiarz",
        "UPDATE lch_loans SET current_debt = @debt, last_tick = @tick WHERE uuid = @uuid");
    SqlBindInt   (q, "@debt", nDebt);
    SqlBindInt   (q, "@tick", nNewTick);
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlStep(q);
    return nDebt;
}

// Creates or extends a loan for oPC by nAmount
void LchBorrow(object oPC, int nAmount)
{
    int  nNow  = LchNow();
    json jLoan = LchGetLoan(oPC);

    if(JsonGetType(jLoan) == JSON_TYPE_NULL)
    {
        sqlquery q = SqlPrepareQueryCampaign("lichwiarz",
            "INSERT INTO lch_loans (uuid, char_name, principal, current_debt, interest_rate, last_tick, borrowed_at, penalty_level, total_repaid) VALUES (@uuid, @name, @amt, @amt, @rate, @now, @now, 0, 0)");
        SqlBindString(q, "@uuid", GetObjectUUID(oPC));
        SqlBindString(q, "@name", GetName(oPC));
        SqlBindInt   (q, "@amt",  nAmount);
        SqlBindFloat (q, "@rate", LCH_BASE_RATE);
        SqlBindInt   (q, "@now",  nNow);
        SqlStep(q);
    }
    else
    {
        int nPrincipal = JsonGetInt(JsonObjectGet(jLoan, "principal"));
        int nDebt      = JsonGetInt(JsonObjectGet(jLoan, "current_debt"));
        sqlquery q = SqlPrepareQueryCampaign("lichwiarz",
            "UPDATE lch_loans SET principal = @p, current_debt = @d, last_tick = @now, char_name = @name WHERE uuid = @uuid");
        SqlBindInt   (q, "@p",    nPrincipal + nAmount);
        SqlBindInt   (q, "@d",    nDebt + nAmount);
        SqlBindInt   (q, "@now",  nNow);
        SqlBindString(q, "@name", GetName(oPC));
        SqlBindString(q, "@uuid", GetObjectUUID(oPC));
        SqlStep(q);
    }
}

// Applies a partial payment; deletes record when fully repaid.
// Returns remaining debt (0 = loan cleared).
int LchRepay(object oPC, int nAmount)
{
    json jLoan = LchGetLoan(oPC);
    if(JsonGetType(jLoan) == JSON_TYPE_NULL) return 0;

    int nDebt   = JsonGetInt(JsonObjectGet(jLoan, "current_debt"));
    int nRepaid = JsonGetInt(JsonObjectGet(jLoan, "total_repaid"));

    if(nAmount >= nDebt)
    {
        sqlquery q = SqlPrepareQueryCampaign("lichwiarz",
            "DELETE FROM lch_loans WHERE uuid = @uuid");
        SqlBindString(q, "@uuid", GetObjectUUID(oPC));
        SqlStep(q);
        return 0;
    }

    int nNewDebt = nDebt - nAmount;
    sqlquery q = SqlPrepareQueryCampaign("lichwiarz",
        "UPDATE lch_loans SET current_debt = @debt, total_repaid = @repaid, penalty_level = 0 WHERE uuid = @uuid");
    SqlBindInt   (q, "@debt",   nNewDebt);
    SqlBindInt   (q, "@repaid", nRepaid + nAmount);
    SqlBindString(q, "@uuid",   GetObjectUUID(oPC));
    SqlStep(q);
    return nNewDebt;
}

void LchSetPenaltyLevel(object oPC, int nLevel)
{
    sqlquery q = SqlPrepareQueryCampaign("lichwiarz",
        "UPDATE lch_loans SET penalty_level = @level WHERE uuid = @uuid");
    SqlBindInt   (q, "@level", nLevel);
    SqlBindString(q, "@uuid",  GetObjectUUID(oPC));
    SqlStep(q);
}

// Seconds remaining until next interest tick (0 if overdue)
int LchSecondsUntilNextTick(object oPC)
{
    json jLoan = LchGetLoan(oPC);
    if(JsonGetType(jLoan) == JSON_TYPE_NULL) return 0;
    int nLastTick = JsonGetInt(JsonObjectGet(jLoan, "last_tick"));
    int nNow      = LchNow();
    int nElapsed  = nNow - nLastTick;
    if(nElapsed >= LCH_TICK_SECONDS) return 0;
    return LCH_TICK_SECONDS - nElapsed;
}

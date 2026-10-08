#include "lib_mor_def"

// Creates tables if they don't exist.
void MorCreateTables()
{
    // Per-character morale stored keyed by PC UUID; also records last rest time.
    sqlquery q = SqlPrepareQueryCampaign(MOR_DB,
        "CREATE TABLE IF NOT EXISTS mor_morale ("
        "  uuid       TEXT PRIMARY KEY,"
        "  char_name  TEXT DEFAULT '',"
        "  morale     INTEGER DEFAULT 100,"
        "  updated_at INTEGER DEFAULT 0"
        ")");
    SqlStep(q);
}

// Upsert morale for PC.
void MorSave(object oPC, int nMorale)
{
    sqlquery q = SqlPrepareQueryCampaign(MOR_DB,
        "INSERT INTO mor_morale (uuid, char_name, morale, updated_at)"
        " VALUES (@uuid, @name, @morale, strftime('%s','now'))"
        " ON CONFLICT(uuid) DO UPDATE SET"
        "   char_name  = excluded.char_name,"
        "   morale     = excluded.morale,"
        "   updated_at = excluded.updated_at");
    SqlBindString(q, "@uuid",   GetObjectUUID(oPC));
    SqlBindString(q, "@name",   GetName(oPC));
    SqlBindInt   (q, "@morale", nMorale);
    SqlStep(q);
}

// Load morale for PC; returns MOR_MAX if no record.
int MorLoad(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign(MOR_DB,
        "SELECT morale FROM mor_morale WHERE uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return MOR_MAX;
}

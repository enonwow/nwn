// sql_slm.nss — SQL schema and query functions for the Words of Power module

void SlmCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("slm",
        "CREATE TABLE IF NOT EXISTS slm_known_words ("
        "  uuid     TEXT NOT NULL,"
        "  word_id  INTEGER NOT NULL,"
        "  PRIMARY KEY (uuid, word_id)"
        ")");
    SqlStep(q);

    // slot 0..5 per character; elem/target/power store word IDs
    q = SqlPrepareQueryCampaign("slm",
        "CREATE TABLE IF NOT EXISTS slm_incantations ("
        "  uuid    TEXT    NOT NULL,"
        "  slot    INTEGER NOT NULL,"
        "  elem    INTEGER NOT NULL,"
        "  target  INTEGER NOT NULL,"
        "  power   INTEGER NOT NULL,"
        "  PRIMARY KEY (uuid, slot)"
        ")");
    SqlStep(q);
}

int SlmKnowsWord(object oPC, int nWordId)
{
    sqlquery q = SqlPrepareQueryCampaign("slm",
        "SELECT 1 FROM slm_known_words WHERE uuid = @uuid AND word_id = @wid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@wid",  nWordId);
    return SqlStep(q);
}

void SlmLearnWord(object oPC, int nWordId)
{
    sqlquery q = SqlPrepareQueryCampaign("slm",
        "INSERT OR IGNORE INTO slm_known_words (uuid, word_id) VALUES (@uuid, @wid)");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@wid",  nWordId);
    SqlStep(q);
}

void SlmLearnAllWords(object oPC)
{
    int i;
    for(i = 1; i <= 6; i++)  SlmLearnWord(oPC, i);      // elements
    for(i = 11; i <= 14; i++) SlmLearnWord(oPC, i);     // targets
    for(i = 21; i <= 23; i++) SlmLearnWord(oPC, i);     // powers
}

// Returns JsonArray of known word_ids
json SlmGetKnownWords(object oPC)
{
    json jWords = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("slm",
        "SELECT word_id FROM slm_known_words WHERE uuid = @uuid ORDER BY word_id");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
        jWords = JsonArrayInsert(jWords, JsonInt(SqlGetInt(q, 0)));
    return jWords;
}

void SlmSaveIncantation(object oPC, int nSlot, int nElem, int nTarget, int nPower)
{
    sqlquery q = SqlPrepareQueryCampaign("slm",
        "INSERT OR REPLACE INTO slm_incantations (uuid, slot, elem, target, power) "
        "VALUES (@uuid, @slot, @elem, @target, @power)");
    SqlBindString(q, "@uuid",   GetObjectUUID(oPC));
    SqlBindInt   (q, "@slot",   nSlot);
    SqlBindInt   (q, "@elem",   nElem);
    SqlBindInt   (q, "@target", nTarget);
    SqlBindInt   (q, "@power",  nPower);
    SqlStep(q);
}

void SlmDeleteIncantation(object oPC, int nSlot)
{
    sqlquery q = SqlPrepareQueryCampaign("slm",
        "DELETE FROM slm_incantations WHERE uuid = @uuid AND slot = @slot");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@slot", nSlot);
    SqlStep(q);
}

// Returns JsonArray of {slot, elem, target, power} objects, sorted by slot
json SlmGetIncantations(object oPC)
{
    json jList = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("slm",
        "SELECT slot, elem, target, power FROM slm_incantations "
        "WHERE uuid = @uuid ORDER BY slot");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json jEntry = JsonObject();
        jEntry = JsonObjectSet(jEntry, "slot",   JsonInt(SqlGetInt(q, 0)));
        jEntry = JsonObjectSet(jEntry, "elem",   JsonInt(SqlGetInt(q, 1)));
        jEntry = JsonObjectSet(jEntry, "target", JsonInt(SqlGetInt(q, 2)));
        jEntry = JsonObjectSet(jEntry, "power",  JsonInt(SqlGetInt(q, 3)));
        jList = JsonArrayInsert(jList, jEntry);
    }
    return jList;
}

// Returns single incantation row or JsonNull()
json SlmGetIncantationBySlot(object oPC, int nSlot)
{
    sqlquery q = SqlPrepareQueryCampaign("slm",
        "SELECT slot, elem, target, power FROM slm_incantations "
        "WHERE uuid = @uuid AND slot = @slot");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@slot", nSlot);
    if(!SqlStep(q)) return JsonNull();
    json jEntry = JsonObject();
    jEntry = JsonObjectSet(jEntry, "slot",   JsonInt(SqlGetInt(q, 0)));
    jEntry = JsonObjectSet(jEntry, "elem",   JsonInt(SqlGetInt(q, 1)));
    jEntry = JsonObjectSet(jEntry, "target", JsonInt(SqlGetInt(q, 2)));
    jEntry = JsonObjectSet(jEntry, "power",  JsonInt(SqlGetInt(q, 3)));
    return jEntry;
}


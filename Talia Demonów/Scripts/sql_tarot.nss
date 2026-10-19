#include "lib_tarot_def"

// ----------------------------------------------------------------
// Schema
// ----------------------------------------------------------------

void TarotInitDB()
{
    SqlStep(SqlPrepareQueryCampaign(GetModule(),
        "CREATE TABLE IF NOT EXISTS tarot_drawn ("
        "  pc_uuid    TEXT    NOT NULL,"
        "  card_id    INTEGER NOT NULL,"
        "  drawn_at   INTEGER NOT NULL DEFAULT 0,"
        "  draw_count INTEGER NOT NULL DEFAULT 1,"
        "  PRIMARY KEY (pc_uuid, card_id)"
        ")"));
}

// ----------------------------------------------------------------
// Writes
// ----------------------------------------------------------------

void TarotRecordDraw(object oPC, int nCardId)
{
    string sUUID = GetObjectUUID(oPC);
    int nNow = GetCalendarYear() * 10000 + GetCalendarMonth() * 100 + GetCalendarDay();

    sqlquery q = SqlPrepareQueryCampaign(GetModule(),
        "INSERT INTO tarot_drawn (pc_uuid, card_id, drawn_at, draw_count) "
        "VALUES (@u, @c, @t, 1) "
        "ON CONFLICT(pc_uuid, card_id) "
        "DO UPDATE SET draw_count = draw_count + 1, drawn_at = @t");
    SqlBindString(q, "@u", sUUID);
    SqlBindInt   (q, "@c", nCardId);
    SqlBindInt   (q, "@t", nNow);
    SqlStep(q);
}

void TarotResetDeck(object oPC)
{
    string sUUID = GetObjectUUID(oPC);
    sqlquery q = SqlPrepareQueryCampaign(GetModule(),
        "DELETE FROM tarot_drawn WHERE pc_uuid = @u");
    SqlBindString(q, "@u", sUUID);
    SqlStep(q);
}

// ----------------------------------------------------------------
// Reads
// ----------------------------------------------------------------

// Returns JsonArray of { card_id, draw_count, drawn_at }
json TarotGetDrawnCards(object oPC)
{
    string sUUID = GetObjectUUID(oPC);
    sqlquery q = SqlPrepareQueryCampaign(GetModule(),
        "SELECT card_id, draw_count, drawn_at "
        "FROM tarot_drawn WHERE pc_uuid = @u "
        "ORDER BY drawn_at ASC");
    SqlBindString(q, "@u", sUUID);

    json jResult = JsonArray();
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "card_id",    JsonInt(SqlGetInt(q, 0)));
        jRow = JsonObjectSet(jRow, "draw_count", JsonInt(SqlGetInt(q, 1)));
        jRow = JsonObjectSet(jRow, "drawn_at",   JsonInt(SqlGetInt(q, 2)));
        jResult = JsonArrayInsert(jResult, jRow);
    }
    return jResult;
}

int TarotGetDrawnCount(object oPC)
{
    string sUUID = GetObjectUUID(oPC);
    sqlquery q = SqlPrepareQueryCampaign(GetModule(),
        "SELECT COUNT(*) FROM tarot_drawn WHERE pc_uuid = @u");
    SqlBindString(q, "@u", sUUID);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns draw_count for the given card (0 = not drawn)
int TarotGetCardDrawCount(object oPC, int nCardId)
{
    string sUUID = GetObjectUUID(oPC);
    sqlquery q = SqlPrepareQueryCampaign(GetModule(),
        "SELECT draw_count FROM tarot_drawn "
        "WHERE pc_uuid = @u AND card_id = @c");
    SqlBindString(q, "@u", sUUID);
    SqlBindInt   (q, "@c", nCardId);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

// Returns a random undrawn card ID, or -1 if all have been drawn
int TarotPickRandomUndrawn(object oPC)
{
    // Load drawn flags into module-level temp vars
    object oMod = GetModule();
    string sUUID = GetObjectUUID(oPC);

    sqlquery q = SqlPrepareQueryCampaign(GetModule(),
        "SELECT card_id FROM tarot_drawn WHERE pc_uuid = @u");
    SqlBindString(q, "@u", sUUID);

    int i;
    for(i = 0; i < TAROT_CARD_COUNT; i++)
        SetLocalInt(oMod, "TAROT_TMP_" + IntToString(i), 0);

    while(SqlStep(q))
        SetLocalInt(oMod, "TAROT_TMP_" + IntToString(SqlGetInt(q, 0)), 1);

    // Build pool of undrawn cards
    json jPool = JsonArray();
    for(i = 0; i < TAROT_CARD_COUNT; i++)
    {
        if(!GetLocalInt(oMod, "TAROT_TMP_" + IntToString(i)))
            jPool = JsonArrayInsert(jPool, JsonInt(i));
        DeleteLocalInt(oMod, "TAROT_TMP_" + IntToString(i));
    }

    int nCount = JsonGetLength(jPool);
    if(nCount == 0) return -1;
    return JsonGetInt(JsonArrayGet(jPool, Random(nCount)));
}

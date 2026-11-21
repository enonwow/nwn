// Schemat:
//   msk_masks  — definicje dostepnych masek (globalne)
//   msk_owned  — ktory gracz posiada ktora maske
//
// Maska nie jest niszczona z bazy po "spaleniu" — tylko oznaczana burned.
// Pozwala to na logi i potencjalne resety przez DM.

void MskCreateTables()
{
    sqlquery q;

    q = SqlPrepareQueryCampaign("masquerade",
        "CREATE TABLE IF NOT EXISTS msk_masks ("
        " id       INTEGER PRIMARY KEY AUTOINCREMENT,"
        " tag      TEXT    NOT NULL UNIQUE,"
        " name     TEXT    NOT NULL DEFAULT 'Nieznana',"
        " flavor   TEXT    NOT NULL DEFAULT '',"
        " susp_rate INTEGER NOT NULL DEFAULT 1"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("masquerade",
        "CREATE TABLE IF NOT EXISTS msk_owned ("
        " id        INTEGER PRIMARY KEY AUTOINCREMENT,"
        " pc_uuid   TEXT NOT NULL,"
        " mask_id   INTEGER NOT NULL,"
        " burned    INTEGER NOT NULL DEFAULT 0,"
        " acquired  INTEGER NOT NULL DEFAULT (strftime('%s','now')),"
        " UNIQUE(pc_uuid, mask_id)"
        ")");
    SqlStep(q);

    // Seed domyslne maski jesli tabela pusta
    q = SqlPrepareQueryCampaign("masquerade",
        "SELECT COUNT(*) FROM msk_masks");
    if(SqlStep(q) && SqlGetInt(q, 0) == 0)
        MskSeedDefaultMasks();
}

void MskSeedDefaultMasks()
{
    struct SMskSeed { string tag; string name; string flavor; int rate; };

    // Wewnetrzna lista startowych masek — modul dostarcza je jako definicje;
    // fizyczne itemy w haku moga sie roznic.
    sqlquery ins = SqlPrepareQueryCampaign("masquerade",
        "INSERT OR IGNORE INTO msk_masks (tag, name, flavor, susp_rate)"
        " VALUES (@tag, @name, @flavor, @rate)");

    SqlBindString(ins, "@tag",    "msk_mask_merchant");
    SqlBindString(ins, "@name",   "Oblicze Kupca");
    SqlBindString(ins, "@flavor", "Twarz spokojnego handlarza, bez blizn i bez historii. Kto by podejrzal mieszczanina?");
    SqlBindInt   (ins, "@rate",   1);
    SqlStep(ins);

    SqlBindString(ins, "@tag",    "msk_mask_guard");
    SqlBindString(ins, "@name",   "Oblicze Straznika");
    SqlBindString(ins, "@flavor", "Surowe rysy, obcieta broda — twarz, ktora wydaje rozkazy i nie pyta o pozwolenie.");
    SqlBindInt   (ins, "@rate",   2);
    SqlStep(ins);

    SqlBindString(ins, "@tag",    "msk_mask_noble");
    SqlBindString(ins, "@name",   "Oblicze Szlachcica");
    SqlBindString(ins, "@flavor", "Wyniosle spojrzenie i pietnastka przy pasie. Nikt nie smieje sie z czlowieka w aksamicie.");
    SqlBindInt   (ins, "@rate",   1);
    SqlStep(ins);

    SqlBindString(ins, "@tag",    "msk_mask_pilgrim");
    SqlBindString(ins, "@name",   "Oblicze Pielgrzyma");
    SqlBindString(ins, "@flavor", "Kaptur zaslanial twarz przez trzy tygodnie drogi. Nikomu nie zalezy, kogo kryje.");
    SqlBindInt   (ins, "@rate",   1);
    SqlStep(ins);

    SqlBindString(ins, "@tag",    "msk_mask_executioner");
    SqlBindString(ins, "@name",   "Oblicze Kata");
    SqlBindString(ins, "@flavor", "Czarna maska bez otworow na oczy — jedyni, ktorzy ja nosza, widza przez nia doskonale.");
    SqlBindInt   (ins, "@rate",   3);
    SqlStep(ins);
}

// Rejestracja maski przez tag itemu (wywolana przy wejsciu lub OnPickUp)
void MskRegisterMaskForPC(object oPC, string sTag)
{
    sqlquery qFind = SqlPrepareQueryCampaign("masquerade",
        "SELECT id FROM msk_masks WHERE tag = @tag");
    SqlBindString(qFind, "@tag", sTag);
    if(!SqlStep(qFind)) return;
    int nMaskId = SqlGetInt(qFind, 0);

    sqlquery qOwn = SqlPrepareQueryCampaign("masquerade",
        "INSERT OR IGNORE INTO msk_owned (pc_uuid, mask_id)"
        " VALUES (@uuid, @mid)");
    SqlBindString(qOwn, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (qOwn, "@mid",  nMaskId);
    SqlStep(qOwn);
}

// Zwraca JsonArray [{own_id, mask_id, name, flavor, susp_rate, burned}, ...]
json MskGetOwnedMasks(object oPC)
{
    json jRows = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign("masquerade",
        "SELECT o.id, o.mask_id, m.name, m.flavor, m.susp_rate, o.burned"
        " FROM msk_owned o"
        " JOIN msk_masks m ON m.id = o.mask_id"
        " WHERE o.pc_uuid = @uuid"
        " ORDER BY o.acquired ASC");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json jRow = JsonObject();
        jRow = JsonObjectSet(jRow, "own_id",    JsonInt   (SqlGetInt   (q, 0)));
        jRow = JsonObjectSet(jRow, "mask_id",   JsonInt   (SqlGetInt   (q, 1)));
        jRow = JsonObjectSet(jRow, "name",      JsonString(SqlGetString(q, 2)));
        jRow = JsonObjectSet(jRow, "flavor",    JsonString(SqlGetString(q, 3)));
        jRow = JsonObjectSet(jRow, "susp_rate", JsonInt   (SqlGetInt   (q, 4)));
        jRow = JsonObjectSet(jRow, "burned",    JsonInt   (SqlGetInt   (q, 5)));
        jRows = JsonArrayInsert(jRows, jRow);
    }
    return jRows;
}

json MskGetMaskById(int nMaskId)
{
    sqlquery q = SqlPrepareQueryCampaign("masquerade",
        "SELECT id, name, flavor, susp_rate FROM msk_masks WHERE id = @id");
    SqlBindInt(q, "@id", nMaskId);
    if(!SqlStep(q)) return JsonNull();
    json j = JsonObject();
    j = JsonObjectSet(j, "id",        JsonInt   (SqlGetInt   (q, 0)));
    j = JsonObjectSet(j, "name",      JsonString(SqlGetString(q, 1)));
    j = JsonObjectSet(j, "flavor",    JsonString(SqlGetString(q, 2)));
    j = JsonObjectSet(j, "susp_rate", JsonInt   (SqlGetInt   (q, 3)));
    return j;
}

void MskBurnMask(object oPC, int nMaskId)
{
    sqlquery q = SqlPrepareQueryCampaign("masquerade",
        "UPDATE msk_owned SET burned = 1"
        " WHERE pc_uuid = @uuid AND mask_id = @mid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@mid",  nMaskId);
    SqlStep(q);
}

void MskRestoreMask(object oPC, int nMaskId)
{
    sqlquery q = SqlPrepareQueryCampaign("masquerade",
        "UPDATE msk_owned SET burned = 0"
        " WHERE pc_uuid = @uuid AND mask_id = @mid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@mid",  nMaskId);
    SqlStep(q);
}

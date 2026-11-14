void IntrCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign("intr",
        "CREATE TABLE IF NOT EXISTS intr_confessions ("
        "  resref      TEXT NOT NULL,"
        "  threshold   INTEGER NOT NULL,"
        "  secret_text TEXT DEFAULT '',"
        "  PRIMARY KEY (resref, threshold)"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("intr",
        "CREATE TABLE IF NOT EXISTS intr_sessions ("
        "  id            INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  pc_uuid       TEXT NOT NULL,"
        "  prisoner_uuid TEXT NOT NULL,"
        "  broken        INTEGER DEFAULT 0,"
        "  moral_cost    INTEGER DEFAULT 0,"
        "  timestamp     INTEGER DEFAULT (strftime('%s','now'))"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("intr",
        "CREATE TABLE IF NOT EXISTS intr_conflog ("
        "  id             INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  pc_uuid        TEXT NOT NULL,"
        "  prisoner_uuid  TEXT NOT NULL,"
        "  prisoner_name  TEXT DEFAULT '',"
        "  threshold      INTEGER NOT NULL,"
        "  secret_text    TEXT DEFAULT '',"
        "  timestamp      INTEGER DEFAULT (strftime('%s','now'))"
        ")");
    SqlStep(q);
}

string IntrGetConfession(string sResRef, int nThreshold)
{
    sqlquery q = SqlPrepareQueryCampaign("intr",
        "SELECT secret_text FROM intr_confessions "
        "WHERE resref = @resref AND threshold = @threshold");
    SqlBindString(q, "@resref",    sResRef);
    SqlBindInt   (q, "@threshold", nThreshold);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "";
}

string IntrGetGenericSecret(int nRacialType, int nThreshold)
{
    if(   nRacialType == RACIAL_TYPE_HUMAN
       || nRacialType == RACIAL_TYPE_HALFORC
       || nRacialType == RACIAL_TYPE_HALFELF
       || nRacialType == RACIAL_TYPE_DWARF
       || nRacialType == RACIAL_TYPE_ELF
       || nRacialType == RACIAL_TYPE_GNOME
       || nRacialType == RACIAL_TYPE_HALFLING)
    {
        if(nThreshold == 75) return "Spotykamy sie o swicie przy starym kamieniu za mlynarstwem.";
        if(nThreshold == 50) return "Haslo to 'Czerwona gwiazda'. Dowodca czeka w karczmie Pod Krukiem.";
        if(nThreshold == 25) return "Magazyn broni jest pod piwnica swierni starej — wejscie od strony rzeki.";
        if(nThreshold == 0)  return "Lord Varen sprzedal miasto... za zloto i obietnice wiecznosci. Mam na niego dowody!";
    }

    if(nRacialType == RACIAL_TYPE_UNDEAD)
    {
        if(nThreshold == 75) return "Poczulem smierc... lecz nie odszedlem. Ktos mnie przyzwal z powrotem.";
        if(nThreshold == 50) return "Mistrz czeka pod Ruinami Kolmaru. Wchodzi sie przez krypty.";
        if(nThreshold == 25) return "Rytual wymaga pieciu serc zertwowanych przy pelni.";
        if(nThreshold == 0)  return "Liksz nie moze umrzec — jego filar bije pod posadzka katedry!";
    }

    if(nRacialType == RACIAL_TYPE_HUMANOID_GOBLINOID)
    {
        if(nThreshold == 75) return "Plemie spi w jaskiniach pod wodospadem za wioska.";
        if(nThreshold == 50) return "Szaman ma kamien, ktory mowi glosem Ciemnosci.";
        if(nThreshold == 25) return "Goblin-Krul odkryl wejscie do starszych katakumb pod zamkiem.";
        if(nThreshold == 0)  return "Wielki Czerwony Orc szykuje najazd. Przyjdzie przy pelni ksiezyca!";
    }

    if(nRacialType == RACIAL_TYPE_OUTSIDER)
    {
        if(nThreshold == 75) return "Cierpienie jest dla mnie... slodkie. Ale nie aZ tak slodkie.";
        if(nThreshold == 50) return "Mam pakt. Zadna sila nie zerwie go bez zgody Nizszych Warstw.";
        if(nThreshold == 25) return "Istnieja wrota — cien bez ciala strzeze ich od wiekow.";
        if(nThreshold == 0)  return "Sigil krwi jest wyryty na progach kazdego kosciola w tym miescie!";
    }

    if(nThreshold == 75) return "Powiem... ale nie tutaj...";
    if(nThreshold == 50) return "Nie znam calej prawdy...";
    if(nThreshold == 25) return "Juz dosc! Powiem wszystko!";
    return "Laskawosci... prosze o laskawosci...";
}

void IntrAddConfession(string sResRef, int nThreshold, string sText)
{
    sqlquery q = SqlPrepareQueryCampaign("intr",
        "INSERT OR REPLACE INTO intr_confessions (resref, threshold, secret_text) "
        "VALUES (@r, @t, @s)");
    SqlBindString(q, "@r", sResRef);
    SqlBindInt   (q, "@t", nThreshold);
    SqlBindString(q, "@s", sText);
    SqlStep(q);
}

void IntrLogSession(string sPcUUID, string sPrisonerUUID, int nBroken, int nMoral)
{
    sqlquery q = SqlPrepareQueryCampaign("intr",
        "INSERT INTO intr_sessions (pc_uuid, prisoner_uuid, broken, moral_cost) "
        "VALUES (@p, @c, @b, @m)");
    SqlBindString(q, "@p", sPcUUID);
    SqlBindString(q, "@c", sPrisonerUUID);
    SqlBindInt   (q, "@b", nBroken);
    SqlBindInt   (q, "@m", nMoral);
    SqlStep(q);
}

void IntrLogConfession(string sPcUUID, string sPrisonerUUID,
                       string sPrisonerName, int nThreshold, string sText)
{
    sqlquery q = SqlPrepareQueryCampaign("intr",
        "INSERT INTO intr_conflog "
        "  (pc_uuid, prisoner_uuid, prisoner_name, threshold, secret_text) "
        "VALUES (@p, @c, @n, @t, @s)");
    SqlBindString(q, "@p", sPcUUID);
    SqlBindString(q, "@c", sPrisonerUUID);
    SqlBindString(q, "@n", sPrisonerName);
    SqlBindInt   (q, "@t", nThreshold);
    SqlBindString(q, "@s", sText);
    SqlStep(q);
}

int IntrGetTotalBroken(string sPcUUID)
{
    sqlquery q = SqlPrepareQueryCampaign("intr",
        "SELECT COUNT(*) FROM intr_sessions WHERE pc_uuid = @p AND broken = 1");
    SqlBindString(q, "@p", sPcUUID);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

int IntrGetTotalSessions(string sPcUUID)
{
    sqlquery q = SqlPrepareQueryCampaign("intr",
        "SELECT COUNT(*) FROM intr_sessions WHERE pc_uuid = @p");
    SqlBindString(q, "@p", sPcUUID);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

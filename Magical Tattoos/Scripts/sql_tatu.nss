// SQL schema and queries for the Magical Tattoos module.
// Campaign DB name: "tatu"

const string TATU_DB = "tatu";

// ----------------------------------------------------------------
// Schema
// ----------------------------------------------------------------

void TatuCreateTables()
{
    sqlquery q = SqlPrepareQueryCampaign(TATU_DB,
        "CREATE TABLE IF NOT EXISTS tatu_designs ("
        "id INTEGER PRIMARY KEY,"
        "name TEXT NOT NULL DEFAULT '',"
        "description TEXT DEFAULT '',"
        "slot TEXT NOT NULL DEFAULT '',"
        "cost_gold INTEGER DEFAULT 0,"
        "cost_item TEXT DEFAULT '',"
        "bon_ab INTEGER DEFAULT 0,"
        "bon_ac INTEGER DEFAULT 0,"
        "bon_skill INTEGER DEFAULT -1,"
        "bon_skill_v INTEGER DEFAULT 0,"
        "bon_save INTEGER DEFAULT -1,"
        "bon_save_v INTEGER DEFAULT 0,"
        "bon_resist INTEGER DEFAULT 0,"
        "is_cursed INTEGER DEFAULT 0,"
        "curse_desc TEXT DEFAULT '',"
        "curse_ab INTEGER DEFAULT 0,"
        "curse_saves INTEGER DEFAULT 0,"
        "curse_cha INTEGER DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign(TATU_DB,
        "CREATE TABLE IF NOT EXISTS tatu_pc ("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "pc_uuid TEXT NOT NULL,"
        "design_id INTEGER NOT NULL,"
        "slot TEXT NOT NULL,"
        "applied_at INTEGER DEFAULT 0,"
        "UNIQUE(pc_uuid, slot)"
        ")");
    SqlStep(q);
}

// ----------------------------------------------------------------
// Design seeding
// ----------------------------------------------------------------

void TatuSeedOne(int nId, string sName, string sDesc, string sSlot,
                 int nGold, string sItem,
                 int nBonAb, int nBonAc, int nBonSk, int nBonSkV,
                 int nBonSv, int nBonSvV, int nBonRs,
                 int bCursed, string sCurseDesc,
                 int nCurAb, int nCurSv, int nCurCha)
{
    sqlquery q = SqlPrepareQueryCampaign(TATU_DB,
        "INSERT OR IGNORE INTO tatu_designs "
        "(id,name,description,slot,cost_gold,cost_item,"
        " bon_ab,bon_ac,bon_skill,bon_skill_v,bon_save,bon_save_v,bon_resist,"
        " is_cursed,curse_desc,curse_ab,curse_saves,curse_cha) "
        "VALUES (@id,@nm,@ds,@sl,@cg,@ci,"
        " @ba,@bc,@bsk,@bskv,@bsv,@bsvv,@br,"
        " @ic,@cd,@cab,@csv,@ccha)");
    SqlBindInt   (q, "@id",   nId);
    SqlBindString(q, "@nm",   sName);
    SqlBindString(q, "@ds",   sDesc);
    SqlBindString(q, "@sl",   sSlot);
    SqlBindInt   (q, "@cg",   nGold);
    SqlBindString(q, "@ci",   sItem);
    SqlBindInt   (q, "@ba",   nBonAb);
    SqlBindInt   (q, "@bc",   nBonAc);
    SqlBindInt   (q, "@bsk",  nBonSk);
    SqlBindInt   (q, "@bskv", nBonSkV);
    SqlBindInt   (q, "@bsv",  nBonSv);
    SqlBindInt   (q, "@bsvv", nBonSvV);
    SqlBindInt   (q, "@br",   nBonRs);
    SqlBindInt   (q, "@ic",   bCursed);
    SqlBindString(q, "@cd",   sCurseDesc);
    SqlBindInt   (q, "@cab",  nCurAb);
    SqlBindInt   (q, "@csv",  nCurSv);
    SqlBindInt   (q, "@ccha", nCurCha);
    SqlStep(q);
}

void TatuSeedDesigns()
{
    // Slot GLOWA — 2 designs
    TatuSeedOne(1,
        "Szpon Wrona",
        "Symbol kruczego szponu wyryty na czole igłą maczaną w atramencie "
        "z piór nocnych ptaków. Kto nosi ten znak, atakuje z chyżością "
        "i precyzją drapieżnika.",
        "GLOWA", 80, "ink_crow",
        2, 0, -1, 0, -1, 0, 0,
        0, "", 0, 0, 0);

    TatuSeedOne(2,
        "Oko Proroka",
        "Spirala wokół lewego oka wytrawiona atramentem wizji ze źrenicy "
        "widziadłowego ptaka. Obdarza noszącego ponadnaturalną "
        "spostrzegawczością — każdy cień staje się czytelny.",
        "GLOWA", 60, "ink_sight",
        0, 0, 17, 3, -1, 0, 0,
        0, "", 0, 0, 0);

    // Slot SZYJA — 2 designs
    TatuSeedOne(3,
        "Pieczęć Zarazy",
        "Czarny krąg na szyi otoczony wzorem robaków toczących trupią skórę. "
        "Trucizny i choroby omijają ciało noszącego jak wodę omija rynna — "
        "lecz ci, którzy go widzą, odwracają wzrok z odrazą.",
        "SZYJA", 80, "ink_bile",
        0, 0, -1, 0, 1, 3, 0,
        1, "Widok pieczęci budzi wstręt — Charyzma –2.",
        0, 0, 2);

    TatuSeedOne(4,
        "Kość Milczenia",
        "Wzór wyryty z proszku kości pokruszonych pod księżycem w pełni. "
        "Skupia umysł noszącego jak ostrze skalpela — pozwala zachować "
        "zimną krew nawet gdy piekło kipi wokół.",
        "SZYJA", 70, "ink_bone",
        0, 0, 1, 3, -1, 0, 0,
        0, "", 0, 0, 0);

    // Slot PIERSI — 3 designs
    TatuSeedOne(5,
        "Serce Kamienia",
        "Pełna klatka piersiowa pokryta geometrycznym wzorem skały wulkanicznej. "
        "Ciało staje się twardą powłoką odporną na ciosy — lecz twarz "
        "zastyga w chłodnym, kamiennym bezruchu.",
        "PIERSI", 120, "ink_stone",
        0, 2, -1, 0, -1, 0, 0,
        1, "Kamienna twarz odpycha ludzi — Charyzma –2.",
        0, 0, 2);

    TatuSeedOne(6,
        "Łańcuch Obrońcy",
        "Splot łańcuchów wijący się od obojczyka po żebra wzmacnia skórę "
        "jak zbroję z ciemnego żelaza. Żaden wzór nie oferuje tak "
        "skutecznej ochrony bez przekleństwa.",
        "PIERSI", 100, "ink_iron",
        0, 3, -1, 0, -1, 0, 0,
        0, "", 0, 0, 0);

    TatuSeedOne(7,
        "Blizna Ognia",
        "Fraktalne blizny po ogniu odnowione atramentem z popiołu salamandry. "
        "Skóra noszącego twardnieje na podmuch płomieni jak hartowana "
        "stal — ogień staje się jedynie ciepłym tchnieniem.",
        "PIERSI", 90, "ink_ash",
        0, 0, -1, 0, -1, 0, 10,
        0, "", 0, 0, 0);

    // Slot LEWE_RAMIE — 2 designs
    TatuSeedOne(8,
        "Skrzydła Nocy",
        "Para czarnych skrzydeł na lewym ramieniu — atrament ze smoły "
        "i skropionego cienia. Każdy krok noszącego staje się cichy "
        "jak lot sowy polującej w mrok.",
        "LEWE_RAMIE", 50, "ink_shadow",
        0, 0, 8, 4, -1, 0, 0,
        0, "", 0, 0, 0);

    TatuSeedOne(9,
        "Znak Złodzieja",
        "Sześć linii przecinających się w gwiezdny wzór wygnieciony "
        "na lewym nadgarstku. Dłoń staje się zwinna i niezauważalna — "
        "idealna do pracy w cudzej kieszeni.",
        "LEWE_RAMIE", 45, "ink_shadow",
        0, 0, 13, 3, -1, 0, 0,
        0, "", 0, 0, 0);

    // Slot PRAWE_RAMIE — 1 design
    TatuSeedOne(10,
        "Pięść Tyranta",
        "Wzór czarnych kolców spiralujących od łokcia po knykcie prawej ręki. "
        "Uderzenia stają się mordercze — lecz ciało żyje w permanentnym "
        "napięciu, drżąco reagując na każdą groźbę.",
        "PRAWE_RAMIE", 110, "ink_blood",
        2, 0, -1, 0, -1, 0, 0,
        1, "Nerwy w gotowości bojowej — wszystkie rzuty obronne –2.",
        0, 2, 0);
}

// ----------------------------------------------------------------
// Queries
// ----------------------------------------------------------------

json TatuRowToJson(sqlquery q)
{
    json j = JsonObject();
    j = JsonObjectSet(j, "id",          JsonInt   (SqlGetInt   (q, 0)));
    j = JsonObjectSet(j, "name",        JsonString(SqlGetString(q, 1)));
    j = JsonObjectSet(j, "description", JsonString(SqlGetString(q, 2)));
    j = JsonObjectSet(j, "slot",        JsonString(SqlGetString(q, 3)));
    j = JsonObjectSet(j, "cost_gold",   JsonInt   (SqlGetInt   (q, 4)));
    j = JsonObjectSet(j, "cost_item",   JsonString(SqlGetString(q, 5)));
    j = JsonObjectSet(j, "bon_ab",      JsonInt   (SqlGetInt   (q, 6)));
    j = JsonObjectSet(j, "bon_ac",      JsonInt   (SqlGetInt   (q, 7)));
    j = JsonObjectSet(j, "bon_skill",   JsonInt   (SqlGetInt   (q, 8)));
    j = JsonObjectSet(j, "bon_skill_v", JsonInt   (SqlGetInt   (q, 9)));
    j = JsonObjectSet(j, "bon_save",    JsonInt   (SqlGetInt   (q, 10)));
    j = JsonObjectSet(j, "bon_save_v",  JsonInt   (SqlGetInt   (q, 11)));
    j = JsonObjectSet(j, "bon_resist",  JsonInt   (SqlGetInt   (q, 12)));
    j = JsonObjectSet(j, "is_cursed",   JsonInt   (SqlGetInt   (q, 13)));
    j = JsonObjectSet(j, "curse_desc",  JsonString(SqlGetString(q, 14)));
    j = JsonObjectSet(j, "curse_ab",    JsonInt   (SqlGetInt   (q, 15)));
    j = JsonObjectSet(j, "curse_saves", JsonInt   (SqlGetInt   (q, 16)));
    j = JsonObjectSet(j, "curse_cha",   JsonInt   (SqlGetInt   (q, 17)));
    return j;
}

const string TATU_SELECT_COLS =
    "SELECT id,name,description,slot,cost_gold,cost_item,"
    " bon_ab,bon_ac,bon_skill,bon_skill_v,bon_save,bon_save_v,bon_resist,"
    " is_cursed,curse_desc,curse_ab,curse_saves,curse_cha"
    " FROM tatu_designs";

json TatuGetAllDesigns()
{
    json jArr = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(TATU_DB,
        TATU_SELECT_COLS + " ORDER BY slot, id");
    while(SqlStep(q))
        jArr = JsonArrayInsert(jArr, TatuRowToJson(q));
    return jArr;
}

json TatuGetDesignById(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign(TATU_DB,
        TATU_SELECT_COLS + " WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if(SqlStep(q)) return TatuRowToJson(q);
    return JsonNull();
}

json TatuGetPCTattoos(object oPC)
{
    json jArr = JsonArray();
    sqlquery q = SqlPrepareQueryCampaign(TATU_DB,
        "SELECT design_id, slot FROM tatu_pc WHERE pc_uuid = @uuid");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "design_id", JsonInt   (SqlGetInt   (q, 0)));
        j = JsonObjectSet(j, "slot",      JsonString(SqlGetString(q, 1)));
        jArr = JsonArrayInsert(jArr, j);
    }
    return jArr;
}

int TatuGetPCTattooDesignInSlot(object oPC, string sSlot)
{
    sqlquery q = SqlPrepareQueryCampaign(TATU_DB,
        "SELECT design_id FROM tatu_pc WHERE pc_uuid = @uuid AND slot = @slot");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@slot", sSlot);
    if(SqlStep(q)) return SqlGetInt(q, 0);
    return 0;
}

void TatuApplyTattoo(object oPC, int nDesignId, string sSlot)
{
    sqlquery q = SqlPrepareQueryCampaign(TATU_DB,
        "INSERT OR REPLACE INTO tatu_pc (pc_uuid, design_id, slot, applied_at)"
        " VALUES (@uuid, @did, @slot, strftime('%s','now'))");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@did",  nDesignId);
    SqlBindString(q, "@slot", sSlot);
    SqlStep(q);
}

void TatuRemoveTattoo(object oPC, string sSlot)
{
    sqlquery q = SqlPrepareQueryCampaign(TATU_DB,
        "DELETE FROM tatu_pc WHERE pc_uuid = @uuid AND slot = @slot");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindString(q, "@slot", sSlot);
    SqlStep(q);
}

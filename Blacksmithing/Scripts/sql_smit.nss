// Material item tags (must match tags on actual HAK items)
const string SMIT_TAG_IRON    = "smit_iron";
const string SMIT_TAG_BONE    = "smit_bone";
const string SMIT_TAG_LEATHER = "smit_leather";
const string SMIT_TAG_WOOD    = "smit_wood";
const string SMIT_TAG_GEM     = "smit_gem";

// Category strings
const string SMIT_CAT_WEAPON  = "Bron";
const string SMIT_CAT_ARMOR   = "Zbroja";
const string SMIT_CAT_SHIELD  = "Tarcza";

// Quality tier display names
const string SMIT_QUAL_1 = "Kruche";
const string SMIT_QUAL_2 = "Pospolite";
const string SMIT_QUAL_3 = "Dobre";
const string SMIT_QUAL_4 = "Wyborne";
const string SMIT_QUAL_5 = "Mistrzowskie";

const int SMIT_MAX_HISTORY = 15;
const int SMIT_MAX_MATS    = 4;

void SmithCreateTables()
{
    sqlquery q;

    q = SqlPrepareQueryCampaign("smith",
        "CREATE TABLE IF NOT EXISTS smith_recipes ("
        "  id             INTEGER PRIMARY KEY,"
        "  category       TEXT    NOT NULL,"
        "  name           TEXT    NOT NULL,"
        "  resref         TEXT    NOT NULL,"
        "  descr          TEXT    DEFAULT '',"
        "  materials_json TEXT    DEFAULT '[]',"
        "  craft_dc       INTEGER DEFAULT 10"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("smith",
        "CREATE TABLE IF NOT EXISTS smith_history ("
        "  id          INTEGER PRIMARY KEY AUTOINCREMENT,"
        "  pc_uuid     TEXT    NOT NULL,"
        "  recipe_id   INTEGER NOT NULL,"
        "  recipe_name TEXT    NOT NULL DEFAULT '',"
        "  quality     INTEGER NOT NULL DEFAULT 2,"
        "  forged_at   INTEGER NOT NULL DEFAULT 0"
        ")");
    SqlStep(q);

    q = SqlPrepareQueryCampaign("smith",
        "CREATE TABLE IF NOT EXISTS smith_meta ("
        "  key   TEXT PRIMARY KEY,"
        "  value TEXT DEFAULT ''"
        ")");
    SqlStep(q);
}

// ---- Recipe seeding ----

json SmithMat(string sTag, string sName, int nCount)
{
    json j = JsonObject();
    j = JsonObjectSet(j, "tag",   JsonString(sTag));
    j = JsonObjectSet(j, "name",  JsonString(sName));
    j = JsonObjectSet(j, "count", JsonInt(nCount));
    return j;
}

void SmithInsertRecipe(int nId, string sCategory, string sName, string sResRef,
                       string sDescr, json jMats, int nDC)
{
    sqlquery q = SqlPrepareQueryCampaign("smith",
        "INSERT OR IGNORE INTO smith_recipes "
        "(id,category,name,resref,descr,materials_json,craft_dc) "
        "VALUES (@id,@cat,@name,@res,@desc,@mats,@dc)");
    SqlBindInt   (q, "@id",   nId);
    SqlBindString(q, "@cat",  sCategory);
    SqlBindString(q, "@name", sName);
    SqlBindString(q, "@res",  sResRef);
    SqlBindString(q, "@desc", sDescr);
    SqlBindString(q, "@mats", JsonDump(jMats));
    SqlBindInt   (q, "@dc",   nDC);
    SqlStep(q);
}

void SmithSeedRecipes()
{
    sqlquery qCheck = SqlPrepareQueryCampaign("smith",
        "SELECT value FROM smith_meta WHERE key = 'seeded'");
    if(SqlStep(qCheck) && SqlGetString(qCheck, 0) == "1") return;

    json jIron1 = SmithMat(SMIT_TAG_IRON,    "Zelazna Sztabka",  1);
    json jIron2 = SmithMat(SMIT_TAG_IRON,    "Zelazna Sztabka",  2);
    json jIron3 = SmithMat(SMIT_TAG_IRON,    "Zelazna Sztabka",  3);
    json jIron4 = SmithMat(SMIT_TAG_IRON,    "Zelazna Sztabka",  4);
    json jIron5 = SmithMat(SMIT_TAG_IRON,    "Zelazna Sztabka",  5);
    json jIron6 = SmithMat(SMIT_TAG_IRON,    "Zelazna Sztabka",  6);
    json jBone2 = SmithMat(SMIT_TAG_BONE,    "Odlamek Kosci",    2);
    json jLeat1 = SmithMat(SMIT_TAG_LEATHER, "Pasek Skory",      1);
    json jLeat2 = SmithMat(SMIT_TAG_LEATHER, "Pasek Skory",      2);
    json jLeat4 = SmithMat(SMIT_TAG_LEATHER, "Pasek Skory",      4);
    json jWood2 = SmithMat(SMIT_TAG_WOOD,    "Belka Drewna",     2);
    json jGem1  = SmithMat(SMIT_TAG_GEM,     "Surowy Klejnot",   1);

    // ---- Weapons ----
    json jM; json jM1; json jM2; json jM3; json jM4;

    jM = JsonArrayInsert(JsonArrayInsert(JsonArray(), jIron2), jLeat1);
    SmithInsertRecipe(1, SMIT_CAT_WEAPON, "Zelazny Miecz", "nw_wswss001",
        "Prosty jednorezny miecz kuty z zelaza. Wierny towarzysz wojownika w mrocznych czasach.",
        jM, 10);

    jM = JsonArrayInsert(JsonArrayInsert(JsonArray(), jIron3), jLeat1);
    SmithInsertRecipe(2, SMIT_CAT_WEAPON, "Ciezka Maczuga", "nw_wblml001",
        "Masywna zelazna maczuga. Prosta w wykonaniu, skuteczna w kruszeniu kosci i zbroi.",
        jM, 10);

    jM = JsonArrayInsert(JsonArrayInsert(JsonArray(), jBone2), jLeat1);
    SmithInsertRecipe(3, SMIT_CAT_WEAPON, "Sztylet z Kosci", "nw_wswdg001",
        "Ostrze kute z ludzkich kosci — ulubiona bron kultystow i rzezimieszków.",
        jM, 8);

    jM = JsonArrayInsert(JsonArrayInsert(JsonArray(), jIron4), jLeat1);
    SmithInsertRecipe(4, SMIT_CAT_WEAPON, "Dwureczny Topor", "nw_waxbt001",
        "Ciezki topor wojenny wymagajacy obu rak. Kruszy zbroje i kosci rownie skutecznie.",
        jM, 14);

    jM = JsonArrayInsert(JsonArrayInsert(JsonArray(), jIron2), jWood2);
    SmithInsertRecipe(5, SMIT_CAT_WEAPON, "Zelazny Luk Wojenny", "nw_wbwlw001",
        "Wzmacniany zelazem luk bojowy. Probna nieznana dotad sila rzutu.",
        jM, 12);

    jM = JsonArrayInsert(JsonArrayInsert(JsonArray(), jIron2), jLeat1);
    SmithInsertRecipe(6, SMIT_CAT_WEAPON, "Topor Bojowy", "nw_waxbt002",
        "Jednorezny topor z zelaznym ostrzem na solidnym trzonku. Klasyczna bron zbojow.",
        jM, 10);

    jM = JsonArrayInsert(JsonArrayInsert(JsonArrayInsert(JsonArray(), jIron2), jGem1), jLeat1);
    SmithInsertRecipe(7, SMIT_CAT_WEAPON, "Ceremonialny Sztylet", "nw_wswdg003",
        "Ozdobny sztylet z klejnotem w rekojesci. Rytualne znaczenie uzupelniaja ostre krawedzie.",
        jM, 14);

    jM = JsonArrayInsert(JsonArrayInsert(JsonArrayInsert(JsonArray(), jIron4), jLeat2), jGem1);
    SmithInsertRecipe(8, SMIT_CAT_WEAPON, "Dlugi Miecz Mistrza", "nw_wswls001",
        "Dlugi miecz wykuty metodami dawnych mistrzow. Wymaga skupienia i doswiadczenia kowalskiego.",
        jM, 18);

    // ---- Armor ----
    jM = JsonArrayInsert(JsonArray(), jLeat4);
    SmithInsertRecipe(9, SMIT_CAT_ARMOR, "Skorzana Zbroja", "nw_arleab001",
        "Lekka zbroja ze skory. Dobra dla tych, ktorzy cenia mobilnosc ponad ochrone.",
        jM, 8);

    jM = JsonArrayInsert(JsonArrayInsert(JsonArray(), jIron5), jLeat1);
    SmithInsertRecipe(10, SMIT_CAT_ARMOR, "Kolczuga", "nw_armcl001",
        "Zbroja z przeplatanych zelaznych ogniw. Chroni przy relatywnie malej wadze.",
        jM, 14);

    jM = JsonArrayInsert(JsonArrayInsert(JsonArray(), jIron6), jLeat2);
    SmithInsertRecipe(11, SMIT_CAT_ARMOR, "Plytowy Napiersnnik", "nw_armdm001",
        "Kuty zelazny napiersnik. Wymagajacy w wykonaniu, lecz niezastapiony w polu bitwy.",
        jM, 16);

    jM = JsonArrayInsert(JsonArrayInsert(JsonArrayInsert(JsonArray(), jLeat2), jBone2), jLeat1);
    SmithInsertRecipe(12, SMIT_CAT_ARMOR, "Skorzana Zbroja z Koscmi", "nw_arleab002",
        "Skorzana zbroja wzmocniona koscmi nieprzyjaciela. Nosi ja wielu barbarzynskich wojownikow.",
        jM, 10);

    // ---- Shields ----
    jM = JsonArrayInsert(JsonArrayInsert(JsonArray(), jIron2), jLeat1);
    SmithInsertRecipe(13, SMIT_CAT_SHIELD, "Mala Zelazna Tarcza", "nw_ashlw001",
        "Lekka tarcza. Prosta ochrona dla tych, ktorzy nie chca rezygnowac z szybkosci.",
        jM, 10);

    jM = JsonArrayInsert(JsonArrayInsert(JsonArray(), jIron3), jLeat1);
    SmithInsertRecipe(14, SMIT_CAT_SHIELD, "Duza Tarcza", "nw_ashmd001",
        "Ciezka tarcza wiezowa. Daje solidna ochrone kosztem manewrowosci.",
        jM, 12);

    jM = JsonArrayInsert(JsonArrayInsert(JsonArray(), jIron2), jBone2);
    SmithInsertRecipe(15, SMIT_CAT_SHIELD, "Tarcza z Kosciana Kolczatka", "nw_ashlw002",
        "Na jej zelaznym licu tkwia fragmenty kosci. Atakujacy ja wrogowie czesto tego zaluja.",
        jM, 12);

    sqlquery qMark = SqlPrepareQueryCampaign("smith",
        "INSERT OR REPLACE INTO smith_meta (key,value) VALUES ('seeded','1')");
    SqlStep(qMark);
}

// ---- Query helpers ----

json SmithGetAllRecipes(string sFilter)
{
    string sWhere = (sFilter == "" ? "" : " WHERE category = @cat");
    sqlquery q = SqlPrepareQueryCampaign("smith",
        "SELECT id,category,name,resref,descr,materials_json,craft_dc "
        "FROM smith_recipes" + sWhere + " ORDER BY category, craft_dc, name");
    if(sFilter != "") SqlBindString(q, "@cat", sFilter);

    json jArr = JsonArray();
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "id",        JsonInt   (SqlGetInt   (q, 0)));
        j = JsonObjectSet(j, "category",  JsonString(SqlGetString(q, 1)));
        j = JsonObjectSet(j, "name",      JsonString(SqlGetString(q, 2)));
        j = JsonObjectSet(j, "resref",    JsonString(SqlGetString(q, 3)));
        j = JsonObjectSet(j, "descr",     JsonString(SqlGetString(q, 4)));
        j = JsonObjectSet(j, "materials", JsonParse (SqlGetString(q, 5)));
        j = JsonObjectSet(j, "dc",        JsonInt   (SqlGetInt   (q, 6)));
        jArr = JsonArrayInsert(jArr, j);
    }
    return jArr;
}

json SmithGetRecipeById(int nId)
{
    sqlquery q = SqlPrepareQueryCampaign("smith",
        "SELECT id,category,name,resref,descr,materials_json,craft_dc "
        "FROM smith_recipes WHERE id = @id");
    SqlBindInt(q, "@id", nId);
    if(!SqlStep(q)) return JsonNull();

    json j = JsonObject();
    j = JsonObjectSet(j, "id",        JsonInt   (SqlGetInt   (q, 0)));
    j = JsonObjectSet(j, "category",  JsonString(SqlGetString(q, 1)));
    j = JsonObjectSet(j, "name",      JsonString(SqlGetString(q, 2)));
    j = JsonObjectSet(j, "resref",    JsonString(SqlGetString(q, 3)));
    j = JsonObjectSet(j, "descr",     JsonString(SqlGetString(q, 4)));
    j = JsonObjectSet(j, "materials", JsonParse (SqlGetString(q, 5)));
    j = JsonObjectSet(j, "dc",        JsonInt   (SqlGetInt   (q, 6)));
    return j;
}

void SmithAddHistory(object oPC, int nRecipeId, string sRecipeName, int nQuality)
{
    // Prune old entries before inserting a new one
    sqlquery qDel = SqlPrepareQueryCampaign("smith",
        "DELETE FROM smith_history WHERE id IN ("
        "  SELECT id FROM smith_history WHERE pc_uuid = @uuid"
        "  ORDER BY forged_at DESC LIMIT -1 OFFSET @keep"
        ")");
    SqlBindString(qDel, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (qDel, "@keep", SMIT_MAX_HISTORY - 1);
    SqlStep(qDel);

    sqlquery q = SqlPrepareQueryCampaign("smith",
        "INSERT INTO smith_history (pc_uuid,recipe_id,recipe_name,quality,forged_at) "
        "VALUES (@uuid,@rid,@rname,@qual,strftime('%s','now'))");
    SqlBindString(q, "@uuid",  GetObjectUUID(oPC));
    SqlBindInt   (q, "@rid",   nRecipeId);
    SqlBindString(q, "@rname", sRecipeName);
    SqlBindInt   (q, "@qual",  nQuality);
    SqlStep(q);
}

json SmithGetHistory(object oPC)
{
    sqlquery q = SqlPrepareQueryCampaign("smith",
        "SELECT recipe_name,quality,forged_at FROM smith_history "
        "WHERE pc_uuid = @uuid ORDER BY forged_at DESC LIMIT @max");
    SqlBindString(q, "@uuid", GetObjectUUID(oPC));
    SqlBindInt   (q, "@max",  SMIT_MAX_HISTORY);

    json jArr = JsonArray();
    while(SqlStep(q))
    {
        json j = JsonObject();
        j = JsonObjectSet(j, "name",      JsonString(SqlGetString(q, 0)));
        j = JsonObjectSet(j, "quality",   JsonInt   (SqlGetInt   (q, 1)));
        j = JsonObjectSet(j, "forged_at", JsonInt   (SqlGetInt   (q, 2)));
        jArr = JsonArrayInsert(jArr, j);
    }
    return jArr;
}

string SmithFormatDate(int nUnix)
{
    sqlquery q = SqlPrepareQueryCampaign("smith",
        "SELECT strftime('%d.%m', @ts, 'unixepoch')");
    SqlBindInt(q, "@ts", nUnix);
    if(SqlStep(q)) return SqlGetString(q, 0);
    return "--";
}

// test_esi.nss — Echo Sight: OnUsed script for the demo test placeable
// Place a placeable in the toolset, set its OnUsed script to "test_esi".
// Using it will configure the placeable as a traumatic echo and then trigger it,
// demonstrating the full vision → codex → consume flow.

#include "lib_esi"

// Three sample echoes embedded for demo purposes.
// In production, builders set these variables via the Toolset property editor.

void ConfigureAsEcho(object oObj, int nVariant)
{
    switch(nVariant)
    {
        case 0:
            SetLocalString(oObj, ESI_VAR_TITLE,    "Rzeź w Piwnicy");
            SetLocalString(oObj, ESI_VAR_TEXT,
                "Powietrze jest gęste od zapachu żelaza. Widzisz mężczyznę z obciętymi dłońmi,\n"
                "przykutego łańcuchami do belki. Oprawca jest powolny i metodyczny — nie ma tu pośpiechu.\n"
                "Ofiara dawno przestała krzyczeć. Na ścianie ktoś wyrysowal symbol — krzyż bez ramion.\n"
                "Scena rozpływa się. Zostaje tylko zimno i dławiące milczenie.");
            SetLocalInt   (oObj, ESI_VAR_CATEGORY,   ESI_CAT_MURDER);
            SetLocalInt   (oObj, ESI_VAR_DC,          12);
            SetLocalInt   (oObj, ESI_VAR_BONUS_TYPE,  ESI_BONUS_SEARCH);
            SetLocalInt   (oObj, ESI_VAR_BONUS_VAL,   2);
            SetLocalInt   (oObj, ESI_VAR_TRAUMA,      1);
            SetLocalString(oObj, ESI_VAR_FLAVOR,     "Ślady tortur i niemego bólu.");
            break;

        case 1:
            SetLocalString(oObj, ESI_VAR_TITLE,    "Ofiara na Rozstaju");
            SetLocalString(oObj, ESI_VAR_TEXT,
                "Trzech kapłanów w szkarłatnych szatach stoi wokół kamiennego kręgu.\n"
                "Rytuał trwa od świtu — to widać po świecach wypalonych do połowy.\n"
                "W centrum kręgu coś pulsuje ciemnym światłem. Jeden z kapłanów drżącym głosem\n"
                "recytuje zaklęcie w języku, którego już nikt nie pamięta.\n"
                "Nagle wszystkie świece gasną jednocześnie. Potem cisza.");
            SetLocalInt   (oObj, ESI_VAR_CATEGORY,   ESI_CAT_RITUAL);
            SetLocalInt   (oObj, ESI_VAR_DC,          0);
            SetLocalInt   (oObj, ESI_VAR_BONUS_TYPE,  ESI_BONUS_SAVES);
            SetLocalInt   (oObj, ESI_VAR_BONUS_VAL,   1);
            SetLocalInt   (oObj, ESI_VAR_TRAUMA,      0);
            SetLocalString(oObj, ESI_VAR_FLAVOR,     "Rytualny okrąg skąpany w ciemności.");
            break;

        case 2:
            SetLocalString(oObj, ESI_VAR_TITLE,    "Ostatnia Bitwa Strażnicy");
            SetLocalString(oObj, ESI_VAR_TEXT,
                "Widzisz dziedziniec fortu w ogniu. Sześciu strażników broni bramy\n"
                "przeciwko dwudziestu napastnikom. Są zmęczeni — widać to po tym,\n"
                "jak trzymają tarcze. Jeden z nich, starszy, z blizną na policzku,\n"
                "krzyczy rozkazy spokojnym głosem mimo krwi na twarzy.\n"
                "Nie ocaleją. Wszyscy to wiedzą. Walczą dalej.");
            SetLocalInt   (oObj, ESI_VAR_CATEGORY,   ESI_CAT_BATTLE);
            SetLocalInt   (oObj, ESI_VAR_DC,          8);
            SetLocalInt   (oObj, ESI_VAR_BONUS_TYPE,  ESI_BONUS_ATTACK);
            SetLocalInt   (oObj, ESI_VAR_BONUS_VAL,   1);
            SetLocalInt   (oObj, ESI_VAR_TRAUMA,      0);
            SetLocalString(oObj, ESI_VAR_FLAVOR,     "Nieustraszony opór w obliczu klęski.");
            break;
    }
}

void main()
{
    object oPC  = GetLastUsedBy();
    object oObj = OBJECT_SELF;

    if(!GetIsPC(oPC)) return;

    // Cycle through demo echoes based on how many times this object was used
    int nVariant = GetLocalInt(oObj, "ESI_TEST_VARIANT");
    ConfigureAsEcho(oObj, nVariant % 3);
    SetLocalInt(oObj, "ESI_TEST_VARIANT", nVariant + 1);

    // Open codex instead on the third activation (to show the codex UI)
    if(nVariant == 3)
    {
        EsiOpenCodex(oPC);
        return;
    }

    EsiHandleEchoUse(oPC, oObj);
}

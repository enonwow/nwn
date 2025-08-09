#include "x3_inc_string"
#include "lib_app"

const string APP_BODY_PHENOTYPE = "APP_BODY_PHENOTYPE";
const string APP_BODY_SLIDER = "APP_BODY_SLIDER";

const string APP_BODY_WINGS_ID = "APP_BODY_WINGS_ID";
const string APP_BODY_WINGS_ENTRIES = "APP_BODY_WINGS_ENTRIES";
const string APP_BODY_WINGS_PREV_BTN = "APP_BODY_WINGS_PREV_BTN";
const string APP_BODY_WINGS_NEXT_BTN = "APP_BODY_WINGS_NEXT_BTN";

const string APP_BODY_TAIL_ID = "APP_BODY_TAIL_ID";
const string APP_BODY_TAIL_ENTRIES = "APP_BODY_TAIL_ENTRIES";
const string APP_BODY_TAIL_PREV_BTN = "APP_BODY_TAIL_PREV_BTN";
const string APP_BODY_TAIL_NEXT_BTN = "APP_BODY_TAIL_NEXT_BTN";

void FeedAppBodyWingsWindow(object oPC, int nToken)
{
    int nWingType = GetCreatureWingType(oPC);
    NuiSetBind(oPC, nToken, APP_BODY_WINGS_ID, JsonInt(nWingType));

    json jEntries = JsonArray();
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("None", CREATURE_WING_TYPE_NONE));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Demon", CREATURE_WING_TYPE_DEMON));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Angel", CREATURE_WING_TYPE_ANGEL));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Bat", CREATURE_WING_TYPE_BAT));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Dragon", CREATURE_WING_TYPE_DRAGON));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Butterfly", CREATURE_WING_TYPE_BUTTERFLY));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Bird", CREATURE_WING_TYPE_BIRD));

    NuiSetBind(oPC, nToken, APP_BODY_WINGS_ENTRIES, jEntries);
}

void FeedAppBodyTailWindow(object oPC, int nToken)
{
    int nTailType = GetCreatureTailType(oPC);
    NuiSetBind(oPC, nToken, APP_BODY_TAIL_ID, JsonInt(nTailType));

    json jEntries = JsonArray();
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("None", CREATURE_TAIL_TYPE_NONE));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Lizard", CREATURE_TAIL_TYPE_LIZARD));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Bone", CREATURE_TAIL_TYPE_BONE));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Devil", CREATURE_TAIL_TYPE_DEVIL));

    NuiSetBind(oPC, nToken, APP_BODY_TAIL_ENTRIES, jEntries);
}

void FeedAppBodyWindow(object oPC, int nToken)
{
    int nSkinColor = GetColor(oPC, COLOR_CHANNEL_SKIN);
    string sId = IntToString(nSkinColor);

    AppOnColorEncouraged(oPC, nToken, APP_BTN + sId);

    NuiSetBind(oPC, nToken, APP_COLOR_TE, JsonString(sId));

    int nPhenoType = GetPhenoType(oPC);

    int nOption;
    switch(nPhenoType)
    {
        case 0:
            nOption = 0;
        break;
        case 2:
            nOption = 1;
        break;
    }

    NuiSetBind(oPC, nToken, APP_BODY_PHENOTYPE, JsonInt(nOption));

    float fScale = GetObjectVisualTransform(oPC, OBJECT_VISUAL_TRANSFORM_SCALE) * 10;
    NuiSetBind(oPC, nToken, APP_BODY_SLIDER, JsonInt(FloatToInt(fScale)));

    FeedAppBodyWingsWindow(oPC, nToken);
    FeedAppBodyTailWindow(oPC, nToken);
}

json CreateAppBodyPhenotype()
{
    json jSpacer = NuiSpacer();

    json jLabel = NuiLabel(
        JsonString("Budowa:"),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jLabel = AppSetForegroundColor(jLabel);

    json jElemnts = JsonArray();
    jElemnts = JsonArrayInsert(jElemnts, JsonString("Normal"));
    jElemnts = JsonArrayInsert(jElemnts, JsonString("Big"));

    json jNuiOptions = NuiOptions(
        NUI_DIRECTION_HORIZONTAL,
        jElemnts,
        NuiBind(APP_BODY_PHENOTYPE));

    jNuiOptions = AppSetForegroundColor(jNuiOptions);
    jNuiOptions = NuiWidth(jNuiOptions, 150.0);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 50.0));
    jRow = JsonArrayInsert(jRow, jLabel);
    jRow = JsonArrayInsert(jRow, jNuiOptions);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

json CreateAppBodyGrowth()
{
    json jSpacer = NuiSpacer();

    json jLabel = NuiLabel(
        JsonString("Height:"),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jLabel = AppSetForegroundColor(jLabel);

    json jSlider = NuiSlider(
        NuiBind(APP_BODY_SLIDER),
        JsonInt(5),
        JsonInt(15),
        JsonInt(1));

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jLabel);
    jRow = JsonArrayInsert(jRow, jSlider);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

json CreateAppBodyWings(object oPC)
{
    json jSpacer = NuiSpacer();

    json jLabel = NuiLabel(
        JsonString("Wings:"),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jLabel = AppSetForegroundColor(jLabel);

    json jPrevBtn = NuiButtonImage(JsonString(APP_ARROW_PREV_BTN));
    jPrevBtn = NuiId(jPrevBtn, APP_BODY_WINGS_PREV_BTN);
    jPrevBtn = NuiWidth(jPrevBtn, APP_BTN_WIDTH);
    jPrevBtn = NuiHeight(jPrevBtn, APP_BTN_HEIGHT);
    jPrevBtn = NuiTooltip(jPrevBtn, JsonString("Previous wings"));
    jPrevBtn = AppSetForegroundColor(jPrevBtn);

    json jCombo = NuiCombo(
        NuiBind(APP_BODY_WINGS_ENTRIES),
        NuiBind(APP_BODY_WINGS_ID));
    jCombo = NuiHeight(jCombo, APP_BTN_HEIGHT);

    json jNextBtn = NuiButtonImage(JsonString(APP_ARROW_NEXT_BTN));
    jNextBtn = NuiId(jNextBtn, APP_BODY_WINGS_NEXT_BTN);
    jNextBtn = NuiWidth(jNextBtn, APP_BTN_WIDTH);
    jNextBtn = NuiHeight(jNextBtn, APP_BTN_HEIGHT);
    jNextBtn = NuiTooltip(jNextBtn, JsonString("Next wings"));
    jNextBtn = AppSetForegroundColor(jNextBtn);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jPrevBtn);
    jRow = JsonArrayInsert(jRow, jCombo);
    jRow = JsonArrayInsert(jRow, jNextBtn);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

json CreateAppBodyTail(object oPC)
{
    json jSpacer = NuiSpacer();

    json jLabel = NuiLabel(
        JsonString("Tail:"),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE));
    jLabel = AppSetForegroundColor(jLabel);

    json jPrevBtn = NuiButtonImage(JsonString(APP_ARROW_PREV_BTN));
    jPrevBtn = NuiId(jPrevBtn, APP_BODY_TAIL_PREV_BTN);
    jPrevBtn = NuiWidth(jPrevBtn, APP_BTN_WIDTH);
    jPrevBtn = NuiHeight(jPrevBtn, APP_BTN_HEIGHT);
    jPrevBtn = NuiTooltip(jPrevBtn, JsonString("Previous tail"));
    jPrevBtn = AppSetForegroundColor(jPrevBtn);

    json jCombo = NuiCombo(
        NuiBind(APP_BODY_TAIL_ENTRIES),
        NuiBind(APP_BODY_TAIL_ID));
    jCombo = NuiHeight(jCombo, APP_BTN_HEIGHT);

    json jNextBtn = NuiButtonImage(JsonString(APP_ARROW_NEXT_BTN));
    jNextBtn = NuiId(jNextBtn, APP_BODY_TAIL_NEXT_BTN);
    jNextBtn = NuiWidth(jNextBtn, APP_BTN_WIDTH);
    jNextBtn = NuiHeight(jNextBtn, APP_BTN_HEIGHT);
    jNextBtn = NuiTooltip(jNextBtn, JsonString("Next tail"));
    jNextBtn = AppSetForegroundColor(jNextBtn);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jPrevBtn);
    jRow = JsonArrayInsert(jRow, jCombo);
    jRow = JsonArrayInsert(jRow, jNextBtn);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

void CreateAppBodyWindow(object oPC)
{
    json jSpacer = NuiSpacer();
    json jNextElements = JsonArray();

    // IMPORTANT:
    // Change the phenotype on the PC copy due to a camera bug.
    // Currently, the camera gets stuck on the PC copy.
    // That's why the phenotype-related part is commented out.
    //jNextElements = JsonArrayInsert(jNextElements, CreateAppBodyPhenotype());
    jNextElements = JsonArrayInsert(jNextElements, CreateAppBodyGrowth());
    jNextElements = JsonArrayInsert(jNextElements, CreateAppBodyWings(oPC));
    jNextElements = JsonArrayInsert(jNextElements, CreateAppBodyTail(oPC));

    int nToken = AppColorTemplateWindow(
        oPC,
        APP_BODY_WINDOW,
        "Body",
        "cc_color_s_",
        JsonArray(),
        jNextElements,
        735.0,
        "lib_app_body_ev",
        70.0);

    FeedAppBodyWindow(oPC, nToken);
}

void AppBodyWingsEvents(
    object oPC,
    object oPCopy,
    int nToken,
    int nId)
{
    NuiSetBindWatch(oPC, nToken, APP_BODY_WINGS_ID, FALSE);
    SetCreatureWingType(nId, oPCopy);
    NuiSetBind(oPC, nToken, APP_BODY_WINGS_ID, JsonInt(nId));
    NuiSetBindWatch(oPC, nToken, APP_BODY_WINGS_ID, TRUE);
}

void AppBodyTailEvents(
    object oPC,
    object oPCopy,
    int nToken,
    int nId)
{
    NuiSetBindWatch(oPC, nToken, APP_BODY_TAIL_ID, FALSE);
    SetCreatureTailType(nId, oPCopy);
    NuiSetBind(oPC, nToken, APP_BODY_TAIL_ID, JsonInt(nId));
    NuiSetBindWatch(oPC, nToken, APP_BODY_TAIL_ID, TRUE);
}

void AppBodyCopy(object oSource, object oTarget)
{
    int nColor = GetColor(oSource, COLOR_CHANNEL_SKIN);
    SetColor(oTarget, COLOR_CHANNEL_SKIN, nColor);

    // Phenotype bug!
    // int nPhenoType = GetPhenoType(oSource);
    // SetPhenoType(nPhenoType, oTarget);

    float fScale = GetLocalFloat(oSource, "SCALE");
    SetLocalFloat(oTarget, "SCALE", fScale);
    SetObjectVisualTransform(oTarget, OBJECT_VISUAL_TRANSFORM_SCALE, fScale);

    int nWingType = GetCreatureWingType(oSource);
    SetCreatureWingType(nWingType, oTarget);

    int nTailType = GetCreatureTailType(oSource);
    SetCreatureTailType(nTailType, oTarget);
}

void AppBodyEvents(
    string sEventType,
    string sEventElem,
    object oPC,
    int nToken)
{
    object oArea = GetArea(oPC);
    object oPCopy = GetLocalObject(oArea, APP_DRESSING_ROOM_COPY);

    if(sEventType == EVENT_TYPE_CLICK)
    {
        if(FindSubString(sEventElem, APP_BTN) >= 0)
        {
            int nColor = StringToInt(StringReplace(sEventElem, APP_BTN, ""));
            AppSetColor(oPC, oPCopy, nToken, nColor, COLOR_CHANNEL_SKIN);
        }
        else if(sEventElem == APP_PREV_COLOR_BTN)
        {
            string sBtnId = JsonGetString(NuiGetBind(oPC, nToken, NUI_DATA_ENCOURAGED));
            int nColor = StringToInt(StringReplace(sBtnId, APP_BTN, ""));
            nColor -= 1;

            AppSetColor(oPC, oPCopy, nToken, nColor, COLOR_CHANNEL_SKIN);
        }
        else if(sEventElem == APP_NEXT_COLOR_BTN)
        {
            string sBtnId = JsonGetString(NuiGetBind(oPC, nToken, NUI_DATA_ENCOURAGED));
            int nColor = StringToInt(StringReplace(sBtnId, APP_BTN, ""));
            nColor += 1;

            AppSetColor(oPC, oPCopy, nToken, nColor, COLOR_CHANNEL_SKIN);
        }
        else if(sEventElem == APP_BODY_WINGS_PREV_BTN)
        {
            int nId = AppComboValidate(oPC, nToken, APP_BODY_WINGS_ENTRIES, APP_BODY_WINGS_ID, -1);
            AppBodyWingsEvents(oPC, oPCopy, nToken, nId);
        }
        else if(sEventElem == APP_BODY_WINGS_NEXT_BTN)
        {
            int nId = AppComboValidate(oPC, nToken, APP_BODY_WINGS_ENTRIES, APP_BODY_WINGS_ID, 1);
            AppBodyWingsEvents(oPC, oPCopy, nToken, nId);
        }
        else if(sEventElem == APP_BODY_TAIL_PREV_BTN)
        {
            int nId = AppComboValidate(oPC, nToken, APP_BODY_TAIL_ENTRIES, APP_BODY_TAIL_ID, -1);
            AppBodyTailEvents(oPC, oPCopy, nToken, nId);
        }
        else if(sEventElem == APP_BODY_TAIL_NEXT_BTN)
        {
            int nId = AppComboValidate(oPC, nToken, APP_BODY_TAIL_ENTRIES, APP_BODY_TAIL_ID, 1);
            AppBodyTailEvents(oPC, oPCopy, nToken, nId);
        }
        else if(sEventElem == APP_CONFIRM_BTN)
        {
            AppBodyCopy(oPCopy, oPC);
            AppDestroyActiveWindow(oPC);

            int nTokenPanel = NuiFindWindow(oPC, APP_RIGHT_PANEL_WINDOW);
            AppRightPanelOffEncouraged(oPC, nTokenPanel);
        }
        else if(sEventElem == APP_CANCEL_BTN)
        {
            AppBodyCopy(oPC, oPCopy);
            AppDestroyActiveWindow(oPC);

            int nTokenPanel = NuiFindWindow(oPC, APP_RIGHT_PANEL_WINDOW);
            AppRightPanelOffEncouraged(oPC, nTokenPanel);
        }
    }
    else if(sEventType == EVENT_TYPE_WATCH)
    {
        if(sEventElem == APP_BODY_PHENOTYPE)
        {
            int nOption = JsonGetInt(NuiGetBind(oPC, nToken, APP_BODY_PHENOTYPE));

            int nPhenotype;

            switch(nOption)
            {
                case 0:
                    nPhenotype = PHENOTYPE_NORMAL;
                break;
                case 1:
                    nPhenotype = PHENOTYPE_BIG;
                break;
            }

            SetPhenoType(nPhenotype, oPCopy);
        }
        else if(sEventElem == APP_BODY_SLIDER)
        {
            float fScale = JsonGetInt(NuiGetBind(oPC, nToken, APP_BODY_SLIDER)) / 10.0;
            SetObjectVisualTransform(oPCopy, OBJECT_VISUAL_TRANSFORM_SCALE, fScale);
            SetLocalFloat(oPCopy, "SCALE", fScale);
        }
        else if(sEventElem == APP_BODY_WINGS_ID)
        {
            int nId = AppComboValidate(oPC, nToken, APP_BODY_WINGS_ENTRIES, APP_BODY_WINGS_ID, 0);
            AppBodyWingsEvents(oPC, oPCopy, nToken, nId);
        }
        else if(sEventElem == APP_BODY_TAIL_ID)
        {
            int nId = AppComboValidate(oPC, nToken, APP_BODY_TAIL_ENTRIES, APP_BODY_TAIL_ID, 0);
            AppBodyTailEvents(oPC, oPCopy, nToken, nId);
        }
    }
    else if(sEventType == EVENT_TYPE_OPEN)
    {
        NuiSetBindWatch(oPC, nToken, APP_BODY_PHENOTYPE, TRUE);
        NuiSetBindWatch(oPC, nToken, APP_BODY_SLIDER, TRUE);
        NuiSetBindWatch(oPC, nToken, APP_COLOR_TE, TRUE);
        NuiSetBindWatch(oPC, nToken, APP_BODY_WINGS_ID, TRUE);
        NuiSetBindWatch(oPC, nToken, APP_BODY_TAIL_ID, TRUE);
    }
}

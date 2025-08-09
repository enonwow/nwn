#include "x3_inc_string"
#include "lib_app"

const string APP_TATOO_SELECTED = "APP_TATOO_SELECTED";

const string APP_TATOO_BACKGROUND = "APP_TATOO_BACKGROUND";
const string APP_TATOO_RIGHT_BICEP = "APP_TATOO_RIGHT_BICEP";
const string APP_TATOO_TORSO = "APP_TATOO_TORSO";
const string APP_TATOO_LEFT_BICEP = "APP_TATOO_LEFT_BICEP";
const string APP_TATOO_RIGHT_FOREARM = "APP_TATOO_RIGHT_FOREARM";
const string APP_TATOO_LEFT_FOREARM = "APP_TATOO_LEFT_FOREARM";
const string APP_TATOO_RIGHT_THIGH = "APP_TATOO_RIGHT_THIGH";
const string APP_TATOO_LEFT_THIGH = "APP_TATOO_LEFT_THIGH";
const string APP_TATOO_RIGHT_SHIN = "APP_TATOO_RIGHT_SHIN";
const string APP_TATOO_LEFT_SHIN = "APP_TATOO_LEFT_SHIN";

const string APP_TATOO_RIGHT_BICEP_IMAGE = "RIGHT_BICEP";
const string APP_TATOO_TORSO_IMAGE = "TORSO";
const string APP_TATOO_LEFT_BICEP_IMAGE = "LEFT_BICEP";
const string APP_TATOO_RIGHT_FOREARM_IMAGE = "RIGHT_FOREARM";
const string APP_TATOO_LEFT_FOREARM_IMAGE = "LEFT_FOREARM";
const string APP_TATOO_RIGHT_THIGH_IMAGE = "RIGHT_THIGH";
const string APP_TATOO_LEFT_THIGH_IMAGE = "LEFT_THIGH";
const string APP_TATOO_RIGHT_SHIN_IMAGE = "RIGHT_SHIN";
const string APP_TATOO_LEFT_SHIN_IMAGE = "LEFT_SHIN";

const string APP_TATOO_IMAGE_ENCOURAGED = "_E";
const string APP_TATOO_ACTIVE = "ACTIVE";

float APP_TATOO_CHECK_WIDTH = 25.0;
float APP_TATOO_CHECK_HEIGHT = 25.0;

float APP_TATOO_IMAGE_WIDTH = 171.0;
float APP_TATOO_IMAGE_HEIGHT = 250.0;

int AppTatooHasTattoo(object oPC, int nBodyPart)
{
    return GetCreatureBodyPart(nBodyPart, oPC) == 2;
}

void FeedAppTatooColor(
    object oPC,
    object oPCopy,
    int nToken,
    int nColorChannel)
{
    string sBind = AppGetColorPickerButtonBind(nColorChannel);

    int nColor = GetColor(oPCopy, nColorChannel);
    string sId = IntToString(nColor);

    AppOffColorEncouraged(oPC, nToken);
    AppOnColorEncouraged(oPC, nToken, APP_BTN + sId);
    NuiSetBind(oPC, nToken, APP_COLOR_TE, JsonString(sId));

    NuiSetBind(oPC, nToken, sBind, JsonString("cc_color_" + sId));
    AppSetColorPickerButtonEncouraged(oPC, nToken, 2, sBind, 2);
}

void AppSetTatooColor(
    object oPC,
    object oPCopy,
    int nToken,
    int nColor,
    int nColorChannel)
{
    AppSetColor(oPC, oPCopy, nToken, nColor, nColorChannel);

    int nColor = GetColor(oPCopy, nColorChannel);
    string sId = IntToString(nColor);

    string sBind = AppGetColorPickerButtonBind(nColorChannel);
    NuiSetBind(oPC, nToken, sBind, JsonString("cc_color_" + sId));
}

void FeedAppTatoo(
    object oPC,
    object oPCopy,
    int nToken,
    int nBodyPart,
    int bEncouraged = FALSE)
{
    string sImageBind;
    string sImage;

    switch(nBodyPart)
    {
        case CREATURE_PART_RIGHT_BICEP:
            {
                sImageBind = APP_TATOO_RIGHT_BICEP;
                sImage = APP_TATOO_RIGHT_BICEP_IMAGE;
            }
            break;
        case CREATURE_PART_TORSO:
            {
                sImageBind = APP_TATOO_TORSO;
                sImage = APP_TATOO_TORSO_IMAGE;
            }
            break;
        case CREATURE_PART_LEFT_BICEP:
            {
                sImageBind = APP_TATOO_LEFT_BICEP;
                sImage = APP_TATOO_LEFT_BICEP_IMAGE;
            }
            break;
        case CREATURE_PART_RIGHT_FOREARM:
            {
                sImageBind = APP_TATOO_RIGHT_FOREARM;
                sImage = APP_TATOO_RIGHT_FOREARM_IMAGE;
            }
            break;
        case CREATURE_PART_LEFT_FOREARM:
            {
                sImageBind = APP_TATOO_LEFT_FOREARM;
                sImage = APP_TATOO_LEFT_FOREARM_IMAGE;
            }
            break;
        case CREATURE_PART_RIGHT_THIGH:
            {
                sImageBind = APP_TATOO_RIGHT_THIGH;
                sImage = APP_TATOO_RIGHT_THIGH_IMAGE;
            }
            break;
        case CREATURE_PART_LEFT_THIGH:
            {
                sImageBind = APP_TATOO_LEFT_THIGH;
                sImage = APP_TATOO_LEFT_THIGH_IMAGE;
            }
            break;
        case CREATURE_PART_RIGHT_SHIN:
            {
                sImageBind = APP_TATOO_RIGHT_SHIN;
                sImage = APP_TATOO_RIGHT_SHIN_IMAGE;
            }
            break;
        case CREATURE_PART_LEFT_SHIN:
            {
                sImageBind = APP_TATOO_LEFT_SHIN;
                sImage = APP_TATOO_LEFT_SHIN_IMAGE;
            }
            break;
    }

    int bTattoo = AppTatooHasTattoo(oPCopy, nBodyPart);

    if(bEncouraged)
    {
        int nActive = JsonGetInt(NuiGetBind(oPC, nToken, APP_TATOO_ACTIVE));
        if(nActive > 0 && nActive != nBodyPart)
        {
            FeedAppTatoo(oPC, oPCopy, nToken, nActive);
        }

        NuiSetBind(oPC, nToken, sImageBind, JsonString(sImage + APP_TATOO_IMAGE_ENCOURAGED));
        NuiSetBind(oPC, nToken, APP_TATOO_SELECTED, JsonBool(bTattoo));
        NuiSetBind(oPC, nToken, APP_TATOO_ACTIVE, JsonInt(nBodyPart));
    }
    else
    {
        NuiSetBind(oPC, nToken, sImageBind,
            JsonString(bTattoo ? sImage : "cc_tato_bg"));
    }
}

void FeedAppTatooWindow(object oPC, object oPCopy, int nToken)
{
    json jEntries = JsonArray();
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Right biceps", CREATURE_PART_RIGHT_BICEP));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Torso", CREATURE_PART_TORSO));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Left biceps", CREATURE_PART_LEFT_BICEP));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Right forearm", CREATURE_PART_RIGHT_FOREARM));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Left forearm", CREATURE_PART_LEFT_FOREARM));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Right thigh", CREATURE_PART_RIGHT_THIGH));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Left thigh", CREATURE_PART_LEFT_THIGH));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Right shin", CREATURE_PART_RIGHT_SHIN));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Left shin", CREATURE_PART_LEFT_SHIN));

    int i;
    //COLOR_CHANNEL_TATTOO_1, COLOR_CHANNEL_TATTOO_2
    for(i = 2; i < 4; i++)
    {
        int nColor = GetColor(oPCopy, i);
        string sId = IntToString(nColor);

        string sBind = AppGetColorPickerButtonBind(i);

        NuiSetBind(oPC, nToken, sBind, JsonString("cc_color_" + sId));

        if(i == 2)
        {
            AppOffColorEncouraged(oPC, nToken);
            AppOnColorEncouraged(oPC, nToken, APP_BTN + sId);
            NuiSetBind(oPC, nToken, APP_COLOR_TE, JsonString(sId));
        }
    }

    NuiSetBind(oPC, nToken, APP_ITEM_ENTRIES, jEntries);
    NuiSetBind(oPC, nToken, APP_ITEM_ID, JsonInt(CREATURE_PART_RIGHT_BICEP));

    NuiSetBind(oPC, nToken, APP_TATOO_BACKGROUND, JsonString("cc_tato_body"));

    NuiSetBind(oPC, nToken, APP_COLOR_BTN_ACTIVE, JsonInt(2));
    NuiSetBind(oPC, nToken, AppGetColorPickerButtonEncouragedBind(2), JsonBool(TRUE));

    FeedAppTatoo(oPC, oPCopy, nToken, CREATURE_PART_RIGHT_BICEP, TRUE);
    FeedAppTatoo(oPC, oPCopy, nToken, CREATURE_PART_TORSO);
    FeedAppTatoo(oPC, oPCopy, nToken, CREATURE_PART_LEFT_BICEP);
    FeedAppTatoo(oPC, oPCopy, nToken, CREATURE_PART_RIGHT_FOREARM);
    FeedAppTatoo(oPC, oPCopy, nToken, CREATURE_PART_LEFT_FOREARM);
    FeedAppTatoo(oPC, oPCopy, nToken, CREATURE_PART_RIGHT_THIGH);
    FeedAppTatoo(oPC, oPCopy, nToken, CREATURE_PART_LEFT_THIGH);
    FeedAppTatoo(oPC, oPCopy, nToken, CREATURE_PART_RIGHT_SHIN);
    FeedAppTatoo(oPC, oPCopy, nToken, CREATURE_PART_LEFT_SHIN);
}

void FeedAppTatooModel(
    object oPC,
    int nToken,
    int nModelId)
{
    NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, FALSE);

    NuiSetBind(oPC, nToken, APP_ITEM_ID, JsonInt(nModelId));

    NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, TRUE);
}

json CreateAppTatooColorPicker()
{
    json jSpacer = NuiSpacer();

    json jRow = JsonArray();

    json jColorBtn = AppCreateColorPickerButton(COLOR_CHANNEL_TATTOO_1,
        "Tattoo 1");
    json jColorBtn2 = AppCreateColorPickerButton(COLOR_CHANNEL_TATTOO_2,
        "Tattoo 2");

    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jColorBtn);
    jRow = JsonArrayInsert(jRow, jColorBtn2);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

json CreateAppTatooChecks()
{
    json jSpacer = NuiSpacer();

    json jCol = JsonArray();
    json jRow = JsonArray();
    {
        jRow = JsonArrayInsert(jRow, jSpacer);

        jCol = JsonArrayInsert(jCol, NuiHeight(NuiRow(jRow), 30.0));
    }

    jRow = JsonArray();
    {
        json jRightBiceps = NuiButton(JsonString(""));
        jRightBiceps = NuiId(jRightBiceps, IntToString(CREATURE_PART_RIGHT_BICEP));
        jRightBiceps = NuiTooltip(jRightBiceps, JsonString("Right biceps"));
        jRightBiceps = NuiWidth(jRightBiceps, APP_TATOO_CHECK_WIDTH);
        jRightBiceps = AppSetForegroundColor(jRightBiceps);

        json jTorso = NuiButton(JsonString(""));
        jTorso = NuiId(jTorso, IntToString(CREATURE_PART_TORSO));
        jTorso = NuiTooltip(jTorso, JsonString("Torso"));
        jTorso = NuiWidth(jTorso, APP_TATOO_CHECK_WIDTH);
        jTorso = AppSetForegroundColor(jTorso);

        json jLeftBiceps = NuiButton(JsonString(""));
        jLeftBiceps = NuiId(jLeftBiceps, IntToString(CREATURE_PART_LEFT_BICEP));
        jLeftBiceps = NuiTooltip(jLeftBiceps, JsonString("Left biceps"));
        jLeftBiceps = NuiWidth(jLeftBiceps, APP_TATOO_CHECK_WIDTH);
        jLeftBiceps = AppSetForegroundColor(jLeftBiceps);

        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 32.0));
        jRow = JsonArrayInsert(jRow, jRightBiceps);
        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 10.0));
        jRow = JsonArrayInsert(jRow, jTorso);
        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 11.0));
        jRow = JsonArrayInsert(jRow, jLeftBiceps);
        jRow = JsonArrayInsert(jRow, jSpacer);

        jCol = JsonArrayInsert(jCol, NuiHeight(NuiRow(jRow), APP_TATOO_CHECK_HEIGHT));
    }

    jRow = JsonArray();
    {
        json jRightForearm = NuiButton(JsonString(""));
        jRightForearm = NuiId(jRightForearm, IntToString(CREATURE_PART_RIGHT_FOREARM));
        jRightForearm = NuiTooltip(jRightForearm, JsonString("Right forearm"));
        jRightForearm = NuiWidth(jRightForearm, APP_TATOO_CHECK_WIDTH);
        jRightForearm = AppSetForegroundColor(jRightForearm);

        json jTorso = NuiButton(JsonString(""));
        jTorso = NuiId(jTorso, IntToString(CREATURE_PART_TORSO));
        jTorso = NuiTooltip(jTorso, JsonString("Torso"));
        jTorso = NuiWidth(jTorso, APP_TATOO_CHECK_WIDTH);
        jTorso = AppSetForegroundColor(jTorso);

        json jLeftForearm = NuiButton(JsonString(""));
        jLeftForearm = NuiId(jLeftForearm, IntToString(CREATURE_PART_LEFT_FOREARM));
        jLeftForearm = NuiTooltip(jLeftForearm, JsonString("Left forearm"));
        jLeftForearm = NuiWidth(jLeftForearm, APP_TATOO_CHECK_WIDTH);
        jLeftForearm = AppSetForegroundColor(jLeftForearm);

        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 25.0));
        jRow = JsonArrayInsert(jRow, jRightForearm);
        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 17.0));
        jRow = JsonArrayInsert(jRow, jTorso);
        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 18.0));
        jRow = JsonArrayInsert(jRow, jLeftForearm);
        jRow = JsonArrayInsert(jRow, jSpacer);

        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    jRow = JsonArray();
    {
        json jRightThigh = NuiButton(JsonString(""));
        jRightThigh = NuiId(jRightThigh, IntToString(CREATURE_PART_RIGHT_THIGH));
        jRightThigh = NuiTooltip(jRightThigh, JsonString("Right thigh"));
        jRightThigh = NuiWidth(jRightThigh, APP_TATOO_CHECK_WIDTH);
        jRightThigh = AppSetForegroundColor(jRightThigh);

        json jLeftThigh = NuiButton(JsonString(""));
        jLeftThigh = NuiId(jLeftThigh, IntToString(CREATURE_PART_LEFT_THIGH));
        jLeftThigh = NuiTooltip(jLeftThigh, JsonString("Left thigh"));
        jLeftThigh = NuiWidth(jLeftThigh, APP_TATOO_CHECK_WIDTH);
        jLeftThigh = AppSetForegroundColor(jLeftThigh);

        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 50.0));
        jRow = JsonArrayInsert(jRow, jRightThigh);
        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 12.0));
        jRow = JsonArrayInsert(jRow, jLeftThigh);
        jRow = JsonArrayInsert(jRow, jSpacer);

        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    jRow = JsonArray();
    {
        jRow = JsonArrayInsert(jRow, jSpacer);

        jCol = JsonArrayInsert(jCol, NuiHeight(NuiRow(jRow), 10.0));
    }

    jRow = JsonArray();
    {
        json jRightShin = NuiButton(JsonString(""));
        jRightShin = NuiId(jRightShin, IntToString(CREATURE_PART_RIGHT_SHIN));
        jRightShin = NuiTooltip(jRightShin, JsonString("Right shin"));
        jRightShin = NuiWidth(jRightShin, APP_TATOO_CHECK_WIDTH);
        jRightShin = AppSetForegroundColor(jRightShin);

        json jLeftShin = NuiButton(JsonString(""));
        jLeftShin = NuiId(jLeftShin, IntToString(CREATURE_PART_LEFT_SHIN));
        jLeftShin = NuiTooltip(jLeftShin, JsonString("Left shin"));
        jLeftShin = NuiWidth(jLeftShin, APP_TATOO_CHECK_WIDTH);
        jLeftShin = AppSetForegroundColor(jLeftShin);

        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 48.0));
        jRow = JsonArrayInsert(jRow, jRightShin);
        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 18.0));
        jRow = JsonArrayInsert(jRow, jLeftShin);
        jRow = JsonArrayInsert(jRow, jSpacer);

        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    return jCol;
}

json CreateAppTatooPicker()
{
    json jSpacer = NuiSpacer();

    json jCheck = NuiCheck(JsonString("Nałożony"), NuiBind(APP_TATOO_SELECTED));
    jCheck = NuiWidth(jCheck, 140.0);
    jCheck = NuiHeight(jCheck, APP_BTN_HEIGHT);
    jCheck = AppSetForegroundColor(jCheck);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jCheck);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

json CreateAppTatooImage(
    json jImageList,
    string sImageBind,
    float fWidth,
    float fHeight,
    int nOrder = NUI_DRAW_LIST_ITEM_ORDER_AFTER)
{
    json jImage = NuiDrawListImage(
        JsonBool(TRUE),
        NuiBind(sImageBind),
        NuiRect(
            0.0,
            0.0,
            fWidth,
            fHeight),
        JsonInt(NUI_ASPECT_FIT),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE),
        nOrder,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

    jImageList = JsonArrayInsert(jImageList, jImage);

    return jImageList;
}

json CreateAppTatooImageList()
{
    json jImageList = JsonArray();

    jImageList = CreateAppTatooImage(
        jImageList,
        APP_TATOO_BACKGROUND,
        APP_TATOO_IMAGE_WIDTH,
        APP_TATOO_IMAGE_HEIGHT);

    jImageList = CreateAppTatooImage(
        jImageList,
        APP_TATOO_RIGHT_BICEP,
        APP_TATOO_IMAGE_WIDTH,
        APP_TATOO_IMAGE_HEIGHT);

    jImageList = CreateAppTatooImage(
        jImageList,
        APP_TATOO_TORSO,
        APP_TATOO_IMAGE_WIDTH,
        APP_TATOO_IMAGE_HEIGHT);

    jImageList = CreateAppTatooImage(
        jImageList,
        APP_TATOO_LEFT_BICEP,
        APP_TATOO_IMAGE_WIDTH,
        APP_TATOO_IMAGE_HEIGHT);

    jImageList = CreateAppTatooImage(
        jImageList,
        APP_TATOO_RIGHT_FOREARM,
        APP_TATOO_IMAGE_WIDTH,
        APP_TATOO_IMAGE_HEIGHT);

    jImageList = CreateAppTatooImage(
        jImageList,
        APP_TATOO_LEFT_FOREARM,
        APP_TATOO_IMAGE_WIDTH,
        APP_TATOO_IMAGE_HEIGHT);

    jImageList = CreateAppTatooImage(
        jImageList,
        APP_TATOO_RIGHT_THIGH,
        APP_TATOO_IMAGE_WIDTH,
        APP_TATOO_IMAGE_HEIGHT);

    jImageList = CreateAppTatooImage(
        jImageList,
        APP_TATOO_LEFT_THIGH,
        APP_TATOO_IMAGE_WIDTH,
        APP_TATOO_IMAGE_HEIGHT);

    jImageList = CreateAppTatooImage(
        jImageList,
        APP_TATOO_RIGHT_SHIN,
        APP_TATOO_IMAGE_WIDTH,
        APP_TATOO_IMAGE_HEIGHT);

    jImageList = CreateAppTatooImage(
        jImageList,
        APP_TATOO_LEFT_SHIN,
        APP_TATOO_IMAGE_WIDTH,
        APP_TATOO_IMAGE_HEIGHT);

    return jImageList;
}

json CreateMergedTatooImage()
{
    json jSpacer = NuiSpacer();

    json jGroupList = CreateAppTatooChecks();

    json jImageList = CreateAppTatooImageList();

    json jResult = NuiDrawList(NuiCol(jGroupList), JsonBool(FALSE), jImageList);
    jResult = NuiWidth(jResult, APP_TATOO_IMAGE_WIDTH);
    jResult = NuiHeight(jResult, APP_TATOO_IMAGE_HEIGHT);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jResult);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

void CreateAppTatooWindow(object oPC)
{
    json jPrevElements = JsonArray();

    jPrevElements = JsonArrayInsert(jPrevElements, CreateAppTatooColorPicker());

    json jNextElements = JsonArray();
    jNextElements = JsonArrayInsert(jNextElements, CreateAppItemPicker());
    jNextElements = JsonArrayInsert(jNextElements, CreateAppTatooPicker());
    jNextElements = JsonArrayInsert(jNextElements, CreateMergedTatooImage());

    int nToken = AppColorTemplateWindow(
        oPC,
        APP_TATOO_WINDOW,
        "Tattoos",
        "cc_color_",
        jPrevElements,
        jNextElements,
        1015.0,
        "lib_app_tatoo_ev",
        85.0);
}

void AppTatooRandomize(
    object oPC,
    int nToken,
    int nBodyPart)
{
    int bTattoo = Random(2);

    NuiSetBind(oPC, nToken, IntToString(nBodyPart), JsonBool(bTattoo));

    if(bTattoo)
    {
        SetCreatureBodyPart(nBodyPart, CREATURE_MODEL_TYPE_TATTOO, oPC);
    }
    else
    {
        SetCreatureBodyPart(nBodyPart, 1, oPC);
    }
}

void AppTatooModel(
    object oPC,
    object oPCopy,
    int nToken,
    int nBodyPart)
{
    if(nBodyPart > 0)
    {
        NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, FALSE);

        int bTattoo = AppTatooHasTattoo(oPCopy, nBodyPart);

        NuiSetBind(oPC, nToken, APP_ITEM_ID, JsonInt(nBodyPart));

        FeedAppTatoo(oPC, oPCopy, nToken, nBodyPart, TRUE);

        NuiSetBind(oPC, nToken, APP_TATOO_SELECTED, JsonBool(bTattoo));

        NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, TRUE);
    }
}

void AppTatooValidate(object oSource, object oTarget, int nBodyPart)
{
    int bTattoo = AppTatooHasTattoo(oSource, nBodyPart);

    if(bTattoo)
    {
        SetCreatureBodyPart(nBodyPart, CREATURE_MODEL_TYPE_TATTOO, oTarget);
    }
    else
    {
        SetCreatureBodyPart(nBodyPart, 1, oTarget);
    }
}

void AppTatooCopy(object oSource, object oTarget)
{
    int nColor = GetColor(oSource, COLOR_CHANNEL_TATTOO_1);
    SetColor(oTarget, COLOR_CHANNEL_TATTOO_1, nColor);

    nColor = GetColor(oSource, COLOR_CHANNEL_TATTOO_2);
    SetColor(oTarget, COLOR_CHANNEL_TATTOO_2, nColor);

    AppTatooValidate(oSource, oTarget, CREATURE_PART_RIGHT_BICEP);
    AppTatooValidate(oSource, oTarget, CREATURE_PART_TORSO);
    AppTatooValidate(oSource, oTarget, CREATURE_PART_LEFT_BICEP);
    
    AppTatooValidate(oSource, oTarget, CREATURE_PART_RIGHT_FOREARM);
    AppTatooValidate(oSource, oTarget, CREATURE_PART_LEFT_FOREARM);
    
    AppTatooValidate(oSource, oTarget, CREATURE_PART_RIGHT_THIGH);
    AppTatooValidate(oSource, oTarget, CREATURE_PART_LEFT_THIGH);
    
    AppTatooValidate(oSource, oTarget, CREATURE_PART_RIGHT_SHIN);
    AppTatooValidate(oSource, oTarget, CREATURE_PART_LEFT_SHIN);
}

void AppTatooEvents(
    string sEventType,
    string sEventElem,
    object oPC,
    int nToken)
{
    object oArea = GetArea(oPC);
    object oPCopy = GetLocalObject(oArea, APP_DRESSING_ROOM_COPY);

    if(sEventType == EVENT_TYPE_CLICK)
    {
        if(FindSubString(sEventElem, APP_COLOR_BTN) >= 0)
        {
            NuiSetBindWatch(oPC, nToken, APP_COLOR_TE, FALSE);
            FeedAppTatooColor(oPC, oPCopy, nToken, StringToInt(StringReplace(sEventElem, APP_COLOR_BTN, "")));
            NuiSetBindWatch(oPC, nToken, APP_COLOR_TE, TRUE);
        }
        else
        {
            int nActiveColor = JsonGetInt(NuiGetBind(oPC, nToken, APP_COLOR_BTN_ACTIVE));
            int nChannel = nActiveColor == 2 ? COLOR_CHANNEL_TATTOO_1 : COLOR_CHANNEL_TATTOO_2;

            if(FindSubString(sEventElem, APP_BTN) >= 0)
            {
                int nColor = StringToInt(StringReplace(sEventElem, APP_BTN, ""));
                AppSetTatooColor(oPC, oPCopy, nToken, nColor, nChannel);
            }
            else if(sEventElem == APP_PREV_COLOR_BTN)
            {
                string sBtnId = JsonGetString(NuiGetBind(oPC, nToken, NUI_DATA_ENCOURAGED));
                int nColor = StringToInt(StringReplace(sBtnId, APP_BTN, ""));
                nColor -= 1;

                AppSetTatooColor(oPC, oPCopy, nToken, nColor, nChannel);
            }
            else if(sEventElem == APP_NEXT_COLOR_BTN)
            {
                string sBtnId = JsonGetString(NuiGetBind(oPC, nToken, NUI_DATA_ENCOURAGED));
                int nColor = StringToInt(StringReplace(sBtnId, APP_BTN, ""));
                nColor += 1;

                AppSetTatooColor(oPC, oPCopy, nToken, nColor, nChannel);
            }
            else if(sEventElem == APP_ITEM_PREVIOUS_BTN)
            {
                int nBodyPart = AppComboValidate(oPC, nToken, APP_ITEM_ENTRIES, APP_ITEM_ID, -1);
                AppTatooModel(oPC, oPCopy, nToken, nBodyPart);
            }
            else if(sEventElem == APP_ITEM_NEXT_BTN)
            {
                int nBodyPart = AppComboValidate(oPC, nToken, APP_ITEM_ENTRIES, APP_ITEM_ID, 1);
                AppTatooModel(oPC, oPCopy, nToken, nBodyPart);
            }
            else if(sEventElem == APP_CONFIRM_BTN)
            {
                AppTatooCopy(oPCopy, oPC);
                AppDestroyActiveWindow(oPC);

                int nTokenPanel = NuiFindWindow(oPC, APP_RIGHT_PANEL_WINDOW);
                AppRightPanelOffEncouraged(oPC, nTokenPanel);
            }
            else if(sEventElem == APP_CANCEL_BTN)
            {
                AppTatooCopy(oPC, oPCopy);
                AppDestroyActiveWindow(oPC);

                int nTokenPanel = NuiFindWindow(oPC, APP_RIGHT_PANEL_WINDOW);
                AppRightPanelOffEncouraged(oPC, nTokenPanel);
            }
            else
            {
                int nBodyPart = StringToInt(sEventElem);
                AppTatooModel(oPC, oPCopy, nToken, nBodyPart);
            }
        }
    }
    else if(sEventType == EVENT_TYPE_WATCH)
    {
        if(sEventElem == APP_COLOR_TE)
        {
            int nActiveColor = JsonGetInt(NuiGetBind(oPC, nToken, APP_COLOR_BTN_ACTIVE));
            int nChannel = nActiveColor == 2 ? COLOR_CHANNEL_TATTOO_1 : COLOR_CHANNEL_TATTOO_2;

            string sColor = JsonGetString(NuiGetBind(oPC, nToken, APP_COLOR_TE));
            int nColor = StringToInt(sColor);

            AppSetTatooColor(oPC, oPCopy, nToken, nColor, nChannel);
        }
        else if(sEventElem == APP_TATOO_SELECTED)
        {
            NuiSetBindWatch(oPC, nToken, APP_TATOO_SELECTED, FALSE);

            int bTattoo = JsonGetInt(NuiGetBind(oPC, nToken, APP_TATOO_SELECTED));
            int nBodyPart = JsonGetInt(NuiGetBind(oPC, nToken, APP_ITEM_ID));

            if(bTattoo)
            {
                SetCreatureBodyPart(nBodyPart, CREATURE_MODEL_TYPE_TATTOO, oPCopy);
            }
            else
            {
                SetCreatureBodyPart(nBodyPart, 1, oPCopy);
            }

            NuiSetBindWatch(oPC, nToken, APP_TATOO_SELECTED, TRUE);
        }
        else if(sEventElem == APP_ITEM_ID)
        {
            int nBodyPart = AppComboValidate(oPC, nToken, APP_ITEM_ENTRIES, APP_ITEM_ID, 0);
            AppTatooModel(oPC, oPCopy, nToken, nBodyPart);
        }
    }
    else if(sEventType == EVENT_TYPE_OPEN)
    {
        FeedAppTatooWindow(oPC, oPCopy, nToken);
        NuiSetBindWatch(oPC, nToken, APP_COLOR_TE, TRUE);
        NuiSetBindWatch(oPC, nToken, APP_TATOO_SELECTED, TRUE);
    }
}

#include "x3_inc_string"
#include "lib_app"

const string ARMOR_PART = "ARMOR_PART_";
const string ARMOR_PART_ENCOURAGED = "ARMOR_PART_ENCOURAGED_";
const string ARMOR_PART_ENCOURAGED_CURRENT = "ARMOR_PART_ENCOURAGED_CURRENT";

const string ARMOR_ENTRIES = "ARMOR_ENTRIES";
const string ARMOR_ID = "ARMOR_ID";

const string ARMOR_ELEMENTS_ID = "ARMOR_ELEMENTS_ID";
const string ARMOR_ELEMENTS_ENTRIES = "ARMOR_ELEMENTS_ENTRIES";

const string APP_PREV_ARMOR_PART = "APP_PREV_ARMOR_PART";
const string APP_NEXT_ARMOR_PART = "APP_NEXT_ARMOR_PART";

const string APP_PREV_ELEMENT = "APP_PREV_ELEMENT";
const string APP_NEXT_ELEMENT = "APP_NEXT_ELEMENT";

const string APP_ARMOR_PART_IMAGE = "APP_ARMOR_PART_IMAGE";
const string APP_ARMOR_PART_IMAGE_2 = "APP_ARMOR_PART_IMAGE_2";

const string APP_ARMOR_SPECIFIC_COLOR = "APP_ARMOR_SPECIFIC_COLOR";
const string APP_ARMOR_CLEAR_BTN = "APP_ARMOR_CLEAR_BTN";

float APP_ARMOR_BUTTON_WIDTH = 20.0;
float APP_ARMOR_BUTTON_HEIGHT = 25.0;

float APP_ARMOR_IMAGE_WIDTH = 175.0;
float APP_ARMOR_IMAGE_HEIGHT = 245.0;

string Get2daPart(int nModel)
{
    string s2daParts;

    switch(nModel)
    {
        case ITEM_APPR_ARMOR_MODEL_RFOOT:
        case ITEM_APPR_ARMOR_MODEL_LFOOT:
            s2daParts = "parts_foot";
        break;

        case ITEM_APPR_ARMOR_MODEL_RSHIN:
        case ITEM_APPR_ARMOR_MODEL_LSHIN:
            s2daParts = "parts_shin";
        break;

        case ITEM_APPR_ARMOR_MODEL_RTHIGH:
        case ITEM_APPR_ARMOR_MODEL_LTHIGH:
            s2daParts = "parts_legs";
        break;

        case ITEM_APPR_ARMOR_MODEL_PELVIS:
            s2daParts = "parts_pelvis";
        break;

        case ITEM_APPR_ARMOR_MODEL_TORSO:
            s2daParts = "parts_chest";
        break;

        case ITEM_APPR_ARMOR_MODEL_BELT:
            s2daParts = "parts_belt";
        break;

        case ITEM_APPR_ARMOR_MODEL_NECK:
            s2daParts = "parts_neck";
        break;

        case ITEM_APPR_ARMOR_MODEL_RFOREARM:
        case ITEM_APPR_ARMOR_MODEL_LFOREARM:
            s2daParts = "parts_forearm";
        break;

        case ITEM_APPR_ARMOR_MODEL_RBICEP:
        case ITEM_APPR_ARMOR_MODEL_LBICEP:
            s2daParts = "parts_bicep";
        break;

        case ITEM_APPR_ARMOR_MODEL_RSHOULDER:
        case ITEM_APPR_ARMOR_MODEL_LSHOULDER:
            s2daParts = "parts_shoulder";
        break;

        case ITEM_APPR_ARMOR_MODEL_RHAND:
        case ITEM_APPR_ARMOR_MODEL_LHAND:
            s2daParts = "parts_hand";
        break;

        case ITEM_APPR_ARMOR_MODEL_ROBE:
            s2daParts = "parts_robe";
        break;
    }

    return s2daParts;
}

json CreateModelArmorNui(int nPart, string sTooltip)
{
    string sPart = IntToString(nPart);

    json jButton = NuiButton(JsonString(""));
    jButton = NuiId(jButton, ARMOR_PART + sPart);
    jButton = NuiEncouraged(jButton, NuiBind(ARMOR_PART_ENCOURAGED + sPart));
    jButton = NuiTooltip(jButton, JsonString(sTooltip));
    jButton = NuiWidth(jButton, APP_ARMOR_BUTTON_WIDTH);
    jButton = AppSetForegroundColor(jButton);

    return jButton;
}

json CreateAppArmorSpecificColorPicker()
{
    json jSpacer = NuiSpacer();
    json jRow = JsonArray();

    json jSpecificColorBtn = NuiCheck(JsonString("Color for the selected part"), NuiBind(APP_ARMOR_SPECIFIC_COLOR));
    jSpecificColorBtn = NuiWidth(jSpecificColorBtn, 220.0);
    jSpecificColorBtn = NuiHeight(jSpecificColorBtn, 40.0);
    jSpecificColorBtn = AppSetForegroundColor(jSpecificColorBtn);

    // json jButton = NuiButtonImage(JsonString("cc_color_255"));
    json jButton = NuiButton(JsonString("Clrear"));
    jButton = NuiId(jButton, APP_ARMOR_CLEAR_BTN);
    jButton = NuiTooltip(jButton, JsonString("Clear selected color"));
    jButton = NuiVisible(jButton, NuiBind(APP_ARMOR_SPECIFIC_COLOR));
    jButton = NuiWidth(jButton, 100.0);
    jButton = NuiHeight(jButton, 40.0);
    jButton = AppSetForegroundColor(jButton);

    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jSpecificColorBtn);
    jRow = JsonArrayInsert(jRow, jButton);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

json CreateAppArmorPartsUpperSpacer()
{
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiHeight(NuiSpacer(), 20.0));
    return NuiRow(jRow);
}

json CreateAppArmorParts()
{
    json jSpacer = NuiSpacer();
    json jCol = JsonArray();

    jCol = JsonArrayInsert(jCol, CreateAppArmorPartsUpperSpacer());

    json jRow = JsonArray();
    {
        json jRightShoulder = CreateModelArmorNui(0, "Right shoulder");
        json jNeck = CreateModelArmorNui(1, "Neck");
        json jLeftShoulder = CreateModelArmorNui(2, "Left shoulder");

        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 40.0));
        jRow = JsonArrayInsert(jRow, jRightShoulder);
        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 9.0));
        jRow = JsonArrayInsert(jRow, jNeck);
        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 10.0));
        jRow = JsonArrayInsert(jRow, jLeftShoulder);
        jRow = JsonArrayInsert(jRow, jSpacer);

        jCol = JsonArrayInsert(jCol, NuiHeight(NuiRow(jRow), APP_ARMOR_BUTTON_HEIGHT));
    }

    jRow = JsonArray();
    {
        json jRightBicep = CreateModelArmorNui(3, "Right biceps");
        json jTorso = CreateModelArmorNui(4, "Torso");
        json jLeftBicep = CreateModelArmorNui(5, "Left biceps");

        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 30.0));
        jRow = JsonArrayInsert(jRow, jRightBicep);
        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 19.0));
        jRow = JsonArrayInsert(jRow, jTorso);
        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 20.0));
        jRow = JsonArrayInsert(jRow, jLeftBicep);
        jRow = JsonArrayInsert(jRow, jSpacer);

        jCol = JsonArrayInsert(jCol, NuiHeight(NuiRow(jRow), APP_ARMOR_BUTTON_HEIGHT));
    }

    jRow = JsonArray();
    {
        json jRightForearm = CreateModelArmorNui(6, "Right forearm");
        json jBelt = CreateModelArmorNui(7, "Belt");
        json jLeftForearm = CreateModelArmorNui(8, "Left forearm");
        json jPelvis = CreateModelArmorNui(10, "Pelvis");

        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 25.0));
        jRow = JsonArrayInsert(jRow, jRightForearm);
        jRow = JsonArrayInsert(jRow, jPelvis);
        jRow = JsonArrayInsert(jRow, jBelt);
        jRow = JsonArrayInsert(jRow, jPelvis);
        jRow = JsonArrayInsert(jRow, jLeftForearm);
        jRow = JsonArrayInsert(jRow, jSpacer);

        jCol = JsonArrayInsert(jCol, NuiHeight(NuiRow(jRow), APP_ARMOR_BUTTON_HEIGHT));
    }

    jRow = JsonArray();
    {
        json jBelt = CreateModelArmorNui(7, "Belt");
        json jRightHand = CreateModelArmorNui(9, "Right hand");
        json jPelvis = CreateModelArmorNui(10, "Pelvis");
        json jLeftHand = CreateModelArmorNui(11, "Left hand");

        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 25.0));
        jRow = JsonArrayInsert(jRow, jRightHand);
        jRow = JsonArrayInsert(jRow, jPelvis);
        jRow = JsonArrayInsert(jRow, jBelt);
        jRow = JsonArrayInsert(jRow, jPelvis);
        jRow = JsonArrayInsert(jRow, jLeftHand);
        jRow = JsonArrayInsert(jRow, jSpacer);

        jCol = JsonArrayInsert(jCol, NuiHeight(NuiRow(jRow), APP_ARMOR_BUTTON_HEIGHT));
    }

    jRow = JsonArray();
    {
        json jRightThigh = CreateModelArmorNui(12, "Right thigh");
        json jLeftThigh = CreateModelArmorNui(13, "Left thigh");

        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 48.0));
        jRow = JsonArrayInsert(jRow, jRightThigh);
        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 20.0));
        jRow = JsonArrayInsert(jRow, jLeftThigh);
        jRow = JsonArrayInsert(jRow, jSpacer);

        jCol = JsonArrayInsert(jCol, NuiHeight(NuiRow(jRow), APP_ARMOR_BUTTON_HEIGHT));
    }

    jRow = JsonArray();
    {
        json jRightShin = CreateModelArmorNui(14, "Right shin");
        json jLeftShin = CreateModelArmorNui(15, "Left shin");

        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 48.0));
        jRow = JsonArrayInsert(jRow, jRightShin);
        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 20.0));
        jRow = JsonArrayInsert(jRow, jLeftShin);
        jRow = JsonArrayInsert(jRow, jSpacer);

        jCol = JsonArrayInsert(jCol, NuiHeight(NuiRow(jRow), APP_ARMOR_BUTTON_HEIGHT));
    }

    jRow = JsonArray();
    {
        json jRightFoot = CreateModelArmorNui(16, "Right foot");
        json jLeftFoot = CreateModelArmorNui(17, "Left foot");

        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 47.0));
        jRow = JsonArrayInsert(jRow, jRightFoot);
        jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 24.0));
        jRow = JsonArrayInsert(jRow, jLeftFoot);
        jRow = JsonArrayInsert(jRow, jSpacer);

        jCol = JsonArrayInsert(jCol, NuiHeight(NuiRow(jRow), APP_ARMOR_BUTTON_HEIGHT));
    }

    return jCol;
}

json CreateAppArmorRobe()
{
    json jRow = JsonArray();

    json jCol = JsonArray();

    jRow = JsonArray();

    string sPart = "18";

    json jButton = NuiButton(JsonString(""));
    jButton = NuiId(jButton, ARMOR_PART + sPart);
    jButton = NuiEncouraged(jButton, NuiBind(ARMOR_PART_ENCOURAGED + sPart));
    jButton = NuiTooltip(jButton, JsonString("Robe"));
    jButton = NuiWidth(jButton, APP_ARMOR_IMAGE_WIDTH - 50.0);
    jButton = NuiHeight(jButton, APP_ARMOR_IMAGE_HEIGHT - 25.0);
    jButton = AppSetForegroundColor(jButton);

    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), 20.0));
    jRow = JsonArrayInsert(jRow, jButton);

    jCol = JsonArrayInsert(jCol, NuiRow(jRow));

    return jCol;
}

json CreateAppArmorPartsImage(
    json jElementDrawAt,
    string sImageStatic,
    string sImageBind,
    float fWidth,
    float fHeight)
{
    json jImageList = JsonArray();

    json jImage = NuiDrawListImage(
        JsonBool(TRUE),
        JsonString(sImageStatic),
        NuiRect(
            0.0,
            0.0,
            fWidth,
            fHeight),
        JsonInt(NUI_ASPECT_FIT),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

    json jImageParts = NuiDrawListImage(
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
        NUI_DRAW_LIST_ITEM_ORDER_AFTER,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

    jImageList = JsonArrayInsert(jImageList, jImage);
    jImageList = JsonArrayInsert(jImageList, jImageParts);

    json jResult = NuiDrawList(NuiCol(jElementDrawAt), JsonBool(FALSE), jImageList);
    jResult = NuiWidth(jResult, fWidth);
    jResult = NuiHeight(jResult, fHeight);

    return jResult;
}

json CreateAppArmorNextElements()
{
    json jRow = JsonArray();
    json jCol = JsonArray();
    {
        json jSpacer = NuiSpacer();

        json jArmorParts = CreateAppArmorParts();
        json jRobe = CreateAppArmorRobe();

        json jArmorPartsImage = CreateAppArmorPartsImage(
            jArmorParts,
            "app_armor_body",
            APP_ARMOR_PART_IMAGE,
            APP_ARMOR_IMAGE_WIDTH,
            APP_ARMOR_IMAGE_HEIGHT);

        json jRobeImage = CreateAppArmorPartsImage(
            jRobe,
            "app_cloth_body",
            APP_ARMOR_PART_IMAGE_2,
            APP_ARMOR_IMAGE_WIDTH,
            APP_ARMOR_IMAGE_HEIGHT);

        jRow = JsonArrayInsert(jRow, jSpacer);
        jRow = JsonArrayInsert(jRow, jArmorPartsImage);
        jRow = JsonArrayInsert(jRow, jRobeImage);
        jRow = JsonArrayInsert(jRow, jSpacer);
    };

    return NuiRow(jRow);
}

json CreateAppArmorPartPicker()
{
    json jLeftBtn = NuiButtonImage(JsonString(APP_ARROW_PREV_BTN));
    jLeftBtn = NuiId(jLeftBtn, APP_PREV_ARMOR_PART);
    jLeftBtn = NuiWidth(jLeftBtn, APP_BTN_WIDTH);
    jLeftBtn = NuiHeight(jLeftBtn, APP_BTN_HEIGHT);
    jLeftBtn = NuiTooltip(jLeftBtn, JsonString("Previous armor part"));
    jLeftBtn = AppSetForegroundColor(jLeftBtn);

    json jCombo = NuiCombo(
        NuiBind(ARMOR_ENTRIES),
        NuiBind(ARMOR_ID));
    jCombo = NuiHeight(jCombo, APP_BTN_HEIGHT);

    json jRightBtn = NuiButtonImage(JsonString(APP_ARROW_NEXT_BTN));
    jRightBtn = NuiId(jRightBtn, APP_NEXT_ARMOR_PART);
    jRightBtn = NuiWidth(jRightBtn, APP_BTN_WIDTH);
    jRightBtn = NuiHeight(jRightBtn, APP_BTN_HEIGHT);
    jRightBtn = NuiTooltip(jRightBtn, JsonString("Next armor part"));
    jRightBtn = AppSetForegroundColor(jRightBtn);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jLeftBtn);
    jRow = JsonArrayInsert(jRow, jCombo);
    jRow = JsonArrayInsert(jRow, jRightBtn);

    return NuiRow(jRow);
}

json CreateAppArmorPickerElements()
{
    json jLeftBtn = NuiButtonImage(JsonString(APP_ARROW_PREV_BTN));
    jLeftBtn = NuiId(jLeftBtn, APP_PREV_ELEMENT);
    jLeftBtn = NuiWidth(jLeftBtn, APP_BTN_WIDTH);
    jLeftBtn = NuiHeight(jLeftBtn, APP_BTN_HEIGHT);
    jLeftBtn = NuiTooltip(jLeftBtn, JsonString("Previous element"));
    jLeftBtn = AppSetForegroundColor(jLeftBtn);

    json jCombo = NuiCombo(
        NuiBind(ARMOR_ELEMENTS_ENTRIES),
        NuiBind(ARMOR_ELEMENTS_ID));
    jCombo = NuiHeight(jCombo, APP_BTN_HEIGHT);

    json jRightBtn = NuiButtonImage(JsonString(APP_ARROW_NEXT_BTN));
    jRightBtn = NuiId(jRightBtn, APP_NEXT_ELEMENT);
    jRightBtn = NuiWidth(jRightBtn, APP_BTN_WIDTH);
    jRightBtn = NuiHeight(jRightBtn, APP_BTN_HEIGHT);
    jRightBtn = NuiTooltip(jRightBtn, JsonString("Next element"));
    jRightBtn = AppSetForegroundColor(jRightBtn);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jLeftBtn);
    jRow = JsonArrayInsert(jRow, jCombo);
    jRow = JsonArrayInsert(jRow, jRightBtn);

    return NuiRow(jRow);
}

json CreateAppArmorPartPickerMerge()
{
    json jSpacer = NuiSpacer();

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 27.0));
    jRow = JsonArrayInsert(jRow, CreateAppArmorPartPicker());
    jRow = JsonArrayInsert(jRow, CreateAppArmorPickerElements());
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

int GetAppArmorModelFromComboId(int nId)
{
    switch(nId)
    {
        case 0:
            return ITEM_APPR_ARMOR_MODEL_RSHOULDER;
        case 1:
            return ITEM_APPR_ARMOR_MODEL_NECK;
        case 2:
            return ITEM_APPR_ARMOR_MODEL_LSHOULDER;
        case 3:
            return ITEM_APPR_ARMOR_MODEL_RBICEP;
        case 4:
            return ITEM_APPR_ARMOR_MODEL_TORSO;
        case 5:
            return ITEM_APPR_ARMOR_MODEL_LBICEP;
        case 6:
            return ITEM_APPR_ARMOR_MODEL_RFOREARM;
        case 7:
            return ITEM_APPR_ARMOR_MODEL_BELT;
        case 8:
            return ITEM_APPR_ARMOR_MODEL_LFOREARM;
        case 9:
            return ITEM_APPR_ARMOR_MODEL_RHAND;
        case 10:
            return ITEM_APPR_ARMOR_MODEL_PELVIS;
        case 11:
            return ITEM_APPR_ARMOR_MODEL_LHAND;
        case 12:
            return ITEM_APPR_ARMOR_MODEL_RTHIGH;
        case 13:
            return ITEM_APPR_ARMOR_MODEL_LTHIGH;
        case 14:
            return ITEM_APPR_ARMOR_MODEL_RSHIN;
        case 15:
            return ITEM_APPR_ARMOR_MODEL_LSHIN;
        case 16:
            return ITEM_APPR_ARMOR_MODEL_RFOOT;
        case 17:
            return ITEM_APPR_ARMOR_MODEL_LFOOT;
        case 18:
            return ITEM_APPR_ARMOR_MODEL_ROBE;
    }

    return 0;
}

void FeedArmorColor(
    object oPC,
    object oItem,
    int nToken,
    int nType,
    int nColorChannelId,
    int nChannel)
{
    string sBind = AppGetColorPickerButtonBind(nColorChannelId);

    int nColor = GetItemAppearance(oItem, nType, nChannel);
    string sId = IntToString(nColor);

    AppOffColorEncouraged(oPC, nToken);
    AppOnColorEncouraged(oPC, nToken, APP_BTN + sId);
    NuiSetBind(oPC, nToken, APP_COLOR_TE, JsonString(sId));

    string sValue = AppGetItemColor(nColorChannelId);
    NuiSetBind(oPC, nToken, sBind, JsonString(sValue + sId));
    AppSetColorPickerButtonEncouraged(oPC, nToken, 6, sBind, 0);
    FeedAppColorTemplate(oPC, nToken, sValue);
}

void FeedArmorPartModels(
    object oPC,
    object oPCopy,
    int nToken,
    int nModel)
{
    string s2daParts = Get2daPart(nModel);

    object oArmor = GetItemInSlot(INVENTORY_SLOT_CHEST, oPCopy);

    int nArmorAc = 0;
    if(nModel == ITEM_APPR_ARMOR_MODEL_TORSO)
    {
        int nChestId = GetItemAppearance(oArmor, ITEM_APPR_TYPE_ARMOR_MODEL, ITEM_APPR_ARMOR_MODEL_TORSO);
        nArmorAc = StringToInt(Get2DAString("parts_chest", "ACBONUS", nChestId));
    }

    json jModels = JsonArray();

    int nLength = Get2DARowCount(s2daParts);

    int nAppearance = GetItemAppearance(oArmor, ITEM_APPR_TYPE_ARMOR_MODEL, nModel);

    int nId, nAppearanceId = 0;
    int i;
    for(i=0; i<=nLength; i++)
    {
        if(nAppearance == i)
        {
            nAppearanceId = nId;
        }

        string sAcBonus = Get2DAString(s2daParts, "ACBONUS", i);
        if(sAcBonus != "")
        {
            if(nModel == ITEM_APPR_ARMOR_MODEL_TORSO && nArmorAc != StringToInt(sAcBonus))
            {
                continue;
            }

            jModels = JsonArrayInsert(jModels, NuiComboEntry(IntToString(i), nId++));
        }
    }

    NuiSetBind(oPC, nToken, ARMOR_ELEMENTS_ENTRIES, jModels);
    NuiSetBind(oPC, nToken, ARMOR_ELEMENTS_ID, JsonInt(nAppearanceId));
}

void FeedAppArmorSpecificColor(
    object oPC,
    object oArmor,
    int nModel,
    int nToken)
{
    int nChannel = ITEM_APPR_ARMOR_NUM_COLORS + (nModel * ITEM_APPR_ARMOR_NUM_COLORS);

    int nFirstLeather = GetItemAppearance(oArmor,
        ITEM_APPR_TYPE_ARMOR_COLOR, nChannel + ITEM_APPR_ARMOR_COLOR_LEATHER1);

    int nSecondLeather = GetItemAppearance(oArmor,
        ITEM_APPR_TYPE_ARMOR_COLOR, nChannel + ITEM_APPR_ARMOR_COLOR_LEATHER2);

    int nFirstCloth = GetItemAppearance(oArmor,
        ITEM_APPR_TYPE_ARMOR_COLOR, nChannel + ITEM_APPR_ARMOR_COLOR_CLOTH1);

    int nSecondCloth = GetItemAppearance(oArmor,
        ITEM_APPR_TYPE_ARMOR_COLOR, nChannel + ITEM_APPR_ARMOR_COLOR_CLOTH2);

    int nFirstMetal = GetItemAppearance(oArmor,
        ITEM_APPR_TYPE_ARMOR_COLOR, nChannel + ITEM_APPR_ARMOR_COLOR_METAL1);

    int nSecondMetal = GetItemAppearance(oArmor,
        ITEM_APPR_TYPE_ARMOR_COLOR, nChannel + ITEM_APPR_ARMOR_COLOR_METAL2);

    NuiSetBind(oPC, nToken,
        AppGetColorPickerButtonBind(ITEM_APPR_ARMOR_COLOR_LEATHER1),
        JsonString("cc_color_" + IntToString(nFirstLeather)));

    NuiSetBind(oPC, nToken,
        AppGetColorPickerButtonBind(ITEM_APPR_ARMOR_COLOR_LEATHER2),
        JsonString("cc_color_" + IntToString(nSecondLeather)));

    NuiSetBind(oPC, nToken,
        AppGetColorPickerButtonBind(ITEM_APPR_ARMOR_COLOR_CLOTH1),
        JsonString("cc_color_" + IntToString(nFirstCloth)));

    NuiSetBind(oPC, nToken,
        AppGetColorPickerButtonBind(ITEM_APPR_ARMOR_COLOR_CLOTH2),
        JsonString("cc_color_" + IntToString(nSecondCloth)));

    NuiSetBind(oPC, nToken,
        AppGetColorPickerButtonBind(ITEM_APPR_ARMOR_COLOR_METAL1),
        JsonString("cc_color_m_" + IntToString(nFirstMetal)));

    NuiSetBind(oPC, nToken,
        AppGetColorPickerButtonBind(ITEM_APPR_ARMOR_COLOR_METAL2),
        JsonString("cc_color_m_" + IntToString(nSecondMetal)));

    int nActive = JsonGetInt(NuiGetBind(oPC, nToken, APP_COLOR_BTN_ACTIVE));
    switch(nActive)
    {
        case ITEM_APPR_ARMOR_COLOR_LEATHER1:
            AppSetItemColor(oPC, nToken, nFirstLeather, nChannel);
            break;
        case ITEM_APPR_ARMOR_COLOR_LEATHER2:
            AppSetItemColor(oPC, nToken, nSecondLeather, nChannel);
            break;
        case ITEM_APPR_ARMOR_COLOR_CLOTH1:
            AppSetItemColor(oPC, nToken, nFirstCloth, nChannel);
            break;
        case ITEM_APPR_ARMOR_COLOR_CLOTH2:
            AppSetItemColor(oPC, nToken, nSecondCloth, nChannel);
            break;
        case ITEM_APPR_ARMOR_COLOR_METAL1:
            AppSetItemColor(oPC, nToken, nFirstMetal, nChannel);
            break;
        case ITEM_APPR_ARMOR_COLOR_METAL2:
            AppSetItemColor(oPC, nToken, nSecondMetal, nChannel);
            break;
    }
}

void FeedAppArmorPart(
    object oPC,
    object oPCopy,
    int nToken,
    int nId)
{
    string sId = IntToString(nId);
    string sEncouragedPart = ARMOR_PART_ENCOURAGED + sId;

    NuiSetBindWatch(oPC, nToken, ARMOR_ID, FALSE);
    NuiSetBindWatch(oPC, nToken, ARMOR_ELEMENTS_ID, FALSE);

    string sCurrentPart = JsonGetString(NuiGetBind(oPC, nToken, ARMOR_PART_ENCOURAGED_CURRENT));
    if(sCurrentPart != "")
    {
        NuiSetBind(oPC, nToken, sCurrentPart, JsonBool(FALSE));
    }

    NuiSetBind(oPC, nToken, ARMOR_PART_ENCOURAGED_CURRENT, JsonString(sEncouragedPart));

    NuiSetBind(oPC, nToken, sEncouragedPart, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, ARMOR_ID, JsonInt(nId));

    if(nId < 18)
    {
        NuiSetBind(oPC, nToken, APP_ARMOR_PART_IMAGE, JsonString(ARMOR_PART + IntToString(nId)));
        NuiSetBind(oPC, nToken, APP_ARMOR_PART_IMAGE_2, JsonString("app_cloth_body"));
    }
    else
    {
        NuiSetBind(oPC, nToken, APP_ARMOR_PART_IMAGE, JsonString("app_armor_body"));
        NuiSetBind(oPC, nToken, APP_ARMOR_PART_IMAGE_2, JsonString(ARMOR_PART + IntToString(nId)));
    }

    FeedArmorPartModels(oPC, oPCopy, nToken, GetAppArmorModelFromComboId(nId));

    NuiSetBindWatch(oPC, nToken, ARMOR_ID, TRUE);
    NuiSetBindWatch(oPC, nToken, ARMOR_ELEMENTS_ID, TRUE);

    object oArmor = GetItemInSlot(INVENTORY_SLOT_CHEST, oPCopy);
    if(JsonGetInt(NuiGetBind(oPC, nToken, APP_ARMOR_SPECIFIC_COLOR)))
    {
        int nModelPart = GetAppArmorModelFromComboId(nId);
        FeedAppArmorSpecificColor(oPC, oArmor, nModelPart, nToken);
    }
    else
    {
        FeedBasicColorPickerButtons(oPC, oArmor, nToken);
    }
}

void FeedAppArmorWindow(object oPC, int nToken)
{
    json jEntries = JsonArray();
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Right shoulder", 0));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Neck", 1));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Left shoulder", 2));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Right biceps", 3));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Torso", 4));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Left biceps", 5));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Right forearm", 6));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Belt", 7));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Left forearm", 8));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Right hand", 9));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Pelvis", 10));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Left hand", 11));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Right thigh", 12));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Left thigh", 13));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Right shin", 14));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Left shin", 15));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Right foot", 16));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Left foot", 17));
    jEntries = JsonArrayInsert(jEntries, NuiComboEntry("Robe", 18));

    NuiSetBind(oPC, nToken, ARMOR_ENTRIES, jEntries);
    NuiSetBind(oPC, nToken, ARMOR_ID, JsonInt(0));

    object oArmor = GetItemInSlot(INVENTORY_SLOT_CHEST, oPC);

    NuiSetBind(oPC, nToken, APP_COLOR_BTN_ACTIVE, JsonInt(0));

    NuiSetBind(oPC, nToken,
        AppGetColorPickerButtonEncouragedBind(ITEM_APPR_ARMOR_COLOR_LEATHER1), JsonBool(TRUE));

    FeedBasicColorPickerButtons(oPC, oArmor, nToken);

    NuiSetBind(oPC, nToken, APP_ARMOR_PART_IMAGE, JsonString("ARMOR_PART_0"));
}

void FeedAppArmorElement(
    object oPC,
    object oPCopy,
    int nToken,
    int nId)
{
    NuiSetBindWatch(oPC, nToken, ARMOR_ELEMENTS_ID, FALSE);

    NuiSetBind(oPC, nToken, ARMOR_ELEMENTS_ID, JsonInt(nId));

    int nModelId = JsonGetInt(NuiGetBind(oPC, nToken, ARMOR_ID));
    int nModelPart = GetAppArmorModelFromComboId(nModelId);

    int nNewValue = StringToInt(
        NuiGetValueFromCombo(oPC, nToken, ARMOR_ELEMENTS_ENTRIES, nId));

    CreateNewItem(
        oPCopy,
        GetItemInSlot(INVENTORY_SLOT_CHEST, oPCopy),
        INVENTORY_SLOT_CHEST,
        ITEM_APPR_TYPE_ARMOR_MODEL,
        nModelPart,
        nNewValue);

    NuiSetBindWatch(oPC, nToken, ARMOR_ELEMENTS_ID, TRUE);
}

void CreateAppArmorWindow(object oPC)
{
    json jPrevElements = JsonArray();

    jPrevElements = JsonArrayInsert(jPrevElements, CreateAppColorPicker());
    jPrevElements = JsonArrayInsert(jPrevElements, CreateAppArmorSpecificColorPicker());

    json jNextElements = JsonArray();
    jNextElements = JsonArrayInsert(jNextElements, CreateAppArmorPartPickerMerge());
    jNextElements = JsonArrayInsert(jNextElements, CreateAppArmorNextElements());

    int nToken = AppColorTemplateWindow(
        oPC,
        APP_ARMOR_WINDOW,
        "Armor",
        "cc_color_",
        jPrevElements,
        jNextElements,
        1010.0,
        "lib_app_armor_ev",
        80.0);

    NuiSetBindWatch(oPC, nToken, ARMOR_ID, TRUE);
    FeedAppArmorWindow(oPC, nToken);
    NuiSetBindWatch(oPC, nToken, APP_COLOR_TE, TRUE);
    NuiSetBindWatch(oPC, nToken, ARMOR_ELEMENTS_ID, TRUE);
    NuiSetBindWatch(oPC, nToken, APP_ARMOR_SPECIFIC_COLOR, TRUE);
}

void AppArmorColorEvents(
    object oPC,
    object oPCopy,
    int nToken,
    int nColor)
{
    int nChannel = JsonGetInt(NuiGetBind(oPC, nToken, APP_COLOR_BTN_ACTIVE));
    int nChannelId = nChannel;

    if(JsonGetInt(NuiGetBind(oPC, nToken, APP_ARMOR_SPECIFIC_COLOR)))
    {
        int nModelId = JsonGetInt(NuiGetBind(oPC, nToken, ARMOR_ID));
        int nModelPart = GetAppArmorModelFromComboId(nModelId);

        nChannel = ITEM_APPR_ARMOR_NUM_COLORS +
            (nModelPart * ITEM_APPR_ARMOR_NUM_COLORS) + nChannel;
    }

    object oArmor = GetItemInSlot(INVENTORY_SLOT_CHEST, oPCopy);

    CreateNewItem(oPCopy, oArmor, INVENTORY_SLOT_CHEST, ITEM_APPR_TYPE_ARMOR_COLOR, nChannel, nColor);
    AppSetItemColor(oPC, nToken, nColor, nChannelId);
}

void AppArmorCopy(object oSource, object oTarget)
{
    object oArmor = GetItemInSlot(INVENTORY_SLOT_CHEST, oSource);
    CopyItemToSlot(oArmor, oTarget, INVENTORY_SLOT_CHEST);
}

void AppArmorEvents(
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
            int nChannel = StringToInt(StringReplace(sEventElem, APP_COLOR_BTN, ""));
            int nChannelColor = nChannel;

            if(JsonGetInt(NuiGetBind(oPC, nToken, APP_ARMOR_SPECIFIC_COLOR)))
            {
                int nModelId = JsonGetInt(NuiGetBind(oPC, nToken, ARMOR_ID));
                int nModelPart = GetAppArmorModelFromComboId(nModelId);

                nChannel = ITEM_APPR_ARMOR_NUM_COLORS +
                    (nModelPart * ITEM_APPR_ARMOR_NUM_COLORS) + nChannel;
            }

            object oArmor = GetItemInSlot(INVENTORY_SLOT_CHEST, oPCopy);

            NuiSetBindWatch(oPC, nToken, APP_COLOR_TE, FALSE);
            FeedArmorColor(oPC, oArmor, nToken, ITEM_APPR_TYPE_ARMOR_COLOR, nChannelColor, nChannel);
            NuiSetBindWatch(oPC, nToken, APP_COLOR_TE, TRUE);
        }
        else if(sEventElem == APP_PREV_ARMOR_PART)
        {
            int nId = AppComboValidate(oPC, nToken, ARMOR_ENTRIES, ARMOR_ID, -1);
            FeedAppArmorPart(oPC, oPCopy, nToken, nId);
        }
        else if(sEventElem == APP_NEXT_ARMOR_PART)
        {
            int nId = AppComboValidate(oPC, nToken, ARMOR_ENTRIES, ARMOR_ID, 1);
            FeedAppArmorPart(oPC, oPCopy, nToken, nId);
        }
        else if(sEventElem == APP_PREV_ELEMENT)
        {
            int nId = AppComboValidate(oPC, nToken, ARMOR_ELEMENTS_ENTRIES, ARMOR_ELEMENTS_ID, -1);
            FeedAppArmorElement(oPC, oPCopy, nToken, nId);
        }
        else if(sEventElem == APP_NEXT_ELEMENT)
        {
            int nId = AppComboValidate(oPC, nToken, ARMOR_ELEMENTS_ENTRIES, ARMOR_ELEMENTS_ID, 1);
            FeedAppArmorElement(oPC, oPCopy, nToken, nId);
        }
        else if(sEventElem == APP_PREV_COLOR_BTN)
        {
            string sBtnId = JsonGetString(NuiGetBind(oPC, nToken, NUI_DATA_ENCOURAGED));
            int nColor = StringToInt(StringReplace(sBtnId, APP_BTN, ""));
            nColor += -1;

            AppArmorColorEvents(oPC, oPCopy, nToken, nColor);
        }
        else if(sEventElem == APP_NEXT_COLOR_BTN)
        {
            string sBtnId = JsonGetString(NuiGetBind(oPC, nToken, NUI_DATA_ENCOURAGED));
            int nColor = StringToInt(StringReplace(sBtnId, APP_BTN, ""));
            nColor += 1;

            AppArmorColorEvents(oPC, oPCopy, nToken, nColor);
        }
        else if(sEventElem == APP_ARMOR_CLEAR_BTN)
        {
            AppArmorColorEvents(oPC, oPCopy, nToken, 255);
        }
        else if(FindSubString(sEventElem, APP_BTN) >= 0)
        {
            int nColor = StringToInt(StringReplace(sEventElem, APP_BTN, ""));

            AppArmorColorEvents(oPC, oPCopy, nToken, nColor);
        }
        else if(FindSubString(sEventElem, ARMOR_PART) >= 0)
        {
            int nId = StringToInt(StringReplace(sEventElem, ARMOR_PART, ""));
            FeedAppArmorPart(oPC, oPCopy, nToken, nId);
        }
        else if(sEventElem == APP_CONFIRM_BTN)
        {
            RemoveAntyExploitStatus(oPC);
            AppArmorCopy(oPCopy, oPC);
            DelayCommand(0.2, SetAntyExploitStatus(oPC));

            AppDestroyActiveWindow(oPC);

            int nTokenPanel = NuiFindWindow(oPC, APP_RIGHT_PANEL_WINDOW);
            AppRightPanelOffEncouraged(oPC, nTokenPanel);
        }
        else if(sEventElem == APP_CANCEL_BTN)
        {
            RemoveAntyExploitStatus(oPC);
            AppArmorCopy(oPC, oPCopy);
            SetAntyExploitStatus(oPC);

            AppDestroyActiveWindow(oPC);

            int nTokenPanel = NuiFindWindow(oPC, APP_RIGHT_PANEL_WINDOW);
            AppRightPanelOffEncouraged(oPC, nTokenPanel);
        }
    }
    else if(sEventType == EVENT_TYPE_WATCH)
    {
        if(sEventElem == ARMOR_ID)
        {
            int nId = JsonGetInt(NuiGetBind(oPC, nToken, sEventElem));
            FeedAppArmorPart(oPC, oPCopy, nToken, nId);
        }
        else if(sEventElem == ARMOR_ELEMENTS_ID)
        {
            int nId = JsonGetInt(NuiGetBind(oPC, nToken, sEventElem));
            FeedAppArmorElement(oPC, oPCopy, nToken, nId);
        }
        else if(sEventElem == APP_ARMOR_SPECIFIC_COLOR)
        {
            int nChannel = JsonGetInt(NuiGetBind(oPC, nToken, APP_COLOR_BTN_ACTIVE));
            int nChannelColor = nChannel;

            object oArmor = GetItemInSlot(INVENTORY_SLOT_CHEST, oPCopy);
            if(JsonGetInt(NuiGetBind(oPC, nToken, APP_ARMOR_SPECIFIC_COLOR)))
            {
                int nModelId = JsonGetInt(NuiGetBind(oPC, nToken, ARMOR_ID));
                int nModelPart = GetAppArmorModelFromComboId(nModelId);

                nChannel = ITEM_APPR_ARMOR_NUM_COLORS +
                    (nModelPart * ITEM_APPR_ARMOR_NUM_COLORS) + nChannel;

                FeedAppArmorSpecificColor(oPC, oArmor, nModelPart, nToken);
            }
            else
            {
                FeedBasicColorPickerButtons(oPC, oArmor, nToken);
            }

            NuiSetBindWatch(oPC, nToken, APP_COLOR_TE, FALSE);
            FeedArmorColor(oPC, oArmor, nToken, ITEM_APPR_TYPE_ARMOR_COLOR, nChannelColor, nChannel);
            NuiSetBindWatch(oPC, nToken, APP_COLOR_TE, TRUE);
        }
        else if(sEventElem == APP_COLOR_TE)
        {
            int nColor = StringToInt(JsonGetString(NuiGetBind(oPC, nToken, APP_COLOR_TE)));

            AppArmorColorEvents(oPC, oPCopy, nToken, nColor);
        }
    }
}

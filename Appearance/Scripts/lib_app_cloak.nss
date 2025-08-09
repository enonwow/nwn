#include "x3_inc_string"
#include "lib_app"

struct ModelInfo GetCloakModels(
    object oPC,
    object oCloak)
{
    json jModels = JsonArray();
    json jModelIds = JsonArray();

    string sItem = Get2DAString("baseitems", "ItemClass", BASE_ITEM_CLOAK);
    sItem = "i" + sItem + "_m_";

    int nAppearance = GetItemAppearance(oCloak, ITEM_APPR_TYPE_SIMPLE_MODEL, -1);

    int nLength = Get2DARowCount("cloakmodel");

    int nId = 0;
    int i, nAppId;
    for(i = 1; i <= nLength; i++)
    {
        string sModelId = sItem + IntToPaddedString(i, 3);

        if(ResManGetAliasFor(sModelId, RESTYPE_PLT) != "")
        {
            string sModel = Get2DAString("cloakmodel", "Label", i);
            if(sModel != "")
            {
                jModels = JsonArrayInsert(jModels, NuiComboEntry(sModel, nId++));
            }

            if(nAppearance == i)
            {
                nAppId = nId;
            }

            jModelIds = JsonArrayInsert(jModelIds, JsonInt(i));
        }
    }

    struct ModelInfo ModelInfo;

    ModelInfo.nLength = nId;
    ModelInfo.jModels = jModels;
    ModelInfo.jModelIds = jModelIds;
    ModelInfo.nAppId = nAppearance;
    ModelInfo.sKeyPrefix = sItem;
    ModelInfo.sKeySuffix = "_con";

    return ModelInfo;
}

void FeedAppCloakModel(
    object oPC,
    object oPCopy,
    int nToken,
    int nModelId)
{
    NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, FALSE);

    EncourageItemModel(oPC, nToken, nModelId);

    NuiSetBind(oPC, nToken, APP_ITEM_ID, JsonInt(nModelId));

    json jModelIds = NuiGetBind(oPC, nToken, APP_ITEM_MODELS_ID);

    int nModelIndex = JsonGetInt(JsonArrayGet(jModelIds, nModelId));

    object oCloak = GetItemInSlot(INVENTORY_SLOT_CLOAK, oPCopy);
    CreateNewItem(oPCopy, oCloak, INVENTORY_SLOT_CLOAK, ITEM_APPR_TYPE_SIMPLE_MODEL, 0, nModelIndex);

    NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, TRUE);
}

void FeedCloakColor(
    object oPC,
    object oPCopy,
    int nToken,
    int nChannel)
{
    object oCloak = GetItemInSlot(INVENTORY_SLOT_CLOAK, oPCopy);

    string sBind = AppGetColorPickerButtonBind(nChannel);
    int nColor = GetItemAppearance(oCloak, ITEM_APPR_TYPE_ARMOR_COLOR, nChannel);
    string sId = IntToString(nColor);

    AppOffColorEncouraged(oPC, nToken);
    AppOnColorEncouraged(oPC, nToken, APP_BTN + sId);
    NuiSetBind(oPC, nToken, APP_COLOR_TE, JsonString(sId));

    string sValue = AppGetItemColor(nChannel);
    NuiSetBind(oPC, nToken, sBind, JsonString(sValue + sId));
    AppSetColorPickerButtonEncouraged(oPC, nToken, 6, sBind, 0);
    FeedAppColorTemplate(oPC, nToken, sValue);
}

void FeedAppCloakWindow(
    object oPC,
    int nToken,
    object oCloak,
    struct ModelInfo ModelInfo)
{
    FeedItem1Part(oPC, nToken, oCloak, ModelInfo);

    NuiSetBind(oPC, nToken, APP_COLOR_BTN_ACTIVE, JsonInt(0));

    NuiSetBind(oPC, nToken,
        AppGetColorPickerButtonEncouragedBind(ITEM_APPR_ARMOR_COLOR_LEATHER1), JsonBool(TRUE));

    FeedBasicColorPickerButtons(oPC, oCloak, nToken);

    NuiSetBind(oPC, nToken, APP_ITEM_ENTRIES, ModelInfo.jModels);
}

void CreateAppCloakWindow(object oPC)
{
    object oCloak = GetItemInSlot(INVENTORY_SLOT_CLOAK, oPC);
    struct ModelInfo ModelInfo = GetCloakModels(oPC, oCloak);

    json jPrevElements = JsonArray();

    jPrevElements = JsonArrayInsert(jPrevElements, CreateAppColorPicker());

    json jNextElements = JsonArray();
    jNextElements = JsonArrayInsert(jNextElements, CreateAppItem1PartModel(ModelInfo));

    int nToken = AppColorTemplateWindow(
        oPC,
        APP_CLOAK_WINDOW,
        "Cloak",
        "cc_color_",
        jPrevElements,
        jNextElements,
        990.0,
        "lib_app_cloak_ev",
        80.0);

    FeedAppCloakWindow(oPC, nToken, oCloak, ModelInfo);
}

void AppCloakColorEvents(
    object oPC,
    object oPCopy,
    int nToken,
    int nColor)
{
    int nChannel = JsonGetInt(NuiGetBind(oPC, nToken, APP_COLOR_BTN_ACTIVE));

    object oCloak = GetItemInSlot(INVENTORY_SLOT_CLOAK, oPCopy);

    CreateNewItem(oPCopy, oCloak, INVENTORY_SLOT_CLOAK, ITEM_APPR_TYPE_ARMOR_COLOR, nChannel, nColor);
    AppSetItemColor(oPC, nToken, nColor, nChannel);
}

void AppCloakCopy(object oSource, object oTarget)
{
    object oCloak = GetItemInSlot(INVENTORY_SLOT_CLOAK, oSource);
    CopyItemToSlot(oCloak, oTarget, INVENTORY_SLOT_CLOAK);
}

void AppCloakEvents(
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

            NuiSetBindWatch(oPC, nToken, APP_COLOR_TE, FALSE);
            FeedCloakColor(oPC, oPCopy, nToken, nChannel);
            NuiSetBindWatch(oPC, nToken, APP_COLOR_TE, TRUE);
        }
        else if(FindSubString(sEventElem, APP_BTN) >= 0)
        {
            int nColor = StringToInt(StringReplace(sEventElem, APP_BTN, ""));

            AppCloakColorEvents(oPC, oPCopy, nToken, nColor);
        }
        else if(sEventElem == APP_PREV_COLOR_BTN)
        {
            string sBtnId = JsonGetString(NuiGetBind(oPC, nToken, NUI_DATA_ENCOURAGED));
            int nColor = StringToInt(StringReplace(sBtnId, APP_BTN, ""));
            nColor--;

            AppCloakColorEvents(oPC, oPCopy, nToken, nColor);
        }
        else if(sEventElem == APP_NEXT_COLOR_BTN)
        {
            string sBtnId = JsonGetString(NuiGetBind(oPC, nToken, NUI_DATA_ENCOURAGED));
            int nColor = StringToInt(StringReplace(sBtnId, APP_BTN, ""));
            nColor++;

            AppCloakColorEvents(oPC, oPCopy, nToken, nColor);
        }
        else if(sEventElem == APP_ITEM_PREVIOUS_BTN)
        {
            int nModelId = AppComboValidate(oPC, nToken, APP_ITEM_ENTRIES, APP_ITEM_ID, -1);
            FeedAppCloakModel(oPC, oPCopy, nToken, nModelId);
        }
        else if(sEventElem == APP_ITEM_NEXT_BTN)
        {
            int nModelId = AppComboValidate(oPC, nToken, APP_ITEM_ENTRIES, APP_ITEM_ID, 1);
            FeedAppCloakModel(oPC, oPCopy, nToken, nModelId);
        }
        else if(FindSubString(sEventElem, APP_ITEM_MODEL) >= 0)
        {
            int nModelId = StringToInt(StringReplace(sEventElem, APP_ITEM_MODEL, ""));
            FeedAppCloakModel(oPC, oPCopy, nToken, nModelId);
        }
        else if(sEventElem == APP_CONFIRM_BTN)
        {
            RemoveAntyExploitStatus(oPC);
            AppCloakCopy(oPCopy, oPC);
            DelayCommand(0.2, SetAntyExploitStatus(oPC));

            AppDestroyActiveWindow(oPC);

            int nTokenPanel = NuiFindWindow(oPC, APP_RIGHT_PANEL_WINDOW);
            AppRightPanelOffEncouraged(oPC, nTokenPanel);
        }
        else if(sEventElem == APP_CANCEL_BTN)
        {
            RemoveAntyExploitStatus(oPC);
            AppCloakCopy(oPC, oPCopy);
            SetAntyExploitStatus(oPC);

            AppDestroyActiveWindow(oPC);

            int nTokenPanel = NuiFindWindow(oPC, APP_RIGHT_PANEL_WINDOW);
            AppRightPanelOffEncouraged(oPC, nTokenPanel);
        }
    }
    else if(sEventType == EVENT_TYPE_WATCH)
    {
        if(sEventElem == APP_COLOR_TE)
        {
            int nColor = StringToInt(JsonGetString(NuiGetBind(oPC, nToken, APP_COLOR_TE)));

            AppCloakColorEvents(oPC, oPCopy, nToken, nColor);
        }
        else if(sEventElem == APP_ITEM_ID)
        {
            int nModelId = AppComboValidate(oPC, nToken, APP_ITEM_ENTRIES, APP_ITEM_ID, 0);
            FeedAppCloakModel(oPC, oPCopy, nToken, nModelId);
        }
    }
}

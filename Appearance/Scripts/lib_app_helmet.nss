#include "x3_inc_string"
#include "lib_app"

void FeedAppHelmetModel(
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

    object oHelmet = GetItemInSlot(INVENTORY_SLOT_HEAD, oPCopy);
    CreateNewItem(oPCopy, oHelmet, INVENTORY_SLOT_HEAD, ITEM_APPR_TYPE_SIMPLE_MODEL, 0, nModelIndex);

    NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, TRUE);
}

void FeedHelmetColor(
    object oPC,
    object oPCopy,
    int nToken,
    int nChannel)
{
    object oHelmet = GetItemInSlot(INVENTORY_SLOT_HEAD, oPCopy);

    string sBind = AppGetColorPickerButtonBind(nChannel);
    int nColor = GetItemAppearance(oHelmet, ITEM_APPR_TYPE_ARMOR_COLOR, nChannel);
    string sId = IntToString(nColor);

    AppOffColorEncouraged(oPC, nToken);
    AppOnColorEncouraged(oPC, nToken, APP_BTN + sId);
    NuiSetBind(oPC, nToken, APP_COLOR_TE, JsonString(sId));

    string sValue = AppGetItemColor(nChannel);
    NuiSetBind(oPC, nToken, sBind, JsonString(sValue + sId));
    AppSetColorPickerButtonEncouraged(oPC, nToken, 6, sBind, 0);
    FeedAppColorTemplate(oPC, nToken, sValue);
}

void FeedAppHelmetWindow(
    object oPC,
    int nToken,
    struct ModelInfo ModelInfo)
{
    object oHelmet = GetItemInSlot(INVENTORY_SLOT_HEAD, oPC);

    NuiSetBind(oPC, nToken, APP_COLOR_BTN_ACTIVE, JsonInt(0));

    NuiSetBind(oPC, nToken,
        AppGetColorPickerButtonEncouragedBind(ITEM_APPR_ARMOR_COLOR_LEATHER1), JsonBool(TRUE));

    FeedBasicColorPickerButtons(oPC, oHelmet, nToken);

    NuiSetBind(oPC, nToken, APP_ITEM_ENTRIES, ModelInfo.jModels);

    int nId = ModelInfo.nAppId - 1;

    NuiSetBind(oPC, nToken, APP_ITEM_ID, JsonInt(nId));
    NuiSetBind(oPC, nToken, APP_ITEM_MODEL_ENCOURAGED, JsonInt(nId));
    NuiSetBind(oPC, nToken, APP_ITEM_MODEL_ENCOURAGED + IntToString(nId), JsonBool(TRUE));

    NuiSetBind(oPC, nToken, APP_ITEM_MODELS_ID, ModelInfo.jModelIds);
}

void CreateAppHelmetWindow(object oPC)
{
    struct ModelInfo ModelInfo = GetModelInfo(
        GetItemInSlot(INVENTORY_SLOT_HEAD, oPC),
        RESTYPE_PLT,
        "i",
        "_conv");

    json jPrevElements = JsonArray();

    jPrevElements = JsonArrayInsert(jPrevElements, CreateAppColorPicker());

    json jNextElements = JsonArray();
    jNextElements = JsonArrayInsert(jNextElements, CreateAppItemPrviews(ModelInfo));
    jNextElements = JsonArrayInsert(jNextElements, CreateAppItemPicker());
    jNextElements = JsonArrayInsert(jNextElements, NuiHeight(NuiSpacer(), 10.0));

    int nToken = AppColorTemplateWindow(
        oPC,
        APP_HELMET_WINDOW,
        "Helmet",
        "cc_color_",
        jPrevElements,
        jNextElements,
        1000.0,
        "lib_app_helmet_e",
        85.0);

    FeedAppHelmetWindow(oPC, nToken, ModelInfo);
    NuiSetBindWatch(oPC, nToken, APP_COLOR_TE, TRUE);
    NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, TRUE);
}

void AppHelmetColorEvents(
    object oPC,
    object oPCopy,
    int nToken,
    int nColor)
{
    int nChannel = JsonGetInt(NuiGetBind(oPC, nToken, APP_COLOR_BTN_ACTIVE));

    object oHelmet = GetItemInSlot(INVENTORY_SLOT_HEAD, oPCopy);

    CreateNewItem(oPCopy, oHelmet, INVENTORY_SLOT_HEAD, ITEM_APPR_TYPE_ARMOR_COLOR, nChannel, nColor);
    AppSetItemColor(oPC, nToken, nColor, nChannel);
}

void AppHelmetCopy(object oSource, object oTarget)
{
    object oHelmet = GetItemInSlot(INVENTORY_SLOT_HEAD, oSource);
    CopyItemToSlot(oHelmet, oTarget, INVENTORY_SLOT_HEAD);
}

void AppHelmetEvents(
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
            FeedHelmetColor(oPC, oPCopy, nToken, nChannel);
            NuiSetBindWatch(oPC, nToken, APP_COLOR_TE, TRUE);
        }
        else if(FindSubString(sEventElem, APP_BTN) >= 0)
        {
            int nColor = StringToInt(StringReplace(sEventElem, APP_BTN, ""));

            AppHelmetColorEvents(oPC, oPCopy, nToken, nColor);
        }
        else if(sEventElem == APP_PREV_COLOR_BTN)
        {
            string sBtnId = JsonGetString(NuiGetBind(oPC, nToken, NUI_DATA_ENCOURAGED));
            int nColor = StringToInt(StringReplace(sBtnId, APP_BTN, ""));
            nColor--;

            AppHelmetColorEvents(oPC, oPCopy, nToken, nColor);
        }
        else if(sEventElem == APP_NEXT_COLOR_BTN)
        {
            string sBtnId = JsonGetString(NuiGetBind(oPC, nToken, NUI_DATA_ENCOURAGED));
            int nColor = StringToInt(StringReplace(sBtnId, APP_BTN, ""));
            nColor++;

            AppHelmetColorEvents(oPC, oPCopy, nToken, nColor);
        }
        else if(sEventElem == APP_ITEM_PREVIOUS_BTN)
        {
            int nModelId = AppComboValidate(oPC, nToken, APP_ITEM_ENTRIES, APP_ITEM_ID, -1);
            FeedAppHelmetModel(oPC, oPCopy, nToken, nModelId);
        }
        else if(sEventElem == APP_ITEM_NEXT_BTN)
        {
            int nModelId = AppComboValidate(oPC, nToken, APP_ITEM_ENTRIES, APP_ITEM_ID, 1);
            FeedAppHelmetModel(oPC, oPCopy, nToken, nModelId);
        }
        else if(FindSubString(sEventElem, APP_ITEM_MODEL) >= 0)
        {
            int nModelId = StringToInt(StringReplace(sEventElem, APP_ITEM_MODEL, ""));
            FeedAppHelmetModel(oPC, oPCopy, nToken, nModelId);
        }
        else if(sEventElem == APP_CONFIRM_BTN)
        {
            RemoveAntyExploitStatus(oPC);
            AppHelmetCopy(oPCopy, oPC);
            DelayCommand(0.2, SetAntyExploitStatus(oPC));

            AppDestroyActiveWindow(oPC);

            int nTokenPanel = NuiFindWindow(oPC, APP_RIGHT_PANEL_WINDOW);
            AppRightPanelOffEncouraged(oPC, nTokenPanel);
        }
        else if(sEventElem == APP_CANCEL_BTN)
        {
            RemoveAntyExploitStatus(oPC);
            AppHelmetCopy(oPC, oPCopy);
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

            AppHelmetColorEvents(oPC, oPCopy, nToken, nColor);
        }
        else if(sEventElem == APP_ITEM_ID)
        {
            int nModelId = AppComboValidate(oPC, nToken, APP_ITEM_ENTRIES, APP_ITEM_ID, 0);
            FeedAppHelmetModel(oPC, oPCopy, nToken, nModelId);
        }
    }
}

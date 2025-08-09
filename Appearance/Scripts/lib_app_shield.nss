#include "x3_inc_string"
#include "lib_app"

const string APP_SHIELD_NUI_SCRIPT = "lib_app_shield_e";

void FeedAppShieldModel(
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

    object oShield = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oPCopy);
    CreateNewItem(oPCopy, oShield, INVENTORY_SLOT_LEFTHAND, ITEM_APPR_TYPE_SIMPLE_MODEL, 0, nModelIndex);

    NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, TRUE);
}

void FeedAppShieldWindow(
    object oPC,
    int nToken,
    struct ModelInfo ModelInfo)
{
    object oShield = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oPC);

    NuiSetBind(oPC, nToken, APP_ITEM_ENTRIES, ModelInfo.jModels);

    int nId = ModelInfo.nAppId - 1;

    NuiSetBind(oPC, nToken, APP_ITEM_ID, JsonInt(nId));
    NuiSetBind(oPC, nToken, APP_ITEM_MODEL_ENCOURAGED, JsonInt(nId));
    NuiSetBind(oPC, nToken, APP_ITEM_MODEL_ENCOURAGED + IntToString(nId), JsonBool(TRUE));

    NuiSetBind(oPC, nToken, APP_ITEM_MODELS_ID, ModelInfo.jModelIds);
}

void CreateAppShieldWindow(object oPC)
{
    struct ModelInfo ModelInfo = 
        GetModelInfo(
            GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oPC), 
            RESTYPE_TGA);

    json jSpacer = NuiSpacer();

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, CreateAppColorTemplateTopSpacer(60.0));
    jCol = JsonArrayInsert(jCol, CreateAppColorTemplateLabelName("Shield"));
    jCol = JsonArrayInsert(jCol, CreateAppItemPrviews(ModelInfo));
    jCol = JsonArrayInsert(jCol, CreateAppItemPicker());
    jCol = JsonArrayInsert(jCol, NuiHeight(jSpacer, 10.0));
    jCol = JsonArrayInsert(jCol, CreateAppColorTemplateButtonPanel());
    jCol = JsonArrayInsert(jCol, jSpacer);

    json jImageList = JsonArray();
    json jImage = NuiDrawListImage(
        JsonBool(TRUE),
        JsonString("cc"),
        NuiRect(
            0.0,
            15.0,
            APP_BACKGROUND_IMAGE_WIDTH,
            500.0),
        JsonInt(NUI_ASPECT_STRETCH),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_TOP),
        NUI_DRAW_LIST_ITEM_ORDER_BEFORE,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

    jImageList = JsonArrayInsert(jImageList, jImage);

    json jRoot = NuiDrawList(NuiCol(jCol), JsonBool(FALSE), jImageList);

    json jNui = NuiWindow(
        jRoot,
        JsonNull(),
        NuiBind(WINDOW_GEOMETRY),
        NuiBind(WINDOW_RESIZABLE),
        JsonBool(FALSE),
        NuiBind(WINDOW_CLOSABLE),
        NuiBind(WINDOW_TRANSPARENT),
        NuiBind(WINDOW_BORDER));

    int nToken = NuiCreate(oPC, jNui, APP_SHIELD_WINDOW, APP_SHIELD_NUI_SCRIPT);

    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY, AppGetGeometryWindow(oPC));
    NuiSetBind(oPC, nToken, WINDOW_RESIZABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_CLOSABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_TRANSPARENT, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, WINDOW_BORDER, JsonBool(FALSE));

    AppSetActiveWindow(oPC, nToken);

    FeedAppShieldWindow(oPC, nToken, ModelInfo);
    NuiSetBindWatch(oPC, nToken, APP_COLOR_TE, TRUE);
    NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, TRUE);
}

void AppShieldCopy(
    object oSource, 
    object oTarget)
{
    object oShield = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oSource);
    CopyItemToSlot(oShield, oTarget, INVENTORY_SLOT_LEFTHAND);
}

void AppShieldEvents(
    string sEventType,
    string sEventElem,
    object oPC,
    int nToken)
{
    object oArea = GetArea(oPC);
    object oPCopy = GetLocalObject(oArea, APP_DRESSING_ROOM_COPY);

    if(sEventType == EVENT_TYPE_CLICK)
    {
        if(sEventElem == APP_ITEM_PREVIOUS_BTN)
        {
            int nModelId = AppComboValidate(oPC, nToken, APP_ITEM_ENTRIES, APP_ITEM_ID, -1);
            FeedAppShieldModel(oPC, oPCopy, nToken, nModelId);
        }
        else if(sEventElem == APP_ITEM_NEXT_BTN)
        {
            int nModelId = AppComboValidate(oPC, nToken, APP_ITEM_ENTRIES, APP_ITEM_ID, 1);
            FeedAppShieldModel(oPC, oPCopy, nToken, nModelId);
        }
        else if(FindSubString(sEventElem, APP_ITEM_MODEL) >= 0)
        {
            int nModelId = StringToInt(StringReplace(sEventElem, APP_ITEM_MODEL, ""));
            FeedAppShieldModel(oPC, oPCopy, nToken, nModelId);
        }
        else if(sEventElem == APP_CONFIRM_BTN)
        {
            RemoveAntyExploitStatus(oPC);
            AppShieldCopy(oPCopy, oPC);
            DelayCommand(0.2, SetAntyExploitStatus(oPC));

            AppDestroyActiveWindow(oPC);

            int nTokenPanel = NuiFindWindow(oPC, APP_RIGHT_PANEL_WINDOW);
            AppRightPanelOffEncouraged(oPC, nTokenPanel);
        }
        else if(sEventElem == APP_CANCEL_BTN)
        {
            RemoveAntyExploitStatus(oPC);
            AppShieldCopy(oPC, oPCopy);
            SetAntyExploitStatus(oPC);

            AppDestroyActiveWindow(oPC);

            int nTokenPanel = NuiFindWindow(oPC, APP_RIGHT_PANEL_WINDOW);
            AppRightPanelOffEncouraged(oPC, nTokenPanel);
        }  
    }
    else if(sEventType == EVENT_TYPE_WATCH)
    {
        if(sEventElem == APP_ITEM_ID)
        {
            int nModelId = AppComboValidate(oPC, nToken, APP_ITEM_ENTRIES, APP_ITEM_ID, 0);
            FeedAppShieldModel(oPC, oPCopy, nToken, nModelId);
        }
    }
}

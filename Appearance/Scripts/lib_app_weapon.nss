#include "x3_inc_string"
#include "lib_app"

const string APP_WEAPON_NUI_SCRIPT = "lib_app_weapon_e";

const string APP_WEAPON_ACTIVE_SLOT = "APP_WEAPON_ACTIVE_SLOT";

const string APP_WEAPON_RIGHT_HAND_BTN = "APP_WEAPON_RIGHT_HAND_BTN";
const string APP_WEAPON_RIGHT_HAND_BTN_ENCOURAGED = "APP_WEAPON_RIGHT_HAND_BTN_ENCOURAGED";
const string APP_WEAPON_RIGHT_HAND_BTN_ENABLED = "APP_WEAPON_RIGHT_HAND_BTN_ENABLED";

const string APP_WEAPON_LEFT_HAND_BTN = "APP_WEAPON_LEFT_HAND_BTN";
const string APP_WEAPON_LEFT_HAND_BTN_ENCOURAGED = "APP_WEAPON_LEFT_HAND_BTN_ENCOURAGED";
const string APP_WEAPON_LEFT_HAND_BTN_ENABLED = "APP_WEAPON_LEFT_HAND_BTN_ENABLED";

struct WeaponSlotInfo
{
    int nBaseType;
    int nWeaponType;
    string sItemClass;
    int nModelType;
};

struct WeaponInfo
{
    struct WeaponSlotInfo RightHand;
    struct WeaponSlotInfo LeftHand;
};

struct WeaponSlotInfo GetWeaponSlotInfo(object oPC, int nHand)
{
    struct WeaponSlotInfo WeaponSlotInfo;

    object oItem = GetItemInSlot(nHand, oPC);

    if(!GetIsObjectValid(oItem))
    {
        return WeaponSlotInfo;
    }

    int nBaseType = GetBaseItemType(oItem);

    WeaponSlotInfo.nBaseType = nBaseType;
    WeaponSlotInfo.nWeaponType =
        StringToInt(Get2DAString("baseitems", APP_ITEM_WEAPON_TYPE, nBaseType));
    WeaponSlotInfo.sItemClass =
        Get2DAString("baseitems", APP_ITEM_ITEM_CLASS, nBaseType);
    WeaponSlotInfo.nModelType =
        StringToInt(Get2DAString("baseitems", APP_ITEM_MODEL_TYPE, nBaseType));

    return WeaponSlotInfo;
}

struct WeaponInfo GetWeaponInfo(object oPC)
{
    struct WeaponInfo WeaponInfo;

    WeaponInfo.RightHand = GetWeaponSlotInfo(oPC, INVENTORY_SLOT_RIGHTHAND);
    WeaponInfo.LeftHand = GetWeaponSlotInfo(oPC, INVENTORY_SLOT_LEFTHAND);

    return WeaponInfo;
}

json CreateAppWeaponButtons()
{
    json jSpacer = NuiSpacer();

    json jRow = JsonArray();
    json jButtonRight = NuiId(NuiButtonImage(JsonString("app_hand_right")), APP_WEAPON_RIGHT_HAND_BTN);
    jButtonRight = NuiEnabled(jButtonRight, NuiBind(APP_WEAPON_RIGHT_HAND_BTN_ENABLED));
    jButtonRight = NuiEncouraged(jButtonRight, NuiBind(APP_WEAPON_RIGHT_HAND_BTN_ENCOURAGED));
    jButtonRight = NuiTooltip(jButtonRight, JsonString("Right hand"));
    jButtonRight = NuiWidth(jButtonRight, 60.0);
    jButtonRight = NuiHeight(jButtonRight, 60.0);

    json jButtonLeft = NuiId(NuiButtonImage(JsonString("app_hand_left")), APP_WEAPON_LEFT_HAND_BTN);
    jButtonLeft = NuiEnabled(jButtonLeft, NuiBind(APP_WEAPON_LEFT_HAND_BTN_ENABLED));
    jButtonLeft = NuiEncouraged(jButtonLeft, NuiBind(APP_WEAPON_LEFT_HAND_BTN_ENCOURAGED));
    jButtonLeft = NuiTooltip(jButtonLeft, JsonString("Left hand"));
    jButtonLeft = NuiWidth(jButtonLeft, 60.0);
    jButtonLeft = NuiHeight(jButtonLeft, 60.0);

    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jButtonRight);
    jRow = JsonArrayInsert(jRow, jButtonLeft);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

void FeedWeapon1PartModel(
    object oPC,
    object oPCopy,
    int nToken,
    int nModelId)
{
    int nSlot = JsonGetInt(NuiGetBind(oPC, nToken, APP_WEAPON_ACTIVE_SLOT));

    NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, FALSE);

    EncourageItemModel(oPC, nToken, nModelId);

    NuiSetBind(oPC, nToken, APP_ITEM_ID, JsonInt(nModelId));

    json jModelIds = NuiGetBind(oPC, nToken, APP_ITEM_MODELS_ID);

    int nModelIndex = JsonGetInt(JsonArrayGet(jModelIds, nModelId));

    object oWeapon = GetItemInSlot(nSlot, oPCopy);
    CreateNewItem(oPCopy, oWeapon, nSlot, ITEM_APPR_TYPE_SIMPLE_MODEL, 0, nModelIndex);

    NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, TRUE);
}

void AppWeaponSwapLayout(
    object oPC,
    object oPCopy,
    int nToken,
    int nSlot)
{
    object oWeapon = GetItemInSlot(nSlot, oPCopy);

    int nBaseType = GetBaseItemType(oWeapon);
    int nModelType = StringToInt(Get2DAString("baseitems", APP_ITEM_MODEL_TYPE, nBaseType));

    switch(nModelType)
    {
        case 0:
            {
                OffWatch3PartModels(oPC, nToken);
                NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, FALSE);

                struct ModelInfo ModelInfo = GetModelInfo(oWeapon, RESTYPE_TGA);

                NuiSetGroupLayout(oPC, nToken, APP_ITEM_SWAP_LAYOUT,
                    CreateAppItem1PartModel(ModelInfo));

                FeedItem1Part(oPC, nToken, oWeapon, ModelInfo);

                NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, TRUE);
            }
            break;
        case 2:
            {
                OffWatch3PartModels(oPC, nToken);
                NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, FALSE);

                NuiSetGroupLayout(oPC, nToken, APP_ITEM_SWAP_LAYOUT, CreateAppItem3PartModels());
                FeedItem3PartModels(oPC, oWeapon, nToken, nBaseType);
                OnWatch3PartModels(oPC, nToken);
            }
            break;
    }

    if(nSlot == INVENTORY_SLOT_RIGHTHAND)
    {
        NuiSetBind(oPC, nToken, APP_WEAPON_RIGHT_HAND_BTN_ENCOURAGED, JsonBool(TRUE));
        NuiSetBind(oPC, nToken, APP_WEAPON_LEFT_HAND_BTN_ENCOURAGED, JsonBool(FALSE));
    }
    else if(nSlot == INVENTORY_SLOT_LEFTHAND)
    {
        NuiSetBind(oPC, nToken, APP_WEAPON_RIGHT_HAND_BTN_ENCOURAGED, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, APP_WEAPON_LEFT_HAND_BTN_ENCOURAGED, JsonBool(TRUE));
    }

    NuiSetBind(oPC, nToken, APP_WEAPON_ACTIVE_SLOT, JsonInt(nSlot));
}

void GetAndFeed3PartModels(
    object oPC,
    object oPCopy,
    int nToken,
    int nSlot)
{
    object oWeapon = GetItemInSlot(nSlot, oPCopy);

    int nBaseType = GetBaseItemType(oWeapon);
    int nModelType = StringToInt(Get2DAString("baseitems", APP_ITEM_MODEL_TYPE, nBaseType));

    FeedItem3PartModels(oPC, oWeapon, nToken, nBaseType);
}

void CreateAppWeaponWindow(object oPC)
{
    struct WeaponInfo WeaponInfo = GetWeaponInfo(oPC);
    json jSpacer = NuiSpacer();

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, CreateAppColorTemplateTopSpacer(60.0));
    jCol = JsonArrayInsert(jCol, CreateAppColorTemplateLabelName("Weapon"));
    jCol = JsonArrayInsert(jCol, CreateAppWeaponButtons());
    jCol = JsonArrayInsert(jCol, CreateAppItemSwapLayout());
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
            610.0),
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

    int nToken = NuiCreate(oPC, jNui, APP_WEAPON_WINDOW, APP_WEAPON_NUI_SCRIPT);

    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY, AppGetGeometryWindow(oPC));
    NuiSetBind(oPC, nToken, WINDOW_RESIZABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_CLOSABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_TRANSPARENT, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, WINDOW_BORDER, JsonBool(FALSE));

    AppSetActiveWindow(oPC, nToken);

    NuiSetBind(oPC, nToken, APP_WEAPON_RIGHT_HAND_BTN_ENABLED, JsonBool(WeaponInfo.RightHand.nWeaponType > 0));
    NuiSetBind(oPC, nToken, APP_WEAPON_LEFT_HAND_BTN_ENABLED, JsonBool(WeaponInfo.LeftHand.nWeaponType > 0));
}

void AppWeapon3PartModelsEvents(
    object oPC,
    object oPCopy,
    int nToken,
    string sEntries,
    string sId,
    int nStep,
    int nType,
    int nIndex)
{
    int nSlot = JsonGetInt(NuiGetBind(oPC, nToken, APP_WEAPON_ACTIVE_SLOT));
    int nModel = AppComboValidate(oPC, nToken, sEntries, sId, nStep);

    object oWeapon = GetItemInSlot(nSlot, oPCopy);
    CreateNewItem(oPCopy, oWeapon,
        nSlot, nType, nIndex, nModel);

    //Need gives time to create new item
    DelayCommand(0.1, GetAndFeed3PartModels(oPC, oPCopy, nToken, nSlot));
}

void AppWeapon3PartModelsWatchEvents(
    object oPC,
    object oPCopy,
    int nToken,
    int nModel,
    int nType,
    int nIndex)
{
    int nSlot = JsonGetInt(NuiGetBind(oPC, nToken, APP_WEAPON_ACTIVE_SLOT));

    object oWeapon = GetItemInSlot(nSlot, oPCopy);
    CreateNewItem(oPCopy, oWeapon,
        nSlot, nType, nIndex, nModel);

    //Need gives time to create new item
    DelayCommand(0.1, GetAndFeed3PartModels(oPC, oPCopy, nToken, nSlot));
}

void AppWeaponCopy(
    object oSource, 
    object oTarget)
{
    object oWeapon = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oSource);
    CopyItemToSlot(oWeapon, oTarget, INVENTORY_SLOT_RIGHTHAND);

    oWeapon = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oSource);
    if(GetIsObjectValid(oWeapon))
    {
        CopyItemToSlot(oWeapon, oTarget, INVENTORY_SLOT_LEFTHAND);
    }
}

void AppWeaponEvents(
    string sEventType,
    string sEventElem,
    object oPC,
    int nToken)
{
    object oArea = GetArea(oPC);
    object oPCopy = GetLocalObject(oArea, APP_DRESSING_ROOM_COPY);

    if(sEventType == EVENT_TYPE_CLICK)
    {
        if(sEventElem == APP_WEAPON_RIGHT_HAND_BTN)
        {
            DelayCommand(0.1, AppWeaponSwapLayout(oPC, oPCopy, nToken, INVENTORY_SLOT_RIGHTHAND));
        }
        else if(sEventElem == APP_WEAPON_LEFT_HAND_BTN)
        {
            DelayCommand(0.1, AppWeaponSwapLayout(oPC, oPCopy, nToken, INVENTORY_SLOT_LEFTHAND));
        }
        //Top
        else if(sEventElem == APP_ITEM_TOP_PREVIOUS_MODEL_BTN)
        {
            AppWeapon3PartModelsEvents(
                oPC,
                oPCopy,
                nToken,
                APP_ITEM_TOP_ENTRIES,
                APP_ITEM_TOP_ID,
                -1,
                ITEM_APPR_TYPE_WEAPON_MODEL,
                ITEM_APPR_WEAPON_MODEL_TOP);
        }
        else if(sEventElem == APP_ITEM_TOP_NEXT_MODEL_BTN)
        {
            AppWeapon3PartModelsEvents(
                oPC,
                oPCopy,
                nToken,
                APP_ITEM_TOP_ENTRIES,
                APP_ITEM_TOP_ID,
                1,
                ITEM_APPR_TYPE_WEAPON_MODEL,
                ITEM_APPR_WEAPON_MODEL_TOP);
        }
        else if(sEventElem == APP_ITEM_TOP_PREVIOUS_COLOR_BTN)
        {
            AppWeapon3PartModelsEvents(
                oPC,
                oPCopy,
                nToken,
                APP_ITEM_TOP_COLOR_ENTRIES,
                APP_ITEM_TOP_COLOR_ID,
                -1,
                ITEM_APPR_TYPE_WEAPON_COLOR,
                ITEM_APPR_WEAPON_COLOR_TOP);
        }
        else if(sEventElem == APP_ITEM_TOP_NEXT_COLOR_BTN)
        {
            AppWeapon3PartModelsEvents(
                oPC,
                oPCopy,
                nToken,
                APP_ITEM_TOP_COLOR_ENTRIES,
                APP_ITEM_TOP_COLOR_ID,
                1,
                ITEM_APPR_TYPE_WEAPON_COLOR,
                ITEM_APPR_WEAPON_COLOR_TOP);
        }
        //Mid
        else if(sEventElem == APP_ITEM_MID_PREVIOUS_MODEL_BTN)
        {
            AppWeapon3PartModelsEvents(
                oPC,
                oPCopy,
                nToken,
                APP_ITEM_MID_ENTRIES,
                APP_ITEM_MID_ID,
                -1,
                ITEM_APPR_TYPE_WEAPON_MODEL,
                ITEM_APPR_WEAPON_MODEL_MIDDLE);
        }
        else if(sEventElem == APP_ITEM_MID_NEXT_MODEL_BTN)
        {
            AppWeapon3PartModelsEvents(
                oPC,
                oPCopy,
                nToken,
                APP_ITEM_MID_ENTRIES,
                APP_ITEM_MID_ID,
                1,
                ITEM_APPR_TYPE_WEAPON_MODEL,
                ITEM_APPR_WEAPON_MODEL_MIDDLE);
        }
        else if(sEventElem == APP_ITEM_MID_PREVIOUS_COLOR_BTN)
        {
            AppWeapon3PartModelsEvents(
                oPC,
                oPCopy,
                nToken,
                APP_ITEM_MID_COLOR_ENTRIES,
                APP_ITEM_MID_COLOR_ID,
                -1,
                ITEM_APPR_TYPE_WEAPON_COLOR,
                ITEM_APPR_WEAPON_COLOR_MIDDLE);
        }
        else if(sEventElem == APP_ITEM_MID_NEXT_COLOR_BTN)
        {
            AppWeapon3PartModelsEvents(
                oPC,
                oPCopy,
                nToken,
                APP_ITEM_MID_COLOR_ENTRIES,
                APP_ITEM_MID_COLOR_ID,
                1,
                ITEM_APPR_TYPE_WEAPON_COLOR,
                ITEM_APPR_WEAPON_COLOR_MIDDLE);
        }
        //Bottom
        else if(sEventElem == APP_ITEM_BOTTOM_PREVIOUS_MODEL_BTN)
        {
            AppWeapon3PartModelsEvents(
                oPC,
                oPCopy,
                nToken,
                APP_ITEM_BOTTOM_ENTRIES,
                APP_ITEM_BOTTOM_ID,
                -1,
                ITEM_APPR_TYPE_WEAPON_MODEL,
                ITEM_APPR_WEAPON_MODEL_BOTTOM);
        }
        else if(sEventElem == APP_ITEM_BOTTOM_NEXT_MODEL_BTN)
        {
            AppWeapon3PartModelsEvents(
                oPC,
                oPCopy,
                nToken,
                APP_ITEM_BOTTOM_ENTRIES,
                APP_ITEM_BOTTOM_ID,
                1,
                ITEM_APPR_TYPE_WEAPON_MODEL,
                ITEM_APPR_WEAPON_MODEL_BOTTOM);
        }
        else if(sEventElem == APP_ITEM_BOTTOM_PREVIOUS_COLOR_BTN)
        {
            AppWeapon3PartModelsEvents(
                oPC,
                oPCopy,
                nToken,
                APP_ITEM_BOTTOM_COLOR_ENTRIES,
                APP_ITEM_BOTTOM_COLOR_ID,
                -1,
                ITEM_APPR_TYPE_WEAPON_COLOR,
                ITEM_APPR_WEAPON_COLOR_BOTTOM);
        }
        else if(sEventElem == APP_ITEM_BOTTOM_NEXT_COLOR_BTN)
        {
            AppWeapon3PartModelsEvents(
                oPC,
                oPCopy,
                nToken,
                APP_ITEM_BOTTOM_COLOR_ENTRIES,
                APP_ITEM_BOTTOM_COLOR_ID,
                1,
                ITEM_APPR_TYPE_WEAPON_COLOR,
                ITEM_APPR_WEAPON_COLOR_BOTTOM);
        }
        else if(sEventElem == APP_ITEM_PREVIOUS_BTN)
        {
            int nModelId = AppComboValidate(oPC, nToken, APP_ITEM_ENTRIES, APP_ITEM_ID, -1);
            FeedWeapon1PartModel(oPC, oPCopy, nToken, nModelId);
        }
        else if(sEventElem == APP_ITEM_NEXT_BTN)
        {
            int nModelId = AppComboValidate(oPC, nToken, APP_ITEM_ENTRIES, APP_ITEM_ID, 1);
            FeedWeapon1PartModel(oPC, oPCopy, nToken, nModelId);
        }
        else if(FindSubString(sEventElem, APP_ITEM_MODEL) >= 0)
        {
            int nModelId = StringToInt(StringReplace(sEventElem, APP_ITEM_MODEL, ""));
            FeedWeapon1PartModel(oPC, oPCopy, nToken, nModelId);
        }
        else if(sEventElem == APP_CONFIRM_BTN)
        {
            RemoveAntyExploitStatus(oPC);
            AppWeaponCopy(oPCopy, oPC);
            DelayCommand(0.2, SetAntyExploitStatus(oPC));

            AppDestroyActiveWindow(oPC);

            int nTokenPanel = NuiFindWindow(oPC, APP_RIGHT_PANEL_WINDOW);
            AppRightPanelOffEncouraged(oPC, nTokenPanel);
        }
        else if(sEventElem == APP_CANCEL_BTN)
        {
            RemoveAntyExploitStatus(oPC);
            AppWeaponCopy(oPC, oPCopy);
            SetAntyExploitStatus(oPC);

            AppDestroyActiveWindow(oPC);

            int nTokenPanel = NuiFindWindow(oPC, APP_RIGHT_PANEL_WINDOW);
            AppRightPanelOffEncouraged(oPC, nTokenPanel);
        }        
    }
    else if(sEventType == EVENT_TYPE_WATCH)
    {
        if(sEventElem == APP_ITEM_TOP_ID)
        {
            int nModelId =
                AppComboValidate(oPC, nToken, APP_ITEM_TOP_ENTRIES, APP_ITEM_TOP_ID, 0);

            AppWeapon3PartModelsWatchEvents(
                oPC,
                oPCopy,
                nToken,
                nModelId,
                ITEM_APPR_TYPE_WEAPON_MODEL,
                ITEM_APPR_WEAPON_MODEL_TOP);
        }
        else if(sEventElem == APP_ITEM_TOP_COLOR_ID)
        {
            int nModelId =
                AppComboValidate(oPC, nToken, APP_ITEM_TOP_COLOR_ENTRIES, APP_ITEM_TOP_COLOR_ID, 0);

            AppWeapon3PartModelsWatchEvents(
                oPC,
                oPCopy,
                nToken,
                nModelId,
                ITEM_APPR_TYPE_WEAPON_COLOR,
                ITEM_APPR_WEAPON_COLOR_TOP);
        }
        else if(sEventElem == APP_ITEM_MID_ID)
        {
            int nModelId =
                AppComboValidate(oPC, nToken, APP_ITEM_MID_ENTRIES, APP_ITEM_MID_ID, 0);

            AppWeapon3PartModelsWatchEvents(
                oPC,
                oPCopy,
                nToken,
                nModelId,
                ITEM_APPR_TYPE_WEAPON_MODEL,
                ITEM_APPR_WEAPON_MODEL_MIDDLE);
        }
        else if(sEventElem == APP_ITEM_MID_COLOR_ID)
        {
            int nModelId =
                AppComboValidate(oPC, nToken, APP_ITEM_MID_COLOR_ENTRIES, APP_ITEM_MID_COLOR_ID, 0);

            AppWeapon3PartModelsWatchEvents(
                oPC,
                oPCopy,
                nToken,
                nModelId,
                ITEM_APPR_TYPE_WEAPON_COLOR,
                ITEM_APPR_WEAPON_COLOR_MIDDLE);
        }
        else if(sEventElem == APP_ITEM_BOTTOM_ID)
        {
            int nModelId =
                AppComboValidate(oPC, nToken, APP_ITEM_BOTTOM_ENTRIES, APP_ITEM_BOTTOM_ID, 0);

            AppWeapon3PartModelsWatchEvents(
                oPC,
                oPCopy,
                nToken,
                nModelId,
                ITEM_APPR_TYPE_WEAPON_MODEL,
                ITEM_APPR_WEAPON_MODEL_BOTTOM);
        }
        else if(sEventElem == APP_ITEM_BOTTOM_COLOR_ID)
        {
            int nModelId =
                AppComboValidate(oPC, nToken, APP_ITEM_BOTTOM_COLOR_ENTRIES, APP_ITEM_BOTTOM_COLOR_ID, 0);

            AppWeapon3PartModelsWatchEvents(
                oPC,
                oPCopy,
                nToken,
                nModelId,
                ITEM_APPR_TYPE_WEAPON_COLOR,
                ITEM_APPR_WEAPON_COLOR_BOTTOM);
        }
        else if(sEventElem == APP_ITEM_ID)
        {
            int nModelId = AppComboValidate(oPC, nToken, APP_ITEM_ENTRIES, APP_ITEM_ID, 0);
            FeedWeapon1PartModel(oPC, oPCopy, nToken, nModelId);
        }
    }
    else if(sEventType == EVENT_TYPE_OPEN)
    {
        AppWeaponSwapLayout(oPC, oPCopy, nToken, INVENTORY_SLOT_RIGHTHAND);
    }
}

#include "x3_inc_string"
#include "lib_app"

const string APP_MISC_NUI_SCRIPT = "lib_app_misc_ev";

const string APP_MISC_ITEM_UUID = "APP_MISC_ITEM_UUID";

const string APP_ITEM_NAME = "APP_ITEM_NAME";
const string APP_ITEM_NAME_SAVE_BTN = "APP_ITEM_NAME_SAVE_BTN";

const string APP_MISC_PICKED = "APP_MISC_PICKED";
const string APP_MISC_PICK_BTN = "APP_MISC_PICK_BTN";

void AppMiscSwapLayout(
    object oPC,
    object oItem,
    int nToken,
    string sItemUUID)
{
    int nBaseType = GetBaseItemType(oItem);
    int nModelType = StringToInt(Get2DAString("baseitems", APP_ITEM_MODEL_TYPE, nBaseType));

    switch(nModelType)
    {
        case 0:
            {
                OffWatch3PartModels(oPC, nToken);
                NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, FALSE);

                struct ModelInfo ModelInfo = GetModelInfo(oItem, RESTYPE_TGA);

                NuiSetGroupLayout(oPC, nToken, APP_ITEM_SWAP_LAYOUT,
                   CreateAppItem1PartModel(ModelInfo));

                FeedItem1Part(oPC, nToken, oItem, ModelInfo);

                NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, TRUE);
            }
            break;
        case 2:
            {
                OffWatch3PartModels(oPC, nToken);
                NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, FALSE);

                NuiSetGroupLayout(oPC, nToken, APP_ITEM_SWAP_LAYOUT, CreateAppItem3PartModels());
                FeedItem3PartModels(oPC, oItem, nToken, nBaseType, "i", RESTYPE_TGA);
                OnWatch3PartModels(oPC, nToken);
            }
            break;
    }

    NuiSetBind(oPC, nToken, APP_MISC_ITEM_UUID, JsonString(sItemUUID));
}

json CreateAppItemName()
{
    json jSpacer = NuiSpacer();

    json jTextEdit = NuiTextEdit(
        JsonString(""),
        NuiBind(APP_ITEM_NAME),
        100,
        FALSE);
    jTextEdit = NuiWidth(jTextEdit, 200.0);
    jTextEdit = NuiHeight(jTextEdit, APP_BOTTOM_BTN_HEIGHT);
    jTextEdit = NuiEnabled(jTextEdit, NuiBind(APP_MISC_PICKED));

    json jButtonSave =
        NuiId(NuiButtonImage(JsonString("app_save")), APP_ITEM_NAME_SAVE_BTN);
    jButtonSave = NuiWidth(jButtonSave, APP_BOTTOM_BTN_WIDTH);
    jButtonSave = NuiHeight(jButtonSave, APP_BOTTOM_BTN_HEIGHT);
    jButtonSave = NuiEnabled(jButtonSave, NuiBind(APP_MISC_PICKED));

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jTextEdit);
    jRow = JsonArrayInsert(jRow, jButtonSave);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

json CreateAppMiscButton()
{
    json jSpacer = NuiSpacer();

    json jButtonPick = NuiButtonImage(JsonString("custom_pick_nui"));
    jButtonPick = NuiId(jButtonPick, APP_MISC_PICK_BTN);
    jButtonPick = NuiWidth(jButtonPick, APP_BOTTOM_BTN_WIDTH);
    jButtonPick = NuiHeight(jButtonPick, APP_BOTTOM_BTN_HEIGHT);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jButtonPick);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

void CreateAppMiscWindow(object oPC)
{
    json jSpacer = NuiSpacer();

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, CreateAppColorTemplateTopSpacer(60.0));
    jCol = JsonArrayInsert(jCol, CreateAppColorTemplateLabelName("Misc"));
    jCol = JsonArrayInsert(jCol, CreateAppItemName());
    jCol = JsonArrayInsert(jCol, CreateAppItemSwapLayout());
    jCol = JsonArrayInsert(jCol, NuiHeight(jSpacer, 10.0));
    jCol = JsonArrayInsert(jCol, CreateAppMiscButton());
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

    int nToken = NuiCreate(oPC, jNui, APP_MISC_WINDOW, APP_MISC_NUI_SCRIPT);

    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY, AppGetGeometryWindow(oPC));
    NuiSetBind(oPC, nToken, WINDOW_RESIZABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_CLOSABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_TRANSPARENT, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, WINDOW_BORDER, JsonBool(FALSE));

    AppSetActiveWindow(oPC, nToken);
}

void GetAndFeedMisc3PartModels(
    object oPC,
    int nToken,
    object oItem)
{
    int nBaseType = GetBaseItemType(oItem);
    int nModelType = StringToInt(Get2DAString("baseitems", APP_ITEM_MODEL_TYPE, nBaseType));

    FeedItem3PartModels(oPC, oItem, nToken, nBaseType, "i", RESTYPE_TGA);

    NuiSetBind(oPC, nToken, APP_MISC_ITEM_UUID, JsonString(GetObjectUUID(oItem)));
}

void AppMisc3PartModelsEvents(
    object oPC,
    int nToken,
    string sEntries,
    string sId,
    int nStep,
    int nType,
    int nIndex)
{
    string sItemUUID = JsonGetString(NuiGetBind(oPC, nToken, APP_MISC_ITEM_UUID));
    object oItem = GetObjectByUUID(sItemUUID);

    int nModel = AppComboValidate(oPC, nToken, sEntries, sId, nStep);

    object oNewItem = CopyItemAndModify(oItem, nType, nIndex, nModel);

    if(GetIsObjectValid(oNewItem))
    {
        DestroyObject(oItem);
    }
    else
    {
        SendMessageToPC(oPC, "You can't select this model.");
        oNewItem = oItem;
    }

    //Need gives time to create new item
    DelayCommand(0.1, GetAndFeedMisc3PartModels(oPC, nToken, oNewItem));
}

void AppMisc3PartModelsWatchEvents(
    object oPC,
    int nToken,
    int nModel,
    int nType,
    int nIndex)
{
    string sItemUUID = JsonGetString(NuiGetBind(oPC, nToken, APP_MISC_ITEM_UUID));
    object oItem = GetObjectByUUID(sItemUUID);

    object oNewItem = CopyItemAndModify(oItem, nType, nIndex, nModel);

    if(GetIsObjectValid(oNewItem))
    {
        DestroyObject(oItem);
    }
    else
    {
        SendMessageToPC(oPC, "You can't select this model.");
        oNewItem = oItem;
    }

    //Need gives time to create new item
    DelayCommand(0.1, GetAndFeedMisc3PartModels(oPC, nToken, oNewItem));
}

void AppMisc1PartModelEvents(
    object oPC,
    int nToken,
    int nModelId)
{
    NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, FALSE);

    EncourageItemModel(oPC, nToken, nModelId);

    NuiSetBind(oPC, nToken, APP_ITEM_ID, JsonInt(nModelId));

    json jModelIds = NuiGetBind(oPC, nToken, APP_ITEM_MODELS_ID);

    int nModelIndex = JsonGetInt(JsonArrayGet(jModelIds, nModelId));

    string sItemUUID = JsonGetString(NuiGetBind(oPC, nToken, APP_MISC_ITEM_UUID));
    object oItem = GetObjectByUUID(sItemUUID);

    int nAppearance = GetItemAppearance(oItem, ITEM_APPR_TYPE_SIMPLE_MODEL, -1);
    if(nAppearance == nModelIndex)
    {
        return;
    }

    object oNewItem = CopyItemAndModify(oItem, ITEM_APPR_TYPE_SIMPLE_MODEL, 0, nModelIndex);

    if(GetIsObjectValid(oNewItem))
    {
        NuiSetBind(oPC, nToken, APP_MISC_ITEM_UUID, JsonString(GetObjectUUID(oNewItem)));
        DestroyObject(oItem);
    }
    else
    {
        SendMessageToPC(oPC, "You can't select this model.");
        oNewItem = oItem;
    }

    NuiSetBindWatch(oPC, nToken, APP_ITEM_ID, TRUE);
}

void AppMiscEvents(
    string sEventType,
    string sEventElem,
    object oPC,
    int nToken)
{
    if(sEventType == EVENT_TYPE_CLICK)
    {
        if(sEventElem == APP_MISC_PICK_BTN)
        {
            EnterTargetingMode(oPC, OBJECT_TYPE_ITEM);
        }
        //Top
        else if(sEventElem == APP_ITEM_TOP_PREVIOUS_MODEL_BTN)
        {
            AppMisc3PartModelsEvents(
                oPC,
                nToken,
                APP_ITEM_TOP_ENTRIES,
                APP_ITEM_TOP_ID,
                -1,
                ITEM_APPR_TYPE_WEAPON_MODEL,
                ITEM_APPR_WEAPON_MODEL_TOP);
        }
        else if(sEventElem == APP_ITEM_TOP_NEXT_MODEL_BTN)
        {
            AppMisc3PartModelsEvents(
                oPC,
                nToken,
                APP_ITEM_TOP_ENTRIES,
                APP_ITEM_TOP_ID,
                1,
                ITEM_APPR_TYPE_WEAPON_MODEL,
                ITEM_APPR_WEAPON_MODEL_TOP);
        }
        else if(sEventElem == APP_ITEM_TOP_PREVIOUS_COLOR_BTN)
        {
            AppMisc3PartModelsEvents(
                oPC,
                nToken,
                APP_ITEM_TOP_COLOR_ENTRIES,
                APP_ITEM_TOP_COLOR_ID,
                -1,
                ITEM_APPR_TYPE_WEAPON_COLOR,
                ITEM_APPR_WEAPON_COLOR_TOP);
        }
        else if(sEventElem == APP_ITEM_TOP_NEXT_COLOR_BTN)
        {
            AppMisc3PartModelsEvents(
                oPC,
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
            AppMisc3PartModelsEvents(
                oPC,
                nToken,
                APP_ITEM_MID_ENTRIES,
                APP_ITEM_MID_ID,
                -1,
                ITEM_APPR_TYPE_WEAPON_MODEL,
                ITEM_APPR_WEAPON_MODEL_MIDDLE);
        }
        else if(sEventElem == APP_ITEM_MID_NEXT_MODEL_BTN)
        {
            AppMisc3PartModelsEvents(
                oPC,
                nToken,
                APP_ITEM_MID_ENTRIES,
                APP_ITEM_MID_ID,
                1,
                ITEM_APPR_TYPE_WEAPON_MODEL,
                ITEM_APPR_WEAPON_MODEL_MIDDLE);
        }
        else if(sEventElem == APP_ITEM_MID_PREVIOUS_COLOR_BTN)
        {
            AppMisc3PartModelsEvents(
                oPC,
                nToken,
                APP_ITEM_MID_COLOR_ENTRIES,
                APP_ITEM_MID_COLOR_ID,
                -1,
                ITEM_APPR_TYPE_WEAPON_COLOR,
                ITEM_APPR_WEAPON_COLOR_MIDDLE);
        }
        else if(sEventElem == APP_ITEM_MID_NEXT_COLOR_BTN)
        {
            AppMisc3PartModelsEvents(
                oPC,
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
            AppMisc3PartModelsEvents(
                oPC,
                nToken,
                APP_ITEM_BOTTOM_ENTRIES,
                APP_ITEM_BOTTOM_ID,
                -1,
                ITEM_APPR_TYPE_WEAPON_MODEL,
                ITEM_APPR_WEAPON_MODEL_BOTTOM);
        }
        else if(sEventElem == APP_ITEM_BOTTOM_NEXT_MODEL_BTN)
        {
            AppMisc3PartModelsEvents(
                oPC,
                nToken,
                APP_ITEM_BOTTOM_ENTRIES,
                APP_ITEM_BOTTOM_ID,
                1,
                ITEM_APPR_TYPE_WEAPON_MODEL,
                ITEM_APPR_WEAPON_MODEL_BOTTOM);
        }
        else if(sEventElem == APP_ITEM_BOTTOM_PREVIOUS_COLOR_BTN)
        {
            AppMisc3PartModelsEvents(
                oPC,
                nToken,
                APP_ITEM_BOTTOM_COLOR_ENTRIES,
                APP_ITEM_BOTTOM_COLOR_ID,
                -1,
                ITEM_APPR_TYPE_WEAPON_COLOR,
                ITEM_APPR_WEAPON_COLOR_BOTTOM);
        }
        else if(sEventElem == APP_ITEM_BOTTOM_NEXT_COLOR_BTN)
        {
            AppMisc3PartModelsEvents(
                oPC,
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
            AppMisc1PartModelEvents(oPC, nToken, nModelId);
        }
        else if(sEventElem == APP_ITEM_NEXT_BTN)
        {
            int nModelId = AppComboValidate(oPC, nToken, APP_ITEM_ENTRIES, APP_ITEM_ID, 1);
            AppMisc1PartModelEvents(oPC, nToken, nModelId);
        }
        else if(FindSubString(sEventElem, APP_ITEM_MODEL) >= 0)
        {
            int nModelId = StringToInt(StringReplace(sEventElem, APP_ITEM_MODEL, ""));
            AppMisc1PartModelEvents(oPC, nToken, nModelId);
        }
        else if(sEventElem == APP_ITEM_NAME_SAVE_BTN)
        {
            string sItemUUID = JsonGetString(NuiGetBind(oPC, nToken, APP_MISC_ITEM_UUID));
            object oItem = GetObjectByUUID(sItemUUID);

            string sName = JsonGetString(NuiGetBind(oPC, nToken, APP_ITEM_NAME));

            SetName(oItem, sName);
        }
    }
    else if(sEventType == EVENT_TYPE_WATCH)
    {
        if(sEventElem == APP_ITEM_TOP_ID)
        {
            int nModelId =
                AppComboValidate(oPC, nToken, APP_ITEM_TOP_ENTRIES, APP_ITEM_TOP_ID, 0);

            AppMisc3PartModelsWatchEvents(
                oPC,
                nToken,
                nModelId,
                ITEM_APPR_TYPE_WEAPON_MODEL,
                ITEM_APPR_WEAPON_MODEL_TOP);
        }
        else if(sEventElem == APP_ITEM_TOP_COLOR_ID)
        {
            int nModelId =
                AppComboValidate(oPC, nToken, APP_ITEM_TOP_COLOR_ENTRIES, APP_ITEM_TOP_COLOR_ID, 0);

            AppMisc3PartModelsWatchEvents(
                oPC,
                nToken,
                nModelId,
                ITEM_APPR_TYPE_WEAPON_COLOR,
                ITEM_APPR_WEAPON_COLOR_TOP);
        }
        else if(sEventElem == APP_ITEM_MID_ID)
        {
            int nModelId =
                AppComboValidate(oPC, nToken, APP_ITEM_MID_ENTRIES, APP_ITEM_MID_ID, 0);

            AppMisc3PartModelsWatchEvents(
                oPC,
                nToken,
                nModelId,
                ITEM_APPR_TYPE_WEAPON_MODEL,
                ITEM_APPR_WEAPON_MODEL_MIDDLE);
        }
        else if(sEventElem == APP_ITEM_MID_COLOR_ID)
        {
            int nModelId =
                AppComboValidate(oPC, nToken, APP_ITEM_MID_COLOR_ENTRIES, APP_ITEM_MID_COLOR_ID, 0);

            AppMisc3PartModelsWatchEvents(
                oPC,
                nToken,
                nModelId,
                ITEM_APPR_TYPE_WEAPON_COLOR,
                ITEM_APPR_WEAPON_COLOR_MIDDLE);
        }
        else if(sEventElem == APP_ITEM_BOTTOM_ID)
        {
            int nModelId =
                AppComboValidate(oPC, nToken, APP_ITEM_BOTTOM_ENTRIES, APP_ITEM_BOTTOM_ID, 0);

            AppMisc3PartModelsWatchEvents(
                oPC,
                nToken,
                nModelId,
                ITEM_APPR_TYPE_WEAPON_MODEL,
                ITEM_APPR_WEAPON_MODEL_BOTTOM);
        }
        else if(sEventElem == APP_ITEM_BOTTOM_COLOR_ID)
        {
            int nModelId =
                AppComboValidate(oPC, nToken, APP_ITEM_BOTTOM_COLOR_ENTRIES, APP_ITEM_BOTTOM_COLOR_ID, 0);

            AppMisc3PartModelsWatchEvents(
                oPC,
                nToken,
                nModelId,
                ITEM_APPR_TYPE_WEAPON_COLOR,
                ITEM_APPR_WEAPON_COLOR_BOTTOM);
        }
        else if(sEventElem == APP_ITEM_ID)
        {
            int nModelId = AppComboValidate(oPC, nToken, APP_ITEM_ENTRIES, APP_ITEM_ID, 0);
            AppMisc1PartModelEvents(oPC, nToken, nModelId);
        }
    }
}

//-------------------------------------//
//-------------------------------------//
//------ Event On Player Target -------//
//-------------------------------------//
//-------------------------------------//
int ValidateAppMiscItem(object oPC, object oTarget)
{
    int nBaseType = GetBaseItemType(oTarget);
    int nWeaponType =
        StringToInt(Get2DAString("baseitems", "WeaponType", nBaseType));

    if((nBaseType != BASE_ITEM_BRACER && nBaseType != BASE_ITEM_GLOVES)
        && nWeaponType > 0)
    {
        return FALSE;
    }

    if(nBaseType == BASE_ITEM_SMALLSHIELD
        || nBaseType == BASE_ITEM_LARGESHIELD
        || nBaseType == BASE_ITEM_TOWERSHIELD
        || nBaseType == BASE_ITEM_HELMET
        || nBaseType == BASE_ITEM_ARMOR
        || nBaseType == BASE_ITEM_CLOAK
        || nBaseType == BASE_ITEM_SCROLL)
    {
        return FALSE;
    }

    return TRUE;
}

void AppMiscOnItemTarget(object oPC, object oTarget)
{
    int nToken = NuiFindWindow(oPC, APP_MISC_WINDOW);
    if(nToken == 0)
    {
        return;
    }

    string sTargetUUID = GetObjectUUID(oTarget);

    if(GetIsObjectValid(oTarget))
    {
        int bIsValid = FALSE;

        object oItemInventory = GetFirstItemInInventory(oPC);
        while(GetIsObjectValid(oItemInventory))
        {
            if(GetObjectUUID(oItemInventory) == sTargetUUID)
            {
                bIsValid = TRUE;

                NuiSetBind(oPC, nToken, APP_ITEM_NAME, JsonString(GetName(oItemInventory)));
                NuiSetBind(oPC, nToken, APP_MISC_PICKED, JsonBool(TRUE));

                if(ValidateAppMiscItem(oPC, oTarget))
                {
                    AppMiscSwapLayout(
                        oPC,
                        oTarget,
                        nToken,
                        sTargetUUID);
                }

                break;
            }

            oItemInventory = GetNextItemInInventory(oPC);
        }

        if(!bIsValid)
        {
            SendMessageToPC(oPC, "You can't select an item that is not in your inventory.");
            return;
        }
    }
}

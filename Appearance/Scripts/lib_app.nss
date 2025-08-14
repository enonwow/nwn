#include "lib_nui"

const string APP_UNEQUIPED_ITEMS = "APP_UNEQUIPED_ITEMS";

string GetRaceLetter(object oPC)
{
    int nRace = GetRacialType(oPC);

    string sRaceLetter = "";

    switch(nRace)
    {
        case RACIAL_TYPE_DWARF:
            sRaceLetter = "D";
            break;
        case RACIAL_TYPE_ELF:
            sRaceLetter = "E";
            break;
        case RACIAL_TYPE_GNOME:
            sRaceLetter = "G";
            break;
        case RACIAL_TYPE_HALFLING:
            sRaceLetter = "A";
            break;
        case RACIAL_TYPE_HALFORC:
            sRaceLetter = "O";
            break;
        case RACIAL_TYPE_HALFELF:
        case RACIAL_TYPE_HUMAN:
            sRaceLetter = "H";
            break;
    }

    return sRaceLetter;
}

json UnequipSlot(
    object oPCopy,
    int nSlot,
    json jItems)
{
    object oItem = GetItemInSlot(nSlot, oPCopy);

    if(GetIsObjectValid(oItem))
    {
        AssignCommand(oPCopy, ActionUnequipItem(oItem));

        jItems = JsonObjectSet(jItems,
            IntToString(nSlot), JsonString(GetObjectUUID(oItem)));
    }

    return jItems;
}

void WearItems(
    object oPC,
    object oPCopy,
    int nToken)
{
    json jItems = NuiGetBind(oPC, nToken, APP_UNEQUIPED_ITEMS);
    json jKeys = JsonObjectKeys(jItems);
    int nLength = JsonGetLength(jKeys);

    if(nLength > 0)
    {
        int i;
        for(i = 0; i < nLength; i++)
        {
            string sSlot = JsonGetString(JsonArrayGet(jKeys, i));
            string sItemUUID = JsonGetString(JsonObjectGet(jItems, sSlot));
            object oItem = GetObjectByUUID(sItemUUID);

            if(GetIsObjectValid(oItem))
            {
                AssignCommand(oPCopy, ActionEquipItem(oItem, StringToInt(sSlot)));
            }
        }

        NuiSetBind(oPC, nToken, APP_UNEQUIPED_ITEMS, JsonObject());
    }
}

void UnequipHelmet(
    object oPC,
    object oPCopy,
    int nToken)
{
    json jItemToEquip = NuiGetBind(oPC, nToken, APP_UNEQUIPED_ITEMS);
    json jKeys = JsonObjectKeys(jItemToEquip);
    int nLength = JsonGetLength(jKeys);

    int bSkip = FALSE;

    if(nLength > 0)
    {
        int i;
        for(i = 0; i < nLength; i++)
        {
            string sSlot = JsonGetString(JsonArrayGet(jKeys, i));

            if(sSlot == IntToString(INVENTORY_SLOT_HEAD))
            {
                bSkip = TRUE;
                continue;
            }

            string sItemUUID = JsonGetString(JsonObjectGet(jItemToEquip, sSlot));
            object oItem = GetObjectByUUID(sItemUUID);

            if(GetIsObjectValid(oItem))
            {
                AssignCommand(oPCopy, ActionEquipItem(oItem, StringToInt(sSlot)));
                JsonObjectDelInplace(jItemToEquip, sSlot);
            }
        }
    }

    if(!bSkip)
    {
        json jItems = UnequipSlot(oPCopy, INVENTORY_SLOT_HEAD, JsonObject());
        NuiSetBind(oPC, nToken, APP_UNEQUIPED_ITEMS, jItems);
    }
    else
    {
        NuiSetBind(oPC, nToken, APP_UNEQUIPED_ITEMS, jItemToEquip);
    }
}

void UnequipVisualItems(
    object oPC,
    object oPCopy,
    int nToken)
{
    json jItems = NuiGetBind(oPC, nToken, APP_UNEQUIPED_ITEMS);

    if(JsonGetType(jItems) == JSON_TYPE_NULL)
    {
        jItems = JsonObject();
    }

    if(JsonGetType(JsonObjectGet(jItems, IntToString(INVENTORY_SLOT_HEAD))) == JSON_TYPE_NULL)
    {
        jItems = UnequipSlot(oPCopy, INVENTORY_SLOT_HEAD, jItems);
    }

    if(JsonGetType(JsonObjectGet(jItems, IntToString(INVENTORY_SLOT_CHEST))) == JSON_TYPE_NULL)
    {
        jItems = UnequipSlot(oPCopy, INVENTORY_SLOT_CHEST, jItems);
    }

    if(JsonGetType(JsonObjectGet(jItems, IntToString(INVENTORY_SLOT_LEFTHAND))) == JSON_TYPE_NULL)
    {
        jItems = UnequipSlot(oPCopy, INVENTORY_SLOT_LEFTHAND, jItems);
    }

    if(JsonGetType(JsonObjectGet(jItems, IntToString(INVENTORY_SLOT_RIGHTHAND))) == JSON_TYPE_NULL)
    {
        jItems = UnequipSlot(oPCopy, INVENTORY_SLOT_RIGHTHAND, jItems);
    }

    if(JsonGetType(JsonObjectGet(jItems, IntToString(INVENTORY_SLOT_CLOAK))) == JSON_TYPE_NULL)
    {
        jItems = UnequipSlot(oPCopy, INVENTORY_SLOT_CLOAK, jItems);
    }

    NuiSetBind(oPC, nToken, APP_UNEQUIPED_ITEMS, jItems);
}

void UnequipedAllItems(
    object oPC,
    object oPCopy,
    int nToken)
{
    object oItem;
    int nSlot;

    json jItems = JsonObject();

    for (nSlot=0; nSlot < NUM_INVENTORY_SLOTS; nSlot++)
    {
        oItem = GetItemInSlot(nSlot, oPC);

        if(GetIsObjectValid(oItem))
        {
            jItems = JsonObjectSet(jItems,
                IntToString(nSlot), JsonString(GetObjectUUID(oItem)));

            AssignCommand(oPCopy, ActionUnequipItem(oItem));
        }
    }

    NuiSetBind(oPC, nToken, APP_UNEQUIPED_ITEMS, jItems);
}

int HasEquipedArmor(object oPC)
{
    object oItem = GetItemInSlot(INVENTORY_SLOT_CHEST, oPC);

    return GetIsObjectValid(oItem);
}

int HasEquipedCloak(object oPC)
{
    object oItem = GetItemInSlot(INVENTORY_SLOT_CLOAK, oPC);

    return GetIsObjectValid(oItem);
}

int HasEquipedHelmet(object oPC)
{
    object oItem = GetItemInSlot(INVENTORY_SLOT_HEAD, oPC);

    return GetIsObjectValid(oItem);
}

int HasEquipedWeaponInHand(object oPC, int nHand)
{
    object oItem = GetItemInSlot(nHand, oPC);

    if(!GetIsObjectValid(oItem))
    {
        return FALSE;
    }

    int nBaseType = GetBaseItemType(oItem);
    int nWeaponType =
        StringToInt(Get2DAString("baseitems", "WeaponType", nBaseType));

    return nWeaponType > 0;
}

int HasEquipedWeapon(object oPC)
{
    return HasEquipedWeaponInHand(oPC, INVENTORY_SLOT_RIGHTHAND) ||
        HasEquipedWeaponInHand(oPC, INVENTORY_SLOT_LEFTHAND);
}

int HasEquipedShield(object oPC)
{
    object oItem = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oPC);

    if(!GetIsObjectValid(oItem))
    {
        return FALSE;
    }

    int nBaseType = GetBaseItemType(oItem);
    string sItem = Get2DAString("baseitems", "label", nBaseType);

    return FindSubString(sItem, "shield") >= 0;
}

//-------------------------------------//
//-------------------------------------//
//-------------- LOCATION -------------//
//-------------------------------------//
//-------------------------------------//
const string APP_DRESSING_ROOM_RESREF = "dressing_room";
const string APP_DRESSING_ROOM_BACK_LOCATION = "APP_DRESSING_ROOM_BACK_LOCATION";
const string APP_DRESSING_ROOM_WP = "WP_DRESSING_ROOM";
const string APP_DRESSING_ROOM_WP_TP = "WP_DRESSING_ROOM_TP";
const string APP_DRESSING_ROOM_WP_TP2 = "WP_DRESSING_ROOM_TP2";

const string APP_DRESSING_ROOM_COPY = "APP_DRESSING_ROOM_COPY";

void DressingRoomDisableGuiPanel(object oPC, int bDisable)
{
    SetGuiPanelDisabled(oPC, GUI_PANEL_MINIMAP, bDisable);
    SetGuiPanelDisabled(oPC, GUI_PANEL_COMPASS, bDisable);
    SetGuiPanelDisabled(oPC, GUI_PANEL_INVENTORY, bDisable);
    SetGuiPanelDisabled(oPC, GUI_PANEL_PLAYERLIST, bDisable);
    SetGuiPanelDisabled(oPC, GUI_PANEL_JOURNAL, bDisable);
    SetGuiPanelDisabled(oPC, GUI_PANEL_SPELLBOOK, bDisable);
    SetGuiPanelDisabled(oPC, GUI_PANEL_CHARACTERSHEET, bDisable);
    SetGuiPanelDisabled(oPC, GUI_PANEL_GOLD_INVENTORY, bDisable);
    SetGuiPanelDisabled(oPC, GUI_PANEL_GOLD_BARTER, bDisable);
    SetGuiPanelDisabled(oPC, GUI_PANEL_RADIAL_TRIGGER, bDisable);
    SetGuiPanelDisabled(oPC, GUI_PANEL_RADIAL_CREATURE, bDisable);
    SetGuiPanelDisabled(oPC, GUI_PANEL_RADIAL_ITEM, bDisable);
    SetGuiPanelDisabled(oPC, GUI_PANEL_RADIAL_PLACEABLE, bDisable);
    SetGuiPanelDisabled(oPC, GUI_PANEL_RADIAL_DOOR, bDisable);
    SetGuiPanelDisabled(oPC, GUI_PANEL_RADIAL_QUICKBAR, bDisable);
}

void DressingRoomCreateCopy(object oPC)
{
    object oArea = OBJECT_SELF;

    object oWP = GetFirstObjectInArea(oArea, OBJECT_TYPE_WAYPOINT);
    while(GetIsObjectValid(oWP))
    {
        if(GetTag(oWP) == APP_DRESSING_ROOM_WP)
        {
            break;
        }

        oWP = GetNextObjectInArea(oArea, OBJECT_TYPE_WAYPOINT);
    }

    location lSpawnLocation = GetLocation(oWP);

    json jsonPC = ObjectToJson(oPC);
    jsonPC = JsonObjectSet(jsonPC, "ItemList", JsonObjectSet(JsonObjectGet(jsonPC, "ItemList"), "value", JsonArray()));
    object oPCopy = JsonToObject(jsonPC, lSpawnLocation, OBJECT_INVALID, TRUE);

    SetObjectVisibleDistance(oPCopy, 200.0);

    DelayCommand(0.5, AttachCamera(oPC, oPCopy, TRUE));

    SetLocalObject(oArea, APP_DRESSING_ROOM_COPY, oPCopy);
}

void EnterDressingRoom(object oPC)
{
    object oArea = OBJECT_SELF;

    object oWP = GetFirstObjectInArea(oArea, OBJECT_TYPE_WAYPOINT);
    while(GetIsObjectValid(oWP))
    {
        if(GetTag(oWP) == APP_DRESSING_ROOM_WP_TP2)
        {
            break;
        }

        oWP = GetNextObjectInArea(oArea, OBJECT_TYPE_WAYPOINT);
    }

    location lLocationTP = GetLocation(oWP);
    AssignCommand(oPC, JumpToLocation(lLocationTP));
    DelayCommand(1.0, SetAntyExploitStatus(oPC));
}

object CreateDressingRoom(object oPC)
{
    object oArea = CreateArea(APP_DRESSING_ROOM_RESREF);

    location lLocation = GetLocation(oPC);

    object oWP = GetFirstObjectInArea(oArea, OBJECT_TYPE_WAYPOINT);
    while(GetIsObjectValid(oWP))
    {
        if(GetTag(oWP) == APP_DRESSING_ROOM_WP_TP)
        {
            break;
        }

        oWP = GetNextObjectInArea(oArea, OBJECT_TYPE_WAYPOINT);
    }

    location lLocationTP = GetLocation(oWP);

    ClearAllActions(TRUE, oPC);
    AssignCommand(oPC, JumpToLocation(lLocationTP));

    SetLocalLocation(oArea, APP_DRESSING_ROOM_BACK_LOCATION, lLocation);

    return oArea;
}

void VoidDestroyArea(object oArea)
{
    DestroyArea(oArea);
}

void DestroyDressingRoom(object oPC)
{
    object oArea = GetArea(oPC);

    AttachCamera(oPC, oPC);

    location lLocation = GetLocalLocation(oArea, APP_DRESSING_ROOM_BACK_LOCATION);

    RemoveAntyExploitStatus(oPC);
    DressingRoomDisableGuiPanel(oPC, FALSE);

    AssignCommand(oPC, JumpToLocation(lLocation));

    DelayCommand(10.0, VoidDestroyArea(oArea));
}

//-------------------------------------//
//-------------------------------------//
//--------------- CAMERA --------------//
//-------------------------------------//
//-------------------------------------//

const string APP_CAMERA_DISTANCE = "APP_CAMERA_DISTANCE";

object GetAppArea(object oPC)
{
    return GetArea(oPC);
}

void SetCameraDistance(object oPC, float fDistance)
{
    SetLocalFloat(GetAppArea(oPC), APP_CAMERA_DISTANCE, fDistance);
}

float GetCameraDistance(object oPC)
{
    return GetLocalFloat(GetAppArea(oPC), APP_CAMERA_DISTANCE);
}

void LockCamera(object oPC)
{
    LockCameraDistance(oPC, TRUE);
    LockCameraPitch(oPC, TRUE);
    LockCameraDirection(oPC, TRUE);
}

void UnlockCamera(object oPC)
{
    LockCameraDistance(oPC, FALSE);
    LockCameraPitch(oPC, FALSE);
    LockCameraDirection(oPC, FALSE);
}

float GetCameraHeightForBody(object oPC)
{
    int nRace = GetRacialType(oPC);

    float fHeight;

    switch(nRace)
    {
        case RACIAL_TYPE_DWARF:
            fHeight = 0.8;
            break;
        case RACIAL_TYPE_ELF:
            fHeight = 0.8;
            break;
        case RACIAL_TYPE_GNOME:
            fHeight = 0.8;
            break;
        case RACIAL_TYPE_HALFLING:
            fHeight = 0.8;
            break;
        case RACIAL_TYPE_HALFELF:
        case RACIAL_TYPE_HUMAN:
            fHeight = 0.8;
            break;
        case RACIAL_TYPE_HALFORC:
            fHeight = 0.8;
            break;
    }

    return fHeight;
}

float GetCameraDistanceForBody(object oPC)
{
    int nRace = GetRacialType(oPC);

    float fDistance;

    switch(nRace)
    {
        case RACIAL_TYPE_DWARF:
            fDistance = 3.0;
            break;
        case RACIAL_TYPE_ELF:
            fDistance = 3.0;
            break;
        case RACIAL_TYPE_GNOME:
            fDistance = 3.0;
            break;
        case RACIAL_TYPE_HALFLING:
            fDistance = 3.0;
            break;
        case RACIAL_TYPE_HALFELF:
        case RACIAL_TYPE_HUMAN:
            fDistance = 3.0;
            break;
        case RACIAL_TYPE_HALFORC:
            fDistance = 3.0;
            break;
    }

    return fDistance;
}

float GetCameraHeightForFace(object oPC)
{
    int nRace = GetRacialType(oPC);

    float fHeight;

    switch(nRace)
    {
        case RACIAL_TYPE_DWARF:
            fHeight = 1.35;
            break;
        case RACIAL_TYPE_ELF:
            fHeight = 1.6;
            break;
        case RACIAL_TYPE_GNOME:
            fHeight = 1.25;
            break;
        case RACIAL_TYPE_HALFLING:
            fHeight = 1.2;
            break;
        case RACIAL_TYPE_HALFELF:
        case RACIAL_TYPE_HUMAN:
            fHeight = 1.8;
            break;
        case RACIAL_TYPE_HALFORC:
            fHeight = 2.0;
            break;
    }

    return fHeight;
}

float GetCameraDistanceForFace(object oPC)
{
    int nRace = GetRacialType(oPC);

    float fDistance;

    switch(nRace)
    {
        case RACIAL_TYPE_DWARF:
            fDistance = 1.0;
            break;
        case RACIAL_TYPE_ELF:
            fDistance = 1.0;
            break;
        case RACIAL_TYPE_GNOME:
            fDistance = 1.0;
            break;
        case RACIAL_TYPE_HALFLING:
            fDistance = 1.0;
            break;
        case RACIAL_TYPE_HALFELF:
        case RACIAL_TYPE_HUMAN:
            fDistance = 1.0;
            break;
        case RACIAL_TYPE_HALFORC:
            fDistance = 1.0;
            break;
    }

    return fDistance;
}

void ReleaseCameraBody(object oPC, object oPCopy)
{
    float fScale = GetLocalFloat(oPCopy, "SCALE");
    fScale = fScale == 0.0 ? 1.0 : fScale;

    float fDistance = GetCameraDistanceForBody(oPC) * fScale;
    float fHeight = GetCameraHeightForBody(oPC) * fScale;

    AssignCommand(oPC,
        SetCameraFacing(
            270.0,
            fDistance,
            90.0,
            CAMERA_TRANSITION_TYPE_SNAP));

    SetCameraHeight(oPC, fHeight);

    SetCameraDistance(oPC, fDistance);
}

void SetCameraBody(object oPC, object oPCopy)
{
    float fScale = GetLocalFloat(oPCopy, "SCALE");
    fScale = fScale == 0.0 ? 1.0 : fScale;

    float fDistance = GetCameraDistanceForBody(oPC) * fScale;
    float fHeight = GetCameraHeightForBody(oPC) * fScale;

    AssignCommand(oPC,
        SetCameraFacing(
            90.0,
            fDistance,
            90.0,
            CAMERA_TRANSITION_TYPE_SNAP));

    SetCameraHeight(oPC, fHeight);

    SetCameraDistance(oPC, fDistance);

    //DelayCommand(1.0, LockCamera(oPC));
}

void SetCameraFace(object oPC, object oPCopy)
{
    float fScale = GetLocalFloat(oPCopy, "SCALE");
    fScale = fScale == 0.0 ? 1.0 : fScale;

    float fDistance = GetCameraDistanceForFace(oPC) * fScale;
    float fHeight = GetCameraHeightForFace(oPC) * fScale;

    AssignCommand(oPC,
        SetCameraFacing(
            90.0,
            fDistance,
            90.0,
            CAMERA_TRANSITION_TYPE_SNAP));

    SetCameraHeight(oPC, fHeight);

    SetCameraDistance(oPC, fDistance);
}

void SetCameraZoom(object oPC, float fZoom)
{
    float fDistance = GetCameraDistance(oPC) + fZoom;

    if(fDistance < 1.0)
    {
        return;
    }
    else if(fDistance > 7.0)
    {
        return;
    }

    AssignCommand(oPC,
        SetCameraFacing(
            90.0,
            fDistance,
            90.0,
            CAMERA_TRANSITION_TYPE_SNAP));

    SetCameraDistance(oPC, fDistance);
}

void RotateObject(object oObject, float fAngle)
{
    object oArea = GetAppArea(oObject);

    float fDirection = GetFacing(oObject) + fAngle;

    AssignCommand(oObject, SetFacing(fDirection, oObject));
}

//-------------------------------------//
//-------------------------------------//
//----------------- NUI ---------------//
//-------------------------------------//
//-------------------------------------//

const string APP_ACTIVE_WINDOW = "APP_ACTIVE_WINDOW";
const string APP_GEOMETRY_WINDOW = "APP_GEOMETRY_WINDOW";

const string APP_PREV_COLOR_BTN = "APP_PREV_COLOR_BTN";
const string APP_COLOR_TE = "APP_COLOR_TE";
const string APP_NEXT_COLOR_BTN = "APP_NEXT_COLOR_BTN";

const string APP_ARROW_PREV_BTN = "cc_arrow_l_btn";
const string APP_ARROW_NEXT_BTN = "cc_arrow_r_btn";

const string APP_RANDOMIZE_BTN = "APP_RANDOMIZE_BTN";
const string APP_CONFIRM_BTN = "APP_CONFIRM_BTN";
const string APP_CANCEL_BTN = "APP_CANCEL_BTN";

const string APP_BTN = "APP_BTN_";
const string APP_COLOR_BTN = "APP_COLOR_BTN_";
const string APP_COLOR_BTN_ENCOURAGED = "_ENCOURAGED";
const string APP_COLOR_BTN_ACTIVE = "APP_COLOR_BTN_ACTIVE";

const float APP_BACKGROUND_IMAGE_WIDTH = 542.0;
const float APP_BACKGROUND_IMAGE_HEIGHT = 900.0;

const float APP_UPPER_SPACER_HEIGHT = 50.0;
const float APP_LEFT_SPACER_WIDTH = 33.0;

const float APP_COLOR_BTN_WIDTH = 25.0;
const float APP_COLOR_BTN_HEIGHT = 25.0;

const float APP_BTN_WIDTH = 40.0;
const float APP_BTN_HEIGHT = 40.0;

const float APP_BOTTOM_BTN_WIDTH = 50.0;
const float APP_BOTTOM_BTN_HEIGHT = 50.0;

const float APP_LABEL_WIDTH = 50.0;

const float APP_OFFSET = 10.0;

const string APP_COLOR_BTN_PREFIX = "APP_COLOR_BTN_PREFIX_";

const int APP_MAX_COLUMNS = 11;
const int APP_MAX_ROWS = 16;

const string APP_ITEM_ENTRIES = "APP_ITEM_ENTRIES";
const string APP_ITEM_ID = "APP_ITEM_ID";
const string APP_ITEM_PREVIOUS_BTN = "APP_ITEM_PREVIOUS_BTN";
const string APP_ITEM_NEXT_BTN = "APP_ITEM_NEXT_BTN";

const string APP_ITEM_MODEL = "APP_ITEM_MODEL_";
const string APP_ITEM_MODEL_ENCOURAGED = "APP_ITEM_MODEL_ENCOURAGED";
const string APP_ITEM_MODELS_ID = "APP_ITEM_MODELS_ID";

const string APP_RIGHT_PANEL_WINDOW = "APP_RIGHT_PANEL_WINDOW";
const string APP_HEAD_WINDOW = "APP_HEAD_WINDOW";
const string APP_BODY_WINDOW = "APP_BODY_WINDOW";
const string APP_TATOO_WINDOW = "APP_TATOO_WINDOW";
const string APP_HELMET_WINDOW = "APP_HELMET_WINDOW";
const string APP_ARMOR_WINDOW = "APP_ARMOR_WINDOW";
const string APP_CLOAK_WINDOW = "APP_CLOAK_WINDOW";
const string APP_WEAPON_WINDOW = "APP_WEAPON_WINDOW";
const string APP_SHIELD_WINDOW = "APP_SHIELD_WINDOW";
const string APP_MISC_WINDOW = "APP_MISC_WINDOW";

struct ModelInfo
{
    int nLength;
    json jModels;
    json jModelIds;
    int nAppId;
    string sKeySuffix;
    string sKeyPrefix;
};

void AppDestroyActiveWindow(object oPC)
{
    object oArea = GetAppArea(oPC);

    int nToken = GetLocalInt(oArea, APP_ACTIVE_WINDOW);

    if(nToken > 0)
    {
        NuiDestroy(oPC, nToken);
        SetLocalInt(oArea, APP_ACTIVE_WINDOW, 0);
    }
}

void AppSetActiveWindow(object oPC, int nToken)
{
    object oArea = GetAppArea(oPC);

    SetLocalInt(oArea, APP_ACTIVE_WINDOW, nToken);
}

void AppSetGeometryWindow(object oPC, json jGeometry)
{
    object oArea = GetAppArea(oPC);

    SetLocalJson(oArea, APP_GEOMETRY_WINDOW, jGeometry);
}

void AppCreateGeometryWindow(object oPC, float fRightPanelX)
{
    int nDeviceHeigt = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT);

    float fWindowWidth = APP_BACKGROUND_IMAGE_WIDTH + APP_OFFSET;
    float fWindowHeight = nDeviceHeigt + APP_OFFSET;

    json jGeometry = NuiRect(
        fRightPanelX - APP_BACKGROUND_IMAGE_WIDTH + 3.0,
        0.0,
        fWindowWidth,
        fWindowHeight);

    AppSetGeometryWindow(oPC, jGeometry);
}

json AppGetGeometryWindow(object oPC)
{
    object oArea = GetAppArea(oPC);

    return GetLocalJson(oArea, APP_GEOMETRY_WINDOW);
}

void AppOffColorEncouraged(object oPC, int nToken)
{
    string sBtnId = JsonGetString(NuiGetBind(oPC, nToken, NUI_DATA_ENCOURAGED));

    if(sBtnId != "")
    {
        NuiSetBind(oPC, nToken, sBtnId, JsonBool(FALSE));
        NuiSetBind(oPC, nToken, NUI_DATA_ENCOURAGED, JsonString(""));
    }
}

void AppOnColorEncouraged(
    object oPC,
    int nToken,
    string sBtnId)
{
    NuiSetBind(oPC, nToken, sBtnId, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, NUI_DATA_ENCOURAGED, JsonString(sBtnId));
}

int AppValidateColor(int nColor)
{
    if(nColor == 255)
    {
        return nColor;
    }

    if(nColor < 0)
    {
        nColor = 175;
    }
    else if(nColor > 175)
    {
        nColor = 0;
    }

    return nColor;
}

json AppSetForegroundColor(json jElement)
{
    // json jColor = NuiColor(168, 127, 0);
    json jColor = NuiColor(255, 255, 255);

    jElement = NuiStyleForegroundColor(jElement, jColor);

    return jElement;
}

void AppSetColorNui(
    object oPC,
    int nToken,
    int nColor,
    int nColorChannel)
{
    NuiSetBindWatch(oPC, nToken, APP_COLOR_TE, FALSE);
    NuiSetBind(oPC, nToken, APP_COLOR_TE, JsonString(IntToString(nColor)));
    NuiSetBindWatch(oPC, nToken, APP_COLOR_TE, TRUE);

    AppOffColorEncouraged(oPC, nToken);
    AppOnColorEncouraged(oPC, nToken, APP_BTN + IntToString(nColor));
}

void AppSetColor(
    object oPC,
    object oPCopy,
    int nToken,
    int nColor,
    int nColorChannel)
{
    nColor = AppValidateColor(nColor);

    SetColor(oPCopy, nColorChannel, nColor);

    AppSetColorNui(oPC, nToken, nColor, nColorChannel);
}

string AppGetColorPickerButtonBind(int nId)
{
    return APP_COLOR_BTN + IntToString(nId);
}

string AppGetColorPickerButtonEncouragedBind(int nId)
{
    return AppGetColorPickerButtonBind(nId) + APP_COLOR_BTN_ENCOURAGED;
}

json AppCreateColorPickerButton(int nId, string sTooltip)
{
    string sBind = AppGetColorPickerButtonBind(nId);

    json jColorBtn = NuiButtonImage(NuiBind(sBind));
    jColorBtn = NuiId(jColorBtn, sBind);
    jColorBtn = NuiTooltip(jColorBtn, JsonString(sTooltip));
    jColorBtn = NuiWidth(jColorBtn, 40.0);
    jColorBtn = NuiHeight(jColorBtn, 40.0);
    jColorBtn = NuiEncouraged(jColorBtn,
        NuiBind(AppGetColorPickerButtonEncouragedBind(nId)));
    jColorBtn = AppSetForegroundColor(jColorBtn);

    return jColorBtn;
}

void AppSetColorPickerButtonEncouraged(
    object oPC,
    int nToken,
    int nButtonCount,
    string sBindActive,
    int nStartId = 0)
{
    int nEndId = nStartId + nButtonCount;

    int i;
    for(i = nStartId; i < nEndId; i++)
    {
        string sBind = AppGetColorPickerButtonBind(i);
        if(sBind == sBindActive)
        {
            NuiSetBind(oPC, nToken,
                AppGetColorPickerButtonEncouragedBind(i), JsonBool(TRUE));
            NuiSetBind(oPC, nToken, APP_COLOR_BTN_ACTIVE, JsonInt(i));
        }
        else
        {
            NuiSetBind(oPC, nToken,
                AppGetColorPickerButtonEncouragedBind(i), JsonBool(FALSE));
        }
    }
}

void FeedAppColorTemplate(
    object oPC,
    int nToken,
    string sInitColorBtnPrefix)
{
    int nMax = APP_MAX_COLUMNS * APP_MAX_ROWS;

    int i;
    for(i = 0; i < nMax; i++)
    {
        string sId = IntToString(i);
        string sBind = APP_COLOR_BTN_PREFIX + sId;

        NuiSetBind(oPC, nToken, sBind, JsonString(sInitColorBtnPrefix + sId));
    }
}

json CreateAppColorTemplateTopSpacer(float fHeight)
{
    json jSpacer = NuiSpacer();

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiHeight(jSpacer, fHeight));

    return NuiRow(jRow);
}

json CreateAppColorTemplateLabelName(string sWindowNameLabel)
{
    json jLabel = NuiLabel(
        JsonString(sWindowNameLabel),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jLabel = NuiHeight(jLabel, 30.0);
    jLabel = AppSetForegroundColor(jLabel);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jLabel);

    return NuiRow(jRow);
}

json AppDispatchElements(
    json jElements,
    json jCol)
{
    int nLength = JsonGetLength(jElements);
    int i;

    for(i = 0; i < nLength; i++)
    {
        json jElement = JsonArrayGet(jElements, i);

        jCol = JsonArrayInsert(jCol, jElement);
    }

    return jCol;
}

json CreateAppColorTemplateColorPicker()
{
    json jColorCol = JsonArray();

    float fHeight;
    int i,j;

    for(i = 0; i < APP_MAX_COLUMNS; i++)
    {
        json jColorRow = JsonArray();

        for(j = 0; j < APP_MAX_ROWS; j++)
        {
            string sId = IntToString(j + i * 16);

            string sBtnId = APP_BTN + sId;

            json jButton = NuiButtonImage(NuiBind(APP_COLOR_BTN_PREFIX + sId));
            jButton = NuiId(jButton, sBtnId);
            jButton = NuiTooltip(jButton, JsonString(sId));
            jButton = NuiEncouraged(jButton, NuiBind(sBtnId));
            jButton = NuiWidth(jButton, APP_COLOR_BTN_WIDTH);
            jButton = NuiHeight(jButton, APP_COLOR_BTN_HEIGHT);
            jButton = AppSetForegroundColor(jButton);

            jColorRow = JsonArrayInsert(jColorRow, jButton);
        }

        jColorCol = JsonArrayInsert(jColorCol, NuiRow(jColorRow));

        fHeight += APP_COLOR_BTN_HEIGHT + 9;
    }

    json jSpacer = NuiSpacer();

    json jElements = JsonArray();
    jElements = JsonArrayInsert(jElements, NuiWidth(jSpacer, APP_LEFT_SPACER_WIDTH));
    jElements = JsonArrayInsert(jElements, NuiCol(jColorCol));
    jElements = JsonArrayInsert(jElements, jSpacer);

    json jGroup = NuiGroup(NuiRow(jElements), FALSE, NUI_SCROLLBARS_NONE);
    jGroup = NuiHeight(jGroup, fHeight);

    return jGroup;
}

json CreateAppColorTemplateColorChooser()
{
    json jSpacer = NuiSpacer();

    json jLeftBtn = NuiButtonImage(JsonString(APP_ARROW_PREV_BTN));
    jLeftBtn = NuiId(jLeftBtn, APP_PREV_COLOR_BTN);
    jLeftBtn = NuiTooltip(jLeftBtn, JsonString("Previous color"));
    jLeftBtn = NuiWidth(jLeftBtn, APP_BTN_WIDTH);
    jLeftBtn = NuiHeight(jLeftBtn, APP_BTN_HEIGHT);

    json jTextEdit = NuiTextEdit(
        JsonString(""),
        NuiBind(APP_COLOR_TE),
        3,
        FALSE);
    jTextEdit = NuiTooltip(jTextEdit, JsonString("Color"));
    jTextEdit = AppSetForegroundColor(jTextEdit);
    jTextEdit = NuiWidth(jTextEdit, APP_BTN_WIDTH);
    jTextEdit = NuiHeight(jTextEdit, APP_BTN_HEIGHT);

    json jRightBtn = NuiButtonImage(JsonString(APP_ARROW_NEXT_BTN));
    jRightBtn = NuiId(jRightBtn, APP_NEXT_COLOR_BTN);
    jRightBtn = NuiTooltip(jRightBtn, JsonString("Next color"));
    jRightBtn = NuiWidth(jRightBtn, APP_BTN_WIDTH);
    jRightBtn = NuiHeight(jRightBtn, APP_BTN_HEIGHT);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jLeftBtn);
    jRow = JsonArrayInsert(jRow, jTextEdit);
    jRow = JsonArrayInsert(jRow, jRightBtn);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

json CreateAppColorTemplateButtonPanel()
{
    json jSpacer = NuiSpacer();

    json jRandomizeBtn = NuiButtonImage(JsonString("app_roll"));
    jRandomizeBtn = NuiTooltip(jRandomizeBtn, JsonString("Randomize"));
    jRandomizeBtn = NuiId(jRandomizeBtn, APP_RANDOMIZE_BTN);
    jRandomizeBtn = NuiWidth(jRandomizeBtn, APP_BOTTOM_BTN_WIDTH);
    jRandomizeBtn = NuiHeight(jRandomizeBtn, APP_BOTTOM_BTN_HEIGHT);

    json jConfirmBtn = NuiButtonImage(JsonString("app_confirm"));
    jConfirmBtn = NuiTooltip(jConfirmBtn, JsonString("Confirm"));
    jConfirmBtn = NuiId(jConfirmBtn, APP_CONFIRM_BTN);
    jConfirmBtn = NuiWidth(jConfirmBtn, APP_BOTTOM_BTN_WIDTH);
    jConfirmBtn = NuiHeight(jConfirmBtn, APP_BOTTOM_BTN_HEIGHT);

    json jCancelBtn = NuiButtonImage(JsonString("custom_close_nui"));
    jCancelBtn = NuiTooltip(jCancelBtn, JsonString("Cancel"));
    jCancelBtn = NuiId(jCancelBtn, APP_CANCEL_BTN);
    jCancelBtn = NuiWidth(jCancelBtn, APP_BOTTOM_BTN_WIDTH);
    jCancelBtn = NuiHeight(jCancelBtn, APP_BOTTOM_BTN_HEIGHT);

    json jRow = JsonArray();
    // jRow = JsonArrayInsert(jRow, jSpacer);
    // jRow = JsonArrayInsert(jRow, jRandomizeBtn);
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jConfirmBtn);
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jCancelBtn);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

int AppColorTemplateWindow(
    object oPC,
    string sWindowName,
    string sWindowNameLabel,
    string sInitColorBtnPrefix,
    json jPrevElements,
    json jNextElements,
    float fWindowHeight,
    string sEventScript,
    float fTopSpacerHeight = APP_UPPER_SPACER_HEIGHT)
{
    json jSpacer = NuiSpacer();

    json jCol = JsonArray();
    json jRow = JsonArray();

    jCol = JsonArrayInsert(jCol, CreateAppColorTemplateTopSpacer(fTopSpacerHeight));
    jCol = JsonArrayInsert(jCol, CreateAppColorTemplateLabelName(sWindowNameLabel));

    jCol = AppDispatchElements(jPrevElements, jCol);

    jCol = JsonArrayInsert(jCol, CreateAppColorTemplateColorPicker());
    jCol = JsonArrayInsert(jCol, CreateAppColorTemplateColorChooser());

    jCol = AppDispatchElements(jNextElements, jCol);

    jCol = JsonArrayInsert(jCol, CreateAppColorTemplateButtonPanel());

    jRow = JsonArray();
    {
        jRow = JsonArrayInsert(jRow, jSpacer);

        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    json jImageList = JsonArray();

    json jImage = NuiDrawListImage(
        JsonBool(TRUE),
        JsonString("cc"),
        NuiRect(
            0.0,
            15.0,
            APP_BACKGROUND_IMAGE_WIDTH,
            fWindowHeight),
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

    int nToken = NuiCreate(oPC, jNui, sWindowName, sEventScript);

    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY, AppGetGeometryWindow(oPC));
    NuiSetBind(oPC, nToken, WINDOW_RESIZABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_CLOSABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_TRANSPARENT, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, WINDOW_BORDER, JsonBool(FALSE));

    AppSetActiveWindow(oPC, nToken);

    FeedAppColorTemplate(oPC, nToken, sInitColorBtnPrefix);

    return nToken;
}

json AppCreateImage(
    json jElementDrawAt,
    string sImage,
    float fWidth,
    float fHeight)
{
    json jImageList = JsonArray();

    json jImage = NuiDrawListImage(
        JsonBool(TRUE),
        JsonString(sImage),
        NuiRect(
            0.0,
            0.0,
            fWidth,
            fHeight),
        JsonInt(NUI_ASPECT_FIT),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE),
        NUI_DRAW_LIST_ITEM_ORDER_BEFORE,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

    jImageList = JsonArrayInsert(jImageList, jImage);

    json jResult = NuiDrawList(NuiCol(jElementDrawAt), JsonBool(FALSE), jImageList);
    jResult = NuiWidth(jResult, fWidth);
    jResult = NuiHeight(jResult, fHeight);

    return jResult;
}

string AppGetItemColor(int nColorChannel)
{
    string sValue;

    switch(nColorChannel)
    {
        case ITEM_APPR_ARMOR_COLOR_LEATHER1:
        case ITEM_APPR_ARMOR_COLOR_LEATHER2:
        case ITEM_APPR_ARMOR_COLOR_CLOTH1:
        case ITEM_APPR_ARMOR_COLOR_CLOTH2:
            sValue = "cc_color_";
            break;
        case ITEM_APPR_ARMOR_COLOR_METAL1:
        case ITEM_APPR_ARMOR_COLOR_METAL2:
            sValue = "cc_color_m_";
            break;
    }

    return sValue;
}

void AppSetItemColor(
    object oPC,
    int nToken,
    int nColor,
    int nColorChannel)
{
    nColor = AppValidateColor(nColor);

    string sId = IntToString(nColor);

    string sBind = AppGetColorPickerButtonBind(nColorChannel);
    string sValue = AppGetItemColor(nColorChannel) + sId;

    NuiSetBind(oPC, nToken, sBind, JsonString(sValue));

    AppSetColorNui(oPC, nToken, nColor, nColorChannel);
}

void KeepItemInLeftHand(object oPC)
{
    object oItem = GetItemInSlot(INVENTORY_SLOT_LEFTHAND, oPC);

    if(GetIsObjectValid(oItem))
    {
        AssignCommand(oPC, ActionEquipItem(oItem, INVENTORY_SLOT_LEFTHAND));
    }

}

void CopyItemToSlot(
    object oItemToCopy,
    object oTarget,
    int nSlot)
{
    object oItem = GetItemInSlot(nSlot, oTarget);

    DestroyObject(oItem);

    object oNewItem = CopyItem(oItemToCopy, oTarget, TRUE);

    AssignCommand(oTarget, ActionEquipItem(oNewItem, nSlot));
}

void CreateNewItem(
    object oPC,
    object oItem,
    int nSlot,
    int nType,
    int nIndex,
    int nNewValue)
{
    object oItem = GetItemInSlot(nSlot, oPC);

    object oNewItem = CopyItemAndModify(oItem, nType, nIndex, nNewValue);

    if(GetIsObjectValid(oNewItem))
    {
        AssignCommand(oPC, ActionEquipItem(oNewItem, nSlot));
        DestroyObject(oItem);
    }
    else
    {
        SendMessageToPC(oPC, "You can't select this model.");
        oNewItem = oItem;
    }

    if(nSlot == INVENTORY_SLOT_RIGHTHAND)
    {
        KeepItemInLeftHand(oPC);
    }
}

json CreateAppColorPicker()
{
    json jSpacer = NuiSpacer();
    json jRow = JsonArray();

    json jFirstLeatherBtn = AppCreateColorPickerButton(
        ITEM_APPR_ARMOR_COLOR_LEATHER1, "Leather color 1");

    json jSecondLeatherBtn = AppCreateColorPickerButton(
        ITEM_APPR_ARMOR_COLOR_LEATHER2, "Leather color 2");

    json jFirstClothBtn = AppCreateColorPickerButton(
        ITEM_APPR_ARMOR_COLOR_CLOTH1, "Cloth color 1");

    json jSecondClothBtn = AppCreateColorPickerButton(
        ITEM_APPR_ARMOR_COLOR_CLOTH2, "Cloth color 2");

    json jFirstMetalBtn = AppCreateColorPickerButton(
        ITEM_APPR_ARMOR_COLOR_METAL1, "Metal color 1");

    json jSecondMetalBtn = AppCreateColorPickerButton(
        ITEM_APPR_ARMOR_COLOR_METAL2, "Metal color 2");

    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jFirstLeatherBtn);
    jRow = JsonArrayInsert(jRow, jSecondLeatherBtn);
    jRow = JsonArrayInsert(jRow, jFirstClothBtn);
    jRow = JsonArrayInsert(jRow, jSecondClothBtn);
    jRow = JsonArrayInsert(jRow, jFirstMetalBtn);
    jRow = JsonArrayInsert(jRow, jSecondMetalBtn);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

void FeedAppItemColor(
    object oPC,
    object oItem,
    int nToken,
    int nType,
    int nColorChannel,
    int nButtonCount,
    int nStartId = 0)
{
    string sBind = AppGetColorPickerButtonBind(nColorChannel);

    int nColor = GetItemAppearance(oItem, nType, nColorChannel);
    string sId = IntToString(nColor);

    AppOffColorEncouraged(oPC, nToken);
    AppOnColorEncouraged(oPC, nToken, APP_BTN + sId);
    NuiSetBind(oPC, nToken, APP_COLOR_TE, JsonString(sId));

    string sValue = AppGetItemColor(nColorChannel);
    NuiSetBind(oPC, nToken, sBind, JsonString(sValue + sId));
    AppSetColorPickerButtonEncouraged(oPC, nToken, nButtonCount, sBind, nStartId);
    FeedAppColorTemplate(oPC, nToken, sValue);
}

void FeedBasicColorPickerButtons(
    object oPC,
    object oItem,
    int nToken)
{
    int nFirstLeather = GetItemAppearance(oItem,
        ITEM_APPR_TYPE_ARMOR_COLOR, ITEM_APPR_ARMOR_COLOR_LEATHER1);

    int nSecondLeather = GetItemAppearance(oItem,
        ITEM_APPR_TYPE_ARMOR_COLOR, ITEM_APPR_ARMOR_COLOR_LEATHER2);

    int nFirstCloth = GetItemAppearance(oItem,
        ITEM_APPR_TYPE_ARMOR_COLOR, ITEM_APPR_ARMOR_COLOR_CLOTH1);

    int nSecondCloth = GetItemAppearance(oItem,
        ITEM_APPR_TYPE_ARMOR_COLOR, ITEM_APPR_ARMOR_COLOR_CLOTH2);

    int nFirstMetal = GetItemAppearance(oItem,
        ITEM_APPR_TYPE_ARMOR_COLOR, ITEM_APPR_ARMOR_COLOR_METAL1);

    int nSecondMetal = GetItemAppearance(oItem,
        ITEM_APPR_TYPE_ARMOR_COLOR, ITEM_APPR_ARMOR_COLOR_METAL2);

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
            AppSetItemColor(oPC, nToken, nFirstLeather, nActive);
            break;
        case ITEM_APPR_ARMOR_COLOR_LEATHER2:
            AppSetItemColor(oPC, nToken, nSecondLeather, nActive);
            break;
        case ITEM_APPR_ARMOR_COLOR_CLOTH1:
            AppSetItemColor(oPC, nToken, nFirstCloth, nActive);
            break;
        case ITEM_APPR_ARMOR_COLOR_CLOTH2:
            AppSetItemColor(oPC, nToken, nSecondCloth, nActive);
            break;
        case ITEM_APPR_ARMOR_COLOR_METAL1:
            AppSetItemColor(oPC, nToken, nFirstMetal, nActive);
            break;
        case ITEM_APPR_ARMOR_COLOR_METAL2:
            AppSetItemColor(oPC, nToken, nSecondMetal, nActive);
            break;
    }
}

//Action: 1(+1) - next, -1 - prev
int AppComboValidate(
    object oPC,
    int nToken,
    string sEntriesBind,
    string sIdBind,
    int nAction)
{
    int nActive = JsonGetInt(NuiGetBind(oPC, nToken, sIdBind));

    json jEntries = NuiGetBind(oPC, nToken, sEntriesBind);
    int nLength = JsonGetLength(jEntries);

    int i;
    for(i = 0; i < nLength; i++)
    {
        json jEntry = JsonArrayGet(jEntries, i);
        int nEntryId = JsonGetInt(JsonArrayGet(jEntry, 1));

        if(nEntryId == nActive)
        {
            break;
        }
    }

    int nId;
    i += nAction;

    if(i >= nLength)
    {
        return JsonGetInt(JsonArrayGet(JsonArrayGet(jEntries, 0), 1));
    }

    if(i < 0)
    {
        return JsonGetInt(JsonArrayGet(JsonArrayGet(jEntries, nLength - 1), 1));
    }

    return JsonGetInt(JsonArrayGet(JsonArrayGet(jEntries, i), 1));
}

json CreateAppItemPicker(
    string sPreviousTooltip = "Previous element",
    string sNextTooltip = "Next element")
{
    json jSpacer = NuiSpacer();
    json jRow = JsonArray();

    json jButtonPrevious = NuiButtonImage(JsonString(APP_ARROW_PREV_BTN));
    jButtonPrevious = NuiId(jButtonPrevious, APP_ITEM_PREVIOUS_BTN);
    jButtonPrevious = NuiWidth(jButtonPrevious, APP_BTN_WIDTH);
    jButtonPrevious = NuiHeight(jButtonPrevious, APP_BTN_HEIGHT);
    jButtonPrevious = NuiTooltip(jButtonPrevious, JsonString(sPreviousTooltip));
    jButtonPrevious = AppSetForegroundColor(jButtonPrevious);

    json jCombo = NuiCombo(
        NuiBind(APP_ITEM_ENTRIES),
        NuiBind(APP_ITEM_ID));
    jCombo = NuiHeight(jCombo, APP_BTN_HEIGHT);

    json jButtonNext = NuiButtonImage(JsonString(APP_ARROW_NEXT_BTN));
    jButtonNext = NuiId(jButtonNext, APP_ITEM_NEXT_BTN);
    jButtonNext = NuiWidth(jButtonNext, APP_BTN_WIDTH);
    jButtonNext = NuiHeight(jButtonNext, APP_BTN_HEIGHT);
    jButtonNext = NuiTooltip(jButtonNext, JsonString(sNextTooltip));
    jButtonNext = AppSetForegroundColor(jButtonNext);

    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jButtonPrevious);
    jRow = JsonArrayInsert(jRow, jCombo);
    jRow = JsonArrayInsert(jRow, jButtonNext);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

string GetItemIconKeyByModelInfo(struct ModelInfo ModelInfo, int nId)
{
    return ModelInfo.sKeyPrefix + IntToPaddedString(nId, 3) + ModelInfo.sKeySuffix;
}

json CreateAppItemPrviews(struct ModelInfo ModelInfo)
{
    float fButtonWidth = 80.0;
    float fButtonHeight = 80.0;

    float fWidth = APP_MAX_ROWS * APP_COLOR_BTN_WIDTH
        + (APP_MAX_ROWS * 4.0);

    float fColumns = fWidth / fButtonWidth;
    int nColumns = FloatToInt(fColumns);
    int nRows = ModelInfo.nLength / nColumns + 1;

    json jSpacer = NuiSpacer();
    json jElements = JsonArray();

    int i;
    for(i=0; i<nRows; i++)
    {
        json jRow = JsonArray();
        jRow = JsonArrayInsert(jRow, jSpacer);

        int j;
        for(j=0; j<nColumns; j++)
        {
            int nIndex = i * nColumns + j;

            if(nIndex >= ModelInfo.nLength)
            {
                break;
            }

            int nModelId = JsonGetInt(JsonArrayGet(ModelInfo.jModelIds, nIndex));

            json jButtonImage = NuiButtonImage(JsonString(GetItemIconKeyByModelInfo(ModelInfo, nModelId)));
            jButtonImage = NuiId(jButtonImage, APP_ITEM_MODEL + IntToString(nIndex));
            jButtonImage = NuiEncouraged(jButtonImage, NuiBind(APP_ITEM_MODEL_ENCOURAGED + IntToString(nIndex)));
            jButtonImage = NuiTooltip(jButtonImage, JsonString("Id: " + IntToString(nModelId)));
            jButtonImage = NuiWidth(jButtonImage, fButtonWidth);
            jButtonImage = NuiHeight(jButtonImage, fButtonHeight);
            jButtonImage = AppSetForegroundColor(jButtonImage);

            jRow = JsonArrayInsert(jRow, jButtonImage);
        }

        jRow = JsonArrayInsert(jRow, jSpacer);

        jElements = JsonArrayInsert(jElements, NuiRow(jRow));
    }

    json jGroup = NuiGroup(NuiCol(jElements), TRUE);
    jGroup = NuiWidth(jGroup, fWidth);
    jGroup = NuiHeight(jGroup, fButtonHeight * 3 + 30.0);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, APP_LEFT_SPACER_WIDTH));
    jRow = JsonArrayInsert(jRow, jGroup);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

struct ModelInfo GetModelInfo(
    object oItem,
    int nResType = RESTYPE_TGA,
    string sKeyPrefix = "i",
    string sKeySuffix = "")
{
    int nBaseType = GetBaseItemType(oItem);
    string sItem = Get2DAString("baseitems", "ItemClass", nBaseType);
    int nAppearance = GetItemAppearance(oItem, ITEM_APPR_TYPE_SIMPLE_MODEL, -1);

    json jModels = JsonArray();
    json jModelIds = JsonArray();

    int nModelCount = StringToInt(Get2DAString("baseitems", "MaxRange", nBaseType));

    int nId = 0;
    int i, nAppId;
    for(i=0; i<nModelCount; i++)
    {
        string sModel = sKeyPrefix + sItem + "_" + IntToPaddedString(i, 3);

        if(ResManGetAliasFor(sModel, nResType) != "")
        {
            jModels = JsonArrayInsert(jModels, NuiComboEntry(IntToString(i), nId++));
            jModelIds = JsonArrayInsert(jModelIds, JsonInt(i));

            if(nAppearance == i)
            {
                nAppId = nId;
            }
        }
    }

    struct ModelInfo ModelInfo;

    ModelInfo.nLength = nId;
    ModelInfo.jModels = jModels;
    ModelInfo.jModelIds = jModelIds;
    ModelInfo.nAppId = nAppId;
    ModelInfo.sKeyPrefix = sKeyPrefix + sItem + "_";
    ModelInfo.sKeySuffix = sKeySuffix;

    return ModelInfo;
}

void EncourageItemModel(
    object oPC,
    int nToken,
    int nModelId)
{
    int nEncouraged = JsonGetInt(NuiGetBind(oPC, nToken, APP_ITEM_MODEL_ENCOURAGED));

    NuiSetBind(oPC, nToken, APP_ITEM_MODEL_ENCOURAGED, JsonInt(nModelId));
    NuiSetBind(oPC, nToken, APP_ITEM_MODEL_ENCOURAGED + IntToString(nEncouraged), JsonBool(FALSE));
    NuiSetBind(oPC, nToken, APP_ITEM_MODEL_ENCOURAGED + IntToString(nModelId), JsonBool(TRUE));
}

//-------------------------------------//
//-------------------------------------//
//---------  1/3 Parts Models  --------//
//-------------------------------------//
//-------------------------------------//
const string APP_ITEM_TOP = "_t_";
const string APP_ITEM_TOP_ENTRIES = "APP_ITEM_TOP_ENTRIES";
const string APP_ITEM_TOP_ID = "APP_ITEM_TOP_ID";
const string APP_ITEM_TOP_COLOR_ENTRIES = "APP_ITEM_TOP_COLOR_ENTRIES";
const string APP_ITEM_TOP_COLOR_ID = "APP_ITEM_TOP_COLOR_ID";
const string APP_ITEM_TOP_NEXT_MODEL_BTN = "APP_ITEM_TOP_NEXT_MODEL_BTN";
const string APP_ITEM_TOP_PREVIOUS_MODEL_BTN = "APP_ITEM_TOP_PREVIOUS_MODEL_BTN";
const string APP_ITEM_TOP_NEXT_COLOR_BTN = "APP_ITEM_TOP_NEXT_COLOR_BTN";
const string APP_ITEM_TOP_PREVIOUS_COLOR_BTN = "APP_ITEM_TOP_PREVIOUS_COLOR_BTN";

const string APP_ITEM_MID = "_m_";
const string APP_ITEM_MID_ENTRIES = "APP_ITEM_MID_ENTRIES";
const string APP_ITEM_MID_ID = "APP_ITEM_MID_ID";
const string APP_ITEM_MID_COLOR_ENTRIES = "APP_ITEM_MID_COLOR_ENTRIES";
const string APP_ITEM_MID_COLOR_ID = "APP_ITEM_MID_COLOR_ID";
const string APP_ITEM_MID_NEXT_MODEL_BTN = "APP_ITEM_MID_NEXT_MODEL_BTN";
const string APP_ITEM_MID_PREVIOUS_MODEL_BTN = "APP_ITEM_MID_PREVIOUS_MODEL_BTN";
const string APP_ITEM_MID_NEXT_COLOR_BTN = "APP_ITEM_MID_NEXT_COLOR_BTN";
const string APP_ITEM_MID_PREVIOUS_COLOR_BTN = "APP_ITEM_MID_PREVIOUS_COLOR_BTN";

const string APP_ITEM_BOTTOM = "_b_";
const string APP_ITEM_BOTTOM_ENTRIES = "APP_ITEM_BOTTOM_ENTRIES";
const string APP_ITEM_BOTTOM_ID = "APP_ITEM_BOTTOM_ID";
const string APP_ITEM_BOTTOM_COLOR_ENTRIES = "APP_ITEM_BOTTOM_COLOR_ENTRIES";
const string APP_ITEM_BOTTOM_COLOR_ID = "APP_ITEM_BOTTOM_COLOR_ID";
const string APP_ITEM_BOTTOM_NEXT_MODEL_BTN = "APP_ITEM_BOTTOM_NEXT_MODEL_BTN";
const string APP_ITEM_BOTTOM_PREVIOUS_MODEL_BTN = "APP_ITEM_BOTTOM_PREVIOUS_MODEL_BTN";
const string APP_ITEM_BOTTOM_NEXT_COLOR_BTN = "APP_ITEM_BOTTOM_NEXT_COLOR_BTN";
const string APP_ITEM_BOTTOM_PREVIOUS_COLOR_BTN = "APP_ITEM_BOTTOM_PREVIOUS_COLOR_BTN";

const string APP_ITEM_IMAGE = "APP_ITEM_IMAGE";

const string APP_ITEM_IMAGE_TOP = "APP_ITEM_IMAGE_TOP";
const string APP_ITEM_IMAGE_MID = "APP_ITEM_IMAGE_MID";
const string APP_ITEM_IMAGE_BOTTOM = "APP_ITEM_IMAGE_BOTTOM";

const string APP_ITEM_BASE_TYPE = "BaseType";
const string APP_ITEM_WEAPON_TYPE = "WeaponType";
const string APP_ITEM_ITEM_CLASS = "ItemClass";
const string APP_ITEM_MODEL_TYPE = "ModelType";
const string APP_ITEM_INFO = "APP_ITEM_INFO";

const string APP_ITEM_SWAP_LAYOUT = "APP_ITEM_SWAP_LAYOUT";

const float APP_ITEM_IMAGE_WIDTH = 100.0;
const float APP_ITEM_IMAGE_HEIGHT = 150.0;

const float APP_ITEM_LABEL_WIDTH = 150.0;
const float APP_ITEM_LABEL_HEIGHT = 50.0;

json CreateAppEmptyFullWidthSpacer()
{
    json jSpacer = NuiSpacer();
    jSpacer = NuiWidth(jSpacer, APP_BACKGROUND_IMAGE_WIDTH);
    jSpacer = NuiHeight(jSpacer, 1.0);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

json CreateAppItem1PartModel(struct ModelInfo ModelInfo)
{
    json jCol = JsonArray();
    //TODO: I am not sure if this is needed
    //jCol = JsonArrayInsert(jCol, CreateAppEmptyFullWidthSpacer());

    jCol = JsonArrayInsert(jCol, CreateAppItemPrviews(ModelInfo));
    jCol = JsonArrayInsert(jCol, CreateAppItemPicker());

    return NuiCol(jCol);
}

void FeedItem1Part(
    object oPC,
    int nToken,
    object oItem,
    struct ModelInfo ModelInfo)
{
    NuiSetBind(oPC, nToken, APP_ITEM_ENTRIES, ModelInfo.jModels);

    int nId = ModelInfo.nAppId - 1;

    int nEncouraged = JsonGetInt(NuiGetBind(oPC, nToken, APP_ITEM_MODEL_ENCOURAGED));
    NuiSetBind(oPC, nToken, APP_ITEM_MODEL_ENCOURAGED + IntToString(nEncouraged), JsonBool(FALSE));

    NuiSetBind(oPC, nToken, APP_ITEM_ID, JsonInt(nId));
    NuiSetBind(oPC, nToken, APP_ITEM_MODEL_ENCOURAGED, JsonInt(nId));
    NuiSetBind(oPC, nToken, APP_ITEM_MODEL_ENCOURAGED + IntToString(nId), JsonBool(TRUE));

    NuiSetBind(oPC, nToken, APP_ITEM_MODELS_ID, ModelInfo.jModelIds);
}

json CreateAppItem3PartLabels()
{
    json jSpacer = NuiSpacer();
    json jRow = JsonArray();

    json jLabelModel = NuiLabel(
        JsonString("Model:"),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jLabelModel = NuiHeight(jLabelModel, APP_ITEM_LABEL_HEIGHT);
    jLabelModel = NuiWidth(jLabelModel, APP_ITEM_LABEL_WIDTH);

    json jLabelColor = NuiLabel(
        JsonString("Color:"),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jLabelColor = NuiHeight(jLabelColor, APP_ITEM_LABEL_HEIGHT);
    jLabelColor = NuiWidth(jLabelColor, APP_ITEM_LABEL_WIDTH);

    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jLabelModel);
    jRow = JsonArrayInsert(jRow, jLabelColor);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiWidth(NuiRow(jRow), APP_BACKGROUND_IMAGE_WIDTH);
}

json CreateAppItemModelButtons(
    string sImage,
    string sId,
    string sTooltip)
{
    json jButton = NuiButtonImage(JsonString(sImage));
    jButton = NuiId(jButton, sId);
    jButton = NuiWidth(jButton, APP_BTN_WIDTH);
    jButton = NuiHeight(jButton, APP_BTN_HEIGHT);
    jButton = NuiTooltip(jButton, JsonString(sTooltip));
    jButton = AppSetForegroundColor(jButton);

    return jButton;
}

json CreateAppItemEntry(
    string sModelTooltip,
    string sColorTooltip,
    string sModelEntries,
    string sModelEntriesId,
    string sColorEntries,
    string sColorEntriesId,
    string sPreviousModelBtn,
    string sNextModelBtn,
    string sPreviousColorBtn,
    string sNextColorBtn)
{
    json jSpacer = NuiSpacer();
    json jRow = JsonArray();

    json jComboTopModel = NuiCombo(
        NuiBind(sModelEntries),
        NuiBind(sModelEntriesId));
    jComboTopModel = NuiHeight(jComboTopModel, APP_BTN_HEIGHT);
    jComboTopModel = NuiWidth(jComboTopModel, 100.0);

    json jComboTopColor = NuiCombo(
        NuiBind(sColorEntries),
        NuiBind(sColorEntriesId));
    jComboTopColor = NuiHeight(jComboTopColor, APP_BTN_HEIGHT);
    jComboTopColor = NuiWidth(jComboTopColor, 100.0);

    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow,
        CreateAppItemModelButtons(APP_ARROW_PREV_BTN, sPreviousModelBtn, "Previous element"));
    jRow = JsonArrayInsert(jRow, jComboTopModel);
    jRow = JsonArrayInsert(jRow,
        CreateAppItemModelButtons(APP_ARROW_NEXT_BTN, sNextModelBtn, "Next element"));
    jRow = JsonArrayInsert(jRow,
        CreateAppItemModelButtons(APP_ARROW_PREV_BTN, sPreviousColorBtn, "Previous color"));
    jRow = JsonArrayInsert(jRow, jComboTopColor);
    jRow = JsonArrayInsert(jRow,
        CreateAppItemModelButtons(APP_ARROW_NEXT_BTN, sNextColorBtn, "Next color"));
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

json CreateAppItemImage()
{
    json jImageList = JsonArray();
    json jImageTop = NuiDrawListImage(
        JsonBool(TRUE),
        NuiBind(APP_ITEM_IMAGE_TOP),
        NuiRect(
            0.0,
            0.0,
            APP_ITEM_IMAGE_WIDTH,
            APP_ITEM_IMAGE_HEIGHT),
        JsonInt(NUI_ASPECT_STRETCH),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_TOP),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

    json jImageMid = NuiDrawListImage(
        JsonBool(TRUE),
        NuiBind(APP_ITEM_IMAGE_MID),
        NuiRect(
            0.0,
            0.0,
            APP_ITEM_IMAGE_WIDTH,
            APP_ITEM_IMAGE_HEIGHT),
        JsonInt(NUI_ASPECT_STRETCH),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_TOP),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

    json jImageBottom = NuiDrawListImage(
        JsonBool(TRUE),
        NuiBind(APP_ITEM_IMAGE_BOTTOM),
        NuiRect(
            0.0,
            0.0,
            APP_ITEM_IMAGE_WIDTH,
            APP_ITEM_IMAGE_HEIGHT),
        JsonInt(NUI_ASPECT_STRETCH),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_TOP),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

    jImageList = JsonArrayInsert(jImageList, jImageTop);
    jImageList = JsonArrayInsert(jImageList, jImageMid);
    jImageList = JsonArrayInsert(jImageList, jImageBottom);

    json jImages = NuiSpacer();
    jImages = NuiWidth(jImages, APP_ITEM_IMAGE_WIDTH);
    jImages = NuiHeight(jImages, APP_ITEM_IMAGE_HEIGHT);
    jImages = NuiDrawList(jImages, JsonBool(FALSE), jImageList);

    json jSpacer = NuiSpacer();

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jImages);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

json CreateAppItem3PartModels()
{
    json jCol = JsonArray();

    jCol = JsonArrayInsert(jCol, CreateAppItem3PartLabels());
    jCol = JsonArrayInsert(jCol,
        CreateAppItemEntry(
            "Top model",
            "Top color",
            APP_ITEM_TOP_ENTRIES,
            APP_ITEM_TOP_ID,
            APP_ITEM_TOP_COLOR_ENTRIES,
            APP_ITEM_TOP_COLOR_ID,
            APP_ITEM_TOP_PREVIOUS_MODEL_BTN,
            APP_ITEM_TOP_NEXT_MODEL_BTN,
            APP_ITEM_TOP_PREVIOUS_COLOR_BTN,
            APP_ITEM_TOP_NEXT_COLOR_BTN));

    jCol = JsonArrayInsert(jCol,
        CreateAppItemEntry(
            "Middle model",
            "Middle color",
            APP_ITEM_MID_ENTRIES,
            APP_ITEM_MID_ID,
            APP_ITEM_MID_COLOR_ENTRIES,
            APP_ITEM_MID_COLOR_ID,
            APP_ITEM_MID_PREVIOUS_MODEL_BTN,
            APP_ITEM_MID_NEXT_MODEL_BTN,
            APP_ITEM_MID_PREVIOUS_COLOR_BTN,
            APP_ITEM_MID_NEXT_COLOR_BTN));

    jCol = JsonArrayInsert(jCol,
        CreateAppItemEntry(
            "Bottom model",
            "Bottom color",
            APP_ITEM_BOTTOM_ENTRIES,
            APP_ITEM_BOTTOM_ID,
            APP_ITEM_BOTTOM_COLOR_ENTRIES,
            APP_ITEM_BOTTOM_COLOR_ID,
            APP_ITEM_BOTTOM_PREVIOUS_MODEL_BTN,
            APP_ITEM_BOTTOM_NEXT_MODEL_BTN,
            APP_ITEM_BOTTOM_PREVIOUS_COLOR_BTN,
            APP_ITEM_BOTTOM_NEXT_COLOR_BTN));

    jCol = JsonArrayInsert(jCol, CreateAppItemImage());

    return NuiCol(jCol);
}

void OffWatch3PartModels(object oPC, int nToken)
{
    NuiSetBindWatch(oPC, nToken, APP_ITEM_TOP_ID, FALSE);
    NuiSetBindWatch(oPC, nToken, APP_ITEM_TOP_COLOR_ID, FALSE);
    NuiSetBindWatch(oPC, nToken, APP_ITEM_MID_ID, FALSE);
    NuiSetBindWatch(oPC, nToken, APP_ITEM_MID_COLOR_ID, FALSE);
    NuiSetBindWatch(oPC, nToken, APP_ITEM_BOTTOM_ID, FALSE);
    NuiSetBindWatch(oPC, nToken, APP_ITEM_BOTTOM_COLOR_ID, FALSE);
}

void OnWatch3PartModels(object oPC, int nToken)
{
    NuiSetBindWatch(oPC, nToken, APP_ITEM_TOP_ID, TRUE);
    NuiSetBindWatch(oPC, nToken, APP_ITEM_TOP_COLOR_ID, TRUE);
    NuiSetBindWatch(oPC, nToken, APP_ITEM_MID_ID, TRUE);
    NuiSetBindWatch(oPC, nToken, APP_ITEM_MID_COLOR_ID, TRUE);
    NuiSetBindWatch(oPC, nToken, APP_ITEM_BOTTOM_ID, TRUE);
    NuiSetBindWatch(oPC, nToken, APP_ITEM_BOTTOM_COLOR_ID, TRUE);
}

string GetItem3PartModelsImage(
    string sItemClass,
    string sPart,
    string sModelId)
{
    string sItemPrefix = "i" + sItemClass;

    return sItemPrefix + sPart
        + IntToPaddedString(StringToInt(sModelId), 3);
}

string GetItemTopImage(string sItemClass, string sModelId)
{
    return GetItem3PartModelsImage(sItemClass, APP_ITEM_TOP, sModelId);
}

string GetItemMidImage(string sItemClass, string sModelId)
{
    return GetItem3PartModelsImage(sItemClass, APP_ITEM_MID, sModelId);
}

string GetItemBottomImage(string sItemClass, string sModelId)
{
    return GetItem3PartModelsImage(sItemClass, APP_ITEM_BOTTOM, sModelId);
}

//sPart - _t_ , _m_ , _b_
void FeedItemPartModels(
    object oPC,
    int nToken,
    int nBaseType,
    string sItem,
    string sNuiModelEntriesName,
    string sNuiColorEntriesName,
    string sPart,
    string sModelPrefix = "",
    int nResType = RESTYPE_MDL)
{
    json jModels = JsonArray();
    json jColors = JsonArray();

    int nModelCount = StringToInt(Get2DAString("baseitems", "MaxRange", nBaseType)) / 10;

    int nColorMax = 0;

    string sModel = sModelPrefix + sItem + sPart;

    int bSaveModel = FALSE;
    int i, j;
    for(i=0; i<nModelCount; i++)
    {
        string sModelId = sModel + IntToPaddedString(i, 2);

        for(j=1; j<10; j++)
        {
            string sModelColor = sModelId + IntToString(j);

            if(ResManGetAliasFor(sModelColor, nResType) != "")
            {
                bSaveModel = TRUE;

                nColorMax = nColorMax < j
                    ? j
                    : nColorMax;
            }
        }

        if(bSaveModel)
        {
            jModels = JsonArrayInsert(jModels, NuiComboEntry(IntToString(i), i));
            bSaveModel = FALSE;
        }
    }

    for(i=1; i<=nColorMax; i++)
    {
        jColors = JsonArrayInsert(jColors, NuiComboEntry(IntToString(i), i));
    }

    NuiSetBind(oPC, nToken, sNuiModelEntriesName, jModels);
    NuiSetBind(oPC, nToken, sNuiColorEntriesName, jColors);
}

void FeedItem3PartModels(
    object oPC,
    object oItem,
    int nToken,
    int nBaseType,
    string sModelPrefix = "",
    int nResType = RESTYPE_MDL)
{
    OffWatch3PartModels(oPC, nToken);

    string sItemClass = Get2DAString("baseitems", "ItemClass", nBaseType);

    //Top
    FeedItemPartModels(
        oPC,
        nToken,
        nBaseType,
        sItemClass,
        APP_ITEM_TOP_ENTRIES,
        APP_ITEM_TOP_COLOR_ENTRIES,
        APP_ITEM_TOP,
        sModelPrefix,
        nResType);

    int nModelTop = GetItemAppearance(oItem, ITEM_APPR_TYPE_WEAPON_MODEL, ITEM_APPR_WEAPON_MODEL_TOP);
    int nModelTopColor = GetItemAppearance(oItem, ITEM_APPR_TYPE_WEAPON_COLOR, ITEM_APPR_WEAPON_COLOR_TOP);
    NuiSetBind(oPC, nToken, APP_ITEM_TOP_ID, JsonInt(nModelTop));
    NuiSetBind(oPC, nToken, APP_ITEM_TOP_COLOR_ID, JsonInt(nModelTopColor));

    //Mid
    FeedItemPartModels(
        oPC,
        nToken,
        nBaseType,
        sItemClass,
        APP_ITEM_MID_ENTRIES,
        APP_ITEM_MID_COLOR_ENTRIES,
        APP_ITEM_MID,
        sModelPrefix,
        nResType);

    int nModelMid = GetItemAppearance(oItem, ITEM_APPR_TYPE_WEAPON_MODEL, ITEM_APPR_WEAPON_MODEL_MIDDLE);
    int nModelMidColor = GetItemAppearance(oItem, ITEM_APPR_TYPE_WEAPON_COLOR, ITEM_APPR_WEAPON_COLOR_MIDDLE);
    NuiSetBind(oPC, nToken, APP_ITEM_MID_ID, JsonInt(nModelMid));
    NuiSetBind(oPC, nToken, APP_ITEM_MID_COLOR_ID, JsonInt(nModelMidColor));

    //Bottom
    FeedItemPartModels(
        oPC,
        nToken,
        nBaseType,
        sItemClass,
        APP_ITEM_BOTTOM_ENTRIES,
        APP_ITEM_BOTTOM_COLOR_ENTRIES,
        APP_ITEM_BOTTOM,
        sModelPrefix,
        nResType);

    int nModelBottom = GetItemAppearance(oItem, ITEM_APPR_TYPE_WEAPON_MODEL, ITEM_APPR_WEAPON_MODEL_BOTTOM);
    int nModelBottomColor = GetItemAppearance(oItem, ITEM_APPR_TYPE_WEAPON_COLOR, ITEM_APPR_WEAPON_COLOR_BOTTOM);
    NuiSetBind(oPC, nToken, APP_ITEM_BOTTOM_ID, JsonInt(nModelBottom));
    NuiSetBind(oPC, nToken, APP_ITEM_BOTTOM_COLOR_ID, JsonInt(nModelBottomColor));

    string sModelTop = IntToString(nModelTop) + IntToString(nModelTopColor);
    string sModelMid = IntToString(nModelMid) + IntToString(nModelMidColor);
    string sModelBottom = IntToString(nModelBottom) + IntToString(nModelBottomColor);

    NuiSetBind(oPC, nToken, APP_ITEM_IMAGE_TOP,
        JsonString(GetItemTopImage(sItemClass, sModelTop)));
    NuiSetBind(oPC, nToken, APP_ITEM_IMAGE_MID,
        JsonString(GetItemMidImage(sItemClass, sModelMid)));
    NuiSetBind(oPC, nToken, APP_ITEM_IMAGE_BOTTOM,
        JsonString(GetItemBottomImage(sItemClass, sModelBottom)));

    OnWatch3PartModels(oPC, nToken);
}

json CreateAppItemSwapLayout()
{
    json jLayout = JsonArray();
    jLayout = NuiRow(jLayout);
    jLayout = NuiGroup(jLayout, FALSE);
    jLayout = NuiHeight(jLayout, 370.0);
    jLayout = NuiId(jLayout, APP_ITEM_SWAP_LAYOUT);

    return jLayout;
}

void AppRightPanelOffEncouraged(object oPC, int nToken)
{
    NuiSetBind(oPC, nToken, APP_HEAD_WINDOW, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, APP_BODY_WINDOW, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, APP_TATOO_WINDOW, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, APP_HELMET_WINDOW, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, APP_ARMOR_WINDOW, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, APP_CLOAK_WINDOW, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, APP_WEAPON_WINDOW, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, APP_SHIELD_WINDOW, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, APP_MISC_WINDOW, JsonBool(FALSE));
}

//-------------------------------------//
//-------------------------------------//
//--------- Button Controller ---------//
//-------------------------------------//
//-------------------------------------//
const string APP_BUTTON_HEAD_ENABLED = "app_head_enabled";
const string APP_BUTTON_BODY_ENABLED = "app_body_enabled";
const string APP_BUTTON_TATOO_ENABLED = "app_tatoo_enabled";
const string APP_BUTTON_HELMET_ENABLED = "app_helmet_enabled";
const string APP_BUTTON_ARMOR_ENABLED = "app_armor_enabled";
const string APP_BUTTON_CLOAK_ENABLED = "app_cloak_enabled";
const string APP_BUTTON_WEAPON_ENABLED = "app_weapon_enabled";
const string APP_BUTTON_SHIELD_ENABLED = "app_shield_enabled";
const string APP_BUTTON_MISC_ENABLED = "app_misc_enabled";

struct ButtonController
{
    int bHeadButton;
    int bBodyButton;
    int bTatooButton;
    int bHelmetButton;
    int bArmorButton;
    int bCloakButton;
    int bWeaponButton;
    int bShieldButton;
    int bMiscButton;
};

struct ButtonController AppReadButtonController(object oArea)
{
    struct ButtonController ButtonController;

    ButtonController.bHeadButton = GetLocalInt(oArea, APP_BUTTON_HEAD_ENABLED);
    ButtonController.bBodyButton = GetLocalInt(oArea, APP_BUTTON_BODY_ENABLED);
    ButtonController.bTatooButton = GetLocalInt(oArea, APP_BUTTON_TATOO_ENABLED);
    ButtonController.bHelmetButton = GetLocalInt(oArea, APP_BUTTON_HELMET_ENABLED);
    ButtonController.bArmorButton = GetLocalInt(oArea, APP_BUTTON_ARMOR_ENABLED);
    ButtonController.bCloakButton = GetLocalInt(oArea, APP_BUTTON_CLOAK_ENABLED);
    ButtonController.bWeaponButton = GetLocalInt(oArea, APP_BUTTON_WEAPON_ENABLED);
    ButtonController.bShieldButton = GetLocalInt(oArea, APP_BUTTON_SHIELD_ENABLED);
    ButtonController.bMiscButton = GetLocalInt(oArea, APP_BUTTON_MISC_ENABLED);

    return ButtonController;
}

#include "lib_app_rotate"
#include "lib_app_head"
#include "lib_app_body"
#include "lib_app_tatoo"
#include "lib_app_helmet"
#include "lib_app_armor"
#include "lib_app_cloak"
#include "lib_app_weapon"
#include "lib_app_shield"
#include "lib_app_misc"

const string APP_RIGHT_PANEL_NUI_EVENT_SCRIPT = "lib_app_panel_ev";

const float APP_IMAGE_WIDTH = 85.0;
const float APP_IMAGE_HEIGHT = 85.0;

const float APP_RIGHT_PANEL_IMAGE_WIDTH = 180.0;
const float APP_RIGHT_PANEL_IMAGE_HEIGHT = 1000.0;

const string APP_RIGHT_IMAGE_SUFIX = "_IMAGE";
const string APP_RIGHT_ENABLED_SUFIX = "_ENABLED";

const string APP_RIGHT_CLOSE_BTN = "APP_RIGHT_CLOSE_BTN";

json AppRightPanelButton(
    json jCol,
    string sWindow,
    string sImage,
    int bEnabled,
    string sTooltip,
    float fWidth,
    float fHeight)
{
    json jSpacer = NuiSpacer();
    json jRow = JsonArray();

    json jButton = NuiButtonImage(JsonString(sImage));
    jButton = NuiId(jButton, sWindow);
    jButton = NuiTooltip(jButton, JsonString(sTooltip));
    jButton = NuiEncouraged(jButton, NuiBind(sWindow));
    jButton = NuiEnabled(jButton, JsonBool(bEnabled));
    jButton = NuiWidth(jButton, fWidth);
    jButton = NuiHeight(jButton, fHeight);
    jButton = AppSetForegroundColor(jButton);

    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jButton);
    jRow = JsonArrayInsert(jRow, jSpacer);

    jCol = JsonArrayInsert(jCol, NuiRow(jRow));

    return jCol;
}

json AppRightPanelCloseButton(
    json jCol,
    float fWidth,
    float fHeight)
{
    json jSpacer = NuiSpacer();
    json jRow = JsonArray();

    json jButton = NuiButtonImage(JsonString("custom_close_nui"));
    jButton = NuiId(jButton, APP_RIGHT_CLOSE_BTN);
    jButton = NuiTooltip(jButton, JsonString("Close"));
    jButton = NuiWidth(jButton, fWidth);
    jButton = NuiHeight(jButton, fHeight);
    jButton = AppSetForegroundColor(jButton);

    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jButton);
    jRow = JsonArrayInsert(jRow, jSpacer);

    jCol = JsonArrayInsert(jCol, NuiRow(jRow));

    return jCol;
}

void CreateAppRightPanelWindow(object oPC, struct ButtonController ButtonController)
{
    int nDeviceWidth = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH);
    int nDeviceHeigt = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT);

    float fScale =
        IntToFloat(nDeviceHeigt) / APP_RIGHT_PANEL_IMAGE_HEIGHT;

    float fHeight = APP_IMAGE_HEIGHT * fScale;
    float fWidth = APP_IMAGE_WIDTH * fScale;

    float fOffset = 10.0;

    float fImageWidth = APP_RIGHT_PANEL_IMAGE_WIDTH * fScale - fOffset;
    float fImageHeight = APP_RIGHT_PANEL_IMAGE_HEIGHT * fScale - fOffset;

    float fWindowWidth = fImageWidth + fOffset;
    float fWindowHeight = IntToFloat(nDeviceHeigt);

    json jSpacer = NuiSpacer();

    json jCol = JsonArray();
    json jRow = JsonArray();
    {
        jRow = JsonArrayInsert(jRow, jSpacer);

        jCol = JsonArrayInsert(jCol, NuiHeight(NuiRow(jRow), 30.0));
    }

    if(ButtonController.bHeadButton)
    {
        jCol = AppRightPanelButton(
            jCol,
            APP_HEAD_WINDOW,
            "cc_head_btn",
            TRUE,
            "Head",
            fWidth,
            fHeight);
    }

    if(ButtonController.bBodyButton)
    {
        jCol = AppRightPanelButton(
            jCol,
            APP_BODY_WINDOW,
            "cc_body_btn",
            TRUE,
            "Body",
            fWidth,
            fHeight);
    }

    if(ButtonController.bTatooButton)
    {
        jCol = AppRightPanelButton(
            jCol,
            APP_TATOO_WINDOW,
            "cc_tato_btn",
            TRUE,
            "Tattoos",
            fWidth,
            fHeight);
    }

    if(ButtonController.bHelmetButton)
    {
        jCol = AppRightPanelButton(
            jCol,
            APP_HELMET_WINDOW,
            "app_helmet",
            HasEquipedHelmet(oPC),
            "Helmet",
            fWidth,
            fHeight);
    }

    if(ButtonController.bArmorButton)
    {
        jCol = AppRightPanelButton(
            jCol,
            APP_ARMOR_WINDOW,
            "app_armor",
            HasEquipedArmor(oPC),
            "Armor",
            fWidth,
            fHeight);
    }

    if(ButtonController.bCloakButton)
    {
        jCol = AppRightPanelButton(
            jCol,
            APP_CLOAK_WINDOW,
            "app_cloak",
            HasEquipedCloak(oPC),
            "Cloak",
            fWidth,
            fHeight);        
    }

    if(ButtonController.bWeaponButton)
    {
        jCol = AppRightPanelButton(
            jCol,
            APP_WEAPON_WINDOW,
            "app_sword",
            HasEquipedWeapon(oPC),
            "Weapon",
            fWidth,
            fHeight);        
    }

    if(ButtonController.bShieldButton)
    {
        jCol = AppRightPanelButton(
            jCol,
            APP_SHIELD_WINDOW,
            "app_shield",
            HasEquipedShield(oPC),
            "Shield",
            fWidth,
            fHeight);
    }

    if(ButtonController.bMiscButton)
    {
        jCol = AppRightPanelButton(
            jCol,
            APP_MISC_WINDOW,
            "app_misc",
            TRUE,
            "Misc",
            fWidth,
            fHeight);        
    }

    jCol = AppRightPanelCloseButton(jCol, fWidth, fHeight);

    jRow = JsonArray();
    {
        jRow = JsonArrayInsert(jRow, jSpacer);

        jCol = JsonArrayInsert(jCol, NuiRow(jRow));
    }

    json jImageList = JsonArray();

    json jImage = NuiDrawListImage(
        JsonBool(TRUE),
        JsonString("cc_right_panel"),
        NuiRect(
            0.0,
            0.0,
            fImageWidth,
            fImageHeight),
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

    int nToken = NuiCreate(oPC, jNui, APP_RIGHT_PANEL_WINDOW, APP_RIGHT_PANEL_NUI_EVENT_SCRIPT);

    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY, NuiRect(
        IntToFloat(nDeviceWidth),
        0.0,
        fWindowWidth,
        fWindowHeight));
    NuiSetBind(oPC, nToken, WINDOW_RESIZABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_CLOSABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_TRANSPARENT, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, WINDOW_BORDER, JsonBool(FALSE));

    AppCreateGeometryWindow(oPC, nDeviceWidth - fWindowWidth);
}

void AppRightPanelEvents(
    string sEventType,
    string sEventElem,
    object oPC,
    int nToken)
{
    if(sEventType == EVENT_TYPE_CLICK)
    {
        if(NuiFindWindow(oPC, sEventElem) > 0)
        {
            return;
        }

        AppDestroyActiveWindow(oPC);

        AppRightPanelOffEncouraged(oPC, nToken);
        NuiSetBind(oPC, nToken, sEventElem, JsonBool(TRUE));

        int nRotateToken = NuiFindWindow(oPC, APP_ROTATE_WINDOW);
        if(nRotateToken > 0)
        {
            NuiDestroy(oPC, nRotateToken);
        }

        object oArea = GetArea(oPC);
        object oPCopy = GetLocalObject(oArea, APP_DRESSING_ROOM_COPY);

        if(sEventElem == APP_HEAD_WINDOW)
        {
            DelayCommand(0.1, UnequipHelmet(oPC, oPCopy, nToken));

            DelayCommand(0.1, CreateAppHeadWindow(oPC));

            SetCameraFace(oPC, oPCopy);

            // CreateAppRotateWindow(oPC);
        }
        else if(sEventElem == APP_BODY_WINDOW)
        {
            DelayCommand(0.1, UnequipVisualItems(oPC, oPCopy, nToken));

            DelayCommand(0.1, CreateAppBodyWindow(oPC));

            SetCameraBody(oPC, oPCopy);

            // CreateAppRotateWindow(oPC);
        }
        else if(sEventElem == APP_TATOO_WINDOW)
        {
            DelayCommand(0.1, UnequipVisualItems(oPC, oPCopy, nToken));

            DelayCommand(0.1, CreateAppTatooWindow(oPC));

            SetCameraBody(oPC, oPCopy);

            // CreateAppRotateWindow(oPC);
        }
        else if(sEventElem == APP_HELMET_WINDOW)
        {
            WearItems(oPC, oPCopy, nToken);
            DelayCommand(0.1, CreateAppHelmetWindow(oPC));

            SetCameraFace(oPC, oPCopy);

            // CreateAppRotateWindow(oPC);
        }
        else if(sEventElem == APP_ARMOR_WINDOW)
        {
            WearItems(oPC, oPCopy, nToken);
            DelayCommand(0.1, CreateAppArmorWindow(oPC));

            SetCameraBody(oPC, oPCopy);

            // CreateAppRotateWindow(oPC);
        }
        else if(sEventElem == APP_CLOAK_WINDOW)
        {
            WearItems(oPC, oPCopy, nToken);
            DelayCommand(0.1, CreateAppCloakWindow(oPC));

            SetCameraBody(oPC, oPCopy);

            // CreateAppRotateWindow(oPC);
        }
        else if(sEventElem == APP_WEAPON_WINDOW)
        {
            WearItems(oPC, oPCopy, nToken);
            DelayCommand(0.1, CreateAppWeaponWindow(oPC));

            SetCameraBody(oPC, oPCopy);

            // CreateAppRotateWindow(oPC);
        }
        else if(sEventElem == APP_SHIELD_WINDOW)
        {
            WearItems(oPC, oPCopy, nToken);
            DelayCommand(0.1, CreateAppShieldWindow(oPC));

            SetCameraBody(oPC, oPCopy);

            // CreateAppRotateWindow(oPC);
        }
        else if(sEventElem == APP_MISC_WINDOW)
        {
            WearItems(oPC, oPCopy, nToken);
            CreateAppMiscWindow(oPC);
        }
        else if(sEventElem == APP_RIGHT_CLOSE_BTN)
        {
            NuiDestroy(oPC, nToken);

            DestroyDressingRoom(oPC);
        }
    }
}

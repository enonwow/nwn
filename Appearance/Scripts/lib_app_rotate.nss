#include "lib_app"

const string APP_ROTATE_WINDOW = "APP_CREATE_ROTATE_WINDOW";
const string APP_ROTATE_NUI_EVENT_SCRIPT = "lib_app_rotate_e";

const string APP_ROTATE_TURN_LEFT_BTN = "APP_ROTATE_TURN_LEFT_BTN";
const string APP_ROTATE_TURN_RIGHT_BTN = "APP_ROTATE_TURN_RIGHT_BTN";
const string APP_ROTATE_ZOOM_IN_BTN = "APP_ROTATE_ZOOM_IN_BTN";
const string APP_ROTATE_ZOOM_OUT_BTN = "APP_ROTATE_ZOOM_OUT_BTN";

const float APP_ROTATE_IMAGE_WIDTH = 60.0;
const float APP_ROTATE_IMAGE_HEIGHT = 60.0;

const float APP_ROTATE_BTN_WIDTH = 42.0;
const float APP_ROTATE_BTN_HEIGHT = 42.0;

json AppRotateCreateBtn(string sId)
{
    json jBtn = NuiButton(JsonString(""));
    jBtn = NuiId(jBtn, sId);
    jBtn = NuiWidth(jBtn, APP_ROTATE_BTN_WIDTH);
    jBtn = NuiHeight(jBtn, APP_ROTATE_BTN_HEIGHT);
    jBtn = AppSetForegroundColor(jBtn);

    return jBtn;
}

void CreateAppRotateWindow(object oPC)
{
    float fSpacerWidth = 10.0;
    json jSpacer = NuiSpacer();

    json jRow = JsonArray();

    json jCol = JsonArray();
    {
        jCol = JsonArrayInsert(jCol, NuiWidth(jSpacer, fSpacerWidth));

        jRow = JsonArrayInsert(jRow, NuiCol(jCol));
    }

    jCol = JsonArray();
    {
        jCol = JsonArrayInsert(jCol, jSpacer);
        jCol = JsonArrayInsert(jCol, AppRotateCreateBtn(APP_ROTATE_TURN_LEFT_BTN));
        jCol = JsonArrayInsert(jCol, jSpacer);

        jRow = JsonArrayInsert(jRow, NuiCol(jCol));
    }

    jCol = JsonArray();
    {
        jCol = JsonArrayInsert(jCol, jSpacer);
        jCol = JsonArrayInsert(jCol, AppRotateCreateBtn(APP_ROTATE_ZOOM_IN_BTN));
        jCol = JsonArrayInsert(jCol, jSpacer);
        jCol = JsonArrayInsert(jCol, AppRotateCreateBtn(APP_ROTATE_ZOOM_OUT_BTN));
        jCol = JsonArrayInsert(jCol, jSpacer);

        jRow = JsonArrayInsert(jRow, NuiCol(jCol));
    }

    jCol = JsonArray();
    {
        jCol = JsonArrayInsert(jCol, jSpacer);
        jCol = JsonArrayInsert(jCol, AppRotateCreateBtn(APP_ROTATE_TURN_RIGHT_BTN));
        jCol = JsonArrayInsert(jCol, jSpacer);

        jRow = JsonArrayInsert(jRow, NuiCol(jCol));
    }

    jCol = JsonArray();
    {
        jCol = JsonArrayInsert(jCol, NuiWidth(jSpacer, fSpacerWidth));

        jRow = JsonArrayInsert(jRow, NuiCol(jCol));
    }

    float offsetWidth = fSpacerWidth * 2;
    float offsetHeight = 130.0;

    float fWindowWidth = APP_ROTATE_IMAGE_WIDTH * 3 + offsetWidth;
    float fWindowHeight = APP_ROTATE_IMAGE_WIDTH * 2 + offsetHeight;

    int nDeviceWidth = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH);
    int nDeviceHeigt = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT);

    float fWindowX = IntToFloat(nDeviceWidth  / 2) - (fWindowWidth / 2);
    float fWindowY = IntToFloat(nDeviceHeigt - 280);

    float fRotateX = (fWindowWidth - APP_ROTATE_BTN_WIDTH) / 2;
    float fRotateY = fWindowHeight / 2;

    json jImageList = JsonArray();

    json jImageTurnLeft = NuiDrawListImage(
        JsonBool(TRUE),
        JsonString("cc_turn_left"),
        NuiRect(
            fSpacerWidth + 12,
            fWindowHeight / 2 - APP_ROTATE_IMAGE_HEIGHT / 2 - 3,
            APP_ROTATE_IMAGE_WIDTH,
            APP_ROTATE_IMAGE_HEIGHT),
        JsonInt(NUI_ASPECT_STRETCH),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

    float fSpacerHeight = (fWindowHeight - (APP_ROTATE_BTN_HEIGHT * 2)) / 3;

    json jImageZoomin = NuiDrawListImage(
        JsonBool(TRUE),
        JsonString("cc_zoomin"),
        NuiRect(
            fSpacerWidth + APP_ROTATE_IMAGE_WIDTH + 3,
            fSpacerHeight - 10,
            APP_ROTATE_IMAGE_WIDTH,
            APP_ROTATE_IMAGE_HEIGHT),
        JsonInt(NUI_ASPECT_STRETCH),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

    json jImageZoomout = NuiDrawListImage(
        JsonBool(TRUE),
        JsonString("cc_zoomout"),
        NuiRect(
            fSpacerWidth + APP_ROTATE_IMAGE_WIDTH + 3,
            fSpacerHeight * 2  + APP_ROTATE_BTN_HEIGHT - 13,
            APP_ROTATE_IMAGE_WIDTH,
            APP_ROTATE_IMAGE_HEIGHT),
        JsonInt(NUI_ASPECT_STRETCH),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

    json jImageTurnRight = NuiDrawListImage(
        JsonBool(TRUE),
        JsonString("cc_turn_right"),
        NuiRect(
            (fSpacerWidth + 10) * 2 + APP_ROTATE_BTN_WIDTH * 2,
            fWindowHeight / 2 - APP_ROTATE_IMAGE_HEIGHT / 2 - 3,
            APP_ROTATE_IMAGE_WIDTH,
            APP_ROTATE_IMAGE_HEIGHT),
        JsonInt(NUI_ASPECT_STRETCH),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

    jImageList = JsonArrayInsert(jImageList, jImageTurnLeft);
    jImageList = JsonArrayInsert(jImageList, jImageZoomin);
    jImageList = JsonArrayInsert(jImageList, jImageZoomout);
    jImageList = JsonArrayInsert(jImageList, jImageTurnRight);

    json jRoot = NuiDrawList(NuiRow(jRow), JsonBool(FALSE), jImageList);

    json jNui = NuiWindow(
        jRoot,
        JsonNull(),
        NuiBind(WINDOW_GEOMETRY),
        NuiBind(WINDOW_RESIZABLE),
        JsonBool(FALSE),
        NuiBind(WINDOW_CLOSABLE),
        NuiBind(WINDOW_TRANSPARENT),
        NuiBind(WINDOW_BORDER));

    int nToken = NuiCreate(oPC, jNui, APP_ROTATE_WINDOW, APP_ROTATE_NUI_EVENT_SCRIPT);

    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY, NuiRect(fWindowX, fWindowY, fWindowWidth, fWindowHeight));
    NuiSetBind(oPC, nToken, WINDOW_RESIZABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_CLOSABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_TRANSPARENT, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, WINDOW_BORDER, JsonBool(FALSE));
}

void AppRotateEvents(
    string sEventType,
    string sEventElem,
    object oPC,
    int nToken)
{
    if(sEventType == EVENT_TYPE_CLICK)
    {
        if(sEventElem == APP_ROTATE_TURN_LEFT_BTN)
        {
            object oArea = GetArea(oPC);
            object oCopyPC = GetLocalObject(oArea, APP_DRESSING_ROOM_COPY);
            RotateObject(oCopyPC, 15.0);
        }
        else if(sEventElem == APP_ROTATE_TURN_RIGHT_BTN)
        {
            object oArea = GetArea(oPC);
            object oCopyPC = GetLocalObject(oArea, APP_DRESSING_ROOM_COPY);
            RotateObject(oCopyPC, -15.0);
        }
        else if(sEventElem == APP_ROTATE_ZOOM_IN_BTN)
        {
            SetCameraZoom(oPC, -0.25);
        }
        else if(sEventElem == APP_ROTATE_ZOOM_OUT_BTN)
        {
            SetCameraZoom(oPC, 0.25);
        }
    }
}

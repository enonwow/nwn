#include "lib_nui"

//--------------------------------//
//--------------------------------//
//------- NUI POPUP LABEL --------//
//--------------------------------//
//--------------------------------//
const string POPUP_LABEL_WINDOW = "POPUP_LABEL_WINDOW";

json CreateLabel(string sText)
{
    json jLabel = NuiLabel(
        JsonString(sText),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_TOP));

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jLabel);

    return jRow;
}

void CreateLabelPopup(
    object oPC,
    string sText,
    float fTimeToDestroy = 6.0)
{
    float fWindowW = GetStringLength(sText) * 8 + 30.0;
    float fWindowH = 50.0;

    float fWindowX = (GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH) / 2.0) - (fWindowW / 2.0);
    float fWindowY = -1.0;

    json jRoot = NuiRow(CreateLabel(sText));

    json jGeometry = NuiRect(fWindowX ,fWindowY, fWindowW, fWindowH);

    json jNui = NuiWindow(
        jRoot,
        NuiBind(WINDOW_TITLE),
        NuiBind(WINDOW_GEOMETRY),
        NuiBind(WINDOW_RESIZABLE),
        JsonBool(FALSE),
        NuiBind(WINDOW_CLOSABLE),
        NuiBind(WINDOW_TRANSPARENT),
        NuiBind(WINDOW_BORDER));

    int nToken = NuiCreate(oPC, jNui, POPUP_LABEL_WINDOW);

    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY, jGeometry);
    NuiSetBind(oPC, nToken, WINDOW_TITLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_RESIZABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_CLOSABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_TRANSPARENT, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, WINDOW_BORDER, JsonBool(FALSE));

    AssignCommand(oPC, DelayCommand(fTimeToDestroy, NuiDestroy(oPC, nToken)));
}

//--------------------------------//
//--------------------------------//
//---------- NUI POPUP -----------//
//--------------------------------//
//--------------------------------//
const string POPUP_CLOSE_BUTTON = "POPUP_CLOSE_BUTTON";

const float POPUP_BUTTON_WIDTH = 50.0;
const float POPUP_BUTTON_HEIGHT = 50.0;

const float POPUP_WINDOW_WIDTH = 500.0;
const float POPUP_WINDOW_HEIGHT = 500.0;

const string POPUP_WINDOW = "POPUP_WINDOW";
const string POPUP_NUI_EVENT_SCRIPT = "lib_popup_ev";

json CreatePopupSpace(float fWidth = 0.0)
{
    json jSpacer = NuiSpacer();

    if(fWidth > 0.0)
    {
        jSpacer = NuiHeight(jSpacer, fWidth);
    }

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

json CreatePopupContent(string sText, int bCloseButton = TRUE)
{
    float fHeightButtonOffset = bCloseButton ? POPUP_BUTTON_HEIGHT : 0.0;

    json jText = NuiText(JsonString(sText), FALSE, NUI_SCROLLBARS_AUTO);
    jText = NuiWidth(jText, POPUP_WINDOW_WIDTH - 80.0);
    jText = NuiHeight(jText, POPUP_WINDOW_HEIGHT -
        (fHeightButtonOffset + 100.0));

    json jSpacer = NuiSpacer();

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiWidth(jSpacer, 35.0));
    jRow = JsonArrayInsert(jRow, jText);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

json CreatePopupButtons()
{
    json jButtonClose = NuiButtonImage(JsonString("custom_close_nui"));
    jButtonClose = NuiId(jButtonClose, POPUP_CLOSE_BUTTON);
    jButtonClose = NuiWidth(jButtonClose, POPUP_BUTTON_WIDTH);
    jButtonClose = NuiHeight(jButtonClose, POPUP_BUTTON_HEIGHT);
    jButtonClose = NuiTooltip(jButtonClose, JsonString("Close"));

    json jSpacer = NuiSpacer();

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jButtonClose);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

json AddBackgroundImage(
    json jImageList,
    string sImage,
    float fWindowWidth,
    float fWindowHeight)
{
    json jBackground = NuiDrawListImage(
        JsonBool(TRUE),
        JsonString(sImage),
        NuiRect(0.0, 0.0, fWindowWidth, fWindowHeight),
        JsonInt(NUI_ASPECT_STRETCH),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE),
        NUI_DRAW_LIST_ITEM_ORDER_BEFORE,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

    jImageList = JsonArrayInsert(jImageList, jBackground);

    return jImageList;
}

void CreatePopup(
    object oPC,
    string sText,
    int bCloseButton = TRUE,
    float fTimeToDestroy = 6.0)
{
    int nToken = NuiFindWindow(oPC, POPUP_WINDOW);
    if (nToken != 0)
    {
        return;
    }

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, CreatePopupSpace(40.0));
    jCol = JsonArrayInsert(jCol, CreatePopupContent(sText, bCloseButton));
    jCol = JsonArrayInsert(jCol, CreatePopupSpace());

    if(bCloseButton)
    {
        jCol = JsonArrayInsert(jCol, CreatePopupButtons());
        jCol = JsonArrayInsert(jCol, CreatePopupSpace(20.0));
    }

    json jImageList = JsonArray();
    jImageList = AddBackgroundImage(jImageList, "popoup_bg", POPUP_WINDOW_WIDTH, POPUP_WINDOW_HEIGHT);

    json jRoot = NuiDrawList(NuiCol(jCol), JsonBool(FALSE), jImageList);

    json jNui = NuiWindow(
        jRoot,
        NuiBind(WINDOW_TITLE),
        NuiBind(WINDOW_GEOMETRY),
        NuiBind(WINDOW_RESIZABLE),
        JsonBool(FALSE),
        NuiBind(WINDOW_CLOSABLE),
        NuiBind(WINDOW_TRANSPARENT),
        NuiBind(WINDOW_BORDER));

    nToken = NuiCreate(oPC, jNui, POPUP_WINDOW, POPUP_NUI_EVENT_SCRIPT);

    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY, NuiRect(-1.0, -1.0, POPUP_WINDOW_WIDTH, POPUP_WINDOW_HEIGHT));
    NuiSetBind(oPC, nToken, WINDOW_TITLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_RESIZABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_CLOSABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_TRANSPARENT, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, WINDOW_BORDER, JsonBool(FALSE));

    AssignCommand(oPC, DelayCommand(fTimeToDestroy, NuiDestroy(oPC, nToken)));
}

//--------------------------------//
//--------------------------------//
//----- NUI POPUP CONROLLER ------//
//--------------------------------//
//--------------------------------//
const string POPUP_CONTROLLER_SELCTED_TYPE = "POPUP_CONTROLLER_SELCTED_TYPE";
const string POPUP_CONTROLLER_SELCTED_AREA_TYPE = "POPUP_CONTROLLER_SELCTED_AREA_TYPE";

const string POPUP_CONTROLLER_TEXT = "POPUP_CONTROLLER_TEXT";

const string POPUP_CONTROLLER_DELAY = "POPUP_CONTROLLER_DELAY";

const string POPUP_CONTROLLER_SEND_MESSAGE_ENABLED = "POPUP_CONTROLLER_SEND_MESSAGE_ENABLED";

const string POPUP_CONTROLLER_SEND_MESSAGE_BUTTON = "POPUP_CONTROLLER_SEND_MESSAGE_BUTTON";
const string POPUP_CONTROLLER_CLOSE_BUTTON = "POPUP_CONTROLLER_CLOSE_BUTTON";

const float POPUP_CONTROLLER_WINDOW_WIDTH = 500.0;
const float POPUP_CONTROLLER_WINDOW_HEIGHT = 500.0;

const string POPUP_CONTROLLER_WINDOW = "POPUP_CONTROLLER_WINDOW";

json CreatePopupControllerDropdown()
{
    json jTypeEntries = JsonArray();
    jTypeEntries = JsonArrayInsert(jTypeEntries, NuiComboEntry("Choose Popup Type", 0));
    jTypeEntries = JsonArrayInsert(jTypeEntries, NuiComboEntry("Label Popup", 1));
    jTypeEntries = JsonArrayInsert(jTypeEntries, NuiComboEntry("Content Popup with close button", 2));
    jTypeEntries = JsonArrayInsert(jTypeEntries, NuiComboEntry("Content Popup without close button", 3));

    json jTypeDropdown = NuiCombo(jTypeEntries, NuiBind(POPUP_CONTROLLER_SELCTED_TYPE));
    jTypeDropdown = NuiWidth(jTypeDropdown, 200.0);
    jTypeDropdown = NuiHeight(jTypeDropdown, 50.0);

    json jAreaTypeEntries = JsonArray();
    jAreaTypeEntries = JsonArrayInsert(jAreaTypeEntries, NuiComboEntry("Choose Area Type", 0));
    jAreaTypeEntries = JsonArrayInsert(jAreaTypeEntries, NuiComboEntry("Module", 1));
    jAreaTypeEntries = JsonArrayInsert(jAreaTypeEntries, NuiComboEntry("Current Area", 2));

    json jAreaTypeDropdown = NuiCombo(jAreaTypeEntries, NuiBind(POPUP_CONTROLLER_SELCTED_AREA_TYPE));
    jAreaTypeDropdown = NuiWidth(jAreaTypeDropdown, 200.0);
    jAreaTypeDropdown = NuiHeight(jAreaTypeDropdown, 50.0);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jTypeDropdown);
    jRow = JsonArrayInsert(jRow, jAreaTypeDropdown);

    return NuiRow(jRow);
}

json CreatePopupControllerContent()
{
    json jTextEdit = NuiTextEdit(
        JsonString("Your text here"),
        NuiBind(POPUP_CONTROLLER_TEXT),
        500,
        TRUE);
    jTextEdit = NuiWidth(jTextEdit, 450.0);
    jTextEdit = NuiHeight(jTextEdit, 250.0);

    json jSpacer = NuiSpacer();

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jTextEdit);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

json CreatePopupControllerDelay()
{
    json jTextEdit = NuiTextEdit(
        JsonString("Delayed NUI destroy"),
        NuiBind(POPUP_CONTROLLER_DELAY),
        2,
        FALSE);
    jTextEdit = NuiWidth(jTextEdit, 450.0);
    jTextEdit = NuiHeight(jTextEdit, 50.0);

    json jSpacer = NuiSpacer();

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jTextEdit);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

json CreatePopupControllerButtons()
{
    json jButtonCreate = NuiButton(JsonString("Send message"));
    jButtonCreate = NuiId(jButtonCreate, POPUP_CONTROLLER_SEND_MESSAGE_BUTTON);
    jButtonCreate = NuiEnabled(jButtonCreate, NuiBind(POPUP_CONTROLLER_SEND_MESSAGE_ENABLED));

    json jButtonClose = NuiButton(JsonString("Close"));
    jButtonClose = NuiId(jButtonClose, POPUP_CONTROLLER_CLOSE_BUTTON);

    json jSpacer = NuiSpacer();

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jButtonCreate);
    jRow = JsonArrayInsert(jRow, jSpacer);
    jRow = JsonArrayInsert(jRow, jButtonClose);
    jRow = JsonArrayInsert(jRow, jSpacer);

    return NuiRow(jRow);
}

void CreatePopupControllerWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, POPUP_CONTROLLER_WINDOW);
    if (nToken != 0)
    {
        return;
    }

    json jCol = JsonArray();
    // jCol = JsonArrayInsert(jCol, CreatePopupSpace(30.0));
    jCol = JsonArrayInsert(jCol, CreatePopupControllerDropdown());
    jCol = JsonArrayInsert(jCol, CreatePopupControllerContent());
    jCol = JsonArrayInsert(jCol, CreatePopupControllerDelay());
    jCol = JsonArrayInsert(jCol, CreatePopupControllerButtons());
    jCol = JsonArrayInsert(jCol, CreatePopupSpace());

    json jRoot = NuiCol(jCol);

    json jNui = NuiWindow(
        jRoot,
        NuiBind(WINDOW_TITLE),
        NuiBind(WINDOW_GEOMETRY),
        NuiBind(WINDOW_RESIZABLE),
        NuiBind(WINDOW_COLLAPSED),
        NuiBind(WINDOW_CLOSABLE),
        NuiBind(WINDOW_TRANSPARENT),
        NuiBind(WINDOW_BORDER));

    nToken = NuiCreate(oPC, jNui, POPUP_CONTROLLER_WINDOW, POPUP_NUI_EVENT_SCRIPT);

    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY, NuiRect(-1.0, -1.0, POPUP_CONTROLLER_WINDOW_WIDTH, POPUP_CONTROLLER_WINDOW_HEIGHT));
    NuiSetBind(oPC, nToken, WINDOW_TITLE, JsonString("Popup Controller"));
    NuiSetBind(oPC, nToken, WINDOW_RESIZABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_COLLAPSED, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_CLOSABLE, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, WINDOW_TRANSPARENT, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_BORDER, JsonBool(TRUE));

    NuiSetBindWatch(oPC, nToken, POPUP_CONTROLLER_SELCTED_TYPE, TRUE);
    NuiSetBindWatch(oPC, nToken, POPUP_CONTROLLER_SELCTED_AREA_TYPE, TRUE);
}

void SendMessageToModule(
    object oPC,
    int nPopupType,
    string sText,
    float fTimeToDestroy)
{
    object oPCTarget = GetFirstPC();
    while(GetIsObjectValid(oPCTarget))
    {
        if(oPCTarget != oPC)
        {
            switch(nPopupType)
            {
                case 1:
                    CreateLabelPopup(oPCTarget, sText, fTimeToDestroy);
                    break;
                case 2:
                    CreatePopup(oPCTarget, sText, TRUE, fTimeToDestroy);
                    break;
                case 3:
                    CreatePopup(oPCTarget, sText, FALSE, fTimeToDestroy);
                    break;
            }
        }

        oPCTarget = GetNextPC();
    }
}

void SendMessageToCurrentArea(
    object oPC,
    int nPopupType,
    string sText,
    float fTimeToDestroy)
{
    object oArea = GetArea(oPC);

    object oPCTarget = GetFirstObjectInArea(oArea, OBJECT_TYPE_CREATURE);
    while(GetIsObjectValid(oPCTarget))
    {
        if(GetIsPC(oPCTarget) && oPCTarget != oPC)
        {
            switch(nPopupType)
            {
                case 1:
                    CreateLabelPopup(oPCTarget, sText, fTimeToDestroy);
                    break;
                case 2:
                    CreatePopup(oPCTarget, sText, TRUE, fTimeToDestroy);
                    break;
                case 3:
                    CreatePopup(oPCTarget, sText, FALSE, fTimeToDestroy);
                    break;
            }
        }

        oPCTarget = GetNextObjectInArea(oArea, OBJECT_TYPE_CREATURE);
    }
}

void SendPopupMessage(object oPC, int nToken)
{
    int nSelectedType = JsonGetInt(
        NuiGetBind(oPC, nToken, POPUP_CONTROLLER_SELCTED_TYPE));

    int nSelectedAreaType = JsonGetInt(
        NuiGetBind(oPC, nToken, POPUP_CONTROLLER_SELCTED_AREA_TYPE));

    string sText = JsonGetString(NuiGetBind(oPC, nToken, POPUP_CONTROLLER_TEXT));

    string sDelay = JsonGetString(NuiGetBind(oPC, nToken, POPUP_CONTROLLER_DELAY));
    float fDelay = StringToFloat(sDelay);

    if(fDelay == 0.0)
    {
        fDelay = 6.0;
    }

    switch(nSelectedAreaType)
    {
        case 1:
            SendMessageToModule(oPC, nSelectedType, sText, fDelay);
            break;
        case 2:
            SendMessageToCurrentArea(oPC, nSelectedType, sText, fDelay);
            break;
    }
}

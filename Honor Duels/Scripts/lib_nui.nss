#include "nw_inc_nui"
#include "lib_nui_utility"

const string LABEL_WINDOW = "LABEL_WINDOW";
const string STATMENT = "STATMENT";
const string GEOMETRY = "GEOMETRY";
const string CLOSE = "CLOSE";
const string ENABLED = "ENABLED";

const string PROGRESS = "PROGRESS";
const string COLORBAR = "COLORBAR";
const string TOOLTIP = "TOOLTIP";

const string TIMER_WINDOW = "TIMER_WINDOW";
const string STARTING_MINUTES = "STARTING MINUTES";
const string MINUTES = "MINUTES";
const string SECONDS = "SECONDS";

const string EVENT_TYPE_WATCH = "watch";
const string EVENT_TYPE_OPEN = "open";
const string EVENT_TYPE_CLOSE = "close";
const string EVENT_TYPE_CLICK = "click";
const string EVENT_TYPE_MOUSEUP = "mouseup";
const string EVENT_TYPE_MOUSEDOWN = "mousedown";
const string EVENT_TYPE_MOUSESCROLL = "mousescroll";
const string EVENT_TYPE_RANGE = "range";
const string EVENT_TYPE_FOCUS = "focus";
const string EVENT_TYPE_BLUR = "blur";

const string WINDOW_TITLE = "title";
const string WINDOW_GEOMETRY = "geometry";
const string WINDOW_RESIZABLE = "resizable";
const string WINDOW_COLLAPSED = "collapsed";
const string WINDOW_CLOSABLE = "closable";
const string WINDOW_TRANSPARENT = "transparent";
const string WINDOW_BORDER = "border";

const int EVENT_BUTTON_LEFT = 0;
const int EVENT_BUTTON_MIDDLE = 1;
const int EVENT_BUTTON_RIGHT = 2;

const string NUI_INFO_BUTTON_ID = "NUI_INFO_BUTTON_ID";
const string NUI_INFO_IMAGE = "information64";
const float NUI_INFO_IMAGE_WIDTH = 64.0;
const float NUI_INFO_IMAGE_HEIGHT = 64.0;
const string NUI_INFO_WINDOW = "NUI_INFO_WINDOW";
const string NUI_INFO_NUI_EVENT_SCRIPT = "lib_nui_ev";
const string NUI_INFO_MODAL_WINDOW = "NUI_INFO_MODAL_WINDOW";
const string NUI_INFO_MODAL_OBJECT_UUID = "NUI_INFO_MODAL_OBJECT_UUID";
const string NUI_INFO_MODAL_INT = "NUI_INFO_MODAL_INT";
const string NUI_INFO_MODAL_OBJECTS = "NUI_INFO_MODAL_OBJECTS";
const string NUI_GIF_WINDOW = "NUI_GIF_WINDOW";

// GetNuiScaleDimension(oPC, fDimension, fScaleMax=1.5) — scales widget dimensions by player's GUI scale
float GetNuiScaleDimension(object oPC, float fDemension, float fScaleMax = 1.5)
{
    int nScaleGui = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_SCALE);
    float fScaleGui = nScaleGui / 100.0;
    fScaleGui = fScaleGui > fScaleMax ? fScaleMax : fScaleGui;
    return (fDemension / fScaleGui);
}

// CreateEmptyRow(oPC, fHeight) — fixed-height spacer row (scale-aware)
json CreateEmptyRow(object oPC, float fHeight, float fScaleMax = 1.5)
{
    json jRow = JsonArray();
    if(fHeight <= 0.0)
        jRow = JsonArrayInsert(jRow, NuiSpacer());
    else
        jRow = JsonArrayInsert(jRow, NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, fHeight)));
    return NuiRow(jRow);
}

json GetNuiColorNwnGold()
{
    return NuiColor(185, 150, 100);
}

// NuiAddInfoRow() — returns a row with an info button (?) to attach to a title row
json NuiAddInfoRow()
{
    float fButtonWidth = NUI_INFO_IMAGE_WIDTH - 30.0;
    float fButtonHeight = NUI_INFO_IMAGE_HEIGHT - 15.0;
    json jRow = JsonArray();
    json jButton = NuiId(NuiButton(JsonString("")), NUI_INFO_BUTTON_ID);
    jButton = NuiWidth(jButton, fButtonWidth);
    jButton = NuiHeight(jButton, fButtonHeight);
    jButton = NuiTooltip(jButton, JsonString("Click for more information."));
    jRow = JsonArrayInsert(jRow, NuiHeight(NuiSpacer(), fButtonWidth));
    jRow = JsonArrayInsert(jRow, jButton);
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), 15.0));
    return NuiRow(jRow);
}

// NuiAddInfoImage(fWindowWidth, jImageList, nImageWidthOffset) — dodaje ikone info do DrawList
json NuiAddInfoImage(float fWindowWidth, json jImageList, float nImageWidthOffset)
{
    json jImageInfo = NuiDrawListImage(
        JsonBool(TRUE), JsonString(NUI_INFO_IMAGE),
        NuiRect(fWindowWidth - (NUI_INFO_IMAGE_WIDTH + nImageWidthOffset), 0.0, NUI_INFO_IMAGE_WIDTH, NUI_INFO_IMAGE_HEIGHT),
        JsonInt(NUI_ASPECT_STRETCH), JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);
    return JsonArrayInsert(jImageList, jImageInfo);
}

// CreateWindowInfo(oPC, sStatment) — opens an info window (500x400) with text and a Close button
// Obslugiwane przez lib_nui_ev.nss (NUI_INFO_NUI_EVENT_SCRIPT)
void CreateWindowInfo(object oPC, string sStatment);

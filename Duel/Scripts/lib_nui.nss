// lib_nui.nss
// Stripped-down NUI helper library for Honor Duels demo.
// Self-contained: depends only on nw_inc_nui (base game).
// No NWNX, no lib_nui_utility.
#include "nw_inc_nui"

// ============================================================
// Event type strings (NuiGetEventType)
// https://nwnlexicon.com/index.php/NuiGetEventType
// ============================================================
const string EVENT_TYPE_WATCH       = "watch";
const string EVENT_TYPE_OPEN        = "open";
const string EVENT_TYPE_CLOSE       = "close";
const string EVENT_TYPE_CLICK       = "click";
const string EVENT_TYPE_MOUSEUP     = "mouseup";
const string EVENT_TYPE_MOUSEDOWN   = "mousedown";
const string EVENT_TYPE_MOUSESCROLL = "mousescroll";
const string EVENT_TYPE_RANGE       = "range";
const string EVENT_TYPE_FOCUS       = "focus";
const string EVENT_TYPE_BLUR        = "blur";

// ============================================================
// Window bind names (used for NuiBind in NuiWindow construction)
// ============================================================
const string WINDOW_TITLE       = "title";
const string WINDOW_GEOMETRY    = "geometry";
const string WINDOW_RESIZABLE   = "resizable";
const string WINDOW_COLLAPSED   = "collapsed";
const string WINDOW_CLOSABLE    = "closable";
const string WINDOW_TRANSPARENT = "transparent";
const string WINDOW_BORDER      = "border";

const int EVENT_BUTTON_LEFT   = 0;
const int EVENT_BUTTON_MIDDLE = 1;
const int EVENT_BUTTON_RIGHT  = 2;

// ============================================================
// Scale-aware dimensions
// ============================================================

// GetNuiScaleDimension(oPC, fDimension, fScaleMax=1.5) -
// scales widget dimensions according to player's GUI scale setting.
// Use only for INSIDE widgets, not for window-level geometry pulled
// from screen pixel dimensions (those are raw px and should not be scaled).
float GetNuiScaleDimension(object oPC, float fDimension, float fScaleMax = 1.5)
{
    int nScaleGui = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_SCALE);
    float fScaleGui = nScaleGui / 100.0;
    if(fScaleGui > fScaleMax) fScaleGui = fScaleMax;
    return (fDimension / fScaleGui);
}

// CreateEmptyRow(oPC, fHeight) - fixed-height spacer row (scale-aware).
// Pass fHeight <= 0 to get an elastic spacer instead.
json CreateEmptyRow(object oPC, float fHeight, float fScaleMax = 1.5)
{
    json jRow = JsonArray();
    if(fHeight <= 0.0)
        jRow = JsonArrayInsert(jRow, NuiSpacer());
    else
        jRow = JsonArrayInsert(jRow,
            NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, fHeight, fScaleMax)));
    return NuiRow(jRow);
}

// Project gold accent color.
json GetNuiColorNwnGold()
{
    return NuiColor(185, 150, 100);
}

// ============================================================
// Info button + info popup window
// ============================================================
const string NUI_INFO_BUTTON_ID        = "NUI_INFO_BUTTON_ID";
const string NUI_INFO_IMAGE            = "information64";
const float  NUI_INFO_IMAGE_WIDTH      = 64.0;
const float  NUI_INFO_IMAGE_HEIGHT     = 64.0;
const string NUI_INFO_WINDOW           = "NUI_INFO_WINDOW";
const string NUI_INFO_NUI_EVENT_SCRIPT = "lib_nui_ev";

// NuiAddInfoRow() - returns a row containing the (?) info button.
// Insert into the title row of any window to give players a help button.
json NuiAddInfoRow()
{
    float fButtonWidth  = NUI_INFO_IMAGE_WIDTH  - 30.0;
    float fButtonHeight = NUI_INFO_IMAGE_HEIGHT - 15.0;

    json jButton = NuiId(NuiButton(JsonString("")), NUI_INFO_BUTTON_ID);
    jButton = NuiWidth(jButton, fButtonWidth);
    jButton = NuiHeight(jButton, fButtonHeight);
    jButton = NuiTooltip(jButton, JsonString("Click for more information."));

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiHeight(NuiSpacer(), fButtonWidth));
    jRow = JsonArrayInsert(jRow, jButton);
    jRow = JsonArrayInsert(jRow, NuiWidth(NuiSpacer(), 15.0));
    return NuiRow(jRow);
}

// NuiAddInfoImage(fWindowWidth, jImageList, nImageWidthOffset) -
// adds the info icon to a DrawList image array.
json NuiAddInfoImage(float fWindowWidth, json jImageList, float nImageWidthOffset)
{
    json jImageInfo = NuiDrawListImage(
        JsonBool(TRUE),
        JsonString(NUI_INFO_IMAGE),
        NuiRect(
            fWindowWidth - (NUI_INFO_IMAGE_WIDTH + nImageWidthOffset),
            0.0,
            NUI_INFO_IMAGE_WIDTH,
            NUI_INFO_IMAGE_HEIGHT),
        JsonInt(NUI_ASPECT_STRETCH),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);
    return JsonArrayInsert(jImageList, jImageInfo);
}

// CreateWindowInfo(oPC, sStatement) - opens a 500x400 info window with text
// and a Close button. Handled by lib_nui_ev.nss (NUI_INFO_NUI_EVENT_SCRIPT).
const string CLOSE = "CLOSE";

void CreateWindowInfo(object oPC, string sStatement)
{
    float fWindowW = 500.0;
    float fWindowH = 400.0;

    // Body row with the text.
    json jTextRow = JsonArray();
    json jText = NuiText(JsonString(sStatement));
    jText = NuiWidth(jText, fWindowW - 25.0);
    jText = NuiHeight(jText, fWindowH - 110.0);
    jTextRow = JsonArrayInsert(jTextRow, jText);

    // Close button row.
    json jBtnRow = JsonArray();
    json jButton = NuiId(NuiButton(JsonString("Close")), CLOSE);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());
    jBtnRow = JsonArrayInsert(jBtnRow, jButton);
    jBtnRow = JsonArrayInsert(jBtnRow, NuiSpacer());

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTextRow));
    jCol = JsonArrayInsert(jCol, NuiRow(jBtnRow));

    json jRoot = NuiCol(jCol);

    json jNui = NuiWindow(jRoot,
        JsonString("Information"),
        NuiBind(WINDOW_GEOMETRY),
        NuiBind(WINDOW_RESIZABLE),
        NuiBind(WINDOW_COLLAPSED),
        NuiBind(WINDOW_CLOSABLE),
        NuiBind(WINDOW_TRANSPARENT),
        NuiBind(WINDOW_BORDER));

    int nToken = NuiCreate(oPC, jNui, NUI_INFO_WINDOW, NUI_INFO_NUI_EVENT_SCRIPT);

    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY,    NuiRect(-1.0, -1.0, fWindowW, fWindowH));
    NuiSetBind(oPC, nToken, WINDOW_RESIZABLE,   JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_COLLAPSED,   JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_CLOSABLE,    JsonBool(TRUE));
    NuiSetBind(oPC, nToken, WINDOW_TRANSPARENT, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_BORDER,      JsonBool(TRUE));
}

#include "nw_inc_nui"

const string RIBBON_TEXT = "RIBBON_TEXT";

const int RIBBON_ORIGINAL_WIDTH = 846;
const int RIBBON_ORIGINAL_HEIGHT = 250;

float RIBBON_WIDTH = RIBBON_ORIGINAL_WIDTH / 2.0;
float RIBBON_HEIGHT = RIBBON_ORIGINAL_HEIGHT / 2.0;

const string RIBBON_WINDOW = "RIBBON_WINDOW";

void CreateRibbonWindow(object oPC, string sText)
{
    int nToken = NuiFindWindow(oPC, RIBBON_WINDOW);
    if(nToken > 0)
    {
        return;
    }

    int nDeviceWidth = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH);
    int nDeviceHeigt = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT);

    float fWindowX = (nDeviceWidth - RIBBON_WIDTH) / 2.0;
    float fWindowY = 0.0;

    json jSpacer = NuiSpacer();

    json jImageList = JsonArray();

    json jImage = NuiDrawListImage(
        JsonBool(TRUE),
        JsonString("ribbon"),
        NuiRect(
            0.0,
            0.0,
            RIBBON_WIDTH,
            RIBBON_HEIGHT),
        JsonInt(NUI_ASPECT_STRETCH),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_TOP),
        NUI_DRAW_LIST_ITEM_ORDER_BEFORE,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

    int nTextLength = GetStringLength(sText);
    int nTextX = nTextLength * 7;
    float fTextWidth = nTextLength * 8.0;

    json jRect = NuiRect(
        (RIBBON_WIDTH - nTextX) / 2,
        RIBBON_HEIGHT / 4.5,
        fTextWidth,
        15.0);

    json jText = NuiDrawListText(
        JsonBool(TRUE),
        NuiColor(255, 255, 255),
        jRect,
        JsonString(sText),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS);

    jImageList = JsonArrayInsert(jImageList, jImage);
    jImageList = JsonArrayInsert(jImageList, jText);

    json jRoot = NuiDrawList(jSpacer, JsonBool(FALSE), jImageList);

    json jNui = NuiWindow(
        jRoot,
        JsonNull(),
        NuiRect(
            fWindowX,
            fWindowY,
            RIBBON_WIDTH + 15.0,
            RIBBON_HEIGHT + 15.0),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    nToken = NuiCreate(oPC, jNui, RIBBON_WINDOW);

    DelayCommand(5.0, NuiDestroy(oPC, nToken));
}

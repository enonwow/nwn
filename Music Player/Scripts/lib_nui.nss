#include "nw_inc_nui"

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

//--------------------------------//
//--------------------------------//
//---------- Encouraged ----------//
//--------------------------------//
//--------------------------------//
const string NUI_DATA_ENCOURAGED = "NUI_DATA_ENCOURAGED";
const string NUI_DATA_CELL = "NUI_DATA_CELL";
const string NUI_DATA_ROW = "NUI_DATA_ROW";

void NuiOffEncouragedData(object oPC, int nToken)
{
    json jRow = NuiGetBind(oPC, nToken, NUI_DATA_ROW);
    if (JsonGetType(jRow) != JSON_TYPE_NULL)
    {
        int nRow = JsonGetInt(jRow);

        json jEncouraged = NuiGetBind(oPC, nToken, NUI_DATA_ENCOURAGED);

        jEncouraged = JsonArraySet(jEncouraged, nRow, JsonBool(FALSE));

        NuiSetBind(oPC, nToken, NUI_DATA_ENCOURAGED, jEncouraged);
        NuiSetBind(oPC, nToken, NUI_DATA_ROW, JsonArray());
    }
}

void NuiOnEncouragedData(object oPC, int nToken, int nRow)
{
    json jEncouraged = NuiGetBind(oPC, nToken, NUI_DATA_ENCOURAGED);

    jEncouraged = JsonArraySet(jEncouraged, nRow, JsonBool(TRUE));

    NuiSetBind(oPC, nToken, NUI_DATA_ENCOURAGED, jEncouraged);
    NuiSetBind(oPC, nToken, NUI_DATA_ROW, JsonInt(nRow));
}

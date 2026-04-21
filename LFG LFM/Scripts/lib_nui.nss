// lib_nui.nss
// Core NUI utilities (demo module version)

#include "nw_inc_nui"
#include "lib_nui_utility"

// Event type constants
const string EVENT_TYPE_WATCH     = "watch";
const string EVENT_TYPE_OPEN      = "open";
const string EVENT_TYPE_CLOSE     = "close";
const string EVENT_TYPE_CLICK     = "click";
const string EVENT_TYPE_MOUSEUP   = "mouseup";
const string EVENT_TYPE_MOUSEDOWN = "mousedown";
const string EVENT_TYPE_MOUSESCROLL = "mousescroll";
const string EVENT_TYPE_RANGE     = "range";
const string EVENT_TYPE_FOCUS     = "focus";
const string EVENT_TYPE_BLUR      = "blur";

// Window bind names
const string WINDOW_GEOMETRY    = "geometry";
const string WINDOW_RESIZABLE   = "resizable";
const string WINDOW_COLLAPSED   = "collapsed";
const string WINDOW_CLOSABLE    = "closable";
const string WINDOW_TRANSPARENT = "transparent";
const string WINDOW_BORDER      = "border";

const string CLOSE = "CLOSE";

// Returns gold color used throughout the project
json GetNuiColorNwnGold()
{
    return NuiColor(185, 150, 100);
}

// Returns a dimension scaled to the player's GUI scale
float GetNuiScaleDimension(object oPC, float fDimension, float fScaleMax = 1.5)
{
    int nScaleGui   = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_SCALE);
    float fScaleGui = nScaleGui / 100.0;
    fScaleGui = fScaleGui > fScaleMax ? fScaleMax : fScaleGui;
    return fDimension / fScaleGui;
}

// Returns a fixed-height empty row (scale-aware)
json CreateEmptyRow(object oPC, float fHeight, float fScaleMax = 1.5)
{
    json jRow = JsonArray();
    if(fHeight <= 0.0)
        jRow = JsonArrayInsert(jRow, NuiSpacer());
    else
        jRow = JsonArrayInsert(jRow, NuiHeight(NuiSpacer(), GetNuiScaleDimension(oPC, fHeight, fScaleMax)));
    return NuiRow(jRow);
}

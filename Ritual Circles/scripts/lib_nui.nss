// lib_nui.nss - minimal NUI helpers (open source, no NWNX dependency)
//
// Subset of LC's lib_nui without NWNX deps:
//   - NUI event type string constants
//   - Window property constants
//   - Mouse button constants
//   - GetNuiScaleDimension - GUI scale awareness
//   - CreateEmptyRow - scale-aware fixed-height spacer row
//   - GetNuiColorNwnGold - project standard gold color

#include "nw_inc_nui"

// ============================================================
// NUI event types (NuiGetEventType returns one of these)
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
// Window properties (bind names for NuiWindow params)
// ============================================================
const string WINDOW_TITLE       = "title";
const string WINDOW_GEOMETRY    = "geometry";
const string WINDOW_RESIZABLE   = "resizable";
const string WINDOW_COLLAPSED   = "collapsed";
const string WINDOW_CLOSABLE    = "closable";
const string WINDOW_TRANSPARENT = "transparent";
const string WINDOW_BORDER      = "border";

// ============================================================
// Mouse buttons (NuiGetEventPayload for click events)
// ============================================================
const int EVENT_BUTTON_LEFT   = 0;
const int EVENT_BUTTON_MIDDLE = 1;
const int EVENT_BUTTON_RIGHT  = 2;

// ============================================================
// Scale-aware helpers
// ============================================================

// Returns dimension scaled by player's GUI scale (capped at fScaleMax).
// Use for widget sizes inside windows so layout looks consistent across resolutions.
float GetNuiScaleDimension(object oPC, float fDimension, float fScaleMax = 1.5)
{
    int nScaleGui = GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_SCALE);
    float fScaleGui = nScaleGui / 100.0;

    if(fScaleGui > fScaleMax) fScaleGui = fScaleMax;
    if(fScaleGui <= 0.0)      fScaleGui = 1.0;

    return (fDimension / fScaleGui);
}

// Scale-aware spacer row of given height. Pass fHeight=0 for elastic spacer.
json CreateEmptyRow(object oPC, float fHeight, float fScaleMax = 1.5)
{
    json jRow = JsonArray();

    if(fHeight <= 0.0)
    {
        jRow = JsonArrayInsert(jRow, NuiSpacer());
    }
    else
    {
        jRow = JsonArrayInsert(jRow, NuiHeight(
            NuiSpacer(),
            GetNuiScaleDimension(oPC, fHeight, fScaleMax)));
    }

    return NuiRow(jRow);
}

// ============================================================
// Project color helpers
// ============================================================

json GetNuiColorNwnGold()
{
    return NuiColor(185, 150, 100);
}

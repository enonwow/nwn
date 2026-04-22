#include "lib_st_def"

// ============================================================
//  Spell Tracker ? layout, feed, tick, window creation
// ============================================================

// Forward declarations (tick functions call each other + feed)
void StTickList(object oPC, int nToken);
void StTickIcons(object oPC, int nToken);


// ================================================================
//  LIST WINDOW
// ================================================================

// ----------------------------------------------------------------
//  StBuildListCell
//  Layout per row:
//    ROW
//    +?? COL#1 [elastic]
//    -   +?? COL#1.1  ? spell icon (fixed 44px)
//    -   L?? COL#1.2  [elastic]
//    -       +?? ROW#1.2.1 ? [name (elastic) | timer (52px)]
//    -       L?? ROW#1.2.2 ? [progress bar (full width)]
//    L?? COL#2        ? Remove button (72px)
//  All dynamic fields are NuiBind ? NuiList fills them per row.
// ----------------------------------------------------------------
json StBuildListCell()
{
    // --- COL#1.1: spell icon ---
    json jIcon = NuiImage(
        NuiBind(ST_BIND_L_ICONS),
        JsonInt(NUI_ASPECT_FIT),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE)
    );
    jIcon = NuiWidth(jIcon,  44.0);
    jIcon = NuiHeight(jIcon, 44.0);

    // --- ROW#1.2.1: name (elastic) + timer (fixed) ---
    json jName = NuiLabel(
        NuiBind(ST_BIND_L_NAMES),
        JsonInt(NUI_HALIGN_LEFT),
        JsonInt(NUI_VALIGN_MIDDLE)
    );
    json jTimer = NuiLabel(
        NuiBind(ST_BIND_L_TIMERS),
        JsonInt(NUI_HALIGN_RIGHT),
        JsonInt(NUI_VALIGN_MIDDLE)
    );
    jTimer = NuiWidth(jTimer, 52.0);

    json jRow121 = JsonArray();
    jRow121 = JsonArrayInsert(jRow121, jName);
    jRow121 = JsonArrayInsert(jRow121, jTimer);

    // --- ROW#1.2.2: progress bar spanning full COL#1.2 width ---
    json jProgress = NuiProgress(NuiBind(ST_BIND_L_PROGRESS));
    jProgress = NuiHeight(jProgress, 10.0);
    jProgress = NuiStyleForegroundColor(jProgress, NuiBind(ST_BIND_L_PROGCOL));

    json jRow122 = JsonArray();
    jRow122 = JsonArrayInsert(jRow122, jProgress);

    // --- COL#1.2: name+timer row stacked above progress row ---
    json jProgressRow = NuiRow(jRow122);
    jProgressRow = NuiHeight(jProgressRow, 14.0);

    json jCol12 = JsonArray();
    jCol12 = JsonArrayInsert(jCol12, NuiRow(jRow121));
    jCol12 = JsonArrayInsert(jCol12, jProgressRow);

    // --- COL#1: icon beside col#1.2 ---
    json jCol1 = JsonArray();
    jCol1 = JsonArrayInsert(jCol1, jIcon);
    jCol1 = JsonArrayInsert(jCol1, NuiGroup(NuiCol(jCol12), FALSE, NUI_SCROLLBARS_NONE));

    // --- COL#2: Remove button (fixed width, visibility per-row) ---
    json jRemove = NuiButton(JsonString("Dispel"));
    jRemove = NuiId(jRemove, ST_BTN_L_REMOVE);
    jRemove = NuiVisible(jRemove, NuiBind(ST_BIND_L_BTNVIS));
    jRemove = NuiWidth(jRemove, 72.0);

    // --- main row: COL#1 (elastic) + COL#2 (fixed) ---
    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, NuiGroup(NuiRow(jCol1), FALSE, NUI_SCROLLBARS_NONE));
    jRow = JsonArrayInsert(jRow, jRemove);

    json jCell = NuiGroup(NuiRow(jRow), TRUE, NUI_SCROLLBARS_NONE);

    json jTmpl = JsonArray();
    jTmpl = JsonArrayInsert(jTmpl, NuiListTemplateCell(jCell, 0.0, TRUE));
    return jTmpl;
}

// ----------------------------------------------------------------
//  StFeedList
//  Reads current spells and pushes all array binds into the window.
// ----------------------------------------------------------------
void StFeedList(object oPC, int nToken)
{
    json jSpells = StCollectSpells(oPC);
    int  nCount  = JsonGetLength(jSpells);

    json jIcons    = JsonArray();
    json jNames    = JsonArray();
    json jTimers   = JsonArray();
    json jBtnVis   = JsonArray();
    json jProgress = JsonArray();
    json jProgCol  = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json jSpell = JsonArrayGet(jSpells, i);

        jIcons = JsonArrayInsert(jIcons, JsonObjectGet(jSpell, ST_F_ICON));
        jNames = JsonArrayInsert(jNames, JsonObjectGet(jSpell, ST_F_NAME));
        jBtnVis = JsonArrayInsert(jBtnVis, JsonObjectGet(jSpell, ST_F_CANREMOVE));

        int nSec = JsonGetInt(JsonObjectGet(jSpell, ST_F_TIMER));
        int nDur = JsonGetInt(JsonObjectGet(jSpell, ST_F_DURATION));
        jTimers  = JsonArrayInsert(jTimers, JsonString(StFormatTimer(nSec)));

        float fRatio = 1.0;
        if(nDur > 0) fRatio = IntToFloat(nSec) / IntToFloat(nDur);
        if(fRatio < 0.0) fRatio = 0.0;
        if(fRatio > 1.0) fRatio = 1.0;
        jProgress = JsonArrayInsert(jProgress, JsonFloat(fRatio));
        jProgCol  = JsonArrayInsert(jProgCol,  StGetTimerColor(nSec, nDur));
    }

    NuiSetBind(oPC, nToken, ST_BIND_L_ICONS,    jIcons);
    NuiSetBind(oPC, nToken, ST_BIND_L_NAMES,    jNames);
    NuiSetBind(oPC, nToken, ST_BIND_L_TIMERS,   jTimers);
    NuiSetBind(oPC, nToken, ST_BIND_L_BTNVIS,   jBtnVis);
    NuiSetBind(oPC, nToken, ST_BIND_L_PROGRESS, jProgress);
    NuiSetBind(oPC, nToken, ST_BIND_L_PROGCOL,  jProgCol);
    NuiSetBind(oPC, nToken, ST_BIND_L_COUNT,    JsonInt(nCount));
}

// ----------------------------------------------------------------
//  StTickList
//  Feeds the list window, then schedules itself for the next tick.
//  Stops if the window was closed or the running flag was cleared.
// ----------------------------------------------------------------
void StTickList(object oPC, int nToken)
{
    if(!GetLocalInt(oPC, ST_LVAR_L_RUNNING)) return;

    if(NuiFindWindow(oPC, ST_LIST_WINDOW_ID) == 0)
    {
        DeleteLocalInt(oPC, ST_LVAR_L_RUNNING);
        DeleteLocalInt(oPC, ST_LVAR_L_TOKEN);
        return;
    }

    StFeedList(oPC, nToken);
    DelayCommand(ST_TICK_INTERVAL, StTickList(oPC, nToken));
}


// ================================================================
//  ICON WINDOW
// ================================================================

// ----------------------------------------------------------------
//  StBuildOneIconSlot
//  Builds a single icon cell: NuiButtonImage with a DrawList timer
//  overlay in the top-right corner.
// ----------------------------------------------------------------
json StBuildOneIconSlot(int nIdx, string sIcon, string sTimer, json jColor, string sName)
{
    // Button with unique ID so click events are identifiable
    json jBtn = NuiButtonImage(JsonString(sIcon));
    jBtn = NuiId(jBtn, ST_BTN_IC_PREFIX + IntToString(nIdx));
    jBtn = NuiWidth(jBtn,  ST_ICON_SIZE);
    jBtn = NuiHeight(jBtn, ST_ICON_SIZE);
    jBtn = NuiTooltip(jBtn, JsonString(sName));

    // Timer text overlaid on the button ? color reflects remaining time ratio
    json jDLItems = JsonArray();
    json jTimerText = NuiDrawListText(
        JsonBool(TRUE),
        jColor,
        NuiRect(2.0, 2.0, ST_ICON_SIZE - 4.0, 14.0),
        JsonString(sTimer),
        NUI_DRAW_LIST_ITEM_ORDER_AFTER,
        NUI_DRAW_LIST_ITEM_RENDER_ALWAYS
    );
    jDLItems = JsonArrayInsert(jDLItems, jTimerText);
    jBtn = NuiDrawList(jBtn, JsonBool(FALSE), jDLItems);

    return jBtn;
}

// ----------------------------------------------------------------
//  StBuildIconsRow
//  Builds a NuiRow of icon slots from the collected spell array.
//  When no spells are active a placeholder label is shown instead.
// ----------------------------------------------------------------
json StBuildIconsRow(json jSpells)
{
    json jRow  = JsonArray();
    int  nCount = JsonGetLength(jSpells);

    if(nCount == 0)
    {
        json jLbl = NuiLabel(
            JsonString("No active spells"),
            JsonInt(NUI_HALIGN_CENTER),
            JsonInt(NUI_VALIGN_MIDDLE)
        );
        jRow = JsonArrayInsert(jRow, jLbl);
        return NuiRow(jRow);
    }

    int i;
    for(i = 0; i < nCount; i++)
    {
        json   jSpell = JsonArrayGet(jSpells, i);
        string sIcon  = JsonGetString(JsonObjectGet(jSpell, ST_F_ICON));
        string sName  = JsonGetString(JsonObjectGet(jSpell, ST_F_NAME));
        int    nSec   = JsonGetInt(JsonObjectGet(jSpell, ST_F_TIMER));
        int    nDur   = JsonGetInt(JsonObjectGet(jSpell, ST_F_DURATION));

        jRow = JsonArrayInsert(jRow, StBuildOneIconSlot(i, sIcon, StFormatTimer(nSec), StGetTimerColor(nSec, nDur), sName));
    }
    return NuiRow(jRow);
}

// ----------------------------------------------------------------
//  StFeedIcons
//  Collects spells, caches data for click handler, rebuilds the
//  icon group layout via NuiSetGroupLayout.
// ----------------------------------------------------------------
void StFeedIcons(object oPC, int nToken)
{
    json jSpells = StCollectSpells(oPC);
    SetLocalJson(oPC, ST_LVAR_IC_SPDATA, jSpells);

    NuiSetGroupLayout(oPC, nToken, ST_GROUP_IC_ROW, StBuildIconsRow(jSpells));
}

// ----------------------------------------------------------------
//  StTickIcons
//  Rebuilds the icon row, then schedules itself for the next tick.
//  Stops if the window was closed or the running flag was cleared.
// ----------------------------------------------------------------
void StTickIcons(object oPC, int nToken)
{
    if(!GetLocalInt(oPC, ST_LVAR_IC_RUNNING)) return;

    if(NuiFindWindow(oPC, ST_ICON_WINDOW_ID) == 0)
    {
        DeleteLocalInt(oPC, ST_LVAR_IC_RUNNING);
        DeleteLocalInt(oPC, ST_LVAR_IC_TOKEN);
        return;
    }

    StFeedIcons(oPC, nToken);
    DelayCommand(ST_TICK_INTERVAL, StTickIcons(oPC, nToken));
}


// ================================================================
//  WINDOW CREATION
// ================================================================

// ----------------------------------------------------------------
//  CreateSpellTrackerListWindow
//  Opens the list-style spell tracker for oPC.
//  If the window is already open, returns without creating a second.
// ----------------------------------------------------------------
void CreateSpellTrackerListWindow(object oPC)
{
    if(NuiFindWindow(oPC, ST_LIST_WINDOW_ID) != 0) return;

    json jTmpl = StBuildListCell();
    json jList = NuiList(jTmpl, NuiBind(ST_BIND_L_COUNT), ST_ROW_H, TRUE, NUI_SCROLLBARS_Y);

    json jRootChildren = JsonArray();
    jRootChildren = JsonArrayInsert(jRootChildren, jList);
    json jRoot = NuiCol(jRootChildren);

    json jGeom   = NuiRect(-1.0, -1.0, ST_LIST_W, ST_LIST_H);
    json jWindow = NuiWindow(
        jRoot,
        JsonString("Spell Tracker"),
        jGeom,
        JsonBool(TRUE),   // resizable
        JsonBool(FALSE),  // collapsed
        JsonBool(TRUE),   // closable
        JsonBool(FALSE),  // transparent
        JsonBool(TRUE)    // border
    );

    int nToken = NuiCreate(oPC, jWindow, ST_LIST_WINDOW_ID, "lib_st_ev");
    SetLocalInt(oPC, ST_LVAR_L_TOKEN, nToken);
    SetLocalInt(oPC, ST_LVAR_L_RUNNING, 1);

    StFeedList(oPC, nToken);
    DelayCommand(ST_TICK_INTERVAL, StTickList(oPC, nToken));
}

// ----------------------------------------------------------------
//  CreateSpellTrackerIconWindow
//  Opens the horizontal icon bar spell tracker for oPC.
//  If the window is already open, returns without creating a second.
//  The icon group is populated immediately and rebuilt every tick.
// ----------------------------------------------------------------
void CreateSpellTrackerIconWindow(object oPC)
{
    if(NuiFindWindow(oPC, ST_ICON_WINDOW_ID) != 0) return;

    // The group starts empty; StFeedIcons fills it right after NuiCreate
    json jIconGroup = NuiGroup(NuiRow(JsonArray()), FALSE, NUI_SCROLLBARS_AUTO);
    jIconGroup = NuiId(jIconGroup, ST_GROUP_IC_ROW);
    jIconGroup = NuiHeight(jIconGroup, ST_ICON_SIZE + 26.0);

    json jRootChildren = JsonArray();
    jRootChildren = JsonArrayInsert(jRootChildren, jIconGroup);
    json jRoot = NuiCol(jRootChildren);

    json jGeom   = NuiRect(-1.0, -1.0, ST_ICON_W, ST_ICON_H);
    json jWindow = NuiWindow(
        jRoot,
        JsonString("Spell Tracker - Icons"),
        jGeom,
        JsonBool(TRUE),   // resizable
        JsonBool(FALSE),  // collapsed
        JsonBool(TRUE),   // closable
        JsonBool(FALSE),  // transparent
        JsonBool(TRUE)    // border
    );

    int nToken = NuiCreate(oPC, jWindow, ST_ICON_WINDOW_ID, "lib_st_ev");
    SetLocalInt(oPC, ST_LVAR_IC_TOKEN, nToken);
    SetLocalInt(oPC, ST_LVAR_IC_RUNNING, 1);

    StFeedIcons(oPC, nToken);
    DelayCommand(ST_TICK_INTERVAL, StTickIcons(oPC, nToken));
}

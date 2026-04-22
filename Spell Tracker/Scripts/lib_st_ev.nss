#include "lib_st"

// ============================================================
//  Spell Tracker — NUI event handler
//  Handles events from both ST_LIST_WINDOW_ID and ST_ICON_WINDOW_ID.
// ============================================================

// ----------------------------------------------------------------
//  StCleanupList
//  Stops the list window tick loop and removes its LVARs.
// ----------------------------------------------------------------
void StCleanupList(object oPC)
{
    DeleteLocalInt(oPC, ST_LVAR_L_RUNNING);
    DeleteLocalInt(oPC, ST_LVAR_L_TOKEN);
}

// ----------------------------------------------------------------
//  StCleanupIcons
//  Stops the icon window tick loop and removes its LVARs.
// ----------------------------------------------------------------
void StCleanupIcons(object oPC)
{
    DeleteLocalInt(oPC, ST_LVAR_IC_RUNNING);
    DeleteLocalInt(oPC, ST_LVAR_IC_TOKEN);
    DeleteLocalJson(oPC, ST_LVAR_IC_SPDATA);
}

// ----------------------------------------------------------------
//  StHandleListRemove
//  Called when the Remove button fires in a list row.
//  nRow is NuiGetEventArrayIndex() — maps directly to jSpells[nRow].
//  Uses a short delay so the button press animation completes first.
// ----------------------------------------------------------------
void StHandleListRemove(object oPC, int nRow)
{
    json jSpells = StCollectSpells(oPC);
    if(nRow < 0 || nRow >= JsonGetLength(jSpells)) return;

    int nSpellId = JsonGetInt(JsonObjectGet(JsonArrayGet(jSpells, nRow), ST_F_ID));
    DelayCommand(0.3, StRemoveBySpellId(oPC, nSpellId));
}

// ----------------------------------------------------------------
//  StHandleIconClick
//  Called when any icon button fires in the icon window.
//  Parses the numeric suffix from the button ID to find the spell.
//  Uses cached ST_LVAR_IC_SPDATA to avoid a full effect scan.
// ----------------------------------------------------------------
void StHandleIconClick(object oPC, string sElement)
{
    int    nPrefixLen = GetStringLength(ST_BTN_IC_PREFIX);
    string sIdx       = GetSubString(sElement, nPrefixLen,
                                     GetStringLength(sElement) - nPrefixLen);
    int    nIdx       = StringToInt(sIdx);

    json jSpells = GetLocalJson(oPC, ST_LVAR_IC_SPDATA);
    if(nIdx < 0 || nIdx >= JsonGetLength(jSpells)) return;

    int nSpellId = JsonGetInt(JsonObjectGet(JsonArrayGet(jSpells, nIdx), ST_F_ID));
    DelayCommand(0.3, StRemoveBySpellId(oPC, nSpellId));
}

// ----------------------------------------------------------------
//  main
//  NWN EE calls this script for every NUI event on both windows.
//  Identifies the source window by comparing the event token with
//  stored LVARs, then routes to the appropriate handler.
// ----------------------------------------------------------------
void main()
{
    object oPC      = NuiGetEventPlayer();
    int    nToken   = NuiGetEventWindow();
    string sEvent   = NuiGetEventType();
    string sElement = NuiGetEventElement();
    int    nRow     = NuiGetEventArrayIndex();

    if(nToken == 0) return;

    int bIsList  = (nToken == GetLocalInt(oPC, ST_LVAR_L_TOKEN));
    int bIsIcons = (nToken == GetLocalInt(oPC, ST_LVAR_IC_TOKEN));

    if(!bIsList && !bIsIcons) return;

    // --- window closed by player ---
    if(sEvent == ST_EV_CLOSE)
    {
        if(bIsList)  StCleanupList(oPC);
        if(bIsIcons) StCleanupIcons(oPC);
        return;
    }

    // --- button click ---
    if(sEvent == ST_EV_CLICK)
    {
        if(bIsList && sElement == ST_BTN_L_REMOVE)
        {
            StHandleListRemove(oPC, nRow);
            return;
        }

        if(bIsIcons &&
           GetStringLeft(sElement, GetStringLength(ST_BTN_IC_PREFIX)) == ST_BTN_IC_PREFIX)
        {
            StHandleIconClick(oPC, sElement);
            return;
        }
    }
}

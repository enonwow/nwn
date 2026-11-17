#include "lib_smit"

// ----------------------------------------------------------------
// Helpers
// ----------------------------------------------------------------

// Switch from recipe list to forge panel for the given list row index.
void SmithSelectRecipe(object oPC, int nToken, int nRowIdx)
{
    json jRecs = GetLocalJson(oPC, SMIT_LVAR_RECIPES);
    if(nRowIdx < 0 || nRowIdx >= JsonGetLength(jRecs)) return;

    int nId = JsonGetInt(JsonObjectGet(JsonArrayGet(jRecs, nRowIdx), "id"));
    SetLocalInt(oPC, SMIT_LVAR_SEL, nId);

    NuiSetGroupLayout(oPC, nToken, SMIT_GRP_CONTENT, SmithBuildForgeView(oPC));
    SmithFeedForgePanel(oPC, nToken);
}

// Switch back to recipe list from either forge or history.
void SmithShowRecipeList(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, SMIT_GRP_CONTENT, SmithBuildRecipeView(oPC));
    SmithFeedRecipeList(oPC, nToken);
}

// Switch to history view.
void SmithShowHistory(object oPC, int nToken)
{
    NuiSetGroupLayout(oPC, nToken, SMIT_GRP_CONTENT, SmithBuildHistoryView(oPC));
    SmithFeedHistoryPanel(oPC, nToken);
}

// ----------------------------------------------------------------
// Main NUI event handler
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, SMIT_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt   (oPC, SMIT_LVAR_SEL);
        DeleteLocalString(oPC, SMIT_LVAR_FILTER);
        DeleteLocalJson  (oPC, SMIT_LVAR_RECIPES);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        // ---- Close ----
        if(sElem == SMIT_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        // ---- Back (from forge or history) ----
        if(sElem == SMIT_BTN_BACK)
        {
            SmithShowRecipeList(oPC, nToken);
            return;
        }

        // ---- History ----
        if(sElem == SMIT_BTN_HISTORY)
        {
            SmithShowHistory(oPC, nToken);
            return;
        }

        // ---- Category filters ----
        if(sElem == SMIT_BTN_F_ALL)
        {
            DeleteLocalString(oPC, SMIT_LVAR_FILTER);
            SmithFeedRecipeList(oPC, nToken);
            return;
        }
        if(sElem == SMIT_BTN_F_WPN)
        {
            SetLocalString(oPC, SMIT_LVAR_FILTER, SMIT_CAT_WEAPON);
            SmithFeedRecipeList(oPC, nToken);
            return;
        }
        if(sElem == SMIT_BTN_F_ARM)
        {
            SetLocalString(oPC, SMIT_LVAR_FILTER, SMIT_CAT_ARMOR);
            SmithFeedRecipeList(oPC, nToken);
            return;
        }
        if(sElem == SMIT_BTN_F_SHL)
        {
            SetLocalString(oPC, SMIT_LVAR_FILTER, SMIT_CAT_SHIELD);
            SmithFeedRecipeList(oPC, nToken);
            return;
        }

        // ---- Forge ----
        if(sElem == SMIT_BTN_FORGE)
        {
            SmithDoForge(oPC, nToken);
            return;
        }
    }

    // ---- Recipe row click (mousedown for snappier response) ----
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == SMIT_BTN_ROW)
    {
        SmithSelectRecipe(oPC, nToken, nIdx);
        return;
    }
}

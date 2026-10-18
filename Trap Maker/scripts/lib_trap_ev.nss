#include "lib_trap"

// ================================================================
// lib_trap_ev.nss  —  NUI event handler for Trap Maker window
// ================================================================

void main()
{
    object oPC     = NuiGetEventPlayer();
    int    nToken  = NuiGetEventWindow();
    string sEvent  = NuiGetEventType();
    string sElem   = NuiGetEventElement();
    int    nIdx    = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, TRAP_WIN_CRAFT)) return;

    // ---- Window closed ----
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, TRAP_LVAR_SEL_IDX);
        return;
    }

    // ---- Clicks ----
    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == TRAP_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == TRAP_BTN_CRAFT)
        {
            TrapHandleCraft(oPC, nToken);
            return;
        }

        if(sElem == TRAP_BTN_DEPLOY)
        {
            TrapEnterDeployMode(oPC, nToken);
            return;
        }
    }

    // ---- Recipe row clicked ----
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == TRAP_BTN_REC_ROW)
    {
        json jRecipes = TrapGetRecipes();
        if(nIdx < 0 || nIdx >= JsonGetLength(jRecipes)) return;

        int nPrev = GetLocalInt(oPC, TRAP_LVAR_SEL_IDX);
        SetLocalInt(oPC, TRAP_LVAR_SEL_IDX, nIdx);

        // Update encouraged state: deselect old, select new
        int nCount = JsonGetLength(jRecipes);
        json jEncs = JsonArray();
        int i;
        for(i = 0; i < nCount; i++)
            jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
        NuiSetBind(oPC, nToken, TRAP_BIND_REC_ENC, jEncs);

        TrapFeedRecipeDetail(oPC, nToken, nIdx);
        return;
    }
}

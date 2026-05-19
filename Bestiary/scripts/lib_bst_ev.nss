// lib_bst_ev.nss — NUI event handler for Codex Bestiarum
#include "lib_bst"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, BST_WIN_CODEX)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        // Cancel any pending targeting mode
        DeleteLocalInt(oPC, BST_LVAR_STUDYING);
        DeleteLocalInt(oPC, BST_LVAR_SEL_IDX);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == BST_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == BST_BTN_STUDY)
        {
            // Disable button while targeting to prevent double-entry
            NuiSetBind(oPC, nToken, BST_BIND_STUDY_ENA, JsonBool(FALSE));
            SetLocalInt(oPC, BST_LVAR_STUDYING, 1);
            EnterTargetingMode(oPC, OBJECT_TYPE_CREATURE);
            SendMessageToPC(oPC,
                "[Codex] Kliknij na stworzenie w świecie gry, aby je zbadać."
                " Każde stworzenie można zbadać tylko raz.");
            return;
        }
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == BST_BTN_ROW)
    {
        if(nIdx < 0 || nIdx >= BST_RACE_COUNT) return;

        // Toggle: clicking the already-selected row deselects
        int nPrev = GetLocalInt(oPC, BST_LVAR_SEL_IDX) - 1;
        if(nPrev == nIdx)
        {
            DeleteLocalInt(oPC, BST_LVAR_SEL_IDX);
            BstFeedList(oPC, nToken);
            NuiSetGroupLayout(oPC, nToken, BST_GRP_DETAIL, BstBuildDetailEmpty(oPC));
            NuiSetBind(oPC, nToken, BST_BIND_STUDY_ENA, JsonBool(TRUE));
            return;
        }

        SetLocalInt(oPC, BST_LVAR_SEL_IDX, nIdx + 1);
        BstFeedList(oPC, nToken);
        BstFeedDetail(oPC, nToken, nIdx);
        return;
    }
}

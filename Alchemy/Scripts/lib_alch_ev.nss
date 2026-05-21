#include "lib_alch"

void AlchOnNuiEvent()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetWindowToken();
    string sWin   = NuiGetWindowId();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(sWin != ALCH_WINDOW) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        AlchClearAllSlots(oPC);
        DeleteLocalInt(oPC, ALCH_LVAR_SEL_RCP);
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK) return;

    // Close button
    if(sElem == ALCH_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    // Brew button
    if(sElem == ALCH_BTN_BREW)
    {
        AlchBrew(oPC, nToken);
        return;
    }

    // Slot clear buttons: "alch_btn_slotclr1" / "2" / "3"
    if(GetStringLeft(sElem, GetStringLength(ALCH_BTN_SLOT_CLR)) == ALCH_BTN_SLOT_CLR)
    {
        string sSuf = GetStringRight(sElem, 1);
        int nSlot   = StringToInt(sSuf);
        if(nSlot >= 1 && nSlot <= 3)
        {
            string sVar    = (nSlot == 1) ? ALCH_LVAR_SLOT1
                           : (nSlot == 2) ? ALCH_LVAR_SLOT2 : ALCH_LVAR_SLOT3;
            string sObjVar = (nSlot == 1) ? ALCH_LVAR_SLOT1_OBJ
                           : (nSlot == 2) ? ALCH_LVAR_SLOT2_OBJ : ALCH_LVAR_SLOT3_OBJ;
            DeleteLocalString(oPC, sVar);
            DeleteLocalObject(oPC, sObjVar);
            AlchFeedSlotLabels(oPC, nToken);
        }
        return;
    }

    // Slot pick buttons: "alch_btn_slot1" / "2" / "3" — enter targeting mode
    if(GetStringLeft(sElem, GetStringLength(ALCH_BTN_SLOT)) == ALCH_BTN_SLOT
    && GetStringLength(sElem) == GetStringLength(ALCH_BTN_SLOT) + 1)
    {
        string sSuf = GetStringRight(sElem, 1);
        int nSlot   = StringToInt(sSuf);
        if(nSlot >= 1 && nSlot <= 3)
        {
            SetLocalInt(oPC, ALCH_LVAR_TARGETING, nSlot);
            EnterTargetingMode(oPC, OBJECT_TYPE_ITEM);
        }
        return;
    }

    // Recipe row buttons: "alch_btn_rcp_row0" … "alch_btn_rcp_row9"
    if(GetStringLeft(sElem, GetStringLength(ALCH_BTN_RCP_ROW)) == ALCH_BTN_RCP_ROW)
    {
        string sSuf  = GetStringRight(sElem, GetStringLength(sElem) - GetStringLength(ALCH_BTN_RCP_ROW));
        int nRecipeId = StringToInt(sSuf);
        if(nRecipeId >= 0 && nRecipeId < ALCH_RECIPE_COUNT
        && AlchIsRecipeKnown(oPC, nRecipeId))
        {
            SetLocalInt(oPC, ALCH_LVAR_SEL_RCP, nRecipeId);
            AlchFeedRecipeList(oPC, nToken);
            AlchFeedRecipeInfo(oPC, nToken, nRecipeId);
        }
        return;
    }
}

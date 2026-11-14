#include "lib_intr"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(nToken != NuiFindWindow(oPC, INTR_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        // Apply any accumulated moral penalty on window close
        IntrApplyMoralPenalty(oPC);

        // Persist session to SQL
        string sUUID = GetLocalString(oPC, INTR_LVAR_PRISONER_UUID);
        int nBroken  = GetLocalInt(oPC, INTR_LVAR_BROKEN  + sUUID);
        int nMoral   = GetLocalInt(oPC, INTR_LVAR_MORAL_COST);
        IntrLogSession(GetObjectUUID(oPC), sUUID, nBroken, nMoral);

        // Reset session moral counter (penalties already applied)
        SetLocalInt(oPC, INTR_LVAR_MORAL_COST, 0);
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK) return;

    if(sElem == INTR_BTN_CLOSE)
    {
        IntrApplyMoralPenalty(oPC);
        NuiDestroy(oPC, nToken);
        return;
    }

    if(sElem == INTR_BTN_QUESTION)
    {
        IntrApplyMethod(oPC, INTR_METHOD_QUESTION);
        return;
    }

    if(sElem == INTR_BTN_INTIMIDATE)
    {
        IntrApplyMethod(oPC, INTR_METHOD_INTIMIDATE);
        return;
    }

    if(sElem == INTR_BTN_TORTURE)
    {
        IntrApplyMethod(oPC, INTR_METHOD_TORTURE);
        return;
    }

    if(sElem == INTR_BTN_DECEIVE)
    {
        IntrApplyMethod(oPC, INTR_METHOD_DECEIVE);
        return;
    }
}

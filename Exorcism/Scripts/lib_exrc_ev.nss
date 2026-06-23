#include "lib_exrc"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    // ---- Detect window ----
    if(nToken == NuiFindWindow(oPC, EXRC_WIN_DETECT))
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == EXRC_BTN_DETCLOSE)
            {
                NuiDestroy(oPC, nToken);
            }
            else if(sElem == EXRC_BTN_EXORCISE)
            {
                object oTarget = GetLocalObject(oPC, EXRC_LVAR_TARGET);
                NuiDestroy(oPC, nToken);
                if(GetIsObjectValid(oTarget))
                    ExrcOpenRitualWindow(oPC, oTarget);
            }
        }
        return;
    }

    // ---- Ritual window ----
    if(nToken != NuiFindWindow(oPC, EXRC_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        // Clean up LVAR state if ritual is still in progress
        DeleteLocalInt(oPC, EXRC_LVAR_STARTED);
        DeleteLocalInt(oPC, EXRC_LVAR_PROGRESS);
        DeleteLocalInt(oPC, EXRC_LVAR_DEADLINE);
        DeleteLocalJson(oPC, EXRC_LVAR_SEQUENCE);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == EXRC_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == EXRC_BTN_BEGIN)
        {
            ExrcBeginRitual(oPC, nToken);
            return;
        }

        // Symbol button click: exrc_btn_sym0 .. exrc_btn_sym5
        if(GetStringLeft(sElem, GetStringLength(EXRC_BTN_SYM)) == EXRC_BTN_SYM)
        {
            int nSym = StringToInt(GetStringRight(sElem,
                GetStringLength(sElem) - GetStringLength(EXRC_BTN_SYM)));
            ExrcHandleSymbolClick(oPC, nToken, nSym);
            return;
        }
    }
}

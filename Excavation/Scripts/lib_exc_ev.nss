#include "lib_exc"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, EXC_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalString(oPC, EXC_LVAR_SITE_TAG);
        DeleteLocalInt   (oPC, EXC_LVAR_VIEW);
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK && sEvent != EVENT_TYPE_MOUSEDOWN) return;

    // ---- Tab and close buttons ----
    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == EXC_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == EXC_BTN_TAB_DIG)
        {
            SetLocalInt(oPC, EXC_LVAR_VIEW, EXC_VIEW_DIG);
            NuiSetGroupLayout(oPC, nToken, EXC_GRP_SWAP, BuildExcDigView(oPC));
            ExcFeedDigView(oPC, nToken);
            return;
        }

        if(sElem == EXC_BTN_TAB_COD)
        {
            SetLocalInt(oPC, EXC_LVAR_VIEW, EXC_VIEW_CODEX);
            NuiSetGroupLayout(oPC, nToken, EXC_GRP_SWAP, BuildExcCodexView(oPC));
            ExcFeedCodexView(oPC, nToken);
            return;
        }

        if(sElem == EXC_BTN_DIG)
        {
            ExcDoDigAttempt(oPC, nToken);
            return;
        }

        // Assemble button inside the Codex list — array index = era
        if(sElem == EXC_BTN_ASSEMBLE)
        {
            ExcDoAssemble(oPC, nToken, nIdx);
            return;
        }
    }

    // ---- Era row highlight in Codex view ----
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == EXC_BTN_ERA_ROW)
    {
        json jEncs = JsonArray();
        int i;
        for(i = 0; i < EXC_ERA_COUNT; i++)
            jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
        NuiSetBind(oPC, nToken, EXC_BIND_ERA_ENC, jEncs);
    }
}

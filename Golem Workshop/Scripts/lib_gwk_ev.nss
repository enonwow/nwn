#include "lib_gwk"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(nToken != NuiFindWindow(oPC, GWK_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        // Sync golem HP to DB on window close if golem is live
        object oGolem = GwkFindGolem(oPC);
        if(GetIsObjectValid(oGolem))
            GwkUpdateHp(oPC, GetCurrentHitPoints(oGolem));
        return;
    }

    // Combo selection changed: refresh material display
    if(sEvent == EVENT_TYPE_WATCH && sElem == GWK_BIND_TYPE_SEL)
    {
        GwkFeedForgeSection(oPC, nToken);
        return;
    }

    if(sEvent != EVENT_TYPE_CLICK) return;

    if(sElem == GWK_BTN_TAB_FORGE)
    {
        GwkSwitchTab(oPC, nToken, 0);
        return;
    }

    if(sElem == GWK_BTN_TAB_GOLEM)
    {
        GwkSwitchTab(oPC, nToken, 1);
        return;
    }

    if(sElem == GWK_BTN_FORGE)
    {
        int nType = JsonGetInt(NuiGetBind(oPC, nToken, GWK_BIND_TYPE_SEL));
        GwkDoForge(oPC, nToken, nType);
        return;
    }

    if(sElem == GWK_BTN_REPAIR)
    {
        GwkDoRepair(oPC, nToken);
        return;
    }

    if(sElem == GWK_BTN_RECALL)
    {
        GwkDoRecall(oPC, nToken);
        return;
    }

    if(sElem == GWK_BTN_DESTROY)
    {
        GwkDoDestroy(oPC, nToken);
        return;
    }
}

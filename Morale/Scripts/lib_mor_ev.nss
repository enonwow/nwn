#include "lib_mor"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(nToken != NuiFindWindow(oPC, MOR_WINDOW)) return;

    switch(sEvent)
    {
        case EVENT_TYPE_CLOSE:
            // Nothing to clean up; morale persists.
            break;

        case EVENT_TYPE_CLICK:
            if(sElem == MOR_BTN_CLOSE)
            {
                NuiDestroy(oPC, nToken);
            }
            else if(sElem == MOR_BTN_STEEL)
            {
                MorDoSteel(oPC);
            }
            break;

        case EVENT_TYPE_OPEN:
            MorFeedWindow(oPC, nToken);
            break;
    }
}

#include "lib_popup"

object oPC         = NuiGetEventPlayer();
string sEventType  = NuiGetEventType();
int    nToken      = NuiGetEventWindow();
string sEventElem  = NuiGetEventElement();
int    nEnventIdx  = NuiGetEventArrayIndex();
string sWindowId   = NuiGetWindowId(oPC, nToken);

void main()
{
    if(sWindowId == POPUP_WINDOW)
    {
        if(sEventType == EVENT_TYPE_CLICK)
        {
            if(sEventElem == POPUP_CLOSE_BUTTON)
            {
                NuiDestroy(oPC, nToken);
            }
        }
    }
    else if(sWindowId == POPUP_CONTROLLER_WINDOW)
    {
        if(sEventType == EVENT_TYPE_CLICK)
        {
            if(sEventElem == POPUP_CONTROLLER_SEND_MESSAGE_BUTTON)
            {
                SendPopupMessage(oPC, nToken);
            }
            else if(sEventElem == POPUP_CONTROLLER_CLOSE_BUTTON)
            {
                NuiDestroy(oPC, nToken);
            }
        }
        else if(sEventType == EVENT_TYPE_WATCH)
        {
            int nSelectedType = JsonGetInt(
                NuiGetBind(oPC, nToken, POPUP_CONTROLLER_SELCTED_TYPE));

            int nSelectedAreaType = JsonGetInt(
                NuiGetBind(oPC, nToken, POPUP_CONTROLLER_SELCTED_AREA_TYPE));
            
            int bEnabled = nSelectedType > 0 && nSelectedAreaType > 0;
            
            NuiSetBind(oPC, nToken, POPUP_CONTROLLER_SEND_MESSAGE_ENABLED, JsonBool(bEnabled));
        }
    }
}

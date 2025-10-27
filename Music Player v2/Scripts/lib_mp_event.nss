#include "lib_mp"

object oPC         = NuiGetEventPlayer();
string sEventType  = NuiGetEventType();
int    nToken      = NuiGetEventWindow();
string sEventElem  = NuiGetEventElement();
int    nEnventIdx  = NuiGetEventArrayIndex();
string sWindowId   = NuiGetWindowId(oPC, nToken);

void main()
{
    if (sEventType == EVENT_TYPE_CLICK)
    {
        if(sEventElem == MP_BUTTON_CLOSE)
        {
            MPStopSoundOnlyForPlayer(oPC, nToken);
            NuiDestroy(oPC, nToken);
        }
        else if(sEventElem == MP_BUTTON)
        {
            if(JsonGetInt(NuiGetBind(oPC, nToken, MP_IS_PLAYING)) == TRUE)
            {
                MPStopSoundOnlyForPlayer(oPC, nToken);
            }
            else
            {
                MPPlaySoundOnlyForPlayer(oPC, nToken);
            }
        }
        else if(sEventElem == MP_BUTTON_PREV)
        {
            MPChangeMusicForPlayer(oPC, nToken, -1);
        }
        else if(sEventElem == MP_BUTTON_NEXT)
        {
            MPChangeMusicForPlayer(oPC, nToken, 1);
        }
        else if(sEventElem == MP_BUTTON_LOOP)
        {
            MPChangeLoopForPlayer(oPC, nToken);
        }
    }
    else if(sEventType == EVENT_TYPE_MOUSEDOWN)
    {
        if (sEventElem == MP_MOUSEDOWN)
        {
            NuiOffEncouragedData(oPC, nToken);
            NuiOnEncouragedData(oPC, nToken, nEnventIdx);
        }
    }
    else if(sEventType == EVENT_TYPE_WATCH)
    {
        if(sEventElem == MP_VOLUME)
        {
            MPSetVolumeForPlayer(oPC, nToken);
        }
    }
    else if(sEventType == EVENT_TYPE_OPEN)
    {
        NuiOffEncouragedData(oPC, nToken);
        NuiOnEncouragedData(oPC, nToken, 0);
    }
}

#include "lib_sm_bar"

void main()
{
    object oPC      = NuiGetEventPlayer();
    int    nToken   = NuiGetEventWindow();
    string sWinId   = NuiGetWindowId(oPC, nToken);
    string sEvent   = NuiGetEventType();
    string sElement = NuiGetEventElement();

    if(sWinId == SM_WIN_BAR)
    {
        if(sEvent == SM_EVENT_CLICK && GetStringLeft(sElement, 9) == SM_BAR_BTN_PFX)
        {
            int nSeqIdx = StringToInt(GetStringRight(sElement,
                GetStringLength(sElement) - 9));
            json jData = SmLoadByIdx(oPC, nSeqIdx);
            if(JsonGetType(jData) == JSON_TYPE_NULL) return;
            SmExecute(oPC, JsonObjectGet(jData, "spells"), JsonGetInt(JsonObjectGet(jData, "target_mode")));
            return;
        }
    }
}

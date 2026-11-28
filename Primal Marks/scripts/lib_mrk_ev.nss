#include "lib_mrk"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sWin   = NuiGetWindowId(oPC, nToken);
    string sEvt   = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(sEvt == "close") return;

    if(sWin == MRK_WINDOW)
    {
        if(sEvt != "click") return;

        if(sElem == MRK_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        // Transform buttons: MRK_BTN_TRANSFORM + "0".."4"
        int i;
        for(i = 0; i < MRK_TYPE_COUNT; i++)
        {
            string sBtnId = MRK_BTN_TRANSFORM + IntToString(i);
            if(sElem == sBtnId)
            {
                int nActiveBit = GetLocalInt(oPC, MRK_LVAR_ACTIVE);
                if(nActiveBit == i + 1)
                {
                    // Cancel active transform
                    MrkEndTransform(oPC);
                }
                else
                {
                    MrkActivateTransform(oPC, i);
                }
                return;
            }
        }
    }
}

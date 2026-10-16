#include "lib_sb"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    // ---- Confirm popup ----
    if(nToken == NuiFindWindow(oPC, SB_WIN_CONFIRM))
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == SB_BTN_CONF_YES)
            {
                string sUuid = GetLocalString(oPC, "SB_BREAK_UUID");
                NuiDestroy(oPC, nToken);
                SbExecuteBreak(oPC, sUuid);
            }
            else if(sElem == SB_BTN_CONF_NO)
            {
                NuiDestroy(oPC, nToken);
            }
        }
        return;
    }

    if(nToken != NuiFindWindow(oPC, SB_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalString(oPC, SB_LVAR_INSPECTED);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == SB_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == SB_BTN_INSPECT)
        {
            SbInspectMainHand(oPC);
            return;
        }

        if(sElem == SB_BTN_BREAK)
        {
            string sUuid = GetLocalString(oPC, SB_LVAR_INSPECTED);
            if(sUuid == "")
            {
                SendMessageToPC(oPC, "[Więź Duszy] Nie wybrano żadnej broni do zbadania.");
                return;
            }
            json jData = SbGetWeapon(sUuid);
            if(JsonGetType(jData) == JSON_TYPE_NULL)
            {
                SendMessageToPC(oPC, "[Więź Duszy] Ta broń nie ma żadnej więzi.");
                return;
            }
            int nRank = JsonGetInt(JsonObjectGet(jData, "rank"));
            if(nRank <= 0)
            {
                SendMessageToPC(oPC, "[Więź Duszy] Nie ma jeszcze nic do zerwania.");
                return;
            }
            string sWpName = JsonGetString(JsonObjectGet(jData, "weapon_name"));
            SbShowConfirmBreak(oPC, sUuid, sWpName);
            return;
        }
    }
}

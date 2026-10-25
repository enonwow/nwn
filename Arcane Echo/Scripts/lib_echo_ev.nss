#include "lib_echo"

// ----------------------------------------------------------------
// Main NUI event handler — registered as ECHO_EV_SCRIPT
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, ECHO_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, ECHO_LVAR_SEL_ID);
        DeleteLocalInt(oPC, ECHO_LVAR_IS_OWN);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == ECHO_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == ECHO_BTN_REFRESH)
        {
            SetLocalInt(oPC, ECHO_LVAR_SEL_ID, 0);
            EchoFeedTraceList(oPC, nToken);
            EchoFeedDetailEmpty(oPC, nToken);
            SendMessageToPC(oPC, "[Echo Arkanów] Skanowanie obszaru…");
            return;
        }

        if(sElem == ECHO_BTN_ERASE)
        {
            int bIsOwn = GetLocalInt(oPC, ECHO_LVAR_IS_OWN);
            if(!bIsOwn)
            {
                SendMessageToPC(oPC, "[Echo Arkanów] Możesz zacierać tylko własne ślady.");
                return;
            }

            string sAreaTag    = GetTag(GetArea(oPC));
            string sCasterUuid = GetObjectUUID(oPC);
            int nCount = EchoCasterTraceCount(sAreaTag, sCasterUuid);
            int nCost  = nCount * ECHO_ERASE_GOLD_COST;

            if(GetGold(oPC) < nCost)
            {
                SendMessageToPC(oPC, "[Echo Arkanów] Brak złota na rytuał zacierania (potrzeba "
                    + IntToString(nCost) + " sz.).");
                return;
            }

            AssignCommand(oPC, TakeGoldFromCreature(nCost, oPC, TRUE));
            EchoEraseCasterTraces(sAreaTag, sCasterUuid);

            SendMessageToPC(oPC, "[Echo Arkanów] Pieczęć krwi pulsuje słabo… ślady magiczne rozmyły się w mroku.");
            SetLocalInt(oPC, ECHO_LVAR_SEL_ID, 0);
            EchoFeedTraceList(oPC, nToken);
            EchoFeedDetailEmpty(oPC, nToken);
            return;
        }
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN)
    {
        if(sElem == ECHO_BTN_ROW)
        {
            object oArea    = GetArea(oPC);
            string sAreaTag = GetTag(oArea);
            json   jTraces  = EchoGetAreaTraces(sAreaTag, ECHO_MAX_LIST);

            if(nIdx < 0 || nIdx >= JsonGetLength(jTraces)) return;

            json jRow = JsonArrayGet(jTraces, nIdx);
            int  nId  = JsonGetInt(JsonObjectGet(jRow, "id"));

            // Highlight selected row
            int nCount = JsonGetLength(jTraces);
            json jEncs = JsonArray();
            int i;
            for(i = 0; i < nCount; i++)
                jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
            NuiSetBind(oPC, nToken, ECHO_BIND_ROW_ENC, jEncs);

            EchoFeedDetail(oPC, nToken, nId);
            return;
        }
    }
}

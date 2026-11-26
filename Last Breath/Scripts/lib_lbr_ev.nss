#include "lib_lbr"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, LBR_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, LBR_LVAR_SEL_ID);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == LBR_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == LBR_BTN_DRINK)
        {
            int nId = GetLocalInt(oPC, LBR_LVAR_SEL_ID);
            if(nId > 0)
                LbrConsumeEssence(oPC, nId);
            SetLocalInt(oPC, LBR_LVAR_SEL_ID, 0);
            LbrFeedWindow(oPC, nToken);
            return;
        }

        if(sElem == LBR_BTN_DISCARD)
        {
            int nId = GetLocalInt(oPC, LBR_LVAR_SEL_ID);
            if(nId > 0)
            {
                LbrDeleteEssence(nId);
                SendMessageToPC(oPC, "[Ostatnie Tchnienie] Roztrzaskałeś fiolkę. Esencja ulatnia się bez śladu.");
            }
            SetLocalInt(oPC, LBR_LVAR_SEL_ID, 0);
            LbrFeedWindow(oPC, nToken);
            return;
        }

        if(sElem == LBR_BTN_HARVEST)
        {
            LbrClearDecayed(oPC);
            if(LbrGetEssenceCount(oPC) >= LBR_MAX_ESSENCES)
            {
                SendMessageToPC(oPC,
                    "[Ostatnie Tchnienie] Nosisz już "
                    + IntToString(LBR_MAX_ESSENCES)
                    + " fiolek. Opróżnij jedną przed polowaniem.");
                return;
            }
            object oVial = GetItemPossessedBy(oPC, LBR_VIAL_TAG);
            if(!GetIsObjectValid(oVial))
            {
                SendMessageToPC(oPC, "[Ostatnie Tchnienie] Potrzebujesz Fiolki Ostatniego Tchnienia.");
                return;
            }
            SetLocalInt(oPC, LBR_LVAR_TARGETING, 1);
            EnterTargetingMode(oPC, OBJECT_TYPE_CREATURE);
            SendMessageToPC(oPC,
                "[Ostatnie Tchnienie] Wskaż martwą istotę aby pochłonąć jej tchnienie.");
            return;
        }
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == LBR_BTN_ROW)
    {
        json jEssences = LbrGetEssences(oPC);
        if(nIdx < 0 || nIdx >= JsonGetLength(jEssences)) return;
        json jRow = JsonArrayGet(jEssences, nIdx);
        SetLocalInt(oPC, LBR_LVAR_SEL_ID, JsonGetInt(JsonObjectGet(jRow, "id")));
        LbrFeedWindow(oPC, nToken);
        return;
    }
}

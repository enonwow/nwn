#include "lib_obs"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, OBS_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, OBS_LVAR_SEL_IDX);
        return;
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == OBS_BTN_ROW)
    {
        if(nIdx < 0 || nIdx >= OBS_NUM_CATEGORIES) return;
        ObsFeedDetails(oPC, nToken, nIdx);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == OBS_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == OBS_BTN_SUPPRESS)
        {
            int nSelIdx = GetLocalInt(oPC, OBS_LVAR_SEL_IDX);
            string sCat = ObsGetCategoryAtIndex(nSelIdx);
            int nPoints = ObsGetPoints(oPC, sCat);
            int nTier   = ObsGetTier(nPoints);

            if(nTier < OBS_TIER_FIXATION)
            {
                SendMessageToPC(oPC, "[Obsesje] Nie ma czego tłumić.");
                return;
            }
            if(ObsIsSuppressed(oPC, sCat))
            {
                SendMessageToPC(oPC, "[Obsesje] Ta obsesja jest już stumiona.");
                return;
            }
            if(GetGold(oPC) < OBS_SUPPRESS_COST)
            {
                SendMessageToPC(oPC, "[Obsesje] Potrzebujesz " + IntToString(OBS_SUPPRESS_COST) + " złotych, aby stumić tę obsesję.");
                return;
            }

            AssignCommand(oPC, TakeGoldFromCreature(OBS_SUPPRESS_COST, oPC, TRUE));
            ObsSuppressCategory(oPC, sCat, OBS_SUPPRESS_DURATION);

            // Remove active bonus effects so they don't persist while suppressed
            ObsApplyBonuses(oPC);

            SendMessageToPC(oPC,
                "[Obsesje] Obsesja \"" + ObsCategoryLabel(sCat) + "\" stumiona na godzinę. "
                "Ciemna część ciebie milczy... na razie.");
            FloatingTextStringOnCreature("Pieczęć woli...", oPC, FALSE);

            ObsFeedUI(oPC, nToken);
            return;
        }
    }
}

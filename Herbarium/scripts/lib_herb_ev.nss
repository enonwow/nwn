#include "lib_herb"

// ----------------------------------------------------------------
// Harvest: skill check then deplete node
// ----------------------------------------------------------------

void HerbHandleHarvest(object oPC, int nToken)
{
    string sTag  = GetLocalString(oPC, HERB_LVAR_NODE);
    int    nType = GetLocalInt   (oPC, HERB_LVAR_NTYPE);

    if(HerbNodeGetCharges(sTag) <= 0)
    {
        SendMessageToPC(oPC, "[Zielarz] Roślina jest wyczerpana. Wróć po jakimś czasie.");
        FeedHarvestWindow(oPC, nToken);
        return;
    }

    // Survival DC 10 — on failure charges still depleted (plant damaged)
    int nSkill   = GetSkillRank(SKILL_SURVIVAL, oPC);
    int nRoll    = Random(20) + 1;
    int bSuccess = (nRoll + nSkill >= 10);

    HerbNodeHarvest(sTag);

    if(!bSuccess)
    {
        SendMessageToPC(oPC, "[Zielarz] Nieudany zbiór (rzut " + IntToString(nRoll)
            + " + " + IntToString(nSkill) + " = " + IntToString(nRoll + nSkill)
            + " vs 10). Zioło zniszczone przy wyrywaniu.");
        FeedHarvestWindow(oPC, nToken);
        return;
    }

    // +1 yield when in season
    int nYield = 1 + (HerbIsInSeason(nType) ? 1 : 0);
    HerbPlayerGive(oPC, nType, nYield);

    string sMsg = "[Zielarz] Zebrano " + IntToString(nYield) + "x " + HerbGetName(nType) + ".";
    if(HerbIsInSeason(nType))
        sMsg = sMsg + " (sezon zbiorów — dodatkowy plon)";
    SendMessageToPC(oPC, sMsg);

    FeedHarvestWindow(oPC, nToken);
}

// ----------------------------------------------------------------
// Journal: consume one herb and apply its effect
// ----------------------------------------------------------------

void HerbHandleUse(object oPC, int nToken)
{
    int nType = GetLocalInt(oPC, HERB_LVAR_SEL);
    if(nType <= 0)
    {
        SendMessageToPC(oPC, "[Zielarz] Nie wybrano żadnego ziołą.");
        return;
    }

    int nHave = HerbPlayerGetCount(oPC, nType);
    if(nHave <= 0)
    {
        SendMessageToPC(oPC, "[Zielarz] Brak ziół tego rodzaju w sakwie.");
        FeedJournalWindow(oPC, nToken);
        return;
    }

    HerbPlayerConsume(oPC, nType, 1);
    HerbApplyEffect(oPC, nType);
    FeedJournalWindow(oPC, nToken);
}

// ================================================================
// Main NUI event handler
// ================================================================

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    // ---- Harvest window ----
    if(nToken == NuiFindWindow(oPC, HERB_WIN_HARVEST))
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == HERB_BTN_CLOSE_H)
            {
                NuiDestroy(oPC, nToken);
                return;
            }
            if(sElem == HERB_BTN_HARVEST)
            {
                HerbHandleHarvest(oPC, nToken);
                return;
            }
            if(sElem == HERB_BTN_JOURNAL)
            {
                OpenJournalWindow(oPC);
                return;
            }
        }
        if(sEvent == EVENT_TYPE_CLOSE)
        {
            DeleteLocalString(oPC, HERB_LVAR_NODE);
            DeleteLocalInt   (oPC, HERB_LVAR_NTYPE);
        }
        return;
    }

    // ---- Journal window ----
    if(nToken == NuiFindWindow(oPC, HERB_WIN_JOURNAL))
    {
        if(sEvent == EVENT_TYPE_CLOSE)
        {
            DeleteLocalInt(oPC, HERB_LVAR_SEL);
            return;
        }

        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == HERB_BTN_CLOSE_J)
            {
                NuiDestroy(oPC, nToken);
                return;
            }
            if(sElem == HERB_BTN_USE)
            {
                HerbHandleUse(oPC, nToken);
                return;
            }
        }

        if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == HERB_BTN_ROW)
        {
            json jAll = HerbPlayerGetAll(oPC);
            if(nIdx < 0 || nIdx >= JsonGetLength(jAll)) return;

            json jRow  = JsonArrayGet(jAll, nIdx);
            int  nType = JsonGetInt(JsonObjectGet(jRow, "type"));
            SetLocalInt(oPC, HERB_LVAR_SEL, nType);
            FeedJournalWindow(oPC, nToken);
            return;
        }
    }
}

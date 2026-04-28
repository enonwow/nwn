// lib_hench_ev.nss
// Event handler for the henchman system
#include "lib_hench"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        SetLocalInt(oPC, HENCH_LVAR_TOKEN,   0);
        SetLocalInt(oPC, HENCH_LVAR_SEL_IDX, -1);
        return;
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == HENCH_BTN_ROW)
    {
        NuiOffEncouragedData(oPC, nToken, HENCH_BIND_ENC);
        SetLocalInt(oPC, HENCH_LVAR_SEL_IDX, nIdx);
        NuiOnEncouragedData(oPC, nToken, HENCH_BIND_ENC, nIdx);
        FeedDetailPanel(oPC, nToken, nIdx);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK && sElem == HENCH_BTN_HIRE)
    {
        int nSel = GetLocalInt(oPC, HENCH_LVAR_SEL_IDX);
        if(nSel < 0) return;

        // Check if PC already has a companion
        if(GetIsObjectValid(GetHenchman(oPC)))
        {
            SendMessageToPC(oPC, "You already have a companion. Dismiss them before hiring a new one.");
            return;
        }

        json jRoster = GetLocalJson(GetModule(), HENCH_MOD_ROSTER);
        if(JsonGetType(jRoster) != JSON_TYPE_ARRAY) return;
        if(nSel >= JsonGetLength(jRoster)) return;

        json jE = JsonArrayGet(jRoster, nSel);
        string sResRef = JsonGetString(JsonObjectGet(jE, "resref"));
        int    nCost   = JsonGetInt(JsonObjectGet(jE, "cost"));

        if(GetGold(oPC) < nCost)
        {
            SendMessageToPC(oPC, "Not enough gold. You need " + IntToString(nCost) + " gp.");
            return;
        }

        object oHench = CreateObject(OBJECT_TYPE_CREATURE, sResRef, GetLocation(oPC), FALSE);
        if(!GetIsObjectValid(oHench))
        {
            SendMessageToPC(oPC, "Failed to hire companion.");
            return;
        }

        AssignCommand(oPC, TakeGoldFromCreature(nCost, oPC, TRUE));

        AddHenchman(oPC, oHench);
        HenchSetupCreatedHench(oPC, oHench);

        HenchSave(oPC);

        NuiSetGroupLayout(oPC, nToken, HENCH_GROUP_MAIN, HenchBuildFireLayout(oPC));
        FeedFireLayout(oPC, nToken);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK && sElem == HENCH_BTN_RESURRECT)
    {
        if(!HenchResurrect(oPC)) return;

        NuiSetGroupLayout(oPC, nToken, HENCH_GROUP_MAIN, HenchBuildFireLayout(oPC));
        FeedFireLayout(oPC, nToken);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK && sElem == HENCH_BTN_FIRE)
    {
        // Branch: living henchman -> HenchFire; dead -> HenchFireDead.
        if(GetIsObjectValid(GetHenchman(oPC)))
            HenchFire(oPC);
        else
            HenchFireDead(oPC);

        SetLocalInt(oPC, HENCH_LVAR_SEL_IDX, -1);

        NuiSetGroupLayout(oPC, nToken, HENCH_GROUP_MAIN, HenchBuildHireLayout(oPC));
        NuiSetBind(oPC, nToken, HENCH_BIND_HIRE_EN, JsonBool(FALSE));
        FeedRosterList(oPC, nToken);
        FeedDetailPanel(oPC, nToken, -1);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK && sElem == HENCH_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }
}

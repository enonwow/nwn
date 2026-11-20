#include "lib_fam"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    if(nToken != NuiFindWindow(oPC, FAM_WINDOW)) return;

    if(sEvent != EVENT_TYPE_CLICK) return;

    // ---- Close ----
    if(sElem == FAM_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    json jFam = FamGet(oPC);
    int bHasFam = (JsonGetType(jFam) != JSON_TYPE_NULL);

    // ---- Bonding view buttons ----
    if(!bHasFam)
    {
        // Type selection buttons
        int i;
        for(i = 0; i < FAM_TYPE_COUNT; i++)
        {
            if(sElem == FAM_BTN_TYPE + IntToString(i))
            {
                SetLocalInt(oPC, FAM_LVAR_SEL_TYPE, i);
                NuiSetBind(oPC, nToken, FAM_BIND_TYPE_DESC, JsonString(FamTypeDesc(i)));
                NuiSetBind(oPC, nToken, FAM_BIND_BOND_ENA, JsonBool(TRUE));
                return;
            }
        }

        if(sElem == FAM_BTN_BOND)
        {
            // Check mourning
            sqlquery qCheck = SqlPrepareQueryCampaign("familiar",
                "SELECT mourning_until FROM fam_familiar WHERE uuid = @uuid");
            SqlBindString(qCheck, "@uuid", GetObjectUUID(oPC));
            if(SqlStep(qCheck))
            {
                int nMourn = SqlGetInt(qCheck, 0);
                if(nMourn > 0 && FamNowUnix() < nMourn)
                {
                    int nLeft = nMourn - FamNowUnix();
                    SendMessageToPC(oPC, "[Znamię] Jesteś w żałobie. Poczekaj jeszcze "
                        + IntToString(nLeft / 3600) + " godzin.");
                    return;
                }
            }
            FamBond(oPC, nToken);
        }
        return;
    }

    // ---- Main view buttons ----
    if(sElem == FAM_BTN_SCOUT)
    {
        FamExecuteScout(oPC, nToken, jFam);
        return;
    }

    if(sElem == FAM_BTN_FORAGE)
    {
        FamExecuteForage(oPC, nToken, jFam);
        return;
    }

    if(sElem == FAM_BTN_VIGIL)
    {
        FamExecuteVigil(oPC, nToken, jFam);
        return;
    }

    if(sElem == FAM_BTN_CARRY)
    {
        string sCarry = JsonGetString(JsonObjectGet(jFam, "carry_json"));
        if(sCarry != "")
            FamRetrieveCarry(oPC, nToken, jFam);
        else
            FamExecuteCarry(oPC, nToken);
        return;
    }

    if(sElem == FAM_BTN_RETRIEVE)
    {
        FamProcessForageReturn(oPC, nToken, jFam);
        return;
    }

    if(sElem == FAM_BTN_DISMISS)
    {
        FamExecuteDismiss(oPC, nToken, jFam);
        return;
    }

    if(sElem == FAM_BTN_RELEASE)
    {
        FamExecuteRelease(oPC, nToken, jFam);
        return;
    }
}

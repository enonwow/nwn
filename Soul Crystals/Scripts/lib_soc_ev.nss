// lib_soc_ev.nss — Soul Crystals: NUI event handler.

#include "lib_soc"

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if (nToken != NuiFindWindow(oPC, SOC_WINDOW)) return;

    if (sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, SOC_LVAR_SEL_ID);
        DeleteLocalInt(oPC, SOC_LVAR_BINDING);
        return;
    }

    if (sEvent == EVENT_TYPE_CLICK)
    {
        if (sElem == SOC_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if (sElem == SOC_BTN_BIND)
        {
            if (SocGetCrystalCount(oPC) >= SOC_MAX_CRYSTALS)
            {
                SendMessageToPC(oPC, "[Kryształy Dusz] Wszystkie sloty kryształów są zajęte.");
                return;
            }
            SetLocalInt(oPC, SOC_LVAR_BINDING, 1);
            EnterTargetingMode(oPC, OBJECT_TYPE_CREATURE);
            SendMessageToPC(oPC,
                "[Kryształy Dusz] Wskaż osłabione stworzenie (HP ≤ 25%), by schwytać jego duszę.");
            return;
        }

        // Consume / release buttons — require a selected crystal
        int nSelId = GetLocalInt(oPC, SOC_LVAR_SEL_ID);
        if (nSelId <= 0) return;

        if (sElem == SOC_BTN_STR)     { SocConsumeFor(oPC, nToken, nSelId, 1); return; }
        if (sElem == SOC_BTN_WIS)     { SocConsumeFor(oPC, nToken, nSelId, 2); return; }
        if (sElem == SOC_BTN_AC)      { SocConsumeFor(oPC, nToken, nSelId, 3); return; }
        if (sElem == SOC_BTN_REGEN)   { SocConsumeFor(oPC, nToken, nSelId, 4); return; }
        if (sElem == SOC_BTN_FULL)    { SocConsumeFor(oPC, nToken, nSelId, 5); return; }
        if (sElem == SOC_BTN_RELEASE) { SocReleaseCrystal(oPC, nToken, nSelId); return; }
    }

    if (sEvent == EVENT_TYPE_MOUSEDOWN && sElem == SOC_BTN_ROW)
    {
        json jCrystals = SocGetCrystals(oPC);
        if (nIdx < 0 || nIdx >= JsonGetLength(jCrystals)) return;

        json jRow = JsonArrayGet(jCrystals, nIdx);
        int  nId  = JsonGetInt(JsonObjectGet(jRow, "id"));

        SetLocalInt(oPC, SOC_LVAR_SEL_ID, nId);
        SocFeedList  (oPC, nToken);
        SocFeedDetail(oPC, nToken);
    }
}

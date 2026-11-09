#include "lib_mrel"

// Called by NUI framework when any event fires for windows owned by this script.
void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, MREL_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, MREL_LVAR_SEL_SLOT);
        DeleteLocalInt(oPC, MREL_LVAR_ATTUNING);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK || sEvent == EVENT_TYPE_MOUSEDOWN)
    {
        // ---- Close button ----
        if(sElem == MREL_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        // ---- Slot row selection ----
        if(sElem == MREL_BTN_ROW)
        {
            int nSlot = nIdx + 1;
            if(nSlot < 1 || nSlot > MREL_SLOT_COUNT) return;
            SetLocalInt(oPC, MREL_LVAR_SEL_SLOT, nSlot);
            MrelFeedRelicList(oPC, nToken);
            MrelFeedDetail(oPC, nToken);
            return;
        }

        // ---- Attune: enter targeting mode ----
        if(sElem == MREL_BTN_ATTUNE)
        {
            int nSel = GetLocalInt(oPC, MREL_LVAR_SEL_SLOT);
            // If nothing selected, default to first empty slot
            if(nSel < 1 || nSel > MREL_SLOT_COUNT)
            {
                string sUuid = GetObjectUUID(oPC);
                int i;
                for(i = 1; i <= MREL_SLOT_COUNT; i++)
                {
                    json jR = MrelDbGetRelic(sUuid, i);
                    if(JsonGetType(jR) == JSON_TYPE_NULL) { nSel = i; break; }
                }
            }
            if(nSel < 1) { SendMessageToPC(oPC, "[Relikwia] Wszystkie sloty są zajęte."); return; }

            SetLocalInt(oPC, MREL_LVAR_SEL_SLOT, nSel);
            SetLocalInt(oPC, MREL_LVAR_ATTUNING, nSel);
            EnterTargetingMode(oPC, OBJECT_TYPE_ITEM);
            SendMessageToPC(oPC, "[Relikwia] Kliknij przedmiot z ekwipunku, który chcesz poświęcić (slot "
                + IntToString(nSel) + ").");
            return;
        }

        // ---- Remove relic ----
        if(sElem == MREL_BTN_REMOVE)
        {
            int nSel = GetLocalInt(oPC, MREL_LVAR_SEL_SLOT);
            if(nSel < 1 || nSel > MREL_SLOT_COUNT) return;
            MrelRemoveRelic(oPC, nSel);
            DeleteLocalInt(oPC, MREL_LVAR_SEL_SLOT);
            MrelFeedRelicList(oPC, nToken);
            MrelFeedDetail(oPC, nToken);
            return;
        }

        // ---- Blood offering ----
        if(sElem == MREL_BTN_BLOOD)
        {
            int nSel = GetLocalInt(oPC, MREL_LVAR_SEL_SLOT);
            if(nSel < 1 || nSel > MREL_SLOT_COUNT) return;

            json jRelic = MrelDbGetRelic(GetObjectUUID(oPC), nSel);
            if(JsonGetType(jRelic) == JSON_TYPE_NULL) return;

            int nHunger = JsonGetInt(JsonObjectGet(jRelic, "hunger"));
            if(nHunger < 2)
            {
                SendMessageToPC(oPC, "[Relikwia] Ta relikwia jest jeszcze zbyt słaba, by pić twoją krew. Nasyć ją wpierw wspomnieniami.");
                return;
            }
            if(GetCurrentHitPoints(oPC) <= MREL_BLOOD_COST_HP + 5)
            {
                SendMessageToPC(oPC, "[Relikwia] Masz za mało krwi, by składać ofiary. Żyj, zanim zapomnisz jak.");
                return;
            }

            // Inflict non-lethal-ish damage (magical, so cannot overkill via resistances usually)
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectDamage(MREL_BLOOD_COST_HP, DAMAGE_TYPE_MAGICAL, DAMAGE_POWER_NORMAL), oPC);

            SetLocalInt(oPC, "MREL_LAST_TRIG_" + IntToString(nSel), MREL_TRIG_SURVIVE);
            MrelFeedMemory(oPC, MREL_BLOOD_MEMORY_GAIN, MREL_TRIG_SURVIVE);

            FloatingTextStringOnCreature("-" + IntToString(MREL_BLOOD_COST_HP) + " PŻ (ofiara krwi)", oPC, FALSE);
            return;
        }

        // ---- Force wake ----
        if(sElem == MREL_BTN_WAKE)
        {
            int nSel = GetLocalInt(oPC, MREL_LVAR_SEL_SLOT);
            if(nSel < 1 || nSel > MREL_SLOT_COUNT) return;

            json jRelic = MrelDbGetRelic(GetObjectUUID(oPC), nSel);
            if(JsonGetType(jRelic) == JSON_TYPE_NULL) return;

            int nHunger = JsonGetInt(JsonObjectGet(jRelic, "hunger"));
            int nMem    = JsonGetInt(JsonObjectGet(jRelic, "memory"));
            int nMemMax = MrelMemMax(nHunger);

            if(nMem < nMemMax)
            {
                SendMessageToPC(oPC, "[Relikwia] Puls jest zbyt słaby. Relikwia potrzebuje więcej wspomnień ("
                    + IntToString(nMem) + "/" + IntToString(nMemMax) + ").");
                return;
            }
            MrelWakeRelic(oPC, nSel);
            return;
        }
    }
}

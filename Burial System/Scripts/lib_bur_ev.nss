#include "lib_bur"

// ----------------------------------------------------------------
// Main NUI event handler — assigned to both BUR_WIN and BUR_WIN_DESECRATE
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    // ---- Desecrate confirmation popup ----
    if(nToken == NuiFindWindow(oPC, BUR_WIN_DESECRATE))
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            int nGraveId = GetLocalInt(oPC, BUR_LVAR_SEL_GRAVE);
            if(sElem == BUR_BTN_DES_CONFIRM)
            {
                NuiDestroy(oPC, nToken);
                BurDesecrate(oPC, nGraveId);
            }
            else if(sElem == BUR_BTN_DES_CANCEL)
            {
                NuiDestroy(oPC, nToken);
            }
        }
        return;
    }

    if(nToken != NuiFindWindow(oPC, BUR_WIN)) return;

    // ---- Window closed ----
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalObject(oPC, BUR_LVAR_TARGET_OBJ);
        DeleteLocalString(oPC, BUR_LVAR_VICTIM_NAME);
        DeleteLocalInt   (oPC, BUR_LVAR_SEL_GRAVE);
        DeleteLocalInt   (oPC, BUR_LVAR_TARGETING);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        // Close button
        if(sElem == BUR_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        // Open targeting mode to pick a corpse
        if(sElem == BUR_BTN_BURY_NEW)
        {
            NuiDestroy(oPC, nToken);
            SetLocalInt(oPC, BUR_LVAR_TARGETING, 1);
            EnterTargetingMode(oPC, OBJECT_TYPE_CREATURE);
            SendMessageToPC(oPC, "[Pochówek] Wskaż ciało poległego wroga.");
            return;
        }

        // Back from rite view to register
        if(sElem == BUR_BTN_CANCEL)
        {
            DeleteLocalObject(oPC, BUR_LVAR_TARGET_OBJ);
            DeleteLocalString(oPC, BUR_LVAR_VICTIM_NAME);
            BurSwapToRegister(oPC, nToken);
            return;
        }

        // Rite selection
        if(sElem == BUR_BTN_RITE0)
        {
            BurApplyRite(oPC, BUR_RITE_SIMPLE,
                GetLocalObject(oPC, BUR_LVAR_TARGET_OBJ));
            return;
        }
        if(sElem == BUR_BTN_RITE1)
        {
            BurApplyRite(oPC, BUR_RITE_HONORED,
                GetLocalObject(oPC, BUR_LVAR_TARGET_OBJ));
            return;
        }
        if(sElem == BUR_BTN_RITE2)
        {
            BurApplyRite(oPC, BUR_RITE_CURSED,
                GetLocalObject(oPC, BUR_LVAR_TARGET_OBJ));
            return;
        }

        // Meditate at selected grave
        if(sElem == BUR_BTN_MEDITATE)
        {
            int nGraveId = GetLocalInt(oPC, BUR_LVAR_SEL_GRAVE);
            if(nGraveId > 0)
                BurMeditate(oPC, nGraveId);
            return;
        }

        // Request desecration with confirmation popup
        if(sElem == BUR_BTN_DESECRATE)
        {
            int nGraveId = GetLocalInt(oPC, BUR_LVAR_SEL_GRAVE);
            if(nGraveId > 0)
                BurShowDesecrateConfirm(oPC, nGraveId);
            return;
        }
    }

    // ---- Grave row click — select + show details ----
    if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == BUR_BTN_ROW)
    {
        json jGraves = BurGetMyGraves(oPC);
        if(nIdx < 0 || nIdx >= JsonGetLength(jGraves)) return;

        json jRow    = JsonArrayGet(jGraves, nIdx);
        int  nId     = JsonGetInt   (JsonObjectGet(jRow, "id"));
        string sVic  = JsonGetString(JsonObjectGet(jRow, "victim_name"));
        int  nRite   = JsonGetInt   (JsonObjectGet(jRow, "rite_type"));
        int  nDes    = JsonGetInt   (JsonObjectGet(jRow, "desecrated"));

        SetLocalInt(oPC, BUR_LVAR_SEL_GRAVE, nId);

        string sInfo = sVic + "\n" + BurRiteName(nRite) + "\n" + BurRiteDesc(nRite);
        if(nDes) sInfo = sInfo + "\n\n[Ten grób jest zbezczeszczony.]";
        NuiSetBind(oPC, nToken, BUR_BIND_INFO, JsonString(sInfo));

        NuiSetBind(oPC, nToken, BUR_BIND_MEDITATE_ENA,  JsonBool(TRUE));
        NuiSetBind(oPC, nToken, BUR_BIND_DESECRATE_ENA, JsonBool(!nDes));

        // Highlight selected row
        int nCount = JsonGetLength(jGraves);
        json jEncs = JsonArray();
        int i;
        for(i = 0; i < nCount; i++)
            jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
        NuiSetBind(oPC, nToken, BUR_BIND_ROW_ENC, jEncs);
        return;
    }
}

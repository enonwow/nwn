// lib_lfg_ev.nss
// LFG/LFM system - NUI event handler

#include "lib_lfg"

void main()
{
    object oPC      = NuiGetEventPlayer();
    int    nToken   = NuiGetEventWindow();
    string sEvent   = NuiGetEventType();
    string sElem    = NuiGetEventElement();
    int    nIdx     = NuiGetEventArrayIndex();

    // --------------------------------------------------------
    // OPEN
    // --------------------------------------------------------
    if(sEvent == EVENT_TYPE_OPEN)
    {
        LfgSwapToStart(oPC, nToken);
        return;
    }

    // --------------------------------------------------------
    // CLOSE
    // --------------------------------------------------------
    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC,    LFG_LVAR_TOKEN);
        DeleteLocalString(oPC, LFG_LVAR_CATEGORY);
        DeleteLocalString(oPC, LFG_LVAR_MODE);
        DeleteLocalString(oPC, LFG_LVAR_SEL_UUID);
        DeleteLocalString(oPC, LFG_LVAR_PREV_VIEW);
        DeleteLocalJson(oPC,   LFG_LVAR_LIST_UUIDS);
        DeleteLocalJson(oPC,   LFG_LVAR_PEND_UUIDS);
        DeleteLocalJson(oPC,   LFG_LVAR_FORM_CL_IDS);
        DeleteLocalJson(oPC,   LFG_LVAR_FORM_CL_AV);
        return;
    }

    // --------------------------------------------------------
    // WATCH (form field changes)
    // --------------------------------------------------------
    if(sEvent == EVENT_TYPE_WATCH)
    {
        LfgValidateForm(oPC, nToken);
        return;
    }

    // --------------------------------------------------------
    // CLICK
    // --------------------------------------------------------
    if(sEvent != EVENT_TYPE_CLICK && sEvent != EVENT_TYPE_MOUSEDOWN) return;

    // --- Start screen ---

    if(sElem == LFG_BTN_LFM && sEvent == EVENT_TYPE_CLICK)
    {
        SetLocalString(oPC, LFG_LVAR_MODE, LFG_MODE_LFM);
        // If already an active LFM leader - go directly to active view
        if(LfgIsLeader(oPC))
        {
            LfgSwapToLfmActive(oPC, nToken);
        }
        else
        {
            LfgSwapToCategories(oPC, nToken);
        }
        return;
    }

    if(sElem == LFG_BTN_LFG && sEvent == EVENT_TYPE_CLICK)
    {
        SetLocalString(oPC, LFG_LVAR_MODE, LFG_MODE_LFG);
        LfgSwapToCategories(oPC, nToken);
        return;
    }

    if(sElem == LFG_BTN_LIST && sEvent == EVENT_TYPE_CLICK)
    {
        if(LfgIsLeader(oPC))
        {
            SetLocalString(oPC, LFG_LVAR_MODE, LFG_MODE_LFM);
            LfgSwapToLfmActive(oPC, nToken);
        }
        else
        {
            SetLocalString(oPC, LFG_LVAR_MODE, LFG_MODE_LFG);
            SetLocalString(oPC, LFG_LVAR_CATEGORY, LFG_CAT_ALL);
            LfgSwapToLfgList(oPC, nToken);
        }
        return;
    }

    // --- Close button (X) - destroy window, listing stays active ---
    if(sElem == LFG_BTN_CLOSE && sEvent == EVENT_TYPE_CLICK)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    // --- Back button ---
    if(sElem == LFG_BTN_BACK && sEvent == EVENT_TYPE_CLICK)
    {
        string sPrev = GetLocalString(oPC, LFG_LVAR_PREV_VIEW);
        if(sPrev == "categories") LfgSwapToCategories(oPC, nToken);
        else if(sPrev == "start") LfgSwapToStart(oPC, nToken);
        // else: na Start - nic nie rób (przycisk niewidoczny)
        return;
    }

    // --- Category buttons ---
    if(sEvent == EVENT_TYPE_CLICK &&
       (sElem == LFG_BTN_CAT_EXP || sElem == LFG_BTN_CAT_DUN ||
        sElem == LFG_BTN_CAT_RP  || sElem == LFG_BTN_CAT_PVP ||
        sElem == LFG_BTN_CAT_ALL))
    {
        string sCat = LFG_CAT_ALL;
        if(sElem == LFG_BTN_CAT_EXP) sCat = LFG_CAT_EXP;
        else if(sElem == LFG_BTN_CAT_DUN) sCat = LFG_CAT_DUNGEON;
        else if(sElem == LFG_BTN_CAT_RP)  sCat = LFG_CAT_RP;
        else if(sElem == LFG_BTN_CAT_PVP) sCat = LFG_CAT_PVP;

        SetLocalString(oPC, LFG_LVAR_CATEGORY, sCat);

        string sMode = GetLocalString(oPC, LFG_LVAR_MODE);
        if(sMode == LFG_MODE_LFM)
            LfgSwapToLfmForm(oPC, nToken);
        else
            LfgSwapToLfgList(oPC, nToken, "categories");
        return;
    }

    // --- LFM form ---

    if(sElem == LFG_BTN_FORM_ADD && sEvent == EVENT_TYPE_CLICK)
    {
        // Add selected class to restriction list
        int nSel = JsonGetInt(NuiGetBind(oPC, nToken, LFG_BIND_FORM_CL_SEL));
        json jAvail = GetLocalJson(oPC, LFG_LVAR_FORM_CL_AV);
        if(JsonGetLength(jAvail) == 0) return;

        // Get class ID from available list (same order as combo)
        // jAvail is built same order as combo entries
        if(nSel < 0 || nSel >= JsonGetLength(jAvail)) return;
        int nClassId = JsonGetInt(JsonArrayGet(jAvail, nSel));

        // Prevent duplicates
        json jCurrent = GetLocalJson(oPC, LFG_LVAR_FORM_CL_IDS);
        int i, nLen = JsonGetLength(jCurrent);
        for(i = 0; i < nLen; i++)
        {
            if(JsonGetInt(JsonArrayGet(jCurrent, i)) == nClassId) return;
        }

        jCurrent = JsonArrayInsert(jCurrent, JsonInt(nClassId));
        SetLocalJson(oPC, LFG_LVAR_FORM_CL_IDS, jCurrent);
        LfgRefreshRestrictions(oPC, nToken);
        return;
    }

    if(sElem == LFG_BTN_FORM_REM && sEvent == EVENT_TYPE_CLICK)
    {
        // Remove class at index nIdx from restriction list
        json jCurrent = GetLocalJson(oPC, LFG_LVAR_FORM_CL_IDS);
        if(nIdx < 0 || nIdx >= JsonGetLength(jCurrent)) return;
        jCurrent = JsonArrayDel(jCurrent, nIdx);
        SetLocalJson(oPC, LFG_LVAR_FORM_CL_IDS, jCurrent);
        LfgRefreshRestrictions(oPC, nToken);
        return;
    }

    if(sElem == LFG_BTN_FORM_CRE && sEvent == EVENT_TYPE_CLICK)
    {
        // Only leader of a party can create LFM
        if(GetFactionLeader(oPC) != oPC)
        {
            SendMessageToPC(oPC, "Only the party leader can create an LFM listing.");
            return;
        }
        if(LfgIsLeader(oPC))
        {
            SendMessageToPC(oPC, "You already have an active LFM listing.");
            return;
        }

        string sName  = JsonGetString(NuiGetBind(oPC, nToken, LFG_BIND_FORM_NAME));
        string sDesc  = JsonGetString(NuiGetBind(oPC, nToken, LFG_BIND_FORM_DESC));
        int nLimit    = StringToInt(JsonGetString(NuiGetBind(oPC, nToken, LFG_BIND_FORM_LIMIT)));
        int nLvlMin   = StringToInt(JsonGetString(NuiGetBind(oPC, nToken, LFG_BIND_FORM_LVLMIN)));
        int nLvlMax   = StringToInt(JsonGetString(NuiGetBind(oPC, nToken, LFG_BIND_FORM_LVLMAX)));

        // Resolve category
        string sCat = GetLocalString(oPC, LFG_LVAR_CATEGORY);
        if(sCat == LFG_CAT_ALL)
        {
            // User picked from combo
            int nCatSel = JsonGetInt(NuiGetBind(oPC, nToken, LFG_BIND_FORM_CAT_SEL));
            sCat = LfgCatByIndex(nCatSel);
        }

        json jClasses = GetLocalJson(oPC, LFG_LVAR_FORM_CL_IDS);

        LfgGroupCreate(
            GetObjectUUID(oPC),
            GetName(oPC),
            sName,
            sDesc,
            nLimit,
            nLvlMin,
            nLvlMax,
            sCat,
            jClasses);

        // Clear all pending LFG applications - player is now an LFM leader
        LfgApplicantClear(GetObjectUUID(oPC));

        SetLocalString(oPC, LFG_LVAR_MODE, LFG_MODE_LFM);
        LfgSwapToLfmActive(oPC, nToken);
        return;
    }

    // --- LFM active ---

    if(sElem == LFG_BTN_ACT_INV && sEvent == EVENT_TYPE_CLICK)
    {
        // Accept the pending application at index nIdx
        json jUuids = GetLocalJson(oPC, LFG_LVAR_PEND_UUIDS);
        if(nIdx < 0 || nIdx >= JsonGetLength(jUuids)) return;
        string sAppUuid = JsonGetString(JsonArrayGet(jUuids, nIdx));
        string sLdrUuid = GetObjectUUID(oPC);
        LfgAcceptApplication(sLdrUuid, sAppUuid);
        if(LfgIsLeader(oPC))
            LfgRefreshPending(oPC, nToken);
        else
            LfgSwapToStart(oPC, nToken);
        return;
    }

    if(sElem == LFG_BTN_ACT_CAN && sEvent == EVENT_TYPE_CLICK)
    {
        // Cancel LFM listing
        string sUuid = GetObjectUUID(oPC);
        json jGroup  = LfgGroupGet(sUuid);
        if(JsonGetType(jGroup) != JSON_TYPE_NULL)
        {
            // Notify pending applicants
            json jPending = JsonObjectGet(jGroup, LFG_FIELD_PENDING);
            int i, nLen = JsonGetLength(jPending);
            for(i = 0; i < nLen; i++)
            {
                string sAppUuid = JsonGetString(JsonArrayGet(jPending, i));
                object oApp = GetObjectByUUID(sAppUuid);
                if(GetIsObjectValid(oApp))
                    SendMessageToPC(oApp, "The LFM group you applied to has been cancelled.");
                LfgApplicantRemove(sAppUuid, sUuid);
            }
            LfgGroupRemove(sUuid);
        }
        LfgSwapToStart(oPC, nToken);
        return;
    }

    // --- LFG list ---

    if(sElem == LFG_BTN_LIST_ROW && sEvent == EVENT_TYPE_MOUSEDOWN)
    {
        // Highlight row
        NuiOffEncouragedData(oPC, nToken);
        NuiOnEncouragedData(oPC, nToken, nIdx);

        // Store selected UUID
        json jUuids = GetLocalJson(oPC, LFG_LVAR_LIST_UUIDS);
        if(nIdx >= 0 && nIdx < JsonGetLength(jUuids))
            SetLocalString(oPC, LFG_LVAR_SEL_UUID, JsonGetString(JsonArrayGet(jUuids, nIdx)));
        return;
    }

    if(sElem == LFG_BTN_LIST_ACT && sEvent == EVENT_TYPE_CLICK)
    {
        json jUuids = GetLocalJson(oPC, LFG_LVAR_LIST_UUIDS);
        if(nIdx < 0 || nIdx >= JsonGetLength(jUuids)) return;
        string sLdrUuid = JsonGetString(JsonArrayGet(jUuids, nIdx));
        string sPcUuid  = GetObjectUUID(oPC);

        if(LfgApplicantHasApplied(sPcUuid, sLdrUuid))
        {
            // Cancel application
            LfgPendingRemove(sLdrUuid, sPcUuid);
            LfgApplicantRemove(sPcUuid, sLdrUuid);
            LfgRefreshList(oPC, nToken);
        }
        else
        {
            // Apply to join
            if(!LfgCanApply(oPC))
            {
                SendMessageToPC(oPC, "You have reached the maximum of " +
                    IntToString(LFG_MAX_APPLICATIONS) + " pending applications.");
                return;
            }

            // Check class restrictions
            json jGroup = LfgGroupGet(sLdrUuid);
            if(JsonGetType(jGroup) == JSON_TYPE_NULL) return;

            json jClasses = JsonObjectGet(jGroup, LFG_FIELD_CLASSES);
            if(!LfgClassesMatch(oPC, jClasses))
            {
                SendMessageToPC(oPC, "Your party does not meet the class requirements.");
                return;
            }

            LfgPendingAdd(sLdrUuid, sPcUuid);
            LfgApplicantAdd(sPcUuid, sLdrUuid);

            // Notify LFM leader
            object oLeader = GetObjectByUUID(sLdrUuid);
            if(GetIsObjectValid(oLeader))
                SendMessageToPC(oLeader, GetName(oPC) + "'s party has applied to join your group.");

            LfgRefreshList(oPC, nToken);
        }
        return;
    }
}

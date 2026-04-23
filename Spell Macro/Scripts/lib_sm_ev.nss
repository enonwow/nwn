#include "lib_sm"

void main()
{
    object oPC      = NuiGetEventPlayer();
    int    nToken   = NuiGetEventWindow();
    string sWinId   = NuiGetWindowId(oPC, nToken);
    string sEvent   = NuiGetEventType();
    string sElement = NuiGetEventElement();
    int    nIdx     = NuiGetEventArrayIndex();

    // --------------------------------------------------------------------------
    //  MAIN WINDOW
    // --------------------------------------------------------------------------
    if(sWinId == SM_WIN_MENU)
    {
        if(sEvent == SM_EVENT_CLOSE)
        {
            int nPicker = NuiFindWindow(oPC, SM_WIN_ICON_PICKER);
            if(nPicker > 0) NuiDestroy(oPC, nPicker);
            SetLocalInt(oPC, SM_LVAR_SEL_IDX, -1);
            DeleteLocalJson(oPC, SM_LVAR_SPELLS);
            DeleteLocalJson(oPC, "SM_SPELL_LIST");
            DeleteLocalJson(oPC, "SM_CLS_IDS");
            return;
        }

        // Menu: select row
        if(sEvent == SM_EVENT_MOUSEDOWN && sElement == SM_BTN_M_ROW)
        {
            json jAll = SmLoadAll(oPC);
            if(nIdx < 0 || nIdx >= JsonGetLength(jAll)) return;

            json jEntry = JsonArrayGet(jAll, nIdx);
            int nSeqIdx = JsonGetInt(JsonObjectGet(jEntry, "idx"));

            SmOffEnc(oPC, nToken, SM_BIND_M_ENC, SM_BIND_M_ROW);
            SmOnEnc(oPC, nToken, SM_BIND_M_ENC, SM_BIND_M_ROW, nIdx);

            SetLocalInt(oPC, SM_LVAR_SEL_IDX, nSeqIdx);
            NuiSetBind(oPC, nToken, SM_BIND_M_CAST_EN, JsonBool(TRUE));
            NuiSetBind(oPC, nToken, SM_BIND_M_EDIT_EN, JsonBool(TRUE));
            NuiSetBind(oPC, nToken, SM_BIND_M_DEL_EN,  JsonBool(TRUE));
            return;
        }

        // Create: select spell from list
        if(sEvent == SM_EVENT_MOUSEDOWN && sElement == SM_BTN_C_SP_ROW)
        {
            SmOffEnc(oPC, nToken, SM_BIND_C_SPELL_ENC, SM_BIND_C_SPELL_ROW);
            SmOnEnc(oPC, nToken, SM_BIND_C_SPELL_ENC, SM_BIND_C_SPELL_ROW, nIdx);
            NuiSetBind(oPC, nToken, SM_BIND_C_ADD_EN, JsonBool(TRUE));
            return;
        }

        // Watch: filter changes ? refresh spell list; name change ? update Save
        if(sEvent == SM_EVENT_WATCH)
        {
            if(sElement == SM_BIND_C_CLS_IDX)
            {
                SmRebuildLevels(oPC, nToken);
                FeedSmCreate(oPC, nToken);
                return;
            }

            if(sElement == SM_BIND_C_TARGET_MODE)
            {
                if(GetLocalInt(oPC, "SM_SUPPRESS_TM"))
                {
                    DeleteLocalInt(oPC, "SM_SUPPRESS_TM");
                    FeedSmCreate(oPC, nToken);
                    return;
                }
                SetLocalJson(oPC, SM_LVAR_SPELLS, JsonArray());
                FeedSmSelected(oPC, nToken);
                FeedSmCreate(oPC, nToken);
                SendMessageToPC(oPC, "Spell sequence cleared.");
                return;
            }

            if(sElement == SM_BIND_C_LVL_IDX
            || sElement == SM_BIND_C_META_IDX)
            {
                FeedSmCreate(oPC, nToken);
                return;
            }

            if(sElement == SM_BIND_C_SEQ_NAME)
            {
                FeedSmSelected(oPC, nToken);
                return;
            }

            if(sElement == SM_BIND_C_SPELL_SEARCH)
            {
                FeedSmCreate(oPC, nToken);
                return;
            }
        }

        if(sEvent == SM_EVENT_CLICK)
        {
            // -- Menu view buttons ---------------------------------------------
            if(sElement == SM_BTN_NEW)
            {
                json jAll = SmLoadAll(oPC);
                if(JsonGetLength(jAll) >= SM_MAX_SEQ)
                {
                    SendMessageToPC(oPC, "<c=#FF4444>Macro limit reached: " + IntToString(SM_MAX_SEQ) + ".</c>");
                    return;
                }
                SwapToCreateView(oPC, nToken, -1);
                return;
            }

            if(sElement == SM_BTN_CAST)
            {
                int nSeqIdx = GetLocalInt(oPC, SM_LVAR_SEL_IDX);
                if(nSeqIdx < 0) return;
                json jData = SmLoadByIdx(oPC, nSeqIdx);
                if(JsonGetType(jData) == JSON_TYPE_NULL) return;
                SmExecute(oPC, JsonObjectGet(jData, "spells"), JsonGetInt(JsonObjectGet(jData, "target_mode")));
                return;
            }

            if(sElement == SM_BTN_EDIT)
            {
                int nSeqIdx = GetLocalInt(oPC, SM_LVAR_SEL_IDX);
                if(nSeqIdx < 0) return;
                SwapToCreateView(oPC, nToken, nSeqIdx);
                return;
            }

            if(sElement == SM_BTN_DELETE)
            {
                int nSeqIdx = GetLocalInt(oPC, SM_LVAR_SEL_IDX);
                if(nSeqIdx < 0) return;
                json jData = SmLoadByIdx(oPC, nSeqIdx);
                if(JsonGetType(jData) == JSON_TYPE_NULL) return;
                string sName = JsonGetString(JsonObjectGet(jData, "name"));
                CreateSmDeletePopup(oPC, sName);
                return;
            }

            // -- Create view buttons -------------------------------------------
            if(sElement == SM_BTN_C_ADD)
            {
                json jSeq = GetLocalJson(oPC, SM_LVAR_SPELLS);
                if(JsonGetLength(jSeq) >= SM_MAX_SPELLS)
                {
                    SendMessageToPC(oPC, "<c=#FF4444>Maximum spells per macro: " + IntToString(SM_MAX_SPELLS) + "</c>");
                    return;
                }

                json jRow = NuiGetBind(oPC, nToken, SM_BIND_C_SPELL_ROW);
                if(JsonGetType(jRow) != JSON_TYPE_INTEGER) return;
                int nSpellRow = JsonGetInt(jRow);

                json jSpellList = GetLocalJson(oPC, "SM_SPELL_LIST");
                if(nSpellRow < 0 || nSpellRow >= JsonGetLength(jSpellList)) return;

                json jSpell = JsonArrayGet(jSpellList, nSpellRow);

                json jCls_ids     = GetLocalJson(oPC, "SM_CLS_IDS");
                int  nClsComboIdx = JsonGetInt(NuiGetBind(oPC, nToken, SM_BIND_C_CLS_IDX));
                int  nClassId     = JsonGetInt(JsonArrayGet(jCls_ids, nClsComboIdx));
                int  nLevel       = JsonGetInt(NuiGetBind(oPC, nToken, SM_BIND_C_LVL_IDX));

                int  nMeta  = JsonGetInt(JsonObjectGet(jSpell, SM_F_META));
                int bDomain = JsonGetInt(JsonObjectGet(jSpell, SM_F_DOMAIN));

                json jEntry = JsonObject();
                jEntry = JsonObjectSet(jEntry, SM_F_ID,     JsonObjectGet(jSpell, SM_F_ID));
                jEntry = JsonObjectSet(jEntry, SM_F_NAME,   JsonObjectGet(jSpell, SM_F_NAME));
                jEntry = JsonObjectSet(jEntry, SM_F_ICON,   JsonObjectGet(jSpell, SM_F_ICON));
                jEntry = JsonObjectSet(jEntry, SM_F_CLASS,  JsonInt(nClassId));
                jEntry = JsonObjectSet(jEntry, SM_F_LEVEL,  JsonInt(nLevel));
                jEntry = JsonObjectSet(jEntry, SM_F_META,        JsonInt(nMeta));
                jEntry = JsonObjectSet(jEntry, SM_F_DOMAIN,      JsonInt(bDomain));
                jEntry = JsonObjectSet(jEntry, SM_F_DOMAIN_ICON, JsonObjectGet(jSpell, SM_F_DOMAIN_ICON));

                jSeq = JsonArrayInsert(jSeq, jEntry);
                SetLocalJson(oPC, SM_LVAR_SPELLS, jSeq);
                FeedSmSelected(oPC, nToken);
                return;
            }

            if(GetStringLeft(sElement, 16) == SM_BTN_C_DEL_SEL)
            {
                int nDelIdx = StringToInt(GetStringRight(sElement, GetStringLength(sElement) - 16));
                json jSeq = GetLocalJson(oPC, SM_LVAR_SPELLS);
                if(nDelIdx < 0 || nDelIdx >= JsonGetLength(jSeq)) return;
                jSeq = JsonArrayDel(jSeq, nDelIdx);
                SetLocalJson(oPC, SM_LVAR_SPELLS, jSeq);
                FeedSmSelected(oPC, nToken);
                return;
            }

            if(sElement == SM_BTN_SAVE)
            {
                string sName = JsonGetString(NuiGetBind(oPC, nToken, SM_BIND_C_SEQ_NAME));
                json   jSeq  = GetLocalJson(oPC, SM_LVAR_SPELLS);
                if(sName == "" || JsonGetLength(jSeq) == 0) return;

                string sIcon = JsonGetString(NuiGetBind(oPC, nToken, SM_BIND_C_ICON));
                if(sIcon == "") sIcon = SM_ICO_DEFAULT;

                int nEditIdx = GetLocalInt(oPC, SM_LVAR_EDIT_IDX);
                int nSaveIdx = (nEditIdx >= 0) ? nEditIdx : SmNextFreeIdx(oPC);
                if(nSaveIdx < 0)
                {
                    SendMessageToPC(oPC, "<c=#FF4444>No free macro slot available.</c>");
                    return;
                }

                int nTargetMode = JsonGetInt(NuiGetBind(oPC, nToken, SM_BIND_C_TARGET_MODE));
                SmSave(oPC, nSaveIdx, sName, jSeq, sIcon, nTargetMode);
                SwapToMenuView(oPC, nToken);
                return;
            }

            if(sElement == SM_BTN_C_ICON_PICK)
            {
                SmCreateIconPicker(oPC, nToken);
                return;
            }

            if(sElement == SM_BTN_BACK)
            {
                SwapToMenuView(oPC, nToken);
                return;
            }
        }
    }

    // --------------------------------------------------------------------------
    //  DELETE CONFIRM POPUP
    // --------------------------------------------------------------------------
    if(sWinId == SM_WIN_DELETE)
    {
        if(sEvent == SM_EVENT_CLICK && sElement == SM_BTN_DEL_CONFIRM)
        {
            int nSeqIdx = GetLocalInt(oPC, SM_LVAR_SEL_IDX);
            SmDelete(oPC, nSeqIdx);
            NuiDestroy(oPC, nToken);

            int nMenuToken = NuiFindWindow(oPC, SM_WIN_MENU);
            if(nMenuToken > 0) SwapToMenuView(oPC, nMenuToken);
            return;
        }

        if(sEvent == SM_EVENT_CLICK && sElement == SM_BTN_DEL_CANCEL)
        {
            NuiDestroy(oPC, nToken);
            return;
        }
    }

    // --------------------------------------------------------------------------
    //  ICON PICKER
    // --------------------------------------------------------------------------
    if(sWinId == SM_WIN_ICON_PICKER)
    {
        if(sEvent == SM_EVENT_WATCH && sElement == SM_BIND_ICO_SEARCH)
        {
            string sFilter = JsonGetString(NuiGetBind(oPC, nToken, SM_BIND_ICO_SEARCH));
            SmRebuildIconGrid(oPC, nToken, sFilter);
            return;
        }

        if(sEvent == SM_EVENT_CLICK && GetStringLeft(sElement, 9) == SM_ICO_BTN_PFX)
        {
            int nCacheIdx = StringToInt(GetStringRight(sElement, GetStringLength(sElement) - 9));
            json jCache = SmGetIconCache();
            if(nCacheIdx < 0 || nCacheIdx >= JsonGetLength(jCache)) return;
            string sResref = JsonGetString(JsonObjectGet(JsonArrayGet(jCache, nCacheIdx), "r"));
            int nParentToken = GetLocalInt(oPC, SM_LVAR_ICO_PARENT);
            if(nParentToken > 0)
                NuiSetBind(oPC, nParentToken, SM_BIND_C_ICON, JsonString(sResref));
            NuiDestroy(oPC, nToken);
            return;
        }
    }
}

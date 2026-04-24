#include "lib_mail"

void MailHandleClaimAttachments(object oPC, int nToken, int nMailId)
{
    json jMsg = MailGetMessage(nMailId);
    if(JsonGetType(jMsg) == JSON_TYPE_NULL) return;

    int nGold    = JsonGetInt(JsonObjectGet(jMsg, "gold"));
    string sItems = JsonGetString(JsonObjectGet(jMsg, "items_json"));
    int nClaimed = JsonGetInt(JsonObjectGet(jMsg, "is_claimed"));

    if(nClaimed) return;

    if(nGold > 0)
        GiveGoldToCreature(oPC, nGold);

    json jItems = JsonParse(sItems);
    int nCount  = JsonGetLength(jItems);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jItemData = JsonArrayGet(jItems, i);
        JsonToObject(jItemData, GetLocation(oPC), oPC, TRUE);
    }

    MailMarkClaimed(nMailId);

    if(nCount > 0)
        SendMessageToPC(oPC, "[Mail] Items received ? check your inventory.");
    if(nGold > 0)
        SendMessageToPC(oPC, "[Mail] Received " + IntToString(nGold) + " gold.");

    FeedMailBody(oPC, nToken, nMailId);
}

void MailHandleSend(object oPC, int nToken)
{
    string sRecipUuid = GetLocalString(oPC, MAIL_LVAR_RECIP_UUID);
    string sRecipName = GetLocalString(oPC, MAIL_LVAR_RECIP_NAME);

    if(sRecipUuid == "")
    {
        SendMessageToPC(oPC, "[Mail] No recipient selected.");
        return;
    }

    string sSubject = JsonGetString(NuiGetBind(oPC, nToken, MAIL_BIND_SUBJ_TXT));
    string sBody    = JsonGetString(NuiGetBind(oPC, nToken, MAIL_BIND_BODY_TXT));
    string sGoldStr = JsonGetString(NuiGetBind(oPC, nToken, MAIL_BIND_GOLD_TXT));
    int nGold       = StringToInt(sGoldStr);
    if(nGold < 0 || GetGold(oPC) < nGold)
    {
        SendMessageToPC(oPC, "[Mail] Not enough gold.");
        return;
    }

    if(MailGetRecipientCount(sRecipUuid) >= MAIL_MAX_INBOX)
    {
        SendMessageToPC(oPC, "[Mail] Recipient's inbox is full.");
        return;
    }

    json jSlots = GetLocalJson(oPC, MAIL_LVAR_SLOTS);
    int nItemCount = JsonGetLength(jSlots);

    // Build items_json for storage: serialize each item object
    json jItemsJson = JsonArray();
    int i;
    for(i = 0; i < nItemCount; i++)
    {
        json jSlot   = JsonArrayGet(jSlots, i);
        string sUUID = JsonGetString(JsonObjectGet(jSlot, "uuid"));
        object oItem = GetObjectByTag(sUUID); // won't work ? need stored serialized json
        // Items were serialized at pickup time; retrieve stored json
        json jSerial = JsonObjectGet(jSlot, "obj_json");
        jItemsJson = JsonArrayInsert(jItemsJson, jSerial);
    }

    // Deduct gold
    if(nGold > 0)
        AssignCommand(oPC, TakeGoldFromCreature(nGold, oPC, TRUE));

    MailSend(oPC, sRecipUuid, sSubject, sBody, jItemsJson, nGold);

    // Notify online recipient
    MailNotifyOnline(sRecipUuid, GetName(oPC));

    SendMessageToPC(oPC, "[Mail] Message sent to " + sRecipName + ".");

    SwapToInboxView(oPC, nToken);
}

void MailHandleSlotClick(object oPC, int nToken, int nSlotIdx)
{
    json jSlots = GetLocalJson(oPC, MAIL_LVAR_SLOTS);
    int nCount  = JsonGetLength(jSlots);

    if(nSlotIdx < nCount)
    {
        // Remove item from slot ? item already taken from inventory on add, so it's lost unless we restore it
        // Item was stored as obj_json ? recreate in PC inventory
        json jSlot  = JsonArrayGet(jSlots, nSlotIdx);
        json jSerial = JsonObjectGet(jSlot, "obj_json");
        JsonToObject(jSerial, GetLocation(oPC), oPC, TRUE);

        // Remove slot from array
        json jNew = JsonArray();
        int i;
        for(i = 0; i < nCount; i++)
        {
            if(i != nSlotIdx)
                jNew = JsonArrayInsert(jNew, JsonArrayGet(jSlots, i));
        }
        SetLocalJson(oPC, MAIL_LVAR_SLOTS, jNew);
        FeedMailSlots(oPC, nToken);
    }
    else if(nCount < MAIL_MAX_ITEMS)
    {
        // Empty slot clicked ? enter cursor-select mode
        NuiSetBind(oPC, nToken, MAIL_BIND_SEND_ENA, JsonBool(FALSE));
        EnterTargetingMode(oPC, OBJECT_TYPE_ITEM);
        // nSlotIdx stored so OnPlayerTarget knows which slot to fill
        SetLocalInt(oPC, "MAIL_TARGETING_SLOT", nSlotIdx);
        SendMessageToPC(oPC, "[Mail] Click an item in your inventory to attach it.");
    }
}

// ----------------------------------------------------------------
// Main event handler
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    // ---- New mail notification icon ----
    if(nToken == NuiFindWindow(oPC, MAIL_WIN_NOTIFY))
    {
        if(sEvent == EVENT_TYPE_CLICK && sElem == MAIL_BTN_NOTIFY)
            NuiDestroy(oPC, nToken);
        return;
    }

    // ---- Delete confirmation popup ----
    if(nToken == NuiFindWindow(oPC, MAIL_WIN_DEL_CONFIRM))
    {
        if(sEvent == EVENT_TYPE_CLICK)
        {
            if(sElem == MAIL_BTN_DEL_CONFIRM)
            {
                int nId = GetLocalInt(oPC, MAIL_LVAR_PENDING_DEL);
                MailDelete(nId);
                DeleteLocalInt(oPC, MAIL_LVAR_PENDING_DEL);
                SetLocalInt(oPC, MAIL_LVAR_SEL_ID, 0);
                NuiDestroy(oPC, NuiFindWindow(oPC, MAIL_WIN_DEL_CONFIRM));
                int nMailToken = NuiFindWindow(oPC, MAIL_WINDOW);
                if(nMailToken) FeedMailInbox(oPC, nMailToken);
            }
            else if(sElem == MAIL_BTN_DEL_CANCEL)
            {
                NuiDestroy(oPC, NuiFindWindow(oPC, MAIL_WIN_DEL_CONFIRM));
            }
        }
        return;
    }

    // ---- Search popup ----
    if(nToken == NuiFindWindow(oPC, MAIL_WIN_SEARCH))
    {
        if(sEvent == EVENT_TYPE_MOUSEDOWN && sElem == MAIL_BTN_RESULT_ROW)
        {
            json jRes = GetLocalJson(oPC, MAIL_LVAR_SEARCH_RES);
            if(nIdx < 0 || nIdx >= JsonGetLength(jRes)) return;
            json jEntry  = JsonArrayGet(jRes, nIdx);
            string sUuid = JsonGetString(JsonObjectGet(jEntry, "uuid"));
            string sName = JsonGetString(JsonObjectGet(jEntry, "char_name"));

            SetLocalString(oPC, MAIL_LVAR_RECIP_UUID, sUuid);
            SetLocalString(oPC, MAIL_LVAR_RECIP_NAME, sName);

            NuiDestroy(oPC, nToken);

            int nMailToken = NuiFindWindow(oPC, MAIL_WINDOW);
            if(nMailToken)
            {
                NuiSetBind(oPC, nMailToken, MAIL_BIND_RECIP_LBL, JsonString("To: " + sName));
                string sSub = JsonGetString(NuiGetBind(oPC, nMailToken, MAIL_BIND_SUBJ_TXT));
                string sBod = JsonGetString(NuiGetBind(oPC, nMailToken, MAIL_BIND_BODY_TXT));
                NuiSetBind(oPC, nMailToken, MAIL_BIND_SEND_ENA, JsonBool(sSub != "" || sBod != ""));
            }
        }
        return;
    }

    if(nToken != NuiFindWindow(oPC, MAIL_WINDOW)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        // Return any pending attachment items to PC
        json jSlots = GetLocalJson(oPC, MAIL_LVAR_SLOTS);
        int nCount  = JsonGetLength(jSlots);
        int i;
        for(i = 0; i < nCount; i++)
        {
            json jSlot   = JsonArrayGet(jSlots, i);
            json jSerial = JsonObjectGet(jSlot, "obj_json");
            JsonToObject(jSerial, GetLocation(oPC), oPC, TRUE);
        }
        DeleteLocalJson(oPC, MAIL_LVAR_SLOTS);
        DeleteLocalString(oPC, MAIL_LVAR_RECIP_UUID);
        DeleteLocalString(oPC, MAIL_LVAR_RECIP_NAME);
        DeleteLocalInt(oPC, MAIL_LVAR_SEL_ID);
        DeleteLocalInt(oPC, MAIL_LVAR_SEL_CLAIMED);
        DeleteLocalInt(oPC, MAIL_LVAR_SEL_HAS_ATT);
        DeleteLocalInt(oPC, MAIL_LVAR_PENDING_DEL);
        return;
    }

    // ---- Watch: subject / body — update Send enabled ----
    if(sEvent == EVENT_TYPE_WATCH && (sElem == MAIL_BIND_SUBJ_TXT || sElem == MAIL_BIND_BODY_TXT))
    {
        string sSubj  = JsonGetString(NuiGetBind(oPC, nToken, MAIL_BIND_SUBJ_TXT));
        string sBody  = JsonGetString(NuiGetBind(oPC, nToken, MAIL_BIND_BODY_TXT));
        int bRecip    = (GetLocalString(oPC, MAIL_LVAR_RECIP_UUID) != "");
        NuiSetBind(oPC, nToken, MAIL_BIND_SEND_ENA, JsonBool(bRecip && (sSubj != "" || sBody != "")));
        return;
    }

    // ---- Watch: gold field validation ----
    if(sEvent == EVENT_TYPE_WATCH && sElem == MAIL_BIND_GOLD_TXT)
    {
        string sVal = JsonGetString(NuiGetBind(oPC, nToken, MAIL_BIND_GOLD_TXT));
        int nVal    = StringToInt(sVal);
        if(sVal != "" && sVal != "0" && nVal <= 0)
            SendMessageToPC(oPC, "[Mail] Gold must be a whole positive number.");
        return;
    }

    // ---- Inbox buttons ----
    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == MAIL_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }
        if(sElem == MAIL_BTN_COMPOSE)
        {
            SwapToComposeView(oPC, nToken);
            return;
        }
        if(sElem == MAIL_BTN_CLAIM)
        {
            int nId = GetLocalInt(oPC, MAIL_LVAR_SEL_ID);
            if(nId > 0)
                MailHandleClaimAttachments(oPC, nToken, nId);
            return;
        }
        if(sElem == MAIL_BTN_DELETE)
        {
            int nId = GetLocalInt(oPC, MAIL_LVAR_SEL_ID);
            if(nId <= 0) return;
            int bHasAtt = GetLocalInt(oPC, MAIL_LVAR_SEL_HAS_ATT);
            int bClaimed = GetLocalInt(oPC, MAIL_LVAR_SEL_CLAIMED);
            if(bHasAtt && !bClaimed)
                CreateMailDeletePopup(oPC, nId);
            else
            {
                MailDelete(nId);
                SetLocalInt(oPC, MAIL_LVAR_SEL_ID, 0);
                FeedMailInbox(oPC, nToken);
            }
            return;
        }

        // ---- Compose buttons ----
        if(sElem == MAIL_BTN_BACK)
        {
            // Return unsent attachments
            json jSlots = GetLocalJson(oPC, MAIL_LVAR_SLOTS);
            int nCount  = JsonGetLength(jSlots);
            int i;
            for(i = 0; i < nCount; i++)
            {
                json jSlot   = JsonArrayGet(jSlots, i);
                json jSerial = JsonObjectGet(jSlot, "obj_json");
                JsonToObject(jSerial, GetLocation(oPC), oPC, TRUE);
            }
            DeleteLocalJson(oPC, MAIL_LVAR_SLOTS);
            SwapToInboxView(oPC, nToken);
            return;
        }
if(sElem == MAIL_BTN_SEARCH)
        {
            string sQuery = JsonGetString(NuiGetBind(oPC, nToken, MAIL_BIND_SEARCH_TXT));
            if(sQuery == "")
            {
                SendMessageToPC(oPC, "[Mail] Enter a name to search.");
                return;
            }
            json jRes = MailSearchPlayers(sQuery, oPC);
            if(JsonGetLength(jRes) == 0)
            {
                SendMessageToPC(oPC, "[Mail] No players found. They must log in at least once.");
                return;
            }
            SetLocalJson(oPC, MAIL_LVAR_SEARCH_RES, jRes);
            CreateMailSearchPopup(oPC, jRes);
            return;
        }
        if(sElem == MAIL_BTN_SEND)
        {
            MailHandleSend(oPC, nToken);
            return;
        }

        // Attachment slot click
        if(GetStringLeft(sElem, GetStringLength(MAIL_BTN_SLOT)) == MAIL_BTN_SLOT)
        {
            int nSlotIdx = StringToInt(GetStringRight(sElem, GetStringLength(sElem) - GetStringLength(MAIL_BTN_SLOT)));
            MailHandleSlotClick(oPC, nToken, nSlotIdx);
            return;
        }
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN)
    {
        // Mail row click ? inbox
        if(sElem == MAIL_BTN_ROW)
        {
            json jInbox = MailGetInbox(oPC);
            if(nIdx < 0 || nIdx >= JsonGetLength(jInbox)) return;
            json jRow = JsonArrayGet(jInbox, nIdx);
            int nId   = JsonGetInt(JsonObjectGet(jRow, "id"));

            // Encourage clicked row
            int nCount = JsonGetLength(jInbox);
            json jEncs = JsonArray();
            int i;
            for(i = 0; i < nCount; i++)
                jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
            NuiSetBind(oPC, nToken, MAIL_BIND_ROW_ENC, jEncs);

            FeedMailBody(oPC, nToken, nId);
            return;
        }

    }
}

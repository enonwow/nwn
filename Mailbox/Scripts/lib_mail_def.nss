#include "lib_nui"
#include "sql_mail"

void FeedMailSlots(object oPC, int nToken);
void FeedMailInbox(object oPC, int nToken);
void MailShowNotification(object oPC);

// ----------------------------------------------------------------
// Constants
// ----------------------------------------------------------------

const string MAIL_WINDOW      = "MAIL_WINDOW";
const string MAIL_EV_SCRIPT   = "lib_mail_ev";
const string MAIL_GRP_SWAP    = "MAIL_GRP_SWAP";
const string MAIL_WIN_GEOM    = "mail_win_geom";

// Inbox binds
const string MAIL_BIND_TITLE        = "mail_title";
const string MAIL_BIND_ROW_SENDER   = "mail_row_sender";
const string MAIL_BIND_ROW_SUBJECT  = "mail_row_subject";
const string MAIL_BIND_ROW_DATE     = "mail_row_date";
const string MAIL_BIND_ROW_HAS_GOLD = "mail_row_hasgold";
const string MAIL_BIND_ROW_HAS_ITEM = "mail_row_hasitem";
const string MAIL_BIND_ROW_COLOR    = "mail_row_color";
const string MAIL_BIND_ROW_ENC      = "mail_row_enc";
const string MAIL_BIND_ROW_ATT_COLOR= "mail_row_attcolor";
const string MAIL_BIND_ROW_STATUS   = "mail_row_status";
const string MAIL_BIND_BODY         = "mail_body";
const string MAIL_BIND_CLAIM_LBL    = "mail_claim_lbl";
const string MAIL_BIND_CLAIM_ENA    = "mail_claim_ena";
const string MAIL_BIND_DEL_ENA      = "mail_del_ena";

// Compose binds
const string MAIL_BIND_SEARCH_TXT   = "mail_search_txt";
const string MAIL_BIND_RESULT_NAME  = "mail_res_name";
const string MAIL_BIND_RESULT_ENC   = "mail_res_enc";
const string MAIL_BIND_RESULT_VIS   = "mail_res_vis";
const string MAIL_BIND_RECIP_LBL    = "mail_recip_lbl";
const string MAIL_BIND_SUBJ_TXT     = "mail_subj_txt";
const string MAIL_BIND_BODY_TXT     = "mail_body_txt";
const string MAIL_BIND_GOLD_TXT     = "mail_gold_txt";
const string MAIL_BIND_SLOT_IMG     = "mail_slot_img";
const string MAIL_BIND_SLOT_LBL     = "mail_slot_lbl";
const string MAIL_BIND_SLOT_ENA     = "mail_slot_ena";
const string MAIL_BIND_ATT_CNT      = "mail_att_cnt";
const string MAIL_BIND_SEND_ENA     = "mail_send_ena";

// Notification icon window (top-left, appears on new mail)
const string MAIL_WIN_NOTIFY        = "MAIL_WIN_NOTIFY";
const string MAIL_BTN_NOTIFY        = "mail_btn_notify";
const string MAIL_BIND_NOTIFY_TIP   = "mail_notify_tip";
const string MAIL_BIND_NOTIFY_GEOM  = "mail_notify_geom";
const string MAIL_NOTIFY_ICON       = "mail_icon";         // resref -- add to HAK

// Delete confirmation (inline popup window)
const string MAIL_WIN_DEL_CONFIRM   = "MAIL_WIN_DEL";

// Search popup window
const string MAIL_WIN_SEARCH        = "MAIL_WIN_SEARCH";

// Buttons
const string MAIL_BTN_CLOSE         = "mail_btn_close";
const string MAIL_BTN_COMPOSE       = "mail_btn_compose";
const string MAIL_BTN_CLAIM         = "mail_btn_claim";
const string MAIL_BTN_DELETE        = "mail_btn_delete";
const string MAIL_BTN_BACK          = "mail_btn_back";
const string MAIL_BTN_SEND          = "mail_btn_send";
const string MAIL_BTN_SEARCH        = "mail_btn_search";
const string MAIL_BTN_CLEAR_RECIP   = "mail_btn_clrrecip";
const string MAIL_BTN_ROW           = "mail_btn_row";
const string MAIL_BTN_RESULT_ROW    = "mail_btn_res_row";
const string MAIL_BTN_SLOT          = "mail_btn_slot";      // + IntToString(i)
const string MAIL_BTN_DEL_CONFIRM   = "mail_btn_delconf";
const string MAIL_BTN_DEL_CANCEL    = "mail_btn_delcancel";

// LVARs on PC
const string MAIL_LVAR_SEL_ID       = "MAIL_SEL_ID";       // selected mail id
const string MAIL_LVAR_SEL_CLAIMED  = "MAIL_SEL_CLAIMED";
const string MAIL_LVAR_SEL_HAS_ATT  = "MAIL_SEL_HAS_ATT";  // 1 = has unclaimed items/gold
const string MAIL_LVAR_RECIP_UUID   = "MAIL_RECIP_UUID";
const string MAIL_LVAR_RECIP_NAME   = "MAIL_RECIP_NAME";
const string MAIL_LVAR_SLOTS        = "MAIL_SLOTS_JSON";    // JsonArray of {obj_json, resref, stack}
const string MAIL_LVAR_SEARCH_RES   = "MAIL_SEARCH_RES";    // JsonArray of {uuid, name}
const string MAIL_LVAR_PENDING_DEL  = "MAIL_PENDING_DEL";   // id of mail pending delete confirm

// Limits
const int    MAIL_MAX_INBOX         = 20;
const int    MAIL_MAX_ITEMS         = 10;
const int    MAIL_SUBJECT_MAX       = 60;
const int    MAIL_BODY_MAX          = 500;

// Layout
const float  MAIL_W                 = 800.0;
const float  MAIL_H                 = 550.0;

// ----------------------------------------------------------------
// Notification helper
// ----------------------------------------------------------------

void MailNotifyOnline(string sRecipientUuid, string sSenderName)
{
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(GetObjectUUID(oPC) == sRecipientUuid)
        {
            FloatingTextStringOnCreature("You have new mail from " + sSenderName + "!", oPC, FALSE);
            SendMessageToPC(oPC, "[Mail] New message from " + sSenderName + ".");
            int nToken = NuiFindWindow(oPC, MAIL_WINDOW);
            if(nToken != 0)
                FeedMailInbox(oPC, nToken);
            MailShowNotification(oPC);
            return;
        }
        oPC = GetNextPC();
    }
}

void MailOnPlayerTarget(object oPC)
{
    int nToken = NuiFindWindow(oPC, MAIL_WINDOW);
    if(nToken == 0) return;

    object oItem = GetTargetingModeSelectedObject();
    if(!GetIsObjectValid(oItem) || GetItemPossessor(oItem) != oPC)
    {
        SendMessageToPC(oPC, "[Mail] You can only attach items from your inventory.");
        NuiSetBind(oPC, nToken, MAIL_BIND_SEND_ENA, JsonBool(GetLocalString(oPC, MAIL_LVAR_RECIP_UUID) != ""));
        return;
    }

    json jSlots = GetLocalJson(oPC, MAIL_LVAR_SLOTS);
    if(JsonGetLength(jSlots) >= MAIL_MAX_ITEMS)
    {
        SendMessageToPC(oPC, "[Mail] Maximum " + IntToString(MAIL_MAX_ITEMS) + " attachments.");
        NuiSetBind(oPC, nToken, MAIL_BIND_SEND_ENA, JsonBool(TRUE));
        return;
    }

    json jSerial = ObjectToJson(oItem, TRUE);
    string sName = GetName(oItem);
    string sRes  = GetResRef(oItem);
    int nStack   = GetItemStackSize(oItem);
    string sIcon = Get2DAString("baseitems", "DefaultIcon", GetBaseItemType(oItem));

    json jSlot = JsonObject();
    jSlot = JsonObjectSet(jSlot, "obj_json", jSerial);
    jSlot = JsonObjectSet(jSlot, "resref",   JsonString(sRes));
    jSlot = JsonObjectSet(jSlot, "name",     JsonString(sName));
    jSlot = JsonObjectSet(jSlot, "stack",    JsonInt(nStack));
    jSlot = JsonObjectSet(jSlot, "icon",     JsonString(sIcon));

    jSlots = JsonArrayInsert(jSlots, jSlot);
    SetLocalJson(oPC, MAIL_LVAR_SLOTS, jSlots);

    DestroyObject(oItem);

    NuiSetBind(oPC, nToken, MAIL_BIND_SEND_ENA, JsonBool(GetLocalString(oPC, MAIL_LVAR_RECIP_UUID) != ""));
    FeedMailSlots(oPC, nToken);
}

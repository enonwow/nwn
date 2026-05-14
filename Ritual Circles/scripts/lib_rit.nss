// lib_rit.nss - Ritual Circles: NUI layout, window management, core game logic

#include "lib_rit_def"

// ============================================================
// NUI layout
// ============================================================

json RitBuildLayout(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 32.0);
    float fRowH  = GetNuiScaleDimension(oPC, 30.0);
    float fTypeH = GetNuiScaleDimension(oPC, 36.0);

    json jCol = JsonArray();

    // Header label (ritual name or "Opuszczony Krąg")
    {
        json jLbl = NuiLabel(NuiBind(RIT_BIND_HEADER),
            JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
        jLbl = NuiHeight(jLbl, GetNuiScaleDimension(oPC, 28.0));
        jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jLbl)));
    }

    // State label (color: gold)
    {
        json jLbl = NuiLabel(NuiBind(RIT_BIND_STATUS),
            JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
        jLbl = NuiStyleForegroundColor(jLbl, GetNuiColorNwnGold());
        jLbl = NuiHeight(jLbl, GetNuiScaleDimension(oPC, 22.0));
        jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jLbl)));
    }

    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));

    // Ritual type list (hidden during CASTING / COOLDOWN)
    {
        // Template: one button per row showing the type name
        json jTmpl = JsonArray();
        json jBtn = NuiId(NuiButton(NuiBind(RIT_BIND_TYPE_NAMES)), RIT_BTN_TYPE_ROW);
        jBtn = NuiEncouraged(jBtn, NuiBind(RIT_BIND_TYPE_ENC));
        jBtn = NuiHeight(jBtn, fTypeH);
        jTmpl = JsonArrayInsert(jTmpl, NuiListTemplateCell(jBtn, 0.0, TRUE));

        json jList = NuiList(jTmpl, JsonInt(RIT_TYPE_COUNT), fTypeH);
        float fListH = GetNuiScaleDimension(oPC, 160.0);
        jList = NuiHeight(jList, fListH);

        json jGrp = NuiGroup(NuiCol(JsonArrayInsert(JsonArray(), jList)), FALSE, NUI_SCROLLBARS_NONE);
        jGrp = NuiVisible(jGrp, NuiBind(RIT_BIND_TYPE_VIS));
        jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jGrp)));
    }

    // Flavor / description text
    {
        json jLbl = NuiLabel(NuiBind(RIT_BIND_FLAVOR),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
        jLbl = NuiHeight(jLbl, GetNuiScaleDimension(oPC, 72.0));
        jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jLbl)));
    }

    // Requirements label
    {
        json jLbl = NuiLabel(NuiBind(RIT_BIND_REQ_LABEL),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
        jLbl = NuiHeight(jLbl, GetNuiScaleDimension(oPC, 22.0));
        jLbl = NuiStyleForegroundColor(jLbl, NuiColor(200, 130, 80));
        jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jLbl)));
    }

    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));

    // Participants header
    {
        json jLbl = NuiLabel(NuiBind(RIT_BIND_PART_HEADER),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
        jLbl = NuiHeight(jLbl, GetNuiScaleDimension(oPC, 20.0));
        jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jLbl)));
    }

    // Participants list
    {
        json jTmpl = JsonArray();
        json jNameLbl = NuiLabel(NuiBind(RIT_BIND_PART_NAMES),
            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
        jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(RIT_BIND_PART_COLORS));
        jTmpl = JsonArrayInsert(jTmpl, NuiListTemplateCell(jNameLbl, 0.0, TRUE));

        json jList = NuiList(jTmpl, NuiBind(RIT_BIND_PART_LEN), fRowH);
        jList = NuiHeight(jList, GetNuiScaleDimension(oPC, 120.0));
        jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jList)));
    }

    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));

    // Progress bar + time label (visible only during CASTING)
    {
        json jProg = NuiProgressBar(NuiBind(RIT_BIND_PROGRESS));
        jProg = NuiVisible(jProg, NuiBind(RIT_BIND_PROG_VIS));
        jProg = NuiHeight(jProg, GetNuiScaleDimension(oPC, 18.0));
        jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jProg)));

        json jTimeLbl = NuiLabel(NuiBind(RIT_BIND_PROG_LABEL),
            JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
        jTimeLbl = NuiVisible(jTimeLbl, NuiBind(RIT_BIND_PROG_VIS));
        jTimeLbl = NuiHeight(jTimeLbl, GetNuiScaleDimension(oPC, 18.0));
        jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jTimeLbl)));
    }

    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 0.0)); // elastic spacer

    // Action buttons
    {
        json jBtns = JsonArray();

        json jJoin = NuiId(NuiButton(JsonString("Dołącz")), RIT_BTN_JOIN);
        jJoin = NuiEnabled(jJoin, NuiBind(RIT_BIND_JOIN_ENA));
        jJoin = NuiWidth(jJoin, GetNuiScaleDimension(oPC, 90.0));
        jJoin = NuiHeight(jJoin, fBtnH);

        json jLeave = NuiId(NuiButton(JsonString("Opuść")), RIT_BTN_LEAVE);
        jLeave = NuiEnabled(jLeave, NuiBind(RIT_BIND_LEAVE_ENA));
        jLeave = NuiWidth(jLeave, GetNuiScaleDimension(oPC, 90.0));
        jLeave = NuiHeight(jLeave, fBtnH);

        json jBegin = NuiId(NuiButton(JsonString("Zainicjuj Rytuał")), RIT_BTN_BEGIN);
        jBegin = NuiEnabled(jBegin, NuiBind(RIT_BIND_BEGIN_ENA));
        jBegin = NuiWidth(jBegin, GetNuiScaleDimension(oPC, 140.0));
        jBegin = NuiHeight(jBegin, fBtnH);

        json jCancel = NuiId(NuiButton(JsonString("Przerwij")), RIT_BTN_CANCEL);
        jCancel = NuiEnabled(jCancel, NuiBind(RIT_BIND_CANCEL_ENA));
        jCancel = NuiWidth(jCancel, GetNuiScaleDimension(oPC, 90.0));
        jCancel = NuiHeight(jCancel, fBtnH);

        jBtns = JsonArrayInsert(jBtns, jJoin);
        jBtns = JsonArrayInsert(jBtns, jLeave);
        jBtns = JsonArrayInsert(jBtns, NuiSpacer());
        jBtns = JsonArrayInsert(jBtns, jBegin);
        jBtns = JsonArrayInsert(jBtns, jCancel);

        jCol = JsonArrayInsert(jCol, NuiRow(jBtns));
    }

    return NuiCol(jCol);
}

// ============================================================
// Window open / feed
// ============================================================

void RitOpenWindow(object oPC, object oCircle)
{
    string sTag = GetTag(oCircle);
    SetLocalString(oPC, RIT_LVAR_CIRCLE, sTag);

    int nToken = NuiFindWindow(oPC, RIT_WINDOW);
    if(nToken != 0)
    {
        RitFeedWindow(oPC, nToken, sTag);
        return;
    }

    float fGuiW = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH));
    float fGuiH = IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT));
    float fW    = GetNuiScaleDimension(oPC, RIT_W);
    float fH    = GetNuiScaleDimension(oPC, RIT_H);
    float fCX   = (fGuiW - fW) / 2.0;
    float fCY   = (fGuiH - fH) / 2.0;

    json jWin = NuiWindow(
        RitBuildLayout(oPC),
        JsonString("Krąg Rytuału"),
        NuiRect(fCX, fCY, fW, fH),
        JsonBool(FALSE),  // resizable
        JsonBool(FALSE),  // collapsed
        JsonBool(TRUE),   // closable (native X button)
        JsonBool(FALSE),  // transparent
        JsonBool(TRUE));  // border

    nToken = NuiCreate(oPC, jWin, RIT_WINDOW, RIT_EV_SCRIPT);
    RitFeedWindow(oPC, nToken, sTag);
}

void RitFeedWindow(object oPC, int nToken, string sTag)
{
    json jData = RitGetCircle(sTag);
    if(JsonGetType(jData) == JSON_TYPE_NULL) return;

    int    nState      = JsonGetInt   (JsonObjectGet(jData, "state"));
    int    nType       = JsonGetInt   (JsonObjectGet(jData, "ritual_type"));
    string sLeaderUUID = JsonGetString(JsonObjectGet(jData, "leader_uuid"));
    json   jParts      = JsonParse(JsonGetString(JsonObjectGet(jData, "participants_json")));
    int    nCastStart  = JsonGetInt   (JsonObjectGet(jData, "cast_start"));
    int    nNow        = RitGetUnixTime();
    int    nPartCount  = JsonGetLength(jParts);

    int bIsParticipant = RitIsParticipant(oPC, sTag);
    int bIsLeader      = (GetObjectUUID(oPC) == sLeaderUUID && sLeaderUUID != "");

    // Header
    string sHeader = (nType != RIT_TYPE_NONE && nState != RIT_STATE_IDLE)
                   ? RitTypeName(nType)
                   : "Opuszczony Krąg";
    NuiSetBind(oPC, nToken, RIT_BIND_HEADER, JsonString(sHeader));

    // State label
    NuiSetBind(oPC, nToken, RIT_BIND_STATUS, JsonString(RitStateName(nState)));

    // Flavor text
    string sFlavor;
    if(nState == RIT_STATE_IDLE)
        sFlavor = "Kamienie kręgu są zimne. Czeka na tych, którzy przybędą z ofiarą w dłoniach.";
    else if(nState == RIT_STATE_COOLDOWN)
        sFlavor = "Krąg drży jeszcze od mocy ostatniego rytuału. Powietrze pachnie popiołem i krwią.";
    else if(nType != RIT_TYPE_NONE)
        sFlavor = RitTypeDesc(nType);
    else
        sFlavor = "Wybierz rytuał, by poznać jego opis.";
    NuiSetBind(oPC, nToken, RIT_BIND_FLAVOR, JsonString(sFlavor));

    // Requirements text (only when type is chosen and not on cooldown)
    string sReq = "";
    if(nType != RIT_TYPE_NONE && nState != RIT_STATE_COOLDOWN)
    {
        int nMin = RitTypeMinParts(nType);
        sReq = "Min. " + IntToString(nMin) + " uczestników · Lider niesie: " + RitTypeItemName(nType);
        if(bIsLeader && !RitLeaderHasItem(sTag))
            sReq += "  [BRAK!]";
    }
    NuiSetBind(oPC, nToken, RIT_BIND_REQ_LABEL, JsonString(sReq));

    // Type list visibility
    int bTypeVis = (nState == RIT_STATE_IDLE || nState == RIT_STATE_GATHERING);
    NuiSetBind(oPC, nToken, RIT_BIND_TYPE_VIS, JsonBool(bTypeVis));

    // Ritual type list rows
    {
        json jNames = JsonArray();
        json jEncs  = JsonArray();
        int i;
        for(i = 1; i <= RIT_TYPE_COUNT; i++)
        {
            string sEntry = RitTypeName(i)
                + "  (min. " + IntToString(RitTypeMinParts(i)) + " os."
                + ", wymaga: " + RitTypeItemName(i) + ")";
            jNames = JsonArrayInsert(jNames, JsonString(sEntry));
            jEncs  = JsonArrayInsert(jEncs,  JsonBool(i == nType));
        }
        NuiSetBind(oPC, nToken, RIT_BIND_TYPE_NAMES, jNames);
        NuiSetBind(oPC, nToken, RIT_BIND_TYPE_ENC,   jEncs);
    }

    // Participants list
    {
        json jNames  = JsonArray();
        json jColors = JsonArray();
        int i;
        for(i = 0; i < nPartCount; i++)
        {
            string sUUID = JsonGetString(JsonArrayGet(jParts, i));
            string sName = RitGetNameByUUID(sUUID);
            if(sUUID == sLeaderUUID)
                sName = "[Lider] " + sName;
            jNames  = JsonArrayInsert(jNames,  JsonString(sName));
            json jColor = (sUUID == sLeaderUUID)
                        ? NuiColor(210, 170, 60)
                        : NuiColor(200, 200, 200);
            jColors = JsonArrayInsert(jColors, jColor);
        }
        int nMin = (nType != RIT_TYPE_NONE) ? RitTypeMinParts(nType) : 2;
        string sPartHdr = "Uczestnicy (" + IntToString(nPartCount) + " / " + IntToString(nMin) + " min.):";
        NuiSetBind(oPC, nToken, RIT_BIND_PART_HEADER, JsonString(sPartHdr));
        NuiSetBind(oPC, nToken, RIT_BIND_PART_NAMES,  jNames);
        NuiSetBind(oPC, nToken, RIT_BIND_PART_COLORS, jColors);
        NuiSetBind(oPC, nToken, RIT_BIND_PART_LEN,    JsonInt(nPartCount));
    }

    // Progress bar (CASTING only)
    int bProgVis = (nState == RIT_STATE_CASTING);
    NuiSetBind(oPC, nToken, RIT_BIND_PROG_VIS, JsonBool(bProgVis));
    if(bProgVis)
    {
        int nElapsed  = nNow - nCastStart;
        if(nElapsed < 0) nElapsed = 0;
        float fProg   = IntToFloat(nElapsed) / IntToFloat(RIT_CASTING_SEC);
        if(fProg > 1.0) fProg = 1.0;
        int nRemaining = RIT_CASTING_SEC - nElapsed;
        if(nRemaining < 0) nRemaining = 0;
        NuiSetBind(oPC, nToken, RIT_BIND_PROGRESS,  JsonFloat(fProg));
        NuiSetBind(oPC, nToken, RIT_BIND_PROG_LABEL,
            JsonString(IntToString(nRemaining) + " sek. pozostało..."));
    }
    else
    {
        NuiSetBind(oPC, nToken, RIT_BIND_PROGRESS,  JsonFloat(0.0));
        NuiSetBind(oPC, nToken, RIT_BIND_PROG_LABEL, JsonString(""));
    }

    // Button states
    int bCanJoin   = !bIsParticipant
                   && nState != RIT_STATE_CASTING
                   && nState != RIT_STATE_COOLDOWN
                   && nType  != RIT_TYPE_NONE;
    int bCanLeave  = bIsParticipant && nState != RIT_STATE_CASTING;
    int bCanBegin  = bIsLeader
                   && nState == RIT_STATE_GATHERING
                   && nPartCount >= RitTypeMinParts(nType)
                   && RitLeaderHasItem(sTag);
    int bCanCancel = bIsParticipant && nState == RIT_STATE_CASTING;

    NuiSetBind(oPC, nToken, RIT_BIND_JOIN_ENA,   JsonBool(bCanJoin));
    NuiSetBind(oPC, nToken, RIT_BIND_LEAVE_ENA,  JsonBool(bCanLeave));
    NuiSetBind(oPC, nToken, RIT_BIND_BEGIN_ENA,  JsonBool(bCanBegin));
    NuiSetBind(oPC, nToken, RIT_BIND_CANCEL_ENA, JsonBool(bCanCancel));
}

void RitUpdateAllWindows(string sTag)
{
    json jData = RitGetCircle(sTag);
    if(JsonGetType(jData) == JSON_TYPE_NULL) return;
    json jParts = JsonParse(JsonGetString(JsonObjectGet(jData, "participants_json")));
    int i, n = JsonGetLength(jParts);
    for(i = 0; i < n; i++)
    {
        object oMember = RitGetPCByUUID(JsonGetString(JsonArrayGet(jParts, i)));
        if(!GetIsObjectValid(oMember)) continue;
        int nToken = NuiFindWindow(oMember, RIT_WINDOW);
        if(nToken != 0) RitFeedWindow(oMember, nToken, sTag);
    }
}

void RitNotifyParticipants(string sTag, string sMsg)
{
    json jData = RitGetCircle(sTag);
    if(JsonGetType(jData) == JSON_TYPE_NULL) return;
    json jParts = JsonParse(JsonGetString(JsonObjectGet(jData, "participants_json")));
    int i, n = JsonGetLength(jParts);
    for(i = 0; i < n; i++)
    {
        object oMember = RitGetPCByUUID(JsonGetString(JsonArrayGet(jParts, i)));
        if(GetIsObjectValid(oMember))
            FloatingTextStringOnCreature(sMsg, oMember, FALSE);
    }
}

// ============================================================
// Core actions
// ============================================================

void RitJoin(object oPC, string sTag)
{
    json jData = RitGetCircle(sTag);
    if(JsonGetType(jData) == JSON_TYPE_NULL) return;

    int nState = JsonGetInt(JsonObjectGet(jData, "state"));
    if(nState == RIT_STATE_CASTING || nState == RIT_STATE_COOLDOWN)
    {
        SendMessageToPC(oPC, "[Rytuał] Krąg jest w trakcie rytuału lub odpoczywa.");
        return;
    }
    if(RitIsParticipant(oPC, sTag))
    {
        SendMessageToPC(oPC, "[Rytuał] Już uczestniczysz w tym rytuale.");
        return;
    }
    int nType = JsonGetInt(JsonObjectGet(jData, "ritual_type"));
    if(nType == RIT_TYPE_NONE)
    {
        SendMessageToPC(oPC, "[Rytuał] Najpierw wybierz typ rytuału.");
        return;
    }

    string sUUID  = GetObjectUUID(oPC);
    json jParts   = JsonParse(JsonGetString(JsonObjectGet(jData, "participants_json")));
    jParts        = JsonArrayInsert(jParts, JsonString(sUUID));
    jData         = JsonObjectSet(jData, "participants_json", JsonString(JsonDump(jParts)));

    // First participant becomes leader
    if(JsonGetString(JsonObjectGet(jData, "leader_uuid")) == "")
        jData = JsonObjectSet(jData, "leader_uuid", JsonString(sUUID));

    if(nState == RIT_STATE_IDLE)
        jData = JsonObjectSet(jData, "state", JsonInt(RIT_STATE_GATHERING));

    RitSetCircle(sTag, jData);
    FloatingTextStringOnCreature("Stoisz w kręgu, gotów do rytuału.", oPC, FALSE);
    RitUpdateAllWindows(sTag);
}

void RitLeave(object oPC, string sTag)
{
    if(!RitIsParticipant(oPC, sTag))
    {
        SendMessageToPC(oPC, "[Rytuał] Nie uczestniczysz w tym rytuale.");
        return;
    }
    json jData = RitGetCircle(sTag);
    int nState = JsonGetInt(JsonObjectGet(jData, "state"));
    if(nState == RIT_STATE_CASTING)
    {
        SendMessageToPC(oPC, "[Rytuał] Nie możesz opuścić kręgu w trakcie rytuału — użyj 'Przerwij'.");
        return;
    }

    string sUUID   = GetObjectUUID(oPC);
    json jOld      = JsonParse(JsonGetString(JsonObjectGet(jData, "participants_json")));
    json jNew      = JsonArray();
    int i, n = JsonGetLength(jOld);
    for(i = 0; i < n; i++)
        if(JsonGetString(JsonArrayGet(jOld, i)) != sUUID)
            jNew = JsonArrayInsert(jNew, JsonArrayGet(jOld, i));

    jData = JsonObjectSet(jData, "participants_json", JsonString(JsonDump(jNew)));

    // Reassign leader if the leaving PC was leader
    string sLeader = JsonGetString(JsonObjectGet(jData, "leader_uuid"));
    if(sLeader == sUUID)
    {
        if(JsonGetLength(jNew) > 0)
            jData = JsonObjectSet(jData, "leader_uuid", JsonArrayGet(jNew, 0));
        else
        {
            jData = JsonObjectSet(jData, "leader_uuid",   JsonString(""));
            jData = JsonObjectSet(jData, "ritual_type",   JsonInt(RIT_TYPE_NONE));
            jData = JsonObjectSet(jData, "state",         JsonInt(RIT_STATE_IDLE));
        }
    }
    if(JsonGetLength(jNew) == 0)
        jData = JsonObjectSet(jData, "state", JsonInt(RIT_STATE_IDLE));

    RitSetCircle(sTag, jData);
    DeleteLocalString(oPC, RIT_LVAR_CIRCLE);
    FloatingTextStringOnCreature("Opuszczasz krąg.", oPC, FALSE);
    RitUpdateAllWindows(sTag);
}

// Selecting a ritual type row also auto-joins the player as the first member.
void RitSetType(object oPC, string sTag, int nType)
{
    if(nType < RIT_TYPE_DARK_BLESSING || nType > RIT_TYPE_COUNT) return;

    json jData = RitGetCircle(sTag);
    int nState = JsonGetInt(JsonObjectGet(jData, "state"));
    if(nState == RIT_STATE_CASTING || nState == RIT_STATE_COOLDOWN)
    {
        SendMessageToPC(oPC, "[Rytuał] Nie można zmienić rytuału teraz.");
        return;
    }
    // Only the current leader (or anyone if circle is idle) may change the type
    string sLeaderUUID = JsonGetString(JsonObjectGet(jData, "leader_uuid"));
    if(sLeaderUUID != "" && sLeaderUUID != GetObjectUUID(oPC))
    {
        SendMessageToPC(oPC, "[Rytuał] Tylko lider może zmienić typ rytuału.");
        return;
    }

    jData = JsonObjectSet(jData, "ritual_type", JsonInt(nType));

    // Auto-join as leader if not yet a participant
    if(!RitIsParticipant(oPC, sTag))
    {
        string sUUID = GetObjectUUID(oPC);
        json jParts  = JsonParse(JsonGetString(JsonObjectGet(jData, "participants_json")));
        jParts       = JsonArrayInsert(jParts, JsonString(sUUID));
        jData        = JsonObjectSet(jData, "participants_json", JsonString(JsonDump(jParts)));
        jData        = JsonObjectSet(jData, "leader_uuid",       JsonString(sUUID));
        jData        = JsonObjectSet(jData, "state",             JsonInt(RIT_STATE_GATHERING));
        FloatingTextStringOnCreature("Przejmujesz inicjatywę. Jesteś liderem rytuału.", oPC, FALSE);
    }

    RitSetCircle(sTag, jData);
    RitUpdateAllWindows(sTag);
}

void RitBegin(object oPC, string sTag)
{
    if(!RitIsLeader(oPC, sTag))
    {
        SendMessageToPC(oPC, "[Rytuał] Tylko lider może zainicjować rytuał.");
        return;
    }

    json jData     = RitGetCircle(sTag);
    int  nState    = JsonGetInt(JsonObjectGet(jData, "state"));
    int  nType     = JsonGetInt(JsonObjectGet(jData, "ritual_type"));
    json jParts    = JsonParse(JsonGetString(JsonObjectGet(jData, "participants_json")));
    int  nCount    = JsonGetLength(jParts);
    int  nMin      = RitTypeMinParts(nType);

    if(nState != RIT_STATE_GATHERING)
    {
        SendMessageToPC(oPC, "[Rytuał] Krąg nie jest w trybie zbierania uczestników.");
        return;
    }
    if(nCount < nMin)
    {
        SendMessageToPC(oPC, "[Rytuał] Za mało uczestników. Potrzeba co najmniej "
            + IntToString(nMin) + ".");
        return;
    }
    if(!RitLeaderHasItem(sTag))
    {
        SendMessageToPC(oPC, "[Rytuał] Musisz posiadać: " + RitTypeItemName(nType) + ".");
        return;
    }

    // Consume the ritual item
    string sItemTag = RitTypeItemTag(nType);
    if(sItemTag != "")
    {
        object oItem = GetItemPossessedBy(oPC, sItemTag);
        if(GetIsObjectValid(oItem)) DestroyObject(oItem);
    }

    // Blood Binding: drain 20% HP from every participant (min 1 HP, cannot kill)
    if(nType == RIT_TYPE_BLOOD_BINDING)
    {
        int i;
        for(i = 0; i < nCount; i++)
        {
            object oMember = RitGetPCByUUID(JsonGetString(JsonArrayGet(jParts, i)));
            if(!GetIsObjectValid(oMember)) continue;
            int nMax  = GetMaxHitPoints(oMember);
            int nCost = nMax / 5;
            int nCur  = GetCurrentHitPoints(oMember);
            if(nCost >= nCur) nCost = nCur - 1;
            if(nCost > 0)
                ApplyEffectToObject(DURATION_TYPE_INSTANT,
                    EffectDamage(nCost, DAMAGE_TYPE_MAGICAL), oMember);
            FloatingTextStringOnCreature("Twoja krew spływa do kręgu...", oMember, FALSE);
        }
    }

    int nNow = RitGetUnixTime();
    jData = JsonObjectSet(jData, "state",      JsonInt(RIT_STATE_CASTING));
    jData = JsonObjectSet(jData, "cast_start", JsonInt(nNow));
    RitSetCircle(sTag, jData);

    RitNotifyParticipants(sTag,
        "Pieczęcie kręgu rozżarzają się krwistą czerwienią... Rytuał się rozpoczął.");
    RitUpdateAllWindows(sTag);
}

void RitCancel(object oPC, string sTag)
{
    json jData = RitGetCircle(sTag);
    if(JsonGetInt(JsonObjectGet(jData, "state")) != RIT_STATE_CASTING)
    {
        SendMessageToPC(oPC, "[Rytuał] Rytuał nie jest w toku.");
        return;
    }

    json jParts = JsonParse(JsonGetString(JsonObjectGet(jData, "participants_json")));
    int i, n = JsonGetLength(jParts);

    // Backlash: 2d6 magical damage + 6s stun on every participant
    for(i = 0; i < n; i++)
    {
        object oMember = RitGetPCByUUID(JsonGetString(JsonArrayGet(jParts, i)));
        if(!GetIsObjectValid(oMember)) continue;
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectDamage(d6(2), DAMAGE_TYPE_MAGICAL), oMember);
        effect eStun = ExtraordinaryEffect(EffectStunned());
        ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eStun, oMember, 6.0);
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectVisualEffect(VFX_COM_CHUNK_BONE_MEDIUM), oMember);
        FloatingTextStringOnCreature("Krąg wybucha! Niestabilna magia rani cię!", oMember, FALSE);
    }

    RitResetCircle(sTag);
    RitEnsureCircle(sTag);

    for(i = 0; i < n; i++)
    {
        object oMember = RitGetPCByUUID(JsonGetString(JsonArrayGet(jParts, i)));
        if(GetIsObjectValid(oMember))
        {
            DeleteLocalString(oMember, RIT_LVAR_CIRCLE);
            int nToken = NuiFindWindow(oMember, RIT_WINDOW);
            if(nToken != 0) RitFeedWindow(oMember, nToken, sTag);
        }
    }
}

// ============================================================
// Completion (called by heartbeat when channeling finishes)
// ============================================================

void RitComplete(string sTag, int nType, json jParts)
{
    int i;
    int n = JsonGetLength(jParts);

    // Fetch leader UUID before modifying the DB
    json jDataPre   = RitGetCircle(sTag);
    string sLeaderUUID = JsonGetString(JsonObjectGet(jDataPre, "leader_uuid"));

    if(nType == RIT_TYPE_DARK_BLESSING)
    {
        // +2 attack, +2 magical damage for 1 hour — tagged so it can be stripped
        for(i = 0; i < n; i++)
        {
            object oMember = RitGetPCByUUID(JsonGetString(JsonArrayGet(jParts, i)));
            if(!GetIsObjectValid(oMember)) continue;
            effect eAtk  = EffectAttackIncrease(2);
            effect eDmg  = EffectDamageIncrease(2, DAMAGE_TYPE_MAGICAL);
            effect eLink = TagEffect(EffectLinkEffects(eAtk, eDmg), "RIT_DARK_BLESSING");
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eLink, oMember, 3600.0);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_IMP_EVIL_HELP), oMember);
            FloatingTextStringOnCreature(
                "Mrok cię przyjął. Poczujesz jego siłę w walce.", oMember, FALSE);
        }
    }
    else if(nType == RIT_TYPE_BLOOD_BINDING)
    {
        // Heal every participant to 75% of their max HP
        for(i = 0; i < n; i++)
        {
            object oMember = RitGetPCByUUID(JsonGetString(JsonArrayGet(jParts, i)));
            if(!GetIsObjectValid(oMember)) continue;
            int nMax  = GetMaxHitPoints(oMember);
            int nCur  = GetCurrentHitPoints(oMember);
            int nHeal = (nMax * 3 / 4) - nCur;
            if(nHeal > 0)
                ApplyEffectToObject(DURATION_TYPE_INSTANT, EffectHeal(nHeal), oMember);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_IMP_HEALING_L), oMember);
            FloatingTextStringOnCreature(
                "Pakt krwi zostaje zapieczętowany. Rany się goją.", oMember, FALSE);
        }
    }
    else if(nType == RIT_TYPE_SOUL_CALLING)
    {
        // Summon a wraith that serves the leader for 30 minutes
        object oLeader = RitGetPCByUUID(sLeaderUUID);
        if(GetIsObjectValid(oLeader))
        {
            location lLdr = GetLocation(oLeader);
            ApplyEffectAtLocation(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_FNF_SUMMON_UNDEAD), lLdr);
            object oWraith = CreateObject(OBJECT_TYPE_CREATURE, "nw_shwraith", lLdr,
                FALSE, "RIT_WRAITH_SUMMON");
            if(GetIsObjectValid(oWraith))
            {
                // DEFENDER faction: fights hostiles, friendly to the party
                ChangeToStandardFaction(oWraith, STANDARD_FACTION_DEFENDER);
                AssignCommand(oWraith, ActionForceFollowObject(oLeader, 3.0));
                DelayCommand(1800.0, DestroyObject(oWraith));
            }
            FloatingTextStringOnCreature(
                "Z zaświatów odpowiada duch — zjawa słucha twej woli.", oLeader, FALSE);
        }
        for(i = 0; i < n; i++)
        {
            string sUUID = JsonGetString(JsonArrayGet(jParts, i));
            if(sUUID == sLeaderUUID) continue;
            object oMember = RitGetPCByUUID(sUUID);
            if(GetIsObjectValid(oMember))
                FloatingTextStringOnCreature(
                    "Rytuał przywołania zostaje spełniony.", oMember, FALSE);
        }
    }
    else if(nType == RIT_TYPE_CURSE_WEAVING)
    {
        // Each participant carries the curse outward: -2 to all saving throws for 1h.
        // Tagged "RIT_CURSE_WEAVING" so a server hook can strip it on demand.
        for(i = 0; i < n; i++)
        {
            object oMember = RitGetPCByUUID(JsonGetString(JsonArrayGet(jParts, i)));
            if(!GetIsObjectValid(oMember)) continue;
            effect eCurse = TagEffect(
                ExtraordinaryEffect(EffectSavingThrowDecrease(SAVING_THROW_ALL, 2)),
                "RIT_CURSE_WEAVING");
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eCurse, oMember, 3600.0);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_IMP_CURSE_STRIKE), oMember);
            FloatingTextStringOnCreature(
                "Klątwa przesiąka w twoje kości — staniesz się dla wrogów przekleństwem.", oMember, FALSE);
        }
    }

    // Transition circle to cooldown, clear roster
    int nNow = RitGetUnixTime();
    json jUpd = RitGetCircle(sTag);
    jUpd = JsonObjectSet(jUpd, "state",             JsonInt(RIT_STATE_COOLDOWN));
    jUpd = JsonObjectSet(jUpd, "cooldown_end",      JsonInt(nNow + RIT_COOLDOWN_SEC));
    jUpd = JsonObjectSet(jUpd, "participants_json", JsonString("[]"));
    jUpd = JsonObjectSet(jUpd, "leader_uuid",       JsonString(""));
    jUpd = JsonObjectSet(jUpd, "ritual_type",       JsonInt(RIT_TYPE_NONE));
    RitSetCircle(sTag, jUpd);

    // Clear participants' circle LVAR and refresh their open windows
    for(i = 0; i < n; i++)
    {
        object oMember = RitGetPCByUUID(JsonGetString(JsonArrayGet(jParts, i)));
        if(!GetIsObjectValid(oMember)) continue;
        DeleteLocalString(oMember, RIT_LVAR_CIRCLE);
        int nToken = NuiFindWindow(oMember, RIT_WINDOW);
        if(nToken != 0) RitFeedWindow(oMember, nToken, sTag);
    }
}

// ============================================================
// Heartbeat processing (call from OnHeartbeat every tick)
// ============================================================

void RitProcessHeartbeat()
{
    int nNow = RitGetUnixTime();

    // Advance any circles that have finished channeling
    json jCasting = RitGetActiveCastingCircles();
    int i, nC = JsonGetLength(jCasting);
    for(i = 0; i < nC; i++)
    {
        json jEntry   = JsonArrayGet(jCasting, i);
        string sTag   = JsonGetString(JsonObjectGet(jEntry, "tag"));
        int nType     = JsonGetInt   (JsonObjectGet(jEntry, "ritual_type"));
        int nStart    = JsonGetInt   (JsonObjectGet(jEntry, "cast_start"));
        json jParts   = JsonParse(JsonGetString(JsonObjectGet(jEntry, "participants_json")));

        if(nNow - nStart >= RIT_CASTING_SEC)
        {
            RitComplete(sTag, nType, jParts);
        }
        else
        {
            // Refresh progress bars for all participants
            RitUpdateAllWindows(sTag);
        }
    }

    // Expire circles whose cooldown has elapsed
    json jCooldown = RitGetCooldownCircles();
    int nD = JsonGetLength(jCooldown);
    for(i = 0; i < nD; i++)
    {
        json jEntry  = JsonArrayGet(jCooldown, i);
        string sTag  = JsonGetString(JsonObjectGet(jEntry, "tag"));
        int nCoolEnd = JsonGetInt   (JsonObjectGet(jEntry, "cooldown_end"));
        if(nNow >= nCoolEnd)
        {
            RitResetCircle(sTag);
            RitEnsureCircle(sTag);
        }
    }
}

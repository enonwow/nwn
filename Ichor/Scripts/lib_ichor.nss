#include "lib_ichor_def"

// ----------------------------------------------------------------
// Creature-type display helpers
// ----------------------------------------------------------------

string IchorTypeName(string sCtype)
{
    if(sCtype == ICHOR_TYPE_UNDEAD)      return "Chłód Nieumarłych";
    if(sCtype == ICHOR_TYPE_DEMON)       return "Piekielny Żar";
    if(sCtype == ICHOR_TYPE_DRAGON)      return "Dech Smoka";
    if(sCtype == ICHOR_TYPE_LYCANTHROPE) return "Klątwa Wilka";
    if(sCtype == ICHOR_TYPE_CONSTRUCT)   return "Magnetyczna Iskra";
    if(sCtype == ICHOR_TYPE_FEY)         return "Elficki Pył";
    if(sCtype == ICHOR_TYPE_ABERRATION)  return "Groteskowy Jad";
    if(sCtype == ICHOR_TYPE_BEAST)       return "Dzika Siła";
    return sCtype;
}

json IchorTypeColor(string sCtype)
{
    if(sCtype == ICHOR_TYPE_UNDEAD)      return NuiColor(170, 220, 255);  // icy blue
    if(sCtype == ICHOR_TYPE_DEMON)       return NuiColor(240,  60,  40);  // hellfire red
    if(sCtype == ICHOR_TYPE_DRAGON)      return NuiColor(255, 165,  30);  // dragon orange
    if(sCtype == ICHOR_TYPE_LYCANTHROPE) return NuiColor(200, 180,  80);  // amber
    if(sCtype == ICHOR_TYPE_CONSTRUCT)   return NuiColor( 80, 200, 255);  // electric cyan
    if(sCtype == ICHOR_TYPE_FEY)         return NuiColor(140, 255, 140);  // fey green
    if(sCtype == ICHOR_TYPE_ABERRATION)  return NuiColor(180,  80, 220);  // void purple
    if(sCtype == ICHOR_TYPE_BEAST)       return NuiColor(190, 130,  70);  // earthy brown
    return NuiColor(200, 200, 200);
}

string IchorTypeDesc(string sCtype)
{
    if(sCtype == ICHOR_TYPE_UNDEAD)
        return "Lodowata esencja nieumarłych przenika stal.\n+1k6 obrażeń negatywną energią przy każdym trafieniu.\n\n\"Martwa krew syczy na ostrzu...\"";
    if(sCtype == ICHOR_TYPE_DEMON)
        return "Piekielne żary buchają z ostrza.\n+1k6 obrażeń ogniowych przy każdym trafieniu.\n\n\"Spalone powietrze. Zapach siarki i zguby.\"";
    if(sCtype == ICHOR_TYPE_DRAGON)
        return "Smoczy żar utajony w metalu.\n+2k6 obrażeń ogniowych przy każdym trafieniu.\n\n\"Broń żyje oddechem prastarego potwora.\"";
    if(sCtype == ICHOR_TYPE_LYCANTHROPE)
        return "Klątwa zmiennokształtnych przeniesiona na ostrze.\n+2 do rzutów ataku. Obrażenia traktowane jak srebro.\n\n\"Wilkołak skamlał. Teraz ta moc należy do ciebie.\"";
    if(sCtype == ICHOR_TYPE_CONSTRUCT)
        return "Magnetyczna iskra rozkłada mechanizmy.\n+1k6 obrażeń elektrycznych przy każdym trafieniu.\n\n\"Tryby kręcą się na wspak. Metal krzyczy.\"";
    if(sCtype == ICHOR_TYPE_FEY)
        return "Feański pył rozmazuje zmysły wroga.\n+1 do premii ulepszeń (atak i obrażenia).\n\n\"Ostrze tnie jak wspomnienie złego snu.\"";
    if(sCtype == ICHOR_TYPE_ABERRATION)
        return "Obca żywica rozżera osnowę materii.\n+1k6 obrażeń kwasowych przy każdym trafieniu.\n\n\"Coś poza prawami natury płonie w głowni.\"";
    if(sCtype == ICHOR_TYPE_BEAST)
        return "Dzika furia bestii przejmuje rękę wojownika.\n+1k4 obrażeń obcinających przy każdym trafieniu.\n\n\"Zęby drapieżnika pożyczone na chwilę walki.\"";
    return "Nieznana esencja.";
}

// ----------------------------------------------------------------
// Item-property helpers
// ----------------------------------------------------------------

itemproperty IchorBuildProperty(string sCtype)
{
    if(sCtype == ICHOR_TYPE_UNDEAD)
        return ItemPropertyDamageBonus(ICHOR_DMGT_NEGATIVE,   ICHOR_DICE_1d6);
    if(sCtype == ICHOR_TYPE_DEMON)
        return ItemPropertyDamageBonus(ICHOR_DMGT_FIRE,       ICHOR_DICE_1d6);
    if(sCtype == ICHOR_TYPE_DRAGON)
        return ItemPropertyDamageBonus(ICHOR_DMGT_FIRE,       ICHOR_DICE_2d6);
    if(sCtype == ICHOR_TYPE_LYCANTHROPE)
        return ItemPropertyAttackBonus(2);
    if(sCtype == ICHOR_TYPE_CONSTRUCT)
        return ItemPropertyDamageBonus(ICHOR_DMGT_ELECTRICAL, ICHOR_DICE_1d6);
    if(sCtype == ICHOR_TYPE_FEY)
        return ItemPropertyEnhancementBonus(1);
    if(sCtype == ICHOR_TYPE_ABERRATION)
        return ItemPropertyDamageBonus(ICHOR_DMGT_ACID,       ICHOR_DICE_1d6);
    if(sCtype == ICHOR_TYPE_BEAST)
        return ItemPropertyDamageBonus(ICHOR_DMGT_COLD,       ICHOR_DICE_1d4);
    // fallback: tiny fire bonus
    return ItemPropertyDamageBonus(ICHOR_DMGT_FIRE, ICHOR_DICE_1d4);
}

// Removes the first temporary item property of the same type as the one this
// ctype would apply, leaving any permanent properties of the same type intact.
void IchorRemoveIPFromWeapon(object oWeapon, string sCtype)
{
    // Derive the target type from the property we would apply — avoids hardcoded 2da row IDs.
    int nTargetType = GetItemPropertyType(IchorBuildProperty(sCtype));
    itemproperty ip = GetFirstItemProperty(oWeapon);
    while(GetIsItemPropertyValid(ip))
    {
        if(GetItemPropertyType(ip) == nTargetType &&
           GetItemPropertyDurationType(ip) == DURATION_TYPE_TEMPORARY)
        {
            RemoveItemProperty(oWeapon, ip);
            return;
        }
        ip = GetNextItemProperty(oWeapon);
    }
}

// ----------------------------------------------------------------
// Time formatting
// ----------------------------------------------------------------

// Returns "59m 59s" or "wygasła" for a unix-epoch expiry timestamp.
string IchorFormatTimer(int nExpiresAt)
{
    int nNow  = IchorNow();
    int nSecs = nExpiresAt - nNow;
    if(nSecs <= 0) return "wygasła";
    int nMin  = nSecs / 60;
    int nSec  = nSecs % 60;
    if(nMin > 0)
        return IntToString(nMin) + "m " + IntToString(nSec) + "s";
    return IntToString(nSec) + "s";
}

// ----------------------------------------------------------------
// NUI layout
// ----------------------------------------------------------------

json IchorBuildEssenceList(object oPC)
{
    float fRowH  = GetNuiScaleDimension(oPC, 26.0);

    // Row template: [colored label | info label (right)]
    json jNameLbl = NuiLabel(NuiBind(ICHOR_BIND_ESS_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiStyleForegroundColor(jNameLbl, NuiBind(ICHOR_BIND_ESS_COLOR));

    json jInfoLbl = NuiLabel(NuiBind(ICHOR_BIND_ESS_INFO), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jInfoLbl = NuiStyleForegroundColor(jInfoLbl, NuiBind(ICHOR_BIND_ESS_COLOR));
    jInfoLbl = NuiWidth(jInfoLbl, GetNuiScaleDimension(oPC, 70.0));

    json jInner = JsonArray();
    jInner = JsonArrayInsert(jInner, jNameLbl);
    jInner = JsonArrayInsert(jInner, jInfoLbl);

    json jCell = NuiGroup(NuiRow(jInner), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, ICHOR_BTN_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(ICHOR_BIND_ESS_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(), NuiListTemplateCell(jCell, 0.0, TRUE));

    float fListH = GetNuiScaleDimension(oPC, 160.0);
    json jList = NuiList(jTmpl, NuiBind(ICHOR_BIND_ESS_COUNT), fRowH);
    return NuiHeight(jList, fListH);
}

json IchorBuildWeaponPanel(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 26.0);
    float fRemW  = GetNuiScaleDimension(oPC, 70.0);
    float fLblW  = GetNuiScaleDimension(oPC, 240.0);
    float fTimW  = GetNuiScaleDimension(oPC, 80.0);

    // Weapon name header
    json jWpnLbl = NuiLabel(NuiBind(ICHOR_BIND_WPN_NAME), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jWpnLbl = NuiHeight(jWpnLbl, fBtnH);

    // --- Slot 1 ---
    json jS1Lbl = NuiLabel(NuiBind(ICHOR_BIND_S1_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jS1Lbl = NuiStyleForegroundColor(jS1Lbl, NuiBind(ICHOR_BIND_S1_COLOR));
    jS1Lbl = NuiWidth(jS1Lbl, fLblW);

    json jS1Tim = NuiLabel(NuiBind(ICHOR_BIND_S1_TIMER), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jS1Tim = NuiWidth(jS1Tim, fTimW);

    json jS1Rem = NuiButton(JsonString("Usuń"));
    jS1Rem = NuiId(jS1Rem, ICHOR_BTN_REM1);
    jS1Rem = NuiEnabled(jS1Rem, NuiBind(ICHOR_BIND_S1_REM_ENA));
    jS1Rem = NuiWidth(jS1Rem, fRemW);
    jS1Rem = NuiHeight(jS1Rem, fBtnH);

    json jS1Row = JsonArray();
    jS1Row = JsonArrayInsert(jS1Row, NuiLabel(JsonString("Slot 1:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jS1Row = JsonArrayInsert(jS1Row, jS1Lbl);
    jS1Row = JsonArrayInsert(jS1Row, jS1Tim);
    jS1Row = JsonArrayInsert(jS1Row, jS1Rem);

    // --- Slot 2 ---
    json jS2Lbl = NuiLabel(NuiBind(ICHOR_BIND_S2_LBL), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jS2Lbl = NuiStyleForegroundColor(jS2Lbl, NuiBind(ICHOR_BIND_S2_COLOR));
    jS2Lbl = NuiWidth(jS2Lbl, fLblW);

    json jS2Tim = NuiLabel(NuiBind(ICHOR_BIND_S2_TIMER), JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jS2Tim = NuiWidth(jS2Tim, fTimW);

    json jS2Rem = NuiButton(JsonString("Usuń"));
    jS2Rem = NuiId(jS2Rem, ICHOR_BTN_REM2);
    jS2Rem = NuiEnabled(jS2Rem, NuiBind(ICHOR_BIND_S2_REM_ENA));
    jS2Rem = NuiWidth(jS2Rem, fRemW);
    jS2Rem = NuiHeight(jS2Rem, fBtnH);

    json jS2Row = JsonArray();
    jS2Row = JsonArrayInsert(jS2Row, NuiLabel(JsonString("Slot 2:"), JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jS2Row = JsonArrayInsert(jS2Row, jS2Lbl);
    jS2Row = JsonArrayInsert(jS2Row, jS2Tim);
    jS2Row = JsonArrayInsert(jS2Row, jS2Rem);

    // --- Apply ---
    json jApplyBtn = NuiButton(JsonString("Nałóż Ichor"));
    jApplyBtn = NuiId(jApplyBtn, ICHOR_BTN_APPLY);
    jApplyBtn = NuiEnabled(jApplyBtn, NuiBind(ICHOR_BIND_APPLY_ENA));
    jApplyBtn = NuiWidth(jApplyBtn, GetNuiScaleDimension(oPC, 160.0));
    jApplyBtn = NuiHeight(jApplyBtn, GetNuiScaleDimension(oPC, 32.0));

    json jApplyRow = JsonArray();
    jApplyRow = JsonArrayInsert(jApplyRow, NuiSpacer());
    jApplyRow = JsonArrayInsert(jApplyRow, jApplyBtn);

    // Assemble
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jWpnLbl)));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 4.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jS1Row));
    jCol = JsonArrayInsert(jCol, NuiRow(jS2Row));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, NuiRow(jApplyRow));
    return NuiCol(jCol);
}

json IchorBuildRoot(object oPC)
{
    float fBtnH = GetNuiScaleDimension(oPC, 28.0);

    // ---- Title bar ----
    json jTitle = NuiLabel(JsonString("ICHOR — NAMASZCZENIE OSTRZA"),
                           JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitle = NuiStyleForegroundColor(jTitle, NuiColor(200, 160, 100));
    jTitle = NuiHeight(jTitle, fBtnH);

    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, ICHOR_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 28.0));
    jClose = NuiHeight(jClose, fBtnH);

    json jTitleRow = JsonArray();
    jTitleRow = JsonArrayInsert(jTitleRow, jTitle);
    jTitleRow = JsonArrayInsert(jTitleRow, jClose);

    // ---- Essence list section ----
    json jEssHeader = NuiLabel(JsonString("Esencje istot:"),
                               JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEssHeader = NuiHeight(jEssHeader, GetNuiScaleDimension(oPC, 20.0));

    // ---- Description panel ----
    json jDescTitle = NuiLabel(NuiBind(ICHOR_BIND_DESC_TITLE),
                               JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jDescTitle = NuiHeight(jDescTitle, GetNuiScaleDimension(oPC, 20.0));
    jDescTitle = NuiStyleForegroundColor(jDescTitle, NuiColor(200, 160, 100));

    float fDescH = GetNuiScaleDimension(oPC, 80.0);
    json jDescText = NuiGroup(NuiText(NuiBind(ICHOR_BIND_DESC_TEXT), FALSE),
                              TRUE, NUI_SCROLLBARS_NONE);
    jDescText = NuiHeight(jDescText, fDescH);

    // ---- Separator label ----
    json jSep = NuiLabel(JsonString("— Aktywne powłoki —"),
                         JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jSep = NuiHeight(jSep, GetNuiScaleDimension(oPC, 20.0));
    jSep = NuiStyleForegroundColor(jSep, NuiColor(130, 100, 70));

    // ---- Status line ----
    json jStatus = NuiLabel(NuiBind(ICHOR_BIND_STATUS),
                            JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jStatus = NuiHeight(jStatus, GetNuiScaleDimension(oPC, 20.0));
    jStatus = NuiStyleForegroundColor(jStatus, NuiColor(200, 100, 80));

    // ---- Assemble full column ----
    float fContentW = GetNuiScaleDimension(oPC, 640.0);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTitleRow));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jEssHeader)));
    jCol = JsonArrayInsert(jCol, IchorBuildEssenceList(oPC));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jDescTitle)));
    jCol = JsonArrayInsert(jCol, jDescText);
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jSep)));
    jCol = JsonArrayInsert(jCol, IchorBuildWeaponPanel(oPC));
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jStatus)));

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);

    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Window lifecycle
// ----------------------------------------------------------------

void IchorOpen(object oPC)
{
    if(NuiFindWindow(oPC, ICHOR_WINDOW) != 0)
    {
        IchorFeed(oPC, NuiFindWindow(oPC, ICHOR_WINDOW));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))  - GetNuiScaleDimension(oPC, ICHOR_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT)) - GetNuiScaleDimension(oPC, ICHOR_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY, GetNuiScaleDimension(oPC, ICHOR_W), GetNuiScaleDimension(oPC, ICHOR_H));

    json jWin = NuiWindow(IchorBuildRoot(oPC),
        JsonBool(FALSE),
        NuiBind(ICHOR_WIN_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, ICHOR_WINDOW, ICHOR_EV_SCRIPT);
    NuiSetBind(oPC, nToken, ICHOR_WIN_GEOM, jGeom);

    SetLocalInt(oPC, ICHOR_LVAR_SEL_IDX, -1);
    IchorFeed(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed functions
// ----------------------------------------------------------------

void IchorFeedEssences(object oPC, int nToken)
{
    string sPcUuid = GetObjectUUID(oPC);
    json jList     = IchorGetEssences(sPcUuid);
    SetLocalJson(oPC, ICHOR_LVAR_ESS_JSON, jList);

    int nCount = JsonGetLength(jList);
    int nSel   = GetLocalInt(oPC, ICHOR_LVAR_SEL_IDX);

    json jNames  = JsonArray();
    json jInfos  = JsonArray();
    json jColors = JsonArray();
    json jEncs   = JsonArray();

    int i;
    for(i = 0; i < nCount; i++)
    {
        json   jRow    = JsonArrayGet(jList, i);
        string sCtype  = JsonGetString(JsonObjectGet(jRow, "ctype"));
        string sCname  = JsonGetString(JsonObjectGet(jRow, "cname"));
        int    nChg    = JsonGetInt   (JsonObjectGet(jRow, "charges"));

        string sName   = IchorTypeName(sCtype);
        if(sCname != "") sName = sName + " [" + sCname + "]";
        string sInfo   = IntToString(nChg) + (nChg == 1 ? " ład." : " ład.");

        jNames  = JsonArrayInsert(jNames,  JsonString(sName));
        jInfos  = JsonArrayInsert(jInfos,  JsonString(sInfo));
        jColors = JsonArrayInsert(jColors, IchorTypeColor(sCtype));
        jEncs   = JsonArrayInsert(jEncs,   JsonBool(i == nSel));
    }

    NuiSetBind(oPC, nToken, ICHOR_BIND_ESS_NAME,  jNames);
    NuiSetBind(oPC, nToken, ICHOR_BIND_ESS_INFO,  jInfos);
    NuiSetBind(oPC, nToken, ICHOR_BIND_ESS_COLOR, jColors);
    NuiSetBind(oPC, nToken, ICHOR_BIND_ESS_ENC,   jEncs);
    NuiSetBind(oPC, nToken, ICHOR_BIND_ESS_COUNT, JsonInt(nCount));
}

void IchorFeedDesc(object oPC, int nToken)
{
    int nSel = GetLocalInt(oPC, ICHOR_LVAR_SEL_IDX);
    if(nSel < 0)
    {
        NuiSetBind(oPC, nToken, ICHOR_BIND_DESC_TITLE, JsonString("(wybierz esencję)"));
        NuiSetBind(oPC, nToken, ICHOR_BIND_DESC_TEXT,  JsonString(""));
        return;
    }
    json jList = GetLocalJson(oPC, ICHOR_LVAR_ESS_JSON);
    if(nSel >= JsonGetLength(jList)) return;

    string sCtype = JsonGetString(JsonObjectGet(JsonArrayGet(jList, nSel), "ctype"));
    NuiSetBind(oPC, nToken, ICHOR_BIND_DESC_TITLE, JsonString(IchorTypeName(sCtype)));
    NuiSetBind(oPC, nToken, ICHOR_BIND_DESC_TEXT,  JsonString(IchorTypeDesc(sCtype)));
}

void IchorFeedWeapon(object oPC, int nToken)
{
    object oWeapon = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
    int    bHasWpn = GetIsObjectValid(oWeapon);
    int    nSel    = GetLocalInt(oPC, ICHOR_LVAR_SEL_IDX);

    // Weapon name
    string sWpnName = bHasWpn
        ? "Broń: " + GetName(oWeapon)
        : "Brak broni w prawej dłoni.";
    NuiSetBind(oPC, nToken, ICHOR_BIND_WPN_NAME, JsonString(sWpnName));

    string sPcUuid  = GetObjectUUID(oPC);
    string sItemUuid = bHasWpn ? GetObjectUUID(oWeapon) : "";

    // Slot 1
    json jSlot1 = (bHasWpn) ? IchorGetSlot(sPcUuid, sItemUuid, 1) : JsonNull();
    int  bS1    = (JsonGetType(jSlot1) != JSON_TYPE_NULL);
    if(bS1)
    {
        string sK1 = JsonGetString(JsonObjectGet(jSlot1, "effect_key"));
        int    nE1 = JsonGetInt   (JsonObjectGet(jSlot1, "expires_at"));
        NuiSetBind(oPC, nToken, ICHOR_BIND_S1_LBL,     JsonString(IchorTypeName(sK1)));
        NuiSetBind(oPC, nToken, ICHOR_BIND_S1_TIMER,   JsonString(IchorFormatTimer(nE1)));
        NuiSetBind(oPC, nToken, ICHOR_BIND_S1_COLOR,   IchorTypeColor(sK1));
        NuiSetBind(oPC, nToken, ICHOR_BIND_S1_REM_ENA, JsonBool(TRUE));
    }
    else
    {
        NuiSetBind(oPC, nToken, ICHOR_BIND_S1_LBL,     JsonString("(puste)"));
        NuiSetBind(oPC, nToken, ICHOR_BIND_S1_TIMER,   JsonString(""));
        NuiSetBind(oPC, nToken, ICHOR_BIND_S1_COLOR,   NuiColor(100, 100, 100));
        NuiSetBind(oPC, nToken, ICHOR_BIND_S1_REM_ENA, JsonBool(FALSE));
    }

    // Slot 2
    json jSlot2 = (bHasWpn) ? IchorGetSlot(sPcUuid, sItemUuid, 2) : JsonNull();
    int  bS2    = (JsonGetType(jSlot2) != JSON_TYPE_NULL);
    if(bS2)
    {
        string sK2 = JsonGetString(JsonObjectGet(jSlot2, "effect_key"));
        int    nE2 = JsonGetInt   (JsonObjectGet(jSlot2, "expires_at"));
        NuiSetBind(oPC, nToken, ICHOR_BIND_S2_LBL,     JsonString(IchorTypeName(sK2)));
        NuiSetBind(oPC, nToken, ICHOR_BIND_S2_TIMER,   JsonString(IchorFormatTimer(nE2)));
        NuiSetBind(oPC, nToken, ICHOR_BIND_S2_COLOR,   IchorTypeColor(sK2));
        NuiSetBind(oPC, nToken, ICHOR_BIND_S2_REM_ENA, JsonBool(TRUE));
    }
    else
    {
        NuiSetBind(oPC, nToken, ICHOR_BIND_S2_LBL,     JsonString("(puste)"));
        NuiSetBind(oPC, nToken, ICHOR_BIND_S2_TIMER,   JsonString(""));
        NuiSetBind(oPC, nToken, ICHOR_BIND_S2_COLOR,   NuiColor(100, 100, 100));
        NuiSetBind(oPC, nToken, ICHOR_BIND_S2_REM_ENA, JsonBool(FALSE));
    }

    // Apply button: needs weapon + selected essence + at least one free slot
    int bCanApply = bHasWpn && (nSel >= 0) && (!bS1 || !bS2);
    NuiSetBind(oPC, nToken, ICHOR_BIND_APPLY_ENA, JsonBool(bCanApply));
}

void IchorFeed(object oPC, int nToken)
{
    NuiSetBind(oPC, nToken, ICHOR_BIND_STATUS, JsonString(""));
    IchorFeedEssences(oPC, nToken);
    IchorFeedDesc    (oPC, nToken);
    IchorFeedWeapon  (oPC, nToken);
}

// ----------------------------------------------------------------
// Business logic
// ----------------------------------------------------------------

void IchorApply(object oPC, int nToken)
{
    int nSel = GetLocalInt(oPC, ICHOR_LVAR_SEL_IDX);
    if(nSel < 0)
    {
        NuiSetBind(oPC, nToken, ICHOR_BIND_STATUS, JsonString("Zaznacz esencję z listy."));
        return;
    }

    object oWeapon = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
    if(!GetIsObjectValid(oWeapon))
    {
        NuiSetBind(oPC, nToken, ICHOR_BIND_STATUS, JsonString("Brak broni w prawej dłoni."));
        return;
    }

    json jList = GetLocalJson(oPC, ICHOR_LVAR_ESS_JSON);
    if(nSel >= JsonGetLength(jList))
    {
        NuiSetBind(oPC, nToken, ICHOR_BIND_STATUS, JsonString("Nieprawidłowa esencja."));
        return;
    }

    json   jEss    = JsonArrayGet(jList, nSel);
    int    nEssId  = JsonGetInt   (JsonObjectGet(jEss, "id"));
    string sCtype  = JsonGetString(JsonObjectGet(jEss, "ctype"));
    string sPcUuid = GetObjectUUID(oPC);
    string sWpnId  = GetObjectUUID(oWeapon);

    // Find a free slot (1 first, then 2)
    int nFreeSlot = 0;
    json jS1 = IchorGetSlot(sPcUuid, sWpnId, 1);
    json jS2 = IchorGetSlot(sPcUuid, sWpnId, 2);
    if(JsonGetType(jS1) == JSON_TYPE_NULL)      nFreeSlot = 1;
    else if(JsonGetType(jS2) == JSON_TYPE_NULL) nFreeSlot = 2;

    if(nFreeSlot == 0)
    {
        NuiSetBind(oPC, nToken, ICHOR_BIND_STATUS, JsonString("Oba sloty zajęte. Usuń powłokę."));
        return;
    }

    // Apply item property (temporary)
    itemproperty ip  = IchorBuildProperty(sCtype);
    float        fDur = IntToFloat(ICHOR_DURATION_SEC);
    AddItemProperty(DURATION_TYPE_TEMPORARY, ip, oWeapon, fDur);

    // Record in DB
    int nExpires = IchorNow() + ICHOR_DURATION_SEC;
    IchorAddActive(sPcUuid, sWpnId, nFreeSlot, sCtype, nExpires);
    IchorConsumeCharge(nEssId);

    string sFlavor = "Powłoka nałożona. " + IchorTypeName(sCtype) + " wchłonięta przez metal.";
    SendMessageToPC(oPC, "[Ichor] " + sFlavor);
    FloatingTextStringOnCreature(sFlavor, oPC, FALSE);

    // Reset selection if no more charges
    SetLocalInt(oPC, ICHOR_LVAR_SEL_IDX, -1);
    IchorFeed(oPC, nToken);
}

void IchorRemoveSlotDB(object oPC, int nToken, int nSlot)
{
    object oWeapon = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oPC);
    if(!GetIsObjectValid(oWeapon))
    {
        NuiSetBind(oPC, nToken, ICHOR_BIND_STATUS, JsonString("Brak broni w prawej dłoni."));
        return;
    }

    string sPcUuid = GetObjectUUID(oPC);
    string sWpnId  = GetObjectUUID(oWeapon);
    json   jSlot   = IchorGetSlot(sPcUuid, sWpnId, nSlot);

    if(JsonGetType(jSlot) == JSON_TYPE_NULL)
    {
        IchorFeedWeapon(oPC, nToken);
        return;
    }

    int    nId    = JsonGetInt   (JsonObjectGet(jSlot, "id"));
    string sCtype = JsonGetString(JsonObjectGet(jSlot, "effect_key"));

    IchorRemoveIPFromWeapon(oWeapon, sCtype);
    IchorRemoveActiveById(nId);

    NuiSetBind(oPC, nToken, ICHOR_BIND_STATUS, JsonString("Powłoka usunięta."));
    IchorFeedWeapon(oPC, nToken);
}

// ----------------------------------------------------------------
// Called from sys_on_enter — cleans expired records, refreshes UI
// ----------------------------------------------------------------

void IchorReapplyOnLogin(object oPC)
{
    string sPcUuid = GetObjectUUID(oPC);
    IchorPruneExpired(sPcUuid);

    // Check if any active coatings remain and notify
    json jActive = IchorGetActive(sPcUuid);
    if(JsonGetLength(jActive) > 0)
        SendMessageToPC(oPC, "[Ichor] Masz aktywne powłoki na broni. Otwórz panel Ichoru, aby sprawdzić.");
}

// ----------------------------------------------------------------
// Called from sys_on_death — harvests from a freshly-killed creature
// ----------------------------------------------------------------

void IchorHarvestFromCorpse(object oPC, object oCorpse)
{
    if(!GetIsObjectValid(oCorpse)) return;

    // The death hook sets ICHOR_TYPE on the creature before this call.
    string sCtype = GetLocalString(oCorpse, "ICHOR_TYPE");
    if(sCtype == "") return;

    int nKilledAt = GetLocalInt(oCorpse, "ICHOR_KILLED_AT");
    if(nKilledAt > 0 && IchorNow() - nKilledAt > ICHOR_HARVEST_SEC)
    {
        SendMessageToPC(oPC, "[Ichor] Ciało ostygło — ichor jest już bezużyteczny.");
        return;
    }

    int bAlready = GetLocalInt(oCorpse, "ICHOR_HARVESTED");
    if(bAlready)
    {
        SendMessageToPC(oPC, "[Ichor] Esencja już zebrana z tego ciała.");
        return;
    }

    SetLocalInt(oCorpse, "ICHOR_HARVESTED", 1);
    string sCname  = GetName(oCorpse);
    string sPcUuid = GetObjectUUID(oPC);
    IchorAddEssence(sPcUuid, sCtype, sCname);

    string sMsg = "Zebrałeś esencję: " + IchorTypeName(sCtype) + " [" + sCname + "].";
    SendMessageToPC(oPC, "[Ichor] " + sMsg);
    FloatingTextStringOnCreature(sMsg, oPC, FALSE);
}

// Called by the DM/module on creature death to mark it as harvestable.
void IchorMarkCorpse(object oCorpse)
{
    int nRace = GetRacialType(oCorpse);
    string sCtype = "";

    if(nRace == RACIAL_TYPE_UNDEAD)        sCtype = ICHOR_TYPE_UNDEAD;
    else if(nRace == RACIAL_TYPE_DRAGON)   sCtype = ICHOR_TYPE_DRAGON;
    else if(nRace == RACIAL_TYPE_FEY)      sCtype = ICHOR_TYPE_FEY;
    else if(nRace == RACIAL_TYPE_ABERRATION) sCtype = ICHOR_TYPE_ABERRATION;
    else if(nRace == RACIAL_TYPE_CONSTRUCT)  sCtype = ICHOR_TYPE_CONSTRUCT;
    else if(nRace == RACIAL_TYPE_BEAST ||
            nRace == RACIAL_TYPE_ANIMAL)     sCtype = ICHOR_TYPE_BEAST;
    else if(nRace == RACIAL_TYPE_OUTSIDER)
    {
        // Distinguish demons/devils from other outsiders by alignment
        int nAlign = GetAlignmentGoodEvil(oCorpse);
        sCtype = (nAlign == ALIGNMENT_EVIL) ? ICHOR_TYPE_DEMON : ICHOR_TYPE_FEY;
    }
    else
    {
        // Check local variable set by designers for lycanthropes etc.
        sCtype = GetLocalString(oCorpse, "ICHOR_FORCE_TYPE");
    }

    if(sCtype == "") return;

    SetLocalString(oCorpse, "ICHOR_TYPE",      sCtype);
    SetLocalInt   (oCorpse, "ICHOR_KILLED_AT", IchorNow());
}

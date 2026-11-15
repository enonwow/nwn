#include "lib_mac_def"

// ----------------------------------------------------------------
// Omen texts indexed by proximity tier
// ----------------------------------------------------------------

string MacPickOmenText(int nProximity)
{
    // Using proximity to seed a rough random within tier bucket
    int nRoll = d6();

    if(nProximity >= MAC_TIER_STALKED)
    {
        switch(nRoll)
        {
            case 1: return "Twarze w cieniach wyciagaja do ciebie rece.";
            case 2: return "Czujesz zimny oddech na karku, lecz za soba nie widzisz nic.";
            case 3: return "Twoja krew sniedzi w ranach szybciej niz powinna.";
            case 4: return "Psy uciekaja gdy przechodzisz obok. Dzieci plakaja bez powodu.";
            case 5: return "Widzisz swoj wlasny pogrzeb w snach.";
            default:return "Zegar odmierza ostatnie chwile. Slyszysz kazde tykniecie.";
        }
    }
    if(nProximity >= MAC_TIER_WATCHED)
    {
        switch(nRoll)
        {
            case 1: return "Czarna bielmo zascia oko krukowiate na chwile przed jego lotem.";
            case 2: return "Czujesz zapach swiezej ziemi z otwartego grobu.";
            case 3: return "Lampa gasinela, gdy wszedl_es do izby. Zadnego wiatru.";
            case 4: return "Stara kobieta przy studni spojrzala na ciebie i odwrocila wzrok w milczeniu.";
            case 5: return "Twoja własna twarz w lustrze usmiechinela sie. Ale ty nie.";
            default:return "Piesn pogrzebna dobiega zza muru. Nikt inny jej nie slyszy.";
        }
    }
    if(nProximity >= MAC_TIER_SAFE)
    {
        switch(nRoll)
        {
            case 1: return "Kruk usiadl na twoim ramieniu i szybko odlecial.";
            case 2: return "Wieczorny wiatr przyniosl cos, co brzmialo jak szept twojego imienia.";
            case 3: return "Swietojanska swieca zgasla mimo spokojnego powietrza.";
            case 4: return "Poczules przez chwile, ze ktos chodzi po twoim grobie.";
            case 5: return "Sen byl spokojny. Zbyt spokojny.";
            default:return "Twoj cien przez chwile nie pokrywal sie z twymi ruchami.";
        }
    }
    return "";
}

// ----------------------------------------------------------------
// Send omen to player: floating text + SQL log
// ----------------------------------------------------------------

void MacSendOmen(object oPC, int nProximity)
{
    if(nProximity < MAC_TIER_SAFE) return;

    // Not every step triggers an omen — roughly 1-in-3 chance per point above tier
    if(d3() != 1) return;

    string sText = MacPickOmenText(nProximity);
    if(sText == "") return;

    MacLogOmen(oPC, sText, nProximity);
    FloatingTextStringOnCreature("[Omen] " + sText, oPC, FALSE);
    SendMessageToPC(oPC, "[Danse Macabre] " + sText);
}

// ----------------------------------------------------------------
// Proximity effect callbacks (called after any proximity change)
// ----------------------------------------------------------------

void MacApplyProximityEffects(object oPC, int nOldProximity, int nNewProximity)
{
    // "Marked by Death" aura: proximity >= 75 → passive -1 attack penalty via local var
    // The actual effect application is done in sys_on_enter via CheckMark;
    // here we toggle the LVAR so an external system can query it.
    int nOldMark = (nOldProximity >= MAC_TIER_STALKED) ? 1 : 0;
    int nNewMark = (nNewProximity >= MAC_TIER_STALKED) ? 1 : 0;

    if(nOldMark != nNewMark)
    {
        SetLocalInt(oPC, "MAC_MARKED_BY_DEATH", nNewMark);
        if(nNewMark)
        {
            SendMessageToPC(oPC, "[Danse Macabre] Pieczen smierci pulsuje slabo na twojej skórze...");
            effect eMark = TagEffect(EffectAttackDecrease(1, ATTACK_BONUS_MISC), "MAC_DEATH_MARK");
            ApplyEffectToObject(DURATION_TYPE_PERMANENT, eMark, oPC);
        }
        else
        {
            // Remove the death-mark debuff by tag
            effect eCheck = GetFirstEffect(oPC);
            while(GetIsEffectValid(eCheck))
            {
                effect eNext = GetNextEffect(oPC);
                if(GetEffectTag(eCheck) == "MAC_DEATH_MARK")
                    RemoveEffect(oPC, eCheck);
                eCheck = eNext;
            }
            SendMessageToPC(oPC, "[Danse Macabre] Pieczen smierci blednie.");
            DeleteLocalInt(oPC, "MAC_MARKED_BY_DEATH");
        }
    }

    // Trigger bargain window if proximity just reached 100
    if(nNewProximity >= MAC_TIER_IMMINENT && nOldProximity < MAC_TIER_IMMINENT)
    {
        DelayCommand(2.0, MacOpenWindow(oPC));
    }
}

// ----------------------------------------------------------------
// NUI layout: main view
// ----------------------------------------------------------------

json BuildMacMainView(object oPC)
{
    int    nProx   = MacGetProximity(oPC);
    float  fBtnH   = GetNuiScaleDimension(oPC, 28.0);
    float  fRowH   = GetNuiScaleDimension(oPC, 24.0);
    float  fSmallH = GetNuiScaleDimension(oPC, 18.0);

    // -- Header: proximity value + tier label --
    json jProxVal = NuiLabel(NuiBind(MAC_BIND_PROXIMITY_VAL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jProxVal = NuiStyleForegroundColor(jProxVal, NuiBind(MAC_BIND_TIER_COLOR));
    jProxVal = NuiHeight(jProxVal, GetNuiScaleDimension(oPC, 36.0));

    json jTierLbl = NuiLabel(NuiBind(MAC_BIND_TIER_LABEL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jTierLbl = NuiStyleForegroundColor(jTierLbl, NuiBind(MAC_BIND_TIER_COLOR));
    jTierLbl = NuiHeight(jTierLbl, GetNuiScaleDimension(oPC, 24.0));

    // Progress bar acts as the proximity meter (0.0–1.0)
    json jBar = NuiProgressBar(NuiBind(MAC_BIND_PROXIMITY_BAR));
    jBar = NuiHeight(jBar, GetNuiScaleDimension(oPC, 20.0));

    // -- Omens list --
    json jOmenText = NuiLabel(NuiBind(MAC_BIND_OMEN_TEXT),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jOmenText = NuiStyleForegroundColor(jOmenText, NuiBind(MAC_BIND_OMEN_COLOR));

    json jOmenProx = NuiLabel(NuiBind(MAC_BIND_OMEN_PROX),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jOmenProx = NuiWidth(jOmenProx, GetNuiScaleDimension(oPC, 36.0));
    jOmenProx = NuiStyleForegroundColor(jOmenProx, NuiBind(MAC_BIND_OMEN_COLOR));

    json jOmenCells = JsonArray();
    jOmenCells = JsonArrayInsert(jOmenCells, jOmenText);
    jOmenCells = JsonArrayInsert(jOmenCells, jOmenProx);
    json jOmenCell = NuiGroup(NuiRow(jOmenCells), TRUE, NUI_SCROLLBARS_NONE);
    json jOmenTmpl = JsonArrayInsert(JsonArray(),
        NuiListTemplateCell(jOmenCell, 0.0, TRUE));

    json jOmenList = NuiList(jOmenTmpl, NuiBind(MAC_BIND_OMEN_COUNT), fSmallH);
    jOmenList = NuiHeight(jOmenList, GetNuiScaleDimension(oPC, 150.0));

    json jOmenHeader = NuiLabel(JsonString("Ostatnie zwiastuny:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jOmenHeader = NuiHeight(jOmenHeader, GetNuiScaleDimension(oPC, 20.0));

    // -- Contracts list --
    json jCtrType = NuiLabel(NuiBind(MAC_BIND_CONTRACT_TYPE),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCtrType = NuiWidth(jCtrType, GetNuiScaleDimension(oPC, 100.0));

    json jCtrSac = NuiLabel(NuiBind(MAC_BIND_CONTRACT_SAC),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));

    json jCtrDate = NuiLabel(NuiBind(MAC_BIND_CONTRACT_DATE),
        JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jCtrDate = NuiWidth(jCtrDate, GetNuiScaleDimension(oPC, 50.0));

    json jCtrCells = JsonArray();
    jCtrCells = JsonArrayInsert(jCtrCells, jCtrType);
    jCtrCells = JsonArrayInsert(jCtrCells, jCtrSac);
    jCtrCells = JsonArrayInsert(jCtrCells, jCtrDate);
    json jCtrCell = NuiGroup(NuiRow(jCtrCells), TRUE, NUI_SCROLLBARS_NONE);
    jCtrCell = NuiId(jCtrCell, MAC_BTN_CONTRACT_ROW);
    jCtrCell = NuiEncouraged(jCtrCell, NuiBind(MAC_BIND_CONTRACT_ENC));
    json jCtrTmpl = JsonArrayInsert(JsonArray(),
        NuiListTemplateCell(jCtrCell, 0.0, TRUE));

    json jCtrList = NuiList(jCtrTmpl, NuiBind(MAC_BIND_CONTRACT_COUNT), fRowH);
    jCtrList = NuiHeight(jCtrList, GetNuiScaleDimension(oPC, 160.0));

    json jCtrHeader = NuiLabel(JsonString("Kronika kontraktow ze Smiercia:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jCtrHeader = NuiHeight(jCtrHeader, GetNuiScaleDimension(oPC, 20.0));

    // -- Assemble --
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jProxVal);
    jCol = JsonArrayInsert(jCol, jTierLbl);
    jCol = JsonArrayInsert(jCol, jBar);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jOmenHeader);
    jCol = JsonArrayInsert(jCol, jOmenList);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 6.0));
    jCol = JsonArrayInsert(jCol, jCtrHeader);
    jCol = JsonArrayInsert(jCol, jCtrList);

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 460.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// NUI layout: bargain view (shown at proximity 100)
// ----------------------------------------------------------------

json BuildMacBargainView(object oPC)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 32.0);
    float fFlav  = GetNuiScaleDimension(oPC, 100.0);

    json jFlavor = NuiGroup(NuiText(NuiBind(MAC_BIND_BARG_FLAVOR), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jFlavor = NuiHeight(jFlavor, fFlav);

    // Offer buttons
    json jHpBtn = NuiButton(NuiBind(MAC_BIND_BARG_COST1));
    jHpBtn = NuiId(jHpBtn, MAC_BTN_OFFER_HP);
    jHpBtn = NuiHeight(jHpBtn, fBtnH);

    json jGoldBtn = NuiButton(NuiBind(MAC_BIND_BARG_COST2));
    jGoldBtn = NuiId(jGoldBtn, MAC_BTN_OFFER_GOLD);
    jGoldBtn = NuiHeight(jGoldBtn, fBtnH);

    json jXpBtn = NuiButton(NuiBind(MAC_BIND_BARG_COST3));
    jXpBtn = NuiId(jXpBtn, MAC_BTN_OFFER_XP);
    jXpBtn = NuiHeight(jXpBtn, fBtnH);

    // Memory offer: text field + confirm button
    json jMemField = NuiTextEdit(
        JsonString("Opisz wspomnienie, ktore oddasz..."),
        NuiBind(MAC_BIND_BARG_MEM_TXT), 120, FALSE);
    jMemField = NuiHeight(jMemField, fBtnH);

    json jMemBtn = NuiButton(JsonString("Oddaj wspomnienie"));
    jMemBtn = NuiId(jMemBtn, MAC_BTN_OFFER_MEMORY);
    jMemBtn = NuiEnabled(jMemBtn, NuiBind(MAC_BIND_BARG_MEM_ENA));
    jMemBtn = NuiHeight(jMemBtn, fBtnH);
    jMemBtn = NuiWidth(jMemBtn, GetNuiScaleDimension(oPC, 160.0));

    json jMemRow = JsonArray();
    jMemRow = JsonArrayInsert(jMemRow, jMemField);
    jMemRow = JsonArrayInsert(jMemRow, jMemBtn);

    // Refuse button
    json jRefBtn = NuiButton(JsonString("Odmawiam"));
    jRefBtn = NuiId(jRefBtn, MAC_BTN_REFUSE);
    jRefBtn = NuiHeight(jRefBtn, fBtnH);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jFlavor);
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, jHpBtn);
    jCol = JsonArrayInsert(jCol, jGoldBtn);
    jCol = JsonArrayInsert(jCol, jXpBtn);
    jCol = JsonArrayInsert(jCol, NuiRow(jMemRow));
    jCol = JsonArrayInsert(jCol, CreateEmptyRow(oPC, 8.0));
    jCol = JsonArrayInsert(jCol, jRefBtn);

    json jSide = NuiCol(JsonArrayInsert(JsonArray(), NuiSpacer()));
    float fContentW = GetNuiScaleDimension(oPC, 460.0);
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiCol(jCol), fContentW));
    jMainRow = JsonArrayInsert(jMainRow, jSide);
    return NuiRow(jMainRow);
}

// ----------------------------------------------------------------
// Window create
// ----------------------------------------------------------------

void MacOpenWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, MAC_WINDOW);

    if(nToken != 0)
    {
        // Already open — refresh and possibly force bargain view
        int nProx = MacGetProximity(oPC);
        if(nProx >= MAC_TIER_IMMINENT && !GetLocalInt(oPC, MAC_LVAR_IN_BARGAIN))
            MacShowBargainView(oPC, nToken);
        else
            MacFeedMainView(oPC, nToken);
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, MAC_WIN_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, MAC_WIN_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
        GetNuiScaleDimension(oPC, MAC_WIN_W),
        GetNuiScaleDimension(oPC, MAC_WIN_H));

    float fBtnH = GetNuiScaleDimension(oPC, 28.0);
    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, MAC_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 28.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTopBar = JsonArray();
    jTopBar = JsonArrayInsert(jTopBar, NuiLabel(
        NuiBind(MAC_BIND_HEADER_LBL),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)));
    jTopBar = JsonArrayInsert(jTopBar, NuiSpacer());
    jTopBar = JsonArrayInsert(jTopBar, jCloseBtn);

    int nProx = MacGetProximity(oPC);
    json jInitView = (nProx >= MAC_TIER_IMMINENT)
        ? BuildMacBargainView(oPC)
        : BuildMacMainView(oPC);

    json jSwapGrp = NuiGroup(jInitView, FALSE, NUI_SCROLLBARS_NONE);
    jSwapGrp = NuiId(jSwapGrp, MAC_GRP_SWAP);

    json jRootChildren = JsonArray();
    jRootChildren = JsonArrayInsert(jRootChildren, NuiRow(jTopBar));
    jRootChildren = JsonArrayInsert(jRootChildren, jSwapGrp);
    json jRoot = NuiCol(jRootChildren);

    json jWin = NuiWindow(jRoot,
        JsonBool(FALSE),
        NuiBind(MAC_WIN_GEOM),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE));

    nToken = NuiCreate(oPC, jWin, MAC_WINDOW, MAC_EV_SCRIPT);
    NuiSetBind(oPC, nToken, MAC_WIN_GEOM, jGeom);

    if(nProx >= MAC_TIER_IMMINENT)
    {
        SetLocalInt(oPC, MAC_LVAR_IN_BARGAIN, 1);
        MacFeedBargainView(oPC, nToken);
    }
    else
    {
        MacFeedMainView(oPC, nToken);
    }
}

// ----------------------------------------------------------------
// View switch helpers
// ----------------------------------------------------------------

void MacShowMainView(object oPC, int nToken)
{
    DeleteLocalInt(oPC, MAC_LVAR_IN_BARGAIN);
    NuiSetGroupLayout(oPC, nToken, MAC_GRP_SWAP, BuildMacMainView(oPC));
    MacFeedMainView(oPC, nToken);
}

void MacShowBargainView(object oPC, int nToken)
{
    SetLocalInt(oPC, MAC_LVAR_IN_BARGAIN, 1);
    NuiSetGroupLayout(oPC, nToken, MAC_GRP_SWAP, BuildMacBargainView(oPC));
    MacFeedBargainView(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed: main view
// ----------------------------------------------------------------

void MacFeedMainView(object oPC, int nToken)
{
    int nProx = MacGetProximity(oPC);
    string sTier  = MacGetTierLabel(nProx);
    json   jColor = MacGetTierColor(nProx);

    NuiSetBind(oPC, nToken, MAC_BIND_HEADER_LBL,
        JsonString("Danse Macabre"));
    NuiSetBind(oPC, nToken, MAC_BIND_PROXIMITY_VAL,
        JsonString("Bliskosc Smierci: " + IntToString(nProx) + " / 100"));
    NuiSetBind(oPC, nToken, MAC_BIND_PROXIMITY_BAR,
        JsonFloat(IntToFloat(nProx) / 100.0));
    NuiSetBind(oPC, nToken, MAC_BIND_TIER_LABEL,  JsonString(sTier));
    NuiSetBind(oPC, nToken, MAC_BIND_TIER_COLOR,  jColor);

    // Omens
    json jOmens = MacGetRecentOmens(oPC, 8);
    int  nOmenCount = JsonGetLength(jOmens);

    json jTexts  = JsonArray();
    json jProxes = JsonArray();
    json jColors = JsonArray();

    int i;
    for(i = 0; i < nOmenCount; i++)
    {
        json jRow = JsonArrayGet(jOmens, i);
        int  nP   = JsonGetInt(JsonObjectGet(jRow, "prox"));
        jTexts  = JsonArrayInsert(jTexts,  JsonString(JsonGetString(JsonObjectGet(jRow, "text"))));
        jProxes = JsonArrayInsert(jProxes, JsonString("[" + IntToString(nP) + "]"));
        jColors = JsonArrayInsert(jColors, MacGetOmenColor(nP));
    }

    NuiSetBind(oPC, nToken, MAC_BIND_OMEN_TEXT,  jTexts);
    NuiSetBind(oPC, nToken, MAC_BIND_OMEN_PROX,  jProxes);
    NuiSetBind(oPC, nToken, MAC_BIND_OMEN_COLOR, jColors);
    NuiSetBind(oPC, nToken, MAC_BIND_OMEN_COUNT, JsonInt(nOmenCount));

    // Contracts
    json jContracts = MacGetContracts(oPC, 10);
    int  nCtrCount  = JsonGetLength(jContracts);

    json jTypes = JsonArray();
    json jSacs  = JsonArray();
    json jDates = JsonArray();
    json jEncs  = JsonArray();

    for(i = 0; i < nCtrCount; i++)
    {
        json jRow = JsonArrayGet(jContracts, i);
        int  nType = JsonGetInt(JsonObjectGet(jRow, "type"));
        jTypes = JsonArrayInsert(jTypes, JsonString(MacGetContractTypeName(nType)));
        jSacs  = JsonArrayInsert(jSacs,  JsonString(JsonGetString(JsonObjectGet(jRow, "sac"))));
        jDates = JsonArrayInsert(jDates, JsonString(MacFormatDate(JsonGetInt(JsonObjectGet(jRow, "at")))));
        jEncs  = JsonArrayInsert(jEncs,  JsonBool(FALSE));
    }

    NuiSetBind(oPC, nToken, MAC_BIND_CONTRACT_TYPE,  jTypes);
    NuiSetBind(oPC, nToken, MAC_BIND_CONTRACT_SAC,   jSacs);
    NuiSetBind(oPC, nToken, MAC_BIND_CONTRACT_DATE,  jDates);
    NuiSetBind(oPC, nToken, MAC_BIND_CONTRACT_ENC,   jEncs);
    NuiSetBind(oPC, nToken, MAC_BIND_CONTRACT_COUNT, JsonInt(nCtrCount));
}

// ----------------------------------------------------------------
// Feed: bargain view
// ----------------------------------------------------------------

void MacFeedBargainView(object oPC, int nToken)
{
    NuiSetBind(oPC, nToken, MAC_BIND_HEADER_LBL,
        JsonString("*** TARGOWANIE ***"));

    string sFlavor =
        "Ciemnosc gestnieleje wokol ciebie i czujesz, jak czas zwalnia.\n\n"
        "Postac bez twarzy staje przed toba. Ani zywa, ani martwa.\n"
        "Ani wroga, ani przyjazna.\n\n"
        "\"Twoj czas prawie sie skonczyl,\" mowi glosem z kamiennej krypty.\n"
        "\"Lecz jeszcze nie dzisiaj. Mozemy sie umowic.\"\n\n"
        "Co jej ofiarujesz?";

    NuiSetBind(oPC, nToken, MAC_BIND_BARG_FLAVOR, JsonString(sFlavor));

    int nHP    = GetMaxHitPoints(oPC);
    int nGold  = GetGold(oPC);
    int nXP    = GetXP(oPC);
    int nXPCut = nXP * MAC_BARGAIN_XP_PCT / 100;

    string sCost1 = "Oddaj sile zyciowa  (-" + IntToString(MAC_BARGAIN_HP_COST) + " Kondycja, trwale)";
    string sCost2 = "Oddaj zloto  (-" + IntToString(MAC_BARGAIN_GOLD_COST) + " sztuk zlota)";
    string sCost3 = "Oddaj doswiadczenie  (-" + IntToString(nXPCut) + " PD)";

    NuiSetBind(oPC, nToken, MAC_BIND_BARG_COST1, JsonString(sCost1));
    NuiSetBind(oPC, nToken, MAC_BIND_BARG_COST2, JsonString(sCost2));
    NuiSetBind(oPC, nToken, MAC_BIND_BARG_COST3, JsonString(sCost3));
    NuiSetBind(oPC, nToken, MAC_BIND_BARG_MEM_TXT, JsonString(""));
    NuiSetBind(oPC, nToken, MAC_BIND_BARG_MEM_ENA, JsonBool(FALSE));
    NuiSetBindWatch(oPC, nToken, MAC_BIND_BARG_MEM_TXT, TRUE);
}

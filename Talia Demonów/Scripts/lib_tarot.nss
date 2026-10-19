#include "sql_tarot"

// ----------------------------------------------------------------
// Forward declarations
// ----------------------------------------------------------------

void TarotApplyCardEffect(object oPC, int nCardId);
void TarotRemoveCardEffect(object oPC, int nCardId);
void TarotApplyAllDrawnEffects(object oPC);
void TarotRemoveAllEffects(object oPC);
void TarotOpenWindow(object oPC);
void TarotFeedGrid(object oPC, int nToken);
void TarotFeedDetailPanel(object oPC, int nToken, int nCardId);
void TarotClearDetailPanel(object oPC, int nToken);

// ----------------------------------------------------------------
// Effect application
// ----------------------------------------------------------------

void TarotRemoveCardEffect(object oPC, int nCardId)
{
    RemoveEffectByTag(oPC, TAROT_EFFECT_TAG + IntToString(nCardId));
}

void TarotApplyCardEffect(object oPC, int nCardId)
{
    TarotRemoveCardEffect(oPC, nCardId);

    // Build the primary effect for this card
    effect ePrimary;

    switch(nCardId)
    {
        case 0:  // Nieczysta Moc — Strength +2
            ePrimary = EffectAbilityIncrease(ABILITY_STRENGTH, 2);
            break;

        case 1:  // Czarna Brama — Dex +2, speed +20%
            ePrimary = EffectLinkEffects(
                EffectAbilityIncrease(ABILITY_DEXTERITY, 2),
                EffectMovementSpeedIncrease(20));
            break;

        case 2:  // Pieczęć Pychy — all saves +2, persuade -4
            ePrimary = EffectLinkEffects(
                EffectSavingThrowIncrease(SAVING_THROW_ALL, 2, SAVING_THROW_TYPE_ALL),
                EffectSkillDecrease(SKILL_PERSUADE, 4));
            break;

        case 3:  // Łańcuch Duszy — Con +2, Discipline +6
            ePrimary = EffectLinkEffects(
                EffectAbilityIncrease(ABILITY_CONSTITUTION, 2),
                EffectSkillIncrease(SKILL_DISCIPLINE, 6));
            break;

        case 4:  // Oko Tyranii — Intimidate +10, Persuade -4
            ePrimary = EffectLinkEffects(
                EffectSkillIncrease(SKILL_INTIMIDATE, 10),
                EffectSkillDecrease(SKILL_PERSUADE, 4));
            break;

        case 5:  // Cień Szepty — Spot +6, Listen +6
            ePrimary = EffectLinkEffects(
                EffectSkillIncrease(SKILL_SPOT, 6),
                EffectSkillIncrease(SKILL_LISTEN, 6));
            break;

        case 6:  // Klucz Otchłani — Open Lock +8, Disable Trap +4
            ePrimary = EffectLinkEffects(
                EffectSkillIncrease(SKILL_OPEN_LOCK, 8),
                EffectSkillIncrease(SKILL_DISABLE_TRAP, 4));
            break;

        case 7:  // Krew Ofiary — Regenerate 1 HP/round, Con -2
            ePrimary = EffectLinkEffects(
                EffectRegenerate(1, RoundsToSeconds(1)),
                EffectAbilityDecrease(ABILITY_CONSTITUTION, 2));
            break;

        case 8:  // Znak Chaosu — Int +2, Wis +2
            ePrimary = EffectLinkEffects(
                EffectAbilityIncrease(ABILITY_INTELLIGENCE, 2),
                EffectAbilityIncrease(ABILITY_WISDOM, 2));
            break;

        case 9:  // Piasek Zapomnienia — Will save +8 vs mind spells
            ePrimary = EffectSavingThrowIncrease(
                SAVING_THROW_WILL, 8, SAVING_THROW_TYPE_MIND_SPELLS);
            break;

        case 10: // Miecz Zemsty — AB +2, AC -1
            ePrimary = EffectLinkEffects(
                EffectAttackIncrease(2, ATTACK_BONUS_MISC),
                EffectACDecrease(1, AC_DODGE_ENCHANTMENT_MODIFIER, DAMAGE_TYPE_ALL));
            break;

        case 11: // Wierność Piekłom — saves vs spells +3
            ePrimary = EffectSavingThrowIncrease(
                SAVING_THROW_ALL, 3, SAVING_THROW_TYPE_SPELL);
            break;

        case 12: // Taniec Śmierci — AB +2, Dex +2
            ePrimary = EffectLinkEffects(
                EffectAttackIncrease(2, ATTACK_BONUS_MISC),
                EffectAbilityIncrease(ABILITY_DEXTERITY, 2));
            break;

        case 13: // Lustro Potępienia — Spot +6, Search +6, see invisible
            ePrimary = EffectLinkEffects(
                EffectLinkEffects(
                    EffectSkillIncrease(SKILL_SPOT, 6),
                    EffectSkillIncrease(SKILL_SEARCH, 6)),
                EffectSeeInvisible());
            break;

        case 14: // Pakt Nicości — saves vs spell +4, Wis -2
            ePrimary = EffectLinkEffects(
                EffectSavingThrowIncrease(SAVING_THROW_ALL, 4, SAVING_THROW_TYPE_SPELL),
                EffectAbilityDecrease(ABILITY_WISDOM, 2));
            break;

        case 15: // Głód Mroków — Ultravision, AC -1
            ePrimary = EffectLinkEffects(
                EffectUltravision(),
                EffectACDecrease(1, AC_DODGE_ENCHANTMENT_MODIFIER, DAMAGE_TYPE_ALL));
            break;

        case 16: // Trzecia Twarz — Bluff +12, Persuade +6
            ePrimary = EffectLinkEffects(
                EffectSkillIncrease(SKILL_BLUFF, 12),
                EffectSkillIncrease(SKILL_PERSUADE, 6));
            break;

        case 17: // Spalona Chwała — Fire resist 15%, Con -1
            ePrimary = EffectLinkEffects(
                EffectDamageImmunityIncrease(DAMAGE_TYPE_FIRE, 15),
                EffectAbilityDecrease(ABILITY_CONSTITUTION, 1));
            break;

        case 18: // Wieczne Czuwanie — Will save +6, Fort save +4
            ePrimary = EffectLinkEffects(
                EffectSavingThrowIncrease(SAVING_THROW_WILL, 6, SAVING_THROW_TYPE_ALL),
                EffectSavingThrowIncrease(SAVING_THROW_FORT, 4, SAVING_THROW_TYPE_ALL));
            break;

        case 19: // Waga Grzechu — Cha +2, Persuade +8
            ePrimary = EffectLinkEffects(
                EffectAbilityIncrease(ABILITY_CHARISMA, 2),
                EffectSkillIncrease(SKILL_PERSUADE, 8));
            break;

        case 20: // Maska Kłamcy — Bluff +15, Persuade +6
            ePrimary = EffectLinkEffects(
                EffectSkillIncrease(SKILL_BLUFF, 15),
                EffectSkillIncrease(SKILL_PERSUADE, 6));
            break;

        case 21: // Koniec Ery — all abilities +1
            ePrimary = EffectLinkEffects(
                EffectLinkEffects(
                    EffectAbilityIncrease(ABILITY_STRENGTH, 1),
                    EffectAbilityIncrease(ABILITY_DEXTERITY, 1)),
                EffectLinkEffects(
                    EffectLinkEffects(
                        EffectAbilityIncrease(ABILITY_CONSTITUTION, 1),
                        EffectAbilityIncrease(ABILITY_INTELLIGENCE, 1)),
                    EffectLinkEffects(
                        EffectAbilityIncrease(ABILITY_WISDOM, 1),
                        EffectAbilityIncrease(ABILITY_CHARISMA, 1))));
            break;

        default:
            return;
    }

    effect eTagged = TagEffect(ePrimary, TAROT_EFFECT_TAG + IntToString(nCardId));
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eTagged, oPC);
}

void TarotApplyAllDrawnEffects(object oPC)
{
    json jDrawn = TarotGetDrawnCards(oPC);
    int nCount  = JsonGetLength(jDrawn);
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow   = JsonArrayGet(jDrawn, i);
        int  nCardId = JsonGetInt(JsonObjectGet(jRow, "card_id"));
        TarotApplyCardEffect(oPC, nCardId);
    }
}

void TarotRemoveAllEffects(object oPC)
{
    int i;
    for(i = 0; i < TAROT_CARD_COUNT; i++)
        TarotRemoveCardEffect(oPC, i);
}

// ----------------------------------------------------------------
// Build NUI
// ----------------------------------------------------------------

json TarotBuildCardButton(object oPC, int nCardId)
{
    float fSz  = GetNuiScaleDimension(oPC, TAROT_CARD_SZ);
    string sId = TAROT_BTN_CARD + IntToString(nCardId);

    json jBtn = NuiButtonImage(NuiBind(TAROT_BIND_CARD_IMG + IntToString(nCardId)));
    jBtn = NuiId(jBtn, sId);
    jBtn = NuiWidth(jBtn, fSz);
    jBtn = NuiHeight(jBtn, fSz);
    jBtn = NuiTooltip(jBtn, NuiBind(TAROT_BIND_CARD_TIP + IntToString(nCardId)));
    jBtn = NuiEncouraged(jBtn, NuiBind(TAROT_BIND_CARD_ENC + IntToString(nCardId)));
    return jBtn;
}

json TarotBuildCardGrid(object oPC)
{
    float fSz  = GetNuiScaleDimension(oPC, TAROT_CARD_SZ);
    float fGap = GetNuiScaleDimension(oPC, 4.0);

    // 4 columns × 6 rows (22 cards + 2 empty spacers in last row)
    json jGrid = JsonArray();
    int nRow, nCol;
    for(nRow = 0; nRow < 6; nRow++)
    {
        json jRowCells = JsonArray();
        for(nCol = 0; nCol < 4; nCol++)
        {
            int nCardId = nRow * 4 + nCol;
            if(nCardId < TAROT_CARD_COUNT)
                jRowCells = JsonArrayInsert(jRowCells, TarotBuildCardButton(oPC, nCardId));
            else
                jRowCells = JsonArrayInsert(jRowCells, NuiSpacer());
        }
        float fRowH = GetNuiScaleDimension(oPC, TAROT_CARD_SZ + 2.0);
        json jRowEl = NuiRow(jRowCells);
        jRowEl = NuiHeight(jRowEl, fRowH);
        jGrid = JsonArrayInsert(jGrid, jRowEl);
    }

    return NuiCol(jGrid);
}

json TarotBuildDetailPanel(object oPC)
{
    float fImgW   = GetNuiScaleDimension(oPC, 90.0);
    float fImgH   = GetNuiScaleDimension(oPC, 130.0);
    float fLblH   = GetNuiScaleDimension(oPC, 24.0);
    float fTextH  = GetNuiScaleDimension(oPC, 64.0);
    float fOblH   = GetNuiScaleDimension(oPC, 74.0);

    // Large card image
    json jImg = NuiImage(NuiBind(TAROT_BIND_DET_IMG),
        JsonInt(NUI_ASPECT_FIT),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jImg = NuiWidth(jImg, fImgW);
    jImg = NuiHeight(jImg, fImgH);

    // Card name header
    json jName = NuiLabel(
        NuiBind(TAROT_BIND_DET_NAME),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiHeight(jName, fLblH);

    // Times drawn label
    json jDrawnLbl = NuiLabel(
        NuiBind(TAROT_BIND_DET_DRAWN),
        JsonInt(NUI_HALIGN_CENTER),
        JsonInt(NUI_VALIGN_MIDDLE));
    jDrawnLbl = NuiHeight(jDrawnLbl, GetNuiScaleDimension(oPC, 20.0));

    // Flavor text (italic via multiline label)
    json jFlv = NuiGroup(NuiText(NuiBind(TAROT_BIND_DET_FLV), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jFlv = NuiHeight(jFlv, GetNuiScaleDimension(oPC, 56.0));

    // Effect separator label
    json jEffHdr = NuiLabel(JsonString("Efekt:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEffHdr = NuiHeight(jEffHdr, GetNuiScaleDimension(oPC, 20.0));

    // Effect text
    json jEff = NuiGroup(NuiText(NuiBind(TAROT_BIND_DET_EFF), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jEff = NuiHeight(jEff, fTextH);

    // Obligation separator label
    json jOblHdr = NuiLabel(JsonString("Ciężar karty:"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jOblHdr = NuiHeight(jOblHdr, GetNuiScaleDimension(oPC, 20.0));

    // Obligation text
    json jObl = NuiGroup(NuiText(NuiBind(TAROT_BIND_DET_OBL), FALSE),
        TRUE, NUI_SCROLLBARS_NONE);
    jObl = NuiHeight(jObl, fOblH);

    // Assemble column
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(JsonArrayInsert(JsonArray(), jImg)));
    jCol = JsonArrayInsert(jCol, jName);
    jCol = JsonArrayInsert(jCol, jDrawnLbl);
    jCol = JsonArrayInsert(jCol, jFlv);
    jCol = JsonArrayInsert(jCol, jEffHdr);
    jCol = JsonArrayInsert(jCol, jEff);
    jCol = JsonArrayInsert(jCol, jOblHdr);
    jCol = JsonArrayInsert(jCol, jObl);
    jCol = JsonArrayInsert(jCol, NuiSpacer());

    return NuiCol(jCol);
}

json TarotBuildRoot(object oPC)
{
    float fBtnH     = GetNuiScaleDimension(oPC, 30.0);
    float fGridW    = GetNuiScaleDimension(oPC, 280.0);
    float fDetailW  = GetNuiScaleDimension(oPC, 340.0);
    float fSep      = GetNuiScaleDimension(oPC, 8.0);

    // -- Top bar: title + deck label --
    json jTitleLbl = NuiLabel(JsonString("Talia Demonów"),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTitleLbl = NuiHeight(jTitleLbl, fBtnH);

    json jDeckLbl = NuiLabel(NuiBind(TAROT_BIND_DECK_LBL),
        JsonInt(NUI_HALIGN_CENTER), JsonInt(NUI_VALIGN_MIDDLE));
    jDeckLbl = NuiHeight(jDeckLbl, fBtnH);

    json jCloseBtn = NuiButton(JsonString("X"));
    jCloseBtn = NuiId(jCloseBtn, TAROT_BTN_CLOSE);
    jCloseBtn = NuiWidth(jCloseBtn, GetNuiScaleDimension(oPC, 30.0));
    jCloseBtn = NuiHeight(jCloseBtn, fBtnH);

    json jTopRow = JsonArray();
    jTopRow = JsonArrayInsert(jTopRow, jTitleLbl);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jDeckLbl);
    jTopRow = JsonArrayInsert(jTopRow, NuiSpacer());
    jTopRow = JsonArrayInsert(jTopRow, jCloseBtn);

    // -- Main content: grid + separator + detail panel --
    json jGridGrp = NuiGroup(TarotBuildCardGrid(oPC), FALSE, NUI_SCROLLBARS_NONE);
    jGridGrp = NuiWidth(jGridGrp, fGridW);

    json jDetailGrp = NuiGroup(TarotBuildDetailPanel(oPC), FALSE, NUI_SCROLLBARS_AUTO);
    jDetailGrp = NuiId(jDetailGrp, TAROT_GRP_DETAIL);
    jDetailGrp = NuiWidth(jDetailGrp, fDetailW);

    json jContentRow = JsonArray();
    jContentRow = JsonArrayInsert(jContentRow, jGridGrp);
    jContentRow = JsonArrayInsert(jContentRow, NuiSpacer());
    jContentRow = JsonArrayInsert(jContentRow, jDetailGrp);

    // -- Bottom bar: draw + reset buttons --
    json jDrawBtn = NuiButton(NuiBind(TAROT_BIND_DRAW_LBL));
    jDrawBtn = NuiId(jDrawBtn, TAROT_BTN_DRAW);
    jDrawBtn = NuiEnabled(jDrawBtn, NuiBind(TAROT_BIND_DRAW_ENA));
    jDrawBtn = NuiWidth(jDrawBtn, GetNuiScaleDimension(oPC, 180.0));
    jDrawBtn = NuiHeight(jDrawBtn, fBtnH);

    json jResetBtn = NuiButton(JsonString("Przetasuj talię"));
    jResetBtn = NuiId(jResetBtn, TAROT_BTN_RESET);
    jResetBtn = NuiEnabled(jResetBtn, NuiBind(TAROT_BIND_RESET_ENA));
    jResetBtn = NuiWidth(jResetBtn, GetNuiScaleDimension(oPC, 160.0));
    jResetBtn = NuiHeight(jResetBtn, fBtnH);

    json jBotRow = JsonArray();
    jBotRow = JsonArrayInsert(jBotRow, jDrawBtn);
    jBotRow = JsonArrayInsert(jBotRow, NuiSpacer());
    jBotRow = JsonArrayInsert(jBotRow, jResetBtn);

    // -- Assemble root column --
    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jTopRow));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jContentRow));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jBotRow));

    return NuiCol(jRoot);
}

// ----------------------------------------------------------------
// Window open
// ----------------------------------------------------------------

void TarotOpenWindow(object oPC)
{
    if(NuiFindWindow(oPC, TAROT_WINDOW) != 0)
    {
        TarotFeedGrid(oPC, NuiFindWindow(oPC, TAROT_WINDOW));
        return;
    }

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, TAROT_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, TAROT_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
                         GetNuiScaleDimension(oPC, TAROT_W),
                         GetNuiScaleDimension(oPC, TAROT_H));

    json jWin = NuiWindow(TarotBuildRoot(oPC),
        JsonBool(FALSE),
        NuiBind(TAROT_WIN_GEOM),
        JsonBool(FALSE), JsonBool(FALSE), JsonBool(FALSE),
        JsonBool(TRUE),  JsonBool(FALSE));

    int nToken = NuiCreate(oPC, jWin, TAROT_WINDOW, TAROT_EV_SCRIPT);
    NuiSetBind(oPC, nToken, TAROT_WIN_GEOM, jGeom);

    SetLocalInt(oPC, TAROT_LVAR_SEL_CARD, -1);
    TarotFeedGrid(oPC, nToken);
    TarotClearDetailPanel(oPC, nToken);
}

// ----------------------------------------------------------------
// Feed — card grid
// ----------------------------------------------------------------

void TarotFeedGrid(object oPC, int nToken)
{
    json jDrawn = TarotGetDrawnCards(oPC);
    int  nDrawn = JsonGetLength(jDrawn);
    int  nSel   = GetLocalInt(oPC, TAROT_LVAR_SEL_CARD);

    // Build quick lookup: card_id -> draw_count
    object oMod = GetModule();
    int i;
    for(i = 0; i < TAROT_CARD_COUNT; i++)
        SetLocalInt(oMod, "TAROT_DC_" + IntToString(i), 0);
    for(i = 0; i < nDrawn; i++)
    {
        json jRow = JsonArrayGet(jDrawn, i);
        int nId   = JsonGetInt(JsonObjectGet(jRow, "card_id"));
        int nCnt  = JsonGetInt(JsonObjectGet(jRow, "draw_count"));
        SetLocalInt(oMod, "TAROT_DC_" + IntToString(nId), nCnt);
    }

    // Set per-card binds
    for(i = 0; i < TAROT_CARD_COUNT; i++)
    {
        int  nCnt     = GetLocalInt(oMod, "TAROT_DC_" + IntToString(i));
        int  bDrawn   = (nCnt > 0);
        string sImg   = bDrawn ? TarotCardIcon(i) : TarotCardBackIcon();
        string sTip   = bDrawn ? TarotCardName(i) : "Nieznana karta — wyciągnij, by poznać swój los.";

        NuiSetBind(oPC, nToken, TAROT_BIND_CARD_IMG + IntToString(i), JsonString(sImg));
        NuiSetBind(oPC, nToken, TAROT_BIND_CARD_TIP + IntToString(i), JsonString(sTip));
        NuiSetBind(oPC, nToken, TAROT_BIND_CARD_ENC + IntToString(i), JsonBool(i == nSel));

        DeleteLocalInt(oMod, "TAROT_DC_" + IntToString(i));
    }

    // Deck status label
    string sDeckLbl = IntToString(nDrawn) + " / " + IntToString(TAROT_CARD_COUNT)
                    + " kart odslonieto";
    if(nDrawn >= TAROT_CARD_COUNT)
        sDeckLbl = "Talia wyczerpana — czas przetasować.";
    NuiSetBind(oPC, nToken, TAROT_BIND_DECK_LBL, JsonString(sDeckLbl));

    // Draw button
    int bCanDraw = (nDrawn < TAROT_CARD_COUNT);
    NuiSetBind(oPC, nToken, TAROT_BIND_DRAW_ENA, JsonBool(bCanDraw));
    NuiSetBind(oPC, nToken, TAROT_BIND_DRAW_LBL,
        JsonString(bCanDraw ? "Wyciągnij kartę" : "Talia wyczerpana"));

    // Reset button — available only when all drawn
    NuiSetBind(oPC, nToken, TAROT_BIND_RESET_ENA, JsonBool(nDrawn >= TAROT_CARD_COUNT));
}

// ----------------------------------------------------------------
// Feed — detail panel
// ----------------------------------------------------------------

void TarotFeedDetailPanel(object oPC, int nToken, int nCardId)
{
    int nCnt = TarotGetCardDrawCount(oPC, nCardId);
    string sDrawnLbl = nCnt > 0
        ? ("Wylosowano: " + IntToString(nCnt) + "x")
        : "Jeszcze nie wylosowana.";

    NuiSetBind(oPC, nToken, TAROT_BIND_DET_IMG,   JsonString(nCnt > 0
        ? TarotCardIcon(nCardId) : TarotCardBackIcon()));
    NuiSetBind(oPC, nToken, TAROT_BIND_DET_NAME,  JsonString(nCnt > 0
        ? TarotCardName(nCardId) : "???"));
    NuiSetBind(oPC, nToken, TAROT_BIND_DET_DRAWN, JsonString(sDrawnLbl));
    NuiSetBind(oPC, nToken, TAROT_BIND_DET_FLV,   JsonString(nCnt > 0
        ? TarotCardFlavor(nCardId) : "Odwróć kartę, by poznać jej sekret."));
    NuiSetBind(oPC, nToken, TAROT_BIND_DET_EFF,   JsonString(nCnt > 0
        ? TarotCardEffect(nCardId) : ""));
    NuiSetBind(oPC, nToken, TAROT_BIND_DET_OBL,   JsonString(nCnt > 0
        ? TarotCardObligation(nCardId) : ""));
}

void TarotClearDetailPanel(object oPC, int nToken)
{
    NuiSetBind(oPC, nToken, TAROT_BIND_DET_IMG,   JsonString(TarotCardBackIcon()));
    NuiSetBind(oPC, nToken, TAROT_BIND_DET_NAME,  JsonString("Talia Demonów"));
    NuiSetBind(oPC, nToken, TAROT_BIND_DET_DRAWN, JsonString("Kliknij kartę, by ujrzeć jej oblicze."));
    NuiSetBind(oPC, nToken, TAROT_BIND_DET_FLV,   JsonString("\"Przeznaczenie nie pyta o pozwolenie.\""));
    NuiSetBind(oPC, nToken, TAROT_BIND_DET_EFF,   JsonString(""));
    NuiSetBind(oPC, nToken, TAROT_BIND_DET_OBL,   JsonString(""));
}

// ----------------------------------------------------------------
// Draw action
// ----------------------------------------------------------------

void TarotExecuteDraw(object oPC)
{
    int nToken = NuiFindWindow(oPC, TAROT_WINDOW);

    int nCardId = TarotPickRandomUndrawn(oPC);
    if(nCardId < 0)
    {
        SendMessageToPC(oPC, "[Talia] Talia jest wyczerpana. Przetasuj ją, by kontynuować.");
        return;
    }

    TarotRecordDraw(oPC, nCardId);
    TarotApplyCardEffect(oPC, nCardId);

    // Announce to the player
    string sMsg = "[Talia] Wyciągasz kartę: " + TarotCardName(nCardId) + ". "
                + TarotCardFlavor(nCardId);
    SendMessageToPC(oPC, sMsg);
    FloatingTextStringOnCreature(
        "Karta: " + TarotCardName(nCardId), oPC, FALSE);

    if(nToken != 0)
    {
        SetLocalInt(oPC, TAROT_LVAR_SEL_CARD, nCardId);
        TarotFeedGrid(oPC, nToken);
        TarotFeedDetailPanel(oPC, nToken, nCardId);
    }
}

// ----------------------------------------------------------------
// Reset deck
// ----------------------------------------------------------------

void TarotExecuteReset(object oPC)
{
    TarotRemoveAllEffects(oPC);
    TarotResetDeck(oPC);

    int nToken = NuiFindWindow(oPC, TAROT_WINDOW);
    SetLocalInt(oPC, TAROT_LVAR_SEL_CARD, -1);
    if(nToken != 0)
    {
        TarotFeedGrid(oPC, nToken);
        TarotClearDetailPanel(oPC, nToken);
    }

    SendMessageToPC(oPC, "[Talia] Karty wracają do ciemności. Pieczęć zostaje odnowiona.");
    FloatingTextStringOnCreature("Talia przetasowana.", oPC, FALSE);
}

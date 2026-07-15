#include "lib_obs_def"

void ObsOpen(object oPC);
void ObsFeed(object oPC, int nToken);

// ----------------------------------------------------------------
// Effect application
// ----------------------------------------------------------------

effect ObsBuildReadingEffect(int nSign)
{
    switch(nSign)
    {
        case  0: return EffectAttackIncrease(1, ATTACK_BONUS_ONHAND);
        case  1: return EffectLinkEffects(EffectSkillIncrease(SKILL_SPOT, 3),
                                          EffectSkillIncrease(SKILL_SEARCH, 3));
        case  2: return EffectSavingThrowIncrease(SAVING_THROW_FORT, 2, SAVING_THROW_TYPE_ALL);
        case  3: return EffectSavingThrowIncrease(SAVING_THROW_REFLEX, 2, SAVING_THROW_TYPE_ALL);
        case  4: return EffectAbilityIncrease(ABILITY_STRENGTH, 1);
        case  5: return EffectACIncrease(1, AC_DEFLECTION_BONUS);
        case  6: return EffectSavingThrowIncrease(SAVING_THROW_WILL, 2, SAVING_THROW_TYPE_ALL);
        case  7: return EffectLinkEffects(EffectSkillIncrease(SKILL_HIDE, 3),
                                          EffectSkillIncrease(SKILL_MOVE_SILENTLY, 3));
        case  8: return EffectLinkEffects(EffectDamageImmunityIncrease(DAMAGE_TYPE_COLD, 25),
                                          EffectAbilityIncrease(ABILITY_CONSTITUTION, 1));
        case  9: return EffectSkillIncrease(SKILL_ALL_SKILLS, 2);
        case 10: return EffectLinkEffects(EffectDamageImmunityIncrease(DAMAGE_TYPE_FIRE, 10),
                                          EffectAbilityIncrease(ABILITY_CHARISMA, 1));
        case 11: return EffectRegenerate(1, 10.0);
    }
    return EffectVisualEffect(VFX_DUR_BLUR);
}

effect ObsBuildBirthEffect(int nSign)
{
    switch(nSign)
    {
        case  0: return EffectAttackIncrease(1, ATTACK_BONUS_ONHAND);
        case  1: return EffectLinkEffects(EffectSkillIncrease(SKILL_SPOT, 2),
                                          EffectSkillIncrease(SKILL_SEARCH, 2));
        case  2: return EffectSavingThrowIncrease(SAVING_THROW_FORT, 1, SAVING_THROW_TYPE_ALL);
        case  3: return EffectSavingThrowIncrease(SAVING_THROW_REFLEX, 1, SAVING_THROW_TYPE_ALL);
        case  4: return EffectAbilityIncrease(ABILITY_STRENGTH, 1);
        case  5: return EffectACIncrease(1, AC_NATURAL_BONUS);
        case  6: return EffectSavingThrowIncrease(SAVING_THROW_WILL, 1, SAVING_THROW_TYPE_ALL);
        case  7: return EffectLinkEffects(EffectSkillIncrease(SKILL_HIDE, 2),
                                          EffectSkillIncrease(SKILL_MOVE_SILENTLY, 2));
        case  8: return EffectDamageImmunityIncrease(DAMAGE_TYPE_COLD, 10);
        case  9: return EffectSkillIncrease(SKILL_ALL_SKILLS, 1);
        case 10: return EffectLinkEffects(EffectDamageImmunityIncrease(DAMAGE_TYPE_FIRE, 5),
                                          EffectAbilityIncrease(ABILITY_CHARISMA, 1));
        case 11: return EffectRegenerate(1, 30.0);
    }
    return EffectVisualEffect(VFX_DUR_BLUR);
}

void ObsApplyReadingEffect(object oPC, int nSign)
{
    RemoveEffectByTag(oPC, OBS_TAG_READING);
    effect eEff = TagEffect(ObsBuildReadingEffect(nSign), OBS_TAG_READING);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eEff, oPC);
}

void ObsApplyBirthEffect(object oPC, int nSign)
{
    if(nSign < 0) return;
    RemoveEffectByTag(oPC, OBS_TAG_BIRTH);
    effect eEff = TagEffect(ObsBuildBirthEffect(nSign), OBS_TAG_BIRTH);
    ApplyEffectToObject(DURATION_TYPE_PERMANENT, eEff, oPC);
}

// ----------------------------------------------------------------
// Star map DrawList helpers
// ----------------------------------------------------------------

json ObsBuildBgStars()
{
    json jDl = JsonArray();
    json cDim = NuiColor(90, 90, 130, 160);

    // 24 scattered background stars (deterministic positions)
    float aX[24]; float aY[24];
    aX[0]=12.0;  aY[0]=18.0;
    aX[1]=55.0;  aY[1]=9.0;
    aX[2]=98.0;  aY[2]=24.0;
    aX[3]=145.0; aY[3]=7.0;
    aX[4]=185.0; aY[4]=20.0;
    aX[5]=220.0; aY[5]=11.0;
    aX[6]=28.0;  aY[6]=55.0;
    aX[7]=77.0;  aY[7]=48.0;
    aX[8]=120.0; aY[8]=62.0;
    aX[9]=168.0; aY[9]=44.0;
    aX[10]=210.0;aY[10]=58.0;
    aX[11]=8.0;  aY[11]=105.0;
    aX[12]=44.0; aY[12]=118.0;
    aX[13]=92.0; aY[13]=99.0;
    aX[14]=138.0;aY[14]=112.0;
    aX[15]=188.0;aY[15]=101.0;
    aX[16]=228.0;aY[16]=115.0;
    aX[17]=22.0; aY[17]=168.0;
    aX[18]=65.0; aY[18]=155.0;
    aX[19]=110.0;aY[19]=172.0;
    aX[20]=158.0;aY[20]=160.0;
    aX[21]=202.0;aY[21]=175.0;
    aX[22]=40.0; aY[22]=218.0;
    aX[23]=130.0;aY[23]=225.0;

    float fR = 1.5;
    int i;
    for(i = 0; i < 24; i++)
    {
        json jRect = NuiRect(aX[i] - fR, aY[i] - fR, fR * 2.0, fR * 2.0);
        jDl = JsonArrayInsert(jDl,
            NuiDrawListCircle(JsonBool(TRUE), jRect, cDim, JsonFloat(0.0), JsonBool(TRUE),
                              NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
    }
    return jDl;
}

json ObsMakePair(int nA, int nB)
{
    json j = JsonObject();
    j = JsonObjectSet(j, "a", JsonInt(nA));
    j = JsonObjectSet(j, "b", JsonInt(nB));
    return j;
}

// Returns JsonArray of NuiVec for each star in a constellation.
json ObsGetStarPositions(int nConst, float fW, float fH)
{
    json j = JsonArray();
    switch(nConst)
    {
        case 0: // Wisielec
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.06));
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.28));
            j = JsonArrayInsert(j, NuiVec(fW*0.28, fH*0.45));
            j = JsonArrayInsert(j, NuiVec(fW*0.72, fH*0.45));
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.62));
            j = JsonArrayInsert(j, NuiVec(fW*0.38, fH*0.82));
            j = JsonArrayInsert(j, NuiVec(fW*0.62, fH*0.82));
            break;
        case 1: // Krwawe Oko
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.06));
            j = JsonArrayInsert(j, NuiVec(fW*0.10, fH*0.50));
            j = JsonArrayInsert(j, NuiVec(fW*0.90, fH*0.50));
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.94));
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.50));
            break;
        case 2: // Pożeracz
            j = JsonArrayInsert(j, NuiVec(fW*0.12, fH*0.12));
            j = JsonArrayInsert(j, NuiVec(fW*0.88, fH*0.12));
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.52));
            j = JsonArrayInsert(j, NuiVec(fW*0.28, fH*0.88));
            j = JsonArrayInsert(j, NuiVec(fW*0.72, fH*0.88));
            break;
        case 3: // Czarny Kot
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.06));
            j = JsonArrayInsert(j, NuiVec(fW*0.06, fH*0.50));
            j = JsonArrayInsert(j, NuiVec(fW*0.94, fH*0.50));
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.94));
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.50));
            break;
        case 4: // Żelazna Pięść
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.06));
            j = JsonArrayInsert(j, NuiVec(fW*0.26, fH*0.32));
            j = JsonArrayInsert(j, NuiVec(fW*0.74, fH*0.32));
            j = JsonArrayInsert(j, NuiVec(fW*0.14, fH*0.68));
            j = JsonArrayInsert(j, NuiVec(fW*0.86, fH*0.68));
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.90));
            break;
        case 5: // Cierniowa Korona
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.06));
            j = JsonArrayInsert(j, NuiVec(fW*0.18, fH*0.34));
            j = JsonArrayInsert(j, NuiVec(fW*0.82, fH*0.34));
            j = JsonArrayInsert(j, NuiVec(fW*0.06, fH*0.72));
            j = JsonArrayInsert(j, NuiVec(fW*0.94, fH*0.72));
            j = JsonArrayInsert(j, NuiVec(fW*0.34, fH*0.88));
            j = JsonArrayInsert(j, NuiVec(fW*0.66, fH*0.88));
            break;
        case 6: // Złamany Miecz
            j = JsonArrayInsert(j, NuiVec(fW*0.10, fH*0.08));
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.38));
            j = JsonArrayInsert(j, NuiVec(fW*0.36, fH*0.54));
            j = JsonArrayInsert(j, NuiVec(fW*0.72, fH*0.74));
            j = JsonArrayInsert(j, NuiVec(fW*0.90, fH*0.92));
            break;
        case 7: // Widmo
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.06));
            j = JsonArrayInsert(j, NuiVec(fW*0.28, fH*0.24));
            j = JsonArrayInsert(j, NuiVec(fW*0.72, fH*0.24));
            j = JsonArrayInsert(j, NuiVec(fW*0.20, fH*0.58));
            j = JsonArrayInsert(j, NuiVec(fW*0.80, fH*0.58));
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.88));
            break;
        case 8: // Lodowy Tron
            j = JsonArrayInsert(j, NuiVec(fW*0.25, fH*0.08));
            j = JsonArrayInsert(j, NuiVec(fW*0.75, fH*0.08));
            j = JsonArrayInsert(j, NuiVec(fW*0.25, fH*0.52));
            j = JsonArrayInsert(j, NuiVec(fW*0.75, fH*0.52));
            j = JsonArrayInsert(j, NuiVec(fW*0.10, fH*0.90));
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.90));
            j = JsonArrayInsert(j, NuiVec(fW*0.90, fH*0.90));
            break;
        case 9: // Węzeł Ciemności
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.06));
            j = JsonArrayInsert(j, NuiVec(fW*0.06, fH*0.38));
            j = JsonArrayInsert(j, NuiVec(fW*0.94, fH*0.38));
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.52));
            j = JsonArrayInsert(j, NuiVec(fW*0.22, fH*0.86));
            j = JsonArrayInsert(j, NuiVec(fW*0.78, fH*0.86));
            break;
        case 10: // Płonące Wrzeciono
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.06));
            j = JsonArrayInsert(j, NuiVec(fW*0.30, fH*0.36));
            j = JsonArrayInsert(j, NuiVec(fW*0.70, fH*0.36));
            j = JsonArrayInsert(j, NuiVec(fW*0.16, fH*0.70));
            j = JsonArrayInsert(j, NuiVec(fW*0.84, fH*0.70));
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.92));
            break;
        case 11: // Kruk
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.34));
            j = JsonArrayInsert(j, NuiVec(fW*0.08, fH*0.14));
            j = JsonArrayInsert(j, NuiVec(fW*0.28, fH*0.24));
            j = JsonArrayInsert(j, NuiVec(fW*0.72, fH*0.24));
            j = JsonArrayInsert(j, NuiVec(fW*0.92, fH*0.14));
            j = JsonArrayInsert(j, NuiVec(fW*0.50, fH*0.88));
            break;
    }
    return j;
}

// Returns JsonArray of {a,b} index pairs defining line connections.
json ObsGetConnections(int nConst)
{
    json j = JsonArray();
    switch(nConst)
    {
        case 0: // Wisielec
            j = JsonArrayInsert(j, ObsMakePair(0,1));
            j = JsonArrayInsert(j, ObsMakePair(1,2));
            j = JsonArrayInsert(j, ObsMakePair(1,3));
            j = JsonArrayInsert(j, ObsMakePair(1,4));
            j = JsonArrayInsert(j, ObsMakePair(4,5));
            j = JsonArrayInsert(j, ObsMakePair(4,6));
            break;
        case 1: // Krwawe Oko
            j = JsonArrayInsert(j, ObsMakePair(0,1));
            j = JsonArrayInsert(j, ObsMakePair(0,2));
            j = JsonArrayInsert(j, ObsMakePair(1,3));
            j = JsonArrayInsert(j, ObsMakePair(2,3));
            j = JsonArrayInsert(j, ObsMakePair(4,0));
            j = JsonArrayInsert(j, ObsMakePair(4,3));
            break;
        case 2: // Pożeracz
            j = JsonArrayInsert(j, ObsMakePair(0,2));
            j = JsonArrayInsert(j, ObsMakePair(1,2));
            j = JsonArrayInsert(j, ObsMakePair(2,3));
            j = JsonArrayInsert(j, ObsMakePair(2,4));
            j = JsonArrayInsert(j, ObsMakePair(3,4));
            break;
        case 3: // Czarny Kot
            j = JsonArrayInsert(j, ObsMakePair(0,4));
            j = JsonArrayInsert(j, ObsMakePair(1,4));
            j = JsonArrayInsert(j, ObsMakePair(2,4));
            j = JsonArrayInsert(j, ObsMakePair(3,4));
            break;
        case 4: // Żelazna Pięść
            j = JsonArrayInsert(j, ObsMakePair(0,1));
            j = JsonArrayInsert(j, ObsMakePair(0,2));
            j = JsonArrayInsert(j, ObsMakePair(1,3));
            j = JsonArrayInsert(j, ObsMakePair(2,4));
            j = JsonArrayInsert(j, ObsMakePair(3,5));
            j = JsonArrayInsert(j, ObsMakePair(4,5));
            break;
        case 5: // Cierniowa Korona
            j = JsonArrayInsert(j, ObsMakePair(0,1));
            j = JsonArrayInsert(j, ObsMakePair(0,2));
            j = JsonArrayInsert(j, ObsMakePair(1,3));
            j = JsonArrayInsert(j, ObsMakePair(2,4));
            j = JsonArrayInsert(j, ObsMakePair(3,5));
            j = JsonArrayInsert(j, ObsMakePair(4,6));
            j = JsonArrayInsert(j, ObsMakePair(5,6));
            break;
        case 6: // Złamany Miecz
            j = JsonArrayInsert(j, ObsMakePair(0,1));
            j = JsonArrayInsert(j, ObsMakePair(1,2));
            j = JsonArrayInsert(j, ObsMakePair(2,3));
            j = JsonArrayInsert(j, ObsMakePair(3,4));
            break;
        case 7: // Widmo
            j = JsonArrayInsert(j, ObsMakePair(0,1));
            j = JsonArrayInsert(j, ObsMakePair(0,2));
            j = JsonArrayInsert(j, ObsMakePair(1,3));
            j = JsonArrayInsert(j, ObsMakePair(2,4));
            j = JsonArrayInsert(j, ObsMakePair(3,5));
            j = JsonArrayInsert(j, ObsMakePair(4,5));
            break;
        case 8: // Lodowy Tron
            j = JsonArrayInsert(j, ObsMakePair(0,1));
            j = JsonArrayInsert(j, ObsMakePair(0,2));
            j = JsonArrayInsert(j, ObsMakePair(1,3));
            j = JsonArrayInsert(j, ObsMakePair(2,3));
            j = JsonArrayInsert(j, ObsMakePair(2,4));
            j = JsonArrayInsert(j, ObsMakePair(3,6));
            j = JsonArrayInsert(j, ObsMakePair(4,5));
            j = JsonArrayInsert(j, ObsMakePair(5,6));
            break;
        case 9: // Węzeł Ciemności
            j = JsonArrayInsert(j, ObsMakePair(0,3));
            j = JsonArrayInsert(j, ObsMakePair(1,3));
            j = JsonArrayInsert(j, ObsMakePair(2,3));
            j = JsonArrayInsert(j, ObsMakePair(3,4));
            j = JsonArrayInsert(j, ObsMakePair(3,5));
            j = JsonArrayInsert(j, ObsMakePair(4,5));
            break;
        case 10: // Płonące Wrzeciono
            j = JsonArrayInsert(j, ObsMakePair(0,1));
            j = JsonArrayInsert(j, ObsMakePair(0,2));
            j = JsonArrayInsert(j, ObsMakePair(1,2));
            j = JsonArrayInsert(j, ObsMakePair(1,3));
            j = JsonArrayInsert(j, ObsMakePair(2,4));
            j = JsonArrayInsert(j, ObsMakePair(3,5));
            j = JsonArrayInsert(j, ObsMakePair(4,5));
            break;
        case 11: // Kruk
            j = JsonArrayInsert(j, ObsMakePair(0,1));
            j = JsonArrayInsert(j, ObsMakePair(0,2));
            j = JsonArrayInsert(j, ObsMakePair(0,3));
            j = JsonArrayInsert(j, ObsMakePair(0,4));
            j = JsonArrayInsert(j, ObsMakePair(0,5));
            j = JsonArrayInsert(j, ObsMakePair(1,2));
            j = JsonArrayInsert(j, ObsMakePair(3,4));
            break;
    }
    return j;
}

// Appends constellation drawing items to jDl and returns the updated array.
json ObsAppendConstellation(json jDl, int nConst, float fW, float fH,
                             json cStar, json cLine, float fStarR, float fLineThick)
{
    json jStars = ObsGetStarPositions(nConst, fW, fH);
    json jConns = ObsGetConnections(nConst);
    int  nStars = JsonGetLength(jStars);
    int  nConns = JsonGetLength(jConns);

    // Lines first (drawn behind stars).
    int i;
    for(i = 0; i < nConns; i++)
    {
        json jConn = JsonArrayGet(jConns, i);
        int  nA    = JsonGetInt(JsonObjectGet(jConn, "a"));
        int  nB    = JsonGetInt(JsonObjectGet(jConn, "b"));
        if(nA >= nStars || nB >= nStars) continue;
        json vA = JsonArrayGet(jStars, nA);
        json vB = JsonArrayGet(jStars, nB);
        jDl = JsonArrayInsert(jDl,
            NuiDrawListLine(JsonBool(TRUE), vA, vB, cLine, JsonFloat(fLineThick),
                            NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
    }

    // Star dots on top.
    for(i = 0; i < nStars; i++)
    {
        json vStar = JsonArrayGet(jStars, i);
        float fX   = JsonGetFloat(JsonObjectGet(vStar, "x"));
        float fY   = JsonGetFloat(JsonObjectGet(vStar, "y"));
        json jRect = NuiRect(fX - fStarR, fY - fStarR, fStarR * 2.0, fStarR * 2.0);
        jDl = JsonArrayInsert(jDl,
            NuiDrawListCircle(JsonBool(TRUE), jRect, cStar, JsonFloat(0.0), JsonBool(TRUE),
                              NUI_DRAW_LIST_ITEM_ORDER_BEFORE, NUI_DRAW_LIST_ITEM_RENDER_ALWAYS));
    }
    return jDl;
}

json ObsBuildStarMapDL(int nActive, int nBirth, float fW, float fH)
{
    json jDl = ObsBuildBgStars();

    if(nBirth >= 0 && nBirth != nActive)
    {
        json cBirthStar = NuiColor(80, 160, 240, 200);
        json cBirthLine = NuiColor(60, 120, 200, 120);
        jDl = ObsAppendConstellation(jDl, nBirth, fW, fH, cBirthStar, cBirthLine, 3.5, 1.0);
    }

    json cActiveStar = NuiColor(255, 220, 80, 255);
    json cActiveLine = NuiColor(220, 180, 60, 180);
    jDl = ObsAppendConstellation(jDl, nActive, fW, fH, cActiveStar, cActiveLine, 5.0, 1.6);

    return jDl;
}

// ----------------------------------------------------------------
// NUI window builder
// ----------------------------------------------------------------

json ObsBuildWindow(object oPC, int nActive, int nBirth)
{
    float fBtnH  = GetNuiScaleDimension(oPC, 28.0);
    float fMapW  = GetNuiScaleDimension(oPC, OBS_MAP_W);
    float fMapH  = GetNuiScaleDimension(oPC, OBS_MAP_H);
    float fInfoW = GetNuiScaleDimension(oPC, 284.0);
    float fLblH  = GetNuiScaleDimension(oPC, 20.0);
    float fLoreH = GetNuiScaleDimension(oPC, 108.0);

    // -- Header row --
    json jTitle = NuiLabel(JsonString("OBSERWATORIUM"),
                            JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jClose = NuiButton(JsonString("X"));
    jClose = NuiId(jClose, OBS_BTN_CLOSE);
    jClose = NuiWidth(jClose, GetNuiScaleDimension(oPC, 28.0));
    jClose = NuiHeight(jClose, fBtnH);
    json jHdrRow = JsonArray();
    jHdrRow = JsonArrayInsert(jHdrRow, jTitle);
    jHdrRow = JsonArrayInsert(jHdrRow, NuiSpacer());
    jHdrRow = JsonArrayInsert(jHdrRow, jClose);

    // -- Star map group (left) --
    json jStarDl = ObsBuildStarMapDL(nActive, nBirth, fMapW, fMapH);
    json jMapGrp = NuiGroup(NuiSpacer(), FALSE, NUI_SCROLLBARS_NONE);
    jMapGrp = NuiId(jMapGrp, "obs_map_grp");
    jMapGrp = NuiWidth(jMapGrp, fMapW);
    jMapGrp = NuiHeight(jMapGrp, fMapH);
    jMapGrp = NuiDrawList(jMapGrp, JsonBool(FALSE), jStarDl);

    // -- Info column (right) --
    // Dominant constellation
    json jConsCaption = NuiHeight(
        NuiLabel(JsonString("Dominująca konstelacja:"),
                 JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)),
        fLblH);

    json jConsName = NuiLabel(NuiBind(OBS_BIND_CONS_NAME),
                               JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jConsName = NuiHeight(jConsName, GetNuiScaleDimension(oPC, 28.0));
    jConsName = NuiStyleForegroundColor(jConsName, NuiColor(255, 220, 80));

    json jLoreText = NuiHeight(
        NuiGroup(NuiText(NuiBind(OBS_BIND_CONS_LORE), FALSE), TRUE, NUI_SCROLLBARS_AUTO),
        fLoreH);

    json jEffCaption = NuiHeight(
        NuiLabel(JsonString("Efekt odczytu:"),
                 JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)),
        fLblH);

    json jEffDesc = NuiLabel(NuiBind(OBS_BIND_EFF_DESC),
                              JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jEffDesc = NuiHeight(jEffDesc, fLblH);
    jEffDesc = NuiStyleForegroundColor(jEffDesc, NuiColor(160, 240, 140));

    // Birth sign
    json jBirthCaption = NuiHeight(
        NuiLabel(JsonString("Twój znak urodzenia:"),
                 JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE)),
        fLblH);

    json jBirthLbl = NuiLabel(NuiBind(OBS_BIND_BIRTH_LBL),
                               JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBirthLbl = NuiHeight(jBirthLbl, fLblH);
    jBirthLbl = NuiStyleForegroundColor(jBirthLbl, NuiColor(80, 180, 255));

    json jBirthEff = NuiLabel(NuiBind(OBS_BIND_BIRTH_EFF),
                               JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jBirthEff = NuiHeight(jBirthEff, fLblH);
    jBirthEff = NuiStyleForegroundColor(jBirthEff, NuiColor(110, 150, 210));

    // Read button row
    json jReadBtn = NuiButton(JsonString("Odczytaj Gwiazdy"));
    jReadBtn = NuiId(jReadBtn, OBS_BTN_READ);
    jReadBtn = NuiEnabled(jReadBtn, NuiBind(OBS_BIND_READ_ENA));
    jReadBtn = NuiTooltip(jReadBtn, NuiBind(OBS_BIND_READ_HINT));
    jReadBtn = NuiHeight(jReadBtn, fBtnH);

    json jCntLbl = NuiLabel(NuiBind(OBS_BIND_CNT_LBL),
                             JsonInt(NUI_HALIGN_RIGHT), JsonInt(NUI_VALIGN_MIDDLE));
    jCntLbl = NuiHeight(jCntLbl, fLblH);
    jCntLbl = NuiStyleForegroundColor(jCntLbl, NuiColor(130, 130, 130));

    json jReadRow = JsonArray();
    jReadRow = JsonArrayInsert(jReadRow, jReadBtn);
    jReadRow = JsonArrayInsert(jReadRow, NuiSpacer());
    jReadRow = JsonArrayInsert(jReadRow, jCntLbl);

    json jResultLbl = NuiLabel(NuiBind(OBS_BIND_RESULT),
                                JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_TOP));
    jResultLbl = NuiHeight(jResultLbl, GetNuiScaleDimension(oPC, 46.0));

    // Assemble info column
    json jInfoCol = JsonArray();
    jInfoCol = JsonArrayInsert(jInfoCol, jConsCaption);
    jInfoCol = JsonArrayInsert(jInfoCol, jConsName);
    jInfoCol = JsonArrayInsert(jInfoCol, jLoreText);
    jInfoCol = JsonArrayInsert(jInfoCol, jEffCaption);
    jInfoCol = JsonArrayInsert(jInfoCol, jEffDesc);
    jInfoCol = JsonArrayInsert(jInfoCol, CreateEmptyRow(oPC, 6.0));
    jInfoCol = JsonArrayInsert(jInfoCol, jBirthCaption);
    jInfoCol = JsonArrayInsert(jInfoCol, jBirthLbl);
    jInfoCol = JsonArrayInsert(jInfoCol, jBirthEff);
    jInfoCol = JsonArrayInsert(jInfoCol, NuiSpacer());
    jInfoCol = JsonArrayInsert(jInfoCol, NuiRow(jReadRow));
    jInfoCol = JsonArrayInsert(jInfoCol, jResultLbl);

    json jInfoGrp = NuiWidth(NuiCol(jInfoCol), fInfoW);

    // -- Main content row --
    json jMainRow = JsonArray();
    jMainRow = JsonArrayInsert(jMainRow, jMapGrp);
    jMainRow = JsonArrayInsert(jMainRow, NuiWidth(NuiSpacer(), GetNuiScaleDimension(oPC, 12.0)));
    jMainRow = JsonArrayInsert(jMainRow, jInfoGrp);

    // Root column
    json jRoot = JsonArray();
    jRoot = JsonArrayInsert(jRoot, NuiRow(jHdrRow));
    jRoot = JsonArrayInsert(jRoot, NuiRow(jMainRow));

    json jWin = NuiWindow(NuiCol(jRoot),
        JsonBool(FALSE),
        NuiBind(OBS_BIND_GEOM),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(FALSE),
        JsonBool(TRUE),
        JsonBool(FALSE));

    return jWin;
}

// ----------------------------------------------------------------
// Feed binds
// ----------------------------------------------------------------

void ObsFeed(object oPC, int nToken)
{
    int nActive    = ObsGetDominantConstellation();
    int nBirth     = ObsGetBirthSign(oPC);
    json jReadData = ObsGetReadingData(oPC);
    int nLastTs    = JsonGetInt(JsonObjectGet(jReadData, "ts"));
    int nNow       = ObsNowUnix();
    int nElapsed   = nNow - nLastTs;
    int nReadCount = JsonGetInt(JsonObjectGet(jReadData, "count"));

    NuiSetBind(oPC, nToken, OBS_BIND_CONS_NAME, JsonString(ObsGetConstellationName(nActive)));
    NuiSetBind(oPC, nToken, OBS_BIND_CONS_LORE, JsonString(ObsGetConstellationLore(nActive)));
    NuiSetBind(oPC, nToken, OBS_BIND_EFF_DESC,  JsonString(ObsGetReadingEffectDesc(nActive)));

    if(nBirth >= 0)
    {
        NuiSetBind(oPC, nToken, OBS_BIND_BIRTH_LBL, JsonString(ObsGetConstellationName(nBirth)));
        NuiSetBind(oPC, nToken, OBS_BIND_BIRTH_EFF, JsonString(ObsGetBirthEffectDesc(nBirth)));
    }
    else
    {
        NuiSetBind(oPC, nToken, OBS_BIND_BIRTH_LBL, JsonString("— nieznany —"));
        NuiSetBind(oPC, nToken, OBS_BIND_BIRTH_EFF,
            JsonString("Spędź chwilę pod gwiazdami, by poznać swój znak."));
    }

    int bCanRead = (nLastTs == 0 || nElapsed >= OBS_READING_DURATION);
    NuiSetBind(oPC, nToken, OBS_BIND_READ_ENA, JsonBool(bCanRead));

    if(bCanRead)
    {
        NuiSetBind(oPC, nToken, OBS_BIND_READ_HINT,
            JsonString("Rzut Wiedzą DC " + IntToString(OBS_READ_DC) + " — gwiazdy podzielą się mocą."));
    }
    else
    {
        int nRem = OBS_READING_DURATION - nElapsed;
        int nMin = nRem / 60;
        NuiSetBind(oPC, nToken, OBS_BIND_READ_HINT,
            JsonString("Gwiazdy nie przemówią tak prędko. Poczekaj jeszcze ~" + IntToString(nMin) + " min."));
    }

    string sResult = GetLocalString(oPC, OBS_LVAR_RESULT);
    NuiSetBind(oPC, nToken, OBS_BIND_RESULT,  JsonString(sResult));
    NuiSetBind(oPC, nToken, OBS_BIND_CNT_LBL,
        JsonString(nReadCount > 0 ? IntToString(nReadCount) + " odczytań" : ""));
}

// ----------------------------------------------------------------
// Open window
// ----------------------------------------------------------------

void ObsOpen(object oPC)
{
    int nToken = NuiFindWindow(oPC, OBS_WINDOW);
    if(nToken != 0)
    {
        ObsFeed(oPC, nToken);
        return;
    }

    int nActive = ObsGetDominantConstellation();
    int nBirth  = ObsGetBirthSign(oPC);

    float fCX = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_WIDTH))
                 - GetNuiScaleDimension(oPC, OBS_WIN_W)) / 2.0;
    float fCY = (IntToFloat(GetPlayerDeviceProperty(oPC, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT))
                 - GetNuiScaleDimension(oPC, OBS_WIN_H)) / 2.0;
    json jGeom = NuiRect(fCX, fCY,
                         GetNuiScaleDimension(oPC, OBS_WIN_W),
                         GetNuiScaleDimension(oPC, OBS_WIN_H));

    json jWin  = ObsBuildWindow(oPC, nActive, nBirth);
    nToken     = NuiCreate(oPC, jWin, OBS_WINDOW, OBS_EV_SCRIPT);
    NuiSetBind(oPC, nToken, OBS_BIND_GEOM, jGeom);

    ObsFeed(oPC, nToken);
}

// ----------------------------------------------------------------
// Star reading (skill check + effects)
// ----------------------------------------------------------------

void ObsDoReading(object oPC, int nToken)
{
    int nActive  = ObsGetDominantConstellation();
    int nSkill   = GetSkillRank(SKILL_LORE, oPC, TRUE);
    int nRoll    = d20();
    int bSuccess = ((nSkill + nRoll) >= OBS_READ_DC);

    string sMsg;
    if(bSuccess)
    {
        int nBirth = ObsGetBirthSign(oPC);
        if(nBirth < 0)
        {
            ObsSetBirthSign(oPC, nActive);
            ObsApplyBirthEffect(oPC, nActive);
            sMsg = "Gwiazdy odsłoniły twój znak — "
                   + ObsGetConstellationName(nActive)
                   + ". Pieczęć niebiańska spoczywa na tobie na wieki.";
        }
        else
        {
            sMsg = "Szept " + ObsGetConstellationName(nActive)
                   + " przenika kość i krew. Moc trwa przez dwie godziny.";
        }

        ObsApplyReadingEffect(oPC, nActive);
        ObsRecordReading(oPC, nActive);

        FloatingTextStringOnCreature(
            "★ " + ObsGetConstellationName(nActive)
            + " — " + ObsGetReadingEffectDesc(nActive),
            oPC, FALSE);
    }
    else
    {
        sMsg = "Gwiazdy milczą. Ich przesłanie pozostaje zakryte (Wiedza "
               + IntToString(nSkill) + " + " + IntToString(nRoll)
               + " vs DC " + IntToString(OBS_READ_DC) + ").";
        FloatingTextStringOnCreature("Odczyt nieudany — niebo jest nieme.", oPC, FALSE);
    }

    SetLocalString(oPC, OBS_LVAR_RESULT, sMsg);
    ObsFeed(oPC, nToken);
}

// ----------------------------------------------------------------
// Convergence announcement (called from module heartbeat)
// ----------------------------------------------------------------

void ObsAnnounceConvergence()
{
    int nActive  = ObsGetDominantConstellation();
    string sName = ObsGetConstellationName(nActive);
    string sMsg  = "[Obserwatorium] Niebieska Zbieżność — "
                   + sName
                   + " osiąga szczyt mocy. Odwiedź obserwatorium po wyjątkowy błogosławieństwo.";

    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        SendMessageToPC(oPC, sMsg);
        oPC = GetNextPC();
    }
}

// ----------------------------------------------------------------
// Reapply persistent effects on login
// ----------------------------------------------------------------

void ObsRestoreEffects(object oPC)
{
    int nBirth = ObsGetBirthSign(oPC);
    ObsApplyBirthEffect(oPC, nBirth);

    if(nBirth >= 0)
    {
        SendMessageToPC(oPC,
            "[Obserwatorium] Twój znak urodzenia: "
            + ObsGetConstellationName(nBirth)
            + " — " + ObsGetBirthEffectDesc(nBirth));
    }

    // Reapply reading effect if still within cooldown window.
    json jReadData = ObsGetReadingData(oPC);
    int  nLastTs   = JsonGetInt(JsonObjectGet(jReadData, "ts"));
    int  nLastSign = JsonGetInt(JsonObjectGet(jReadData, "sign"));
    if(nLastTs > 0 && nLastSign >= 0)
    {
        int nNow     = ObsNowUnix();
        int nElapsed = nNow - nLastTs;
        if(nElapsed < OBS_READING_DURATION)
        {
            ObsApplyReadingEffect(oPC, nLastSign);
            SendMessageToPC(oPC,
                "[Obserwatorium] Moc " + ObsGetConstellationName(nLastSign)
                + " nadal przenika twoją krew.");
        }
    }
}

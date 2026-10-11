#include "lib_fcraft"

// ----------------------------------------------------------------
// Active ability dispatch
// ----------------------------------------------------------------

void FcraftDoWebAbility(object oPC)
{
    DeleteLocalInt(oPC, FCRAFT_LVAR_TARGETING);
    SetLocalInt(oPC, FCRAFT_COOL_WEB, 1);

    object oTarget = GetTargetingModeSelectedObject();
    location lLoc  = GetTargetingModeSelectedPosition();

    if(!GetIsObjectValid(oTarget))
        lLoc = GetTargetingModeSelectedPosition();

    ApplyEffectAtLocation(DURATION_TYPE_TEMPORARY, EffectVisualEffect(VFX_DUR_WEB), lLoc, 10.0);

    // Apply entangle to all creatures within 5m of chosen point
    object oC = GetFirstObjectInShape(SHAPE_SPHERE, 5.0, lLoc, TRUE, OBJECT_TYPE_CREATURE);
    while(GetIsObjectValid(oC))
    {
        if(oC != oPC)
            ApplyEffectToObject(DURATION_TYPE_TEMPORARY, EffectEntangle(), oC, 8.0);
        oC = GetNextObjectInShape(SHAPE_SPHERE, 5.0, lLoc, TRUE, OBJECT_TYPE_CREATURE);
    }

    SendMessageToPC(oPC, "[Kowalnia] Sieć wypluwa się i spowija wrogów.");
    FloatingTextStringOnCreature("*plujesz siecią*", oPC, TRUE);
}

void FcraftDoPoisonAbility(object oPC)
{
    DeleteLocalInt(oPC, FCRAFT_LVAR_TARGETING);
    SetLocalInt(oPC, FCRAFT_COOL_POISON, 1);

    object oTarget = GetTargetingModeSelectedObject();
    if(!GetIsObjectValid(oTarget) || !GetIsEnemy(oTarget, oPC))
    {
        SendMessageToPC(oPC, "[Kowalnia] Nieważny cel.");
        return;
    }

    effect ePoison = EffectPoison(POISON_HUGE_SPIDER_VENOM);
    effect eDmg    = EffectDamage(d6(2), DAMAGE_TYPE_POISON);
    effect eFx     = EffectLinkEffects(ePoison, EffectVisualEffect(VFX_IMP_POISON_S));
    ApplyEffectToObject(DURATION_TYPE_INSTANT, eFx,  oTarget);
    ApplyEffectToObject(DURATION_TYPE_INSTANT, eDmg, oTarget);

    SendMessageToPC(oPC, "[Kowalnia] Jad tryska z kłów i trafia w cel.");
    FloatingTextStringOnCreature("*kłujesz jadowitymi kłami*", oPC, TRUE);
}

void FcraftDoBlinkAbility(object oPC)
{
    DeleteLocalInt(oPC, FCRAFT_LVAR_TARGETING);
    SetLocalInt(oPC, FCRAFT_COOL_BLINK, 1);

    location lDest = GetTargetingModeSelectedPosition();
    float fDist    = GetDistanceBetweenLocations(GetLocation(oPC), lDest);
    if(fDist > 8.0 || fDist < 0.1)
    {
        SendMessageToPC(oPC, "[Kowalnia] Zbyt daleko — cień nie sięga.");
        return;
    }

    ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
        EffectVisualEffect(VFX_DUR_CUTSCENE_INVISIBILITY), oPC, 0.5);
    AssignCommand(oPC, JumpToLocation(lDest));
    DelayCommand(0.6, ApplyEffectToObject(DURATION_TYPE_TEMPORARY,
        EffectVisualEffect(VFX_COM_CHUNK_RED_SMALL), oPC, 0.5));

    SendMessageToPC(oPC, "[Kowalnia] Cień przemieszcza cię przez mrok.");
    FloatingTextStringOnCreature("*znikasz w cieniu*", oPC, TRUE);
}

// ----------------------------------------------------------------
// Targeting handler (called from sys_on_target.nss)
// ----------------------------------------------------------------

void FcraftOnTarget(object oPC)
{
    string sModId = GetLocalString(oPC, FCRAFT_LVAR_TARGETING);
    if(sModId == "") return;

    if(sModId == FCRAFT_MOD_SPIDERGLAND) { FcraftDoWebAbility(oPC);    return; }
    if(sModId == FCRAFT_MOD_VENOMFANG)   { FcraftDoPoisonAbility(oPC); return; }
    if(sModId == FCRAFT_MOD_SHADOWLIMB)  { FcraftDoBlinkAbility(oPC);  return; }

    DeleteLocalString(oPC, FCRAFT_LVAR_TARGETING);
}

// ----------------------------------------------------------------
// Main NUI event handler
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, FCRAFT_WIN_MAIN)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        DeleteLocalInt(oPC, FCRAFT_LVAR_SEL_IDX);
        DeleteLocalInt(oPC, FCRAFT_LVAR_SEL_ACT);
        DeleteLocalInt(oPC, FCRAFT_LVAR_TAB);
        DeleteLocalString(oPC, FCRAFT_LVAR_TARGETING);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == FCRAFT_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }

        if(sElem == FCRAFT_BTN_TAB_CAT)
        {
            SetLocalInt(oPC, FCRAFT_LVAR_TAB, 0);
            SetLocalInt(oPC, FCRAFT_LVAR_SEL_IDX, -1);
            FcraftFeedCatalog(oPC, nToken);
            FcraftFeedDetail(oPC, nToken, -1);
            return;
        }

        if(sElem == FCRAFT_BTN_TAB_ACT)
        {
            SetLocalInt(oPC, FCRAFT_LVAR_TAB, 1);
            SetLocalInt(oPC, FCRAFT_LVAR_SEL_ACT, -1);
            FcraftFeedActive(oPC, nToken);
            FcraftFeedActiveDetail(oPC, nToken, -1);
            return;
        }

        if(sElem == FCRAFT_BTN_IMPLANT)
        {
            int nSel = GetLocalInt(oPC, FCRAFT_LVAR_SEL_IDX);
            if(nSel < 0) return;
            string sModId = FcraftModId(nSel);
            FcraftApplyMod(oPC, sModId);
            FcraftFeedCatalog(oPC, nToken);
            FcraftFeedDetail(oPC, nToken, nSel);
            FcraftFeedActive(oPC, nToken);
            return;
        }

        if(sElem == FCRAFT_BTN_REMOVE)
        {
            int nSel = GetLocalInt(oPC, FCRAFT_LVAR_SEL_ACT);
            if(nSel < 0) return;
            json jMods = FcraftGetMods(oPC);
            if(nSel >= JsonGetLength(jMods)) return;
            string sModId = JsonGetString(JsonArrayGet(jMods, nSel));
            FcraftRemoveMod(oPC, sModId);
            SetLocalInt(oPC, FCRAFT_LVAR_SEL_ACT, -1);
            FcraftFeedActive(oPC, nToken);
            FcraftFeedActiveDetail(oPC, nToken, -1);
            FcraftFeedCatalog(oPC, nToken);
            return;
        }

        if(sElem == FCRAFT_BTN_USE)
        {
            int nSel = GetLocalInt(oPC, FCRAFT_LVAR_SEL_ACT);
            if(nSel < 0) return;
            json jMods = FcraftGetMods(oPC);
            if(nSel >= JsonGetLength(jMods)) return;
            string sModId = JsonGetString(JsonArrayGet(jMods, nSel));
            if(!FcraftModHasAbility(sModId)) return;
            string sCoolTag = FcraftModCooldownTag(sModId);
            if(GetLocalInt(oPC, sCoolTag) == 1)
            {
                SendMessageToPC(oPC, "[Kowalnia] Zdolność na odnowieniu — odpocznij, by ją przywrócić.");
                return;
            }
            SetLocalString(oPC, FCRAFT_LVAR_TARGETING, sModId);
            if(sModId == FCRAFT_MOD_SHADOWLIMB)
                EnterTargetingMode(oPC, OBJECT_TYPE_ALL, CURSOR_MAGIC);
            else if(sModId == FCRAFT_MOD_SPIDERGLAND)
                EnterTargetingMode(oPC, OBJECT_TYPE_ALL, CURSOR_ATTACK);
            else
                EnterTargetingMode(oPC, OBJECT_TYPE_CREATURE, CURSOR_ATTACK);
            NuiDestroy(oPC, nToken);
            return;
        }
    }

    if(sEvent == EVENT_TYPE_MOUSEDOWN)
    {
        if(sElem == FCRAFT_BTN_CAT_ROW)
        {
            SetLocalInt(oPC, FCRAFT_LVAR_SEL_IDX, nIdx);
            FcraftFeedDetail(oPC, nToken, nIdx);

            json jEncs = JsonArray();
            int i;
            for(i = 0; i < FCRAFT_MOD_COUNT; i++)
                jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx));
            NuiSetBind(oPC, nToken, FCRAFT_BIND_CAT_ENC, jEncs);
            return;
        }

        if(sElem == FCRAFT_BTN_ACT_ROW)
        {
            SetLocalInt(oPC, FCRAFT_LVAR_SEL_ACT, nIdx);
            FcraftFeedActiveDetail(oPC, nToken, nIdx);

            json jMods = FcraftGetMods(oPC);
            int nCount = JsonGetLength(jMods);
            json jEncs = JsonArray();
            int i;
            for(i = 0; i < FCRAFT_MAX_MODS; i++)
                jEncs = JsonArrayInsert(jEncs, JsonBool(i == nIdx && i < nCount));
            NuiSetBind(oPC, nToken, FCRAFT_BIND_ACT_ENC, jEncs);
            return;
        }
    }
}

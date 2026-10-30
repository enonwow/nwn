#include "lib_eff"

// ----------------------------------------------------------------
// Effigy creation — core action
// ----------------------------------------------------------------

void EffDoCreate(object oPC)
{
    string sTargetUuid = GetLocalString(oPC, EFF_LVAR_SEL_TGT_UUID);
    string sTargetName = GetLocalString(oPC, EFF_LVAR_SEL_TGT_NAME);
    int    nCurseType  = GetLocalInt(oPC,    EFF_LVAR_SEL_CURSE);

    if(sTargetUuid == "" || nCurseType <= 0)
    {
        SendMessageToPC(oPC, "[Figurka] Wybierz cel i rodzaj klątwy.");
        return;
    }

    int nCost = EffCurseCost(nCurseType);
    if(GetGold(oPC) < nCost)
    {
        SendMessageToPC(oPC, "[Figurka] Brakuje ci " + IntToString(nCost) + " złota.");
        return;
    }

    if(EffCountActiveByCreator(GetObjectUUID(oPC)) >= EFF_MAX_EFFIGIES_PER_PC)
    {
        SendMessageToPC(oPC, "[Figurka] Masz już maksymalną liczbę aktywnych figurek ("
            + IntToString(EFF_MAX_EFFIGIES_PER_PC) + ").");
        return;
    }

    TakeGoldFromCreature(nCost, oPC, TRUE);
    int nId = EffCreateEffigy(GetObjectUUID(oPC), sTargetUuid, nCurseType);

    if(nId <= 0)
    {
        SendMessageToPC(oPC, "[Figurka] Rytuał nie powiódł się. Spróbuj ponownie.");
        return;
    }

    SendMessageToPC(oPC,
        "[Figurka] Figurka klątwy " + EffCurseName(nCurseType)
        + " stworzona. Cel: " + sTargetName + ".");

    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_FNF_SMOKE_PUFF), oPC);

    // Reset selection
    DeleteLocalString(oPC, EFF_LVAR_SEL_TGT_UUID);
    DeleteLocalString(oPC, EFF_LVAR_SEL_TGT_NAME);
    DeleteLocalInt(oPC, EFF_LVAR_SEL_CURSE);
}

// ----------------------------------------------------------------
// Smash effigy
// ----------------------------------------------------------------

void EffDoSmash(object oPC)
{
    int nId = GetLocalInt(oPC, EFF_LVAR_SEL_MINE_ID);
    if(nId <= 0)
    {
        SendMessageToPC(oPC, "[Figurka] Nie zaznaczono żadnej figurki.");
        return;
    }

    json jEffigy = EffGetEffigyById(nId, GetObjectUUID(oPC));
    if(JsonGetType(jEffigy) == JSON_TYPE_NULL || JsonGetInt(JsonObjectGet(jEffigy, "is_active")) == 0)
    {
        SendMessageToPC(oPC, "[Figurka] Figurka nie jest już aktywna.");
        DeleteLocalInt(oPC, EFF_LVAR_SEL_MINE_ID);
        return;
    }

    string sTargetUuid = JsonGetString(JsonObjectGet(jEffigy, "target_uuid"));
    int nDmg = EFF_SMASH_DAMAGE_MIN + Random(EFF_SMASH_DAMAGE_MAX - EFF_SMASH_DAMAGE_MIN + 1);

    // Apply damage to the target if online
    object oTarget = GetFirstPC();
    while(GetIsObjectValid(oTarget))
    {
        if(GetObjectUUID(oTarget) == sTargetUuid)
        {
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectDamage(nDmg, DAMAGE_TYPE_NEGATIVE), oTarget);
            ApplyEffectToObject(DURATION_TYPE_INSTANT,
                EffectVisualEffect(VFX_COM_BLOOD_CRT_RED), oTarget);
            SendMessageToPC(oTarget,
                "[Figurka] Coś pęka w tobie jak stłuczona kość... ("
                + IntToString(nDmg) + " obrażeń negatywnej energii)");
            break;
        }
        oTarget = GetNextPC();
    }

    EffDeactivateEffigy(nId, 1);
    DeleteLocalInt(oPC, EFF_LVAR_SEL_MINE_ID);

    SendMessageToPC(oPC,
        "[Figurka] Figurka roztrzaskana. Obrażenia: " + IntToString(nDmg) + ".");
    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_FNF_SMOKE_PUFF), oPC);
}

// ----------------------------------------------------------------
// Cleanse (pay gold to remove selected detected effigy)
// ----------------------------------------------------------------

void EffDoCleanse(object oPC)
{
    int nId = GetLocalInt(oPC, EFF_LVAR_SEL_AFF_ID);
    if(nId <= 0)
    {
        SendMessageToPC(oPC, "[Figurka] Nie zaznaczono klątwy do zdjęcia.");
        return;
    }

    if(GetGold(oPC) < EFF_CLEANSE_COST)
    {
        SendMessageToPC(oPC, "[Figurka] Oczyszczenie kosztuje "
            + IntToString(EFF_CLEANSE_COST) + " złota.");
        return;
    }

    // Verify the effigy is still active and targets this PC
    json jEffigies = EffGetEffigiesTargeting(GetObjectUUID(oPC));
    int  nCount    = JsonGetLength(jEffigies);
    int  bFound    = FALSE;
    string sCreatorUuid = "";
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow = JsonArrayGet(jEffigies, i);
        if(JsonGetInt(JsonObjectGet(jRow, "id")) == nId)
        {
            bFound = TRUE;
            sCreatorUuid = JsonGetString(JsonObjectGet(jRow, "creator_uuid"));
            break;
        }
    }

    if(!bFound)
    {
        SendMessageToPC(oPC, "[Figurka] Ta klątwa nie jest już aktywna.");
        EffDeleteDetection(nId, GetObjectUUID(oPC));
        DeleteLocalInt(oPC, EFF_LVAR_SEL_AFF_ID);
        return;
    }

    TakeGoldFromCreature(EFF_CLEANSE_COST, oPC, TRUE);
    EffDeactivateEffigy(nId, 0);
    EffDeleteDetection(nId, GetObjectUUID(oPC));
    DeleteLocalInt(oPC, EFF_LVAR_SEL_AFF_ID);

    // Remove any lingering stat-drain effects tagged with the effigy id
    effect eEff = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEff))
    {
        if(GetEffectTag(eEff) == "EFF_CURSE_" + IntToString(nId))
            RemoveEffect(oPC, eEff);
        eEff = GetNextEffect(oPC);
    }

    ApplyEffectToObject(DURATION_TYPE_INSTANT,
        EffectVisualEffect(VFX_IMP_REMOVE_CONDITION), oPC);
    SendMessageToPC(oPC, "[Figurka] Klątwa zdjęta. Ciemność odpływa...");

    if(sCreatorUuid != "")
        EffNotifyCreator(sCreatorUuid,
            "Twoja figurka klątwy na " + GetName(oPC) + " została zniszczona.");
}

// ----------------------------------------------------------------
// Detection roll
// ----------------------------------------------------------------

void EffDoDetect(object oPC)
{
    string sUuid    = GetObjectUUID(oPC);
    int nUndet      = EffCountUndetectedAffecting(sUuid);
    if(nUndet == 0)
    {
        SendMessageToPC(oPC, "[Figurka] Nie wyczuwasz żadnych ukrytych klątw.");
        return;
    }

    // WIS modifier + Spellcraft ranks vs DC
    int nWisMod = GetAbilityModifier(ABILITY_WISDOM, oPC);
    int nSpell  = GetSkillRank(SKILL_SPELLCRAFT, oPC, FALSE);
    int nRoll   = d20() + nWisMod + (nSpell / 3);

    SendMessageToPC(oPC,
        "[Figurka] Rzut na wykrycie klątwy: " + IntToString(nRoll)
        + " (potrzeba " + IntToString(EFF_DETECT_DC) + ")");

    if(nRoll < EFF_DETECT_DC)
    {
        SendMessageToPC(oPC, "[Figurka] Pieczęć krwi pulsuje słabo... coś jest, lecz umyka ci.");
        return;
    }

    // Detect all active undetected effigies targeting this PC
    json jAll = EffGetEffigiesTargeting(sUuid);
    int nCount = JsonGetLength(jAll);
    int nNewlyFound = 0;
    int i;
    for(i = 0; i < nCount; i++)
    {
        json jRow = JsonArrayGet(jAll, i);
        int nId   = JsonGetInt(JsonObjectGet(jRow, "id"));
        if(!EffIsDetected(nId, sUuid))
        {
            EffMarkDetected(nId, sUuid);
            nNewlyFound++;
        }
    }

    if(nNewlyFound > 0)
    {
        SendMessageToPC(oPC,
            "[Figurka] Wykryłeś " + IntToString(nNewlyFound)
            + " nową klątwę! Sprawdź listę poniżej.");
        ApplyEffectToObject(DURATION_TYPE_INSTANT,
            EffectVisualEffect(VFX_IMP_NEGATIVE_ENERGY), oPC);
    }
    else
    {
        SendMessageToPC(oPC, "[Figurka] Nic nowego nie wykryto.");
    }
}

// ----------------------------------------------------------------
// Main event handler
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();

    if(oPC == OBJECT_INVALID) return;
    if(NuiFindWindow(oPC, EFF_WINDOW) != nToken) return;

    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nRow   = NuiGetEventArrayIndex();

    // ---- Close ----
    if(sEvent == EVENT_TYPE_CLICK && sElem == EFF_BTN_CLOSE)
    {
        NuiDestroy(oPC, nToken);
        return;
    }

    // ---- Tab switches ----
    if(sEvent == EVENT_TYPE_CLICK && sElem == EFF_BTN_TAB0)
    {
        EffSwitchTab(oPC, nToken, EFF_TAB_CREATE);
        return;
    }
    if(sEvent == EVENT_TYPE_CLICK && sElem == EFF_BTN_TAB1)
    {
        EffSwitchTab(oPC, nToken, EFF_TAB_MINE);
        return;
    }
    if(sEvent == EVENT_TYPE_CLICK && sElem == EFF_BTN_TAB2)
    {
        EffSwitchTab(oPC, nToken, EFF_TAB_AFFECTED);
        return;
    }

    // ---- Target row selection ----
    if(sEvent == EVENT_TYPE_CLICK && sElem == EFF_BTN_TGT_ROW)
    {
        json jPlayers = EffGetKnownPlayers(oPC);
        if(nRow < 0 || nRow >= JsonGetLength(jPlayers)) return;
        json jP = JsonArrayGet(jPlayers, nRow);
        SetLocalString(oPC, EFF_LVAR_SEL_TGT_UUID, JsonGetString(JsonObjectGet(jP, "uuid")));
        SetLocalString(oPC, EFF_LVAR_SEL_TGT_NAME, JsonGetString(JsonObjectGet(jP, "char_name")));
        NuiSetBind(oPC, nToken, EFF_BIND_TGT_LBL,
            JsonString("Cel: " + JsonGetString(JsonObjectGet(jP, "char_name"))));
        EffRefreshCursePanel(oPC, nToken);
        return;
    }

    // ---- Curse type buttons ----
    if(sEvent == EVENT_TYPE_CLICK)
    {
        int nNewCurse = 0;
        if(sElem == EFF_BTN_C1) nNewCurse = EFF_CURSE_ANGUISH;
        if(sElem == EFF_BTN_C2) nNewCurse = EFF_CURSE_WITHER;
        if(sElem == EFF_BTN_C3) nNewCurse = EFF_CURSE_BLINDNESS;
        if(sElem == EFF_BTN_C4) nNewCurse = EFF_CURSE_TORPOR;
        if(nNewCurse > 0)
        {
            SetLocalInt(oPC, EFF_LVAR_SEL_CURSE, nNewCurse);
            EffRefreshCursePanel(oPC, nToken);
            return;
        }
    }

    // ---- Create ----
    if(sEvent == EVENT_TYPE_CLICK && sElem == EFF_BTN_CREATE)
    {
        EffDoCreate(oPC);
        EffFeedTargetList(oPC, nToken);
        EffRefreshCursePanel(oPC, nToken);
        return;
    }

    // ---- Mine row selection ----
    if(sEvent == EVENT_TYPE_CLICK && sElem == EFF_BTN_MINE_ROW)
    {
        json jMine = EffGetMyEffigies(GetObjectUUID(oPC));
        if(nRow < 0 || nRow >= JsonGetLength(jMine)) return;
        json jRow2 = JsonArrayGet(jMine, nRow);
        int nId = JsonGetInt(JsonObjectGet(jRow2, "id"));
        SetLocalInt(oPC, EFF_LVAR_SEL_MINE_ID, nId);
        NuiSetBind(oPC, nToken, EFF_BIND_SMASH_ENA, JsonBool(TRUE));
        NuiSetBind(oPC, nToken, EFF_BIND_MINE_INFO,
            JsonString("Zaznaczono: " + JsonGetString(JsonObjectGet(jRow2, "target_name"))
                + " — " + EffCurseName(JsonGetInt(JsonObjectGet(jRow2, "curse_type")))));
        return;
    }

    // ---- Smash ----
    if(sEvent == EVENT_TYPE_CLICK && sElem == EFF_BTN_SMASH)
    {
        EffDoSmash(oPC);
        EffFeedMyEffigies(oPC, nToken);
        return;
    }

    // ---- Affected row selection ----
    if(sEvent == EVENT_TYPE_CLICK && sElem == EFF_BTN_AFF_ROW)
    {
        string sUuid  = GetObjectUUID(oPC);
        json jDet     = EffGetDetectedAffecting(sUuid);
        if(nRow < 0 || nRow >= JsonGetLength(jDet)) return;
        json jRow3 = JsonArrayGet(jDet, nRow);
        int nId = JsonGetInt(JsonObjectGet(jRow3, "id"));
        SetLocalInt(oPC, EFF_LVAR_SEL_AFF_ID, nId);
        NuiSetBind(oPC, nToken, EFF_BIND_CLEANSE_ENA, JsonBool(TRUE));
        NuiSetBind(oPC, nToken, EFF_BIND_AFF_INFO,
            JsonString("Zaznaczono klątwę od: "
                + JsonGetString(JsonObjectGet(jRow3, "creator_name"))));
        return;
    }

    // ---- Detect ----
    if(sEvent == EVENT_TYPE_CLICK && sElem == EFF_BTN_DETECT)
    {
        EffDoDetect(oPC);
        EffFeedAffectedList(oPC, nToken);
        return;
    }

    // ---- Cleanse ----
    if(sEvent == EVENT_TYPE_CLICK && sElem == EFF_BTN_CLEANSE)
    {
        EffDoCleanse(oPC);
        EffFeedAffectedList(oPC, nToken);
        return;
    }
}

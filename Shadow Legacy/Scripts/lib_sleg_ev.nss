#include "lib_sleg"

void HandleClaimLegacy(object oPC, int nToken)
{
    int nId = GetLocalInt(oPC, SLEG_LVAR_SEL_ID);
    if(nId <= 0)
    {
        SendMessageToPC(oPC, "[Dziedzictwo Cieni] Zaznacz dziedzictwo na liście.");
        return;
    }

    string sCharUuid = GetObjectUUID(oPC);

    if(SlegHasActiveLegacy(sCharUuid))
    {
        SendMessageToPC(oPC,
            "[Dziedzictwo Cieni] Nosisz już jedno dziedzictwo — ciało nie przyjmie kolejnego.");
        return;
    }

    json jRec = SlegGetLegacyById(nId);
    if(JsonGetType(jRec) == JSON_TYPE_NULL) return;

    if(JsonGetInt(JsonObjectGet(jRec, "is_claimed")))
    {
        SendMessageToPC(oPC,
            "[Dziedzictwo Cieni] To dziedzictwo zostało już odebrane.");
        return;
    }

    int nType = JsonGetInt(JsonObjectGet(jRec, "legacy_type"));
    SlegClaimLegacy(nId, sCharUuid);

    // Apply effects immediately
    SlegApplyTypeEffects(oPC, nType);

    string sTypeName = SlegTypeName(nType);
    SendMessageToPC(oPC,
        "[Dziedzictwo Cieni] Przyjmujesz dziedzictwo „" + sTypeName + "".");
    FloatingTextStringOnCreature(
        "Dziedzictwo przeszłości wypełnia twoją krew...", oPC, FALSE);

    SlegFeedDetail(oPC, nToken, nId);
    SlegFeedList(oPC, nToken);
}

// Main event handler — called by NUI engine for all events on SLEG windows.
void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();
    int    nIdx   = NuiGetEventArrayIndex();

    if(nToken != NuiFindWindow(oPC, SLEG_WINDOW)) return;

    if(sEvent == "close")
    {
        DeleteLocalInt(oPC, SLEG_LVAR_SEL_ID);
        return;
    }

    if(sEvent == "click" && sElem == SLEG_BTN_CLAIM)
    {
        HandleClaimLegacy(oPC, nToken);
        return;
    }

    if(sEvent == "mousedown" && sElem == SLEG_BTN_ROW)
    {
        // Identify the clicked row's id from the legacy list
        string sCDKey  = GetPCPublicCDKey(oPC, FALSE);
        json jLegacies = SlegGetLegacies(sCDKey);

        if(nIdx < 0 || nIdx >= JsonGetLength(jLegacies)) return;

        json jRow = JsonArrayGet(jLegacies, nIdx);
        int  nId  = JsonGetInt(JsonObjectGet(jRow, "id"));

        SetLocalInt(oPC, SLEG_LVAR_SEL_ID, nId);
        SlegFeedDetail(oPC, nToken, nId);
        SlegFeedList(oPC, nToken);
        return;
    }
}

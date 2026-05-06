// lib_plg_dm.nss - DM panel (NUI + chat commands jako fallback)
//
// NUI: placeable z OnUsed=test_plg_dm otwiera glowne okno (CreatePlgDmWindow).
// Chat commands (alternatywne):
//   !plg help / list / cure <p> / infect <p> <id> / phase <p> <id> <ph> / reveal <p>

#include "lib_nui"
#include "lib_plg"

// ============================================================
// NUI window constants
// ============================================================

const string PLG_DM_WINDOW    = "PLG_DM_WIN";
const string PLG_DM_EV_SCRIPT = "lib_plg_dm_ev";

// Binds
const string PLG_DM_BIND_INFECTED_NAMES  = "plg_dm_inf_names";  // JsonArray<string>
const string PLG_DM_BIND_INFECTED_INFO   = "plg_dm_inf_info";   // JsonArray<string> (disease + phase)
const string PLG_DM_BIND_INFECTED_TIME   = "plg_dm_inf_time";   // JsonArray<string> (next phase in)
const string PLG_DM_BIND_INFECTED_LEN    = "plg_dm_inf_len";    // JsonInt
const string PLG_DM_BIND_INFECTED_ENC    = "plg_dm_inf_enc";    // JsonArray<bool>
const string PLG_DM_BIND_ONLINE_NAMES    = "plg_dm_onl_names";  // JsonArray<string>
const string PLG_DM_BIND_ONLINE_LEN      = "plg_dm_onl_len";    // JsonInt
const string PLG_DM_BIND_ONLINE_ENC      = "plg_dm_onl_enc";    // JsonArray<bool>
const string PLG_DM_BIND_DEBUG_LBL       = "plg_dm_dbg_lbl";    // JsonString

// Element IDs
const string PLG_DM_BTN_INFECTED_ROW = "plg_dm_inf_row";
const string PLG_DM_BTN_ONLINE_ROW   = "plg_dm_onl_row";
const string PLG_DM_BTN_CURE         = "plg_dm_cure";
const string PLG_DM_BTN_REVEAL       = "plg_dm_reveal";
const string PLG_DM_BTN_PHASE_UP     = "plg_dm_phase_up";
const string PLG_DM_BTN_PHASE_DOWN   = "plg_dm_phase_dn";
const string PLG_DM_BTN_INF_PLAGA    = "plg_dm_inf_plaga";
const string PLG_DM_BTN_INF_KREW     = "plg_dm_inf_krew";
const string PLG_DM_BTN_INF_BAGNA    = "plg_dm_inf_bagna";
const string PLG_DM_BTN_INF_NKR      = "plg_dm_inf_nkr";
const string PLG_DM_BTN_DEBUG        = "plg_dm_debug";
const string PLG_DM_BTN_REFRESH      = "plg_dm_refresh";
const string PLG_DM_BTN_CLOSE        = "plg_dm_close";

// Tab IDs / swap group
const string PLG_DM_TAB_INFECTED = "plg_dm_tab_inf";
const string PLG_DM_TAB_ONLINE   = "plg_dm_tab_onl";
const string PLG_DM_TAB_STATS    = "plg_dm_tab_stats";
const string PLG_DM_GROUP_SWAP   = "plg_dm_swap";

// View IDs (state)
const int PLG_DM_VIEW_INFECTED = 0;
const int PLG_DM_VIEW_ONLINE   = 1;
const int PLG_DM_VIEW_STATS    = 2;
const string PLG_DM_LVAR_VIEW = "PLG_DM_VIEW";

// Tab encouraged binds
const string PLG_DM_BIND_TAB_INF_ENC   = "plg_dm_tab_inf_enc";
const string PLG_DM_BIND_TAB_ONL_ENC   = "plg_dm_tab_onl_enc";
const string PLG_DM_BIND_TAB_STATS_ENC = "plg_dm_tab_stats_enc";

// Stats view binds (label-value rows)
const string PLG_DM_BIND_S_ACTIVE       = "plg_s_active";
const string PLG_DM_BIND_S_MULTI        = "plg_s_multi";
const string PLG_DM_BIND_S_CURED24      = "plg_s_cured24";
const string PLG_DM_BIND_S_DEATHS7      = "plg_s_deaths7";
const string PLG_DM_BIND_S_CONTAG7      = "plg_s_contag7";
const string PLG_DM_BIND_S_CONTRACTS30  = "plg_s_contr30";
const string PLG_DM_BIND_S_CURES30      = "plg_s_cures30";
const string PLG_DM_BIND_S_RECOVERY     = "plg_s_recovery";
const string PLG_DM_BIND_S_TOP_DISEASE  = "plg_s_topdis";
const string PLG_DM_BIND_S_TOP_AREA     = "plg_s_toparea";
const string PLG_DM_BIND_S_AVG_INC_CRIT = "plg_s_avgcrit";
const string PLG_DM_BIND_S_BF_INC       = "plg_s_bfinc";
const string PLG_DM_BIND_S_BF_MILD      = "plg_s_bfmild";
const string PLG_DM_BIND_S_BF_SEV       = "plg_s_bfsev";
const string PLG_DM_BIND_S_BF_CRIT      = "plg_s_bfcrit";
const string PLG_DM_BIND_S_LENS         = "plg_s_lens";
const string PLG_DM_BIND_S_FA_SUCC      = "plg_s_fasucc";
const string PLG_DM_BIND_S_FA_FAIL      = "plg_s_fafail";
const string PLG_DM_BIND_S_WRONG_CURE   = "plg_s_wrongc";

// Selection state (LVAR na DM)
const string PLG_DM_LVAR_SEL_INFECTED_UUID = "PLG_DM_SEL_INF_UUID";
const string PLG_DM_LVAR_SEL_INFECTED_DID  = "PLG_DM_SEL_INF_DID";
const string PLG_DM_LVAR_SEL_ONLINE_UUID   = "PLG_DM_SEL_ONL_UUID";
const string PLG_DM_LVAR_INFECTED_LIST_JSON = "PLG_DM_INF_JSON"; // cache jList do lookup
const string PLG_DM_LVAR_ONLINE_LIST_JSON   = "PLG_DM_ONL_JSON";

// Window dimensions
const float PLG_DM_W = 620.0;
const float PLG_DM_H = 550.0;

// Shared list cell height (both Infected and Online lists use the same).
const float PLG_DM_LIST_ROW_H = 26.0;

// Shared view content width (Infected/Online lists + Stats group).
const float PLG_DM_VIEW_W = 570.0;

// Forward declarations
void CreatePlgDmWindow(object oDm);
void FeedPlgDmWindow(object oDm, int nToken);
json PlgDmFindOnlinePcByUuid(string sUuid);

// ============================================================
// Helpers
// ============================================================

// Znajdz online PC po nazwie (substring match, case-insensitive).
// Zwraca pierwszy match. Jezeli wiele, ustawia GetLocalInt(GetModule, "PLG_DM_AMBIGUOUS", >1).
object PlgDmFindPlayer(string sName)
{
    if(sName == "") return OBJECT_INVALID;
    string sLower = GetStringLowerCase(sName);
    int nMatches = 0;
    object oFirst = OBJECT_INVALID;

    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(GetIsPC(oPC) && !GetIsDM(oPC))
        {
            string sPcName = GetStringLowerCase(GetName(oPC));
            if(FindSubString(sPcName, sLower) >= 0)
            {
                if(nMatches == 0) oFirst = oPC;
                nMatches++;
            }
        }
        oPC = GetNextPC();
    }

    SetLocalInt(GetModule(), "PLG_DM_AMBIGUOUS", nMatches);
    return oFirst;
}

// Tokenizer - split na spacje. Zwraca JsonArray of strings.
json PlgDmTokenize(string sInput)
{
    json jTokens = JsonArray();
    string sCurrent = "";
    int nLen = GetStringLength(sInput);
    int i;
    for(i = 0; i < nLen; i++)
    {
        string sCh = GetSubString(sInput, i, 1);
        if(sCh == " " || sCh == "\t")
        {
            if(sCurrent != "")
            {
                jTokens = JsonArrayInsert(jTokens, JsonString(sCurrent));
                sCurrent = "";
            }
        }
        else
        {
            sCurrent += sCh;
        }
    }
    if(sCurrent != "")
        jTokens = JsonArrayInsert(jTokens, JsonString(sCurrent));
    return jTokens;
}

string PlgDmGetToken(json jTokens, int nIdx)
{
    if(nIdx < 0 || nIdx >= JsonGetLength(jTokens)) return "";
    return JsonGetString(JsonArrayGet(jTokens, nIdx));
}

// ============================================================
// Command handlers
// ============================================================

void PlgDmCmdHelp(object oDm)
{
    SendMessageToPC(oDm, "[Plague DM] Commands:");
    SendMessageToPC(oDm, "  !plg help                          - this list");
    SendMessageToPC(oDm, "  !plg list                          - all infected characters");
    SendMessageToPC(oDm, "  !plg cure <player>                 - cure all diseases on player");
    SendMessageToPC(oDm, "  !plg infect <player> <id 0-3>      - infect player (0=Plague, 1=Blood, 2=Swamp, 3=Necro)");
    SendMessageToPC(oDm, "  !plg phase <player> <id> <phase>   - set phase (1=incub, 2=mild, 3=severe, 4=crit)");
    SendMessageToPC(oDm, "  !plg reveal <player>               - reveal all diseases on player");
}

void PlgDmCmdList(object oDm)
{
    json jInfected = PlgListAllInfected();
    int nLen = JsonGetLength(jInfected);
    if(nLen == 0)
    {
        SendMessageToPC(oDm, "[Plague DM] Nobody is currently infected.");
        return;
    }

    SendMessageToPC(oDm, "[Plague DM] Infected list (" + IntToString(nLen) + "):");
    int i;
    for(i = 0; i < nLen; i++)
    {
        json jRec = JsonArrayGet(jInfected, i);
        string sUuid = JsonGetString(JsonObjectGet(jRec, "uuid"));
        int nDid     = JsonGetInt(JsonObjectGet(jRec, "disease_id"));
        int nPhase   = JsonGetInt(JsonObjectGet(jRec, "phase"));

        // Znajdz online PC po UUID (offline = "[offline]")
        string sCharName = "[offline]";
        object oPC = GetFirstPC();
        while(GetIsObjectValid(oPC))
        {
            if(GetObjectUUID(oPC) == sUuid)
            {
                sCharName = GetName(oPC);
                break;
            }
            oPC = GetNextPC();
        }

        SendMessageToPC(oDm, "  " + sCharName
            + " - " + PlgDiseaseName(nDid)
            + " (" + PlgPhaseName(nPhase) + ")");
    }
}

void PlgDmCmdCure(object oDm, string sPlayerName)
{
    object oTarget = PlgDmFindPlayer(sPlayerName);
    int nMatches = GetLocalInt(GetModule(), "PLG_DM_AMBIGUOUS");

    if(nMatches == 0)
    {
        SendMessageToPC(oDm, "[Plague DM] Player not found: " + sPlayerName);
        return;
    }
    if(nMatches > 1)
    {
        SendMessageToPC(oDm, "[Plague DM] Ambiguous name (" + IntToString(nMatches)
            + " matches). Be more specific.");
        return;
    }

    int nCured = 0;
    int nDiseaseId;
    for(nDiseaseId = 0; nDiseaseId < PLG_DIS_COUNT; nDiseaseId++)
    {
        if(GetLocalInt(oTarget, PLG_LVAR_HAS + IntToString(nDiseaseId)))
        {
            PlgLogDmAction(oDm, oTarget, nDiseaseId, "cure");
            PlgCureAndNotify(oTarget, nDiseaseId);
            nCured++;
        }
    }

    if(nCured == 0)
    {
        SendMessageToPC(oDm, "[Plague DM] " + GetName(oTarget) + " has no diseases.");
    }
    else
    {
        SendMessageToPC(oDm, "[Plague DM] Cured " + GetName(oTarget)
            + " (" + IntToString(nCured) + " disease(s)).");
    }
}

void PlgDmCmdInfect(object oDm, string sPlayerName, string sDiseaseIdStr)
{
    object oTarget = PlgDmFindPlayer(sPlayerName);
    int nMatches = GetLocalInt(GetModule(), "PLG_DM_AMBIGUOUS");

    if(nMatches == 0)
    {
        SendMessageToPC(oDm, "[Plague DM] Player not found: " + sPlayerName);
        return;
    }
    if(nMatches > 1)
    {
        SendMessageToPC(oDm, "[Plague DM] Ambiguous name.");
        return;
    }

    int nDiseaseId = StringToInt(sDiseaseIdStr);
    if(nDiseaseId < 0 || nDiseaseId >= PLG_DIS_COUNT)
    {
        SendMessageToPC(oDm, "[Plague DM] Invalid disease ID (0-3).");
        return;
    }

    if(PlgHasDisease(oTarget, nDiseaseId))
    {
        SendMessageToPC(oDm, "[Plague DM] " + GetName(oTarget) + " already has "
            + PlgDiseaseName(nDiseaseId) + ".");
        return;
    }

    PlgLogDmAction(oDm, oTarget, nDiseaseId, "infect");
    PlgContractAndNotify(oTarget, nDiseaseId);
    SendMessageToPC(oDm, "[Plague DM] Infected " + GetName(oTarget) + " - "
        + PlgDiseaseName(nDiseaseId) + ".");
}

void PlgDmCmdPhase(object oDm, string sPlayerName, string sDiseaseIdStr, string sPhaseStr)
{
    object oTarget = PlgDmFindPlayer(sPlayerName);
    int nMatches = GetLocalInt(GetModule(), "PLG_DM_AMBIGUOUS");

    if(nMatches == 0 || nMatches > 1)
    {
        SendMessageToPC(oDm, "[Plague DM] Invalid player name.");
        return;
    }

    int nDiseaseId = StringToInt(sDiseaseIdStr);
    int nPhase = StringToInt(sPhaseStr);
    if(nDiseaseId < 0 || nDiseaseId >= PLG_DIS_COUNT)
    {
        SendMessageToPC(oDm, "[Plague DM] Invalid disease ID (0-3).");
        return;
    }
    if(nPhase < PLG_PHASE_INCUBATION || nPhase > PLG_PHASE_CRITICAL)
    {
        SendMessageToPC(oDm, "[Plague DM] Invalid phase (1-4).");
        return;
    }
    if(!PlgHasDisease(oTarget, nDiseaseId))
    {
        SendMessageToPC(oDm, "[Plague DM] " + GetName(oTarget) + " does not have that disease.");
        return;
    }

    int nNow = PlgUnixNow();
    int nInterval = (nPhase < PLG_PHASE_CRITICAL)
        ? PlgPhaseInterval(nDiseaseId, nPhase) : 0;
    int nNewEnd = (nInterval > 0) ? nNow + nInterval : 0;

    PlgSetPhase(oTarget, nDiseaseId, nPhase, nNow, nNewEnd);
    PlgApplyEffectsForDisease(oTarget, nDiseaseId, nPhase);
    PlgLogDmAction(oDm, oTarget, nDiseaseId, "phase_set_" + IntToString(nPhase));

    SendMessageToPC(oDm, "[Plague DM] Set phase " + PlgPhaseName(nPhase)
        + " for " + GetName(oTarget) + " (" + PlgDiseaseName(nDiseaseId) + ").");
}

void PlgDmCmdReveal(object oDm, string sPlayerName)
{
    object oTarget = PlgDmFindPlayer(sPlayerName);
    int nMatches = GetLocalInt(GetModule(), "PLG_DM_AMBIGUOUS");

    if(nMatches == 0 || nMatches > 1)
    {
        SendMessageToPC(oDm, "[Plague DM] Invalid player name.");
        return;
    }

    int nRevealed = 0;
    int nDiseaseId;
    for(nDiseaseId = 0; nDiseaseId < PLG_DIS_COUNT; nDiseaseId++)
    {
        if(GetLocalInt(oTarget, PLG_LVAR_HAS + IntToString(nDiseaseId))
           && !PlgIsDiagnosed(oTarget, nDiseaseId))
        {
            SetLocalInt(oTarget, PLG_LVAR_DIAGNOSED + IntToString(nDiseaseId), TRUE);
            PlgSetDiagnosed(oTarget, nDiseaseId, TRUE);
            PlgLogDmAction(oDm, oTarget, nDiseaseId, "reveal");
            nRevealed++;
        }
    }

    SendMessageToPC(oDm, "[Plague DM] Revealed " + IntToString(nRevealed)
        + " disease(s) for " + GetName(oTarget) + ".");
    if(nRevealed > 0)
        SendMessageToPC(oTarget,
            "[Plague] A DM revealed the nature of your diseases. Check your status.");
}

// ============================================================
// Main dispatcher - wywoluj z OnPlayerChat handler.
// Returns TRUE jezeli komenda zostala przetworzona (niech chat handler suppressuje wiadomosc).
// ============================================================

int PlgDmHandleChatCommand(object oDm, string sChatMsg)
{
    if(!GetIsDM(oDm)) return FALSE;
    if(GetStringLeft(sChatMsg, 5) != "!plg ") return FALSE;

    // Strip "!plg " prefix
    string sCmd = GetSubString(sChatMsg, 5, GetStringLength(sChatMsg) - 5);
    json jTokens = PlgDmTokenize(sCmd);

    if(JsonGetLength(jTokens) == 0)
    {
        PlgDmCmdHelp(oDm);
        return TRUE;
    }

    string sCommand = PlgDmGetToken(jTokens, 0);
    sCommand = GetStringLowerCase(sCommand);

    if(sCommand == "help")
    {
        PlgDmCmdHelp(oDm);
    }
    else if(sCommand == "list")
    {
        PlgDmCmdList(oDm);
    }
    else if(sCommand == "cure")
    {
        PlgDmCmdCure(oDm, PlgDmGetToken(jTokens, 1));
    }
    else if(sCommand == "infect")
    {
        PlgDmCmdInfect(oDm, PlgDmGetToken(jTokens, 1), PlgDmGetToken(jTokens, 2));
    }
    else if(sCommand == "phase")
    {
        PlgDmCmdPhase(oDm,
            PlgDmGetToken(jTokens, 1),
            PlgDmGetToken(jTokens, 2),
            PlgDmGetToken(jTokens, 3));
    }
    else if(sCommand == "reveal")
    {
        PlgDmCmdReveal(oDm, PlgDmGetToken(jTokens, 1));
    }
    else
    {
        SendMessageToPC(oDm, "[Plague DM] Unknown command: " + sCommand
            + ". Type '!plg help' for help.");
    }
    return TRUE;
}

// ============================================================
// NUI Panel
// ============================================================

// Helper - znajdz online PC po UUID (dla list lookups).
json PlgDmFindOnlinePcByUuid(string sUuid)
{
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(GetObjectUUID(oPC) == sUuid) return JsonString(GetName(oPC));
        oPC = GetNextPC();
    }
    return JsonString("[offline]");
}

// Buduje JsonArray<json> wszystkich infected (z online + offline na bazie SQL).
// Kazdy element: {uuid, char_name, disease_id, phase}
json PlgDmBuildInfectedList()
{
    json jInfected = PlgListAllInfected(); // z sql_plg.nss
    int nLen = JsonGetLength(jInfected);

    json jResult = JsonArray();
    int i;
    for(i = 0; i < nLen; i++)
    {
        json jRec = JsonArrayGet(jInfected, i);
        string sUuid = JsonGetString(JsonObjectGet(jRec, "uuid"));
        json jName = PlgDmFindOnlinePcByUuid(sUuid);
        jRec = JsonObjectSet(jRec, "char_name", jName);
        jResult = JsonArrayInsert(jResult, jRec);
    }
    return jResult;
}

// Buduje JsonArray<json> wszystkich PC online (potencjalne targety do infect).
// Kazdy element: {uuid, char_name}
json PlgDmBuildOnlineList()
{
    json jResult = JsonArray();
    object oPC = GetFirstPC();
    while(GetIsObjectValid(oPC))
    {
        if(GetIsPC(oPC) && !GetIsDM(oPC))
        {
            json j = JsonObject();
            j = JsonObjectSet(j, "uuid", JsonString(GetObjectUUID(oPC)));
            j = JsonObjectSet(j, "char_name", JsonString(GetName(oPC)));
            jResult = JsonArrayInsert(jResult, j);
        }
        oPC = GetNextPC();
    }
    return jResult;
}

// View 1: infected list + actions (cure, reveal, phase up/down)
json PlgDmBuildViewInfected()
{
    float fListH = 380.0;
    float fBtnH = 28.0;

    json jNameLbl = NuiLabel(NuiBind(PLG_DM_BIND_INFECTED_NAMES),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jNameLbl = NuiWidth(jNameLbl, 170.0);

    json jInfoLbl = NuiLabel(NuiBind(PLG_DM_BIND_INFECTED_INFO),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jInfoLbl = NuiWidth(jInfoLbl, 250.0);

    json jTimeLbl = NuiLabel(NuiBind(PLG_DM_BIND_INFECTED_TIME),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jTimeLbl = NuiWidth(jTimeLbl, 130.0);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jNameLbl);
    jRow = JsonArrayInsert(jRow, jInfoLbl);
    jRow = JsonArrayInsert(jRow, jTimeLbl);

    json jCell = NuiGroup(NuiRow(jRow), TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, PLG_DM_BTN_INFECTED_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(PLG_DM_BIND_INFECTED_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(),
        NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(PLG_DM_BIND_INFECTED_LEN), PLG_DM_LIST_ROW_H);
    jList = NuiHeight(jList, fListH);
    jList = NuiWidth(jList, PLG_DM_VIEW_W);

    float fActionBtnW = 140.0;
    json jBtnCure = NuiId(NuiButton(JsonString("Cure")), PLG_DM_BTN_CURE);
    jBtnCure = NuiHeight(jBtnCure, fBtnH);
    jBtnCure = NuiWidth(jBtnCure, fActionBtnW);
    json jBtnReveal = NuiId(NuiButton(JsonString("Reveal")), PLG_DM_BTN_REVEAL);
    jBtnReveal = NuiHeight(jBtnReveal, fBtnH);
    jBtnReveal = NuiWidth(jBtnReveal, fActionBtnW);
    json jBtnPhUp = NuiId(NuiButton(JsonString("Phase+")), PLG_DM_BTN_PHASE_UP);
    jBtnPhUp = NuiHeight(jBtnPhUp, fBtnH);
    jBtnPhUp = NuiWidth(jBtnPhUp, fActionBtnW);
    json jBtnPhDn = NuiId(NuiButton(JsonString("Phase-")), PLG_DM_BTN_PHASE_DOWN);
    jBtnPhDn = NuiHeight(jBtnPhDn, fBtnH);
    jBtnPhDn = NuiWidth(jBtnPhDn, fActionBtnW);

    json jActionRow = JsonArray();
    jActionRow = JsonArrayInsert(jActionRow, jBtnCure);
    jActionRow = JsonArrayInsert(jActionRow, jBtnReveal);
    jActionRow = JsonArrayInsert(jActionRow, jBtnPhUp);
    jActionRow = JsonArrayInsert(jActionRow, jBtnPhDn);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, NuiRow(jActionRow));
    return NuiCol(jCol);
}

// View 2: online players list + infect buttons (4 diseases)
json PlgDmBuildViewOnline()
{
    float fListH = 380.0;
    float fBtnH = 28.0;

    json jNameLbl = NuiLabel(NuiBind(PLG_DM_BIND_ONLINE_NAMES),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    json jCell = NuiGroup(NuiRow(JsonArrayInsert(JsonArray(), jNameLbl)),
        TRUE, NUI_SCROLLBARS_NONE);
    jCell = NuiId(jCell, PLG_DM_BTN_ONLINE_ROW);
    jCell = NuiEncouraged(jCell, NuiBind(PLG_DM_BIND_ONLINE_ENC));

    json jTmpl = JsonArrayInsert(JsonArray(),
        NuiListTemplateCell(jCell, 0.0, TRUE));
    json jList = NuiList(jTmpl, NuiBind(PLG_DM_BIND_ONLINE_LEN), PLG_DM_LIST_ROW_H);
    jList = NuiHeight(jList, fListH);
    jList = NuiWidth(jList, PLG_DM_VIEW_W);

    float fInfectBtnW = 140.0;
    json jBtnP = NuiId(NuiButton(JsonString("Plague")), PLG_DM_BTN_INF_PLAGA);
    jBtnP = NuiHeight(jBtnP, fBtnH);
    jBtnP = NuiWidth(jBtnP, fInfectBtnW);
    json jBtnK = NuiId(NuiButton(JsonString("Blood")), PLG_DM_BTN_INF_KREW);
    jBtnK = NuiHeight(jBtnK, fBtnH);
    jBtnK = NuiWidth(jBtnK, fInfectBtnW);
    json jBtnB = NuiId(NuiButton(JsonString("Swamp")), PLG_DM_BTN_INF_BAGNA);
    jBtnB = NuiHeight(jBtnB, fBtnH);
    jBtnB = NuiWidth(jBtnB, fInfectBtnW);
    json jBtnN = NuiId(NuiButton(JsonString("Necro")), PLG_DM_BTN_INF_NKR);
    jBtnN = NuiHeight(jBtnN, fBtnH);
    jBtnN = NuiWidth(jBtnN, fInfectBtnW);

    json jInfectRow = JsonArray();
    jInfectRow = JsonArrayInsert(jInfectRow, jBtnP);
    jInfectRow = JsonArrayInsert(jInfectRow, jBtnK);
    jInfectRow = JsonArrayInsert(jInfectRow, jBtnB);
    jInfectRow = JsonArrayInsert(jInfectRow, jBtnN);

    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, jList);
    jCol = JsonArrayInsert(jCol, NuiRow(jInfectRow));
    return NuiCol(jCol);
}

// Helper: builds a single (label name, label value) row.
// NOTE: height is set on cell widgets only - NuiHeight on NuiRow inside a
// scrollable NuiGroup breaks the layout constraint ("constraint can not
// be satisfied" error).
json PlgDmStatRow(string sName, string sBindValue)
{
    float fLabelW = 290.0;
    float fValueW = 250.0;
    float fRowH   = 22.0;

    json jName = NuiLabel(JsonString(sName),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jName = NuiWidth(jName, fLabelW);
    jName = NuiHeight(jName, fRowH);

    json jVal = NuiLabel(NuiBind(sBindValue),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jVal = NuiWidth(jVal, fValueW);
    jVal = NuiHeight(jVal, fRowH);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jName);
    jRow = JsonArrayInsert(jRow, jVal);
    return NuiRow(jRow);
}

// Helper: builds a section header row.
json PlgDmStatHeader(string sTitle)
{
    float fRowH = 22.0;
    json jLbl = NuiLabel(JsonString("=== " + sTitle + " ==="),
        JsonInt(NUI_HALIGN_LEFT), JsonInt(NUI_VALIGN_MIDDLE));
    jLbl = NuiWidth(jLbl, 540.0);
    jLbl = NuiHeight(jLbl, fRowH);

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, jLbl);
    return NuiRow(jRow);
}

// View 3: telemetry / statistics dashboard (read-only).
// Layout: scrollable column of label-value rows organized into sections.
json PlgDmBuildViewStats()
{
    json jCol = JsonArray();

    // ===== Current state =====
    jCol = JsonArrayInsert(jCol, PlgDmStatHeader("CURRENT STATE"));
    jCol = JsonArrayInsert(jCol, PlgDmStatRow("Active diseases on server:",
        PLG_DM_BIND_S_ACTIVE));
    jCol = JsonArrayInsert(jCol, PlgDmStatRow("Players with 2+ diseases:",
        PLG_DM_BIND_S_MULTI));

    // ===== Recent activity =====
    jCol = JsonArrayInsert(jCol, PlgDmStatHeader("RECENT ACTIVITY"));
    jCol = JsonArrayInsert(jCol, PlgDmStatRow("Cured (last 24h):",
        PLG_DM_BIND_S_CURED24));
    jCol = JsonArrayInsert(jCol, PlgDmStatRow("Deaths from disease (7d):",
        PLG_DM_BIND_S_DEATHS7));
    jCol = JsonArrayInsert(jCol, PlgDmStatRow("Contagion spreads (7d):",
        PLG_DM_BIND_S_CONTAG7));

    // ===== Last 30 days summary =====
    jCol = JsonArrayInsert(jCol, PlgDmStatHeader("LAST 30 DAYS"));
    jCol = JsonArrayInsert(jCol, PlgDmStatRow("Total contracts:",
        PLG_DM_BIND_S_CONTRACTS30));
    jCol = JsonArrayInsert(jCol, PlgDmStatRow("Total cures:",
        PLG_DM_BIND_S_CURES30));
    jCol = JsonArrayInsert(jCol, PlgDmStatRow("Recovery rate:",
        PLG_DM_BIND_S_RECOVERY));
    jCol = JsonArrayInsert(jCol, PlgDmStatRow("Top disease:",
        PLG_DM_BIND_S_TOP_DISEASE));
    jCol = JsonArrayInsert(jCol, PlgDmStatRow("Top infection area:",
        PLG_DM_BIND_S_TOP_AREA));
    jCol = JsonArrayInsert(jCol, PlgDmStatRow("Avg time incubation->critical:",
        PLG_DM_BIND_S_AVG_INC_CRIT));

    // ===== Body fight win rate =====
    jCol = JsonArrayInsert(jCol, PlgDmStatHeader("BODY FIGHT WIN RATE"));
    jCol = JsonArrayInsert(jCol, PlgDmStatRow("Incubation:",
        PLG_DM_BIND_S_BF_INC));
    jCol = JsonArrayInsert(jCol, PlgDmStatRow("Mild Symptoms:",
        PLG_DM_BIND_S_BF_MILD));
    jCol = JsonArrayInsert(jCol, PlgDmStatRow("Sickness:",
        PLG_DM_BIND_S_BF_SEV));
    jCol = JsonArrayInsert(jCol, PlgDmStatRow("Critical:",
        PLG_DM_BIND_S_BF_CRIT));

    // ===== Healing economy =====
    jCol = JsonArrayInsert(jCol, PlgDmStatHeader("HEALING ECONOMY (30d)"));
    jCol = JsonArrayInsert(jCol, PlgDmStatRow("Diagnostic lens uses:",
        PLG_DM_BIND_S_LENS));
    jCol = JsonArrayInsert(jCol, PlgDmStatRow("First aid successes:",
        PLG_DM_BIND_S_FA_SUCC));
    jCol = JsonArrayInsert(jCol, PlgDmStatRow("First aid failures:",
        PLG_DM_BIND_S_FA_FAIL));
    jCol = JsonArrayInsert(jCol, PlgDmStatRow("Wrong-rank cure attempts:",
        PLG_DM_BIND_S_WRONG_CURE));

    // Wrap entire column in scrollable group (auto-scroll if content overflows).
    // Stats view has no button row (unlike Infected/Online), so we use the full
    // swap group height (416 = 380 list + 28 button row + 8 padding from other views).
    // Width must leave room for vertical scrollbar inside the group, otherwise
    // a horizontal scrollbar appears.
    json jGroup = NuiGroup(NuiCol(jCol), TRUE, NUI_SCROLLBARS_AUTO);
    jGroup = NuiHeight(jGroup, 416.0);
    jGroup = NuiWidth(jGroup, PLG_DM_VIEW_W);

    json jOuter = JsonArray();
    jOuter = JsonArrayInsert(jOuter, jGroup);
    return NuiCol(jOuter);
}

// Format seconds as "Xh Ym" or "Ys" or "-" for no data.
string PlgDmFormatDuration(int nSec)
{
    if(nSec <= 0) return "-";
    if(nSec < 60) return IntToString(nSec) + "s";
    int nH = nSec / 3600;
    int nM = (nSec % 3600) / 60;
    if(nH > 0) return IntToString(nH) + "h " + IntToString(nM) + "m";
    return IntToString(nM) + "m";
}

// Glowny layout: tabs + swap group + bottom controls
json PlgDmBuildLayout()
{
    float fBtnH = 28.0;
    float fGap = 4.0;

    // ===== Tabs =====
    float fTabW = 195.0;
    json jTabInf = NuiButton(JsonString("Infected"));
    jTabInf = NuiId(jTabInf, PLG_DM_TAB_INFECTED);
    jTabInf = NuiHeight(jTabInf, fBtnH);
    jTabInf = NuiWidth(jTabInf, fTabW);
    jTabInf = NuiEncouraged(jTabInf, NuiBind(PLG_DM_BIND_TAB_INF_ENC));

    json jTabOnl = NuiButton(JsonString("Infect"));
    jTabOnl = NuiId(jTabOnl, PLG_DM_TAB_ONLINE);
    jTabOnl = NuiHeight(jTabOnl, fBtnH);
    jTabOnl = NuiWidth(jTabOnl, fTabW);
    jTabOnl = NuiEncouraged(jTabOnl, NuiBind(PLG_DM_BIND_TAB_ONL_ENC));

    json jTabStats = NuiButton(JsonString("Stats"));
    jTabStats = NuiId(jTabStats, PLG_DM_TAB_STATS);
    jTabStats = NuiHeight(jTabStats, fBtnH);
    jTabStats = NuiWidth(jTabStats, fTabW);
    jTabStats = NuiEncouraged(jTabStats, NuiBind(PLG_DM_BIND_TAB_STATS_ENC));

    json jTabRow = JsonArray();
    jTabRow = JsonArrayInsert(jTabRow, jTabInf);
    jTabRow = JsonArrayInsert(jTabRow, jTabOnl);
    jTabRow = JsonArrayInsert(jTabRow, jTabStats);

    // ===== Swap group (default = view infected) =====
    // Explicit height = list (380) + button row (28) + padding (8) = 416.
    // Without it the list would greedily fill the column and overlap buttons.
    json jSwapGroup = NuiGroup(PlgDmBuildViewInfected(), FALSE, NUI_SCROLLBARS_NONE);
    jSwapGroup = NuiId(jSwapGroup, PLG_DM_GROUP_SWAP);
    jSwapGroup = NuiHeight(jSwapGroup, 416.0);

    // ===== Bottom controls =====
    json jBtnDebug = NuiButton(NuiBind(PLG_DM_BIND_DEBUG_LBL));
    jBtnDebug = NuiId(jBtnDebug, PLG_DM_BTN_DEBUG);
    jBtnDebug = NuiHeight(jBtnDebug, fBtnH);
    jBtnDebug = NuiWidth(jBtnDebug, 160.0);

    json jBtnRefresh = NuiId(NuiButton(JsonString("Refresh")), PLG_DM_BTN_REFRESH);
    jBtnRefresh = NuiHeight(jBtnRefresh, fBtnH);
    jBtnRefresh = NuiWidth(jBtnRefresh, 100.0);

    json jBtnClose = NuiId(NuiButton(JsonString("Close")), PLG_DM_BTN_CLOSE);
    jBtnClose = NuiHeight(jBtnClose, fBtnH);
    jBtnClose = NuiWidth(jBtnClose, 100.0);

    json jBottomRow = JsonArray();
    jBottomRow = JsonArrayInsert(jBottomRow, jBtnDebug);
    jBottomRow = JsonArrayInsert(jBottomRow, NuiSpacer());
    jBottomRow = JsonArrayInsert(jBottomRow, jBtnRefresh);
    jBottomRow = JsonArrayInsert(jBottomRow, jBtnClose);

    // ===== Assemble =====
    json jCol = JsonArray();
    jCol = JsonArrayInsert(jCol, NuiRow(jTabRow));
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), fGap));
    jCol = JsonArrayInsert(jCol, jSwapGroup);
    jCol = JsonArrayInsert(jCol, NuiHeight(NuiSpacer(), fGap));
    jCol = JsonArrayInsert(jCol, NuiRow(jBottomRow));
    return NuiCol(jCol);
}

// Swap helpers
void PlgDmSwapToInfected(object oDm, int nToken)
{
    SetLocalInt(oDm, PLG_DM_LVAR_VIEW, PLG_DM_VIEW_INFECTED);
    NuiSetGroupLayout(oDm, nToken, PLG_DM_GROUP_SWAP, PlgDmBuildViewInfected());
}

void PlgDmSwapToOnline(object oDm, int nToken)
{
    SetLocalInt(oDm, PLG_DM_LVAR_VIEW, PLG_DM_VIEW_ONLINE);
    NuiSetGroupLayout(oDm, nToken, PLG_DM_GROUP_SWAP, PlgDmBuildViewOnline());
}

void PlgDmSwapToStats(object oDm, int nToken)
{
    SetLocalInt(oDm, PLG_DM_LVAR_VIEW, PLG_DM_VIEW_STATS);
    NuiSetGroupLayout(oDm, nToken, PLG_DM_GROUP_SWAP, PlgDmBuildViewStats());
}


// Wypelnia bindy aktualnymi danymi.
void FeedPlgDmWindow(object oDm, int nToken)
{
    // ===== Infected list =====
    json jInfected = PlgDmBuildInfectedList();
    int nInfLen = JsonGetLength(jInfected);

    json jInfNames = JsonArray();
    json jInfInfo  = JsonArray();
    json jInfTime  = JsonArray();
    json jInfEnc   = JsonArray();

    string sSelInfUuid = GetLocalString(oDm, PLG_DM_LVAR_SEL_INFECTED_UUID);
    int    nSelInfDid  = GetLocalInt(oDm, PLG_DM_LVAR_SEL_INFECTED_DID);
    int    nNow        = PlgUnixNow();

    int i;
    for(i = 0; i < nInfLen; i++)
    {
        json jRec = JsonArrayGet(jInfected, i);
        string sUuid = JsonGetString(JsonObjectGet(jRec, "uuid"));
        string sName = JsonGetString(JsonObjectGet(jRec, "char_name"));
        int    nDid  = JsonGetInt(JsonObjectGet(jRec, "disease_id"));
        int    nPh   = JsonGetInt(JsonObjectGet(jRec, "phase"));
        int    nPEnd = JsonGetInt(JsonObjectGet(jRec, "phase_end"));

        jInfNames = JsonArrayInsert(jInfNames, JsonString(sName));
        jInfInfo  = JsonArrayInsert(jInfInfo,
            JsonString(PlgDiseaseName(nDid) + " (" + PlgPhaseName(nPh) + ")"));

        // Time to next phase. Critical = terminal. Offline = unknown
        // (player may be in safe area / disease frozen until login).
        string sTime;
        if(sName == "[offline]")
        {
            sTime = "offline";
        }
        else if(nPh >= PLG_PHASE_CRITICAL)
        {
            sTime = "terminal";
        }
        else if(nPEnd <= 0)
        {
            sTime = "-";
        }
        else
        {
            int nRemain = nPEnd - nNow;
            if(nRemain < 0) nRemain = 0;
            sTime = PlgDmFormatDuration(nRemain);
        }
        jInfTime = JsonArrayInsert(jInfTime, JsonString(sTime));

        int bSel = (sUuid == sSelInfUuid && nDid == nSelInfDid);
        jInfEnc = JsonArrayInsert(jInfEnc, JsonBool(bSel));
    }

    NuiSetBind(oDm, nToken, PLG_DM_BIND_INFECTED_NAMES, jInfNames);
    NuiSetBind(oDm, nToken, PLG_DM_BIND_INFECTED_INFO, jInfInfo);
    NuiSetBind(oDm, nToken, PLG_DM_BIND_INFECTED_TIME, jInfTime);
    NuiSetBind(oDm, nToken, PLG_DM_BIND_INFECTED_LEN, JsonInt(nInfLen));
    NuiSetBind(oDm, nToken, PLG_DM_BIND_INFECTED_ENC, jInfEnc);

    // Cache do lookup w event handler
    SetLocalJson(oDm, PLG_DM_LVAR_INFECTED_LIST_JSON, jInfected);

    // ===== Online list =====
    json jOnline = PlgDmBuildOnlineList();
    int nOnlLen = JsonGetLength(jOnline);

    json jOnlNames = JsonArray();
    json jOnlEnc   = JsonArray();
    string sSelOnlUuid = GetLocalString(oDm, PLG_DM_LVAR_SEL_ONLINE_UUID);

    int j;
    for(j = 0; j < nOnlLen; j++)
    {
        json jRec = JsonArrayGet(jOnline, j);
        string sUuid = JsonGetString(JsonObjectGet(jRec, "uuid"));
        string sName = JsonGetString(JsonObjectGet(jRec, "char_name"));

        jOnlNames = JsonArrayInsert(jOnlNames, JsonString(sName));
        jOnlEnc = JsonArrayInsert(jOnlEnc, JsonBool(sUuid == sSelOnlUuid));
    }

    NuiSetBind(oDm, nToken, PLG_DM_BIND_ONLINE_NAMES, jOnlNames);
    NuiSetBind(oDm, nToken, PLG_DM_BIND_ONLINE_LEN, JsonInt(nOnlLen));
    NuiSetBind(oDm, nToken, PLG_DM_BIND_ONLINE_ENC, jOnlEnc);

    SetLocalJson(oDm, PLG_DM_LVAR_ONLINE_LIST_JSON, jOnline);

    // ===== Debug button label =====
    string sDebugLbl = PlgIsDebugMode() ? "Debug: ON (30s/phase)" : "Debug: OFF";
    NuiSetBind(oDm, nToken, PLG_DM_BIND_DEBUG_LBL, JsonString(sDebugLbl));

    // ===== Tab encouraged (active tab highlight) =====
    int nView = GetLocalInt(oDm, PLG_DM_LVAR_VIEW);
    NuiSetBind(oDm, nToken, PLG_DM_BIND_TAB_INF_ENC,
        JsonBool(nView == PLG_DM_VIEW_INFECTED));
    NuiSetBind(oDm, nToken, PLG_DM_BIND_TAB_ONL_ENC,
        JsonBool(nView == PLG_DM_VIEW_ONLINE));
    NuiSetBind(oDm, nToken, PLG_DM_BIND_TAB_STATS_ENC,
        JsonBool(nView == PLG_DM_VIEW_STATS));

    // ===== Stats binds (refresh on every Feed call) =====
    // Current state
    NuiSetBind(oDm, nToken, PLG_DM_BIND_S_ACTIVE,
        JsonString(IntToString(PlgQryActiveDiseases())));
    NuiSetBind(oDm, nToken, PLG_DM_BIND_S_MULTI,
        JsonString(IntToString(PlgQryMultiDiseasePlayers())));

    // Recent activity
    NuiSetBind(oDm, nToken, PLG_DM_BIND_S_CURED24,
        JsonString(IntToString(PlgQryCuredLast24h())));
    NuiSetBind(oDm, nToken, PLG_DM_BIND_S_DEATHS7,
        JsonString(IntToString(PlgQryDeaths7d())));
    NuiSetBind(oDm, nToken, PLG_DM_BIND_S_CONTAG7,
        JsonString(IntToString(PlgQryContagionSpreads7d())));

    // Last 30 days
    int nContracts30 = PlgQryTotalContracts30d();
    int nCures30     = PlgQryTotalCures30d();
    int nRecovery    = PlgQryRecoveryRate30d();
    int nTopDisId    = PlgQryTopDiseaseId30d();
    string sTopArea  = PlgQryTopAreaName30d();
    int nAvgIncCrit  = PlgQryAvgIncubToCritical30d();

    NuiSetBind(oDm, nToken, PLG_DM_BIND_S_CONTRACTS30,
        JsonString(IntToString(nContracts30)));
    NuiSetBind(oDm, nToken, PLG_DM_BIND_S_CURES30,
        JsonString(IntToString(nCures30)));
    NuiSetBind(oDm, nToken, PLG_DM_BIND_S_RECOVERY,
        JsonString(nRecovery < 0 ? "-" : IntToString(nRecovery) + "%"));
    NuiSetBind(oDm, nToken, PLG_DM_BIND_S_TOP_DISEASE,
        JsonString(nTopDisId < 0 ? "-" : PlgDiseaseName(nTopDisId)));
    NuiSetBind(oDm, nToken, PLG_DM_BIND_S_TOP_AREA,
        JsonString(sTopArea == "" ? "-" : sTopArea));
    NuiSetBind(oDm, nToken, PLG_DM_BIND_S_AVG_INC_CRIT,
        JsonString(PlgDmFormatDuration(nAvgIncCrit)));

    // Body fight win rate per phase
    NuiSetBind(oDm, nToken, PLG_DM_BIND_S_BF_INC,
        JsonString(IntToString(PlgQryBodyFightWinRateForPhase(PLG_PHASE_INCUBATION)) + "%"));
    NuiSetBind(oDm, nToken, PLG_DM_BIND_S_BF_MILD,
        JsonString(IntToString(PlgQryBodyFightWinRateForPhase(PLG_PHASE_MILD)) + "%"));
    NuiSetBind(oDm, nToken, PLG_DM_BIND_S_BF_SEV,
        JsonString(IntToString(PlgQryBodyFightWinRateForPhase(PLG_PHASE_SEVERE)) + "%"));
    NuiSetBind(oDm, nToken, PLG_DM_BIND_S_BF_CRIT,
        JsonString(IntToString(PlgQryBodyFightWinRateForPhase(PLG_PHASE_CRITICAL)) + "%"));

    // Healing economy (30d)
    NuiSetBind(oDm, nToken, PLG_DM_BIND_S_LENS,
        JsonString(IntToString(PlgQryLensUses30d())));
    NuiSetBind(oDm, nToken, PLG_DM_BIND_S_FA_SUCC,
        JsonString(IntToString(PlgQryFirstAidByResult30d("success"))));
    NuiSetBind(oDm, nToken, PLG_DM_BIND_S_FA_FAIL,
        JsonString(IntToString(PlgQryFirstAidByResult30d("fail"))));
    NuiSetBind(oDm, nToken, PLG_DM_BIND_S_WRONG_CURE,
        JsonString(IntToString(PlgQryWrongCureAttempts30d())));
}

void CreatePlgDmWindow(object oDm)
{
    if(!GetIsDM(oDm))
    {
        SendMessageToPC(oDm, "DM Panel is for Dungeon Masters only.");
        return;
    }

    int nToken = NuiFindWindow(oDm, PLG_DM_WINDOW);
    if(nToken != 0)
    {
        FeedPlgDmWindow(oDm, nToken);
        return;
    }

    float fGuiW = IntToFloat(GetPlayerDeviceProperty(oDm, PLAYER_DEVICE_PROPERTY_GUI_WIDTH));
    float fGuiH = IntToFloat(GetPlayerDeviceProperty(oDm, PLAYER_DEVICE_PROPERTY_GUI_HEIGHT));
    float fCX = (fGuiW - PLG_DM_W) / 2.0;
    float fCY = (fGuiH - PLG_DM_H) / 2.0;

    json jWin = NuiWindow(
        PlgDmBuildLayout(),
        JsonString("Plague - DM Panel"),
        NuiRect(fCX, fCY, PLG_DM_W, PLG_DM_H),

        JsonBool(FALSE),         // resizable
        JsonBool(FALSE),         // collapsed
        JsonBool(TRUE),          // closable
        JsonBool(FALSE),         // transparent
        JsonBool(TRUE));         // border

    nToken = NuiCreate(oDm, jWin, PLG_DM_WINDOW, PLG_DM_EV_SCRIPT);
    FeedPlgDmWindow(oDm, nToken);
}

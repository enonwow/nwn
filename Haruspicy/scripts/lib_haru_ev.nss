#include "lib_haru"

// ----------------------------------------------------------------
// Apply-and-save helper called when PC accepts the prophecy
// ----------------------------------------------------------------

void HaruHandleApply(object oPC, int nToken)
{
    if(GetLocalInt(oPC, HARU_LVAR_APPLIED)) return;
    SetLocalInt(oPC, HARU_LVAR_APPLIED, 1);

    int    nScore  = GetLocalInt   (oPC, HARU_LVAR_SCORE);
    string sCName  = GetLocalString(oPC, HARU_LVAR_CNAME);
    int    nCType  = GetLocalInt   (oPC, HARU_LVAR_CTYPE);
    int    nCR     = GetLocalInt   (oPC, HARU_LVAR_CR);
    json   jSigns  = GetLocalJson  (oPC, HARU_LVAR_SIGNS);
    string sProph  = HaruGetProphecy(nScore, nCType);

    HaruApplyEffect(oPC, nScore);
    HaruSaveReading(oPC, sCName, nCType, nCR, jSigns, nScore, sProph, HaruGetEffectId(nScore));
    HaruIncrementMastery(oPC, nScore);

    // Disable the button to prevent re-application
    NuiSetBind(oPC, nToken, HARU_BIND_APPLY_ENA, JsonBool(FALSE));

    // Refresh reading count
    int nTotal = HaruGetTotalReadings(oPC);
    NuiSetBind(oPC, nToken, HARU_BIND_READINGS,
        JsonString("Odczytan lacznie: " + IntToString(nTotal)));

    // Mastery milestone notification
    if(nTotal == 10)
        FloatingTextStringOnCreature(
            "Pieczec krwi pulsuje slabo — dziesiete czytanie wzmocnilo twoja wrażliwosc na omeny.",
            oPC, FALSE);
    else if(nTotal == 25)
        FloatingTextStringOnCreature(
            "Duchy trzewi szepca: dwudziesta piata ofiara — haruspeks dojrzal.",
            oPC, FALSE);
    else if(nTotal == 50)
        FloatingTextStringOnCreature(
            "Pięcdziesiat odczytan. Bogowie patrzą teraz na twoje dłonie z ciekawoscia.",
            oPC, FALSE);
}

// ----------------------------------------------------------------
// Close — cleanup PC locals
// ----------------------------------------------------------------

void HaruHandleClose(object oPC)
{
    DeleteLocalJson  (oPC, HARU_LVAR_SIGNS);
    DeleteLocalInt   (oPC, HARU_LVAR_SCORE);
    DeleteLocalString(oPC, HARU_LVAR_CNAME);
    DeleteLocalInt   (oPC, HARU_LVAR_CTYPE);
    DeleteLocalInt   (oPC, HARU_LVAR_CR);
    DeleteLocalInt   (oPC, HARU_LVAR_APPLIED);
}

// ----------------------------------------------------------------
// Main event dispatch
// ----------------------------------------------------------------

void main()
{
    object oPC    = NuiGetEventPlayer();
    int    nToken = NuiGetEventWindow();
    string sEvent = NuiGetEventType();
    string sElem  = NuiGetEventElement();

    // ---- History window ----
    if(nToken == NuiFindWindow(oPC, HARU_WIN_HIST))
    {
        if(sEvent == EVENT_TYPE_CLICK && sElem == HARU_BTN_HISTCLOSE)
            NuiDestroy(oPC, nToken);
        return;
    }

    if(nToken != NuiFindWindow(oPC, HARU_WIN_MAIN)) return;

    if(sEvent == EVENT_TYPE_CLOSE)
    {
        HaruHandleClose(oPC);
        return;
    }

    if(sEvent == EVENT_TYPE_CLICK)
    {
        if(sElem == HARU_BTN_CLOSE)
        {
            NuiDestroy(oPC, nToken);
            return;
        }
        if(sElem == HARU_BTN_APPLY)
        {
            HaruHandleApply(oPC, nToken);
            return;
        }
        if(sElem == HARU_BTN_HISTORY)
        {
            HaruOpenHistory(oPC);
            return;
        }
    }
}

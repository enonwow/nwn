#include "lib_nui"

const int RUNNING_STAMINA_MAX = 30;
const float RUNNING_EXHAUSTED_TIME = 10.0;

const string RUNNING_WINDOW = "RUNNING_WINDOW";
const string RUNNING_NUI_EVENT_SCRIPT = "lib_running_ev";

const string RUNNING_BUTTON = "RUNNING_BUTTON";
const string RUNNING_ENCOURAGED = "RUNNING_ENCOURAGED";

const string RUNNING_PROGRESS_BAR = "RUNNING_PROGRESS_BAR";
const string RUNNING_COLOR = "RUNNING_COLOR";
const string RUNNING_TOOLTIP = "RUNNING_TOOLTIP";

const string RUNNING_STAMINA = "RUNNING_STAMINA";
const string RUNNING_TOOGLE = "RUNNING_TOOGLE";
const string RUNNING_EXHAUSTED = "RUNNING_EXHAUSTED";

const string RUNNING_EFFECT_TAG = "RUNNING_EFFECT";

const float RUNNING_BUTTON_WIDTH = 50.0;
const float RUNNING_BUTTON_HEIGHT = 50.0;

const float RUNNING_PROGRESS_BAR_WIDTH = 150.0;

const float RUNNING_WIDTH_OFFSET = 25.0;
const float RUNNING_HEIGHT_OFFSET = 55.0;

const float RUNNING_WINDOW_WIDTH = RUNNING_BUTTON_WIDTH + RUNNING_PROGRESS_BAR_WIDTH + RUNNING_WIDTH_OFFSET;
const float RUNNING_WINDOW_HEIGHT = RUNNING_BUTTON_HEIGHT + RUNNING_HEIGHT_OFFSET;

void SetToogle(object oPC, int nToken, int bToogle);

void SetRunningEffect(object oPC, int nSpeedValue = 50)
{
    effect eEffect = EffectMovementSpeedIncrease(nSpeedValue);
    eEffect = TagEffect(eEffect, RUNNING_EFFECT_TAG);

    ApplyEffectToObject(
        DURATION_TYPE_PERMANENT,
        eEffect,
        oPC);
}

void RemoveRunningEffect(object oPC)
{
    effect eEffect = GetFirstEffect(oPC);
    while(GetIsEffectValid(eEffect))
    {
        if(GetEffectTag(eEffect) == RUNNING_EFFECT_TAG)
        {
            RemoveEffect(oPC, eEffect);
        }
        eEffect = GetNextEffect(oPC);
    }
}

void SetRunningValue(
    object oPC,
    int nToken,
    int nPreviousStamina,
    int nStamina)
{
    float fStamina = IntToFloat(nStamina) / RUNNING_STAMINA_MAX;
    float fPreviousStamina = IntToFloat(nPreviousStamina) / RUNNING_STAMINA_MAX;

    float fStage = fStamina / 0.25;
    float fPreviousStage = fPreviousStamina / 0.25;

    if(nStamina > 0 && fStage != fPreviousStage)
    {
        if(fStage == 0.0)
        {
            return;
        }

        SendMessageToPC(oPC, "fStage: " + FloatToString(fStage));

        RemoveRunningEffect(oPC);

        switch(FloatToInt(fStage))
        {
            case 3:
                SetRunningEffect(oPC, 50);
                break;
            case 2:
                SetRunningEffect(oPC, 25);
                break;
            case 1:
            case 0:
                SetRunningEffect(oPC, 5);
                break;
            default:
                break;
        }
    }
}

void SetExhausted(object oPC, int nToken)
{
    RemoveRunningEffect(oPC);

    SetToogle(oPC, nToken, FALSE);

    NuiSetBind(oPC, nToken, RUNNING_EXHAUSTED, JsonInt(TRUE));
    DelayCommand(RUNNING_EXHAUSTED_TIME,
        NuiSetBind(oPC, nToken, RUNNING_EXHAUSTED, JsonInt(FALSE)));

    ApplyEffectToObject(
        DURATION_TYPE_TEMPORARY,
        //EffectMovementSpeedIncrease(-50),
        EffectSlow(),
        oPC,
        RUNNING_EXHAUSTED_TIME);
}

void SetProgressbar(
    object oPC,
    int nToken,
    int nStamina)
{
    float fStamina = IntToFloat(nStamina) / RUNNING_STAMINA_MAX;

    if(fStamina >= 0.75)
    {
        NuiSetBind(oPC, nToken, RUNNING_COLOR, NuiColor(0, 255, 0));
    }
    else if(fStamina <= 0.75 && fStamina >= 0.5)
    {
        NuiSetBind(oPC, nToken, RUNNING_COLOR, NuiColor(255, 255, 0));
    }
    else if(fStamina <= 0.5 && fStamina >= 0.25)
    {
        NuiSetBind(oPC, nToken, RUNNING_COLOR, NuiColor(255, 0, 0));
    }

    string sTooltip =
        IntToString(nStamina) + " / " + IntToString(RUNNING_STAMINA_MAX);

    NuiSetBind(oPC, nToken, RUNNING_PROGRESS_BAR, JsonFloat(fStamina));
    NuiSetBind(oPC, nToken, RUNNING_TOOLTIP, JsonString(sTooltip));
}

void SetToogle(
    object oPC,
    int nToken,
    int bToogle)
{
    int nStamina = JsonGetInt(NuiGetBind(oPC, nToken, RUNNING_STAMINA));

    if(!bToogle)
    {
        int bExhausted = JsonGetInt(NuiGetBind(oPC, nToken, RUNNING_EXHAUSTED));
        if(!bExhausted)
        {
            RemoveRunningEffect(oPC);
        }
    }
    else
    {
        SetRunningValue(oPC, nToken, nStamina, nStamina);
    }

    NuiSetBind(oPC, nToken, RUNNING_TOOGLE, JsonInt(bToogle));
    NuiSetBind(oPC, nToken, RUNNING_ENCOURAGED, JsonInt(bToogle));

    SetProgressbar(oPC, nToken, nStamina);
}

void HandleRunning(object oPC, location lLastLocation)
{
    int nToken = NuiFindWindow(oPC, RUNNING_WINDOW);
    if(nToken == 0)
    {
        return;
    }

    int nExhausted = JsonGetInt(NuiGetBind(oPC, nToken, RUNNING_EXHAUSTED));
    location lCurrentLocation = GetLocation(oPC);

    if(!nExhausted)
    {
        int bToogle = JsonGetInt(NuiGetBind(oPC, nToken, RUNNING_TOOGLE));
        int nStamina = JsonGetInt(NuiGetBind(oPC, nToken, RUNNING_STAMINA));

        if(bToogle)
        {
            int nPreviousStamina = nStamina;
            if(lCurrentLocation != lLastLocation)
            {
                nStamina--;
            }
            else
            {
                nStamina++;

                if(nStamina >= RUNNING_STAMINA_MAX)
                {
                    nStamina = RUNNING_STAMINA_MAX;
                }
            }

            SetRunningValue(oPC, nToken, nPreviousStamina, nStamina);

            if(nStamina <= 0)
            {
                nStamina = 0;

                SetExhausted(oPC, nToken);
            }
        }
        else
        {
            ++nStamina;

            if(nStamina >= RUNNING_STAMINA_MAX)
            {
                nStamina = RUNNING_STAMINA_MAX;
            }
        }

        NuiSetBind(oPC, nToken, RUNNING_STAMINA, JsonInt(nStamina));
        SetProgressbar(oPC, nToken, nStamina);
    }

    DelayCommand(1.0, HandleRunning(oPC, lCurrentLocation));
}

json CreateRunningButton()
{
    json jButtonRunning = NuiButtonImage(JsonString("running_btn"));
    jButtonRunning = NuiId(jButtonRunning, RUNNING_BUTTON);
    jButtonRunning = NuiEncouraged(jButtonRunning, NuiBind(RUNNING_ENCOURAGED));
    jButtonRunning = NuiWidth(jButtonRunning, RUNNING_BUTTON_WIDTH);
    jButtonRunning = NuiHeight(jButtonRunning, RUNNING_BUTTON_HEIGHT);

    return jButtonRunning;
}

json CreateRunningProgressBar()
{
    json jProgressBar = NuiProgress(NuiBind(RUNNING_PROGRESS_BAR));
    jProgressBar = NuiStyleForegroundColor(jProgressBar, NuiBind(RUNNING_COLOR));
    jProgressBar = NuiTooltip(jProgressBar, NuiBind(RUNNING_TOOLTIP));
    jProgressBar = NuiHeight(jProgressBar, RUNNING_BUTTON_HEIGHT);
    jProgressBar = NuiWidth(jProgressBar, RUNNING_PROGRESS_BAR_WIDTH);

    return jProgressBar;
}

void CreateRunningWindow(object oPC)
{
    int nToken = NuiFindWindow(oPC, RUNNING_WINDOW);
    if(nToken != 0)
    {
        return;
    }

    json jRow = JsonArray();
    jRow = JsonArrayInsert(jRow, CreateRunningButton());
    jRow = JsonArrayInsert(jRow, CreateRunningProgressBar());

    json jRoot = NuiRow(jRow);

        json jNui = NuiWindow(
        jRoot,
        NuiBind(WINDOW_TITLE),
        NuiBind(WINDOW_GEOMETRY),
        NuiBind(WINDOW_RESIZABLE),
        NuiBind(WINDOW_COLLAPSED),
        NuiBind(WINDOW_CLOSABLE),
        NuiBind(WINDOW_TRANSPARENT),
        NuiBind(WINDOW_BORDER));

    nToken = NuiCreate(oPC, jNui, RUNNING_WINDOW, RUNNING_NUI_EVENT_SCRIPT);

    NuiSetBind(oPC, nToken, WINDOW_GEOMETRY, NuiRect(-1.0, -1.0, RUNNING_WINDOW_WIDTH, RUNNING_WINDOW_HEIGHT));
    NuiSetBind(oPC, nToken, WINDOW_TITLE, JsonString("Running"));
    NuiSetBind(oPC, nToken, WINDOW_RESIZABLE, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_COLLAPSED, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_CLOSABLE, JsonBool(TRUE));
    NuiSetBind(oPC, nToken, WINDOW_TRANSPARENT, JsonBool(FALSE));
    NuiSetBind(oPC, nToken, WINDOW_BORDER, JsonBool(TRUE));

    NuiSetBind(oPC, nToken, RUNNING_STAMINA, JsonInt(RUNNING_STAMINA_MAX));
    HandleRunning(oPC, GetLocation(oPC));
}

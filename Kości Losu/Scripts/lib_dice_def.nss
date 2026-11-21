// lib_dice_def.nss — constants, hand evaluation, and helpers for Kości Losu

#include "lib_nui"
#include "sql_dice"

// Forward declarations (resolved in lib_dice.nss)
void DiceOpenWindow(object oPC);
void DiceFeedRecord(object oPC, int nToken);
void DiceRevealResults(object oPC, int nToken, int nBet, json jPlayerDice, json jDealerDice);

// ---------------------------------------------------------------
// Window / event script identifiers
// ---------------------------------------------------------------

const string DICE_WINDOW        = "DICE_WINDOW";
const string DICE_EV_SCRIPT     = "lib_dice_ev";
const string DICE_WIN_GEOM      = "dice_win_geom";
const string DICE_WIN_LB        = "DICE_WIN_LB";

// ---------------------------------------------------------------
// Bind names — player's dice display
// ---------------------------------------------------------------

const string DICE_BIND_P_D1     = "dice_p_d1";
const string DICE_BIND_P_D2     = "dice_p_d2";
const string DICE_BIND_P_D3     = "dice_p_d3";
const string DICE_BIND_P_D4     = "dice_p_d4";
const string DICE_BIND_P_D5     = "dice_p_d5";
const string DICE_BIND_P_HAND   = "dice_p_hand";
const string DICE_BIND_P_COL    = "dice_p_col";   // single NuiColor for all 5 dice

// Bind names — dealer's dice display
const string DICE_BIND_D_D1     = "dice_d_d1";
const string DICE_BIND_D_D2     = "dice_d_d2";
const string DICE_BIND_D_D3     = "dice_d_d3";
const string DICE_BIND_D_D4     = "dice_d_d4";
const string DICE_BIND_D_D5     = "dice_d_d5";
const string DICE_BIND_D_HAND   = "dice_d_hand";
const string DICE_BIND_D_COL    = "dice_d_col";

// Bind names — controls & status
const string DICE_BIND_RESULT   = "dice_result";
const string DICE_BIND_GOLD_LBL = "dice_gold_lbl";
const string DICE_BIND_BET_TXT  = "dice_bet_txt";
const string DICE_BIND_ROLL_ENA = "dice_roll_ena";
const string DICE_BIND_REC_LBL  = "dice_rec_lbl";
const string DICE_BIND_JACKPOT  = "dice_jackpot";

// Bind names — leaderboard list
const string DICE_BIND_LB_NAME  = "dice_lb_name";
const string DICE_BIND_LB_WL    = "dice_lb_wl";
const string DICE_BIND_LB_GOLD  = "dice_lb_gold";
const string DICE_BIND_LB_ENC   = "dice_lb_enc";

// ---------------------------------------------------------------
// Button IDs
// ---------------------------------------------------------------

const string DICE_BTN_CLOSE     = "dice_btn_close";
const string DICE_BTN_ROLL      = "dice_btn_roll";
const string DICE_BTN_LB        = "dice_btn_lb";
const string DICE_BTN_LB_CLOSE  = "dice_btn_lb_close";

// ---------------------------------------------------------------
// Local variables stored on PC
// ---------------------------------------------------------------

const string DICE_LVAR_BUSY     = "DICE_BUSY";
const string DICE_LVAR_STREAK   = "DICE_STREAK";  // >0 = win streak, <0 = loss streak

// ---------------------------------------------------------------
// Layout dimensions
// ---------------------------------------------------------------

const float  DICE_W             = 540.0;
const float  DICE_H             = 520.0;

// ---------------------------------------------------------------
// Hand rank constants (higher = better hand)
// ---------------------------------------------------------------

const int    DICE_HAND_HIGH_DIE = 1;
const int    DICE_HAND_PAIR     = 2;
const int    DICE_HAND_TWO_PAIR = 3;
const int    DICE_HAND_THREE    = 4;
const int    DICE_HAND_FULL     = 5;
const int    DICE_HAND_FOUR     = 6;
const int    DICE_HAND_FIVE     = 7;

// ---------------------------------------------------------------
// Bet limits
// ---------------------------------------------------------------

const int    DICE_MIN_BET       = 10;
const int    DICE_MAX_BET       = 5000;
const int    DICE_LB_ROWS       = 10;

// 1/N of each bet contributes to the shared jackpot pool
const int    DICE_JACKPOT_FRAC  = 20;

// ---------------------------------------------------------------
// Hand evaluation
// ---------------------------------------------------------------

// Returns encoded score: rank*100 + tiebreak_value (higher = better).
// Avoids native arrays — uses individual int variables per die value.
int DiceEvaluateHand(json jDice)
{
    int nC1=0, nC2=0, nC3=0, nC4=0, nC5=0, nC6=0;
    int i;
    for(i = 0; i < 5; i++)
    {
        int v = JsonGetInt(JsonArrayGet(jDice, i));
        if     (v == 1) nC1++;
        else if(v == 2) nC2++;
        else if(v == 3) nC3++;
        else if(v == 4) nC4++;
        else if(v == 5) nC5++;
        else             nC6++;
    }

    // Max count and its die value (search ascending → highest value wins ties)
    int nMax=0, nMaxVal=0;
    if(nC1 >= nMax) { nMax=nC1; nMaxVal=1; }
    if(nC2 >= nMax) { nMax=nC2; nMaxVal=2; }
    if(nC3 >= nMax) { nMax=nC3; nMaxVal=3; }
    if(nC4 >= nMax) { nMax=nC4; nMaxVal=4; }
    if(nC5 >= nMax) { nMax=nC5; nMaxVal=5; }
    if(nC6 >= nMax) { nMax=nC6; nMaxVal=6; }

    // Second-highest count (ignoring nMaxVal's slot)
    int nSecond=0;
    if(nMaxVal != 1 && nC1 > nSecond) nSecond=nC1;
    if(nMaxVal != 2 && nC2 > nSecond) nSecond=nC2;
    if(nMaxVal != 3 && nC3 > nSecond) nSecond=nC3;
    if(nMaxVal != 4 && nC4 > nSecond) nSecond=nC4;
    if(nMaxVal != 5 && nC5 > nSecond) nSecond=nC5;
    if(nMaxVal != 6 && nC6 > nSecond) nSecond=nC6;

    // Highest die value present (for high-die tiebreak)
    int nHighDie=1;
    if(nC2 > 0) nHighDie=2;
    if(nC3 > 0) nHighDie=3;
    if(nC4 > 0) nHighDie=4;
    if(nC5 > 0) nHighDie=5;
    if(nC6 > 0) nHighDie=6;

    if(nMax == 5) return DICE_HAND_FIVE     * 100 + nMaxVal;
    if(nMax == 4) return DICE_HAND_FOUR     * 100 + nMaxVal;
    if(nMax == 3 && nSecond == 2)
                  return DICE_HAND_FULL     * 100 + nMaxVal;
    if(nMax == 3) return DICE_HAND_THREE    * 100 + nMaxVal;
    if(nMax == 2 && nSecond == 2)
                  return DICE_HAND_TWO_PAIR * 100 + nMaxVal;
    if(nMax == 2) return DICE_HAND_PAIR     * 100 + nMaxVal;
    return         DICE_HAND_HIGH_DIE * 100 + nHighDie;
}

int  DiceHandRank(int nScore)  { return nScore / 100;  }
int  DiceHandValue(int nScore) { return nScore % 100;  }

string DiceHandName(int nRank)
{
    switch(nRank)
    {
        case DICE_HAND_PAIR:     return "Para";
        case DICE_HAND_TWO_PAIR: return "Dwie pary";
        case DICE_HAND_THREE:    return "Trójka";
        case DICE_HAND_FULL:     return "Full";
        case DICE_HAND_FOUR:     return "Kareta";
        case DICE_HAND_FIVE:     return "Pięć jednakowych";
        default:                 return "Wysokie oczko";
    }
}

// Returns a JsonArray of 5 random d6 rolls
json DiceRollFive()
{
    json jDice = JsonArray();
    int i;
    for(i = 0; i < 5; i++)
        jDice = JsonArrayInsert(jDice, JsonInt(d6()));
    return jDice;
}

// Temporary combat boon for a jackpot-winning five-of-a-kind
void DiceApplyLuckBoon(object oPC)
{
    effect eBoon = EffectAttackIncrease(1, ATTACK_BONUS_MISC);
    eBoon = EffectLinkEffects(eBoon, EffectSavingThrowIncrease(SAVING_THROW_ALL, 1, SAVING_THROW_TYPE_ALL));
    eBoon = SupernaturalEffect(eBoon);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eBoon, oPC, 3600.0);
    FloatingTextStringOnCreature("Błogosławieństwo Fortuny!", oPC, FALSE);
    SendMessageToPC(oPC, "[Kości Losu] Magia losu płonie w twojej piersi. +1 do ataku i rzutów obronnych przez godzinę.");
}

// Temporary penalty for rolling five ones (worst possible outcome)
void DiceApplyLuckCurse(object oPC)
{
    effect eCurse = EffectSavingThrowDecrease(SAVING_THROW_ALL, 1, SAVING_THROW_TYPE_ALL);
    eCurse = SupernaturalEffect(eCurse);
    ApplyEffectToObject(DURATION_TYPE_TEMPORARY, eCurse, oPC, 1800.0);
    FloatingTextStringOnCreature("Klątwa Przegranego!", oPC, FALSE);
    SendMessageToPC(oPC, "[Kości Losu] Przeznaczenie cię opuszcza... -1 do rzutów obronnych przez 30 minut.");
}

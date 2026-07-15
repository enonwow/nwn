#include "lib_obs"

// Fires every 6 seconds. Checks for the monthly Convergence event:
// day 14 of each month, game hour 12, minute 0 (first 6 seconds of that minute).
void main()
{
    if(GetCalendarDay() != 14) return;
    if(GetTimeHour() != 12)    return;
    if(GetTimeMinute() > 0)    return;

    // Build a key so each month's convergence fires only once per server lifetime.
    string sKey = IntToString(GetCalendarYear()) + "_" + IntToString(GetCalendarMonth());
    if(GetLocalString(GetModule(), OBS_LVAR_CONV_SEEN) == sKey) return;

    SetLocalString(GetModule(), OBS_LVAR_CONV_SEEN, sKey);
    ObsAnnounceConvergence();
}

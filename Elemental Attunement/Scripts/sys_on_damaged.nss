// sys_on_damaged.nss — creature OnDamaged handler; accumulates elemental attunement
// Set dynamically on each PC via SetEventScript in sys_on_enter.nss
#include "lib_eatt"

// Points earned = max(1, dmg / 5); ensures even weak hits slowly build attunement
int CalcPoints(int nDmg)
{
    if (nDmg <= 0) return 0;
    int nPts = nDmg / 5;
    return (nPts < 1) ? 1 : nPts;
}

void main()
{
    object oPC = OBJECT_SELF;

    if (GetIsPC(oPC))
    {
        int nFire      = GetDamageDealtByType(DAMAGE_TYPE_FIRE);
        int nCold      = GetDamageDealtByType(DAMAGE_TYPE_COLD);
        int nAcid      = GetDamageDealtByType(DAMAGE_TYPE_ACID);
        int nLightning = GetDamageDealtByType(DAMAGE_TYPE_ELECTRICAL);
        int nShadow    = GetDamageDealtByType(DAMAGE_TYPE_NEGATIVE);

        if (nFire      > 0) EattAddPoints(oPC, EATT_ELEM_FIRE,      CalcPoints(nFire));
        if (nCold      > 0) EattAddPoints(oPC, EATT_ELEM_COLD,      CalcPoints(nCold));
        if (nAcid      > 0) EattAddPoints(oPC, EATT_ELEM_ACID,      CalcPoints(nAcid));
        if (nLightning > 0) EattAddPoints(oPC, EATT_ELEM_LIGHTNING,  CalcPoints(nLightning));
        if (nShadow    > 0) EattAddPoints(oPC, EATT_ELEM_SHADOW,    CalcPoints(nShadow));
    }

    // Chain previously registered OnDamaged script (other modules)
    string sPrev = GetLocalString(oPC, EATT_PREV_SCRIPT);
    if (sPrev != "")
        ExecuteScript(sPrev, oPC);
}

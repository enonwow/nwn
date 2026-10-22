// Called by a trigger or heartbeat when a beacon should be corrupted.
// Place as OnHeartbeat on a creature or trigger OnEnter in a dark area.
// The target object must have BCN_VAR_TYPE set (i.e. it is a beacon placeable).
// Usage from another script:
//   AssignCommand(oBeacon, ExecuteScript("sys_on_target", oBeacon));
// Or wire directly as a heartbeat / enter script on an area trigger near the beacon.
#include "lib_bcn_def"

void BcnCorruptNearbyBeacons(object oSource)
{
    object oArea = GetArea(oSource);
    object oObj  = GetFirstObjectInArea(oArea);
    while(GetIsObjectValid(oObj))
    {
        if(GetLocalString(oObj, BCN_VAR_TYPE) != "")
        {
            string sTag = GetTag(oObj);
            json jB = BcnGetBeacon(sTag);
            if(JsonGetType(jB) != JSON_TYPE_NULL)
            {
                int nCorr = JsonGetInt(JsonObjectGet(jB, "corruption"));
                if(nCorr < BCN_CORR_OUT && BcnIsKindled(sTag))
                {
                    BcnCorrupt(sTag);
                    // Notify any PC standing near the beacon
                    object oPC = GetFirstPC();
                    while(GetIsObjectValid(oPC))
                    {
                        if(GetArea(oPC) == oArea
                            && GetDistanceBetween(oPC, oObj) < 15.0)
                        {
                            SendMessageToPC(oPC,
                                "[Latarnia] Plomien drzy i ciemnieje — mrok dotarl do latarni.");
                        }
                        oPC = GetNextPC();
                    }
                    ApplyEffectAtLocation(DURATION_TYPE_INSTANT,
                        EffectVisualEffect(VFX_FNF_SMOKE_PUFF),
                        GetLocation(oObj));
                }
            }
        }
        oObj = GetNextObjectInArea(oArea);
    }
}

void main()
{
    BcnCorruptNearbyBeacons(OBJECT_SELF);
}

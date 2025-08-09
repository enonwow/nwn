void main()
{
    object oPC = GetEnteringObject();

    float fScale = GetLocalFloat(oPC, "SCALE");

    if(fScale < 0.5)
    {
        fScale = 1.0;
    }
    else
    {
        SetObjectVisualTransform(oPC, OBJECT_VISUAL_TRANSFORM_SCALE, fScale);
    }

    SetLocalFloat(oPC, "SCALE", fScale);
}

//::///////////////////////////////////////////////////////////////
//:: sys_on_load — OnModuleLoad event handler
//::///////////////////////////////////////////////////////////////
//:: Centralny init przy starcie modułu. Każdy system dodaje tu
//:: swoje wywołanie inicjalizacyjne.
//::
//:: Podpiąć w Module Properties → Events → OnModuleLoad.
//::///////////////////////////////////////////////////////////////

void main()
{
    // Feat Shop — uruchom standalone build cache.
    // ExecuteScript zamiast include — fshop_build ma void main() i swój
    // własny limit instrukcji (100M dla heavy build feat.2da).
    ExecuteScript("fshop_build", GetModule());
}

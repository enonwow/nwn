#include "lib_fcraft"

// OnUsed script for the "Stół Rzeźbiarza Ciał" placeable.
// Place it in the module and set this script as the OnUsed handler.
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;

    string sGreet = "Rzeźbiarz odwraca się, nie odrywając wzroku od chirurgicznego narzędzia. "
                  + "\"Siadaj — ciało jest tylko gliną. Ja jestem garncarzem.\"";
    FloatingTextStringOnCreature(sGreet, oPC, FALSE);
    DelayCommand(0.3, FcraftOpen(oPC));
}

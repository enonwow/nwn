// sys_on_activate.nss - module OnPlayerActivateItem event
// Hook: Module Properties -> Events -> OnActivateItem
//
// Wywolywane gdy gracz aktywuje item targetowany na siebie lub innego.
// Tutaj dispatchujemy plague-related items (soczewka, apteczka, lekarstwa).

#include "lib_plg"

void main()
{
    object oPC     = GetItemActivator();
    object oItem   = GetItemActivated();
    object oTarget = GetItemActivatedTarget();

    // Plague items dzialaja tylko na samego siebie (self-targeted)
    if(oTarget != oPC) return;

    PlgHandleItemActivation(oPC, oItem);
}

# Blizny (Wounds & Scars) — Integration Guide

## Wymagania

- NWN:EE 8193.37+ (wymagane `TagEffect` / `GetEffectTag` — natywne w EE)
- Brak NWNX
- Campaign DB `scar` tworzony automatycznie

## Podpięcie hooków

Wywołaj odpowiednie funkcje z istniejących handlerów modułu:

| Zdarzenie modułu | Plik | Wywołanie |
|---|---|---|
| OnModuleLoad | `sys_on_load.nss` | `ScarCreateTables()` |
| OnClientEnter | `sys_on_enter.nss` | Całość lub `ScarRefreshHealed(oPC); ScarApplyEffects(oPC);` |
| OnPlayerRespawn | `sys_on_respawn.nss` | Całość lub `ScarGainWound(oPC);` z 75% szansą |

Jeśli moduł ma jeden skrypt na zdarzenie, możesz użyć pliku bezpośrednio.

## Placeable "Stół Medyczny"

1. Dodaj placeable do modułu, nazwij go dowolnie.
2. Ustaw `OnUsed` → `test_scar`.
3. W środowisku produkcyjnym zamień `test_scar` na dedykowany skrypt bez symulowania ran.

## Skrypty do włączenia w HAK / Override

Brak — moduł nie wymaga zasobów graficznych.

## Co celowo pominięto

- **Animacje leczenia** — wymagałyby assetów w hak
- **Chirurg NPC z dialogiem** — integrator podpina własny NPC przez `ScarOpenWindow(oPC)` w ConversationAction
- **Maksymalna liczba blizn** — blizny (status 2) nie są kasowane; nagromadzone trofea bitewne
- **Dodatkowe typy ran z broni** — rozszerzalne przez `ScarDbAddWound(oPC, nType, nLoc)` bezpośrednio
- **Wizualna zmiana appearance** — celowo rozdzielona od systemu Corruption/Appearance

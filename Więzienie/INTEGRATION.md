# Więzienie Królewskie — Integracja

## Hooki modułu

| Zdarzenie          | Skrypt                            |
|--------------------|-----------------------------------|
| OnModuleLoad       | `sys_on_load`                     |
| OnClientEnter      | `sys_on_enter` (lub wywołaj z istniejącego) |
| OnNUIEvent         | `lib_prison_ev` (auto — `NuiCreate` rejestruje go wewnętrznie) |

## Placeable testowy

1. Utwórz w edytorze dowolny placeable (np. kratę, słup ogłoszeń).
2. Ustaw `OnUsed = test_prison`.
3. Po kliknięciu placeable'a postać gracza zostaje uwięziona z rosnącym poziomem zbrodni.

## Aresztowanie z innego skryptu

Wywołaj z dowolnego miejsca:

```nss
#include "lib_prison"

// Arrest a PC for a crime. nCrimeLevel 1-5.
PrisonArrestPlayer(oPC, 3, "Rozbój na trakcie handlowym");
```

Możesz też najpierw wystawić nakaz i aresztować gracza przy spotkaniu z wartownikiem:

```nss
// Issue a warrant (e.g., a guard witnesses a crime):
PrisonIssueWarrant(oPC, 2, "Kradzież sklepowa");

// Later, a guard NPC checks:
if(PrisonGetWarrantLevel(oPC) >= 1)
    PrisonArrestPlayer(oPC, PrisonGetWarrantLevel(oPC), "Realizacja nakazu aresztu");
```

## Punkty nawigacyjne (Waypoints)

| Tag                  | Opis                                          |
|----------------------|-----------------------------------------------|
| `PRISON_CELL_WP`     | Gracz teleportuje się tu przy areszcie        |
| `PRISON_RELEASE_WP`  | Gracz teleportuje się tu przy zwolnieniu      |

Jeśli waypointy nie istnieją w module, teleport jest pomijany — gracz pozostaje na miejscu.

## Zmienna lokalna na graczu

Zewnętrzne skrypty mogą ustawić `PRISON_CRIME_LEVEL` (int) na obiekcie PC. Nie jest ona automatycznie sprawdzana — służy jako sygnał dla własnych handlerów (np. OnPerception strażnika), które następnie wywołują `PrisonArrestPlayer`.

## Zależności

- **Brak NWNX** — moduł działa na czystym NWN:EE.
- SQLite: dane globalne w campaign DB `"prison"` (tworzone automatycznie przez `sys_on_load`).
- Wytrych: sprawdzane tagi `NW_IT_PICKS001` / `002` / `003` (standardowe narzędzia złodziejskie NWN).

## Co celowo pominięto

- **Sędzia / rozprawy sądowe** — wymaga NPC dialogów; poza zakresem modułu.
- **Kary pieniężne jako alternatywa** — logika trybu grzywny jest zaimplementowana częściowo przez opcję przekupstwa; formalne postępowanie pomięte.
- **Multiplayer synchronizacja cel** — jeden gracz w jednej celi; listy współwięźniów wymagałyby własnego UI.
- **Grafika / tło NUI** — moduł nie dostarcza pliku `.hak`; używa domyślnych kontrolek NWN:EE.

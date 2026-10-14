# Thread of Fate — Nić Przeznaczenia

## Opis

System śledzenia życiowej siły duszy postaci (0–100 punktów). Nić jest drenowana przez długi pobyt na przekletych obszarach lub użycie ciemnych przedmiotów. Przy niższych warstwach nakładają się rosnące kary do rzutów obronnych, KP i Siły. Przy 0 postać staje się „Dotkniętą Śmiercią" — w stanie liminalnym między żywym a nieumarłym. Przywrócenie następuje przez przedmioty oczyszczające lub święte miejsca.

## Wymagania

- NWN: Enhanced Edition (1.84+) — wymaga NUI API, `EffectSavingThrowDecrease`, `TagEffect`, `GetEffectTag`
- NWNX: **nie wymagany**
- SQL: kampania SQLite (`nit`), tworzona przy starcie modułu

## Podpinanie hooków w toolsecie

| Zdarzenie modułu     | Skrypt         |
|----------------------|----------------|
| OnModuleLoad         | `sys_on_load`  |
| OnClientEnter        | `sys_on_enter` |
| OnClientLeave        | `sys_on_leave` |
| OnModuleHeartbeat    | `sys_module_hb`|

Jeśli w module są już inne skrypty dla tych zdarzeń, wywołaj funkcje z `lib_nit.nss` z poziomu istniejących skryptów:

```nwscript
// W OnClientEnter:
#include "lib_nit"
void main() {
    object oPC = GetEnteringObject();
    if(!GetIsPC(oPC)) return;
    NitOnClientEnter(oPC);
    // ... reszta kodu
}
```

## Konfiguracja obszarów (toolset)

W Właściwościach obszaru → Zmienne ustaw:

| Zmienna         | Typ  | Wartość | Efekt                                              |
|-----------------|------|---------|----------------------------------------------------|
| `NIT_AREA_DRAIN` | INT  | 1–5     | Drenaż X punktów co ~60s przy pobycie w obszarze  |
| `NIT_AREA_RESTORE` | INT | 1–5   | Bierny przyrost 1 pkt co ~12 min (tylko jeśli brak drenażu) |

Przykładowe wartości:
- Loch z nieumarłymi: `NIT_AREA_DRAIN = 2`
- Nekromantyczna arena: `NIT_AREA_DRAIN = 5`
- Świątynia: `NIT_AREA_RESTORE = 3`

## Przedmioty

| Tag             | Działanie                                      |
|-----------------|------------------------------------------------|
| `nit_cleanse`   | Użycie konsumuje przedmiot, przywraca +15 pkt  |

Utwórz przedmiot (np. butelkę z wodą święconą) z tagiem `nit_cleanse` i umieść go u kupców/kapłanów.

## Otwieranie okna UI

Gracze mogą otworzyć okno w dowolnym momencie, wywołując:

```nwscript
#include "lib_nit"
NitOpenWindow(oPC);
```

Podepnij to do placeable, rozmowy z NPC, lub skrótu klawiszowego (action/radial script).

## Zewnętrzna integracja drenażu

Inne skrypty mogą drenować lub przywracać Nić gracza:

```nwscript
#include "lib_nit"

// Przy użyciu zaklęcia nekromancji:
NitDrainThread(oPC, 5, "Zaklęcie nekromancji");

// Przy odpoczynku w świątyni:
NitRestoreThread(oPC, 10);
```

## Flaga Dotknięty Śmiercią

Gdy nić gracza osiągnie 0, na obiekcie gracza ustawiana jest zmienna:

```
NIT_DEATH_TOUCHED = 1
```

Możesz jej używać w innych skryptach (np. by modyfikować efekty leczenia):

```nwscript
if(GetLocalInt(oPC, "NIT_DEATH_TOUCHED"))
    // gracz jest Dotkniętym Śmiercią — leczenie o 50% słabsze (logika po stronie twórcy)
```

## Test

Umieść obiekt (placeable) z tagiem dowolnym, skryptem `OnUsed = test_nit`. Po użyciu:
- Drain 20 pkt per kliknięcie
- Automatyczny reset po osiągnięciu 0
- Okno Nić Przeznaczenia otwiera się automatycznie

## Co celowo pominięto

- Wizualne zmiany Appearance przy Death-Touched (zależy od Appearance module)
- Automatyczny drenaż przy pobliżu nieumarłych NPC (ryzyko nadmiernej kary w typowych lochach)
- Trwała przemiana morphologiczna przy 0 (zrealizowana jako flaga, logika po stronie modułu)
- Permanentność statusu Death-Touched (jest resetowalna przez oczyszczanie)

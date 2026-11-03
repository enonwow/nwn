# Excavation — Integracja z modułem

## Co to robi

System wykopalisk arkeologicznych. Gracze aktywują naznaczone "stanowiska"
(placeables) i kopią, wydając punkty życia. Kiedy pasek postępu zapełni się
do 100%, gracz otrzymuje **odłamek** z danej ery historycznej. Zebranie
3 odłamków tej samej ery pozwala w zakładce *Kodeks* złożyć **Relikwię**,
dającą trwały bonus do atrybutu.

| Era              | Bonus (max +3) |
|------------------|----------------|
| Praczasy         | +SIŁ           |
| Wiek Mroku       | +BUD           |
| Epoka Cesarska   | +INT           |
| Zapomniana Era   | +MĄD           |

## Wymagania techniczne

- NWN Enhanced Edition (build 8193+) — wymagane dla `NuiProgress`.
- SQLite kampanijny: skrypt tworzy kampanię `exc` (`exc.sqlite`/`exc.db`)
  w katalogu `[nwn_home]/database/`.
- Bez NWNX.

## Podpięcie hooków

| Hook modułu   | Skrypt do wywołania | Uwaga |
|---------------|---------------------|-------|
| OnModuleLoad  | `sys_on_load`       | Tworzy tabele SQL. |
| OnClientEnter | `sys_on_enter`      | Nakłada efekty relikwii po zalogowaniu. |

Jeśli już masz własne skrypty na tych hookach, wywołaj z nich:
```
// OnModuleLoad:
ExecuteScript("sys_on_load", GetModule());

// OnClientEnter:
ExecuteScript("sys_on_enter", GetModule());
```
lub wczytaj bibliotekę i wywołaj funkcję bezpośrednio:
```
#include "lib_exc"
// OnClientEnter:
ExcApplyRelicEffects(GetEnteringObject());
```

## Dodawanie stanowisk wykopaliskowych

1. Umieść dowolny placeable w obszarze (np. ruiny, kopiec, starożytny ołtarz).
2. Nadaj mu **unikalny tag** (np. `exc_site_ruins1`).
3. Ustaw lokalną zmienną int **`EXC_ERA`** (0–3) określającą erę stanowiska:
   - 0 → Praczasy
   - 1 → Wiek Mroku
   - 2 → Epoka Cesarska
   - 3 → Zapomniana Era
4. Przypisz skrypt **`test_exc`** do eventu `OnUsed` placeabla.

## Parametry konfiguracyjne (w `lib_exc_def.nss`)

| Stała                    | Domyślna wartość | Opis |
|--------------------------|-----------------|------|
| `EXC_SITE_MAX_TRIES`     | 7               | Liczba prób kopania na stanowisko per gracz |
| `EXC_DIG_HP_COST_PCT`    | 5               | Procent max HP kosztu za próbę |
| `EXC_PROGRESS_MIN`       | 15              | Min przyrost postępu (%) za próbę |
| `EXC_PROGRESS_MAX`       | 40              | Max przyrost postępu (%) za próbę |
| `EXC_SHARDS_PER_RELIC`   | 3               | Odłamki potrzebne do złożenia jednej relikwii |
| `EXC_MAX_RELICS_PER_ERA` | 3               | Max relikwii per era per gracz |

## Co celowo pominięto

- Resety stanowisk (nie ma mechaniki "odnowienia" wyczerpanych stanowisk;
  łatwe do dodania przez timed event ustawiający `remaining = EXC_SITE_MAX_TRIES`).
- Narzędzia jako item-requirement (kopanie wymaga tylko HP, nie wykopaliska).
- Różnicowanie jakości odłamków (wszystkie odłamki danej ery są równoważne).
- Animacja kopania (można dodać `ActionPlayAnimation(ANIMATION_LOOPING_GET_LOW, 1.0, 2.0)`).

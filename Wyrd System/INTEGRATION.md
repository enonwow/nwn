# Wyrd System — Integration Guide

## Co to jest

**Krosno Przeznaczenia** — system waluty losu w klimacie dark fantasy.
Gracze gromadzą *wyrd* przez ciemne rytuały i mogą go wydawać na tymczasowe
łaski (save boosty, atak, ukrycie, prawdziwe widzenie, przeżycie śmierci).
Powyżej 75 wyrdu materializują się Duchy Przeznaczenia. Przy 100 — Nemezis.
Wyrd powoli zanika (−1/minutę), tworząc napięcie między gromadzeniem
a bezpieczeństwem.

## Hooki do podpięcia

| Zdarzenie modułu     | Skrypt do podpięcia     | Lub wywołaj                  |
|----------------------|-------------------------|------------------------------|
| OnModuleLoad         | `sys_on_load.nss`       | `WyrdDbInit()`               |
| OnClientEnter        | `sys_on_enter.nss`      | `WyrdOnClientEnter()`        |
| OnModuleHeartbeat    | `sys_on_hbeat.nss`      | `WyrdModuleHeartbeat()`      |
| OnPlayerDeath        | `sys_on_pdeath.nss`     | `WyrdOnPlayerDeath()`        |
| OnNUIEvent           | `lib_wyrd_ev.nss`       | `WyrdHandleNuiEvent()`       |

Jeśli moduł ma już swoje skrypty dla tych zdarzeń, dodaj wywołanie funkcji
Wyrd na końcu istniejącego `main()`.

## Przyznawanie wyrdu z własnych skryptów

```nss
#include "lib_wyrd"

// Np. w skrypcie OnDeath enemy, OnSpellCast, OnUsed ołtarza:
WyrdGrant(oPC, 10, "Krwawa ofiara na Rozstajach.");
```

Zalecane progi przyznawania:
- Małe rytuały (ofiara z monet, modlitwa): 5–10 wyrd
- Średnie rytuały (ofiara z krwi, przysięga): 15–25 wyrd
- Duże rytuały (ofiara z życia, pakt): 30–50 wyrd

## Otwieranie UI z placeable

Przypisz `test_wyrd.nss` jako `OnUsed` dowolnego placeable (np. kamienny
posąg, obelisk, kościotrup przy rozdrożu). Dostosuj stałe:
- `WYRD_TEST_GRANT` — ile wyrdu przyznać per użycie (0 = tylko UI)
- `WYRD_TEST_COOLDOWN` — cooldown w sekundach (domyślnie 120)

Możesz też otworzyć UI bezpośrednio z dowolnego skryptu:
```nss
#include "lib_wyrd"
WyrdOpenWindow(oPC);
```

## Zależności

- **Tylko NWScript + NUI** — brak NWNX.
- Wymaga NWN EE (1.83+) — używa `SqlPrepareQueryCampaign`,
  `NuiCreate`/`NuiSetGroupLayout`, `EffectTrueSeeing`, `ExtraordinaryEffect`.
- Duch Przeznaczenia korzysta z resrefy `nw_shadow002` i `nw_demogorg01`
  (standardowe creatury z NWN EE). Zastąp je własnymi, jeśli nie masz tych
  w hak.

## SQL

Tabela `wyrd_chars` w **Campaign DB** (globalnej): jedna tabela, idempotentna
migracja (`CREATE TABLE IF NOT EXISTS`), bezpieczna przy restarcie serwera.

## Co celowo pominięto

- **Animacje rytuałów** — brak dodatkowych VFX / animacji creatury; byłoby
  zależne od haka.
- **Boon w eq slocie** — łaski są efektami, nie itemami; nie zajmują slotów.
- **Ograniczenie per-serwer** do jednoczesnej liczby aktywnych boonów — łatwo
  dodać przez sprawdzenie liczby aktywnych w WyrdBuyBoon().
- **Ochrona anty-exploit** na rapid-grant przez DM — zakłada się uczciwość
  serwera; produkcyjny moduł powinien dodać rate-limiter w WyrdGrant().

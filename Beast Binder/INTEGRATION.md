# Beast Binder — Integracja modułu

## Wymagania

- NWN:EE build 8193.36+ (NUI, SqlPrepareQueryCampaign)
- NWNX: **nie wymagany**
- Kampania SQLite: tworzona automatycznie jako `bb.sqlite` przy wywołaniu `BbCreateTables()`

## Hooki do podłączenia

| Zdarzenie modułu | Skrypt do dodania | Uwaga |
|-----------------|-------------------|-------|
| `OnModuleLoad`  | `sys_on_load`     | tworzy tabele SQLite |
| `OnClientEnter` | `sys_on_enter`    | decay więzi, respawn bestii |
| `OnPlayerTarget`| `sys_on_target`   | obsługa trybu schwytania |

Jeśli moduł już ma skrypty na tych zdarzeniach, wywołaj odpowiednie funkcje z tych plików wewnątrz istniejących skryptów:

```nss
// W OnModuleLoad:
#include "lib_bb_def"
// ...
BbCreateTables();

// W OnClientEnter:
#include "lib_bb"
// ...
if(GetIsPC(GetEnteringObject())) {
    BbDecayBonding(GetEnteringObject());
    // ... (walidacja bestii — skopiuj treść sys_on_enter.nss)
}

// W OnPlayerTarget:
#include "lib_bb"
// ... (skopiuj treść sys_on_target.nss, obok innych modułów)
```

## Otwieranie okna

Dołącz skrypt `test_bb.nss` jako `OnUsed` do dowolnego placeable (klatka, totem, stół).
Alternatywnie, wywołaj `BbOpenWindow(oPC)` z dowolnego miejsca.

## Wymagany asset — karma/mięso

Bestie karmi się przedmiotem o tagu `bb_meat`.  
Utwórz w toolsecie item (np. `nw_it_food001` z nadpisanym tagiem = `bb_meat`)
i umieść go w sklepach / na zwłokach. Bez tego przedmiotu przycisk **Nakarm** wyświetla
komunikat błędu, ale moduł nie zawiesza się.

## Resfery bestii

Podczas schwytania zapisywany jest `GetResRef(oTarget)`.  
Resref musi istnieć w plikach HAK / basedata modułu — bestia jest potem
odtwarzana przez `CreateObject(OBJECT_TYPE_CREATURE, sResRef, ...)`.  
Polecane domyślne resrefy NWN:
- Wilk: `nw_wolfdir` lub `wolf`
- Pająk: `nw_spidertiny`
- Niedźwiedź: `nw_bear`

## Zmiana liczby slotów

Zmień stałą `BB_MAX_BEASTS` w `lib_bb_def.nss` (domyślnie 5).

## Bonding i efekty

| Próg | Efekt |
|------|-------|
| 0–24 | bestia niestabilna, gracz widzi ostrzeżenie |
| 25–49 | bestia toleruje właściciela |
| 50–74 | bestia pos³uszna |
| 75–99 | bestia wierna, +20 HP przy aktywacji |
| 100 | bestia w pełni oswojona (+20 HP, komunikat osiągnięcia) |

Więź spada o `BB_BOND_DECAY_HOUR` (8 pkt) za każdą godzinę od ostatniego karmienia.
Każde zabójstwo przy aktywnej bestii (obsługiwane przez twój moduł, wywołaj `BbAddKill(nId)`)
podnosi więź o `BB_BOND_KILL` (2 pkt).

## Rejestrowanie zabójstw

Wywołaj `BbAddKill(nId)` z `OnCreatureDeath` lub `OnPlayerDeath` po stronie właściciela.
Przykład:

```nss
#include "lib_bb_def"
// W OnCreatureDeath:
object oKiller = GetLastKiller();
if(GetIsPC(oKiller)) {
    int nActiveId = BbGetActiveBeastId(oKiller);
    if(nActiveId > 0) BbAddKill(nActiveId);
}
```

## Co celowo pominięto

- Persistent henchman across server restarts — bestia jest re-spawnowana przy każdym wejściu do obszaru; destrukcja henchmana między przejściami jest oczekiwana.
- Własna grafika i animacje — bestia używa oryginalnego modelu creature.
- Leveling bestii poza bonding — skupiono się na jednej, czytelnej mechanice więzi.
- UI podglądu modelu bestii — NUI nie wspiera podglądu 3D.

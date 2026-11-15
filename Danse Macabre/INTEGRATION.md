# Danse Macabre — integracja

## Hooki modułowe

| Event modułu NWN | Skrypt do wywołania |
|---|---|
| `OnModuleLoad` | `sys_on_load` (tworzy tabele SQLite) |
| `OnClientEnter` | `sys_on_enter` (rejestruje gracza, sprawdza bliskość) |
| `OnPlayerRespawn` (lub `OnPlayerDeath`) | `sys_on_respawn` (+25 bliskości po śmierci) |

Jeśli moduł już ma własne skrypty na te eventy, dołącz wywołania:
```nwscript
// W istniejącym sys_on_enter:
#include "lib_mac"
// ...
MacRegisterPlayer(oPC);
int nProx = MacGetProximity(oPC);
// (patrz sys_on_enter.nss po pełny kod)
```

## API — eksponowane funkcje

```nwscript
// Odczyt/zapis bliskości
int  MacGetProximity(object oPC);
void MacSetProximity(object oPC, int nProximity);
void MacAddProximity(object oPC, int nAmount);

// Otworzenie okna NUI gracza
void MacOpenWindow(object oPC);

// Wyslanie omenu + zapis do kroniki
void MacSendOmen(object oPC, int nProximity);

// Efekty po zmianie bliskości (Marked-by-Death + trigger bargain przy 100)
void MacApplyProximityEffects(object oPC, int nOldProximity, int nNewProximity);
```

### Przykłady wywołań z własnych skryptów

```nwscript
// Dodaj bliskość po użyciu czarnego zaklęcia
MacAddProximity(oPC, 5);
MacSendOmen(oPC, MacGetProximity(oPC));

// Przekaż efekt po użyciu klątwy/mrocznej mocy
int nOld = MacGetProximity(oPC);
MacAddProximity(oPC, 10);
MacApplyProximityEffects(oPC, nOld, MacGetProximity(oPC));
```

## Zależności

- **SQL**: `SqlPrepareQueryCampaign("danse_macabre", ...)` — tworzy plik `danse_macabre.sql` obok pliku `.mod`
- **NWNX**: nie wymagany
- **HAK**: nie potrzebne nowe assety; okno korzysta z wbudowanych NUI

## Testowanie

Ustaw placeable z tagiem `test_danse_macabre` i skrypt OnUsed `test_mac`.
Ustaw lokalną zmienną `mac_test_cmd` (string) na:
- `add` — +20 bliskości
- `max` — ustaw 100, otwórz bargain
- `reset` — zeruj bliskość
- (puste) — otwórz okno główne

## Pominięto celowo

- Graficzna ikona klepsydry/czaszki w tle (wymaga assetu w HAK)
- DM-command do ręcznego ustawiania bliskości gracza (łatwe do dodania przez `SetLocalInt`)
- Efekty wizualne/dźwiękowe przy pojawieniu się Śmierci (opcjonalne, przez `PlaySound` / `ApplyEffectToObject` VFX)
- Automatyczne zwiększanie bliskości co X minut (łatwe do dodania przez `DelayCommand` loop w `sys_on_enter`)

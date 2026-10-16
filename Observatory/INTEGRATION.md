# Celestial Observatory — Integration Guide

## Hooki modułu

| Hook                  | Skrypt              |
|-----------------------|---------------------|
| OnModuleLoad          | `sys_on_load.nss`   |
| OnClientEnter         | `sys_on_enter.nss`  |
| OnModuleHeartbeat     | `sys_on_hbeat.nss`  |

Jeśli moduł ma już własne hooki — wywołaj funkcje biblioteczne z istniejących skryptów:

```nss
// W OnModuleLoad:
#include "lib_obs_def"
ObsCreateTables();

// W OnClientEnter:
#include "lib_obs"
object oPC = GetEnteringObject();
if(GetIsPC(oPC)) { ObsRegisterPC(oPC); DelayCommand(3.0, ObsRestoreEffects(oPC)); }

// W OnModuleHeartbeat (jeden skrypt per hook — skrypt sys_on_hbeat.nss):
ExecuteScript("sys_on_hbeat", GetModule());
```

## Placeable obserwatorium

1. Umieść dowolny placeable (np. teleskop, kamienny krąg, wieża obserwacyjna).
2. Ustaw **OnUsed** → `test_obs`.
3. Żadnych dodatkowych tagów ani zmiennych nie potrzeba.

## Zależności

- **NWN:EE** (wymagane `TagEffect` / `RemoveEffectByTag`, NUI, `SqlPrepareQueryCampaign`).
- Brak zależności NWNX.
- Kampania SQLite: `observatory` (plik `observatory.sqlite3` w katalogu bazy danych serwera).

## Jak przetestować

1. Zacznij nowy moduł w Toolset lub zmodyfikuj istniejący.
2. Podepnij powyższe hooki.
3. Wrzuć dowolny placeable z `OnUsed = test_obs`.
4. Uruchom serwer, wejdź postacią, kliknij placeable → okno obserwatorium.
5. Aby szybko sprawdzić Zbieżność: ustaw czas modułu na dzień 14, godzina 12.

## Co celowo pominięto

- Brak trybu DM do ręcznego ustawiania konstelacji (można dodać konsolą: `SetCalendarAndTime(...)`).
- Brak animacji/VFX na placeable — sam placeable ma własny model.
- Brak możliwości zmiany znaku urodzenia po pierwszym odczycie (zamierzone: permanentność to rdzeń mechaniki).
- Brak automatycznego wygasania efektu odczytu po stronie serwera — efekt jest permanentny (tagged), ale przy następnym logowaniu nie zostanie przywrócony, jeśli minęły 2h. Opcjonalne rozszerzenie: wywołaj `ObsRemoveReadingEffect` w OnClientLeave.

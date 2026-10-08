# Morale — Instrukcja integracji

## Co to robi

Morale Bojowe to system trwałego duchowego stanu postaci.
Każda PC posiada wskaźnik Morale (0–100). Spada pod wpływem
terroru (nieumarli, ciemność, rany, przewaga wroga), rośnie
podczas odpoczynku i poprzez dobrowolne działania gracza.
Przy niskich wartościach postać traci premie do ataku i rzutów
obronnych; przy skrajnym strachu doznaje ataków paniki.

## Pliki

| Plik | Rola |
|------|------|
| `lib_mor_def.nss` | Stałe, ID bindów, ID przycisków, progi |
| `sql_mor.nss` | Schemat SQLite + zapytania (campaign DB `morale`) |
| `lib_mor.nss` | Cały rdzeń: logika, UI builder, heartbeat, efekty |
| `lib_mor_ev.nss` | Handler zdarzeń NUI |
| `sys_on_load.nss` | Init tabel przy starcie modułu |
| `sys_on_enter.nss` | Inicjalizacja PC + start heartbeatu |
| `sys_on_rest.nss` | Przywrócenie morale po odpoczynku |
| `test_mor.nss` | OnUsed na placeable — demo / tester |
| `lib_nui.nss` | Współdzielona biblioteka NUI (bez zmian) |
| `lib_nui_utility.nss` | Współdzielona biblioteka NUI (bez zmian) |

## Hooki do podpięcia w module

1. **OnModuleLoad** → `sys_on_load` (lub wywołaj `MorOnModuleLoad()` z istniejącego skryptu)
2. **OnClientEnter** → `sys_on_enter` (lub `MorInitPC(GetEnteringObject())`)
3. **OnPCRested** → `sys_on_rest` (lub `MorRestoreOnRest(GetLastPCRested())`)
4. **NUI Event Script** → `lib_mor_ev` (ustaw jako skrypt zdarzeń NUI dla okna `MOR_WINDOW`)

## Zależności

- **NWN EE 8193+** — wymaga `NuiCreate`, `NuiList`, `TagEffect`, `GetRacialType`
- **NWNX**: brak wymaganych rozszerzeń
- **Campaign DB**: `morale` (tworzona automatycznie przez `MorOnModuleLoad()`)

## Jak otworzyć okno

```nss
#include "lib_mor"
MorOpenWindow(oPC);
```

Można to wywołać z: rozmowy z NPC, menu postaci, itemu aktywowanego przez gracza,
lub placeable z `test_mor.nss`.

## Jak modyfikować morale ręcznie (z innych modułów)

```nss
#include "lib_mor"
// Dodaj lub odejmij morale:
MorSet(oPC, MorGet(oPC) - 10);
MorApplyPenalties(oPC);  // zaktualizuj aktywne efekty
```

## Opcjonalne: aura kleryka/paladyna

W skrypcie aury możesz wołać:
```nss
MorSet(oPC, MorGet(oPC) + 2);
```
każde 6 sekund dla pobliskich sojuszników — morale rośnie szybciej przy pobożnym towarzyszu.

## Co celowo pominięto

- Integracja z Ribbon System (ikona w ribbonie) — łatwa do dodania przez `RibbonSetIcon`.
- Wyświetlanie morale innych graczy — wymaga channel-writeback przez serwer.
- Różnicowanie terenu (bagna, krypty) — tag `MOR_DREAD_AREA` na obszarze wystarczy do rozbudowy.
- Leczenie przez zaklęcia Courage/Bless — wymaga wykrycia efektów zaklęć, które zależy od konkretnej implementacji serwera.

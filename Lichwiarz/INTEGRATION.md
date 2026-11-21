# Lichwiarz — Integracja z modułem

## Zależności
- **NWNX**: nie wymagane
- **NWN:EE**: wersja 1.87+ (wymagane `TagEffect` / `RemoveTaggedEffects`)
- **Kampania SQLite**: automatycznie tworzona jako `lichwiarz` w folderze kampanii

## Hooki do podpięcia

| Zdarzenie modułu      | Skrypt              | Uwagi                                          |
|-----------------------|---------------------|------------------------------------------------|
| OnModuleLoad          | `sys_on_load`       | Tworzy tabele SQLite (`CREATE TABLE IF NOT EXISTS`) |
| OnClientEnter         | `sys_on_enter`      | Nalicza brakujące ticki i przywraca kary       |
| Placeable → OnUsed    | `test_lch`          | Otwiera UI lichwiarza; podepnij pod dowolny NPC/placeable |

> Jeśli moduł ma już skrypty OnModuleLoad / OnClientEnter, wywołaj odpowiednie funkcje z istniejących skryptów:
> ```nss
> #include "lib_lch_def"
> // ...
> LchCreateTables();          // w OnLoad
> LchCheckAndApplyPenalties(GetEnteringObject());  // w OnClientEnter
> ```

## Tworzenie Egzekutora
Poziom kary 3 (dług ≥ 300% pożyczonej kwoty) spawnuje kreaturę o resref `lch_enforcer`.
Dodaj do haka kreaturę z tym resrefem — sugerowany blueprint: silny wojownik (CR 10+), uzbrojony, wrogie alignment. Jeśli brak resrefa, spawn jest pomijany (bez błędu).

## Uruchamianie testu
1. Załaduj moduł w Toolsecie (lub użyj istniejącego).
2. Umieść placeable (np. "Altar"), ustaw jego `OnUsed → test_lch`.
3. Uruchom moduł, najedź na placeable — otwiera się okno "LICHWIARZ — Dług i Fatum".
4. Pożycz złoto, odczekaj (lub ustaw `LCH_TICK_SECONDS = 60` dla szybkich testów), otwórz okno ponownie — dług wzrośnie.

## Pliki skryptów
```
Lichwiarz/scripts/
  sql_lch.nss          SQLite: schema + CRUD
  lib_lch_def.nss      Stałe, helpery gry (efekty, kary)
  lib_lch.nss          Budowa NUI, logika pożyczania/spłaty
  lib_lch_ev.nss       Handler zdarzeń NUI (main())
  sys_on_load.nss      OnModuleLoad: inicjalizacja tabeli
  sys_on_enter.nss     OnClientEnter: ticki i kary
  test_lch.nss         OnUsed: otwiera okno
  lib_nui.nss          Wspólna biblioteka NUI (kopia)
  lib_nui_utility.nss  Wspólna biblioteka NUI utils (kopia)
```

## Celowo pominięto
- GUI historii transakcji (logowanie spłat w osobnej tabeli)
- Możliwość ustawienia własnej stopy procentowej per-pożyczka przez DM
- Powiadomienie DM o aktywnych egzekutorach
- Timer heartbeat (ticki są lazy — naliczane przy otwarciu okna lub logowaniu)

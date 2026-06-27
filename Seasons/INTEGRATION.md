# Seasons — Koło Pór Roku

Integracja modułu w istniejącym projekcie NWN:EE.

## Hooki modułowe

| Zdarzenie modułu | Skrypt               | Uwagi                                      |
|------------------|----------------------|--------------------------------------------|
| OnModuleLoad     | `sys_on_load.nss`    | Tworzy tabele SQLite, startuje pętlę ticku |
| OnClientEnter    | `sys_on_enter.nss`   | Nakłada efekty pogody na wchodzącego PC    |
| OnNuiEvent       | `lib_sea_ev.nss`     | Obsługuje kliknięcia w oknach NUI          |

Jeśli moduł ma już skrypty hookujące, dodaj wywołania np.:
```
// W OnModuleLoad:
ExecuteScript("sys_on_load", GetModule());

// W OnClientEnter (na końcu istniejącego skryptu):
ExecuteScript("sys_on_enter", GetEnteringObject());

// W OnNuiEvent (dodaj do switcha lub na początku):
ExecuteScript("lib_sea_ev", OBJECT_SELF);
```

## Placeable testowy

1. Stwórz dowolny placeable (np. słup, wiatrowskaz).
2. Ustaw jego skrypt `OnUsed` na `test_sea`.
3. Gracze i DM mogą go kliknąć, by otworzyć okno informacyjne lub panel sterowania.

## SQLite / Baza danych

Moduł korzysta z `SqlPrepareQueryCampaign("seasons", ...)`.
Dane zapisywane są w kampanii o nazwie **seasons** — plik `seasons.sqlite3`
ląduje w katalogu danych użytkownika NWN (obok `nwnplayer.ini`).

Tabele:
- `sea_state(id, season, weather, season_changed, weather_changed)` — jedna wiersz, globalny stan serwera
- `sea_areas(area_tag, climate)` — strefy klimatyczne per obszar (tag obszaru)

## Zależności

- **NWN:EE ≥ 8193.15** — wymagane `TagEffect` / `GetEffectTag` oraz pełne API NUI.
- Brak NWNX. Brak zewnętrznych bibliotek.

## Jak przetestować

1. W toolsecie lub skryptem DM ustaw skrypt `OnModuleLoad = sys_on_load`.
2. Zaloguj się jako gracz → sprawdź wiadomość `[Klimat]` w konsoli.
3. Zaloguj się jako DM i kliknij placeable → pojawi się panel kontrolny.
4. Naciśnij `>` obok "Pogoda" i zmień na "Zamieć" → gracze na zewnątrz otrzymają kary i obrażenia zimnem co minutę.
5. Kliknij klimat "Arktyczny" dla bieżącego obszaru → kolejna automatyczna zmiana pogody preferuje Zamieć/Śnieg.

## Co celowo pominięto

- Brak własnych modeli/ikon pogodowych w hak — można dodać `sea_icon_*.tga` i odwoływać się przez stałą w `lib_sea_def`.
- Brak per-PC ubrania/ekwipunku redukującego kary pogodowe (ciepłe ubrania) — warstwa rozszerzenia.
- Brak efektów wizualnych obszarowych (deszcz, śnieg) — wymagałoby NWNX lub dedykowanych area-VFX.
- Brak komendy `/pogoda` — można dodać przez hook `OnPlayerChat`.

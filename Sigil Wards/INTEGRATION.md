# Sigil Wards — Integracja z modułem

## Wymagania

- NWN:EE 8193.36+ (NUI, SqlPrepareQueryCampaign)
- Brak zależności NWNX
- Brak niestandardowych zasobów HAK (wizualne efekty używają stockowych VFX)

## Hooki do podłączenia

| Zdarzenie modułu | Skrypt         |
|------------------|----------------|
| OnModuleLoad     | `sys_on_load`  |
| OnClientEnter    | `sys_on_enter` |
| OnHeartbeat      | `sys_on_hb`    |

> Jeśli inne systemy używają tych zdarzeń, wywołaj funkcje `SglXxx` z istniejącego hooka
> zamiast nadpisywać skrypt. Wszystkie pliki `sys_on_*.nss` są cienkie i jednolinijkowe.

## Otwieranie panelu gracza

Umieść placeable w module (np. „Tablica Znaków Ochronnych"), ustaw jego skrypt
`OnUsed = test_sgl`. Alternatywnie wywołaj `CreateSglWindow(oPC)` z dowolnego miejsca
w kodzie — np. komendy czatu, zdarzenia itemu, rozmowy z NPC.

```nss
#include "lib_sgl"

void main()
{
    CreateSglWindow(GetPCSpeaker());
}
```

## Baza danych

Dane są przechowywane w Campaign DB o nazwie `sigil_wards`. Skrypt `sys_on_load`
tworzy tabele idempotentnie (`CREATE TABLE IF NOT EXISTS`). Nie trzeba
nic robić ręcznie — pierwsze uruchomienie modułu zakłada schemat.

Tabele:
- `sgl_sigils` — aktywne znaki (właściciel, obszar, współrzędne, typ, ładunki)
- `sgl_attuned` — uprawnienia dostępu per znak
- `sgl_players` — rejestr graczy (do wyszukiwania w panelu dostępu)

## Mechanika sprawdzania bliskości

`sys_on_hb` uruchamia `SglCheckProximity()` co ~18 sekund (co 3. tik
heartbeat = co 3 × 6 s). Funkcja zapytuje SQL o wszystkie aktywne znaki,
iteruje graczy online i porównuje dystans. Jeśli gracz jest bliżej niż
`SGL_TRIGGER_RADIUS` (domyślnie 4,5 m) i nie jest właścicielem ani
uprawnionym, znak wyzwala efekt i traci jeden ładunek.

Cooldown 30 sekund (local int na graczu) zapobiega wielokrotnemu
wyzwalaniu tego samego znaku przy staniu w miejscu.

## Konfiguracja

Stałe dostępne do zmiany w `lib_sgl_def.nss`:

| Stała                 | Domyślnie | Opis                                    |
|-----------------------|-----------|-----------------------------------------|
| `SGL_MAX_SIGILS`      | 5         | Maks. aktywnych znaków na gracza        |
| `SGL_TRIGGER_RADIUS`  | 4.5       | Promień wyzwalania (metry)              |
| `SGL_HB_MODULO`       | 3         | Sprawdzenie co N heartbeatów (~18 s)   |
| `SGL_COOLDOWN_SECONDS`| 30        | Cooldown retrigera dla tej samej pary  |
| `SGL_MAX_ATTUNED`     | 10        | Maks. uprawnionych na znak              |

Ładunki per typ (w `sql_sgl.nss`):

| Typ            | Ładunki | Efekt                              |
|----------------|---------|------------------------------------|
| Alarm          | 10      | Powiadomienie; brak obrażeń        |
| Porażenie      | 5       | 1k8 obrażeń elektrycznych          |
| Unieruchomienie| 3       | Paraliż 6 sekund                   |
| Trwoga         | 5       | Przerażenie 8 sekund               |

## Efekty wizualne lokalizacji

Przy umieszczeniu znaku i po restarcie serwera (`SglRestoreVisuals`) skrypt
aplikuje `VFX_DUR_PROT_PREMONITION` jako tymczasową poświatę (1 godzina).
Efekty nie są persystentne między restartami — są odtwarzane przy każdym
załadowaniu modułu. Przy dużej liczbie aktywnych znaków i częstych
restartach można wyłączyć `SglRestoreVisuals()` z `sys_on_load` bez utraty
danych (znaki w SQL nadal działają).

## Celowo pominięto

- HAK / nowe assety — brak własnych ikon i tekstur; moduł działa na stockowych VFX
- DM-panel do podglądu wszystkich znaków na mapie
- Wyszukiwarka offline-graczy w panelu dostępu (widoczni tylko zalogowani gracze)
- Item „kreda sygilów" jako wymóg użycia (prosty do dodania: sprawdzenie inventarza
  w `SglPlaceAtLocation` przed insertem do SQL)
- Ograniczenie do konkretnych ras/klas (można sprawdzić `GetRacialType` w `SglPlaceAtLocation`)

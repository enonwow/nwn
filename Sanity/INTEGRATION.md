# Sanity — Integration Guide

## Wymagane hooki modułu

Podłącz skrypty do odpowiednich zdarzeń modułu w Toolset / skrypcie init:

| Zdarzenie modułu | Skrypt |
|---|---|
| OnModuleLoad | `sys_on_load` |
| OnClientEnter | `sys_on_enter` |
| OnHeartbeat | `sys_on_heartbeat` |
| OnPlayerRest | `sys_on_rest` |
| OnNUIEvent | `lib_san_ev` |
| OnActivateItem *(opcjonalne)* | wywołaj `SanOnActivateItem(oPC, oItem)` |

Jeśli masz już własne skrypty na tych zdarzeniach, dodaj wywołania inline:

```nss
// przykład — istniejący sys_on_enter.nss:
#include "lib_san"
// ... twój kod ...
SanOnPlayerEnter(GetEnteringObject());
```

## Zależności

- **NWN:EE 8193.36+** — wymaga NUI (TagEffect, SqlPrepareQueryCampaign).
- **NWNX**: nie jest wymagane.
- **Hak**: żaden — moduł nie używa własnych zasobów graficznych.

## Baza danych

Kampania SQLite `"sanity"` (pliki `sanity.db` w katalogu serwera).
Tabele tworzone automatycznie przy starcie modułu (idempotentne `CREATE TABLE IF NOT EXISTS`).

## Demo — szybki test w Toolset

1. Dodaj placeable z tagiem `san_mirror`, OnUsed → `test_san`.
2. Dodaj placeable z tagiem `san_altar_dark`, OnUsed → `test_san`.
3. Dodaj placeable z tagiem `san_font_holy`, OnUsed → `test_san`.
4. Uruchom moduł. Kliknij **Lustro** — otworzy okno "Stan Psychiczny".
5. Kliknij **Czarny Ołtarz** kilkakrotnie — obserwuj spadek wartości i efekty.
6. Kliknij **Święte Źródło** — odbudowa.
7. Testuj **Medytuj** (przycisk w oknie; cooldown 120 s).

## Przeklęte obszary

Aby oznaczyć obszar jako strefę horroru (pasywna utrata co ~3 min):

```nss
SetLocalInt(oArea, "SAN_HORROR_AREA", 1);
```

Można ustawić w OnEnter obszaru lub przez Toolset → Properties → Variables.

## Stała konfiguracja (lib_san_def.nss)

| Stała | Domyślnie | Opis |
|---|---|---|
| `SAN_THR_UNEASE` | 75 | Próg "Niepokój" |
| `SAN_THR_HORROR` | 50 | Próg "Groza" |
| `SAN_THR_MADNESS` | 25 | Próg "Obłęd" |
| `SAN_THR_INSANITY` | 10 | Próg "Szaleństwo" |
| `SAN_COOLDOWN_MEDITATE` | 120 | Cooldown medytacji (sekundy) |
| `SAN_GAIN_REST` | 15 | Odbudowa po odpoczynku |
| `SAN_GAIN_MEDITATE` | 5 | Odbudowa przez medytację |
| `SAN_GAIN_HOLY` | 10 | Odbudowa przez święconą wodę |
| `SAN_LOSS_UNDEAD` | 3 | Utrata przy nieumarłych |
| `SAN_LOSS_NEAR_DEATH` | 5 | Utrata przy bliskiej śmierci |
| `SAN_LOSS_ALLY_DEATH` | 8 | Utrata przy śmierci sojusznika |

## Święcona woda

Przedmiot z tagiem `san_holy_water`. Wywołaj `SanOnActivateItem(oPC, oItem)`
z hooka `OnActivateItem` — item zostaje zniszczony po użyciu.

## Co celowo pominięto

- **Brak pliku .mod** — środowisko kompilacji NWN nie jest dostępne; patrz sekcja Demo powyżej.
- **Brak obsługi śmierci sojusznika jako hooka** — `SanOnAllyDeath` jest zaimplementowane w `lib_san.nss`; builder sam podłącza je do zdarzenia śmierci creatury (`OnDeath`) lub `OnPlayerDeath`.
- **Brak widgetów "szumu wizualnego"** (nakładki DrawList na ekran) — wymagałoby dedykowanego haka graficznego.
- **Brak ikonki notyfikacji (tray)** — intencjonalnie; informacja przekazywana przez floating text i wiadomość systemową.

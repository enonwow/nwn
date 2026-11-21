# Wróżbiarstwo (Divination) — Integracja

## Wymagania

- NWN EE (Enhanced Edition) — wymagane dla NUI, TagEffect, GetEffectTag
- Brak NWNX — moduł działa wyłącznie na czystym NWScript + SQLite

## Hooki do podpięcia

| Zdarzenie modułu | Skrypt       | Opis                                               |
|------------------|--------------|----------------------------------------------------|
| OnModuleLoad     | sys_on_load  | Tworzy tabelę `div_players` w bazie `divination`  |
| OnClientEnter    | sys_on_enter | Rejestruje gracza, odnawia aktywne efekty kart     |
| OnClientLeave    | sys_on_leave | Czyści tymczasowe zmienne sesji                   |

Jeśli w module istnieją już własne skrypty dla tych hooków, dołącz
odpowiednie `#include "..."` i wywołaj funkcje:

```nss
// W istniejącym OnModuleLoad:
#include "sql_div"
// ...
DivInitTables();

// W istniejącym OnClientEnter:
#include "lib_div"
// ...
DivEnsureRow(oPC);
DivReapplyPersistentEffects(oPC);

// W istniejącym OnClientLeave:
#include "lib_div_def"
// ...
DeleteLocalJson(oPC, DIV_LVAR_CARDS);
DeleteLocalInt(oPC, DIV_LVAR_REVEALED);
DeleteLocalInt(oPC, DIV_LVAR_CARDCNT);
DeleteLocalInt(oPC, DIV_LVAR_LASTCARD);
```

## Placeable do testu

1. Umieść dowolny placeable (stół, skrzynia, ołtarz) na scenie.
2. Ustaw jego skrypt `OnUsed` na `test_div`.
3. Gracz klika placeable → otwiera się okno Wróżbiarstwa.

## Pliki skryptów do skopiowania do hak/.mod

```
lib_div_def.nss
lib_div.nss
lib_div_ev.nss
sql_div.nss
lib_nui.nss
lib_nui_utility.nss
sys_on_load.nss
sys_on_enter.nss
sys_on_leave.nss
test_div.nss
```

## Baza danych

Kampania: `divination`
Tabela: `div_players`

| Kolumna          | Typ     | Opis                                          |
|------------------|---------|-----------------------------------------------|
| uuid             | TEXT PK | UUID gracza (GetObjectUUID)                  |
| char_name        | TEXT    | Imię postaci (czytelność logów)              |
| last_reading_at  | INTEGER | Unix epoch ostatniego odczytania             |
| effects_json     | TEXT    | JSON array aktywnych pieczęci + expiry        |
| total_readings   | INTEGER | Łączna liczba odczytań (statystyki)          |

Format `effects_json`:
```json
[
  { "card_id": 4, "expires_at": 1746700000 },
  { "card_id": 9, "expires_at": 1746710000 }
]
```

## Mechanika — skrót

- **Małe Odczytanie**: 3 karty, 50 złota, cooldown 24h
- **Wielkie Odczytanie**: 5 kart, 150 złota, cooldown 24h
- **Cooldown** wspólny dla obu rodzajów — jedno odczytanie dziennie
- Gracz klika każdą kartę by ją odsłonić; efekty widoczne przed akceptacją
- **Przyjmij Los** — aplikuje efekty i zapisuje w SQLite
- **Anuluj** — wraca bez efektów, złoto przepadło (los nie cofa)
- Po zalogowaniu wszystkie aktywne pieczęcie są automatycznie odnawiane

## Co celowo pominięto

- Animacja „odwracania kart" — NUI nie wspiera animacji tweening bez NWNX
- Grafiki kart — brak obrazków w hak; nazwy wystarczą dla klimatu
- System „złej wróżbitki" karzącej za wielokrotne odmowy — wymagałby dodatkowego NPCdialog systemu
- Integracja z innymi modułami (np. Pantheon) — każdy moduł pozostaje samodzielny

# Cmentarz — Instrukcja integracji

## Opis modułu

System pogrzebu i grabieży grobów. Gracze mogą grzebać poległych wrogów lub
postacie NPC, zdobywając walutę „Łaska Kości" (ŁK). Za ŁK grabarz udziela
tymczasowych błogosławieństw. Zbezczeszczenie grobów przynosi złoto, ale
nakłada trwałe klątwy (Piętno Zbezczeszczenia).

## Hooki do podpięcia

| Zdarzenie                  | Skrypt            |
|----------------------------|-------------------|
| OnModuleLoad               | `sys_on_load`     |
| OnClientEnterArea          | `sys_on_enter`    |
| OnUsed (placeable Głaz)    | `test_grv`        |

## Tworzenie placeabli testowych

### 1. Cmentarny Głaz (otwiera okno pochówku)
- Typ: dowolny placeable (np. Altar, Gravestone)
- Tag: `GRV_BURIAL_STONE` (lub cokolwiek — skrypt sprawdza OnUsed)
- Script OnUsed: `test_grv`

### 2. Grób do zbadania
- Tag: `GRV_TEST_GRAVE`
- Local Int `GRV_GRAVE_ID` = ID z tabeli `grv_graves` (po pierwszym pochówku = 1)
- Script OnUsed: `test_grv`

## Baza danych SQLite

Moduł używa kampanii o nazwie `graveyard`. Tabele tworzone automatycznie
przez `sys_on_load`:

- `grv_graves` — każdy grób: właściciel, imię zmarłego, typ, złoto, data, flaga zbezczeszczenia
- `grv_players` — per-gracz: Łaska Kości, Piętno Zbezczeszczenia
- `grv_pray_log` — czas ostatniej modlitwy przy danym grobie (cooldown 24h)

## Zależności NWNX

**Brak.** Moduł nie wymaga żadnych pluginów NWNX. Używa wyłącznie NWN:EE API:
- `NuiCreate`, `NuiBind`, `NuiList` — system NUI
- `SqlPrepareQueryCampaign` — SQLite campaign DB
- standardowe efekty (`EffectSavingThrowDecrease`, `EffectImmunity`, itp.)

## Konfiguracja równowagi (w `lib_grv_def.nss`)

| Stała                     | Domyślnie | Opis                              |
|---------------------------|-----------|-----------------------------------|
| `GRV_GOLD_MOUND`          | 0         | Koszt pochówku Mogily             |
| `GRV_GOLD_STONE`          | 50        | Koszt Kamiennego Nagrobka         |
| `GRV_GOLD_CRYPT`          | 200       | Koszt Krypty Szlacheckiej         |
| `GRV_GRACE_MOUND`         | 1         | ŁK za Mogiłę                     |
| `GRV_GRACE_STONE`         | 3         | ŁK za Nagrobek                   |
| `GRV_GRACE_CRYPT`         | 10        | ŁK za Kryptę                     |
| `GRV_GHOST_GOLD_MIN`      | 50        | Min złoto ofiarne dla ducha       |
| `GRV_GHOST_CHANCE_BASE`   | 25        | Bazowa szansa (%) na ducha        |
| `GRV_DESEC_CURSE_THRESHOLD`| 5        | Piętno przed klątwą słabą         |
| `GRV_DESEC_HEAVY_THRESHOLD`| 10       | Piętno przed klątwą ciężką        |

## Sklep Grabarza — błogosławieństwa

| Nazwa                    | Koszt | Efekt                                |
|--------------------------|-------|--------------------------------------|
| Pokora Kości             | 3 ŁK  | Leczenie 2k8 HP (natychmiastowe)     |
| Pieczęć Przed Zepsuciem  | 5 ŁK  | +2 AC (Dodge), 8 godzin              |
| Wzrok Przez Zasłonę      | 8 ŁK  | True Seeing, 1 godzina               |
| Tarcza Przed Śmiercią    | 15 ŁK | Odporność na śmierć i neg. poziomy, 1h|
| Rozgrzeszenie            | 10 ŁK | Usuwa 1 Piętno Zbezczeszczenia (1/dobę)|

## Co celowo pominięto

- **Spawning fizycznych towarzyszy (duchy)**: Duch pochówku manifestuje się
  jako tymczasowy efekt mechaniczny (+1 do ataków i rzutów, 30 min).
  Prawdziwe creature-companion wymagałoby NWNX_Companion lub ręcznej
  konfiguracji AI placeable'a — wykracza poza zakres demo.
- **Zlokalizowane placeables grobów na mapie**: Moduł zapisuje groby w DB,
  ale nie spawna placeabli przy lokacji pochówku. W pełnej integracji:
  po `GrvInsertGrave` wywołaj `CreateObject(OBJECT_TYPE_PLACEABLE, "grv_grave_stone", loc)`
  z LocalInt `GRV_GRAVE_ID = nGraveId` i OnUsed = `test_grv`.
- **Limit grobów per obszar**: Nie ma cap'u na liczbę grobów. W dużym
  module warto dodać `COUNT(*) FROM grv_graves WHERE area_resref = @area`.
- **Eksportowanie listy grobów**: Nie ma widoku „Lista wszystkich grobów
  w obszarze" — taki feature wymagałby dodatkowego okna NUI z NuiList.

# Honor Duels — integracja

System honorowych pojedynkow PvP z konfiguracja regul, stawkami w zlocie,
arena ograniczona miejscem wyzwania i rankingiem honoru.

## Co dostajesz

- Tablica honoru (placeable -> NUI z 3 zakladkami: Wyzwania / Historia / Ranking).
- Wyzwanie w trybie targetingu z wyborem przeciwnika.
- Konfiguracja przed wyslaniem: warunek zwyciestwa (pierwsza krew / na smierc /
  do poddania), reguly (bez magii, bez mikstur, bez krytykow), stawka w zlocie.
- Popup u wyzwanego: przyjmij / odrzuc.
- Odliczanie 5s, automatyczne ustawienie wrogosci tymczasowej, HUD z paskami HP.
- Tick co 1s: sprawdza HP, granice areny (10m), warunki zwyciestwa.
- Forfeit za ucieczke (>6s poza arena) lub poddanie sie.
- Honor: +10 wygrana, -3 porazka, -15 odmowa, -25 forfeit, +5 bonus za smiertelny cios.
- Stawka: zwyciezca zabiera obie polowy, remis = zwrot.
- Persystencja: SQLite (campaign-scope, baza "duel").

## Wymagania

- NWN:EE (NUI + JSON API).
- Brak NWNX (czysty NWScript).

## Podpiecie hookow modulu

W plikach swojego modulu wlacz (lub dodaj) odpowiednie wywolania:

### `OnModuleLoad`
```nwscript
ExecuteScript("sys_on_load", OBJECT_SELF);
```
Tworzy schemat SQL i czysci wygasle wyzwania.

### `OnClientEnter`
```nwscript
ExecuteScript("sys_on_enter", OBJECT_SELF);
```
Rejestruje gracza w tabeli honoru i pokazuje liczbe oczekujacych wyzwan.

### `OnPlayerTarget`
```nwscript
ExecuteScript("sys_on_target", OBJECT_SELF);
```
Obsluguje wybor przeciwnika po klikniecu "Rzuc rekawice".
Jezeli juz uzywasz `sys_on_target` z innego modulu (np. Mailbox, Spell Macro),
polacz logike: wywolaj kazdy z handlerow lub dodaj wlasny dispatcher.

## Otwarcie tablicy honoru

Na placeable typu "tablica honoru" / "rynek miejski" / podpis na ladnym sztandarze:
```nwscript
// OnUsed:
#include "lib_duel"
void main()
{
    object oPC = GetLastUsedBy();
    if(!GetIsPC(oPC)) return;
    CreateDuelMainWindow(oPC);
}
```
(rownowazne `test_duel.nss` zalaczone w module).

## Uwagi projektowe

- **Arena** to lokalizacja wyzywajacego w momencie utworzenia wyzwania.
  Promien 10m. Wyzwany musi stawic sie w 1.5x promienia, by przyjac.
- **Reguly bez_magii / bez_mikstur / bez_krytykow** sa zapisywane i wyswietlane,
  ale ich egzekucja (blokada rzucania, blokada uzycia itemu, neutralizacja
  krytyka) nie jest zaszyta w tej wersji — wymaga hookow OnSpellCastAt /
  OnUseItem. Zostawione jako rozszerzenie.
- **Wrogosc** ustawiana przez `SetIsTemporaryEnemy` / `SetIsTemporaryNeutral`.
  Inni gracze nie sa blokowani od interwencji — w docelowym serwerze wprowadz
  zone PvP lub zakaz przez OnPhysicalAttacked.
- **Stawka offline:** jezeli wyzywajacy wyloguje sie przed odpowiedzia,
  zlote idzie w zapomnienie (limit MVP). Realny serwer powinien zwracac przez
  Mailbox.
- **Smiertelny cios** liczony tylko przy warunku TO_DEATH; pierwsza krew i
  poddanie nie zwiekszaja licznika `kills`.

## Pliki

| Plik                  | LOC | Rola                                        |
|-----------------------|----:|---------------------------------------------|
| `lib_duel_def.nss`    | 240 | Stale, statusy, reguly, layout, helpery.    |
| `sql_duel.nss`        | 339 | Schemat (duels + duel_honor) + CRUD.        |
| `lib_duel_flow.nss`   | 526 | State machine: submit/accept/decline/begin/ |
|                       |     | tick/yield/end + honor i stawka.            |
| `lib_duel_ui.nss`     | 290 | Glowne okno (3 zakladki) + feedy listy.     |
| `lib_duel_hud.nss`    | 250 | HUD aktywnego pojedynku + popup wyzwania +  |
|                       |     | popup konfiguracji wyzwania.                |
| `lib_duel_ev.nss`     | 230 | Router eventow NUI dla 4 okien.             |
| `lib_duel.nss`        |  35 | Fasada (#include + DuelStartChallengeTargeting). |
| `sys_on_load.nss`     |   6 | Init schematu + expire.                     |
| `sys_on_enter.nss`    |  16 | Rejestracja honoru + powiadomienie.         |
| `sys_on_target.nss`   |  10 | Targeting -> popup konfiguracji.            |
| `test_duel.nss`       |   7 | Otwarcie tablicy honoru z placeable.        |
| `lib_nui.nss`         | 108 | Pomocnicza warstwa NUI (kopia z Mailbox).   |
| `lib_nui_utility.nss` |  98 | Pomocnicza warstwa NUI (kopia z Mailbox).   |

## Co celowo pominieto (do rozwazenia w v2)

- Egzekucja regul (no_magic / no_items / no_crit) wymaga hookow OnSpellCastAt
  i OnUseItem — duzy refactor poza zakres.
- Sekundanci / swiadkowie.
- Animacje powitalne (sklon, salut mieczem) — wymaga `PlayAnimation` w
  `DuelBegin` ale moze sie gryzc z gotowoscia bojowa.
- Zone PvP (blokada interwencji innych graczy).
- Zwrot stawki przez Mailbox dla offline'owych graczy.
- HAK z grafika tla do glownego okna i ikona tablicy honoru.

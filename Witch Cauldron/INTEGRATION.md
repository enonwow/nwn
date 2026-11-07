# Witch Cauldron — Integracja z modułem

## Wymagania

- NWN:EE 8193.36.3 lub nowszy (NUI, `SqlPrepareQueryCampaign`, `EnterTargetingMode`)
- NWNX: **brak** — moduł działa na czystym NWN:EE

## Pliki

| Plik | Rola |
|---|---|
| `sql_wca.nss` | Schemat SQLite + zapytania |
| `lib_wca_def.nss` | Stałe, katalog receptur, helpery slotów |
| `lib_wca.nss` | Logika UI, warzenie, targeting |
| `lib_wca_ev.nss` | Handler zdarzeń NUI (`NuiGetWindowId() == WCA_WINDOW`) |
| `sys_on_load.nss` | Inicjalizacja tabel — podepnij do `OnModuleLoad` |
| `sys_on_enter.nss` | Powiadomienie gracza — podepnij do `OnClientEnter` |
| `sys_on_target.nss` | Routing targetingu — podepnij do `OnPlayerTarget` |
| `test_wca.nss` | Demo OnUsed dla kocioł-placeable |
| `lib_nui.nss` | Wspólne helpery NUI (kopia) |
| `lib_nui_utility.nss` | Wspólne helpery NUI (kopia) |

## Hooki modułu

W **Properties > Scripts** modułu:

| Event | Akcja |
|---|---|
| `OnModuleLoad` | Wywołaj `WcaCreateTables()` lub skopiuj ciało `sys_on_load.nss` do istniejącego ładowania |
| `OnClientEnter` | Wywołaj kod z `sys_on_enter.nss` |
| `OnPlayerTarget` | Przekaż do `WcaOnPlayerTarget(oPC)` gdy okno `WCA_WINDOW` jest otwarte |
| `OnNuiEvent` | Wywołaj `main()` z `lib_wca_ev.nss` gdy `NuiGetWindowId() == WCA_WINDOW` |

Przykład scalenia z istniejącym `OnNuiEvent`:
```nss
// w istniejącym on_nui_event.nss
void main() {
    string sWin = NuiGetWindowId();
    if(sWin == WCA_WINDOW) { ExecuteScript("lib_wca_ev", OBJECT_SELF); return; }
    // ... inne moduły
}
```

## Przedmioty (item blueprints)

Utwórz w palecie przedmiotów (Items > Custom) po jednym `.uti` dla każdego tagu:

### Składniki (Miscellaneous)
| Tag | Nazwa PL |
|---|---|
| `wca_mandrake` | Korzeń Mandragory |
| `wca_nightshade` | Wilcza Jagoda |
| `wca_bloodmoss` | Skrzepły Mech |
| `wca_gravesoil` | Ziemia z Grobu |
| `wca_bonethorn` | Ciernista Kość |
| `wca_shadowfern` | Czarna Paproć |
| `wca_hellbane` | Płomyk Piekielny |
| `wca_specter_ash` | Popiół Widmy |
| `wca_bat_wing` | Skrzydło Nietoperza |
| `wca_wolfbane` | Tojad Wilczy |

### Produkty (wynik warzenia)
| Tag | Nazwa PL | Zalecany typ bazowy |
|---|---|---|
| `wca_hex_bag` | Worek Klątwy | Miscellaneous |
| `wca_curse_oil` | Przeklęty Olejek | Potion (bez efektu) |
| `wca_dark_fetish` | Mroczny Fetysz | Miscellaneous |
| `wca_despair_vial` | Fiolka Rozpaczy | Potion (bez efektu) |
| `wca_ward_breaker` | Krucha Nić Ochrony | Miscellaneous |

> Produkty mogą mieć skrypt `OnActivate` z efektami mechanicznymi wedle uznania
> budowniczego. Moduł tworzy je przez `CreateItemOnObject(sResref, oPC, 1)`;
> jeśli blueprint nie istnieje, tworzy placeholder `nw_it_novel001` z nazwą receptury.

### Tomy (nauka receptur)
| Tag | Odblokowana receptura |
|---|---|
| `wca_tome_0` | Worek Klątwy |
| `wca_tome_1` | Przeklęty Olejek |
| `wca_tome_2` | Mroczny Fetysz |
| `wca_tome_3` | Fiolka Rozpaczy |
| `wca_tome_4` | Krucha Nić Ochrony |

Podepnij skrypt `OnActivate` tomu: `WcaOnReadTome(oPC, oTome)` z `lib_wca.nss`.
Alternatywnie wywołaj `WcaLearnRecipe(oPC, nId)` bezpośrednio z dialogu NPC.

> Receptura 0 (Worek Klątwy) jest nadawana automatycznie przy pierwszym wejściu
> gracza do modułu (patrz `sys_on_enter.nss`).

## Placeable kocioł

1. Utwórz lub wybierz placeable (np. `plc_pot` lub model z HAK).
2. Przypisz `test_wca.nss` do zdarzenia `OnUsed`.
3. Ustaw tag dowolny (np. `witchcauldron_01`).
4. W produkcji zamień `test_wca.nss` na skrypt, który wywołuje tylko
   `WcaOpenWindow(oPC, OBJECT_SELF)` bez rozdawania przedmiotów testowych.

## Baza danych

Kampania SQLite: `witch_cauldron.sqlite` (tworzona automatycznie).

| Tabela | Zawartość |
|---|---|
| `wca_known_recipes` | Które receptury zna dany gracz (UUID × recipe_id) |
| `wca_brew_log` | Historia każdego warzenia (UUID, recipe_id, success, timestamp) |

## Co celowo pominięto

- **Efekty mechaniczne produktów** — każdy produkt to placeholder; budowniczy
  definiuje efekty w `OnActivate` przedmiotu stosownie do mechanik swojego modułu.
- **Zbieranie składników z terenu** — składniki w produkcji powinny być dropem
  potworów lub skrytkami; moduł nie wymusza sposobu dystrybucji.
- **Multiplikacja kotłów** — każdy gracz może mieć okno otwarte tylko raz
  (`NuiFindWindow`); wiele kotłów w module działa bez zmian.
- **Cooldown na warzenie** — można dodać przez kolumnę `last_brewed_at` w DB.

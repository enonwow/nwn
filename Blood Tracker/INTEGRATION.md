# Blood Tracker — Instrukcja integracji

## Hooki wymagane

| Zdarzenie modułu | Skrypt         | Uwagi |
|------------------|----------------|-------|
| OnModuleLoad     | sys_on_load    | Tworzy tabele SQLite |
| OnHeartbeat      | sys_on_hb      | Śledzi HP graczy, odpada stare ślady, odświeża UI |

## Otwieranie UI

Wywołaj `BtrkOpen(oPC)` z dowolnego skryptu (np. OnUsed na placeable, rozmowa z NPC):

```nwscript
#include "lib_btrk"
void main()
{
    BtrkOpen(GetPCSpeaker());
}
```

## Ślady NPC

**Bez NWNX:** Przypisz `sys_on_dmg` jako `OnDamaged` na wybranych kreaturach
(przez Toolset lub spawn-script). Krew zostawiana jest tylko przez te stworzenia.

**Z NWNX_Events:** W `sys_on_load.nss` dodaj globalną rejestrację zdarzenia:

```nwscript
#include "nwnx_events"
void main()
{
    BtrkCreateTables();
    NWNX_Events_SubscribeEvent("NWNX_ON_CREATURE_DAMAGE_AFTER", "sys_on_dmg_nx");
}
```

Stwórz `sys_on_dmg_nx.nss`:

```nwscript
#include "lib_btrk"
#include "nwnx_events"
void main()
{
    object oTarget = OBJECT_SELF;
    if(GetIsPC(oTarget)) return;
    int nDmg = StringToInt(NWNX_Events_GetEventData("DAMAGE_TOTAL"));
    BtrkDropTrail(oTarget, nDmg);
}
```

## SQL — baza danych

Dane zapisywane są w kampanii `blood_tracker` (dwa pliki: `blood_tracker.sqlite`
w katalogu `<module>/` lub standardowym katalogu kampanii NWN).

Tabele:
- `blood_trails` — aktywne ślady z lokalizacją, źródłem, TTL
- `btrk_discoveries` — historia odkryć per gracz (żeby nie liczyć tego samego śladu dwa razy)

## Testowanie

1. Umieść placeable z `OnUsed = test_btrk` w module.
2. Uruchom moduł, kliknij placeable — pojawi się UI i 3 testowe ślady.
3. Aktywuj tropienie → Szukaj Śladów → sprawdź kierunek i wpisy dziennika.
4. Zranij postać (strata ≥ 5 HP) — heartbeat po ≤6 s wstawi ślad do bazy.

## Co celowo pominięto

- Wizualne markery 3D (efekty VFX na ziemi) — wymagają haka z animowanym placeable lub NWNX_Object
- Reagowanie na wejście w odległość śladu automatycznie (bez kliknięcia) — wymagałoby persistentnego AoE lub tick-based proximity check per tracker
- Persistentne statystyki (liczba odkrytych śladów, rekordy) — łatwe do dodania przez kolejną tabelę SQL

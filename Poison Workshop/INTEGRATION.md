# Wytwórnia Trucizn — Integracja z modułem NWN

## Wymagania

- NWN:EE (1.69+)  
- Brak NWNX — moduł działa na czystym NWScript + SQLite  
- Kampania SQLite o nazwie `"poi"` tworzona automatycznie przez `sys_on_load.nss`

## Hooki do podpięcia

| Zdarzenie modułu       | Skrypt                 |
|------------------------|------------------------|
| OnModuleLoad           | `sys_on_load.nss`      |
| OnClientEnter          | `sys_on_enter.nss`     |
| OnPlayerTarget         | `sys_on_target.nss`    |

Jeśli inne moduły już zajmują `OnClientEnter` / `OnPlayerTarget`, wywołaj
funkcje z tego modułu wewnątrz swoich istniejących handlerów:

```nss
// w swoim OnClientEnter:
#include "lib_poi"
// (...)
// Na końcu handlera:
if(GetIsPC(GetEnteringObject()))
{
    // opcjonalne powiadomienie o fiolkach
}

// w swoim OnPlayerTarget:
#include "lib_poi"
// (...)
if(GetLocalInt(GetLastPlayerToSelectTarget(), POI_LVAR_PENDING) > 0)
    PoiOnWeaponTarget(GetLastPlayerToSelectTarget());
```

## Placeable testowy

Stwórz dowolny placeable (stół, kocioł, ołtarz) i ustaw mu `OnUsed = test_poi`.  
Przy pierwszym użyciu postać dostaje po 3 sztuki każdego składnika.

## Składniki w świecie gry

Składniki nie są itemami — system śledzi stany w SQLite.  
Aby gracz mógł zdobywać składniki w świecie, dodaj trigger/skrypt
`OnContainerOpen` do skrzyni lub OnDeath do potwora:

```nss
#include "lib_poi"
// Przykład: potwór miecznik porzuca po śmierci 1x Worek Jadu Pająka
PoiModifyStock(GetLastKiller(), POI_ING_SPIDER, 1);
SendMessageToPC(GetLastKiller(), "[Trucizny] Znaleziono: Worek Jadu Pająka.");
```

## Trucizny i efekty broni

Trucizna nałożona na broń działa **120 sekund** od momentu naniesienia.
Implementacja opiera się na `AddItemProperty(DURATION_TYPE_TEMPORARY, ...)`,
więc efekt automatycznie gaśnie bez ingerencji w OnHit.

| Fiolka              | Efekt item property                                |
|---------------------|----------------------------------------------------|
| Trucizna Wolna      | `IP_CONST_ONHIT_CASTSPELL_SLOW` (poziom 5)        |
| Jad Paraliżu        | `IP_CONST_ONHIT_CASTSPELL_HOLD_MONSTER` (poz. 5) |
| Jad Ślepoty         | `IP_CONST_ONHIT_CASTSPELL_BLINDNESS_AND_DEAFNESS`|
| Trucizna Osłabienia | `IP_CONST_ONHIT_CASTSPELL_BESTOW_CURSE`           |
| Wyciąg Nocy         | `ItemPropertyDamageBonus(ACID, 2d6)`              |
| Jad Czarownicy      | `IP_CONST_ONHIT_CASTSPELL_DISPEL_MAGIC` (poz. 5) |

## Co celowo pominięto

- **Czas warzenia** — brak animacji/opóźnienia; można dodać `DelayCommand` przed `PoiCraft`.
- **Liczba trafień zamiast czasu** — wymaga NWNX `OnPhysicalAttackHit`; czas jest wystarczająco klimatyczny.
- **Odporności na trucizny** — saving throw gracza-celu to domena silnika NWN wbudowana w `ItemPropertyOnHitCastSpell`.
- **Persistencja stanu broni** — czas naniesienia nie przeżywa resetu serwera; przy potrzebie można dodać kolumnę `poi_weapon_state` z `end_unix` i re-aplikować efekt w `sys_on_enter.nss`.

# Effigy Curse — Instrukcja Integracji

## Co to robi

System klątwy figurkowej. Gracz tworzy woskową figurkę dowolnego innego PC
(za złoto), wiążąc z nią klątwę jednego z czterech typów. Co 6 sekund (moduł
OnHeartbeat) ofiara otrzymuje efekty klątwy. Ofiara może wykryć klątwę rzutem
na WIS+Spellcraft, zobaczyć kto ją rzucił i opłacić oczyszczenie. Twórca może
roztrzaskać figurkę, zadając ofierze jednorazowy cios.

## Typy klątw

| Typ          | Efekt                                     | Koszt   |
|--------------|-------------------------------------------|---------|
| Meczarnia    | 1d4 obrażeń negatywnych / heartbeat       | 300 zł  |
| Więdnięcie   | -2 STR, -2 CON (efekt permanentny)        | 500 zł  |
| Zaćmienie    | 25% szans na ślepotę 4s / heartbeat       | 400 zł  |
| Otępienie    | -2 DEX + 20% szans na spowolnienie 3s    | 600 zł  |

## Wymagane hooki modułu

W Module Properties → Scripts ustaw:

| Zdarzenie        | Skrypt         |
|------------------|----------------|
| OnModuleLoad     | sys_on_load    |
| OnClientEnter    | sys_on_enter   |
| OnHeartbeat      | sys_on_hb      |

Jeśli moduł ma już skrypty na tych zdarzeniach, wywołaj odpowiednie
funkcje z modułu Effigy Curse z istniejących skryptów:

```nss
// W istniejącym OnModuleLoad:
#include "sql_eff"
// ...
EffCreateTables();

// W istniejącym OnClientEnter:
#include "lib_eff_app"
// ...
if(GetIsPC(oPC)) { EffRegisterPlayerDb(oPC); EffApplyEffectsToPC(oPC); }

// W istniejącym OnHeartbeat:
// Skopiuj zawartość sys_on_hb.nss lub wywołaj jako ExecuteScript.
```

## Uruchomienie UI

Umieść placeable z OnUsed = `test_eff`. Albo wywołaj
`CreateEffigyWindow(oPC)` z dowolnego miejsca (rozmowa NPC,
specjalny ołtarz, przedmiot z OnActivate itp.).

## Baza danych

Używa `SqlPrepareQueryCampaign("effigy", ...)`. Campaign DB tworzona
automatycznie przy pierwszym starcie modułu. Nie wymaga NWNX.

Tabele:
- `eff_players` — rejestr znanych PC (uuid, char_name, last_online)
- `eff_effigies` — aktywne i historyczne figurki
- `eff_detections` — kto i kiedy wykrył daną figurkę

## Zależności

- NWN EE (NUI API, TagEffect, SqlPrepareQueryCampaign)
- **Brak wymagań NWNX**
- Wymagane skrypty: nw_inc_nui (standardowy skrypt z NWN EE)

## Co celowo pominięto

- Brak fizycznych itemów reprezentujących figurkę (upraszcza integrację)
- Brak systemu składników/reagentów — koszt wyrażony w złocie
- Brak ograniczenia geograficznego (klątwa działa niezależnie od obszaru)
- Brak wizualnego aura-efektu na ofierze (by nie ujawniać klątwy innym)
- Brak wygasania figurek po czasie (DM może czyścić ręcznie przez SQL)

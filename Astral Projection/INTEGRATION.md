# Astral Projection — Integration Guide

## Wymagania

| Zależność | Wymagane? | Uwagi |
|-----------|-----------|-------|
| NWN:EE 8193.35+ | TAK | `NuiProgressBar`, `TagEffect`, `EffectDamageImmunityIncrease` |
| NWNX | NIE | Moduł działa na czystym NWN:EE |
| Kampania SQLite | TAK | Plik `astral.sqlite` tworzony automatycznie przez `sys_on_load.nss` |

## Hooki do podpięcia

### OnModuleLoad
Dopisz wywołanie `AstrCreateTables()` albo dodaj `sys_on_load.nss` jako jeden ze skryptów
ładowanych przy starcie modułu (np. przez `ExecuteScript("sys_on_load", GetModule())`
wewnątrz istniejącego hooka).

### OnClientEnter
Dopisz `ExecuteScript("sys_on_enter", GetEnteringObject())` lub włącz treść
`sys_on_enter.nss` do swojego istniejącego skryptu OnClientEnter.
Zapewnia czyszczenie stanu po rozłączeniu i seed SQL.

### NUI Event Script
Skrypt `lib_astr_ev.nss` jest rejestrowany automatycznie przez `NuiCreate` — nie wymaga
osobnego hooka.

## Jak uruchomić demo

1. Utwórz placeable (np. kamień ołtarza, Resref dowolny).
2. Ustaw jego skrypt OnUsed na `test_astr`.
3. Gracz używa placeable → wchodzi w projekcję; użycie ponownie → powrót.
4. Alternatywnie: wywołaj `AstrEnterProjection(oPC)` z dowolnego skryptu NPC/itemu.

## Co robi moduł

- **Wejście w projekcję**: VFX blur (duch), 75% concealment, +50% speed, odporność na BPS,
  odporność na zaklęcia umysłu. NUI timer 3:00 → 0:00 w górnym prawym rogu ekranu.
- **Postrzeż ukryte** (przycisk, 30s cd): skanuje promień 12m pod kątem pułapek i skrytek
  oraz 20m pod kątem nieumarłych/wrogów. Wyniki trafiają do czatu serwera.
- **Powrót dobrowolny**: likwiduje efekty, aplikuje Wyczerpanie Astralne
  (STR/DEX/CON −tier na tier×min, tier = sekundy/30, maks. 5).
- **Timeout**: jak wyżej + 2d6 negative energy damage.
- **SQL**: `astral.sqlite → astr_log` — trwałe liczniki sesji, suma sekund, rekord sesji.

## Ograniczenia i co celowo pominięto

- **Ciało jako obiekt** nie zostało zaimplementowane (wymagałoby resrefa placeabla w haku).
  Integracja może stworzyć "Comatose Body" placeable z własnego haka wywołując
  `CreateObject(OBJECT_TYPE_PLACEABLE, "astr_body", GetLocation(oPC))` przed
  `AstrEnterProjection` i niszcząc go po powrocie.
- **Blokowanie ataku/zaklęć** w formie ducha: NWScript bez NWNX nie pozwala zablokować
  akcji bojowych na PC; można dodać `ExecuteScript("astr_combat_check", oPC)` w OnSpellCast
  i OnPhysicalAttacked oraz sprawdzać `ASTR_LVAR_ACTIVE`.
- **Persistencja między sesjami** LVARów na PC: NWN:EE EE DB `SqlPrepareQueryObject`
  może być użyty zamiast LVARów jeśli serwer zapisuje PC-local vars.
- **Multiplayer guard**: wielu graczy może projekcji używać równolegle bez konfliktów —
  każdy ma własny nToken i LVARy.

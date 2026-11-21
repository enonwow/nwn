# Blade Spirit — Duchy Broni

## Wymagania

- NWN: Enhanced Edition (NUI, TagEffect, GetObjectUUID na itemach)
- Brak wymagań NWNX — wszystko działa na czystym NWScript + SQLite (SqlPrepareQueryCampaign)

## Hooki modułu

Ustaw następujące skrypty jako zdarzenia modułu:

| Zdarzenie modułu    | Skrypt               |
|---------------------|----------------------|
| OnModuleLoad        | `sys_on_load`        |
| OnClientEnter       | `sys_on_enter`       |
| OnClientLeave       | `sys_on_leave`       |
| OnEquipItem         | `sys_on_equip`       |
| OnUnEquipItem       | `sys_on_unequip`     |
| OnPlayerTarget      | `sys_on_target`      |

Jeśli moduł już ma skrypty na tych zdarzeniach, dodaj wywołania funkcji modułu Duchy Broni na końcu istniejących skryptów:
- `BsCheckAndApplyBonuses(GetEnteringObject());` — w OnClientEnter
- `BsRemoveBonuses(...)` — w OnClientLeave
- etc.

## Śledzenie zabójstw

Skrypt `sys_on_death` umieść jako zdarzenie **OnDeath** na każdym potworu (creature), którego zabójstwo ma liczyć się w progresi ducha.

Alternatywnie, jeśli serwer używa NWNX:
```
NWNX_Events_SubscribeEvent("NWNX_ON_CREATURE_DEATH_AFTER", "sys_on_death");
```
i zmień `GetLastKiller()` na `NWNX_Object_GetCurrentHitPoints(...)` / wymagany adapter.

## Obiekt testowy — Ołtarz Poległych

Stwórz placeable o dowolnym wyglądzie z:
- OnUsed: `test_bs`

Gracz używa ołtarza → wybiera broń z ekwipunku → otwiera się okno wiązania ducha.

Jeśli gracz trzyma w prawej dłoni już nawiedzoną broń, okno przeglądarki ducha otwiera się bezpośrednio.

## Baza danych SQLite

Tabela: `bs_spirits` w pliku kampanii `blade_spirit`.

```sql
CREATE TABLE IF NOT EXISTS bs_spirits (
  item_uuid     TEXT PRIMARY KEY,
  spirit_name   TEXT NOT NULL DEFAULT '',
  spirit_class  INTEGER NOT NULL DEFAULT 0,
  kill_count    INTEGER NOT NULL DEFAULT 0,
  bound_at      INTEGER NOT NULL DEFAULT 0,
  appeased_at   INTEGER NOT NULL DEFAULT 0,
  manifested_at INTEGER NOT NULL DEFAULT 0
);
```

## Klasy duchów i premie

| Klasa     | Tier 1         | Tier 2                        | Tier 3                         | Tier 4 (Zmaterializowany)              |
|-----------|----------------|-------------------------------|--------------------------------|----------------------------------------|
| Wojownik  | +1 trafienie   | +2 trafienie                  | +3 trafienie, +2 SIŁ           | +4 trafienie, +3 SIŁ                   |
| Czarownik | +2 Konc.       | +3 Konc., +2 Czaroznawstwo    | +4 Konc., +3 Czaroznawstwo     | +5 Konc., +4 Czaroznawstwo, +2 INT     |
| Łotrzyk   | +2 Ukrywanie   | +3 Ukryw., +3 Cichy chód      | +5 Ukryw., +4 Cichy chód       | +6 Ukryw., +6 Cichy chód, +1 trafienie |
| Kapłan    | +2 Leczenie    | +3 Leczenie, +2 Konc.         | +4 Leczenie, +3 Konc.          | +5 Leczenie, +4 Konc., +2 MĄD          |

Ubłaganie ducha (100 sz) dodaje +1 do premii podstawowych przez 6 godzin.

## Progi awansów

| Tier | Nazwa            | Zabójstwa |
|------|------------------|-----------|
| 1    | Uśpiony          | 0         |
| 2    | Niespokojny      | 10        |
| 3    | Aktywny          | 25        |
| 4    | Zmaterializowany | 50        |

## Manifestacje (Tier 4, raz na 20 godz.)

| Klasa     | Nazwa                | Efekt                                               |
|-----------|----------------------|-----------------------------------------------------|
| Wojownik  | Ostatnia Wola        | Knockdown + 2d10 obrażeń wszystkich wrogów w 5m    |
| Czarownik | Arcana Uwolniona     | 3d10 magicznych obrażeń wrogów w 7m                |
| Łotrzyk   | Cień Śmierci         | Improved Invisibility + +4 do trafień przez 3 rundy |
| Kapłan    | Boskie Wotum         | Ulecz 3d10+10 HP + 3d10 boskich obrażeń wrogów 7m  |

## Co celowo pominięto

- Brak obsługi broni w lewej ręce (dual-wield) — duch reaguje tylko na prawą rękę
- Brak transferu ducha między przedmiotami — UUID jest stały; jeśli item zostanie zniszczony lub usunięty z DB, duch znika
- Brak limitów per-PC (gracz może mieć wiele nawiedzonych broni, ale premie z tylko jednej aktywnej)
- Brak HAK — moduł nie potrzebuje własnych ikon/grafik

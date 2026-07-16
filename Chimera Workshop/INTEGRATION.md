# Chimera Workshop — Integracja

## Hooki modułu

| Zdarzenie modułu | Skrypt | Opis |
|---|---|---|
| `OnModuleLoad` | `sys_on_load.nss` | Tworzy tabelę SQL `chim_grafts` (idempotentne `CREATE TABLE IF NOT EXISTS`) |
| `OnClientEnter` | `sys_on_enter.nss` | Ponownie nakłada efekty graftów po restarcie serwera lub zalogowaniu |

## Jak otworzyć okno

Z NPC dialog node, triggera lub placeable OnUsed:

```nss
#include "lib_chim"
ChimOpenWindow(GetPC());
```

`ChimOpenWindow` działa jak toggle — ponowne wywołanie zamyka okno.

## Wymagane trofea (tagi przedmiotów)

Każdy przeszczep konsumuje jeden przedmiot z odpowiednim tagiem:

| Tag przedmiotu | Przeszczep | Slot |
|---|---|---|
| `ds_basilisk_eye` | Oko Bazyliszka | Głowa |
| `ds_mind_flayer_brain` | Koreks Umysłożercy | Głowa |
| `ds_troll_heart` | Ciało Trolla | Tułów |
| `ds_dragon_scale` | Łuski Smoka | Tułów |
| `ds_ghoul_claw` | Szpony Ghula | Ramiona |
| `ds_wyvern_spine` | Jadowity Gruczoł Wiwerna | Ramiona |
| `ds_ogre_tendon` | Mięśnie Ogra | Ramiona |
| `ds_phase_spider_gland` | Ścięgna Pająka Fazowego | Nogi |
| `ds_frost_giant_bone` | Kości Lodowego Giganta | Nogi |
| `ds_shadow_essence` | Esencja Cienia | Nogi |

Przedmioty muszą istnieć w HAK lub module (jako blueprinty z tymi tagami).  
Polecany drop: system loot z odpowiednich potworów (bazyliszek, troll, smok itd.).

## Baza danych

Campaign DB: `"chimera"` → plik `chimera.fptl` lub `chimera.sqlite` w katalogu user data serwera.

```sql
CREATE TABLE IF NOT EXISTS chim_grafts (
    uuid       TEXT NOT NULL,
    slot       TEXT NOT NULL,   -- 'head' | 'torso' | 'arms' | 'legs'
    graft_id   INTEGER NOT NULL,
    applied_at INTEGER DEFAULT 0,
    PRIMARY KEY (uuid, slot)
);
```

## Zależności NWNX

Brak. Moduł używa wyłącznie natywnego NWScript + NUI API + SQLite (`SqlPrepareQueryCampaign`).  
Wymaga NWN EE build 8193.14+ dla `SetEffectTag` / `GetEffectTag`.

## Mechanika — podsumowanie

- 4 sloty ciała (Głowa / Tułów / Ramiona / Nogi), każdy przyjmuje co najwyżej 1 przeszczep.
- 10 graftów do wyboru (2–3 na slot).
- Instalacja: trofeum + 500 zp; trwały efekt na postaci; stary przeszczep w slocie jest zastąpiony.
- Usunięcie: 1000 zp + 20 HP (zabieg boli); trofeum przepadło bezpowrotnie.
- Efekty przeżywają restart serwera — `sys_on_enter.nss` nakłada je na nowo przy każdym logowaniu.

## Celowo pominięto

- Animacje chimeryzacji (wymagałyby dedykowanych plików animacji w HAK).
- Zmiany appearance po grafcie (możliwe przez NWNX::Appearance — poza zakresem).
- Limit łącznej liczby graftów poniżej 4 (każdy z 4 slotów może mieć po 1).
- Zwrot trofeum przy usunięciu (design decision: każda operacja jest stratą zasobów).

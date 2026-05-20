# Trophy Hall — Instrukcja integracji

## Co to robi

Sala Trofeów pozwala graczom zbierać trofea z pobitych stworów
(czaszki, łuski, kły…), deponować je w specjalnym miejscu
i wykuwać talizmany z bonusami do walki przeciw danemu typowi wroga.
Pięcioosobowy ranking myśliwych na serwer pokazuje, kto poluje
najefektywniej.

## Wymagania

- NWN:EE ≥ 8193.36 (NUI + SqlPrepareQueryCampaign + JSON)
- NWNX: opcjonalny (tylko dla haka „wszystkie śmierci stworów")
- Plik kampanii SQLite: `trph.nwn` (tworzony automatycznie przez `sys_on_load`)

## Kroki integracji

### 1. OnModuleLoad

Dodaj wywołanie do istniejącego skryptu ładowania modułu:

```nwscript
ExecuteScript("sys_on_load", GetModule());
```

lub włącz `sys_on_load.nss` jako jeden z wywołań w swoim
`module_on_load.nss`.

### 2. OnClientEnter

Dodaj:

```nwscript
ExecuteScript("sys_on_enter", GetEnteringObject());
```

### 3. Hak śmierci stworów (wybierz opcję A lub B)

#### Opcja A — Toolset (bez NWNX)

W edytorze przypisz `sys_on_death` jako skrypt OnDeath każdej
kreaturze, z której chcesz, żeby spadały trofea. Możesz zrobić
to zbiorczo przez Properties > Scripts dla blueprint'ów kreatur.

Jeśli kreatura ma już OnDeath (własny skrypt lub domyślny
`nw_c2_default7`), utwórz wrapper:

```nwscript
// moj_on_death.nss
void main() {
    ExecuteScript("nw_c2_default7", OBJECT_SELF);   // oryginalny
    ExecuteScript("sys_on_death",   OBJECT_SELF);   // trofea
}
```

#### Opcja B — NWNX_Events (zalecane dla dużych modułów)

Wymagane: NWNX `Events` plugin.

```nwscript
// w OnModuleLoad:
NWNX_Events_SubscribeEvent("NWNX_ON_CREATURE_KILL_AFTER", "trph_on_kill");
```

Utwórz `trph_on_kill.nss`:

```nwscript
#include "nwnx_events"
void main() {
    object oKilled = NWNX_Events_GetEventDataObject("KILLED");
    ExecuteScript("sys_on_death", oKilled);
}
```

### 4. Placeable „Sala Trofeów"

Stwórz w toolsecie placeable (np. szafa z trofeami, witryna)
i ustaw jego skrypt OnUsed na `test_trph`.

Dla RP-bossów i Named NPC ustaw na kreaturze zmienną lokalną:

```
TRPH_FORCE_DROP  (int)  = 1
```

To gwarantuje drop trofeum niezależnie od losowania 40%.

### 5. HAK (opcjonalny, ale zalecany)

System działa bez HAK-a, używając fallback resrefów z gry
bazowej. Żeby mieć własne grafiki trofeów i talizmanów:

| Resref            | Opis                         |
|-------------------|------------------------------|
| `trph_trophy_0`   | Czaszka nieumarłego          |
| `trph_trophy_1`   | Demoniczny kieł              |
| `trph_trophy_2`   | Smocza łuska                 |
| `trph_trophy_3`   | Kły bestii                   |
| `trph_trophy_4`   | Skalp                        |
| `trph_trophy_5`   | Rdzeń golema                 |
| `trph_tal_0_min`  | Talizman mały — nieumarli    |
| `trph_tal_0_maj`  | Talizman wielki — nieumarli  |
| *(analogicznie dla kat. 1–5)* |                |

Fallback dla trofeów: `nw_it_msmlmisc22` (drobne przedmioty misc).
Fallback dla talizmanów: `nw_it_mneck001` (amulet) z dynamicznymi
właściwościami.

## Co celowo pominięto

- **Szybki zapis animacji** ani efektów wizualnych na placeable —
  to decyzja stylistyczna serwera.
- **Osobny ekwipunek/magazyn trofeów** w NUI — gracz trzyma je
  w inventory jak normalny item, dopóki nie złoży w Sali.
- **Powiadomienie o nowym rekordzie** (serwer-wide) — można dodać
  jako rozszerzenie w `TrphAddDeposit`, jeśli potrzebne.
- **Limity talizmanów** (jeden na typ per postać) — można dodać
  przez sprawdzenie GetItemPossessedBy lub SQL.

## SQL — schemat

```sql
CREATE TABLE IF NOT EXISTS trph_records (
    pc_uuid       TEXT NOT NULL,
    pc_name       TEXT NOT NULL DEFAULT '',
    cat_id        INTEGER NOT NULL,
    deposited     INTEGER NOT NULL DEFAULT 0,
    crafted_minor INTEGER NOT NULL DEFAULT 0,
    crafted_major INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (pc_uuid, cat_id)
);
```

Plik kampanii: `trph` → na dysku `trph.nwn` obok pliku modułu.

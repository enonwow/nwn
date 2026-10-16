# Golem Workshop — INTEGRATION

## Wymagania

- NWN:EE 8193.36+
- NUI (wbudowane w silnik od 8193.14)
- NWNX: **nie wymagane**
- SQLite campaign DB: automatycznie tworzone przez `sys_on_load.nss`

## Podpięcie hooków w istniejącym module

### 1. OnModuleLoad

```nwscript
#include "lib_gwk_def"
// ...
void main() {
    GwkCreateTables();          // tworzy tabelę gwk_golems
    // ... reszta twojego on_load
}
```

Lub wywołaj skrypt `sys_on_load.nss` bezpośrednio jako OnModuleLoad.

### 2. OnClientEnter

```nwscript
#include "lib_gwk"
// ...
void main() {
    object oPC = GetEnteringObject();
    if(GetIsPC(oPC))
        DelayCommand(3.0, GwkAutoRecall(oPC));
    // ... reszta twojego on_enter
}
```

### 3. Placeable OnUsed (warsztat/ołtarz/kuźnia)

```nwscript
// Skrypt: test_gwk.nss (gotowy do użycia)
// Ustaw go jako "On Used" na dowolnym placeable oznaczonym jako warsztat.
```

## Tworzenie itemów materiałów

Stwórz w toolsecie następujące przedmioty i nadaj im tagi:

| Tag       | Nazwa PL           | Opis                              |
|-----------|--------------------|-----------------------------------|
| `gwk_clay`  | Bryła gliny        | Wydobywana z podmokłych dolin     |
| `gwk_iron`  | Odłamek żelaza     | Odpadek z kuźni lub złom          |
| `gwk_bone`  | Fragment kości     | Kość humanoidalna lub zwierzęca   |
| `gwk_soul`  | Fragment duszy     | Shard z rozbitego Kryształu Duszy |

Opcjonalnie: dostosuj ikonę i opis, by pasowały do klimatu serwera.

## Creature resrefy golemów

Domyślnie używane są blueprinty ze standardowego NWN:EE:

| Golem   | Resref       | Opis blueprintu    |
|---------|--------------|--------------------|
| Gliniany| `nw_golem01` | Clay Golem (vanilla) |
| Żelazny | `nw_golem02` | Iron Golem (vanilla) |
| Kostny  | `nw_skel01`  | Skeleton (vanilla)   |

**Zalecane**: stwórz własne blueprinty w HAK i zmień stałe
`GWK_RESREF_CLAY / IRON / BONE` w `lib_gwk_def.nss`.

Golem rozpoznawany jest przez lokalną zmienną `GWK_IS_GOLEM = 1`
ustawianą po stworzeniu — tag blueprintu nie ma znaczenia.

## SQL

Dane golema są przechowywane w kampanii `"gwk"` (plik `gwk.sqlite` obok modułu).
Tabela: `gwk_golems` (pc_uuid, golem_type, current_hp, max_hp, is_active).

## Co celowo pominięto

- **Walka golema**: golem używa domyślnego AI blueprintu; niestandardowe zaklęcia/taktyki wymagają dedykowanego AI skryptu.
- **Wiele golemów**: jeden na gracza — projekt celowy.
- **Animacja tworzenia**: efekty wizualne (`ApplyEffectToObject` vfx) można dodać w `GwkDoForge`.
- **Plik .mod**: brak możliwości spakowania `.mod` w środowisku CI; użyj toolsetu zgodnie z instrukcją powyżej.

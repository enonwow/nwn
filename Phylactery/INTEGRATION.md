# Phylactery — Integracja

## Co to robi

System filakterii pozwala graczom stworzyć naczynie dusz zakotwiczone
w wybranej lokacji. Po śmierci postać automatycznie zmartwychwstaje
w zakotwiczonym miejscu kosztem jednego ładunku, z obniżonym HP
i chwilowym osłabieniem. Gdy ostatni ładunek zostanie zużyty, rozbite
naczynie uwalnia energię duszy w postaci tymczasowego wzmocnienia
(+2 do rzutów obronnych i trafień na 1 h). Gracz może też ręcznie
rozbić filakterię przez NUI.

## Wymagania

- NWN:EE 8193.36+ (korzysta z `RespawnPC()`)
- Żadne pluginy NWNX nie są wymagane
- SQLite przez wbudowane API NWN (`SqlPrepareQueryCampaign`)

## Pliki

| Plik                   | Rola                                                  |
|------------------------|-------------------------------------------------------|
| `sql_phy.nss`          | Schemat SQLite i wszystkie zapytania                  |
| `lib_phy_def.nss`      | Stałe, ID bindów, forward declarations               |
| `lib_phy.nss`          | Rdzeń: budowanie NUI, funkcje feed, logika śmierci   |
| `lib_phy_ev.nss`       | Handler eventów NUI                                   |
| `sys_on_load.nss`      | Tworzy tabele — uruchom jako OnModuleLoad             |
| `sys_on_enter.nss`     | Powiadamia gracza o stanie filakterii przy wejściu   |
| `sys_on_death.nss`     | Obsługuje śmierć gracza — integruj z OnPlayerDeath   |
| `test_phy.nss`         | OnUsed na placeable — otwiera okno filakterii        |

## Jak włączyć w istniejącym module

### 1. OnModuleLoad

```nwscript
#include "sql_phy"
// (w swoim głównym OnModuleLoad):
ExecuteScript("sys_on_load", GetModule());
// lub bezpośrednio: PhyCreateTables();
```

### 2. OnClientEnter

```nwscript
ExecuteScript("sys_on_enter", GetEnteringObject());
```

### 3. OnPlayerDeath

```nwscript
ExecuteScript("sys_on_death", GetModule());
// GetLastPlayerDied() działa prawidłowo w tym kontekście
```

### 4. Placeable "Naczynie Dusz"

Stwórz w toolsecie placeable (np. `plc_goldbox` lub własny model
z HAK) z tagiem `phy_vessel` i podepnij skrypt `test_phy` pod
`OnUsed`. Możesz umieścić go w karczmach, świątyniach lub u
alchemika jako punkt dostępu do UI filakterii.

Gracz może też otworzyć okno bezpośrednio z rozmowy z NPC:
```nwscript
#include "lib_phy"
void main() { CreatePhyWindow(GetPCSpeaker()); }
```

## Koszty i parametry (w `sql_phy.nss`)

| Stała                    | Wartość | Opis                              |
|--------------------------|---------|-----------------------------------|
| `PHY_DEFAULT_CHARGES`    | 3       | Ładunki przy stworzeniu           |
| `PHY_MAX_CHARGES`        | 9       | Maksymalna liczba ładunków        |
| `PHY_CREATE_GOLD_COST`   | 250     | Koszt stworzenia (sz)             |
| `PHY_EMPOWER_GOLD_COST`  | 500     | Koszt wzmocnienia +1 ładunek (sz) |
| `PHY_RESURRECT_HP_PCT`   | 25      | HP po zmartwychwstaniu (% maks.)  |
| `PHY_SHATTER_SAVES`      | 2       | Bonus do rzutów obronnych         |
| `PHY_SHATTER_DURATION`   | 3600    | Czas trwania buffy (sekundy)      |

## Co celowo pominięto

- **Komponenty craftingowe** — zamiast konkretnych przedmiotów system
  używa złota, by być samodzielny i nie wymagać zasobów z HAK.
- **Wizualny model 3D filakterii** — wymagałby zasobów HAK; placeable
  korzysta z domyślnych modeli.
- **PvP interakcja** — gracze nie mogą niszczyć filakterii innych
  graczy; mechanika jest single-player per-postać.
- **Integracja z systemem ekwipunku** — filakteria jest wirtualna
  (persystentna w SQLite), nie jest przedmiotem w ekwipunku.

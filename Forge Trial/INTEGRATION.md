# Forge Trial — Integracja

## Co to robi

System minigry kuźniczej: gracz wybiera ekwipowaną broń, tarczę lub zbroję,
a następnie musi uderzyć w odpowiednim momencie oscylującego wskaźnika żaru
(animowany progress bar). Trafienie w strefę „Żar Kuźni" (40–70%) aplikuje
trwały item property. Niecelne uderzenie marnuje próbę; wejście w strefę
„Płomień Zagłady" obniża poziom. Każdy przedmiot ma 1-godzinny cooldown
i limit 3 uderzeń na sesję.

## Poziomy kuźni (maks. 5)

| Poz. | Broń                        | Zbroja/Tarcza               |
|------|-----------------------------|-----------------------------|
| 1    | +1 Wzmocnienie              | +1 KP                       |
| 2    | +2 Wzmocnienie              | +2 KP                       |
| 3    | +3 Wzmocnienie + 1k4 Ogień  | +3 KP                       |
| 4    | +4 Wzmocnienie + 1k4 Ogień  | +4 KP + +2 Ochrona           |
| 5    | +5 Wzmocnienie + 1k6 Ogień  | +5 KP + +3 Ochrona           |

## Pliki

| Plik                       | Rola                                        |
|----------------------------|---------------------------------------------|
| `sql_frg.nss`              | Schemat SQL i zapytania (`campaign: forge`) |
| `lib_frg_def.nss`          | Stałe, nazwy bindów, forward declarations  |
| `lib_frg.nss`              | Rdzeń: NUI, logika, timer, uderzenie        |
| `lib_frg_ev.nss`           | Handler eventów NUI                         |
| `sys_on_load.nss`          | Inicjalizacja (OnModuleLoad)                |
| `test_frg.nss`             | Skrypt OnUsed na placeable kuźni            |

## Zależności

- **NWN:EE** (Enhanced Edition) — wymagany NUI i SQLite (`SqlPrepareQueryCampaign`).
- **NWNX** — niewymagane.
- **Campaign DB**: `forge` — tworzona automatycznie przy pierwszym uruchomieniu.
- Lib: `lib_nui`, `lib_nui_utility`, `nw_inc_nui` — standardowe pliki NWN:EE.

## Jak włączyć w istniejącym module

1. Skopiuj wszystkie pliki `.nss` z `Scripts/` do folderu skryptów modułu.
2. W skrypcie **OnModuleLoad** wywołaj `ExecuteScript("sys_on_load", GetModule())`.
3. W toolsecie utwórz placeable „Kuźnia" (dowolny model kowadła/pieca) i ustaw
   jego **OnUsed** na `test_frg`.
4. Upewnij się, że `lib_nui.nss` i `lib_nui_utility.nss` są dostępne w module
   (są wspólne dla wszystkich modułów z tego repo).

## Co celowo pominięto

- **Efekty wizualne** (VFX ognia na broni) — wymagałyby zasobów `.eff`; łatwe do
  dodania przez `ApplyEffectToObject` z `EffectVisualEffect` po zmianie poziomu.
- **Receptury specjalne** (unikalne kombinacje) — celowo prosty system bonus+bonus;
  rozszerzenie przez dodatkowy wiersz w tabeli SQL `frg_recipes`.
- **Degradacja czasowa** — wzmocnienia są stałe; można dodać timer-based decay.
- **UI animacja tła** (żar, blask) — wymaga DrawList z sekwencją grafik w hakku.

# Corruption – Integration Guide

## Opis modułu

System Korupcji Duszy śledzi stopień moralnego zepsucia każdej postaci graczy
jako wartość 0–100 przechowaną w SQLite. Pięć stadiów (Nieskażony → Potępiony)
aplikuje narastające kary atrybutów i efekty wizualne. Gracze mogą oczyścić
duszę przez rytuał pokuty w oknie NUI, Święconą Wodę lub odpoczynek
w uświęconym miejscu.

---

## Hooki do podpięcia

| Zdarzenie modułu | Skrypt z modułu | Uwagi |
|---|---|---|
| **OnModuleLoad** | `sys_on_load` | Tworzy tabelę SQLite `cor_chars`. |
| **OnClientEnter** | `sys_on_enter` | Wczytuje korupcję z DB, re-aplikuje efekty. |
| **OnPlayerRest** | `sys_on_rest` | Sanctuary bonus + nightmare flavor. |
| **OnActivateItem** | `sys_on_activate` | Święcona woda (`cor_holy_water`) i mroczne artefakty. |
| **OnPlayerDeath** | `sys_on_death` | Opcjonalny flavor dla Potępionych. |

Jeśli Twój moduł ma już skrypty dla tych zdarzeń, wstaw wywołanie
`ExecuteScript("sys_on_enter", OBJECT_SELF)` (lub odpowiedni skrypt)
**na końcu** istniejącego handlera.

---

## NWNX

Moduł **nie wymaga NWNX**. Używa wyłącznie standardowego NWScript + NUI +
`SqlPrepareQueryCampaign`.

---

## Baza danych

Kampania: **`corruption`** (plik `corruption.sqlite3` obok modułu lub w katalogu
kampanii, zależnie od konfiguracji serwera).

```sql
CREATE TABLE IF NOT EXISTS cor_chars (
    uuid        TEXT    PRIMARY KEY,
    char_name   TEXT    DEFAULT '',
    corruption  INTEGER DEFAULT 0,
    last_ritual INTEGER DEFAULT 0
);
```

Tabela jest tworzona idempotentnie przy każdym starcie modułu.

---

## Jak nadać korupcję z zewnętrznego skryptu

```nss
#include "lib_cor"

// Przykład: NPC zabity przez gracza podnosi korupcję, jeśli był neutralny/przyjazny.
// Umieść ten fragment w OnCreatureDeath lub własnym OnPlayerKillTarget.

void main()
{
    object oVictim = OBJECT_SELF;        // martwy NPC
    object oKiller = GetLastKiller();

    if(!GetIsPC(oKiller)) return;

    int nRep = GetReputation(oVictim, oKiller);
    if(nRep >= 70)  // neutralny lub przyjazny
    {
        CorGainCorruption(oKiller, COR_NEUTRAL_KILL_GAIN,
            "Poczucie winy przenika twoje ciało. Zabiłeś kogoś, kto ci nie zagrażał.");
    }
}
```

---

## Mroczne artefakty

Ustaw zmienną lokalną na dowolnym item:

```
LVAR name : COR_DARK_ARTIFACT   (string)
LVAR type : int
LVAR value: 5    (lub inna wartość — tyle pkt korupcji doda aktywacja)
```

Kiedy gracz aktywuje item, `sys_on_activate` dodaje wskazaną liczbę punktów
korupcji i usuwa zmienną (by item mógł aktywować efekt tylko raz per sesję).

---

## Sanctuary (miejsce uświęcone)

Ustaw zmienną lokalną na obiekcie **Area** w Toolsecie:

```
LVAR name : COR_AREA_SANCTUARY   (string)
LVAR type : int
LVAR value: 1
```

Odpoczynek w tej lokacji usuwa `COR_SANCTUARY_REDUCTION` (domyślnie 3) punktów
korupcji zamiast wywoływania koszmarów.

---

## Przedmiot: Święcona Woda

Stwórz item z tagiem `cor_holy_water`. Aktywacja (Activate Item) zużywa item
i usuwa `COR_HWATER_REDUCTION` (domyślnie 10) punktów korupcji.

---

## Demo (test w module)

1. Umieść dowolny placeable (np. Campfire) w obszarze testowym.
2. Ustaw skrypt `test_cor` jako **OnUsed**.
3. Uruchom moduł, podejdź do placeable i użyj go:
   - 1. użycie → otwiera okno NUI Korupcji Duszy.
   - 2. użycie → +15 pkt korupcji.
   - 3. użycie → -15 pkt korupcji.
   - Cykl się powtarza.

---

## Co celowo pominięto (v1)

- **Wizualne zmiany appearance** — wymagałyby ingerencji w moduł Appearance
  lub NWNX:Player (zmiana modelu postaci). Można dodać w v2.
- **Reakcje NPC** (SetReputation) — pominięte, by uniknąć konfliktów
  z istniejącymi systemami reputacji.
- **Automatyczne przyrosty korupcji** (heartbeat za każdą godzinę online
  z mrocznym przedmiotem) — pominięte; architektura to umożliwia przez
  `sys_module_hb.nss`.
- **Kurator/wyznawca** jako NPC potrzebny do rytuału — rytuał jest
  samoobsługowy w NUI; builder może go wymagać wyłącznie przez NPC
  ustawiając zmienną modułową.

# Sacred Oaths — Instrukcja integracji

## Wymagania

- NWN: Enhanced Edition (minimum 8193.34)
- NWNX: **nie wymagane** — moduł używa wyłącznie standardowego API NWScript + NUI + SQLite Campaign DB.
- Campaign DB: `oaths` (tworzona automatycznie przez `sys_on_load.nss`)

## Hooki modułowe do podpięcia

| Zdarzenie modułu      | Skrypt             | Uwagi                                                              |
|-----------------------|--------------------|--------------------------------------------------------------------|
| OnModuleLoad          | `sys_on_load`      | Tworzy tabelę `oaths` w Campaign DB.                              |
| OnClientEnter         | `sys_on_enter`     | Przywraca efekty przysięgi i klątwę po zalogowaniu.              |
| OnHeartbeat           | `sys_on_hb`        | Sprawdza naruszenia co ~60 s (co 10 taktów HB × 6 s = 60 s).    |
| OnNuiEvent            | *(auto — NuiCreate ustawia `lib_oath_ev`)* | Brak dodatkowego hookowania.     |

Jeśli moduł ma już własny `OnHeartbeat`, wywołaj `ExecuteScript("sys_on_hb", GetModule())` wewnątrz istniejącego skryptu lub użyj systemu haków (np. NWNX Hooks / lista skryptów w SetEventScript).

## Kaplica — placeable

1. Umieść dowolny placeable (np. ołtarz, kapliczka, posąg) na mapie.
2. Ustaw jego skrypt `OnUsed` na `test_oath`.
3. Upewnij się, że placeable ma włączone `Usable = TRUE`.

## Jak gracz korzysta z systemu

1. Gracz używa Kaplicy Przysiąg → otwiera się panel NUI.
2. Wybiera przysięgę z lewej listy → widzi szczegóły (premie, ograniczenie, lore, koszt).
3. Klika **Złóż Przysięgę** → pojawia się popup potwierdzenia.
4. Po potwierdzeniu gracz traci złoto (jeśli wymagane) i otrzymuje trwałe efekty.
5. Naruszenia są wykrywane automatycznie w heartbeat (dla Ubóstwa i Żelaza).
6. Po 3 naruszeniach lub dobrodynamicznym wyrzeczeniu się — klątwa (-2 do wszystkich atrybutów).
7. Odkupienie kosztuje 500 sz.z. i zdejmuje klątwę.

## Dostępne przysięgi

| ID | Nazwa                 | Premie                                              | Ograniczenie                                | Koszt   |
|----|-----------------------|-----------------------------------------------------|---------------------------------------------|---------|
| 1  | Przysięga Ubóstwa     | +2 WIS, +2 CHA, +1 do wszystkich rzutów obronnych  | Maks. 500 sz.z. (HB check)                  | 200 sz.z |
| 2  | Przysięga Żelaza      | +4 naturalna KP, +2 CON                             | Brak zbroi z bazową KP > 0 (HB check)       | 150 sz.z |
| 3  | Przysięga Zemsty      | +4 testy ataku, +2k6 obrażeń magicznych             | Nie uciekaj z walki (kodeks honorowy)        | 300 sz.z |
| 4  | Przysięga Krwi        | Odporność na strach i efekty mentalne, +3 STR       | Drenaż 5% maks. PŻ co ~60 s                  | Brak    |
| 5  | Przysięga Milczenia   | +5 Ukrywanie, +5 Cichy krok, +2 DEX                | Brak zaklęć werbalnych (kodeks honorowy)     | 150 sz.z |

## Co celowo pominięto

- **Cel zemsty** dla Przysięgi Zemsty: wybór konkretnej rasy/stworzenia wymagałby NWNX:Creature do podpięcia OnHit i checkowania rasy. Obecna implementacja daje flat +4 AB bez per-race filtrowania — wystarczy na start, można rozszerzyć.
- **Sprawdzanie rzucania zaklęć** dla Przysięgi Milczenia: brak standardowego hooka w NWScript dla „przed rzuceniem czaru". Wymagałby NWNX:Events `NWNX_ON_CAST_SPELL_BEFORE`. Implementacja pozostaje kodeksem honorowym.
- **Zapisywanie geometrii okna**: okno otwiera się wyśrodkowane; zapis pozycji okna (NuiBind geometry) nie jest trwały między sesjami bez NWNX:Persistencia.
- **DM Panel**: brak interfejsu DM do ręcznego resetowania przysiąg. Można to zrobić przez `OathDbClear(oPC)` z konsoli DM.

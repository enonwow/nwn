# Blood Altar — Instrukcja integracji

## Co to robi

Gracze mogą składać ofiary przy ołtarzach (złoto, przedmiot z ekwipunku lub własna krew)
w zamian za tymczasowe wzmocnienia. Każda ciemna ofiara zwiększa wskaźnik **skalania duszy**
(0–100), przechowywany w SQLite. Przy progach 33% i 66% na postaci pojawiają się stałe
efekty aury; przy 100% (Soul Riven) gracz traci 4 punkty Charyzmy dopóki nie odejdzie od mroku.

## Hooki modułowe

| Zdarzenie modułu | Skrypt        | Uwagi                                    |
|------------------|---------------|------------------------------------------|
| OnModuleLoad     | `sys_on_load` | Tworzy tabele SQLite                     |
| OnClientEnter    | `sys_on_enter`| Odświeża VFX korupcji, liczy decay      |
| OnPlayerTarget   | `sys_on_target`| Obsługuje ofiarę z przedmiotu           |

Skrypt `sys_on_use.nss` podepnij jako **OnUsed** na każdym placeablu ołtarza.

## Tagi placeabli

Ustaw `Tag` placeabla na jeden z poniższych (dokładna wielkość liter):

| Tag            | Ołtarz          | Korupcja ofiar     |
|----------------|-----------------|-------------------|
| `ALTAR_BLOOD`  | Ołtarz Krwi     | 8 / 15 / 25       |
| `ALTAR_BONE`   | Ołtarz Kości    | 5 / 12 / 20       |
| `ALTAR_EARTH`  | Ołtarz Ziemi    | 0 / 0 / 0         |
| `ALTAR_SHADOW` | Ołtarz Cienia   | 10 / 15 / 30      |

## NWNX

Brak twardych zależności od NWNX. Wszystkie efekty i VFX używają standardowego NWScript i NWN:EE.

## Baza danych SQLite

Kampania: **`blood_altar`**. Tabele tworzone automatycznie przez `sys_on_load`.

```
balt_corruption  — skalanie per gracz (player_uuid, corruption, last_sacrifice)
balt_log         — historia ofiar (player_uuid, altar_tag, sac_idx, epoch)
```

## Typy ofiar

Każdy ołtarz oferuje 3 poziomy:

| Poziom | Koszt           | Mechanika                                  |
|--------|-----------------|--------------------------------------------|
| Drobna | Złoto (stała kwota) | Natychmiastowe odjęcie złota, buff     |
| Ciała  | Przedmiot z ekwipunku | Targeting mode → wybierz przedmiot, zniszczenie, buff |
| Krwi   | % maks. PW      | Popup potwierdzenia → obrażenia magiczne, buff |

## Korupcja duszy

- **0–32%** — brak efektów wizualnych
- **33–65%** — `VFX_DUR_AURA_EVIL` (stały, odfiltrowywany przez BALT_VFX_TAG_LOW)
- **66–99%** — jak wyżej + `VFX_DUR_AURA_NEGATIVE_ENERGY` (BALT_VFX_TAG_HIGH)
- **100%** — oba aury + `-4 Charyzmy` (BALT_VFX_TAG_RIVEN) + wiadomość narracyjna

Korupcja powoli spada przy każdym logowaniu jeśli minęło odpowiednio dużo czasu
od ostatniej ciemnej ofiary (3 pkt po 12h, 8 po 24h, 15 po 48h).

## Test

1. Umieść dowolny placeable (np. Altar Generic).
2. Ustaw `OnUsed = test_balt`.
3. Klikaj — okno będzie cyklować przez wszystkie 4 typy ołtarzy.

Alternatywnie:
- Ustaw tag placeabla na `ALTAR_BLOOD` i `OnUsed = sys_on_use`.

## Co celowo pominięto

- **Brak .mod** — środowisko CLI nie pozwala pakować plików .mod; użyj Toolsetu.
- **Brak cooldownu per ofiara** — można składać wielokrotnie; tryb PW może wymagać CD.
- **Brak ograniczeń klasowych/rasowych** — każdy może korzystać z każdego ołtarza.
- **Brak redukcji korupcji przez modlitwę/kapłanów** — extension point dla późniejszej integracji z Pantheon.

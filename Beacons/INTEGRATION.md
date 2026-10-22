# Beacons of the Dying Light — Integration Guide

## Co to robi

Moduł dodaje do gry system starożytnych latarni — trwałych punktów odpoczynku/odrodzenia
zainspirowanych mechaniką ognisk (Dark Souls). Latarnie istnieją w świecie jako placeables.
Gracz może:
- **Zapalić** latarnię zużywając 3 sztuki materiału rytualnego (typ zależy od rodzaju latarni);
- **Odpocząć** przy zapalonej latarni — pełna regeneracja HP + błogosławieństwo przez 2 godziny
  (cooldown: 1 godzina czasu rzeczywistego);
- **Oczyścić** skalanie jedną Świeconą Wodą (skalanie przyrasta zewnętrznie przez `sys_on_target.nss`).

Stan latarń jest wspólny dla całego serwera (baza SQLite `beacons`).
Każdy gracz widzi własną listę odwiedzonych latarń w oknie UI.

## Pliki

```
Beacons/Scripts/
  sql_bcn.nss        — schema SQLite + zapytania
  lib_bcn_def.nss    — stałe, ID bindów, ID przycisków
  lib_bcn.nss        — cały rdzeń: logika, UI budowanie, feed, akcje
  lib_bcn_ev.nss     — obsługa eventów NUI (main())
  sys_on_load.nss    — OnModuleLoad: BcnCreateTables()
  sys_on_enter.nss   — OnClientEnter: zamyka nieaktualne okno
  sys_on_target.nss  — skrypt skalowania latarni (OnHeartbeat/OnEnter triggera)
  test_bcn.nss       — OnUsed placeable demonstracyjny
  lib_nui.nss        — pomocnicze funkcje NUI (skopiowane z Mailbox)
  lib_nui_utility.nss
```

## Hooki do podpięcia

| Zdarzenie modułu | Skrypt |
|-----------------|--------|
| OnModuleLoad    | `sys_on_load` |
| OnClientEnter   | `sys_on_enter` |

Latarnia w świecie: placeable z OnUsed ustawionym na `test_bcn` (demo) lub własny skrypt
wywołujący `BcnOpenWindow(oPC, OBJECT_SELF)`.

### Zmienne lokalne na placeablu latarni

| Zmienna    | Typ    | Wartości dopuszczalne | Opis |
|------------|--------|----------------------|------|
| `BCN_TYPE` | string | `fire`, `shadow`, `spirit`, `blood`, `stone` | Typ latarni |
| `BCN_NAME` | string | dowolny               | Nazwa wyświetlana w UI |

Bez ustawienia `BCN_TYPE` latarnia zachowuje się jak `fire`.

## Skalanie latarni (opcjonalne)

Podepnij `sys_on_target` jako skrypt OnHeartbeat creatury lub OnEnter obszarowego triggera.
Skrypt sprawdza wszystkie obiekty w obszarze mające zmienną `BCN_TYPE` i inkrementuje ich
`corruption` o 1 (maks. 3 = zgaszona). Nie skaluje latarni już wygaszonych ani niezapalonych.

## Zależności

- **NWN:EE** ≥ 1.80 — wymagane dla NUI, `SqlPrepareQueryCampaign`, `GetObjectUUID`, `SetTag`
- **NWNX** — *nie jest wymagany*
- Baza kampanii o nazwie `beacons` (plik `beacons.sqlite3` w katalogu kampanii serwera)

## Przedmioty

Przed wdrożeniem utwórz w toolsecie po jednym przedmiocie dla każdego paliwa, nadając mu tag:

| Tag               | Opis                | Przykładowy bazowy item |
|-------------------|---------------------|-------------------------|
| `bcn_tinder`      | Hubka               | świeca / pochodnia       |
| `bcn_shadow_ash`  | Popiół Cienia       | składnik alchemiczny     |
| `bcn_incense`     | Kadzidło            | składnik alchemiczny     |
| `bcn_blood_vial`  | Fiolka Krwi         | pusta fiolka / mikstura  |
| `bcn_quartz`      | Kwarc               | klejnot niskiej wartości |
| `bcn_holy_water`  | Święcona Woda       | mikstura specjalna       |

Skrypt testowy (`test_bcn.nss`) tworzy prowizoryczne zamienniki ze standardowych resrefów
NWN w celu demonstracji — nie nadają się do produkcji.

## Co celowo pominięto

- **Teleportacja między latarniami** — mechanika "podróży warp" byłaby wartościowym
  rozszerzeniem, ale wymaga mapki świata i interfejsu wyboru celu.
- **Respawn przy latarni** — integracja z OnPlayerDeath/Respawn wymagałaby modyfikacji
  głównych hooków modułu poza zakresem tego modułu.
- **Limit latarń na serwer** — brak górnej granicy liczby latarń; zaleca się rozsądne
  umieszczanie w toolsecie.
- **Grafika tła (HAK)** — moduł działa bez własnego HAK; można dodać tło NUI za pomocą
  DrawList jeśli posiada się odpowiednią teksturę.

# Pilgrim's Curse — Instrukcja integracji

## Co to robi

Gracze nawiedzają rozsiane po module **ciemne sanktuaria** (placeables). Każde odwiedzenie
dodaje punkty **Brzemienia** jednego z czterech typów (Cień / Krew / Śmierć / Chaos).
Kumulujące się brzemię odblokowuje coraz silniejsze efekty pasywne (bonusy do STR/CON,
odporności, widzenie w ciemności). Na najwyższym progu pojawia się kara −4 do CHA —
twarz pielgrzyma budzi odrazę. Ołtarz Pokuty (`plg_catharsis`) pozwala oczyścić brzemię
za złoto, ale zostawia tymczasowy debuff. NUI (3 zakładki) pokazuje progress bary brzemienia,
lore sanktuariów i ranking 10 najbardziej przeklętych postaci.

## Hooki modułu

| Zdarzenie              | Skrypt do podpięcia  |
|------------------------|----------------------|
| Module OnLoad          | `sys_on_load`        |
| Module OnClientEnter   | `sys_on_enter`       |

## Placeables

Każde sanktuarium to zwykły placeable z odpowiednim tagiem i skryptem `test_plg` w polu
*OnUsed*. Nie trzeba żadnych zmiennych lokalnych — tag wystarczy.

### Tagi wbudowane (seed w sys_on_load.nss)

| Tag                      | Typ    | Brzemię |
|--------------------------|--------|---------|
| `plg_shrine_shadow_01`   | Cień   | 1       |
| `plg_shrine_shadow_02`   | Cień   | 2       |
| `plg_shrine_blood_01`    | Krew   | 1       |
| `plg_shrine_blood_02`    | Krew   | 2       |
| `plg_shrine_death_01`    | Śmierć | 1       |
| `plg_shrine_death_02`    | Śmierć | 2       |
| `plg_shrine_chaos_01`    | Chaos  | 1       |
| `plg_shrine_chaos_02`    | Chaos  | 2       |
| `plg_catharsis`          | —      | (oczyszczenie) |

Otworzenie okna statusu: dowolny placeable z `test_plg` w OnUsed, tag inny niż powyższe.

### Rejestracja własnych sanktuariów

Wywołaj `PlgRegisterShrine(tag, nazwa, lore, typ, wartość)` z `sys_on_load.nss`
(lub z dowolnego skryptu DM). Typy: `"shadow"`, `"blood"`, `"death"`, `"chaos"`.

```nss
PlgRegisterShrine("moje_sanktuarium", "Ołtarz Bólu", "Ból jest jedyną prawdą.", "blood", 3);
```

## Progi brzemienia i efekty

| Łączne brzemię | Tier                  | Efekty                                              |
|----------------|-----------------------|-----------------------------------------------------|
| < 3            | Nieoznaczony          | brak                                                |
| 3–5            | Lekkie Brzemię        | STR +1                                              |
| 6–9            | Umiarkowane Brzemię   | STR +2, odporność na strach, widzenie w ciemności   |
| 10–14          | Ciężkie Brzemię       | + CON +2, odporność na chorobę                      |
| ≥ 15           | Piętno Potępionego    | + CON +3, odporności na truciznę i paraliż, CHA −4  |

Katharsis: koszt = brzemię × 500 zł; kara: STR −2, CON −2 przez 3600 sekund.

## Baza danych

Campaign DB o nazwie `plg` (plik `plg.sqlite` w folderze servervault/databases):

- `plg_shrines`  — definicje sanktuariów
- `plg_pilgrims` — stan brzemienia per postać (klucz: UUID)
- `plg_visits`   — log wizyt per postać per sanktuarium (reset po ukończeniu obiegu)

Nie wymaga NWNX. Wszystkie zapytania przez `SqlPrepareQueryCampaign`.

## Zależności

- **NWN:EE** — wymagane NUI API (`NuiCreate`, `NuiBind`, …) i `TagEffect` / `SupernaturalEffect`
- Brak wymagań NWNX

## Test manualny

1. Podepnij `sys_on_load` do Module OnLoad i załaduj moduł.
2. Umieść placeable z tagiem `plg_shrine_shadow_01` i `test_plg` w OnUsed.
3. Umieść placeable z tagiem `plg_catharsis` i `test_plg` w OnUsed.
4. Umieść placeable z dowolnym tagiem (np. `plg_status_book`) i `test_plg` w OnUsed — to otwiera okno statusu.
5. Wejdź jako gracz, kliknij sanktuarium, sprawdź pop-up i efekty.
6. Kliknij status-book, przejrzyj 3 zakładki NUI.
7. Zbierz brzemię ≥ 3, sprawdź efekty pasywne na postaci.
8. Podejdź do ołtarza pokuty i kliknij "Katharsis" w oknie statusu.

## Co celowo pominięto

- **Wariant pielgrzymki świetlnej** — dedykowane sanktuaria "białe" z buff-only efektami;
  można dodać jako kolejny `burden_type = "light"` bez zmiany architektury.
- **Notyfikacja DM** o ukończeniu obiegu — brak hooków DM w tym projekcie.
- **Animacje / dźwięki sanktuariów** — wymagałyby niestandardowych zasobów w HAK.
- **Limit sanktuariów per circuit** — aktualnie zlicza wszystkie zarejestrowane;
  dodanie wybranej ścieżki (np. tylko 4 z 8) wymaga pola `path_id` w schemacie.

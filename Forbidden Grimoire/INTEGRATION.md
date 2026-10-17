# Forbidden Grimoire — Integracja

## Co to robi

System badań arkanicznych: gracz zbiera fragmenty arkaniczne (15 typów: 5 szkół × 3 poziomy mocy)
i łączy je po 2 przy stole badań. Rytuał może odkryć jedną z 8 zakazanych formuł, zastosować efekt
natychmiast, a po 3 sukcesach z tą samą recepturą nadać mistrzostwo (bezpłatne wywołanie raz na dobę
przez okno Kodeksu).

## Hooki do podpięcia

| Zdarzenie modułu | Skrypt                     |
|------------------|----------------------------|
| OnModuleLoad     | `sys_on_load`              |
| OnClientEnter    | (opcjonalnie) `sys_on_enter` |

Stół badań (placeable z OnUsed = `test_grim`) uruchamia okno demonstracyjne.

## Fragmenty arkaniczne — HAK

W hakpaku stwórz 15 przedmiotów z resrefami/tagami według wzoru `gf_<typ>_<tier>`:

| Typ | Szkoła   | Tier 1 resref | Tier 2   | Tier 3   |
|-----|----------|---------------|----------|----------|
| 0   | Ignis    | `gf_0_1`      | `gf_0_2` | `gf_0_3` |
| 1   | Glacies  | `gf_1_1`      | `gf_1_2` | `gf_1_3` |
| 2   | Umbra    | `gf_2_1`      | `gf_2_2` | `gf_2_3` |
| 3   | Void     | `gf_3_1`      | `gf_3_2` | `gf_3_3` |
| 4   | Vita     | `gf_4_1`      | `gf_4_2` | `gf_4_3` |

Każdy przedmiot stackowalny (max stack 99), tag = resref.

## Receptury (8)

| ID | Fragment 1        | Fragment 2        | Efekt               |
|----|-------------------|-------------------|---------------------|
| 1  | Mniejszy Ignis    | Mniejszy Ignis    | Kula Ognia          |
| 2  | Mniejszy Glacies  | Mniejszy Glacies  | Lodowy Uścisk       |
| 3  | Mniejszy Umbra    | Mniejszy Umbra    | Zasłona Mroku       |
| 4  | Mniejszy Void     | Mniejszy Void     | Pustka Rozdarcia    |
| 5  | Mniejszy Vita     | Mniejszy Vita     | Tchnięcie Życia     |
| 6  | Większy Ignis     | Mniejszy Vita     | Żar Krwi (buff)     |
| 7  | Większy Glacies   | Mniejszy Umbra    | Widmo Zimy          |
| 8  | Większy Void      | Większy Umbra     | Rozdarcie Duszy     |

## Szansa sukcesu

`40 + (łączny poziom zaklinacza × 3)`, min 30%, max 90%.  
Przy nieznanych kombinacjach porażka jest gwarantowana (30% odrzut).  
Przy znanych, ale nieudanych kombinacjach odrzut zachodzi z szansą 25%.

## Zależności

- **NWNX**: nie wymagany.  
- **SQL**: kampanijna baza `grimoire` tworzona przez `sys_on_load`.  
- **HAK**: 15 przedmiotów-fragmentów + placeable "Stół Badań" z OnUsed = `test_grim`.

## Co celowo pominięto

- Tworzenie fizycznych zwojów (efekty aplikowane natychmiastowo dla prostoty).
- Animacje castowania (można dodać `PlayAnimation(ANIMATION_LOOPING_CONJURE1, …)` przed `GrimApplyEffect`).
- Handel fragmentami przez sklep — pozostawiono jako rozszerzenie.
- Losowe dropy ze stworów — należy dodać `GrimGiveTestFragment(oKiller, …)` w OnDeath wrogów.

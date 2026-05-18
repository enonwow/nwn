# Kuźnia Runiczna — Integracja z modułem NWN

## Wymagania

- NWN EE 8193.36+ (dla `GetObjectByUUID`, `SqlPrepareQueryCampaign`, NUI)
- NWNX: **nie wymagany**
- Kampania SQL: skrypt tworzy własną bazę `runic_forge`

## Pliki do skopiowania

Wszystkie pliki z `Scripts/` dodaj do HAK modułu lub skompiluj bezpośrednio.
Plik `lib_nui.nss` i `lib_nui_utility.nss` (z innego modułu w repo) muszą
być dostępne w tym samym HAK.

## Hooki modułowe

| Hook modułu        | Skrypt do podpięcia         | Uwagi |
|--------------------|-----------------------------|-------|
| OnModuleLoad       | `sys_on_load.nss`           | tworzy tabele SQL |
| OnPlayerTarget     | `sys_on_target.nss`         | obsługuje wybór broni w trybie celowania |

Jeśli moduł używa już własnego `OnPlayerTarget`, do istniejącego handlera
dodaj wywołanie `RFOnPlayerTarget(GetLastPlayerToSelectTarget())` — funkcja
sprawdza flagę `RF_TARGETING` i nic nie robi, gdy targeting pochodzi od
innego systemu.

## Placeable "Kuźnia Runiczna"

1. Utwórz placeable (np. `wp_forge` lub dowolny kowadło/piec z HAK).
2. W zdarzeniu **OnUsed** ustaw skrypt `test_rf`.
3. Postaw obiekt w grze — gracze klikają i otwiera się UI.

## Weryfikacja działania

1. Zaloguj się jako PC z > 500 sztuk złota.
2. Kliknij placeable kuźni.
3. Kliknij **"Wybierz bron"** i zaznacz miecz w ekwipunku.
4. Wybierz runę (np. Runa Ognia).
5. Kliknij **"KUJ!"** — okno kuźni zamknie się, pojawi się okno minigry.
6. Zapamiętaj sekwencję podświetlanych przycisków (4 kroki dla poziomu 0→1).
7. Powtórz sekwencję — przy sukcesie broń dostaje trwały `1k4 obrażeń Ogniem`.
8. Przy kolejnych próbach sekwencja rośnie, a każdy wyższy poziom kosztuje więcej złota.

## Ograniczenia (celowe pominięcia)

- **Walidacja broni**: moduł używa kolumny `DieToRoll` z `baseitems.2da`.
  Przedmioty rzucane (strzały, bełty) mogą przejść walidację — wyklucz je
  ręcznie w `RFOnPlayerTarget` jeśli potrzeba.
- **Brak wizualnych efektów FX**: `EffectVisualEffect` przy sukcesie pominięty,
  bo wymaga resref z HAK. Dodaj `ApplyEffectToObject(DURATION_TYPE_INSTANT,
  EffectVisualEffect(VFX_FNF_SUMMON_GATE), oItem_location)` wg własnych zasobów.
- **Brak HAK**: moduł nie dodaje własnych obrazków — przyciski NUI używają
  czystego stylu systemowego.
- **Jeden timer globalny**: timeout minigry nie uwzględnia pauzy serwera (lag).
  Przy dużym lagsie gracz może mieć efektywnie mniej czasu.
- **Poziom 5 = cap**: po osiągnięciu poziomu V konkretnej runy na konkretnej
  broni przycisk "KUJ!" jest zablokowany. Nie ma mechanizmu zdejmowania rун.

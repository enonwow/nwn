# Ritual Circles — Integration Guide

## Co to robi

System rytualnych kręgów grupowych. Gracze zbierają się przy specjalnym placeable (kręgu), wybierają rytuał, a lider inicjuje 60-sekundowe channelowanie. Po sukcesie wszyscy uczestnicy dostają potężne efekty grupowe; przerwanie powoduje backlash (2d6 obrażeń + ogłuszenie 6s).

## Hooki do podpięcia

| Zdarzenie modułu | Skrypt |
|-----------------|--------|
| OnModuleLoad | `sys_on_load` |
| OnClientEnter | `sys_on_enter` |
| OnHeartbeat | `sys_module_hb` |

Jeśli moduł ma już własne skrypty tych zdarzeń, dołącz wywołania:
- `RitCreateTables()` w OnModuleLoad
- Blok z `sys_on_enter.nss` w OnClientEnter
- `RitProcessHeartbeat()` w OnHeartbeat

## Placeables — kręgi rytualne

1. Umieść w świecie dowolny placeable (np. Brazier, Stone Circle, Altar).
2. Nadaj mu unikalny **Tag**, np. `rit_circle_01`, `rit_circle_02`.
3. Przypisz skrypt `test_rit` do zdarzenia **OnUsed**.

Każdy placeable to oddzielny, niezależny krąg. Można mieć ich wiele jednocześnie.

## Przedmioty rytualne (lider musi trzymać w ekwipunku)

| Rytuał | Tag przedmiotu | Nazwa |
|--------|---------------|-------|
| Błogosławieństwo Mroku | `rit_candle_black` | Czarna świeca |
| Pakt Krwi | `rit_vial_blood` | Fiolka krwi |
| Przywołanie Ducha | `rit_soul_gem` | Klejnot duszy |
| Splot Klątwy | `rit_effigy` | Kukła ofiarna |

Stwórz odpowiednie przedmioty w HAK lub toolsecie z tymi tagami. Przedmiot jest niszczony przy inicjowaniu rytuału.

## Efekty rytuałów

| Rytuał | Min. uczestników | Efekt sukcesu |
|--------|-----------------|---------------|
| Błogosławieństwo Mroku | 2 | +2 do ataku i +2 magicznych obrażeń przez 1h (wszyscy) |
| Pakt Krwi | 3 | Kosztuje 20% HP każdego → leczy wszystkich do 75% max HP |
| Przywołanie Ducha | 4 | Lider przywołuje wrait (nw_shwraith) na 30 min |
| Splot Klątwy | 2 | –2 do wszystkich rzutów obronnych przez 1h (wszyscy niosą klątwę) |

## Baza danych

Kampania SQLite: `"ritual"` (plik `ritual.sqlite` w katalogu modułu).  
Tabela `rit_circles` — jeden wiersz per tag kręgu, tworzony automatycznie przy pierwszym użyciu.

## Zależności NWNX

Brak — moduł używa wyłącznie standardowego NWScript + NUI (NWN:EE 8193+).

## Co celowo pominięto

- Brak systemu rejestracji offline graczy (rytual wymaga obecności online).
- Brak osobnego panelu DM do zarządzania kręgami (można dodać osobny script).
- Przywołana zjawa (Soul Calling) korzysta ze standardowego `nw_shwraith`; zastąp własnym blueprintem, jeśli chcesz inny model.
- Klątwa (Curse Weaving) daje debuff uczestnikom, a nie bezpośrednio wrogom — zamysłem jest RP „niosę klątwę"; opcjonalnie można dodać OnSpellHook dla efektu obszarowego.

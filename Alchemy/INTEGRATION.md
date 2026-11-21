# Pracownia Alchemiczna — Integracja

## Opis modułu

Pracownia Alchemiczna to system craftingowy oparty na NUI. Gracz podchodzi do
stołu alchemicznego, wybiera przepis z listy i klika **Destyluj**. System pobiera
trzy składniki z ekwipunku, wykonuje rzut Wiedza Magiczna + premia INT vs DC
przepisu, po czym:

- **Sukces** → aplikuje efekt bezpośrednio na gracza (Heal, Haste, STR+4, itp.)
- **Porażka** → składniki przepadają, brak efektu
- **Krytyczna porażka (rzut 1)** → składniki przepadają + 1d6+2 obrażeń od kwasowych oparów
- **Krytyczny sukces (total ≥ DC+10 lub rzut 20)** → efekt aplikowany dwukrotnie

## Wymagane hooki w istniejącym module

| Zdarzenie | Skrypt | Uwaga |
|---|---|---|
| OnModuleLoad | `sys_on_load` | Ustawia NUI event handler |
| OnClientEnter | `sys_on_enter` | Inicjuje tabelę SQL + starter recipes |
| OnAcquireItem | `sys_on_acquire` | Wykrywa zwoje receptur |
| OnNuiEvent | `lib_alch_ev` | Obsługa kliknięć w UI |

Jeśli moduł ma już własne skrypty dla tych zdarzeń, dodaj wywołania przez
`ExecuteScript("sys_on_load_alch", OBJECT_SELF)` lub scal ręcznie.

## Wymagane assety w hak/module

### Składniki (OBJECT_TYPE_ITEM)

Utwórz przedmioty z poniższymi resrefs. Mogą to być zwykłe ikony ziół/fiolek.

| Resref | Polska nazwa | Sugerowana ikona |
|---|---|---|
| `alch_piolun` | Piołun | it_herb/fiolka zielona |
| `alch_kosciol` | Kość Trupna | it_bone01 |
| `alch_krew_n` | Krew Nocna | it_vial02 |
| `alch_grzyb` | Czarny Grzyb | it_herb01 |
| `alch_rtec` | Rtęć | it_vial01 |
| `alch_olej` | Tłuszcz Szczurzy | it_oil01 |
| `alch_oko` | Oko Sowy | it_eye01 |
| `alch_kwiat` | Kwiat Bladej Damy | it_herb02 |
| `alch_krew_o` | Krew Ogra | it_vial03 |
| `alch_zelaz` | Pył Żelazny | it_gem01 |

### Zwoje receptur

Utwórz przedmioty z poniższymi **tagami** (tag, nie resref) aby gracze mogli
odblokowywać przepisy 2–8:

| Tag | Odblokowuje |
|---|---|
| `ALCH_REC_2` | Wywar Pancerza Krwi (DC 14) |
| `ALCH_REC_3` | Eliksir Siły Ogra (DC 16) |
| `ALCH_REC_4` | Wywar Cieni (DC 16) |
| `ALCH_REC_5` | Odwar Odporności (DC 18) |
| `ALCH_REC_6` | Eliksir Szybkości (DC 18) |
| `ALCH_REC_7` | Wywar Ostrza (DC 20) |
| `ALCH_REC_8` | Nalewka Czarnego Serca (DC 22) |

### Stół alchemiczny (placeable)

Utwórz placeable z tagiem `alch_bench` i skryptem `test_alch` na zdarzeniu
**OnUsed**.

## Brak NWNX

Moduł działa wyłącznie na standardowym NWScript + NUI. Brak zależności od NWNX.

## Testy

1. Wejdź do modułu jako PC.
2. Kliknij stół `alch_bench` — dostaniesz składniki testowe + zwój receptury 2.
3. Podnieś zwój — zobaczysz komunikat odblokowania i lista w UI się odświeży.
4. Kliknij stół ponownie, wybierz "Nalewka Gojąca", kliknij "Destyluj".
5. Sprawdź komunikaty rzutu i efekt HP.

## Co celowo pominięto

- **Animacja destylacji** — efekt VFX na stole nie jest aplikowany; można dodać
  `ApplyEffectAtLocation(DURATION_TYPE_INSTANT, EffectVisualEffect(VFX_FNF_SMOKE_PUFF), GetLocation(oPC))`.
- **Sklep ze składnikami** — intencjonalnie nie dostarczono NPC handlarza; to
  decyzja projektanta świata.
- **Trwałe efekty** — wszystkie efekty są tymczasowe; "permanentna" alchemia
  wymagałaby osobnego systemu ekwipunku.
- **Multiplayer race condition** — brak locka na składnikach między sprawdzeniem
  a ich zdjęciem (minimalne ryzyko w praktyce przy lokalnym inventory).

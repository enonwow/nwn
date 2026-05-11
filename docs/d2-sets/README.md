# Diablo 2 Item Sets — Complete Reference

A four-part reference compiled by parallel research subagents from Blizzard
patch notes, Diablo Wiki, Maxroll, Icy-Veins, Arreat Summit and PureDiablo.
Built as a design reference for porting D2-style set mechanics into NWN.

## Files

| File | Coverage | Sets | Items | Lines |
|---|---|---:|---:|---:|
| [`classic.md`](classic.md) | All 16 vanilla D2 sets | 16 | 61 | 494 |
| [`lod-class.md`](lod-class.md) | Class-specific LoD sets (one per class) | 8 | 35 | 466 |
| [`lod-general.md`](lod-general.md) | Non-class LoD sets | 8 | 30 | 265 |
| [`d2r-patches.md`](d2r-patches.md) | Patch 2.4 / 2.5 set rebalances | — | — | 105 |
| **Total** | | **32** | **126** | **1330** |

## Sets index

### Classic (16) — see [`classic.md`](classic.md)
Angelic Raiment · Arcanna's Tricks · Arctic Gear · Berserker's Arsenal ·
Cathan's Traps · Civerb's Vestments · Cleglaw's Brace · Death's Disguise ·
Hsarus' Defense · Infernal Tools · Iratha's Finery · Isenhart's Armory ·
Milabrega's Regalia · Sigon's Complete Steel · Tancred's Battlegear · Vidala's Rig

### LoD class-specific (8) — see [`lod-class.md`](lod-class.md)
Aldur's Watchtower (Druid) · Bul-Kathos' Children (Barbarian) ·
Griswold's Legacy (Paladin) · Immortal King (Barbarian) ·
M'avina's Battle Hymn (Amazon) · Natalya's Odium (Assassin) ·
Tal Rasha's Wrappings (Sorceress) · Trang-Oul's Avatar (Necromancer)

### LoD general (8) — see [`lod-general.md`](lod-general.md)
Cow King's Leathers · The Disciple · Heaven's Brethren · Hwanin's Majesty ·
Naj's Ancient Vestige · Orphan's Call · Sander's Folly · Sazabi's Grand Tribute

### D2R patch changes — see [`d2r-patches.md`](d2r-patches.md)
Patch 2.4 (Apr 2022, Ladder Season 1) — major rebalance pass.
Patch 2.5 (Oct 2022) — no set-specific reworks (Terror Zones / Sundering Charms only).

## Notation conventions

- `[verify]` — value flagged uncertain after cross-referencing; choose
  authoritative source before porting.
- `(varies: classic X, D2R Y)` — value differs between vanilla 1.09 and D2R;
  prefer D2R for modern feel.
- Stat ranges written as `min-max` (e.g. `+1-2 fire damage`).
- Procs written as `% chance to cast Skill (level N) on <trigger>`.

## Known gaps

- D2R patches doc was blocked from WebFetch'ing several authoritative sources
  (403). Class-specific 2.4 set tweaks have `[verify]` flags pending manual
  cross-check against the official Blizzard 2.4 patch notes.
- 62 total `[verify]` flags across all four files (23 + 23 + 16 + small handful).
  See "Known [verify] flags summary" section in each file.

## How sets work in D2 (quick primer)

- **Partial bonus**: extra stats granted when you have N>=2 set pieces equipped.
  Each tier (2, 3, 4, …) usually adds another bonus on top of previous.
- **Complete set bonus**: maximum tier bonus when all N pieces are equipped.
  Often shows in green text.
- **Per-item green text**: in LoD/D2R, individual set items display additional
  bonuses that activate as more pieces of the same set are equipped. Tal Rasha
  is the canonical example with a full 5/5 vs 4/5 discontinuity.
- **Level scaling**: a few sets (Tal Rasha, IK Maul, Aldur's) have bonuses
  whose magnitude depends on the wearer's character level. Formulas in the
  per-set Notes sections.
- **Drop sources**: most sets are normal-quality drops that "promote" to set
  on identification. A few have specific TC links — see per-set Notes.

## Porting considerations for NWN

- D2 stat lines (especially **+N to skills**, **+N% Cannot Be Frozen**,
  **Slows Target by N%**) don't map 1:1 to NWN. The cross-set notes appendix
  in `classic.md` lists the typical mapping problems and recommendations.
- The 5/5 vs 4/5 discontinuity (Tal Rasha) is non-trivial — it's probably the
  most distinctive set mechanic and worth replicating.
- Level-scaling formulas are best ported as effects with periodic refresh on
  level-up (similar to the Master & Apprentice skill bonus refresh).
